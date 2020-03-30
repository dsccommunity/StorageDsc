$script:dscModuleName = 'StorageDsc'
$script:dscResourceName = 'DSC_DiskAccessPath'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        $script:testAccessPath = 'c:\TestAccessPath'
        $script:testDiskNumber = 1
        $script:testDiskUniqueId = 'TESTDISKUNIQUEID'
        $script:testDiskGptGuid = [guid]::NewGuid()
        $script:testDiskMbrGuid = '123456'
        $script:NoDefaultDriveLetter = $true

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
            Size                 = $script:mockedPartitionSize
            PartitionNumber      = 1
            Type                 = 'Basic'
            NoDefaultDriveLetter = $true
        }

        $script:mockedPartitionNoDefaultDriveLetter = [pscustomobject] @{
            AccessPaths     = @(
                '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                $script:testAccessPath
            )
            Size                 = $script:mockedPartitionSize
            PartitionNumber      = 1
            Type                 = 'Basic'
            NoDefaultDriveLetter = $false
        }
        $script:mockedPartitionNoAccess = [pscustomobject] @{
            AccessPaths     = @(
                '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
            )
            Size            = $script:mockedPartitionSize
            PartitionNumber = 1
            Type            = 'Basic'
            NoDefaultDriveLetter = $false
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

        $script:parameterFilter_Disk0DiskIdNumber = {
            $DiskId -eq $script:mockedDisk0.Number -and $DiskIdType -eq 'Number'
        }

        $script:parameterFilter_Disk0OfflineDiskIdNumber = {
            $DiskId -eq $script:mockedDisk0Offline.Number -and $DiskIdType -eq 'Number'
        }

        $script:parameterFilter_Disk0ReadonlyDiskIdNumber = {
            $DiskId -eq $script:mockedDisk0Readonly.Number -and $DiskIdType -eq 'Number'
        }

        $script:parameterFilter_Disk0RawDiskIdNumber = {
            $DiskId -eq $script:mockedDisk0Raw.Number -and $DiskIdType -eq 'Number'
        }

        $script:parameterFilter_Disk0OfflineRawDiskIdNumber = {
            $DiskId -eq $script:mockedDisk0OfflineRaw.Number -and $DiskIdType -eq 'Number'
        }

        $script:parameterFilter_Disk0MbrDiskIdNumber = {
            $DiskId -eq $script:mockedDisk0Mbr.Number -and $DiskIdType -eq 'Number'
        }

        $script:parameterFilter_Disk0DiskIdUniqueId = {
            $DiskId -eq $script:mockedDisk0.UniqueId -and $DiskIdType -eq 'UniqueId'
        }

        $script:parameterFilter_Disk0OfflineDiskIdUniqueId = {
            $DiskId -eq $script:mockedDisk0Offline.UniqueId -and $DiskIdType -eq 'UniqueId'
        }

        $script:parameterFilter_Disk0MbrDiskIdUniqueId = {
            $DiskId -eq $script:mockedDisk0Mbr.UniqueId -and $DiskIdType -eq 'UniqueId'
        }

        $script:parameterFilter_Disk0DiskIdGuid = {
            $DiskId -eq $script:mockedDisk0.Guid -and $DiskIdType -eq 'Guid'
        }

        $script:parameterFilter_Disk0OfflineDiskIdGuid = {
            $DiskId -eq $script:mockedDisk0Offline.Guid -and $DiskIdType -eq 'Guid'
        }

        $script:parameterFilter_Disk0MbrDiskIdGuid = {
            $DiskId -eq $script:mockedDisk0Mbr.Guid -and $DiskIdType -eq 'Guid'
        }

        <#
            These functions are required to be able to mock functions where
            values are passed in via the pipeline.
        #>
        function Set-Disk
        {
            [CmdletBinding()]
            param
            (
                [Parameter(ValueFromPipeline = $true)]
                $InputObject,

                [Parameter()]
                [System.Boolean]
                $IsOffline,

                [Parameter()]
                [System.Boolean]
                $IsReadOnly
            )
        }

        function Initialize-Disk
        {
            [CmdletBinding()]
            param
            (
                [Parameter(ValueFromPipeline = $true)]
                $InputObject,

                [Parameter()]
                [System.String]
                $PartitionStyle
            )
        }

        function Get-Partition
        {
            [CmdletBinding()]
            param
            (
                [Parameter(ValueFromPipeline = $true)]
                $Disk,

                [Parameter()]
                [System.Uint32]
                $ParitionNumber
            )
        }

        function New-Partition
        {
            [CmdletBinding()]
            param
            (
                [Parameter(ValueFromPipeline)]
                $Disk,

                [Parameter()]
                [System.Boolean]
                $UseMaximumSize,

                [Parameter()]
                [UInt64]
                $Size
            )
        }

        function Get-Volume
        {
            [CmdletBinding()]
            param
            (
                [Parameter(ValueFromPipeline = $true)]
                $Partition
            )
        }

        function Set-Volume
        {
            [CmdletBinding()]
            param
            (
                [Parameter(ValueFromPipeline = $true)]
                $InputObject,

                [Parameter()]
                [System.String]
                $NewFileSystemLabel
            )
        }

        function Format-Volume
        {
            [CmdletBinding()]
            param
            (
                [Parameter(ValueFromPipeline = $true)]
                $Partition,

                [Parameter()]
                [System.String]
                $FileSystem,

                [Parameter()]
                [System.Boolean]
                $Confirm,

                [Parameter()]
                [System.Uint32]
                $AllocationUnitSize
            )
        }

        function Add-PartitionAccessPath
        {
            [CmdletBinding()]
            param
            (
                [Parameter()]
                [System.String]
                $AccessPath,

                [Parameter()]
                [System.Uint32]
                $DiskNumber,

                [Parameter()]
                [System.Uint32]
                $PartitionNumber
            )
        }

        Describe 'DSC_DiskAccessPath\Get-TargetResource' {
            Context 'When using online GPT disk with a partition/volume and correct Access Path assigned specified by Disk Number' {
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
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
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
                    $resource.DiskId | Should -Be $script:mockedDisk0.Number
                }

                It "Should return AccessPath $($script:testAccessPath)" {
                    $resource.AccessPath | Should -Be $script:testAccessPath
                }

                It "Should return Size $($script:mockedPartition.Size)" {
                    $resource.Size | Should -Be $script:mockedPartition.Size
                }

                It "Should return FSLabel $($script:mockedVolume.FileSystemLabel)" {
                    $resource.FSLabel | Should -Be $script:mockedVolume.FileSystemLabel
                }

                It "Should return AllocationUnitSize $($script:mockedCim.BlockSize)" {
                    $resource.AllocationUnitSize | Should -Be $script:mockedCim.BlockSize
                }

                It "Should return FSFormat $($script:mockedVolume.FileSystem)" {
                    $resource.FSFormat | Should -Be $script:mockedVolume.FileSystem
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                }
            }

            Context 'When using online GPT disk with a partition/volume and correct Access Path assigned specified by Disk Unique Id' {
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
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdUniqueId `
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
                    $resource.DiskId | Should -Be $script:mockedDisk0.UniqueId
                }

                It "Should return AccessPath $($script:testAccessPath)" {
                    $resource.AccessPath | Should -Be $script:testAccessPath
                }

                It "Should return Size $($script:mockedPartition.Size)" {
                    $resource.Size | Should -Be $script:mockedPartition.Size
                }

                It "Should return FSLabel $($script:mockedVolume.FileSystemLabel)" {
                    $resource.FSLabel | Should -Be $script:mockedVolume.FileSystemLabel
                }

                It "Should return AllocationUnitSize $($script:mockedCim.BlockSize)" {
                    $resource.AllocationUnitSize | Should -Be $script:mockedCim.BlockSize
                }

                It "Should return FSFormat $($script:mockedVolume.FileSystem)" {
                    $resource.FSFormat | Should -Be $script:mockedVolume.FileSystem
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdUniqueId
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                }
            }

            Context 'When using online GPT disk with a partition/volume and correct Access Path assigned specified by Disk Guid' {
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
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdGuid `
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
                    $resource.DiskId | Should -Be $script:mockedDisk0.Guid
                }

                It "Should return AccessPath $($script:testAccessPath)" {
                    $resource.AccessPath | Should -Be $script:testAccessPath
                }

                It "Should return Size $($script:mockedPartition.Size)" {
                    $resource.Size | Should -Be $script:mockedPartition.Size
                }

                It "Should return FSLabel $($script:mockedVolume.FileSystemLabel)" {
                    $resource.FSLabel | Should -Be $script:mockedVolume.FileSystemLabel
                }

                It "Should return AllocationUnitSize $($script:mockedCim.BlockSize)" {
                    $resource.AllocationUnitSize | Should -Be $script:mockedCim.BlockSize
                }

                It "Should return FSFormat $($script:mockedVolume.FileSystem)" {
                    $resource.FSFormat | Should -Be $script:mockedVolume.FileSystem
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdGuid
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                }
            }

            Context 'When using online GPT disk with no partition specified by Disk Number' {
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
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
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
                    $resource.DiskId | Should -Be $script:mockedDisk0.Number
                }

                It "Should return AccessPath $($script:testAccessPath)" {
                    $resource.AccessPath | Should -Be $script:testAccessPath
                }

                It "Should return Size null" {
                    $resource.Size | Should -Be $null
                }

                It "Should return FSLabel empty" {
                    $resource.FSLabel | Should -Be ''
                }

                It "Should return AllocationUnitSize null" {
                    $resource.AllocationUnitSize | Should -Be $null
                }

                It "Should return FSFormat null" {
                    $resource.FSFormat | Should -Be $null
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                }
            }
        }

        Describe 'DSC_DiskAccessPath\Set-TargetResource' {
            BeforeAll {
                Mock `
                    -CommandName Test-AccessPathInPSDrive `
                    -Verifiable
            }

            Context 'When using offline GPT disk with NoDefaultDriveLetter set to False specified by Disk Number ' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdNumber `
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

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Initialize-Disk

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Offline.Number `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdNumber
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When using offline GPT disk with NoDefaultDriveLetter set to False specified by Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdUniqueId `
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

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Initialize-Disk

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Offline.UniqueId `
                            -DiskIdType 'UniqueId' `
                            -AccessPath $script:testAccessPath `
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdUniqueId
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When using offline GPT disk specified by Disk Guid' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdGuid `
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

                Mock `
                    -CommandName Set-Partition `
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
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdGuid
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1

                }
            }

            Context 'When using readonly GPT disk specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0ReadonlyDiskIdNumber `
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
                    -CommandName Set-Partition `
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
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0ReadonlyDiskIdNumber
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When using offline RAW disk specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0OfflineRawDiskIdNumber `
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

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0OfflineRaw.Number `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0OfflineRawDiskIdNumber
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When using online RAW disk with Size specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0RawDiskIdNumber `
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

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Raw.Number `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0RawDiskIdNumber
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When using online GPT disk with no partitions specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -MockWith { $script:mockedPartitionNoDefaultDriveLetter } `
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

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -AccessPath $script:testAccessPath `
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When using online MBR disk specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0MbrDiskIdNumber `
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
                    } | Should -Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0MbrDiskIdNumber
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 0
                }
            }

            Context 'When using online MBR disk specified by Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0MbrDiskIdUniqueId `
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
                    } | Should -Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0MbrDiskIdUniqueId
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 0
                }
            }

            Context 'When using online MBR disk specified by Disk Guid' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0MbrDiskIdGuid `
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
                    } | Should -Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0MbrDiskIdGuid
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 0
                }
            }

            Context 'When using online GPT disk with partition/volume already assigned and NoDefaultDriveLetter set to False specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
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
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 0
                }
            }

            Context 'When using online GPT disk containing matching partition but not assigned specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
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

                Mock `
                    -CommandName Set-Partition `
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
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When using online GPT disk containing matching partition but not assigned with no size parameter specified with NoDefaultDriveLetter set to False' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
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

                Mock `
                    -CommandName Set-Partition `
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
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 2
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When using online GPT disk with correct partition/volume but wrong Volume Label assigned specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
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
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-PartitionAccessPath -Exactly -Times 0
                }
            }
        }

        Describe 'DSC_DiskAccessPath\Test-TargetResource' {
            Mock `
                -CommandName Get-CimInstance `
                -MockWith { $script:mockedCim }

            Context 'When using disk not initialized specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdNumber `
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
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdNumber
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When using disk not initialized specified by Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdUniqueId `
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
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdUniqueId
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When using disk not initialized specified by Disk Guid' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdGuid `
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
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0OfflineDiskIdGuid
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When using disk read only specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0ReadonlyDiskIdNumber `
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
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0ReadonlyDiskIdNumber
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When using online unformatted disk specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0RawDiskIdNumber `
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
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0RawDiskIdNumber
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When using mismatching partition size specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
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
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size 124 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When using mismatched AllocationUnitSize specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
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
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -AllocationUnitSize 4097 `
                            -Verbose
                    } | Should -Not -Throw
                }

                <#
                    Mismatching AllocationUnitSize should not trigger a change until
                    AllowDestructive and ClearDisk switches implemented. See:
                    https://github.com/PowerShell/StorageDsc/issues/200
                    Until implemented this test should return true.
                #>
                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When using mismatching FSFormat specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
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
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -FSFormat 'ReFS' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When using mismatching FSLabel specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
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
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When using mismatching NoDefaultDriveLetter specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
                    -MockWith { $script:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionNoDefaultDriveLetter } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0.Number `
                            -AccessPath $script:testAccessPath `
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -FSLabel 'myLabel' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                }
            }

            Context 'When using all disk properties matching specified by Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Assert-AccessPathValid `
                    -MockWith { $script:testAccessPath } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber `
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
                            -NoDefaultDriveLetter $script:NoDefaultDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size $script:mockedPartition.Size `
                            -FSFormat $script:mockedVolume.FileSystem `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Assert-AccessPathValid -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_Disk0DiskIdNumber
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_DiskAccessPath\Test-AccessPathInPSDrive' {
            $getPSDriveWithNameParameterFilter = {
                $Name -eq $script:testAccessPath.Split(':')[0]
            }
            $getPSDriveWithoutNameParameterFilter = {
                $null -eq $Name
            }
            $getPSDriveNoDrivesMock = {
                throw 'Cannot find drive.'
            }
            $getPSDriveDriveFoundMock = {
                @(
                    [PSCustomObject] @{
                        Name = 'C'
                    }
                )
            }

            Context 'When the access path is found' {
                Mock `
                    -CommandName Get-PSDrive `
                    -MockWith $getPSDriveDriveFoundMock `
                    -ParameterFilter $getPSDriveWithNameParameterFilter

                Mock `
                    -CommandName Get-PSDrive `
                    -ParameterFilter $getPSDriveWithoutNameParameterFilter

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-AccessPathInPSDrive `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PSDrive `
                        -ParameterFilter $getPSDriveWithNameParameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-PSDrive `
                        -ParameterFilter $getPSDriveWithoutNameParameterFilter `
                        -Exactly -Times 0
                }
            }

            Context 'When the access path is not found in the PSDrive list and not found after refresh' {
                Mock `
                    -CommandName Get-PSDrive `
                    -MockWith $getPSDriveNoDrivesMock `
                    -ParameterFilter $getPSDriveWithNameParameterFilter

                Mock `
                    -CommandName Get-PSDrive `
                    -ParameterFilter $getPSDriveWithoutNameParameterFilter

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-AccessPathInPSDrive `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PSDrive `
                        -ParameterFilter $getPSDriveWithNameParameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-PSDrive `
                        -ParameterFilter $getPSDriveWithoutNameParameterFilter `
                        -Exactly -Times 1
                }
            }

            Context 'When the access path is not found in the PSDrive list but is found after refresh' {
                Mock `
                    -CommandName Get-PSDrive `
                    -MockWith $getPSDriveNoDrivesMock `
                    -ParameterFilter $getPSDriveWithNameParameterFilter

                Mock `
                    -CommandName Get-PSDrive `
                    -MockWith $getPSDriveDriveFoundMock `
                    -ParameterFilter $getPSDriveWithoutNameParameterFilter

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-AccessPathInPSDrive `
                            -AccessPath $script:testAccessPath `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PSDrive `
                        -ParameterFilter $getPSDriveWithNameParameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-PSDrive `
                        -ParameterFilter $getPSDriveWithoutNameParameterFilter `
                        -Exactly -Times 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
