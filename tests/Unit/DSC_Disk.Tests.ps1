# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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
}

BeforeAll {
    $script:dscModuleName = 'StorageDsc'
    $script:dscResourceName = 'DSC_Disk'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_Disk\Get-TargetResource' -Tag 'Get' {
    Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be $testParams.DiskId
                $result.PartitionStyle | Should -Be 'GPT'
                $result.DriveLetter | Should -Be $testParams.DriveLetter
                $result.Size | Should -Be 1GB
                $result.FSLabel | Should -Be 'myLabel'
                $result.AllocationUnitSize | Should -Be 4096
                $result.FSFormat | Should -Be 'NTFS'
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Number with partition reported twice' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                <#
                    This condition seems to occur in some systems where the
                    same partition is reported twice with the same drive letter.
                #>
                @(
                    [PSCustomObject] @{
                        DriveLetter     = [System.Char] 'G'
                        Size            = 1GB
                        PartitionNumber = 1
                        Type            = 'Basic'
                    },
                    [PSCustomObject] @{
                        DriveLetter     = [System.Char] 'G'
                        Size            = 1GB
                        PartitionNumber = 1
                        Type            = 'Basic'
                    }
                )
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be $testParams.DiskId
                $result.PartitionStyle | Should -Be 'GPT'
                $result.DriveLetter | Should -Be $testParams.DriveLetter
                $result.Size | Should -Be 1GB
                $result.FSLabel | Should -Be 'myLabel'
                $result.AllocationUnitSize | Should -Be 4096
                $result.FSFormat | Should -Be 'NTFS'
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Unique Id' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 'TESTDISKUNIQUEID'
                    DiskIdType  = 'UniqueId'
                    DriveLetter = 'G'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be $testParams.DiskId
                $result.PartitionStyle | Should -Be 'GPT'
                $result.DriveLetter | Should -Be $testParams.DriveLetter
                $result.Size | Should -Be 1GB
                $result.FSLabel | Should -Be 'myLabel'
                $result.AllocationUnitSize | Should -Be 4096
                $result.FSFormat | Should -Be 'NTFS'
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Friendly Name' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 'TESTDISKFRIENDLYNAME'
                    DiskIdType  = 'FriendlyName'
                    DriveLetter = 'G'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be $testParams.DiskId
                $result.PartitionStyle | Should -Be 'GPT'
                $result.DriveLetter | Should -Be $testParams.DriveLetter
                $result.Size | Should -Be 1GB
                $result.FSLabel | Should -Be 'myLabel'
                $result.AllocationUnitSize | Should -Be 4096
                $result.FSFormat | Should -Be 'NTFS'
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Serial Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 'TESTDISKSERIALNUMBER'
                    DiskIdType  = 'SerialNumber'
                    DriveLetter = 'G'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be $testParams.DiskId
                $result.PartitionStyle | Should -Be 'GPT'
                $result.DriveLetter | Should -Be $testParams.DriveLetter
                $result.Size | Should -Be 1GB
                $result.FSLabel | Should -Be 'myLabel'
                $result.AllocationUnitSize | Should -Be 4096
                $result.FSFormat | Should -Be 'NTFS'
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Guid' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = 'f4db9c62-d626-43dc-98f0-ca1c171c1f9b'
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 'f4db9c62-d626-43dc-98f0-ca1c171c1f9b'
                    DiskIdType  = 'Guid'
                    DriveLetter = 'G'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be $testParams.DiskId
                $result.PartitionStyle | Should -Be 'GPT'
                $result.DriveLetter | Should -Be $testParams.DriveLetter
                $result.Size | Should -Be 1GB
                $result.FSLabel | Should -Be 'myLabel'
                $result.AllocationUnitSize | Should -Be 4096
                $result.FSFormat | Should -Be 'NTFS'
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Guid' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = '4a8e9434-8e88-4bfa-aa85-dc268cd9ed2a'
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = '4a8e9434-8e88-4bfa-aa85-dc268cd9ed2a'
                    DiskIdType  = 'Guid'
                    DriveLetter = 'G'
                }

                $results = Get-TargetResource @testParams

                $results.DiskId | Should -Be $testParams.DiskId
                $results.PartitionStyle | Should -Be 'GPT'
                $results.DriveLetter | Should -Be $testParams.DriveLetter
                $results.Size | Should -Be 1GB
                $results.FSLabel | Should -Be 'myLabel'
                $results.AllocationUnitSize | Should -Be 4096
                $results.FSFormat | Should -Be 'NTFS'
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with no partition using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance
            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition
            Mock -CommandName Get-Volume
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be $testParams.DiskId
                $result.PartitionStyle | Should -Be 'GPT'
                $result.DriveLetter | Should -BeNullOrEmpty
                $result.Size | Should -BeNullOrEmpty
                $result.FSLabel | Should -BeNullOrEmpty
                $result.AllocationUnitSize | Should -BeNullOrEmpty
                $result.FSFormat | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online MBR disk with no partition using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance
            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = ''
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'MBR'
                }
            }

            Mock -CommandName Get-Partition
            Mock -CommandName Get-Volume
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be $testParams.DiskId
                $result.PartitionStyle | Should -Be 'MBR'
                $result.DriveLetter | Should -BeNullOrEmpty
                $result.Size | Should -BeNullOrEmpty
                $result.FSLabel | Should -BeNullOrEmpty
                $result.AllocationUnitSize | Should -BeNullOrEmpty
                $result.FSFormat | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online RAW disk with no partition using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance
            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = ''
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'RAW'
                }
            }

            Mock -CommandName Get-Partition
            Mock -CommandName Get-Volume
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be $testParams.DiskId
                $result.PartitionStyle | Should -Be 'RAW'
                $result.DriveLetter | Should -BeNullOrEmpty
                $result.Size | Should -BeNullOrEmpty
                $result.FSLabel | Should -BeNullOrEmpty
                $result.AllocationUnitSize | Should -BeNullOrEmpty
                $result.FSFormat | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When volume on partition is a Dev Drive volume' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'ReFS'
                    DriveLetter     = 'G'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                }
            }

            Mock -CommandName Test-DevDriveVolume -MockWith { $true }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                $result = Get-TargetResource @testParams

                $result.DevDrive | Should -BeTrue
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-DevDriveVolume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When volume on partition is not a Dev Drive volume' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'T'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                    Size            = 50GB
                }
            }

            Mock -CommandName Test-DevDriveVolume -MockWith { $false }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                $result = Get-TargetResource @testParams

                $result.DevDrive | Should -BeFalse
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-DevDriveVolume -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_Disk\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            <#
                    These functions are required to be able to mock functions where
                    values are passed in via the pipeline.
                #>
            function script:Set-Disk
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    $InputObject,

                    [Parameter()]
                    [System.Boolean]
                    $IsOffline,

                    [Parameter()]
                    [System.Boolean]
                    $IsReadOnly
                )
            }

            function script:Clear-Disk
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    $Disk,

                    [Parameter()]
                    [System.UInt32]
                    $Number,

                    [Parameter()]
                    [System.String]
                    $UniqueID,

                    [Parameter()]
                    [System.String]
                    $FriendlyName,

                    [Parameter()]
                    [System.Boolean]
                    $Confirm,

                    [Parameter()]
                    [Switch]
                    $RemoveData,

                    [Parameter()]
                    [Switch]
                    $RemoveOEM
                )
            }

            function script:Initialize-Disk
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    $InputObject,

                    [Parameter()]
                    [System.String]
                    $PartitionStyle
                )
            }

            function script:Get-Partition
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    $Disk,

                    [Parameter()]
                    [System.String]
                    $DriveLetter,

                    [Parameter()]
                    [System.UInt32]
                    $DiskNumber,

                    [Parameter()]
                    [System.UInt32]
                    $PartitionNumber
                )
            }

            function script:Get-Volume
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    $Partition,

                    [Parameter()]
                    [System.String]
                    $DriveLetter
                )
            }

            function script:Resize-Partition
            {
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    [System.String]
                    $DriveLetter,

                    [Parameter()]
                    [System.UInt64]
                    $Size
                )
            }

            function script:New-Partition
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    $Disk,

                    [Parameter()]
                    [System.String]
                    $DriveLetter,

                    [Parameter()]
                    [System.Boolean]
                    $UseMaximumSize,

                    [Parameter()]
                    [System.UInt64]
                    $Size
                )
            }

            function script:Get-PartitionSupportedSize
            {
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    [System.String]
                    $DriveLetter
                )
            }

            function script:Format-Volume
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    $Partition,

                    [Parameter()]
                    [System.String]
                    $DriveLetter,

                    [Parameter()]
                    [System.String]
                    $FileSystem,

                    [Parameter()]
                    [System.Boolean]
                    $Confirm,

                    [Parameter()]
                    [System.String]
                    $NewFileSystemLabel,

                    [Parameter()]
                    [System.UInt32]
                    $AllocationUnitSize,

                    [Parameter()]
                    [Switch]
                    $Force,

                    [Parameter()]
                    [System.Boolean]
                    $DevDrive
                )
            }

            function script:Set-Volume
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    $InputObject,

                    [Parameter()]
                    [System.String]
                    $NewFileSystemLabel
                )
            }

            function script:Set-Partition
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    $Disk,

                    [Parameter()]
                    [System.String]
                    $DriveLetter,

                    [Parameter()]
                    [System.String]
                    $NewDriveLetter
                )
            }
        }
    }

    Context 'When offline GPT disk using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When offline GPT disk using Disk Unique Id' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 'TESTDISKUNIQUEID'
                    DiskIdType  = 'UniqueId'
                    DriveLetter = 'G'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When offline GPT disk using Disk Friendly Name' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Initialize-Disk
        }
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 'TESTDISKFRIENDLYNAME'
                    DiskIdType  = 'FriendlyName'
                    DriveLetter = 'G'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When offline GPT disk using Disk Serial Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 'TESTDISKSERIALNUMBER'
                    DiskIdType  = 'SerialNumber'
                    DriveLetter = 'G'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When offline GPT disk using Disk Guid' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = 'e8527184-01ee-43ed-bfb3-6c8cd8afbf0b'
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 'e8527184-01ee-43ed-bfb3-6c8cd8afbf0b'
                    DiskIdType  = 'Guid'
                    DriveLetter = 'G'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When readonly GPT disk using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $true
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When offline RAW disk using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = ''
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'RAW'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online RAW disk with Size using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = ''
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'RAW'
                }
            }

            Mock -CommandName Initialize-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Set-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    Size               = 1GB
                    AllocationUnitSize = 64
                    FSLabel            = 'MyDisk'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with no partitions using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with no partitions using Disk Number, partition fails to become writeable' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $true
                }
            }

            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $true
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName Set-Volume
            Mock -CommandName Get-Volume
            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition
        }

        It 'Should throw NewPartitionIsReadOnlyError' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                $script:startTime = Get-Date

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.NewPartitionIsReadOnlyError -f 'Number', $testParams.DiskId, 1
                )

                { Set-TargetResource @testParams } | Should -Throw $errorRecord

                $script:endTime = Get-Date
            }
        }

        It 'Should take at least 30s' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                ($endTime - $startTime).TotalSeconds | Should -BeGreaterThan 29
            }
        }

        It 'Should call the correct mocks' {
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope Context
            <#
                Get-Partition will be called multiple times, but depending on
                performance of the call to Get-Partition, it may be called a
                different number of times.
                E.g. on Azure DevOps agents running Windows Server 2016 it is
                called at least 28 times.
            #>
            Should -Invoke -CommandName Get-Partition -Times 1 -Scope Context
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-Volume -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-Partition -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When online GPT disk with no partitions using Disk Number, partition is writable' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName Set-Volume
            Mock -CommandName Get-Volume
            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:startTime = Get-Date

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw

                $script:endTime = Get-Date
            }
        }

        It 'Should take at least 3s' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                ($endTime - $startTime).TotalSeconds | Should -BeGreaterThan 2
            }
        }

        It 'Should call the correct mocks' {
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope Context
            Should -Invoke -CommandName Get-Volume -Exactly -Times 2 -Scope Context
            Should -Invoke -CommandName New-Partition -Exactly -Times 1  -Scope Context
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-Volume -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When online MBR disk using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = ''
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'MBR'
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Get-Volume
            Mock -CommandName Set-Partition
        }

        It 'Should not throw DiskInitializedWithWrongPartitionStyleError' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DiskInitializedWithWrongPartitionStyleError -f 'Number', $testParams.DiskId, 'MBR', 'GPT'
                )

                { Set-TargetResource @testParams } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 0 -Scope It
        }
    }

    Context 'When online MBR disk using Disk Unique Id but GPT required and AllowDestructive and ClearDisk are false' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = ''
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'MBR'
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Get-Volume
            Mock -CommandName Set-Partition
        }

        It 'Should throw DiskInitializedWithWrongPartitionStyleError' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 'TESTDISKUNIQUEID'
                    DiskIdType  = 'UniqueId'
                    DriveLetter = 'G'
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DiskInitializedWithWrongPartitionStyleError -f 'UniqueId', 'TESTDISKUNIQUEID', 'MBR', 'GPT'
                )

                { Set-TargetResource @testParams } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 0 -Scope It
        }
    }

    Context 'When online GPT disk with partition/volume already assigned using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 0 -Scope It
        }
    }

    Context 'When online GPT disk containing matching partition but not assigned using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                    Size        = 1GB
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with a partition/volume and wrong Drive Letter assigned using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'H'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName New-Partition -ParameterFilter {
                $DriveLetter -eq 'H'
            } -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'H'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with a partition/volume and no Drive Letter assigned using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'H'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'H'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When online GPT disk with a partition/volume and wrong Volume Label assigned using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Set-Volume

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                    FSLabel     = 'NewLabel'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume without assigned drive letter and wrong size' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] $null
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = ''
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition
            Mock -CommandName Resize-Partition
            Mock -CommandName Get-PartitionSupportedSize
            Mock -CommandName Set-Volume
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId           = 1
                    DriveLetter      = 'G'
                    Size             = (1GB + 1024)
                    AllowDestructive = $true
                    FSLabel          = 'NewLabel'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Volume -Exactly -Times 0 -Scope It
        }
    }

    Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume but wrong size and remaining size too small' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-PartitionSupportedSize -MockWith {
                return @{
                    SizeMin = 0
                    SizeMax = 1
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition
            Mock -CommandName Get-Volume
            Mock -CommandName Set-Volume
            Mock -CommandName Resize-Partition
        }

        It 'Should throw FreeSpaceViolationError' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId           = 1
                    DriveLetter      = 'G'
                    Size             = (1GB + 1024)
                    AllowDestructive = $true
                    FSLabel          = 'NewLabel'
                }

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.FreeSpaceViolationError -f $testParams.DriveLetter, 1GB, $testParams.Size, 1
                ) -ArgumentName 'Size'

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage ('*' + $errorRecord)
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-PartitionSupportedSize -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Resize-Partition -Exactly -Times 0 -Scope It
        }
    }

    Context 'When AllowDestructive enabled with Size not specified on Online GPT disk with matching partition/volume but wrong size' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-PartitionSupportedSize -MockWith {
                return @{
                    SizeMin = 0
                    SizeMax = 2GB
                }
            }

            Mock -CommandName Resize-Partition
            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Set-Volume

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Set-Partition
            Mock -CommandName Format-Volume
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId           = 1
                    DriveLetter      = 'G'
                    AllowDestructive = $true
                    FSLabel          = 'NewLabel'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-PartitionSupportedSize -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Resize-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume but wrong size and ReFS' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'ReFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Set-Volume
            Mock -CommandName Get-PartitionSupportedSize -MockWith {
                return @{
                    SizeMin = 0
                    SizeMax = 1
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition
            Mock -CommandName Resize-Partition
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId           = 1
                    DriveLetter      = 'G'
                    Size             = (1GB + 1024)
                    AllowDestructive = $true
                    FSLabel          = 'NewLabel'
                    FSFormat         = 'ReFS'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-PartitionSupportedSize -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Resize-Partition -Exactly -Times 0 -Scope It
        }
    }

    Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume but wrong format' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Set-Volume
            Mock -CommandName Format-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Set-Partition
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId           = 1
                    DriveLetter      = 'G'
                    Size             = 1GB
                    FSFormat         = 'ReFS'
                    FSLabel          = 'NewLabel'
                    AllowDestructive = $true
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When AllowDestructive and ClearDisk enabled with Online GPT disk containing arbitrary partitions' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Set-Volume
            Mock -CommandName Clear-Disk

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId           = 1
                    DriveLetter      = 'G'
                    Size             = 1GB
                    FSLabel          = 'NewLabel'
                    AllowDestructive = $true
                    ClearDisk        = $true
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Clear-Disk -Exactly -Times 1 -Scope It
        }
    }

    Context 'When AllowDestructive and ClearDisk enabled with Online MBR disk containing arbitrary partitions but GPT required' {
        BeforeAll {
            <#
                This variable is so that we can change the behavior of the
                Get-DiskByIdentifier mock after the first time it is called
                in the Set-TargetResource function.
            #>
            $script:getDiskByIdentifierCalled = $false

            Mock -CommandName Get-DiskByIdentifier -ParameterFilter {
                $script:getDiskByIdentifierCalled -eq $false
            } -MockWith {
                $script:getDiskByIdentifierCalled = $true

                return [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = ''
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'MBR'
                }
            }

            Mock -CommandName Get-DiskByIdentifier -ParameterFilter {
                $script:getDiskByIdentifierCalled -eq $true
            } -MockWith {
                return [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = ''
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'RAW'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Set-Volume
            Mock -CommandName Clear-Disk

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Set-Partition
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId           = 1
                    DriveLetter      = 'G'
                    Size             = 1GB
                    FSLabel          = 'NewLabel'
                    AllowDestructive = $true
                    ClearDisk        = $true
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 3 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Clear-Disk -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DevDrive flag is true, the AllowDestructive flag is false and there is not enough space on the disk to create the partition' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'T'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                <#
                    Used in the scenario where a user wants to create a Dev Drive volume but there
                    is insufficient unallocated space available and a resize of any partition is not possible.
                #>
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                    Size           = 60Gb
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                @(
                    [PSCustomObject] @{
                        DriveLetter     = [System.Char] 'G'
                        Size            = 50GB
                        PartitionNumber = 1
                        Type            = 'Basic'
                    }
                )
            }

            Mock -CommandName Assert-DevDriveFeatureAvailable
            Mock -CommandName Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue
            Mock -CommandName Assert-SizeMeetsMinimumDevDriveRequirement
            Mock -CommandName Get-PartitionSupportedSize -MockWith {
                [PSCustomObject] @{
                    DriveLetter = [System.Char] 'G'
                    SizeMax     = 50GB
                    SizeMin     = 50GB
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $userDesiredSizeInGb = [Math]::Round(50GB / 1GB, 2)

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'T'
                    Size        = 50GB
                    FSLabel     = 'NewLabel'
                    FSFormat    = 'ReFS'
                    DevDrive    = $true
                }

                $errorRecord = $script:localizedData.FoundNoPartitionsThatCanResizedForDevDrive -f $userDesiredSizeInGb

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage $errorRecord
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DevDrive flag is true, AllowDestructive is false and there is enough space on the disk to create the partition' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'T'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                <#
                    Used in the scenario where a user wants to create a Dev Drive volume
                    and there is sufficient unallocated space available.
                #>
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                    Size           = 100Gb
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                @(
                    [PSCustomObject] @{
                        DriveLetter     = [System.Char] 'G'
                        Size            = 50GB
                        PartitionNumber = 1
                        Type            = 'Basic'
                    },
                    [PSCustomObject] @{
                        DriveLetter     = [System.Char] 'H'
                        Size            = 50GB
                        PartitionNumber = 1
                        Type            = 'Basic'
                    }
                )
            }

            Mock -CommandName Assert-DevDriveFeatureAvailable
            Mock -CommandName Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue
            Mock -CommandName Assert-SizeMeetsMinimumDevDriveRequirement
            Mock -CommandName Test-DevDriveVolume -MockWith {
                $true
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = 'T'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                }
            }

            Mock -CommandName Get-PartitionSupportedSize -ParameterFilter {
                $DriveLetter -eq 'G'
            } -MockWith {
                [PSCustomObject] @{
                    DriveLetter = [System.Char] 'G'
                    SizeMax     = 50GB
                    SizeMin     = 50GB
                }
            }

            Mock -CommandName Get-PartitionSupportedSize -ParameterFilter {
                $DriveLetter -eq 'H'
            } -MockWith {
                [PSCustomObject] @{
                    DriveLetter = [System.Char] 'H'
                    SizeMax     = 100GB
                    SizeMin     = 10GB
                }
            }

            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'T'
                    Size            = 50GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Format-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = 'T'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'T'
                    Size        = 50GB
                    FSLabel     = 'NewLabel'
                    FSFormat    = 'ReFS'
                    DevDrive    = $true
                }

                $result = Set-TargetResource @testParams

                { $result } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-PartitionSupportedSize -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It -ParameterFilter {
                $DevDrive -eq $true
            }
        }
    }

    Context 'When the DevDrive flag is true, AllowDestructive flag is false and there is not enough unallocated disk space but a resize of a partition is possible to create new space' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'T'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                <#
                    Used in the scenario where a user wants to create a Dev Drive volume but there
                    is insufficient unallocated space available. However a resize of a partition possible.
                    which will create new unallocated space for the new partition.
                #>
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                    Size           = 100Gb
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                @(
                    [PSCustomObject] @{
                        DriveLetter     = [System.Char] 'G'
                        Size            = 50GB
                        PartitionNumber = 1
                        Type            = 'Basic'
                    },
                    [PSCustomObject] @{
                        DriveLetter     = [System.Char] 'K'
                        Size            = 70GB
                        PartitionNumber = 1
                        Type            = 'Basic'
                    }
                )
            }

            Mock -CommandName Assert-DevDriveFeatureAvailable
            Mock -CommandName Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue
            Mock -CommandName Assert-SizeMeetsMinimumDevDriveRequirement
            Mock -CommandName Get-PartitionSupportedSize -ParameterFilter {
                $DriveLetter -eq 'G'
            } -MockWith {
                [PSCustomObject] @{
                    DriveLetter = [System.Char] 'G'
                    SizeMax     = 50GB
                    SizeMin     = 50GB
                }
            }

            Mock -CommandName Get-PartitionSupportedSize -ParameterFilter {
                $DriveLetter -eq 'K'
            } -MockWith {
                [PSCustomObject] @{
                    DriveLetter = [System.Char] 'K'
                    SizeMax     = 100GB
                    SizeMin     = 1GB
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
        }

        It 'Should throw an exception stating that AllowDestructive flag needs to be set to resize existing partition for DevDrive' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'T'
                    Size        = 50GB
                    FSLabel     = 'NewLabel'
                    FSFormat    = 'ReFS'
                    DevDrive    = $true
                }

                $errorMessage = $script:localizedData.AllowDestructiveNeededForDevDriveOperation -f 'K'

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage ('*' + $errorMessage)
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DevDrive flag is true, AllowDestructive flag is true and there is not enough unallocated disk space but a resize of a partition is possible to create new space' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'T'
            }

            # For resize scenario we need to call Get-DiskByIdentifier twice. After the resize a disk.FreeLargestExtent is updated.
            Mock -CommandName Get-DiskByIdentifier -MockWith {
                $script:amountOfTimesGetDiskByIdentifierIsCalled++

                if ($script:amountOfTimesGetDiskByIdentifierIsCalled -eq 1)
                {
                    <#
                        Used in the scenario where a user wants to create a Dev Drive volume but there
                        is insufficient unallocated space available. However a resize of a partition possible.
                        which will create new unallocated space for the new partition.
                    #>
                    [PSCustomObject] @{
                        Number         = 1
                        UniqueId       = 'TESTDISKUNIQUEID'
                        FriendlyName   = 'TESTDISKFRIENDLYNAME'
                        SerialNumber   = 'TESTDISKSERIALNUMBER'
                        Guid           = [guid]::NewGuid()
                        IsOffline      = $false
                        IsReadOnly     = $false
                        PartitionStyle = 'GPT'
                        Size           = 100Gb
                    }
                }
                elseif ($script:amountOfTimesGetDiskByIdentifierIsCalled -eq 2)
                {
                    [PSCustomObject] @{
                        Number            = 1
                        UniqueId          = 'TESTDISKUNIQUEID'
                        FriendlyName      = 'TESTDISKFRIENDLYNAME'
                        SerialNumber      = 'TESTDISKSERIALNUMBER'
                        Guid              = [guid]::NewGuid()
                        IsOffline         = $false
                        IsReadOnly        = $false
                        PartitionStyle    = 'GPT'
                        Size              = 100Gb
                        LargestFreeExtent = 50Gb
                    }
                }
                else
                {
                    <#
                        Used in the scenario where a user wants to create a Dev Drive volume but there
                        is insufficient unallocated space available. However a resize of a partition possible.
                        which will create new unallocated space for the new partition.
                    #>
                    [PSCustomObject] @{
                        Number         = 1
                        UniqueId       = 'TESTDISKUNIQUEID'
                        FriendlyName   = 'TESTDISKFRIENDLYNAME'
                        SerialNumber   = 'TESTDISKSERIALNUMBER'
                        Guid           = [guid]::NewGuid()
                        IsOffline      = $false
                        IsReadOnly     = $false
                        PartitionStyle = 'GPT'
                        Size           = 100Gb
                    }
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                @(
                    [PSCustomObject] @{
                        DriveLetter     = [System.Char] 'G'
                        Size            = 50GB
                        PartitionNumber = 1
                        Type            = 'Basic'
                    },
                    [PSCustomObject] @{
                        DriveLetter     = [System.Char] 'K'
                        Size            = 70GB
                        PartitionNumber = 1
                        Type            = 'Basic'
                    }
                )
            }

            Mock -CommandName Assert-DevDriveFeatureAvailable
            Mock -CommandName Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue
            Mock -CommandName Assert-SizeMeetsMinimumDevDriveRequirement
            Mock -CommandName Get-PartitionSupportedSize -ParameterFilter {
                $DriveLetter -eq 'G'
            } -MockWith {
                [PSCustomObject] @{
                    DriveLetter = [System.Char] 'G'
                    SizeMax     = 50GB
                    SizeMin     = 50GB
                }
            }

            Mock -CommandName Get-PartitionSupportedSize -ParameterFilter {
                $DriveLetter -eq 'K'
            } -MockWith {
                [PSCustomObject] @{
                    DriveLetter = [System.Char] 'K'
                    SizeMax     = 100GB
                    SizeMin     = 1GB
                }
            }

            Mock -CommandName Test-DevDriveVolume -MockWith {
                $true
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = 'T'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                }
            }

            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'T'
                    Size            = 50GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Resize-Partition
            Mock -CommandName Format-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                    DriveLetter     = 'T'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:amountOfTimesGetDiskByIdentifierIsCalled = 0

                $testParams = @{
                    DiskId           = 1
                    DriveLetter      = 'T'
                    Size             = 50GB
                    FSLabel          = 'NewLabel'
                    FSFormat         = 'ReFS'
                    DevDrive         = $true
                    AllowDestructive = $true
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 4 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Resize-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It -ParameterFilter {
                $DevDrive -eq $true
            }

            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DevDrive flag is true, AllowDestructive is true, and a Partition that matches the users drive letter exists' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'T'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                    Size           = 100Gb
                }
            }

            Mock -CommandName Test-DevDriveVolume -MockWith {
                $true
            }

            Mock -CommandName Get-PartitionSupportedSize -MockWith {
                [PSCustomObject] @{
                    DriveLetter = [System.Char] 'T'
                    SizeMax     = 100GB
                    SizeMin     = 10GB
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'T'
                    Size            = 50GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'T'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                    Size            = 50GB
                }
            }

            Mock -CommandName Format-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'T'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                    Size            = 50GB
                }
            }

            Mock -CommandName Assert-DevDriveFeatureAvailable

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception and overwrite the existing partition' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId           = 1
                    DriveLetter      = 'T'
                    FSLabel          = 'NewLabel'
                    FSFormat         = 'ReFS'
                    DevDrive         = $true
                    AllowDestructive = $true
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-DevDriveFeatureAvailable -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It -ParameterFilter {
                $DevDrive -eq $true
            }
        }
    }

    Context 'When the DevDrive flag is true, AllowDestructive is false, and a Partition that matches the users drive letter exists' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'T'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                <#
                    Used in the scenario where a user wants to create a Dev Drive volume
                    and there is sufficient unallocated space available.
                #>
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                    Size           = 100Gb
                }
            }

            Mock -CommandName Test-DevDriveVolume -MockWith {
                $false
            }

            Mock -CommandName Get-PartitionSupportedSize -MockWith {
                [PSCustomObject] @{
                    DriveLetter = [System.Char] 'T'
                    SizeMax     = 100GB
                    SizeMin     = 10GB
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'T'
                    Size            = 50GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'T'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                    Size            = 50GB
                }
            }

            Mock -CommandName Assert-DevDriveFeatureAvailable
            Mock -CommandName Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName Format-Volume
        }

        It 'Should throw an exception advising that the volume was not formatted as a Dev Drive volume' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'T'
                    FSLabel     = 'NewLabel'
                    FSFormat    = 'ReFS'
                    DevDrive    = $true
                }

                $errorMessage = $script:localizedData.FailedToConfigureDevDriveVolume `
                    -f '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\', 'T'

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage ('*' + $errorMessage)
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-DevDriveFeatureAvailable -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It -ParameterFilter {
                $DevDrive -eq $true
            }
        }
    }
}

Describe 'DSC_Disk\Test-TargetResource' -Tag 'Test' {
    Context 'When testing disk does not exist using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing disk offline using Disk Unique Id' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing disk offline using Unique Id' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 'TESTDISKUNIQUEID'
                    DiskIdType         = 'UniqueId'
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing disk offline using Friendly Name' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 'TESTDISKFRIENDLYNAME'
                    DiskIdType         = 'FriendlyName'
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing disk offline using Serial Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0
                $testParams = @{
                    DiskId             = 'TESTDISKSERIALNUMBER'
                    DiskIdType         = 'SerialNumber'
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing disk offline using Disk Guid' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = 'f82e9a28-430d-49ac-a633-910d9104f177'
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 'f82e9a28-430d-49ac-a633-910d9104f177'
                    DiskIdType         = 'Guid'
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing disk read only using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $true
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing online unformatted disk using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = ''
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'RAW'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing online disk using Disk Number with partition style GPT but requiring MBR' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = ''
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'MBR'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DiskInitializedWithWrongPartitionStyleError -f 'Number', $testParams.DiskId , 'MBR', 'GPT'
                )

                { Test-TargetResource @testParams } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing online disk using Disk Number with partition style MBR but requiring GPT' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    PartitionStyle     = 'MBR'
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DiskInitializedWithWrongPartitionStyleError -f 'Number',
                    $testParams.DiskId,
                    'GPT',
                    'MBR'
                )

                { Test-TargetResource @testParams } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing online disk using Disk Number with partition style MBR but requiring GPT and AllowDestructive and ClearDisk is True' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    PartitionStyle     = 'MBR'
                    AllowDestructive   = $true
                    ClearDisk          = $true
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing mismatching partition size using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    Size               = (1GB + 1MB)
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing mismatching partition size with AllowDestructive using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-PartitionSupportedSize
            Mock -CommandName Get-Volume
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    Size               = (1GB + 1MB)
                    AllowDestructive   = $true
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-PartitionSupportedSize -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing mismatching partition size without Size specified using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-PartitionSupportedSize -MockWith {
                return @{
                    SizeMin = 0
                    # Adding >1MB, otherwise workaround for wrong SizeMax is triggered
                    SizeMax = $script:mockedPartition.Size + 1.1MB
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-PartitionSupportedSize -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing mismatching partition size without Size specified using Disk Number with partition reported twice' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                <#
                    This condition seems to occur in some systems where the
                    same partition is reported twice with the same drive letter.
                #>
                @(
                    [PSCustomObject] @{
                        DriveLetter     = [System.Char] 'G'
                        Size            = 1GB
                        PartitionNumber = 1
                        Type            = 'Basic'
                    },
                    [PSCustomObject] @{
                        DriveLetter     = [System.Char] 'G'
                        Size            = 1GB
                        PartitionNumber = 1
                        Type            = 'Basic'
                    }
                )
            }

            Mock -CommandName Get-PartitionSupportedSize -MockWith {
                return @{
                    SizeMin = 0
                    # Adding >1MB, otherwise workaround for wrong SizeMax is triggered
                    SizeMax = $script:mockedPartition.Size + 1.1MB
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-PartitionSupportedSize -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing mismatching partition size with AllowDestructive and without Size specified using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-PartitionSupportedSize -MockWith {
                return @{
                    SizeMin = 0
                    # Adding >1MB, otherwise workaround for wrong SizeMax is triggered
                    SizeMax = 1GB + 1.1MB
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    AllowDestructive   = $true
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-PartitionSupportedSize -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing matching partition size with a less than 1MB difference in desired size and with AllowDestructive and without Size specified using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-PartitionSupportedSize -MockWith {
                return @{
                    SizeMin = 0
                    SizeMax = 1GB + 0.98MB
                }
            }

            Mock -CommandName Get-Volume
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    AllowDestructive   = $true
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-PartitionSupportedSize -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing mismatched AllocationUnitSize using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4097
                    AllowDestructive   = $true
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing mismatching FSFormat using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                    FSFormat    = 'ReFS'
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing mismatching FSFormat using Disk Number and AllowDestructive' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId           = 1
                    DriveLetter      = 'G'
                    FSFormat         = 'ReFS'
                    AllowDestructive = $true
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing mismatching FSLabel using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'G'
                    FSLabel     = 'NewLabel'
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing mismatching DriveLetter using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'Z'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'Z'
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When testing all disk properties matching using Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 1GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'G'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    Size               = 1GB
                    FSLabel            = 'myLabel'
                    FSFormat           = 'NTFS'
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DevDrive flag is true, and Size parameter is less than minimum required size for Dev Drive (50 Gb)' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 40GB
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Assert-SizeMeetsMinimumDevDriveRequirement -MockWith {
                throw
            }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    Size               = 40Gb
                    FSLabel            = 'myLabel'
                    FSFormat           = 'ReFS'
                    DevDrive           = $true
                    AllowDestructive   = $true
                }

                { Test-TargetResource @testParams } | Should -Throw
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-SizeMeetsMinimumDevDriveRequirement -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DevDrive flag is true, but the partition is effectively the same size as user inputted size and volume is NTFS' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 161060225024
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                    DriveLetter     = 'T'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                    Size            = 150Gb
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    Size               = 50GB
                    FSLabel            = 'myLabel'
                    FSFormat           = 'NTFS'
                    DevDrive           = $true
                    AllowDestructive   = $true
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DevDrive flag is true, but the partition is not the same size as user inputted size, volume is ReFS formatted but not Dev Drive volume' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 161060225024
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'ReFS'
                    DriveLetter     = 'T'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                    Size            = 50GB
                }
            }

            Mock -CommandName Assert-DevDriveFeatureAvailable
            Mock -CommandName Test-DevDriveVolume -MockWith { $false }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    Size               = 50GB
                    FSLabel            = 'myLabel'
                    FSFormat           = 'ReFS'
                    DevDrive           = $true
                    AllowDestructive   = $true
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Test-DevDriveVolume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-DevDriveFeatureAvailable -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DevDrive flag is true, but the partition is effectively the same size as user inputted size, volume is ReFS formatted and is Dev Drive volume' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 161060225024
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'ReFS'
                    DriveLetter     = 'G'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                }
            }

            Mock -CommandName Assert-DevDriveFeatureAvailable
            Mock -CommandName Test-DevDriveVolume -MockWith { $true }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    Size               = 50Gb
                    FSLabel            = 'myLabel'
                    FSFormat           = 'ReFS'
                    DevDrive           = $true
                    AllowDestructive   = $true
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Test-DevDriveVolume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-DevDriveFeatureAvailable -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the DevDrive flag is true, but the partition is effectively the same size as user inputted size, volume is ReFS formatted and is not Dev Drive volume' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'G'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    FriendlyName   = 'TESTDISKFRIENDLYNAME'
                    SerialNumber   = 'TESTDISKSERIALNUMBER'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    DriveLetter     = [System.Char] 'G'
                    Size            = 161060225024
                    PartitionNumber = 1
                    Type            = 'Basic'
                    IsReadOnly      = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'ReFS'
                    DriveLetter     = 'T'
                    UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                    Size            = 150Gb
                }
            }

            Mock -CommandName Assert-DevDriveFeatureAvailable
            Mock -CommandName Test-DevDriveVolume -MockWith { $false }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    DriveLetter        = 'G'
                    AllocationUnitSize = 4096
                    Size               = 50GB
                    FSLabel            = 'myLabel'
                    FSFormat           = 'ReFS'
                    DevDrive           = $true
                    AllowDestructive   = $true
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Test-DevDriveVolume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-DevDriveFeatureAvailable -Exactly -Times 1 -Scope It
        }
    }
}
