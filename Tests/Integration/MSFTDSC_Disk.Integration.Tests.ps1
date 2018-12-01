$script:DSCModuleName = 'StorageDsc'
$script:DSCResourceName = 'MSFTDSC_Disk'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Integration Test Template Version: 1.1.1
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
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
        Context 'When partitioning and formatting a newly provisioned disk using Disk Number with two volumes and assigning Drive Letters' {
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

            Context "When creating the first volume on Disk Number $($disk.Number)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.Number
                                    DiskIdType     = 'Number'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelA
                                    Size           = 100MB
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.Number
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.FSLabel        | Should -Be $FSLabelA
                    $current.Size           | Should -Be 100MB
                }
            }

            Context "When creating the second volume on Disk Number $($disk.Number)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterB
                                    DiskId         = $disk.Number
                                    DiskIdType     = 'Number'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelB
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.Number
                    $current.DriveLetter    | Should -Be $driveLetterB
                    $current.FSLabel        | Should -Be $FSLabelB
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.Size           | Should -Be 935198720
                }
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

            It "Should have attached drive $driveLetterA" {
                $drives | Where-Object -Property Name -eq $driveLetterA | Should -Not -BeNullOrEmpty
            }

            It "Should have attached drive $driveLetterB" {
                $drives | Where-Object -Property Name -eq $driveLetterB | Should -Not -BeNullOrEmpty
            }

            AfterAll {
                Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
                Remove-Item -Path $VHDPath -Force
            }
        }

        Context 'When partitioniong and formatting a newly provisioned disk using Disk Number with one volume and assigning Drive Letters then resizing' {
            BeforeAll {
                # Create a VHD and attach it to the computer
                $VHDPath = Join-Path -Path $TestDrive `
                    -ChildPath 'TestDisk.vhd'
                $null = New-VDisk -Path $VHDPath -SizeInMB 1024
                $null = Mount-DiskImage -ImagePath $VHDPath -StorageType VHD -NoDriveLetter
                $diskImage = Get-DiskImage -ImagePath $VHDPath
                $disk = Get-Disk -Number $diskImage.Number
                $FSLabelA = 'TestDiskA'

                # Get a spare drive letters
                $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
                $driveLetterA = [char](([int][char]$lastDrive) + 1)
            }

            Context "When creating a volume on Disk Number $($disk.Number)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.Number
                                    DiskIdType     = 'Number'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelA
                                    Size           = 50MB
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.Number
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.FSLabel        | Should -Be $FSLabelA
                    $current.FSFormat       | Should -Be 'NTFS'
                    $current.Size           | Should -Be 50MB
                }
            }

            Context "When resizing a partition on Disk Number $($disk.Number) to use all free space with AllowDestructive" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.Number
                                    DiskIdType     = 'Number'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelA
                                    FSFormat       = 'NTFS'
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_ConfigAllowDestructive" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_ConfigAllowDestructive"
                    }
                    $current.DiskId         | Should -Be $disk.Number
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.FSLabel        | Should -Be $FSLabelA
                    $current.FSFormat       | Should -Be 'NTFS'
                    $current.Size           | Should -Be 1040104960
                }
            }

            # A system partition will have been added to the disk as well as the test partition
            It 'Should have 2 partitions on disk' {
                ($disk | Get-Partition).Count | Should -Be 2
            }

            <#
                Get a list of all drives mounted - this works better on Windows Server 2012 R2 than
                trying to get the drive mounted by name.
            #>
            $drives = Get-PSDrive

            It "Should have attached drive $driveLetterA" {
                $drives | Where-Object -Property Name -eq $driveLetterA | Should -Not -BeNullOrEmpty
            }

            AfterAll {
                Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
                Remove-Item -Path $VHDPath -Force
            }
        }

        Context 'When partitioning and formatting a newly provisioned disk using Disk Number with one volume using MBR then convert to GPT' {
            BeforeAll {
                # Create a VHD and attach it to the computer
                $VHDPath = Join-Path -Path $TestDrive `
                    -ChildPath 'TestDisk.vhd'
                $null = New-VDisk -Path $VHDPath -SizeInMB 1024
                $null = Mount-DiskImage -ImagePath $VHDPath -StorageType VHD -NoDriveLetter
                $diskImage = Get-DiskImage -ImagePath $VHDPath
                $disk = Get-Disk -Number $diskImage.Number
                $FSLabelA = 'TestDiskA'

                # Get a spare drive letters
                $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
                $driveLetterA = [char](([int][char]$lastDrive) + 1)
            }

            Context "When creating a volume on Disk Number $($disk.Number)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.Number
                                    DiskIdType     = 'Number'
                                    PartitionStyle = 'MBR'
                                    FSLabel        = $FSLabelA
                                    Size           = 50MB
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.Number
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.PartitionStyle | Should -Be 'MBR'
                    $current.FSLabel        | Should -Be $FSLabelA
                    $current.FSFormat       | Should -Be 'NTFS'
                    $current.Size           | Should -Be 50MB
                }
            }

            Context "When clearing Disk Number $($disk.Number) and changing the partition style to GPT and adding a 50MB partition" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.Number
                                    DiskIdType     = 'Number'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelA
                                    FSFormat       = 'NTFS'
                                    Size           = 50MB
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_ConfigClearDisk" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_ConfigClearDisk"
                    }
                    $current.DiskId         | Should -Be $disk.Number
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.FSLabel        | Should -Be $FSLabelA
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.FSFormat       | Should -Be 'NTFS'
                    $current.Size           | Should -Be 52428800
                }
            }

            # A system partition will have been added to the disk as well as the test partition
            It 'Should have 2 partitions on disk' {
                ($disk | Get-Partition).Count | Should -Be 2
            }

            <#
                Get a list of all drives mounted - this works better on Windows Server 2012 R2 than
                trying to get the drive mounted by name.
            #>
            $drives = Get-PSDrive

            It "Should have attached drive $driveLetterA" {
                $drives | Where-Object -Property Name -eq $driveLetterA | Should -Not -BeNullOrEmpty
            }

            AfterAll {
                Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
                Remove-Item -Path $VHDPath -Force
            }
        }
        #endregion

        #region Integration Tests for Disk Unique Id
        Context 'When partitioning and formatting a newly provisioned disk using Unique Id with two volumes and assigning Drive Letters' {
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

            Context "When creating the first volume on Disk Unique Id $($disk.UniqueId)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.UniqueId
                                    DiskIdType     = 'UniqueId'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelA
                                    Size           = 100MB
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.UniqueId
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.FSLabel        | Should -Be $FSLabelA
                    $current.Size           | Should -Be 100MB
                }
            }

            Context "When resizing the first volume on Disk Unique Id $($disk.UniqueId) and allowing the disk to be cleared" {
                It 'should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.UniqueId
                                    DiskIdType     = 'UniqueId'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelA
                                    Size           = 900MB
                                    FSFormat       = 'ReFS'
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_ConfigClearDisk" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_ConfigClearDisk"
                    }
                    $current.DiskId         | Should -Be $disk.UniqueId
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.FSLabel        | Should -Be $FSLabelA
                    $current.Size           | Should -Be 900MB
                    $current.FSFormat       | Should -Be 'ReFS'
                }
            }

            Context "When creating second volume on Disk Unique Id $($disk.UniqueId)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterB
                                    DiskId         = $disk.UniqueId
                                    DiskIdType     = 'UniqueId'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelB
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.UniqueId
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.DriveLetter    | Should -Be $driveLetterB
                    $current.FSLabel        | Should -Be $FSLabelB
                    $current.Size           | Should -Be 96337920
                }
            }

            # A system partition will have been added to the disk as well as the 2 test partitions
            It 'Should have 3 partitions on disk' {
                ($disk | Get-Partition).Count | Should -Be 3
            }

            It "Should have attached drive $driveLetterA" {
                Get-PSDrive -Name $driveLetterA -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It "Should have attached drive $driveLetterB" {
                Get-PSDrive -Name $driveLetterB -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            AfterAll {
                $null = Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
                $null = Remove-Item -Path $VHDPath -Force
            }
        }
        #endregion

        #region Integration Tests for Disk Guid
        Context 'When partitioning and formating a newly provisioned disk using Guid with two volumes and assign Drive Letters' {
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

            Context "When creating the first volume on Disk Guid $($disk.Guid)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.Guid
                                    DiskIdType     = 'Guid'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelA
                                    Size           = 100MB
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.Guid
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.FSLabel        | Should -Be $FSLabelA
                    $current.Size           | Should -Be 100MB
                }
            }

            Context "When creating the first volume on Disk Guid $($disk.Guid)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterB
                                    DiskId         = $disk.Guid
                                    DiskIdType     = 'Guid'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelB
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.Guid
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.DriveLetter    | Should -Be $driveLetterB
                    $current.FSLabel        | Should -Be $FSLabelB
                    $current.Size           | Should -Be 935198720
                }
            }

            # A system partition will have been added to the disk as well as the 2 test partitions
            It 'Should have 3 partitions on disk' {
                ($disk | Get-Partition).Count | Should -Be 3
            }

            It "Should have attached drive $driveLetterA" {
                Get-PSDrive -Name $driveLetterA -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It "Should have attached drive $driveLetterB" {
                Get-PSDrive -Name $driveLetterB -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            AfterAll {
                $null = Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
                $null = Remove-Item -Path $VHDPath -Force
            }
        }
        #endregion

        #region Integration Tests for DiskNumber to test if a single disk with a volume using the whole disk can be remounted
        Context 'When partitioning a disk using Disk Number with a single volume using the whole disk, dismounting the volume then reprovisioning it' {
            BeforeAll {
                # Create a VHD and attach it to the computer
                $VHDPath = Join-Path -Path $TestDrive `
                    -ChildPath 'TestDisk.vhd'
                $null = New-VDisk -Path $VHDPath -SizeInMB 1024
                $null = Mount-DiskImage -ImagePath $VHDPath -StorageType VHD -NoDriveLetter
                $diskImage = Get-DiskImage -ImagePath $VHDPath
                $disk = Get-Disk -Number $diskImage.Number
                $FSLabelA = 'TestDiskA'

                # Get a spare drive letters
                $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
                $driveLetterA = [char](([int][char]$lastDrive) + 1)
            }

            Context "When creating the first volume on Disk Number $($disk.Number)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.Number
                                    DiskIdType     = 'Number'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelA
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.Number
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.FSLabel        | Should -Be $FSLabelA
                }
            }

            # This test will ensure the disk can be remounted if it uses all space
            Remove-PartitionAccessPath `
                -DiskNumber $disk.Number `
                -PartitionNumber 2 `
                -AccessPath "$($driveLetterA):"

            Context "When attaching the first volume on Disk Number $($disk.Number)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.Number
                                    DiskIdType     = 'Number'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelA
                                }
                            )
                        }

                        & "$($script:DSCResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData

                        Start-DscConfiguration `
                            -Path $TestDrive `
                            -ComputerName localhost `
                            -Wait `
                            -Verbose `
                            -Force `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = $script:currentConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.Number
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.FSLabel        | Should -Be $FSLabelA
                }
            }

            # A system partition will have been added to the disk as well as the test partition
            It 'Should have 2 partitions on disk' {
                ($disk | Get-Partition).Count | Should -Be 2
            }

            <#
                Get a list of all drives mounted - this works better on Windows Server 2012 R2 than
                trying to get the drive mounted by name.
            #>
            $drives = Get-PSDrive

            It "Should have attached drive $driveLetterA" {
                $drives | Where-Object -Property Name -eq $driveLetterA | Should -Not -BeNullOrEmpty
            }

            AfterAll {
                Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
                Remove-Item -Path $VHDPath -Force
            }
        }
        #endregion
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
