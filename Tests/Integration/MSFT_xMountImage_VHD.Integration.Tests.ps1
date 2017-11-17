$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xMountImage'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Integration Test Template Version: 1.1.1
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xStorage'
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
    # Get a spare drive letter
    $LastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
    $DriveLetter = [char](([int][char]$LastDrive)+1)

    # Create a VHD with a partition
    $VHDPath = Join-Path -Path $ENV:Temp `
        -ChildPath 'TestDisk.vhd'
    $null = New-VDisk -Path $VHDPath -SizeInMB 1024
    $null = Mount-DiskImage -ImagePath $VHDPath
    $diskImage = Get-DiskImage -ImagePath $VHDPath
    $disk = Get-Disk -Number $diskImage.Number
    $null = $disk | Initialize-Disk -PartitionStyle GPT
    $partition = $disk | New-Partition -UseMaximumSize
    $null = $partition | Get-Volume | Format-Volume -FileSystem NTFS -Confirm:$false
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
        Context 'Mount an VHDX and assign a Drive Letter' {
            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_Mount_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $ConfigData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }
            #endregion

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Mount_Config"
                }
                $current.Imagepath        | Should -Be $VHDPath
                $current.DriveLetter      | Should -Be $DriveLetter
                $current.StorageType      | Should -Be 'VHD'
                $current.Access           | Should -Be 'ReadWrite'
                $current.Ensure           | Should -Be 'Present'
            }
        }
    }

    # Dismount VHD
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_dismount.config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_DismountVHD_Integration" {
        Context 'Dismount a previously mounted ISO' {
            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_Dismount_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $ConfigData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }
            #endregion

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Dismount_Config"
                }
                $current.Imagepath        | Should -Be $VHDPath
                $current.Ensure           | Should -Be 'Absent'
            }
        }
    }

    # Delete the VHD test file created
    Remove-Item -Path $VHDPath -Force
    #endregion Integration Tests for VHD
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
