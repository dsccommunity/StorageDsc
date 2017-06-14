$script:DSCModuleName = 'xStorage'
$script:DSCResourceName = 'MSFT_xDisk'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
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
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $script:DSCResourceName {
        #region Pester Test Initialization
        $script:testDriveLetter = 'G'
        $script:testDiskUniqueId = 'TESTDISKUNIQUEID'

        $script:mockedDisk0 = [pscustomobject] @{
            Number         = 0
            UniqueId       = $script:testDiskUniqueId
            IsOffline      = $false
            IsReadOnly     = $false
            PartitionStyle = 'GPT'
        }

        $script:mockedDisk0Mbr = [pscustomobject] @{
            Number         = 0
            UniqueId       = $script:testDiskUniqueId
            IsOffline      = $false
            IsReadOnly     = $false
            PartitionStyle = 'MBR'
        }

        $script:mockedDisk0Offline = [pscustomobject] @{
            Number         = 0
            UniqueId       = $script:testDiskUniqueId
            IsOffline      = $true
            IsReadOnly     = $false
            PartitionStyle = 'GPT'
        }

        $script:mockedDisk0OfflineRaw = [pscustomobject] @{
            Number         = 0
            UniqueId       = $script:testDiskUniqueId
            IsOffline      = $true
            IsReadOnly     = $false
            PartitionStyle = 'Raw'
        }

        $script:mockedDisk0Readonly = [pscustomobject] @{
            Number         = 0
            UniqueId       = $script:testDiskUniqueId
            IsOffline      = $false
            IsReadOnly     = $true
            PartitionStyle = 'GPT'
        }

        $script:mockedDisk0Raw = [pscustomobject] @{
            Number         = 0
            UniqueId       = $script:testDiskUniqueId
            IsOffline      = $false
            IsReadOnly     = $false
            PartitionStyle = 'Raw'
        }

        $script:mockedCim = [pscustomobject] @{BlockSize = 4096}

        $script:mockedPartitionSize = 1GB

        $script:mockedPartition = [pscustomobject] @{
            DriveLetter     = $script:testDriveLetter
            Size            = $script:mockedPartitionSize
            PartitionNumber = 1
            Type            = 'Basic'
        }

        $script:mockedPartitionNoDriveLetter = [pscustomobject] @{
            DriveLetter     = ''
            Size            = $script:mockedPartitionSize
            PartitionNumber = 1
            Type            = 'Basic'
        }

        $script:mockedPartitionNoDriveLetterReadOnly = [pscustomobject] @{
            DriveLetter     = ''
            Size            = $script:mockedPartitionSize
            PartitionNumber = 1
            Type            = 'Basic'
            IsReadOnly      = $true
        }

        $script:mockedVolume = [pscustomobject] @{
            FileSystemLabel = 'myLabel'
            FileSystem      = 'NTFS'
        }

        $script:mockedVolumeUnformatted = [pscustomobject] @{
            FileSystemLabel = ''
            FileSystem      = ''
        }

        $script:mockedVolumeNoDriveLetter = [pscustomobject] @{
            FileSystemLabel = 'myLabel'
            FileSystem      = 'NTFS'
        }

        $script:mockedVolumeReFS = [pscustomobject] @{
            FileSystemLabel = 'myLabel'
            FileSystem      = 'ReFS'
        }
        #endregion

        #region functions for mocking pipeline
        # These functions are required to be able to mock functions where
        # values are passed in via the pipeline.
        function Set-Disk
        {
            Param
            (
                [CmdletBinding()]
                [Parameter(ValueFromPipeline)]
                $InputObject,

                [Boolean]
                $IsOffline,

                [Boolean]
                $IsReadOnly
            )
        }

        function Initialize-Disk
        {
            Param
            (
                [CmdletBinding()]
                [Parameter(ValueFromPipeline)]
                $InputObject,

                [String]
                $PartitionStyle
            )
        }

        function Get-Partition
        {
            Param
            (
                [CmdletBinding()]
                [Parameter(ValueFromPipeline)]
                $Disk,

                [String]
                $DriveLetter,

                [Uint32]
                $DiskNumber,

                [Uint32]
                $PartitionNumber
            )
        }

        function New-Partition
        {
            Param
            (
                [CmdletBinding()]
                [Parameter(ValueFromPipeline)]
                $Disk,

                [String]
                $DriveLetter,

                [Boolean]
                $UseMaximumSize,

                [UInt64]
                $Size
            )
        }

        function Set-Partition
        {
            Param
            (
                [CmdletBinding()]
                [Parameter(ValueFromPipeline)]
                $Disk,

                [String]
                $DriveLetter,

                [String]
                $NewDriveLetter
            )
        }

        function Get-Volume
        {
            Param
            (
                [CmdletBinding()]
                [Parameter(ValueFromPipeline)]
                $Partition,

                [String]
                $DriveLetter
            )
        }

        function Set-Volume
        {
            Param
            (
                [CmdletBinding()]
                [Parameter(ValueFromPipeline)]
                $InputObject,

                [String]
                $NewFileSystemLabel
            )
        }

        function Format-Volume
        {
            Param
            (
                [CmdletBinding()]
                [Parameter(ValueFromPipeline)]
                $Partition,

                [String]
                $DriveLetter,

                [String]
                $FileSystem,

                [Boolean]
                $Confirm,

                [String]
                $NewFileSystemLabel,

                [Uint32]
                $AllocationUnitSize,

                [Switch]
                $Force
            )
        }

        function Get-PartitionSupportedSize
        {
            param
            (
                [Parameter(ValueFromPipeline = $true)]
                [String]
                $DriveLetter
            )
        }

        function Resize-Partition
        {
            param
            (
                [Parameter(ValueFromPipeline = $true)]
                [String]
                $DriveLetter,

                [UInt64]
                $Size
            )
        }
        #endregion

        #region Function Get-TargetResource
        Describe 'MSFT_xDisk\Get-TargetResource' {
            Context 'Online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                $resource = Get-TargetResource `
                    -DiskId 0 `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "DiskId should be $($script:mockedDisk0.Number)" {
                    $resource.DiskId | Should Be $script:mockedDisk0.Number
                }

                It "DriveLetter should be $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should Be $script:testDriveLetter
                }

                It "Size should be $($script:mockedPartition.Size)" {
                    $resource.Size | Should Be $script:mockedPartition.Size
                }

                It "FSLabel should be $($script:mockedVolume.FileSystemLabel)" {
                    $resource.FSLabel | Should Be $script:mockedVolume.FileSystemLabel
                }

                It "AllocationUnitSize should be $($script:mockedCim.BlockSize)" {
                    $resource.AllocationUnitSize | Should Be $script:mockedCim.BlockSize
                }

                It "FSFormat should be $($script:mockedVolume.FileSystem)" {
                    $resource.FSFormat | Should Be $script:mockedVolume.FileSystem
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                }
            }

            Context 'Online GPT disk with a partition/volume and correct Drive Letter assigned using Disk UniqueId' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                $resource = Get-TargetResource `
                    -DiskId $script:testDiskUniqueId `
                    -DiskIdType 'UniqueId' `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "DiskId should be $($script:mockedDisk0.UniqueId)" {
                    $resource.DiskId | Should Be $script:mockedDisk0.UniqueId
                }

                It "DriveLetter should be $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should Be $script:testDriveLetter
                }

                It "Size should be $($script:mockedPartition.Size)" {
                    $resource.Size | Should Be $script:mockedPartition.Size
                }

                It "FSLabel should be $($script:mockedVolume.FileSystemLabel)" {
                    $resource.FSLabel | Should Be $script:mockedVolume.FileSystemLabel
                }

                It "AllocationUnitSize should be $($script:mockedCim.BlockSize)" {
                    $resource.AllocationUnitSize | Should Be $script:mockedCim.BlockSize
                }

                It "FSFormat should be $($script:mockedVolume.FileSystem)" {
                    $resource.FSFormat | Should Be $script:mockedVolume.FileSystem
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                }
            }

            Context 'Online GPT disk with no partition using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -Verifiable

                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -Verifiable

                $resource = Get-TargetResource `
                    -DiskId 0 `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "DiskId should be $($script:mockedDisk0.Number)" {
                    $resource.DiskId | Should Be $script:mockedDisk0.Number
                }

                It "DriveLetter should be null" {
                    $resource.DriveLetter | Should Be $null
                }

                It "Size should be null" {
                    $resource.Size | Should Be $null
                }

                It "FSLabel should be empty" {
                    $resource.FSLabel | Should Be ''
                }

                It "AllocationUnitSize should be null" {
                    $resource.AllocationUnitSize | Should Be $null
                }

                It "FSFormat should be null" {
                    $resource.FSFormat | Should Be $null
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-Disk -Exactly 1
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_xDisk\Set-TargetResource' {
            Context 'Offline GPT disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0Offline } `
                    -Verifiable

                Mock `
                    -CommandName Set-Disk `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                    $DriveLetter -eq $script:testDriveLetter
                } `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Initialize-Disk

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Offline.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                }
            }

            Context 'Offline GPT disk using Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0Offline } `
                    -Verifiable

                Mock `
                    -CommandName Set-Disk `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                    $DriveLetter -eq $script:testDriveLetter
                } `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Initialize-Disk

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Offline.UniqueId `
                            -DiskIdType 'UniqueId' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                }
            }

            Context 'Readonly GPT disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0Readonly } `
                    -Verifiable

                Mock `
                    -CommandName Set-Disk `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                    $DriveLetter -eq $script:testDriveLetter
                } `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Initialize-Disk

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Readonly.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                }
            }

            Context 'Offline RAW disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0OfflineRaw } `
                    -Verifiable

                Mock `
                    -CommandName Set-Disk `
                    -Verifiable

                Mock `
                    -CommandName Initialize-Disk `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                    $DriveLetter -eq $script:testDriveLetter
                } `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0OfflineRaw.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                }
            }

            Context 'Online RAW disk with Size using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0Raw } `
                    -Verifiable

                Mock `
                    -CommandName Initialize-Disk `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                    $DriveLetter -eq $script:testDriveLetter
                } `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Raw.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                }
            }

            Context 'Online RAW disk with Size, FSLabel and AllocationUnit using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0Raw } `
                    -Verifiable

                Mock `
                    -CommandName Initialize-Disk `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                    $DriveLetter -eq $script:testDriveLetter
                } `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Raw.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -AllocationUnitSize 64 `
                            -FSLabel 'MyDisk' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                }
            }

            Context 'Online GPT disk with no partitions using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                    $DriveLetter -eq $script:testDriveLetter
                } `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                }
            }

            Context 'Online GPT disk with no partitions using Disk Number, partition fails to become writeable' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionNoDriveLetterReadOnly } `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                    $DriveLetter -eq $script:testDriveLetter
                } `
                    -MockWith { $script:mockedPartitionNoDriveLetterReadOnly } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Set-Volume
                Mock -CommandName Get-Volume
                Mock -CommandName Format-Volume
                Mock -CommandName Set-Partition

                $startTime = Get-Date
                It 'Should throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should throw
                }

                $endTime = Get-Date

                It 'Should take at least 30s' {
                    ($endTime - $startTime).TotalSeconds | Should BeGreaterThan 29
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                }
            }

            Context 'Online MBR disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0Mbr } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Get-Partition
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Get-Volume
                Mock -CommandName Set-Partition

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.DiskAlreadyInitializedError -f `
                        'Number', $script:mockedDisk0Mbr.Number, $script:mockedDisk0Mbr.PartitionStyle)

                It 'Should throw DiskAlreadyInitializedError' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Mbr.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should Throw $errorRecord
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                }
            }

            Context 'Online MBR disk using Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0Mbr } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Get-Partition
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Get-Volume
                Mock -CommandName Set-Partition

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.DiskAlreadyInitializedError -f `
                        'UniqueId', $script:mockedDisk0Mbr.UniqueId, $script:mockedDisk0Mbr.PartitionStyle)

                It 'Should throw DiskAlreadyInitializedError' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Mbr.UniqueId `
                            -DiskIdType 'UniqueId' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should Throw $errorRecord
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                }
            }

            Context 'Online GPT disk with partition/volume already assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -DriveLetter $script:testDriveLetter `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                }
            }

            Context 'Online GPT disk containing matching partition but not assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume

                It 'Should not throw' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -DriveLetter $script:testDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                }
            }

            Context 'Online GPT disk with a partition/volume and wrong Drive Letter assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                    $DriveLetter -eq 'H'
                } `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -Driveletter 'H' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                }
            }

            Context 'Online GPT disk with a partition/volume and wrong Volume Label assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-Volume `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -Driveletter $script:testDriveLetter `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Times 1
                }
            }

            Context 'AllowDestructive: Online GPT disk with matching partition/volume without assigned drive letter and wrong size' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                    $DriveLetter -eq $script:testDriveLetter
                } `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable
                
                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Format-Volume
                Mock -CommandName Set-Partition
                Mock -CommandName Resize-Partition
                Mock -CommandName Get-PartitionSupportedSize
                Mock -CommandName Set-Volume

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size ($script:mockedPartitionSize + 1024) `
                            -AllowDestructive $true `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                    Assert-MockCalled -CommandName Set-Volume -Times 0
                }
            }

            Context 'AllowDestructive: Online GPT disk with matching partition/volume but wrong size' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-Volume `
                    -Verifiable
                Mock `
                    -CommandName Resize-Partition `
                    -Verifiable
                Mock `
                    -CommandName Get-PartitionSupportedSize `
                    -MockWith {
                    return @{
                        SizeMin = 0
                        SizeMax = [int64]::MaxValue
                    }
                } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size ($script:mockedPartitionSize + 1024) `
                            -AllowDestructive $true `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Times 1
                }
            }

            Context 'AllowDestructive: Online GPT disk with matching partition/volume but wrong size and remaining size too small' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable
               
                Mock `
                    -CommandName Get-PartitionSupportedSize `
                    -MockWith {
                    return @{
                        SizeMin = 0
                        SizeMax = 1
                    }
                } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Set-Partition
                Mock -CommandName Get-Volume
                Mock -CommandName Set-Volume
                Mock -CommandName Resize-Partition

                It 'Should throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size ($script:mockedPartitionSize + 1024) `
                            -AllowDestructive $true `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Times 0
                }
            }

            Context 'AllowDestructive: Online GPT disk with matching partition/volume but wrong size and ReFS' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeReFS } `
                    -Verifiable

                Mock `
                    -CommandName Set-Volume `
                    -Verifiable
               
                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Set-Partition
                Mock -CommandName Resize-Partition
                 Mock  -CommandName Get-PartitionSupportedSize

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size ($script:mockedPartitionSize + 1024) `
                            -AllowDestructive $true `
                            -FSLabel 'NewLabel' `
                            -FSFormat 'ReFS' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Times 1
                    Assert-MockCalled -CommandName Resize-Partition -Times 0
                    Assert-MockCalled -CommandName Get-PartitionSupportedSize -Times 0
                }
            }

            Context 'AllowDestructive: Online GPT disk with matching partition/volume but wrong format' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-Volume `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName New-Partition                
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -FSFormat 'ReFS' `
                            -FSLabel 'NewLabel' `
                            -AllowDestructive $true `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Times 1
                }
            }

            Context 'AllowDestructive: Online GPT disk containing arbitrary partitions' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-Volume `
                    -Verifiable
                Mock `
                    -CommandName Clear-Disk `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -FSLabel 'NewLabel' `
                            -AllowDestructive $true `
                            -ClearDisk $true `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Times 1
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe 'MSFT_xDisk\Test-TargetResource' {
            Mock `
                -CommandName Get-CimInstance `
                -MockWith { $script:mockedCim }

            Context 'Test no disk' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Offline.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }
            
            Context 'Test disk not initialized using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0Offline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Offline.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test disk not initialized using Disk Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0Offline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Offline.UniqueId `
                            -DiskIdType 'UniqueId' `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test disk read only using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0Readonly } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Readonly.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test online unformatted disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0Raw } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Raw.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test mismatching partition size using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size ($script:mockedPartitionSize + 1MB) `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be true' {
                    $script:result | Should Be $true
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test mismatched AllocationUnitSize using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4097 `
                            -AllowDestructive $true `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test mismatching FSFormat using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -DriveLetter $script:testDriveLetter `
                            -FSFormat 'ReFS' `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be true' {
                    $script:result | Should Be $true
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test mismatching FSFormat using Disk Number and AllowDestructive' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -DriveLetter $script:testDriveLetter `
                            -FSFormat 'ReFS' `
                            -AllowDestructive $true `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test mismatching FSLabel using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -DriveLetter $script:testDriveLetter `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test mismatching DriveLetter using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume }

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim }

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -DriveLetter 'Z' `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test all disk properties matching using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size $script:mockedPartition.Size `
                            -FSLabel $script:mockedVolume.FileSystemLabel `
                            -FSFormat $script:mockedVolume.FileSystem `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be true' {
                    $script:result | Should Be $true
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
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
