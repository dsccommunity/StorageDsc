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

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    #region Integration Tests for DiskNumber
    Describe "$($script:DSCResourceName)_Integration" {
        Context 'Partition and format newly provisioned disk using Disk Number with two volumes and assign Drive Letters' {
            BeforeAll {
                # Create a VHDx and attach it to the computer
                $VHDPath = Join-Path -Path $TestDrive `
                    -ChildPath 'TestDisk.vhdx'
                New-VHD -Path $VHDPath -SizeBytes 1GB -Dynamic
                Mount-DiskImage -ImagePath $VHDPath -StorageType VHDX -NoDriveLetter
                $disk = Get-Disk | Where-Object -FilterScript {
                    $_.Location -eq $VHDPath
                }
                $FSLabelA = 'TestDiskA'
                $FSLabelB = 'TestDiskB'

                # Get a spare drive letters
                $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
                $driveLetterA = [char](([int][char]$lastDrive)+1)
                $driveLetterB = [char](([int][char]$lastDrive)+2)
            }

            #region DEFAULT TESTS
            It 'should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                DriveLetter = $driveLetterA
                                DiskId      = $disk.Number
                                DiskIdType  = 'Number'
                                FSLabel     = $FSLabelA
                                Size        = 100MB
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should Not Throw
            }

            It 'should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
            }
            #endregion

            It 'should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should Be $disk.Number
                $current.DriveLetter      | Should Be $driveLetterA
                $current.FSLabel          | Should Be $FSLabelA
                $current.Size             | Should Be 100MB
            }

            It 'should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                DriveLetter = $driveLetterB
                                DiskId      = $disk.Number
                                DiskIdType  = 'Number'
                                FSLabel     = $FSLabelB
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should Not Throw
            }

            It 'should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
            }
            #endregion

            It 'should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should Be $disk.Number
                $current.DriveLetter      | Should Be $driveLetterB
                $current.FSLabel          | Should Be $FSLabelB
                $current.Size             | Should Be 935198720
            }

            # A system partition will have been added to the disk as well as the 2 test partitions
            It 'should have 3 partitions on disk' {
                ($disk | Get-Partition).Count | Should Be 3
            }

            It "should have attached drive $driveLetterA" {
                Get-PSDrive -Name $driveLetterA -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
            }

            It "should have attached drive $driveLetterB" {
                Get-PSDrive -Name $driveLetterB -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
            }

            AfterAll {
                Dismount-DiskImage -ImagePath $VHDPath -StorageType VHDx
                Remove-Item -Path $VHDPath -Force
            }
        }
    }
    #endregion

    #region Integration Tests for Disk Unique Id
    Describe "$($script:DSCResourceName)_Integration" {
        Context 'Partition and format newly provisioned disk using Unique Id with two volumes and assign Drive Letters' {
            BeforeAll {
                # Create a VHDx and attach it to the computer
                $VHDPath = Join-Path -Path $TestDrive `
                    -ChildPath 'TestDisk.vhdx'
                New-VHD -Path $VHDPath -SizeBytes 1GB -Dynamic
                Mount-DiskImage -ImagePath $VHDPath -StorageType VHDX -NoDriveLetter
                $disk = Get-Disk | Where-Object -FilterScript {
                    $_.Location -eq $VHDPath
                }
                $FSLabelA = 'TestDiskA'
                $FSLabelB = 'TestDiskB'

                # Get a spare drive letter
                $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
                $driveLetterA = [char](([int][char]$lastDrive)+1)
                $driveLetterB = [char](([int][char]$lastDrive)+2)
            }

            #region DEFAULT TESTS
            It 'should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName      = 'localhost'
                                DriveLetter   = $driveLetterA
                                DiskId        = $disk.UniqueId
                                DiskIdType    = 'UniqueId'
                                FSLabel       = $FSLabelA
                                Size          = 100MB
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should Not Throw
            }

            It 'should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
            }
            #endregion

            It 'should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should Be $disk.UniqueId
                $current.DriveLetter      | Should Be $driveLetterA
                $current.FSLabel          | Should Be $FSLabelA
                $current.Size             | Should Be 100MB
            }

            #region DEFAULT TESTS
            It 'should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName      = 'localhost'
                                DriveLetter   = $driveLetterB
                                DiskId        = $disk.UniqueId
                                DiskIdType    = 'UniqueId'
                                FSLabel       = $FSLabelB
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should Not Throw
            }

            It 'should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not Throw
            }
            #endregion

            It 'should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should Be $disk.UniqueId
                $current.DriveLetter      | Should Be $driveLetterB
                $current.FSLabel          | Should Be $FSLabelB
                $current.Size             | Should Be 935198720
            }

            # A system partition will have been added to the disk as well as the 2 test partitions
            It 'should have 3 partitions on disk' {
                ($disk | Get-Partition).Count | Should Be 3
            }

            It "should have attached drive $driveLetterA" {
                Get-PSDrive -Name $driveLetterA -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
            }

            It "should have attached drive $driveLetterB" {
                Get-PSDrive -Name $driveLetterB -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
            }

            AfterAll {
                Dismount-DiskImage -ImagePath $VHDPath -StorageType VHDx
                Remove-Item -Path $VHDPath -Force
            }
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
