$script:DSCModuleName = 'xStorage'
$script:DSCResourceName = 'MSFT_xDisk'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Integration Test Template Version: 1.1.1
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xStorage'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
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
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Integration" {
        #region Integration Tests for DiskNumber
        Context 'Partition and format newly provisioned disk using Disk Number with two volumes and assign Drive Letters' {
            BeforeAll {
                # Create a VHD and attach it to the computer
                $VHDPath = Join-Path -Path $TestDrive `
                    -ChildPath 'TestDisk.vhd'
                $null = New-VDisk -Path $VHDPath -SizeInMB 1024
                $null = Mount-DiskImage -ImagePath $VHDPath -StorageType VHD -NoDriveLetter
                $diskImage = Get-DiskImage -ImagePath $VHDPath
                $disk = Get-Disk -Number $diskImage.Number
                $FSLabelA = 'TestDiskA'
                $FSLabelB = 'TestDiskB'

                # Get a spare drive letters
                $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
                $driveLetterA = [char](([int][char]$lastDrive) + 1)
                $driveLetterB = [char](([int][char]$lastDrive) + 2)
            }

            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
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
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }
            #endregion

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should -Be $disk.Number
                $current.DriveLetter      | Should -Be $driveLetterA
                $current.FSLabel          | Should -Be $FSLabelA
                $current.Size             | Should -Be 100MB
            }

            It 'Should compile and apply the MOF without throwing' {
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
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }
            #endregion

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should -Be $disk.Number
                $current.DriveLetter      | Should -Be $driveLetterB
                $current.FSLabel          | Should -Be $FSLabelB
                $current.Size             | Should -Be 935198720
            }

            # A system partition will have been added to the disk as well as the 2 test partitions
            It 'Should have 3 partitions on disk' {
                ($disk | Get-Partition).Count | Should -Be 3
            }

            <#
                Get a list of all drives mounted - this works better on Windows Server 2012 R2 than
                trying to get the drive mounted by name.
            #>
            $drives = Get-PSDrive

            It "should have attached drive $driveLetterA" {
                $drives | Where-Object -Property Name -eq $driveLetterA | Should -Not -BeNullOrEmpty
            }

            It "should have attached drive $driveLetterB" {
                $drives | Where-Object -Property Name -eq $driveLetterB | Should -Not -BeNullOrEmpty
            }

            AfterAll {
                Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
                Remove-Item -Path $VHDPath -Force
            }
        }

        #region Integration Tests for Disk Unique Id
        Context 'Partition and format newly provisioned disk using Unique Id with two volumes and assign Drive Letters' {
            BeforeAll {
                # Create a VHD and attach it to the computer
                $VHDPath = Join-Path -Path $TestDrive `
                    -ChildPath 'TestDisk.vhd'
                $null = New-VDisk -Path $VHDPath -SizeInMB 1024
                $null = Mount-DiskImage -ImagePath $VHDPath -StorageType VHD -NoDriveLetter
                $diskImage = Get-DiskImage -ImagePath $VHDPath
                $disk = Get-Disk -Number $diskImage.Number
                $FSLabelA = 'TestDiskA'
                $FSLabelB = 'TestDiskB'

                # Get a spare drive letter
                $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
                $driveLetterA = [char](([int][char]$lastDrive) + 1)
                $driveLetterB = [char](([int][char]$lastDrive) + 2)
            }

            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                DriveLetter = $driveLetterA
                                DiskId      = $disk.UniqueId
                                DiskIdType  = 'UniqueId'
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
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }
            #endregion

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should -Be $disk.UniqueId
                $current.DriveLetter      | Should -Be $driveLetterA
                $current.FSLabel          | Should -Be $FSLabelA
                $current.Size             | Should -Be 100MB
            }

            #region DEFAULT TESTS Resize/Reformat
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
                                Size          = 900MB
                                FSFormat      = 'ReFS'
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_ConfigDestructive" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }
            #endregion

            It 'should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_ConfigDestructive"
                }
                $current.DiskId           | Should -Be $disk.UniqueId
                $current.DriveLetter      | Should -Be $driveLetterA
                $current.FSLabel          | Should -Be $FSLabelA
                $current.Size             | Should -Be 900MB
                $current.FSFormat         | Should -Be 'ReFS'
            }

            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                DriveLetter = $driveLetterB
                                DiskId      = $disk.UniqueId
                                DiskIdType  = 'UniqueId'
                                FSLabel     = $FSLabelB
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
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
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should -Be $disk.UniqueId
                $current.DriveLetter      | Should -Be $driveLetterB
                $current.FSLabel          | Should -Be $FSLabelB
                $current.Size             | Should -Be 96337920
            }

            # A system partition will have been added to the disk as well as the 2 test partitions
            It 'Should have 3 partitions on disk' {
                ($disk | Get-Partition).Count | Should -Be 3
            }

            It "should have attached drive $driveLetterA" {
                Get-PSDrive -Name $driveLetterA -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It "should have attached drive $driveLetterB" {
                Get-PSDrive -Name $driveLetterB -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            AfterAll {
                $null = Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
                $null = Remove-Item -Path $VHDPath -Force
            }
        }
        #endregion

        #region Integration Tests for Disk Guid
        Context 'Partition and format newly provisioned disk using Guid with two volumes and assign Drive Letters' {
            BeforeAll {
                # Create a VHD and attach it to the computer
                $VHDPath = Join-Path -Path $TestDrive `
                    -ChildPath 'TestDisk.vhd'
                $null = New-VDisk -Path $VHDPath -SizeInMB 1024 -Initialize
                $null = Mount-DiskImage -ImagePath $VHDPath -StorageType VHD -NoDriveLetter
                $diskImage = Get-DiskImage -ImagePath $VHDPath
                $disk = Get-Disk -Number $diskImage.Number
                $FSLabelA = 'TestDiskA'
                $FSLabelB = 'TestDiskB'

                # Get a spare drive letter
                $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
                $driveLetterA = [char](([int][char]$lastDrive) + 1)
                $driveLetterB = [char](([int][char]$lastDrive) + 2)
            }

            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                DriveLetter = $driveLetterA
                                DiskId      = $disk.Guid
                                DiskIdType  = 'Guid'
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
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }
            #endregion

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should -Be $disk.Guid
                $current.DriveLetter      | Should -Be $driveLetterA
                $current.FSLabel          | Should -Be $FSLabelA
                $current.Size             | Should -Be 100MB
            }

            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                DriveLetter = $driveLetterB
                                DiskId      = $disk.Guid
                                DiskIdType  = 'Guid'
                                FSLabel     = $FSLabelB
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
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
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should -Be $disk.Guid
                $current.DriveLetter      | Should -Be $driveLetterB
                $current.FSLabel          | Should -Be $FSLabelB
                $current.Size             | Should -Be 935198720
            }

            # A system partition will have been added to the disk as well as the 2 test partitions
            It 'Should have 3 partitions on disk' {
                ($disk | Get-Partition).Count | Should -Be 3
            }

            It "should have attached drive $driveLetterA" {
                Get-PSDrive -Name $driveLetterA -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It "should have attached drive $driveLetterB" {
                Get-PSDrive -Name $driveLetterB -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            AfterAll {
                $null = Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
                $null = Remove-Item -Path $VHDPath -Force
            }
        }
        #endregion

        #region Integration Tests for Disk Guid
        Context 'Partition and format newly provisioned disk using Guid with two volumes and assign Drive Letters' {
            BeforeAll {
                # Create a VHD and attach it to the computer
                $VHDPath = Join-Path -Path $TestDrive `
                    -ChildPath 'TestDisk.vhd'
                $null = New-VDisk -Path $VHDPath -SizeInMB 1024 -Initialize
                $null = Mount-DiskImage -ImagePath $VHDPath -StorageType VHD -NoDriveLetter
                $diskImage = Get-DiskImage -ImagePath $VHDPath
                $disk = Get-Disk -Number $diskImage.Number
                $FSLabelA = 'TestDiskA'
                $FSLabelB = 'TestDiskB'

                # Get a spare drive letter
                $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
                $driveLetterA = [char](([int][char]$lastDrive) + 1)
                $driveLetterB = [char](([int][char]$lastDrive) + 2)
            }

            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                DriveLetter = $driveLetterA
                                DiskId      = $disk.Guid
                                DiskIdType  = 'Guid'
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
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }
            #endregion

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should -Be $disk.Guid
                $current.DriveLetter      | Should -Be $driveLetterA
                $current.FSLabel          | Should -Be $FSLabelA
                $current.Size             | Should -Be 100MB
            }

            #region DEFAULT TESTS
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                DriveLetter = $driveLetterB
                                DiskId      = $disk.Guid
                                DiskIdType  = 'Guid'
                                FSLabel     = $FSLabelB
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
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
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should -Be $disk.Guid
                $current.DriveLetter      | Should -Be $driveLetterB
                $current.FSLabel          | Should -Be $FSLabelB
                $current.Size             | Should -Be 935198720
            }

            # A system partition will have been added to the disk as well as the 2 test partitions
            It 'Should have 3 partitions on disk' {
                ($disk | Get-Partition).Count | Should -Be 3
            }

            It "should have attached drive $driveLetterA" {
                Get-PSDrive -Name $driveLetterA -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It "should have attached drive $driveLetterB" {
                Get-PSDrive -Name $driveLetterB -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            AfterAll {
                $null = Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
                $null = Remove-Item -Path $VHDPath -Force
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
