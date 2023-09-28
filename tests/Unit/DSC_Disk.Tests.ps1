$script:dscModuleName = 'StorageDsc'
$script:dscResourceName = 'DSC_Disk'

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
        $script:testDriveLetter = 'G'
        $script:testDriveLetterH = 'H'
        $script:testDiskNumber = 1
        $script:testDiskUniqueId = 'TESTDISKUNIQUEID'
        $script:testDiskFriendlyName = 'TESTDISKFRIENDLYNAME'
        $script:testDiskSerialNumber = 'TESTDISKSERIALNUMBER'
        $script:testDiskGptGuid = [guid]::NewGuid()

        $script:mockedDisk0Gpt = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            FriendlyName   = $script:testDiskFriendlyName
            SerialNumber   = $script:testDiskSerialNumber
            Guid           = $script:testDiskGptGuid
            IsOffline      = $false
            IsReadOnly     = $false
            PartitionStyle = 'GPT'
        }

        $script:mockedDisk0Mbr = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            FriendlyName   = $script:testDiskFriendlyName
            SerialNumber   = $script:testDiskSerialNumber
            Guid           = ''
            IsOffline      = $false
            IsReadOnly     = $false
            PartitionStyle = 'MBR'
        }

        $script:mockedDisk0Raw = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            FriendlyName   = $script:testDiskFriendlyName
            SerialNumber   = $script:testDiskSerialNumber
            Guid           = ''
            IsOffline      = $false
            IsReadOnly     = $false
            PartitionStyle = 'RAW'
        }

        $script:mockedDisk0GptOffline = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            FriendlyName   = $script:testDiskFriendlyName
            SerialNumber   = $script:testDiskSerialNumber
            Guid           = $script:testDiskGptGuid
            IsOffline      = $true
            IsReadOnly     = $false
            PartitionStyle = 'GPT'
        }

        $script:mockedDisk0RawOffline = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            FriendlyName   = $script:testDiskFriendlyName
            SerialNumber   = $script:testDiskSerialNumber
            Guid           = ''
            IsOffline      = $true
            IsReadOnly     = $false
            PartitionStyle = 'RAW'
        }

        $script:mockedDisk0GptReadonly = [pscustomobject] @{
            Number         = $script:testDiskNumber
            UniqueId       = $script:testDiskUniqueId
            FriendlyName   = $script:testDiskFriendlyName
            SerialNumber   = $script:testDiskSerialNumber
            Guid           = $script:testDiskGptGuid
            IsOffline      = $false
            IsReadOnly     = $true
            PartitionStyle = 'GPT'
        }

        $script:mockedDisk0GptForDevDrive = [pscustomobject] @{
            Number            = $script:testDiskNumber
            UniqueId          = $script:testDiskUniqueId
            FriendlyName      = $script:testDiskFriendlyName
            SerialNumber      = $script:testDiskSerialNumber
            Guid              = $script:testDiskGptGuid
            IsOffline         = $false
            IsReadOnly        = $false
            PartitionStyle    = 'GPT'
            Size              = 100Gb
            LargestFreeExtent = 90Gb
        }

        $script:mockedDisk0RawForDevDrive = [pscustomobject] @{
            Number            = $script:testDiskNumber
            UniqueId          = $script:testDiskUniqueId
            FriendlyName      = $script:testDiskFriendlyName
            SerialNumber      = $script:testDiskSerialNumber
            Guid              = ''
            IsOffline         = $false
            IsReadOnly        = $false
            PartitionStyle    = 'RAW'
            Size              = 80Gb
            LargestFreeExtent = 0
        }

        $script:mockedCim = [pscustomobject] @{
            BlockSize = 4096
        }

        $script:mockedPartitionSize = 1GB

        $script:mockedPartition = [pscustomobject] @{
            DriveLetter     = [System.Char] $script:testDriveLetter
            Size            = $script:mockedPartitionSize
            PartitionNumber = 1
            Type            = 'Basic'
        }

        $script:mockedPartitionSize40Gb = 40GB

        $script:mockedPartitionSize50Gb = 50GB

        $script:mockedPartitionWithGDriveletter = [pscustomobject] @{
            DriveLetter     = [System.Char] $script:testDriveLetter
            Size            = $script:mockedPartitionSize50Gb
            PartitionNumber = 1
            Type            = 'Basic'
        }

        $script:mockedPartitionWithHDriveLetter = [pscustomobject] @{
            DriveLetter     = [System.Char] $script:testDriveLetterH
            Size            = $script:mockedPartitionSize50Gb
            PartitionNumber = 1
            Type            = 'Basic'
        }

        <#
            This condition seems to occur in some systems where the
            same partition is reported twice with the same drive letter.
        #>
        $script:mockedPartitionMultiple = @(
            [pscustomobject] @{
                DriveLetter     = [System.Char] $script:testDriveLetter
                Size            = $script:mockedPartitionSize
                PartitionNumber = 1
                Type            = 'Basic'
            },
            [pscustomobject] @{
                DriveLetter     = [System.Char] $script:testDriveLetter
                Size            = $script:mockedPartitionSize
                PartitionNumber = 1
                Type            = 'Basic'
            }
        )

        $script:mockedPartitionNoDriveLetter = [pscustomobject] @{
            DriveLetter     = [System.Char] $null
            Size            = $script:mockedPartitionSize
            PartitionNumber = 1
            Type            = 'Basic'
            IsReadOnly      = $false
        }

        $script:mockedPartitionNoDriveLetter50Gb = [pscustomobject] @{
            DriveLetter     = [System.Char] $null
            Size            = $script:mockedPartitionSize50Gb
            PartitionNumber = 1
            Type            = 'Basic'
            IsReadOnly      = $false
        }

        $script:mockedPartitionNoDriveLetterReadOnly = [pscustomobject] @{
            DriveLetter     = [System.Char] $null
            Size            = $script:mockedPartitionSize
            PartitionNumber = 1
            Type            = 'Basic'
            IsReadOnly      = $true
        }

        $script:mockedVolume = [pscustomobject] @{
            FileSystemLabel = 'myLabel'
            FileSystem      = 'NTFS'
            DriveLetter     = $script:testDriveLetter
        }

        $script:mockedVolumeUnformatted = [pscustomobject] @{
            FileSystemLabel = ''
            FileSystem      = ''
            DriveLetter     = ''
        }

        $script:mockedVolumeNoDriveLetter = [pscustomobject] @{
            FileSystemLabel = 'myLabel'
            FileSystem      = 'NTFS'
            DriveLetter     = ''
        }

        $script:mockedVolumeReFS = [pscustomobject] @{
            FileSystemLabel = 'myLabel'
            FileSystem      = 'ReFS'
            DriveLetter     = $script:testDriveLetter
        }

        $script:parameterFilter_MockedDisk0Number = {
            $DiskId -eq $script:mockedDisk0Gpt.Number -and $DiskIdType -eq 'Number'
        }

        $script:UninitializeDiskSizeParamsForDevDrive = {
            $UserDesiredSize -eq $script:userDesiredSize60Gb -and
            $CurrentDiskFreeSpace -eq $script:mockedDisk0RawForDevDrive.size -and
            $DiskNumber -eq $script:mockedDisk0RawForDevDrive.Number
        }

        $script:InitializeDiskSizeParamsForDevDrive = {
            $UserDesiredSize -eq $script:userDesiredSize60Gb -and
            $CurrentDiskFreeSpace -eq $script:mockedDisk0GptForDevDrive.LargestFreeExtent -and
            $DiskNumber -eq $script:mockedDisk0GptForDevDrive.Number
        }

        $script:userDesiredSize60Gb = 60Gb

        $script:userDesiredSize50Gb = 50Gb

        $script:userDesiredSize40Gb = 40Gb

        $script:userDesiredSizeZeroGb = 0Gb

        $script:currentFreeSpaceSize60Gb = 60Gb

        $script:currentFreeSpaceSize50Gb = 50Gb

        <#
            These functions are required to be able to mock functions where
            values are passed in via the pipeline.
        #>
        function Set-Disk
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

        function Initialize-Disk
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

        function Get-Partition
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

        function New-Partition
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

        function Set-Partition
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

        function Get-Volume
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

        function Set-Volume
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

        function Format-Volume
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

        function Get-PartitionSupportedSize
        {
            param
            (
                [Parameter(ValueFromPipeline = $true)]
                [System.String]
                $DriveLetter
            )
        }

        function Resize-Partition
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

        function Clear-Disk
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

        function Get-IsApiSetImplemented
        {
            [CmdletBinding()]
            Param
            (
                [OutputType([System.Boolean])]
                [String]
                $Contract
            )
        }

        function Get-DeveloperDriveEnablementState
        {
            [CmdletBinding()]
            [OutputType([System.Enum])]
            Param
            ()
        }

        function Assert-DevDriveFormatOnReFsFileSystemOnly
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true)]
                [System.String]
                $FSFormat
            )
        }

        function Assert-DiskHasEnoughSpaceToCreateDevDrive
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true)]
                [System.UInt64]
                $UserDesiredSize,

                [Parameter(Mandatory = $true)]
                [System.UInt64]
                $CurrentDiskFreeSpace,

                [Parameter(Mandatory = $true)]
                [System.UInt32]
                $DiskNumber
            )
        }

        function Assert-DevDriveSizeMeetsMinimumRequirement
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true)]
                [System.UInt64]
                $UserDesiredSize
            )
        }

        Describe 'DSC_Disk\Get-TargetResource' {
            Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                    -DiskId $script:mockedDisk0Gpt.Number `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0Gpt.Number)" {
                    $resource.DiskId | Should -Be $script:mockedDisk0Gpt.Number
                }

                It "Should return PartitionStyle $($script:mockedDisk0Gpt.PartitionStyle)" {
                    $resource.PartitionStyle | Should -Be $script:mockedDisk0Gpt.PartitionStyle
                }

                It "Should return DriveLetter $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should -Be $script:testDriveLetter
                }

                It "Should return size $($script:mockedPartition.Size)" {
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
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Number with partition reported twice' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionMultiple } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                $resource = Get-TargetResource `
                    -DiskId $script:mockedDisk0Gpt.Number `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0Gpt.Number)" {
                    $resource.DiskId | Should -Be $script:mockedDisk0Gpt.Number
                }

                It "Should return PartitionStyle $($script:mockedDisk0Gpt.PartitionStyle)" {
                    $resource.PartitionStyle | Should -Be $script:mockedDisk0Gpt.PartitionStyle
                }

                It "Should return DriveLetter $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should -Be $script:testDriveLetter
                }

                It "Should return size $($script:mockedPartition.Size)" {
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
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.UniqueId -and $DiskIdType -eq 'UniqueId' } `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                    -DiskId $script:mockedDisk0Gpt.UniqueId `
                    -DiskIdType 'UniqueId' `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0Gpt.UniqueId)" {
                    $resource.DiskId | Should -Be $script:mockedDisk0Gpt.UniqueId
                }

                It "Should return PartitionStyle $($script:mockedDisk0Gpt.PartitionStyle)" {
                    $resource.PartitionStyle | Should -Be $script:mockedDisk0Gpt.PartitionStyle
                }

                It "Should return DriveLetter $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should -Be $script:testDriveLetter
                }

                It "Should return size $($script:mockedPartition.Size)" {
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
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.UniqueId -and $DiskIdType -eq 'UniqueId' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Friendly Name' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.FriendlyName -and $DiskIdType -eq 'FriendlyName' } `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                    -DiskId $script:mockedDisk0Gpt.FriendlyName `
                    -DiskIdType 'FriendlyName' `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0Gpt.FriendlyName)" {
                    $resource.DiskId | Should -Be $script:mockedDisk0Gpt.FriendlyName
                }

                It "Should return PartitionStyle $($script:mockedDisk0Gpt.PartitionStyle)" {
                    $resource.PartitionStyle | Should -Be $script:mockedDisk0Gpt.PartitionStyle
                }

                It "Should return DriveLetter $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should -Be $script:testDriveLetter
                }

                It "Should return size $($script:mockedPartition.Size)" {
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
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.FriendlyName -and $DiskIdType -eq 'FriendlyName' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Serial Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.SerialNumber -and $DiskIdType -eq 'SerialNumber' } `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                    -DiskId $script:mockedDisk0Gpt.SerialNumber `
                    -DiskIdType 'SerialNumber' `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0Gpt.SerialNumber)" {
                    $resource.DiskId | Should -Be $script:mockedDisk0Gpt.SerialNumber
                }

                It "Should return PartitionStyle $($script:mockedDisk0Gpt.PartitionStyle)" {
                    $resource.PartitionStyle | Should -Be $script:mockedDisk0Gpt.PartitionStyle
                }

                It "Should return DriveLetter $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should -Be $script:testDriveLetter
                }

                It "Should return size $($script:mockedPartition.Size)" {
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
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.SerialNumber -and $DiskIdType -eq 'SerialNumber' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Guid' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.Guid -and $DiskIdType -eq 'Guid' } `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                    -DiskId $script:mockedDisk0Gpt.Guid `
                    -DiskIdType 'Guid' `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0Gpt.Guid)" {
                    $resource.DiskId | Should -Be $script:mockedDisk0Gpt.Guid
                }

                It "Should return PartitionStyle $($script:mockedDisk0Gpt.PartitionStyle)" {
                    $resource.PartitionStyle | Should -Be $script:mockedDisk0Gpt.PartitionStyle
                }

                It "Should return DriveLetter $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should -Be $script:testDriveLetter
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
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.Guid -and $DiskIdType -eq 'Guid' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'When online GPT disk with a partition/volume and correct Drive Letter assigned using Disk Guid' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $script:mockedCim } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.Guid -and $DiskIdType -eq 'Guid' } `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                    -DiskId $script:mockedDisk0Gpt.Guid `
                    -DiskIdType 'Guid' `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0Gpt.Guid)" {
                    $resource.DiskId | Should -Be $script:mockedDisk0Gpt.Guid
                }

                It "Should return PartitionStyle $($script:mockedDisk0Gpt.PartitionStyle)" {
                    $resource.PartitionStyle | Should -Be $script:mockedDisk0Gpt.PartitionStyle
                }

                It "Should return DriveLetter $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should -Be $script:testDriveLetter
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
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.Guid -and $DiskIdType -eq 'Guid' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'When online GPT disk with no partition using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -Verifiable

                $resource = Get-TargetResource `
                    -DiskId $script:mockedDisk0Gpt.Number `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0Gpt.Number)" {
                    $resource.DiskId | Should -Be $script:mockedDisk0Gpt.Number
                }

                It "Should return PartitionStyle $($script:mockedDisk0Gpt.PartitionStyle)" {
                    $resource.PartitionStyle | Should -Be $script:mockedDisk0Gpt.PartitionStyle
                }

                It "Should return an empty drive letter" {
                    $resource.DriveLetter | Should -BeNullOrEmpty
                }

                It "Should return a zero size" {
                    $resource.Size | Should -BeNullOrEmpty
                }

                It "Should return no FSLabel" {
                    $resource.FSLabel | Should -BeNullOrEmpty
                }

                It "Should return an AllocationUnitSize of 0" {
                    $resource.AllocationUnitSize | Should -BeNullOrEmpty
                }

                It "Should return no FSFormat" {
                    $resource.FSFormat | Should -BeNullOrEmpty
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'When online MBR disk with no partition using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Mbr } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -Verifiable

                $resource = Get-TargetResource `
                    -DiskId $script:mockedDisk0Mbr.Number `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0Mbr.Number)" {
                    $resource.DiskId | Should -Be $script:mockedDisk0Mbr.Number
                }

                It "Should return PartitionStyle $($script:mockedDisk0Mbr.PartitionStyle)" {
                    $resource.PartitionStyle | Should -Be $script:mockedDisk0Mbr.PartitionStyle
                }

                It "Should return an empty drive letter" {
                    $resource.DriveLetter | Should -BeNullOrEmpty
                }

                It "Should return a zero size" {
                    $resource.Size | Should -BeNullOrEmpty
                }

                It "Should return no FSLabel" {
                    $resource.FSLabel | Should -BeNullOrEmpty
                }

                It "Should return an AllocationUnitSize of 0" {
                    $resource.AllocationUnitSize | Should -BeNullOrEmpty
                }

                It "Should return no FSFormat" {
                    $resource.FSFormat | Should -BeNullOrEmpty
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'When online RAW disk with no partition using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Raw } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -Verifiable

                $resource = Get-TargetResource `
                    -DiskId $script:mockedDisk0Raw.Number `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "Should return DiskId $($script:mockedDisk0Raw.Number)" {
                    $resource.DiskId | Should -Be $script:mockedDisk0Raw.Number
                }

                It "Should return PartitionStyle $($script:mockedDisk0Raw.PartitionStyle)" {
                    $resource.PartitionStyle | Should -Be $script:mockedDisk0Raw.PartitionStyle
                }

                It "Should return an empty drive letter" {
                    $resource.DriveLetter | Should -BeNullOrEmpty
                }

                It "Should return a zero size" {
                    $resource.Size | Should -BeNullOrEmpty
                }

                It "Should return no FSLabel" {
                    $resource.FSLabel | Should -BeNullOrEmpty
                }

                It "Should return an AllocationUnitSize of 0" {
                    $resource.AllocationUnitSize | Should -BeNullOrEmpty
                }

                It "Should return no FSFormat" {
                    $resource.FSFormat | Should -BeNullOrEmpty
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly 1
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }
        }

        Describe 'DSC_Disk\Set-TargetResource' {
            Context 'When offline GPT disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.Number -and $DiskIdType -eq 'Number' } `
                    -MockWith { $script:mockedDisk0GptOffline } `
                    -Verifiable

                Mock `
                    -CommandName Set-Disk `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter { $DriveLetter -eq $script:testDriveLetter } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0GptOffline.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter { $DriveLetter -eq $script:testDriveLetter }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When offline GPT disk using Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.UniqueId -and $DiskIdType -eq 'UniqueId' } `
                    -MockWith { $script:mockedDisk0GptOffline } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0GptOffline.UniqueId `
                            -DiskIdType 'UniqueId' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.UniqueId -and $DiskIdType -eq 'UniqueId' }
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When offline GPT disk using Disk Friendly Name' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.FriendlyName -and $DiskIdType -eq 'FriendlyName' } `
                    -MockWith { $script:mockedDisk0GptOffline } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0GptOffline.FriendlyName `
                            -DiskIdType 'FriendlyName' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.FriendlyName -and $DiskIdType -eq 'FriendlyName' }
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When offline GPT disk using Disk Serial Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.SerialNumber -and $DiskIdType -eq 'SerialNumber' } `
                    -MockWith { $script:mockedDisk0GptOffline } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0GptOffline.SerialNumber `
                            -DiskIdType 'SerialNumber' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.SerialNumber -and $DiskIdType -eq 'SerialNumber' }
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When offline GPT disk using Disk Guid' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.Guid -and $DiskIdType -eq 'Guid' } `
                    -MockWith { $script:mockedDisk0GptOffline } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0GptOffline.Guid `
                            -DiskIdType 'Guid' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.Guid -and $DiskIdType -eq 'Guid' }
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When readonly GPT disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0GptReadonly } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0GptReadonly.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When offline RAW disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0RawOffline } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0RawOffline.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When online RAW disk with Size using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Raw.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -AllocationUnitSize 64 `
                            -FSLabel 'MyDisk' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When online GPT disk with no partitions using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When online GPT disk with no partitions using Disk Number, partition fails to become writeable' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionNoDriveLetterReadOnly } `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {$DriveLetter -eq $script:testDriveLetter} `
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

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.NewParitionIsReadOnlyError -f `
                        'Number', $script:mockedDisk0Mbr.Number, $script:mockedPartitionNoDriveLetterReadOnly.PartitionNumber)

                It 'Should throw NewParitionIsReadOnlyError' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                $endTime = Get-Date

                It 'Should take at least 30s' {
                    ($endTime - $startTime).TotalSeconds | Should -BeGreaterThan 29
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    <#
                        Get-Partition will be called multiple times, but depending on
                        performance of the call to Get-Partition, it may be called a
                        different number of times.
                        E.g. on Azure DevOps agents running Windows Server 2016 it is
                        called at least 28 times.
                    #>
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
                }
            }

            Context 'When online GPT disk with no partitions using Disk Number, partition is writable' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {$DriveLetter -eq $script:testDriveLetter} `
                    -MockWith { $script:mockedPartitionNoDriveLetter } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Set-Volume
                Mock -CommandName Get-Volume
                Mock -CommandName Format-Volume
                Mock -CommandName Set-Partition

                $startTime = Get-Date

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                $endTime = Get-Date

                It 'Should take at least 3s' {
                    ($endTime - $startTime).TotalSeconds | Should -BeGreaterThan 2
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 2
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When online MBR disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
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
                    -Message ($LocalizedData.DiskInitializedWithWrongPartitionStyleError -f `
                        'Number', $script:mockedDisk0Mbr.Number, $script:mockedDisk0Mbr.PartitionStyle, 'GPT')

                It 'Should not throw DiskInitializedWithWrongPartitionStyleError' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Mbr.Number `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
                }
            }

            Context 'When online MBR disk using Disk Unique Id but GPT required and AllowDestructive and ClearDisk are false' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
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
                    -Message ($LocalizedData.DiskInitializedWithWrongPartitionStyleError -f `
                        'UniqueId', $script:mockedDisk0Mbr.UniqueId, $script:mockedDisk0Mbr.PartitionStyle, 'GPT')

                It 'Should throw DiskInitializedWithWrongPartitionStyleError' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Mbr.UniqueId `
                            -DiskIdType 'UniqueId' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
                }
            }

            Context 'When online GPT disk with partition/volume already assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
                }
            }

            Context 'When online GPT disk containing matching partition but not assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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

                It 'Should not throw an exception' {
                    {
                        Set-targetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When online GPT disk with a partition/volume and wrong Drive Letter assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter 'H' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When online GPT disk with a partition/volume and no Drive Letter assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter 'H' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 2
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When online GPT disk with a partition/volume and wrong Volume Label assigned using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
                }
            }

            Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume without assigned drive letter and wrong size' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size ($script:mockedPartitionSize + 1024) `
                            -AllowDestructive $true `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-Volume -Exactly -Times 0
                }
            }

            Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume but wrong size and remaining size too small' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.FreeSpaceViolationError -f `
                        $script:mockedPartition.DriveLetter, $script:mockedPartition.Size, ($script:mockedPartitionSize + 1024), 1) `
                    -ArgumentName 'Size'

                It 'Should throw FreeSpaceViolationError' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size ($script:mockedPartitionSize + 1024) `
                            -AllowDestructive $true `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-PartitionSupportedSize -Exactly -Times 1
                    Assert-MockCalled -CommandName Resize-Partition -Exactly -Times 0
                }
            }

            Context 'When AllowDestructive enabled with Size not specified on Online GPT disk with matching partition/volume but wrong size' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                            SizeMax = 2GB
                        }
                    } `
                    -Verifiable

                Mock `
                    -CommandName Resize-Partition `
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
                Mock -CommandName Set-Partition
                Mock -CommandName Format-Volume

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -AllowDestructive $true `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-PartitionSupportedSize -Exactly -Times 1
                    Assert-MockCalled -CommandName Resize-Partition -Exactly -Times 1
                }
            }

            Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume but wrong size and ReFS' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                Mock -CommandName Resize-Partition

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size ($script:mockedPartitionSize + 1024) `
                            -AllowDestructive $true `
                            -FSLabel 'NewLabel' `
                            -FSFormat 'ReFS' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-PartitionSupportedSize -Exactly -Times 1
                    Assert-MockCalled -CommandName Resize-Partition -Exactly -Times 0
                }
            }

            Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume but wrong format' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -FSFormat 'ReFS' `
                            -FSLabel 'NewLabel' `
                            -AllowDestructive $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
                }
            }

            Context 'When AllowDestructive and ClearDisk enabled with Online GPT disk containing arbitrary partitions' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -FSLabel 'NewLabel' `
                            -AllowDestructive $true `
                            -ClearDisk $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 2 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Clear-Disk -Exactly -Times 1
                }
            }

            Context 'When AllowDestructive and ClearDisk enabled with Online MBR disk containing arbitrary partitions but GPT required' {
                <#
                    This variable is so that we can change the behavior of the
                    Get-DiskByIdentifier mock after the first time it is called
                    in the Set-TargetResource function.
                #>
                $script:getDiskByIdentifierCalled = $false

                $script:parameterFilter_MockedDisk0Number = {
                    $DiskId -eq $script:mockedDisk0Gpt.Number -and $DiskIdType -eq 'Number'
                }

                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter {
                        $DiskId -eq $script:mockedDisk0Gpt.Number `
                            -and $DiskIdType -eq 'Number' `
                            -and $script:getDiskByIdentifierCalled -eq $false
                    } `
                    -MockWith {
                        $script:getDiskByIdentifierCalled = $true
                        return $script:mockedDisk0Mbr
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter {
                        $DiskId -eq $script:mockedDisk0Gpt.Number `
                            -and $DiskIdType -eq 'Number' `
                            -and $script:getDiskByIdentifierCalled -eq $true
                    } `
                    -MockWith {
                        return $script:mockedDisk0Raw
                    } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -FSLabel 'NewLabel' `
                            -AllowDestructive $true `
                            -ClearDisk $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 2 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Clear-Disk -Exactly -Times 1
                }
            }

            Context 'When Dev Drive flag is enabled and format volume is called with the Dev Drive flag' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0GptForDevDrive } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetter `
                            -Size $script:mockedPartitionSize `
                            -FSLabel 'NewLabel' `
                            -FSFormat 'ReFS' `
                            -DevDrive $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetter
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1 `
                        -ParameterFilter {
                        $DevDrive -eq $true
                    }
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When the user explicitly wants to create a new drive on unallocated space regardless of whether there is a partition that matches the size parameter or not. ' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0GptForDevDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionWithGDriveletter } `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                    $DriveLetter -eq $script:testDriveLetterH
                } `
                    -MockWith { $script:mockedPartitionNoDriveLetter50Gb } `
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

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetterH `
                            -Size $script:mockedPartitionSize50Gb `
                            -FSLabel 'NewLabel' `
                            -FSFormat 'ReFS' `
                            -DevDrive $true `
                            -UseUnallocatedSpace $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName New-Partition -Exactly -Times 1 `
                        -ParameterFilter {
                        $DriveLetter -eq $script:testDriveLetterH
                    }
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1 `
                        -ParameterFilter {
                        $DevDrive -eq $true
                    }
                    Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
                }
            }

            Context 'When the user wants to create a dev drive volume by overwriting a volume that already exists with AllowDestructive set to true' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0GptForDevDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionWithGDriveletter } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeReFS } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -Driveletter $script:testDriveLetterH `
                            -Size $script:mockedPartitionSize50Gb `
                            -FSLabel 'NewLabel' `
                            -FSFormat 'NTFS' `
                            -DevDrive $true `
                            -AllowDestructive $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1 `
                        -ParameterFilter {
                        $DevDrive -eq $true
                    }
                }
            }
        }

        Describe 'DSC_Disk\Test-TargetResource' {
            Mock `
                -CommandName Get-CimInstance `
                -MockWith { $script:mockedCim }

            Context 'When testing disk does not exist using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0GptOffline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0GptOffline.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing disk offline using Disk Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.Number -and $DiskIdType -eq 'Number' } `
                    -MockWith { $script:mockedDisk0GptOffline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0GptOffline.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing disk offline using Unique Id' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.UniqueId -and $DiskIdType -eq 'UniqueId' } `
                    -MockWith { $script:mockedDisk0GptOffline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0GptOffline.UniqueId `
                            -DiskIdType 'UniqueId' `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.UniqueId -and $DiskIdType -eq 'UniqueId' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing disk offline using Friendly Name' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.FriendlyName -and $DiskIdType -eq 'FriendlyName' } `
                    -MockWith { $script:mockedDisk0GptOffline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0GptOffline.FriendlyName `
                            -DiskIdType 'FriendlyName' `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.FriendlyName -and $DiskIdType -eq 'FriendlyName' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing disk offline using Serial Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.SerialNumber -and $DiskIdType -eq 'SerialNumber' } `
                    -MockWith { $script:mockedDisk0GptOffline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0GptOffline.SerialNumber `
                            -DiskIdType 'SerialNumber' `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.SerialNumber -and $DiskIdType -eq 'SerialNumber' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing disk offline using Disk Guid' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0Gpt.Guid -and $DiskIdType -eq 'Guid' } `
                    -MockWith { $script:mockedDisk0GptOffline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0GptOffline.Guid `
                            -DiskIdType 'Guid' `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0GptOffline.Guid -and $DiskIdType -eq 'Guid' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing disk read only using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $script:mockedDisk0GptReadonly.Number -and $DiskIdType -eq 'Number' } `
                    -MockWith { $script:mockedDisk0GptReadonly } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0GptReadonly.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $script:mockedDisk0GptReadonly.Number -and $DiskIdType -eq 'Number' }
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing online unformatted disk using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
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
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing online disk using Disk Number with partition style GPT but requiring MBR' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Mbr } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.DiskInitializedWithWrongPartitionStyleError -f `
                        'Number', $script:mockedDisk0Mbr.Number, $script:mockedDisk0Mbr.PartitionStyle, 'GPT')

                It 'Should throw DiskInitializedWithWrongPartitionStyleError' {
                    {
                        Test-TargetResource `
                            -DiskId $script:mockedDisk0Mbr.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing online disk using Disk Number with partition style MBR but requiring GPT' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.DiskInitializedWithWrongPartitionStyleError -f `
                        'Number', $script:mockedDisk0Gpt.Number, $script:mockedDisk0Gpt.PartitionStyle, 'MBR')

                It 'Should throw DiskInitializedWithWrongPartitionStyleError' {
                    {
                        Test-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -PartitionStyle 'MBR' `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing online disk using Disk Number with partition style MBR but requiring GPT and AllowDestructive and ClearDisk is True' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -PartitionStyle 'MBR' `
                            -AllowDestructive $true `
                            -ClearDisk $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing mismatching partition size using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size ($script:mockedPartitionSize + 1MB) `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When testing mismatching partition size with AllowDestructive using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartition } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-PartitionSupportedSize
                Mock -CommandName Get-Volume
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size ($script:mockedPartitionSize + 1MB) `
                            -AllowDestructive $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-PartitionSupportedSize -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing mismatching partition size without Size specified using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                            # Adding >1MB, otherwise workaround for wrong SizeMax is triggered
                            SizeMax = $script:mockedPartition.Size + 1.1MB
                        }
                    } `
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
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-PartitionSupportedSize -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When testing mismatching partition size without Size specified using Disk Number with partition reported twice' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionMultiple } `
                    -Verifiable

                Mock `
                    -CommandName Get-PartitionSupportedSize `
                    -MockWith {
                        return @{
                            SizeMin = 0
                            # Adding >1MB, otherwise workaround for wrong SizeMax is triggered
                            SizeMax = $script:mockedPartition.Size + 1.1MB
                        }
                    } `
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
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-PartitionSupportedSize -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When testing mismatching partition size with AllowDestructive and without Size specified using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                            # Adding >1MB, otherwise workaround for wrong SizeMax is triggered
                            SizeMax = $script:mockedPartition.Size + 1.1MB
                        }
                    } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -AllowDestructive $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-PartitionSupportedSize -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing matching partition size with a less than 1MB difference in desired size and with AllowDestructive and without Size specified using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                            SizeMax = $script:mockedPartition.Size + 0.98MB
                        }
                    } `
                    -Verifiable
                Mock -CommandName Get-Volume -Verifiable
                Mock -CommandName Get-CimInstance -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -AllowDestructive $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-PartitionSupportedSize -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When testing mismatched AllocationUnitSize using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4097 `
                            -AllowDestructive $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When testing mismatching FSFormat using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -FSFormat 'ReFS' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When testing mismatching FSFormat using Disk Number and AllowDestructive' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -FSFormat 'ReFS' `
                            -AllowDestructive $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When testing mismatching FSLabel using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When testing mismatching DriveLetter using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter 'Z' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0
                }
            }

            Context 'When testing all disk properties matching using Disk Number' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
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
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size $script:mockedPartition.Size `
                            -FSLabel $script:mockedVolume.FileSystemLabel `
                            -FSFormat $script:mockedVolume.FileSystem `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should be true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'When the Dev Drive flag is enabled, and the user is attempting to put Dev Drive volume in an existing partition' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0Gpt } `
                    -Verifiable

                Mock `
                    -CommandName Assert-DevDriveFeatureAvailable `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $null } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size $script:userDesiredSize60Gb `
                            -FSLabel $script:mockedVolume.FileSystemLabel `
                            -FSFormat $script:mockedVolumeReFS.FileSystem `
                            -DevDrive $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Assert-DevDriveFeatureAvailable -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                }
            }

            Context 'When the Dev Drive flag is enabled, disk is initialized, and the user is attempting to put a Dev Drive volume in a new partition' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                    -MockWith { $script:mockedDisk0GptForDevDrive } `
                    -Verifiable

                Mock `
                    -CommandName Assert-DevDriveFeatureAvailable `
                    -Verifiable

                Mock `
                    -CommandName Assert-DiskHasEnoughSpaceToCreateDevDrive `
                    -ParameterFilter $script:InitializeDiskSizeParamsForDevDrive `
                    -Verifiable

                Mock `
                    -CommandName Assert-DevDriveFormatOnReFsFileSystemOnly `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $null } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId $script:mockedDisk0Gpt.Number `
                            -DriveLetter $script:testDriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size $script:userDesiredSize60Gb `
                            -FSLabel $script:mockedVolume.FileSystemLabel `
                            -FSFormat $script:mockedVolumeReFS.FileSystem `
                            -DevDrive $true `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter $script:parameterFilter_MockedDisk0Number
                    Assert-MockCalled -CommandName Assert-DevDriveFeatureAvailable -Exactly -Times 1
                    Assert-MockCalled -CommandName Assert-DiskHasEnoughSpaceToCreateDevDrive -Exactly -Times 1 `
                        -ParameterFilter $script:InitializeDiskSizeParamsForDevDrive
                    Assert-MockCalled -CommandName Assert-DevDriveFormatOnReFsFileSystemOnly -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Exactly -Times 2
                }
            }
        }

        Context 'When the Dev Drive flag is enabled, disk is not initialized, and the user is attempting to put a Dev Drive volume in a new partition' {
            # verifiable (should be called) mocks
            Mock `
                -CommandName Get-DiskByIdentifier `
                -ParameterFilter $script:parameterFilter_MockedDisk0Number `
                -MockWith { $script:mockedDisk0RawForDevDrive } `
                -Verifiable

            Mock `
                -CommandName Assert-DevDriveFeatureAvailable `
                -Verifiable

            Mock `
                -CommandName Assert-DiskHasEnoughSpaceToCreateDevDrive `
                -ParameterFilter $script:UninitializeDiskSizeParamsForDevDrive `
                -Verifiable

            Mock `
                -CommandName Assert-DevDriveFormatOnReFsFileSystemOnly `
                -Verifiable

            Mock `
                -CommandName Get-Partition `
                -MockWith { $null } `
                -Verifiable

            It 'Should not throw an exception' {
                {
                    $script:result = Test-TargetResource `
                        -DiskId $script:mockedDisk0Gpt.Number `
                        -DriveLetter $script:testDriveLetter `
                        -AllocationUnitSize 4096 `
                        -Size $script:userDesiredSize60Gb `
                        -FSLabel $script:mockedVolume.FileSystemLabel `
                        -FSFormat $script:mockedVolumeReFS.FileSystem `
                        -DevDrive $true `
                        -Verbose
                } | Should -Not -Throw
            }

            It 'Should call the correct mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                    -ParameterFilter $script:parameterFilter_MockedDisk0Number
                Assert-MockCalled -CommandName Assert-DevDriveFeatureAvailable -Exactly -Times 1
                Assert-MockCalled -CommandName Assert-DiskHasEnoughSpaceToCreateDevDrive -Exactly -Times 1 `
                    -ParameterFilter $script:UninitializeDiskSizeParamsForDevDrive
                Assert-MockCalled -CommandName Assert-DevDriveFormatOnReFsFileSystemOnly -Exactly -Times 1
                Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
