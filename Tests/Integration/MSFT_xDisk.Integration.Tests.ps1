$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xDisk'

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
    # Ensure that the tests can be performed on this computer
    if (-not (Test-HyperVInstalled))
    {
        Return
    }

    #region Integration Tests for DiskNumber
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).Number.config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_DiskNumber_Integration" {
        Context 'Partition and format newly provisioned disk and assign a Drive Letter' {
            # Create a VHDx and attach it to the computer
            $VHDPath = Join-Path -Path $TestDrive `
                -ChildPath 'TestDisk.vhdx'
            New-VHD -Path $VHDPath -SizeBytes 1GB -Dynamic
            Mount-DiskImage -ImagePath $VHDPath -StorageType VHDX -NoDriveLetter
            $Disk = Get-Disk | Where-Object -FilterScript {
                $_.Location -eq $VHDPath
            }
            $FSLabel = 'TestDisk'

            # Get a spare drive letter
            $LastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
            $DriveLetter = [char](([int][char]$LastDrive)+1)

            #region DEFAULT TESTS
            It 'Should compile without throwing' {
                {
                    # This is so that the
                    $ConfigData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                DriveLetter = $DriveLetter
                                DiskNumber  = $Disk.Number
                                FSLabel     = $FSLabel
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_Number_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $ConfigData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should not throw
            }

            It 'should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }
            #endregion

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Number_Config"
                }
                $current.DiskNumber       | Should Be $Disk.Number
                $current.DriveLetter      | Should Be $DriveLetter
                $current.FSLabel          | Should Be $FSLabel
            }

            Dismount-DiskImage -ImagePath $VHDPath -StorageType VHDx
            Remove-Item -Path $VHDPath -Force
        }
    }
    #endregion

    #region Integration Tests for DiskId
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).UniqueId.config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_DiskUniqueId_Integration" {
        Context 'Partition and format newly provisioned disk and assign a Drive Letter' {
            # Create a VHDx and attach it to the computer
            $VHDPath = Join-Path -Path $TestDrive `
                -ChildPath 'TestDisk.vhdx'
            New-VHD -Path $VHDPath -SizeBytes 1GB -Dynamic
            Mount-DiskImage -ImagePath $VHDPath -StorageType VHDX -NoDriveLetter
            $Disk = Get-Disk | Where-Object -FilterScript {
                $_.Location -eq $VHDPath
            }
            $FSLabel = 'TestDisk'

            # Get a spare drive letter
            $LastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
            $DriveLetter = [char](([int][char]$LastDrive)+1)

            #region DEFAULT TESTS
            It 'Should compile without throwing' {
                {
                    # This is so that the
                    $ConfigData = @{
                        AllNodes = @(
                            @{
                                NodeName      = 'localhost'
                                DriveLetter   = $DriveLetter
                                DiskUniqueId  = $Disk.UniqueId
                                FSLabel       = $FSLabel
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_UniqueId_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $ConfigData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should not throw
            }

            It 'should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }
            #endregion

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_UniqueId_Config"
                }
                $current.DiskUniqueId     | Should Be $Disk.UniqueId
                $current.DriveLetter      | Should Be $DriveLetter
                $current.FSLabel          | Should Be $FSLabel
            }

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
