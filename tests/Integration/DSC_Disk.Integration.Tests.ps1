[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'Disk'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'StorageDsc'
    $script:dscResourceFriendlyName = 'Disk'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe "$($script:dscResourceName)_Integration" {
    BeforeAll {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop
    }

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

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
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

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.DiskId         | Should -Be $disk.Number
                $current.DriveLetter    | Should -Be $driveLetterB
                $current.FSLabel        | Should -Be $FSLabelB
                $current.PartitionStyle | Should -Be 'GPT'
                <#
                        The size of the volume differs depending on OS.
                        - Windows Server 2016: 935198720
                        - Windows Server 2019: 952041472

                        The reason for this difference is not known, but Get-PartitionSupportedSize
                        does return correct and expected values for each OS.
                    #>
                $current.Size           | Should -BeIn @(935198720, 952041472)
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

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
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

                    & "$($script:dscResourceName)_ConfigAllowDestructive" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_ConfigAllowDestructive"
                }
                $current.DiskId         | Should -Be $disk.Number
                $current.DriveLetter    | Should -Be $driveLetterA
                $current.PartitionStyle | Should -Be 'GPT'
                $current.FSLabel        | Should -Be $FSLabelA
                $current.FSFormat       | Should -Be 'NTFS'
                <#
                        The size of the volume differs depending on OS.
                        - Windows Server 2016: 1040104960
                        - Windows Server 2019: 1056947712

                        The reason for this difference is not known, but Get-PartitionSupportedSize
                        does return correct and expected values for each OS.
                    #>
                $current.Size           | Should -BeIn @(1040104960, 1056947712)
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

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
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

                    & "$($script:dscResourceName)_ConfigClearDisk" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_ConfigClearDisk"
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

    Context 'When partitioning and formatting a newly provisioned disk using FriendlyName with two volumes and assigning Drive Letters' {
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

        Context "When creating the first volume on Disk Friendly Name $($disk.FriendlyName)" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName       = 'localhost'
                                DriveLetter    = $driveLetterA
                                DiskId         = $disk.FriendlyName
                                DiskIdType     = 'FriendlyName'
                                PartitionStyle = 'GPT'
                                FSLabel        = $FSLabelA
                                Size           = 100MB
                            }
                        )
                    }

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.DiskId         | Should -Be $disk.FriendlyName
                $current.DriveLetter    | Should -Be $driveLetterA
                $current.PartitionStyle | Should -Be 'GPT'
                $current.FSLabel        | Should -Be $FSLabelA
                $current.Size           | Should -Be 100MB
            }
        }

        Context "When resizing the first volume on Disk Friendly Name $($disk.FriendlyName) and allowing the disk to be cleared" {
            <#
                    There is an issue with Format-Volume that occurs when formatting a volume
                    with ReFS in Windows Server 2019 (build 17763 and above). Therefore on
                    Windows Server 2019 the integration tests will use NTFS only.
                    See Issue #227: https://github.com/dsccommunity/StorageDsc/issues/227
                #>
            if ((Get-CimInstance -ClassName WIN32_OperatingSystem).BuildNumber -ge 17763)
            {
                $FSFormat = 'NTFS'
            }
            else
            {
                $FSFormat = 'ReFS'
            }

            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName       = 'localhost'
                                DriveLetter    = $driveLetterA
                                DiskId         = $disk.FriendlyName
                                DiskIdType     = 'FriendlyName'
                                PartitionStyle = 'GPT'
                                FSLabel        = $FSLabelA
                                Size           = 900MB
                                FSFormat       = $FSFormat
                            }
                        )
                    }

                    & "$($script:dscResourceName)_ConfigClearDisk" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_ConfigClearDisk"
                }
                $current.DiskId         | Should -Be $disk.FriendlyName
                $current.DriveLetter    | Should -Be $driveLetterA
                $current.PartitionStyle | Should -Be 'GPT'
                $current.FSLabel        | Should -Be $FSLabelA
                $current.Size           | Should -Be 900MB
                $current.FSFormat       | Should -Be $FSFormat
            }
        }

        Context "When creating second volume on Disk Friendly Name $($disk.FriendlyName)" {
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName       = 'localhost'
                                DriveLetter    = $driveLetterB
                                DiskId         = $disk.FriendlyName
                                DiskIdType     = 'FriendlyName'
                                PartitionStyle = 'GPT'
                                FSLabel        = $FSLabelB
                            }
                        )
                    }

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.DiskId         | Should -Be $disk.FriendlyName
                $current.PartitionStyle | Should -Be 'GPT'
                $current.DriveLetter    | Should -Be $driveLetterB
                $current.FSLabel        | Should -Be $FSLabelB
                <#
                        The size of the volume differs depending on OS.
                        - Windows Server 2016: 96337920
                        - Windows Server 2019: 113180672
                        The reason for this difference is not known, but Get-PartitionSupportedSize
                        does return correct and expected values for each OS.
                    #>
                $current.Size           | Should -BeIn @(96337920, 113180672)
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

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.DiskId         | Should -Be $disk.UniqueId
                $current.DriveLetter    | Should -Be $driveLetterA
                $current.PartitionStyle | Should -Be 'GPT'
                $current.FSLabel        | Should -Be $FSLabelA
                $current.Size           | Should -Be 100MB
            }
        }

        Context "When resizing the first volume on Disk Unique Id $($disk.UniqueId) and allowing the disk to be cleared" {
            <#
                    There is an issue with Format-Volume that occurs when formatting a volume
                    with ReFS in Windows Server 2019 (build 17763 and above). Therefore on
                    Windows Server 2019 the integration tests will use NTFS only.

                    See Issue #227: https://github.com/dsccommunity/StorageDsc/issues/227
                #>
            if ((Get-CimInstance -ClassName WIN32_OperatingSystem).BuildNumber -ge 17763)
            {
                $FSFormat = 'NTFS'
            }
            else
            {
                $FSFormat = 'ReFS'
            }

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
                                FSFormat       = $FSFormat
                            }
                        )
                    }

                    & "$($script:dscResourceName)_ConfigClearDisk" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_ConfigClearDisk"
                }
                $current.DiskId         | Should -Be $disk.UniqueId
                $current.DriveLetter    | Should -Be $driveLetterA
                $current.PartitionStyle | Should -Be 'GPT'
                $current.FSLabel        | Should -Be $FSLabelA
                $current.Size           | Should -Be 900MB
                $current.FSFormat       | Should -Be $FSFormat
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

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.DiskId         | Should -Be $disk.UniqueId
                $current.PartitionStyle | Should -Be 'GPT'
                $current.DriveLetter    | Should -Be $driveLetterB
                $current.FSLabel        | Should -Be $FSLabelB
                <#
                        The size of the volume differs depending on OS.
                        - Windows Server 2016: 96337920
                        - Windows Server 2019: 113180672

                        The reason for this difference is not known, but Get-PartitionSupportedSize
                        does return correct and expected values for each OS.
                    #>
                $current.Size           | Should -BeIn @(96337920, 113180672)
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

    <#
    Integration tests are disabled for the Disk resource when being tested with 'DiskIdType' set to 'SerialNumber'
    because the Virtual Disk VHD that is created always has a blank SerialNumber.
    To test manually, use a physical/logical disk that has a SerialNumber.
#>
    if ($false)
    {
        Context 'When partitioning and formatting a newly provisioned disk using SerialNumber with two volumes and assigning Drive Letters' {
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

            Context "When creating the first volume on Disk Serial Number $($disk.SerialNumber)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.SerialNumber
                                    DiskIdType     = 'SerialNumber'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelA
                                    Size           = 100MB
                                }
                            )
                        }

                        & "$($script:dscResourceName)_Config" `
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
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.SerialNumber
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.FSLabel        | Should -Be $FSLabelA
                    $current.Size           | Should -Be 100MB
                }
            }

            Context "When resizing the first volume on Disk Serial Number $($disk.SerialNumber) and allowing the disk to be cleared" {
                <#
                        There is an issue with Format-Volume that occurs when formatting a volume
                        with ReFS in Windows Server 2019 (build 17763 and above). Therefore on
                        Windows Server 2019 the integration tests will use NTFS only.
                        See Issue #227: https://github.com/dsccommunity/StorageDsc/issues/227
                    #>
                if ((Get-CimInstance -ClassName WIN32_OperatingSystem).BuildNumber -ge 17763)
                {
                    $FSFormat = 'NTFS'
                }
                else
                {
                    $FSFormat = 'ReFS'
                }

                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterA
                                    DiskId         = $disk.SerialNumber
                                    DiskIdType     = 'SerialNumber'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelA
                                    Size           = 900MB
                                    FSFormat       = $FSFormat
                                }
                            )
                        }

                        & "$($script:dscResourceName)_ConfigClearDisk" `
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
                        $_.ConfigurationName -eq "$($script:dscResourceName)_ConfigClearDisk"
                    }
                    $current.DiskId         | Should -Be $disk.SerialNumber
                    $current.DriveLetter    | Should -Be $driveLetterA
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.FSLabel        | Should -Be $FSLabelA
                    $current.Size           | Should -Be 900MB
                    $current.FSFormat       | Should -Be $FSFormat
                }
            }

            Context "When creating second volume on Disk Serial Number $($disk.SerialNumber)" {
                It 'Should compile and apply the MOF without throwing' {
                    {
                        # This is to pass to the Config
                        $configData = @{
                            AllNodes = @(
                                @{
                                    NodeName       = 'localhost'
                                    DriveLetter    = $driveLetterB
                                    DiskId         = $disk.SerialNumber
                                    DiskIdType     = 'SerialNumber'
                                    PartitionStyle = 'GPT'
                                    FSLabel        = $FSLabelB
                                }
                            )
                        }

                        & "$($script:dscResourceName)_Config" `
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
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }
                    $current.DiskId         | Should -Be $disk.SerialNumber
                    $current.PartitionStyle | Should -Be 'GPT'
                    $current.DriveLetter    | Should -Be $driveLetterB
                    $current.FSLabel        | Should -Be $FSLabelB
                    <#
                            The size of the volume differs depending on OS.
                            - Windows Server 2016: 96337920
                            - Windows Server 2019: 113180672
                            The reason for this difference is not known, but Get-PartitionSupportedSize
                            does return correct and expected values for each OS.
                        #>
                    $current.Size           | Should -BeIn @(96337920, 113180672)
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
    }

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

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
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

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.DiskId         | Should -Be $disk.Guid
                $current.PartitionStyle | Should -Be 'GPT'
                $current.DriveLetter    | Should -Be $driveLetterB
                $current.FSLabel        | Should -Be $FSLabelB
                <#
                        The size of the volume differs depending on OS.
                        - Windows Server 2016: 935198720
                        - Windows Server 2019: 952041472

                        The reason for this difference is not known, but Get-PartitionSupportedSize
                        does return correct and expected values for each OS.
                    #>
                $current.Size           | Should -BeIn @(935198720, 952041472)
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

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
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

                    & "$($script:dscResourceName)_Config" `
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
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
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

    Context 'When maximum size is used, Test-TargetResource needs to report true even though Size and SizeMax are different.' {
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

        Context "When using fixed size Disk Number $($disk.Number)" {
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

                    & "$($script:dscResourceName)_Config" `
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

            It 'Should have set the resource and size should match' {
                $current = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.Size         | Should -Be 100MB
            }
        }

        Context "When using maximum size for new volume on Disk Number $($disk.Number)" {
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

                    & "$($script:dscResourceName)_Config" `
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

            It 'Test-DscConfiguration should return True, indicating that partition size instead of SizeMax was used' {
                Test-DscConfiguration | Should -Be $true
            }
        }

        AfterAll {
            Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
            Remove-Item -Path $VHDPath -Force
        }
    }
}
