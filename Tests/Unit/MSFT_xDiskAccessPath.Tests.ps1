$script:DSCModuleName = 'xStorage'
$script:DSCResourceName = 'MSFT_xDiskAccessPath'

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
        $script:testAccessPath = 'c:\TestAccessPath'
        $script:testDiskNumber = 1
        $script:testDiskUniqueId = 'TESTDISKUNIQUEID'
        $script:testDiskGptGuid = [guid]::NewGuid()
        $script:testDiskMbrGuid = '123456'

        $script:mockedDisk0 = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            Guid           = $script:testDiskGptGuid
            IsOffline      = $false
            IsReadOnly     = $false
            PartitionStyle = 'GPT'
        }

        $script:mockedDisk0Mbr = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            Guid           = $script:testDiskMbrGuid
            IsOffline      = $false
            IsReadOnly     = $false
            PartitionStyle = 'MBR'
        }

        $script:mockedDisk0Offline = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            Guid           = $script:testDiskGptGuid
            IsOffline      = $true
            IsReadOnly     = $false
            PartitionStyle = 'GPT'
        }

        $script:mockedDisk0OfflineRaw = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            Guid           = ''
            IsOffline      = $true
            IsReadOnly     = $false
            PartitionStyle = 'Raw'
        }

        $script:mockedDisk0Readonly = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            Guid           = $script:testDiskGptGuid
            IsOffline      = $false
            IsReadOnly     = $true
            PartitionStyle = 'GPT'
        }

        $script:mockedDisk0Raw = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            Guid           = ''
            IsOffline      = $false
            IsReadOnly     = $false
            PartitionStyle = 'Raw'
        }

        $script:mockedCim = [pscustomobject] @{BlockSize = 4096}

        $script:mockedPartitionSize = 1GB

        $script:mockedPartition = [pscustomobject] @{
            AccessPaths     = @(
                '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                $script:testAccessPath
            )
            Size            = $script:mockedPartitionSize
            PartitionNumber = 1
            Type            = 'Basic'
        }

        $script:mockedPartitionNoAccess = [pscustomobject] @{
            AccessPaths     = @(
                '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
            )
            Size            = $script:mockedPartitionSize
            PartitionNumber = 1
            Type            = 'Basic'
        }

        $script:mockedVolume = [pscustomobject] @{
            FileSystemLabel = 'myLabel'
            FileSystem      = 'NTFS'
        }

        $script:mockedVolumeUnformatted = [pscustomobject] @{
            FileSystemLabel = ''
            FileSystem      = ''
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
            [CmdletBinding()]
            Param
            (
                [Parameter(ValueFromPipeline = $true)]
                $InputObject,

                [Boolean]
                $IsOffline,

                [Boolean]
                $IsReadOnly
            )
        }

        function Initialize-Disk
        {
            [CmdletBinding()]
            Param
            (
                [Parameter(ValueFromPipeline = $true)]
                $InputObject,

                [String]
                $PartitionStyle
            )
        }

        function Get-Partition
        {
            [CmdletBinding()]
            Param
            (
                [Parameter(ValueFromPipeline = $true)]
                $Disk,

                [Uint32]
                $ParitionNumber
            )
        }

        function New-Partition
        {
            [CmdletBinding()]
            Param
            (
                [Parameter(ValueFromPipeline)]
                $Disk,

                [Boolean]
                $UseMaximumSize,

                [UInt64]
                $Size
            )
        }

        function Get-Volume
        {
            [CmdletBinding()]
            Param
            (
                [Parameter(ValueFromPipeline = $true)]
                $Partition
            )
        }

        function Set-Volume
        {
            [CmdletBinding()]
            Param
            (
                [Parameter(ValueFromPipeline = $true)]
                $InputObject,

                [String]
                $NewFileSystemLabel
            )
        }

        function Format-Volume
        {
            [CmdletBinding()]
            Param
            (
                [Parameter(ValueFromPipeline = $true)]
                $Partition,

                [String]
                $FileSystem,

                [Boolean]
                $Confirm,

                [Uint32]
                $AllocationUnitSize
            )
        }

        function Add-PartitionAccessPath
        {
            [CmdletBinding()]
            Param
            (
                [String]
                $AccessPath,

                [Uint32]
                $DiskNumber,

                [Uint32]
                $PartitionNumber
            )
        }
        #endregion

        #region Function Get-TargetResource
        Describe 'MSFT_xDiskAccessPath\Get-TargetResource' {
            Context 'Online GPT disk with a partition/volume and correct Access Path assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' } `
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
                    -DiskId $script:mockedDisk0.Number `
                    -AccessPath $script:testAccessPath `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0.Number)" {
                    $resource.DiskId | Should Be $script:mockedDisk0.Number
                }

                It "Should return AccessPath $($script:testAccessPath)" {
                    $resource.AccessPath | Should Be $script:testAccessPath
                }

                It "Should return Size $($script:mockedPartition.Size)" {
                    $resource.Size | Should Be $script:mockedPartition.Size
                }

                It "Should return FSLabel $($script:mockedVolume.FileSystemLabel)" {
                    $resource.FSLabel | Should Be $script:mockedVolume.FileSystemLabel
                }

                It "Should return AllocationUnitSize $($script:mockedCim.BlockSize)" {
                    $resource.AllocationUnitSize | Should Be $script:mockedCim.BlockSize
                }

                It "Should return FSFormat $($script:mockedVolume.FileSystem)" {
                    $resource.FSFormat | Should Be $script:mockedVolume.FileSystem
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'Online GPT disk with a partition/volume and correct Access Path assigned using Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.UniqueId -and $DiskIdType -eq 'UniqueId' } `
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
                    -DiskId $script:mockedDisk0.UniqueId `
                    -DiskIdType 'UniqueId' `
                    -AccessPath $script:testAccessPath `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0.UniqueId)" {
                    $resource.DiskId | Should Be $script:mockedDisk0.UniqueId
                }

                It "Should return AccessPath $($script:testAccessPath)" {
                    $resource.AccessPath | Should Be $script:testAccessPath
                }

                It "Should return Size $($script:mockedPartition.Size)" {
                    $resource.Size | Should Be $script:mockedPartition.Size
                }

                It "Should return FSLabel $($script:mockedVolume.FileSystemLabel)" {
                    $resource.FSLabel | Should Be $script:mockedVolume.FileSystemLabel
                }

                It "Should return AllocationUnitSize $($script:mockedCim.BlockSize)" {
                    $resource.AllocationUnitSize | Should Be $script:mockedCim.BlockSize
                }

                It "Should return FSFormat $($script:mockedVolume.FileSystem)" {
                    $resource.FSFormat | Should Be $script:mockedVolume.FileSystem
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.UniqueId -and $DiskIdType -eq 'UniqueId' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'Online GPT disk with a partition/volume and correct Access Path assigned using Disk Guid' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Guid -and $DiskIdType -eq 'Guid' } `
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
                    -DiskId $script:mockedDisk0.Guid `
                    -DiskIdType 'Guid' `
                    -AccessPath $script:testAccessPath `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0.Guid)" {
                    $resource.DiskId | Should Be $script:mockedDisk0.Guid
                }

                It "Should return AccessPath $($script:testAccessPath)" {
                    $resource.AccessPath | Should Be $script:testAccessPath
                }

                It "Should return Size $($script:mockedPartition.Size)" {
                    $resource.Size | Should Be $script:mockedPartition.Size
                }

                It "Should return FSLabel $($script:mockedVolume.FileSystemLabel)" {
                    $resource.FSLabel | Should Be $script:mockedVolume.FileSystemLabel
                }

                It "Should return AllocationUnitSize $($script:mockedCim.BlockSize)" {
                    $resource.AllocationUnitSize | Should Be $script:mockedCim.BlockSize
                }

                It "Should return FSFormat $($script:mockedVolume.FileSystem)" {
                    $resource.FSFormat | Should Be $script:mockedVolume.FileSystem
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Guid -and $DiskIdType -eq 'Guid' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'Online GPT disk with no partition using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' } `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume

                $resource = Get-TargetResource `
                    -DiskId $script:mockedDisk0.Number `
                    -AccessPath $script:testAccessPath `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0.Number)" {
                    $resource.DiskId | Should Be $script:mockedDisk0.Number
                }

                It "Should return AccessPath $($script:testAccessPath)" {
                    $resource.AccessPath | Should Be $script:testAccessPath
                }

                It "Should return Size null" {
                    $resource.Size | Should Be $null
                }

                It "Should return FSLabel empty" {
                    $resource.FSLabel | Should Be ''
                }

                It "Should return AllocationUnitSize null" {
                    $resource.AllocationUnitSize | Should Be $null
                }

                It "Should return FSFormat null" {
                    $resource.FSFormat | Should Be $null
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 0
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_xDiskAccessPath\Set-TargetResource' {
            Context 'Offline GPT disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.Number -and $DiskIdType -eq 'Number' } `
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
                    -MockWith { $script:mockedPartitionNoAccess } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Add-PartitionAccessPath `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Initialize-Disk

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Offline.Number `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 1
                }
            }

            Context 'Offline GPT disk using Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.UniqueId -and $DiskIdType -eq 'UniqueId' } `
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
                    -MockWith { $script:mockedPartitionNoAccess } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Add-PartitionAccessPath `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Initialize-Disk

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Offline.UniqueId `
                            -DiskIdType 'UniqueId' `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.UniqueId -and $DiskIdType -eq 'UniqueId' }
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 1
                }
            }

            Context 'Offline GPT disk using Disk Guid' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.Guid -and $DiskIdType -eq 'Guid' } `
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
                    -MockWith { $script:mockedPartitionNoAccess } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Add-PartitionAccessPath `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Initialize-Disk

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Offline.Guid `
                            -DiskIdType 'Guid' `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.Guid -and $DiskIdType -eq 'Guid' }
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 1
                }
            }

            Context 'Readonly GPT disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Readonly.Number -and $DiskIdType -eq 'Number' } `
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
                    -MockWith { $script:mockedPartitionNoAccess } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Add-PartitionAccessPath `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Initialize-Disk

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Readonly.Number `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Readonly.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 1
                }
            }

            Context 'Offline RAW disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0OfflineRaw.Number -and $DiskIdType -eq 'Number' } `
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
                    -MockWith { $script:mockedPartitionNoAccess } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Add-PartitionAccessPath `
                    -Verifiable

                # mocks that should not be called

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0OfflineRaw.Number `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0OfflineRaw.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 1
                }
            }

            Context 'Online RAW disk with Size using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Raw.Number -and $DiskIdType -eq 'Number' } `
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
                    -MockWith { $script:mockedPartitionNoAccess } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Add-PartitionAccessPath `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Raw.Number `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Raw.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 1
                }
            }

            Context 'Online GPT disk with no partitions using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' } `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeUnformatted } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                Mock `
                    -CommandName Add-PartitionAccessPath `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 1
                }
            }

            Context 'Online MBR disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Mbr.Number -and $DiskIdType -eq 'Number' } `
                    -MockWith { $script:mockedDisk0Mbr } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Get-Partition
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Get-Volume
                Mock -CommandName Add-PartitionAccessPath

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.DiskAlreadyInitializedError -f `
                        'Number', $script:mockedDisk0Mbr.Number, $script:mockedDisk0Mbr.PartitionStyle)

                It 'Should throw DiskAlreadyInitializedError' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Mbr.Number `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Mbr.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 0
                }
            }

            Context 'Online MBR disk using Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Mbr.UniqueId -and $DiskIdType -eq 'UniqueId' } `
                    -MockWith { $script:mockedDisk0Mbr } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Get-Partition
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Get-Volume
                Mock -CommandName Add-PartitionAccessPath

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.DiskAlreadyInitializedError -f `
                        'UniqueId', $script:mockedDisk0Mbr.UniqueId, $script:mockedDisk0Mbr.PartitionStyle)

                It 'Should throw DiskAlreadyInitializedError' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Mbr.UniqueId `
                            -DiskIdType 'UniqueId' `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Mbr.UniqueId -and $DiskIdType -eq 'UniqueId' }
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 0
                }
            }

            Context 'Online MBR disk using Disk Guid' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Mbr.Guid -and $DiskIdType -eq 'Guid' } `
                    -MockWith { $script:mockedDisk0Mbr } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Get-Partition
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Get-Volume
                Mock -CommandName Add-PartitionAccessPath

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.DiskAlreadyInitializedError -f `
                        'Guid', $script:mockedDisk0Mbr.Guid, $script:mockedDisk0Mbr.PartitionStyle)

                It 'Should throw DiskAlreadyInitializedError' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Mbr.Guid `
                            -DiskIdType 'Guid' `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Mbr.Guid -and $DiskIdType -eq 'Guid' }
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 0
                }
            }

            Context 'Online GPT disk with partition/volume already assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' } `
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
                Mock -CommandName Add-PartitionAccessPath

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 0
                }
            }

            Context 'Online GPT disk containing matching partition but not assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' } `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionNoAccess } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Add-PartitionAccessPath `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -AccessPath $script:testAccessPath `
                            -Size $script:mockedPartitionSize `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 1
                }
            }

            Context 'Online GPT disk with correct partition/volume but wrong Volume Label assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' } `
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
                Mock -CommandName Add-PartitionAccessPath

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -AccessPath $script:testAccessPath `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Times 0
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe 'MSFT_xDiskAccessPath\Test-TargetResource' {
            Mock `
                -CommandName Get-CimInstance `
                -MockWith { $script:mockedCim }

            Context 'Test disk not initialized using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.Number -and $DiskIdType -eq 'Number' } `
                    -MockWith { $script:mockedDisk0Offline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Offline.Number `
                            -AccessPath $script:testAccessPath `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should return false' {
                    $script:result | Should Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test disk not initialized using Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.UniqueId -and $DiskIdType -eq 'UniqueId' } `
                    -MockWith { $script:mockedDisk0Offline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Offline.UniqueId `
                            -DiskIdType 'UniqueId' `
                            -AccessPath $script:testAccessPath `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should return false' {
                    $script:result | Should Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.UniqueId -and $DiskIdType -eq 'UniqueId' }
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test disk not initialized using Disk Guid' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.Guid -and $DiskIdType -eq 'Guid' } `
                    -MockWith { $script:mockedDisk0Offline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Offline.Guid `
                            -DiskIdType 'Guid' `
                            -AccessPath $script:testAccessPath `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should return false' {
                    $script:result | Should Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Offline.Guid -and $DiskIdType -eq 'Guid' }
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test disk read only using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Readonly.Number -and $DiskIdType -eq 'Number' } `
                    -MockWith { $script:mockedDisk0Readonly } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Readonly.Number `
                            -AccessPath $script:testAccessPath `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should return false' {
                    $script:result | Should Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Readonly.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test online unformatted disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Raw.Number -and $DiskIdType -eq 'Number' } `
                    -MockWith { $script:mockedDisk0Raw } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Raw.Number `
                            -AccessPath $script:testAccessPath `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should return false' {
                    $script:result | Should Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Raw.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test mismatching partition size using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' } `
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

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -AccessPath $script:testAccessPath `
                            -AllocationUnitSize 4096 `
                            -Size 124 `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should return true' {
                    $script:result | Should Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test mismatched AllocationUnitSize using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' } `
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

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -AccessPath $script:testAccessPath `
                            -AllocationUnitSize 4097 `
                            -Verbose
                    } | Should Not Throw
                }

                # skipped due to:  https://github.com/PowerShell/xStorage/issues/22
                It 'Should return false' -skip {
                    $script:result | Should Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test mismatching FSFormat using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' } `
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

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -AccessPath $script:testAccessPath `
                            -FSFormat 'ReFS' `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should return true' {
                    $script:result | Should Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test mismatching FSLabel using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' } `
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

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -AccessPath $script:testAccessPath `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should return false' {
                    $script:result | Should Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test all disk properties matching using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' } `
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

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -AccessPath $script:testAccessPath `
                            -AllocationUnitSize 4096 `
                            -Size $script:mockedPartition.Size `
                            -FSFormat $script:mockedVolume.FileSystem `
                            -Verbose
                    } | Should Not Throw
                }

                It 'Should return true' {
                    $script:result | Should Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number' }
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
