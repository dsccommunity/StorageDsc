$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xDiskAccessPath'

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
    # Ensure that the tests can be performed on this computer
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
            Write-Verbose -Message "$($script:DSCResourceName) integration tests cannot be run on this operating system." -Verbose
            Break
        }
    }

    if ($HyperVInstalled -eq $false)
    {
        Write-Verbose -Message "$($script:DSCResourceName) integration tests cannot be run because Hyper-V Components not installed." -Verbose
        Return
    }

    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Integration" {
        Context 'Partition and format newly provisioned disk and assign an Access Path' {
            # Create a VHDx and attach it to the computer
            $VHDPath = Join-Path -Path $TestEnvironment.WorkingFolder `
                -ChildPath 'TestDisk.vhdx'
            New-VHD -Path $VHDPath -SizeBytes 1GB -Dynamic
            Mount-DiskImage -ImagePath $VHDPath -StorageType VHDX -NoDriveLetter
            $Disk = Get-Disk | Where-Object -FilterScript {
                $_.Location -eq $VHDPath
            }
            $FSLabel = 'TestDisk'


            # Get a mount point path
            $AccessPath = Join-Path -Path $ENV:Temp -ChildPath 'xDiskAccessPath_Mount'
            if (-not (Test-Path -Path $AccessPath))
            {
                New-Item -Path $AccessPath -ItemType Directory
            } # if

            #region DEFAULT TESTS
            It 'Should compile without throwing' {
                {
                    # This is so that the
                    $ConfigData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                AccessPath  = $AccessPath
                                DiskNumber  = $Disk.Number
                                FSLabel     = $FSLabel
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskNumber       | Should Be $Disk.DiskNumber
                $current.AccessPath       | Should Be "$($AccessPath)\"
                $current.FSLabel          | Should Be $FSLabel
            }

            Remove-PartitionAccessPath `
                -DiskNumber $Disk.DiskNumber `
                -PartitionNumber 2 `
                -AccessPath $AccessPath
            Remove-Item -Path $AccessPath -Force
            Dismount-DiskImage -ImagePath $VHDPath -StorageType VHDx
            Remove-Item -Path $VHDPath -Force
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
