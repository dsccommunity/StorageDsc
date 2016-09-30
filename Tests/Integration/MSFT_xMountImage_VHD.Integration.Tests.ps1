# In order to run these tests, Hyper-V must be installed on the testing computer.
# If it is not installed these tests will not be run. This does prevent these tests
# from being run on AppVeyor.

$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xMountImage'

#region HEADER
# Integration Test Template Version: 1.1.1
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests for VHD

    # Ensure that the VHD tests can be performed on this computer
    $ProductType = (Get-CimInstance Win32_OperatingSystem).ProductType
    switch ($ProductType) {
        1
        {
            # Desktop OS
            $HyperVInstalled = (((Get-WindowsOptionalFeature `
                    -FeatureName Microsoft-Hyper-V `
                    -Online).State -eq 'Enabled') -and `
                ((Get-WindowsOptionalFeature `
                    -FeatureName Microsoft-Hyper-V-Management-PowerShell `
                    -Online).State -eq 'Enabled'))
            Break
        }
        3
        {
            # Server OS
            $HyperVInstalled = (((Get-WindowsFeature -Name Hyper-V).Installed) -and `
                ((Get-WindowsFeature -Name Hyper-V-PowerShell).Installed))
            Break
        }
        default
        {
            # Unsupported OS type for testing
            Break
        }
    }

    if ($HyperVInstalled -eq $false)
    {
        Write-Verbose -Message "$($script:DSCResourceName) integration tests cannot be run because Hyper-V Components not installed." -Verbose
        Return
    }

    # Get a spare drive letter
    $LastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
    $DriveLetter = [char](([int][char]$LastDrive)+1)

    # Create a VHDx with a partition
    $VHDPath = Join-Path -Path $TestEnvironment.WorkingFolder `
        -ChildPath 'TestDisk.vhdx'
    $null = New-VHD -Path $VHDPath -SizeBytes 10GB -Dynamic
    $null = Mount-DiskImage -ImagePath $VHDPath
    $disk = Get-Disk | Where-Object -Property Location -EQ -Value $VHDPath
    $null = $disk | Initialize-Disk -PartitionStyle GPT
    $partition = $disk | New-Partition -UseMaximumSize
    $null = $partition | Get-Volume | Format-Volume -FileSystem NTFS
    $null = Dismount-Diskimage -ImagePath $VHDPath

    # Create a config data object to pass to the DSC Configs
    $ConfigData = @{
        AllNodes = @(
            @{
                NodeName    = 'localhost'
                ImagePath   = $VHDPath
                DriveLetter = $DriveLetter
            }
        )
    }

    # Mount VHD
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_mount.config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_MountVHD_Integration" {

        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Mount_Config" `
                    -OutputPath $TestEnvironment.WorkingFolder `
                    -ConfigurationData $ConfigData
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {
                $_.ConfigurationName -eq "$($script:DSCResourceName)_Mount_Config"
            }
            $current.Imagepath        | Should Be $VHDPath
            $current.DriveLetter      | Should Be $DriveLetter
            $current.StorageType      | Should Be 'VHDX'
            $current.Access           | Should Be 'ReadWrite'
            $current.Ensure           | Should Be 'Present'
        }
    }

    # Dismount VHD
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_dismount.config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_DismountVHD_Integration" {

        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                & "$($script:DSCResourceName)_Dismount_Config" `
                    -OutputPath $TestEnvironment.WorkingFolder `
                    -ConfigurationData $ConfigData
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {
                $_.ConfigurationName -eq "$($script:DSCResourceName)_Dismount_Config"
            }
            $current.Imagepath        | Should Be $VHDPath
            $current.Ensure           | Should Be 'Absent'
        }
    }

    # Delete the VHDx test file created
    Remove-Item -Path $VHDPath -Force
    #endregion Integration Tests for VHD
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
