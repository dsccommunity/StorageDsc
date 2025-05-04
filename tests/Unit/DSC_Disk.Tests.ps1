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

# $script:testDriveLetterG = 'G'
# $script:testDriveLetterH = 'H'
# $script:testDriveLetterK = 'K'
# $script:testDriveLetterT = 'T'
# $script:testDiskNumber = 1
# = 'TESTDISKUNIQUEID' = 'TESTDISKUNIQUEID'
# $script:testDiskFriendlyName = 'TESTDISKFRIENDLYNAME'
# $script:testDiskSerialNumber = 'TESTDISKSERIALNUMBER'
# $script:testDiskGptGuid = [guid]::NewGuid()

# $script:mockedDisk0Gpt = [PSCustomObject] @{
#     Number         = 1
#     UniqueId       =  'TESTDISKUNIQUEID'
#     FriendlyName   = 'TESTDISKFRIENDLYNAME'
#     SerialNumber   = 'TESTDISKSERIALNUMBER'
#     Guid           = [guid]::NewGuid()
#     IsOffline      = $false
#     IsReadOnly     = $false
#     PartitionStyle = 'GPT'
# }

# $script:mockedDisk0Mbr = [PSCustomObject] @{
#     Number         = 1
#     UniqueId       =  'TESTDISKUNIQUEID'
#     FriendlyName   = 'TESTDISKFRIENDLYNAME'
#     SerialNumber   = 'TESTDISKSERIALNUMBER'
#     Guid           = ''
#     IsOffline      = $false
#     IsReadOnly     = $false
#     PartitionStyle = 'MBR'
# }

# $script:mockedDisk0Raw = [PSCustomObject] @{
#     Number         = 1
#     UniqueId       =  'TESTDISKUNIQUEID'
#     FriendlyName   = 'TESTDISKFRIENDLYNAME'
#     SerialNumber   = 'TESTDISKSERIALNUMBER'
#     Guid           = ''
#     IsOffline      = $false
#     IsReadOnly     = $false
#     PartitionStyle = 'RAW'
# }

# $script:mockedDisk0GptOffline = [PSCustomObject] @{
#     Number         = 1
#     UniqueId       =  'TESTDISKUNIQUEID'
#     FriendlyName   = 'TESTDISKFRIENDLYNAME'
#     SerialNumber   = 'TESTDISKSERIALNUMBER'
#     Guid           = [guid]::NewGuid()
#     IsOffline      = $true
#     IsReadOnly     = $false
#     PartitionStyle = 'GPT'
# }

# $script:mockedDisk0RawOffline = [PSCustomObject] @{
#     Number         = 1
#     UniqueId       =  'TESTDISKUNIQUEID'
#     FriendlyName   = 'TESTDISKFRIENDLYNAME'
#     SerialNumber   = 'TESTDISKSERIALNUMBER'
#     Guid           = ''
#     IsOffline      = $true
#     IsReadOnly     = $false
#     PartitionStyle = 'RAW'
# }

# $script:mockedDisk0GptReadonly = [PSCustomObject] @{
#     Number         = 1
#     UniqueId       = 'TESTDISKUNIQUEID'
#     FriendlyName   = 'TESTDISKFRIENDLYNAME'
#     SerialNumber   = 'TESTDISKSERIALNUMBER'
#     Guid           = [guid]::NewGuid()
#     IsOffline      = $false
#     IsReadOnly     = $true
#     PartitionStyle = 'GPT'
# }

# <#
#             Used in the scenario where a user wants to create a Dev Drive volume
#             and there is sufficient unallocated space available.
#         #>
# $script:mockedDisk0GptForDevDriveResizeNotNeededScenario = [PSCustomObject] @{
#     Number         = 1
#     UniqueId       = 'TESTDISKUNIQUEID'
#     FriendlyName   = 'TESTDISKFRIENDLYNAME'
#     SerialNumber   = 'TESTDISKSERIALNUMBER'
#     Guid           = [guid]::NewGuid()
#     IsOffline      = $false
#     IsReadOnly     = $false
#     PartitionStyle = 'GPT'
#     Size           = 100Gb
# }

# <#
#             Used in the scenario where a user wants to create a Dev Drive volume but there
#             is insufficient unallocated space available and a resize of any partition is not possibile.
#         #>
# $script:mockedDisk0GptForDevDriveResizeNotPossibleScenario = [PSCustomObject] @{
#     Number         = 1
#     UniqueId       = 'TESTDISKUNIQUEID'
#     FriendlyName   = 'TESTDISKFRIENDLYNAME'
#     SerialNumber   = 'TESTDISKSERIALNUMBER'
#     Guid           = [guid]::NewGuid()
#     IsOffline      = $false
#     IsReadOnly     = $false
#     PartitionStyle = 'GPT'
#     Size           = 60Gb
# }

# <#
#             Used in the scenario where a user wants to create a Dev Drive volume but there
#             is insufficient unallocated space available. However a resize of a partition possibile.
#             which will create new unallocated space for the new partition.
#         #>
# $script:mockedDisk0GptForDevDriveResizePossibleScenario = [PSCustomObject] @{
#     Number         = 1
#     UniqueId       = 'TESTDISKUNIQUEID'
#     FriendlyName   = 'TESTDISKFRIENDLYNAME'
#     SerialNumber   = 'TESTDISKSERIALNUMBER'
#     Guid           = [guid]::NewGuid()
#     IsOffline      = $false
#     IsReadOnly     = $false
#     PartitionStyle = 'GPT'
#     Size           = 100Gb
# }

# $script:mockedDisk0GptForDevDriveAfterResize = [PSCustomObject] @{
#     Number            = 1
#     UniqueId          = 'TESTDISKUNIQUEID'
#     FriendlyName      = 'TESTDISKFRIENDLYNAME'
#     SerialNumber      = 'TESTDISKSERIALNUMBER'
#     Guid              = [guid]::NewGuid()
#     IsOffline         = $false
#     IsReadOnly        = $false
#     PartitionStyle    = 'GPT'
#     Size              = 100Gb
#     LargestFreeExtent = 50Gb
# }

# $script:mockedDisk0RawForDevDrive = [PSCustomObject] @{
#     Number            = 1
#     UniqueId          = 'TESTDISKUNIQUEID'
#     FriendlyName      = 'TESTDISKFRIENDLYNAME'
#     SerialNumber      = 'TESTDISKSERIALNUMBER'
#     Guid              = ''
#     IsOffline         = $false
#     IsReadOnly        = $false
#     PartitionStyle    = 'RAW'
#     Size              = 80Gb
#     LargestFreeExtent = 0
# }

# $script:mockedCim = [PSCustomObject] @{
#     BlockSize = 4096
# }

# $script:mockedPartitionSize = 1GB

# $script:mockedPartition = [PSCustomObject] @{
#     DriveLetter     = [System.Char] 'G'
#     Size            = 1GB
#     PartitionNumber = 1
#     Type            = 'Basic'
# }

# $script:mockedPartitionSize40Gb = 40GB

# $script:mockedPartitionSize50Gb = 50GB

# $script:mockedPartitionSize70Gb = 70GB

# $script:mockedPartitionSize100Gb = 100GB

# $script:mockedPartitionWithTDriveLetter = [PSCustomObject] @{
#     DriveLetter     = [System.Char] 'T'
#     Size            = 50GB
#     PartitionNumber = 1
#     Type            = 'Basic'
# }

# $script:mockedPartitionSupportedSizeForTDriveletter = [PSCustomObject] @{
#     DriveLetter = [System.Char] 'T'
#     SizeMax      = 100GB
#     SizeMin     = 10GB
# }

# $script:mockedPartitionWithGDriveletter = [PSCustomObject] @{
#     DriveLetter     = [System.Char] 'G'
#     Size            = 50GB
#     PartitionNumber = 1
#     Type            = 'Basic'
# }

# $script:mockedPartitionSupportedSizeForGDriveletter = [PSCustomObject] @{
#     DriveLetter = [System.Char] 'G'
#     SizeMax     = 50GB
#     SizeMin     = 50GB
# }

# $script:mockedPartitionWithHDriveLetter = [PSCustomObject] @{
#     DriveLetter     = [System.Char] $script:testDriveLetterH
#     Size            = 50GB
#     PartitionNumber = 1
#     Type            = 'Basic'
# }

# $script:mockedPartitionSupportedSizeForHDriveletter = [PSCustomObject] @{
#     DriveLetter = [System.Char] $script:testDriveLetterH
#     SizeMax      = 100GB
#     SizeMin     = 10GB
# }

# $script:mockedPartitionWithKDriveLetter = [PSCustomObject] @{
#     DriveLetter     = [System.Char] $script:testDriveLetterK
#     Size            = $script:mockedPartitionSize70Gb
#     PartitionNumber = 1
#     Type            = 'Basic'
# }

# $script:mockedPartitionSupportedSizeForKDriveletter = [PSCustomObject] @{
#     DriveLetter = [System.Char] $script:testDriveLetterK
#     SizeMax      = 100GB
#     SizeMin     = 1GB
# }

# $script:mockedPartitionListForResizeNotPossibleScenario = @(
#     $script:mockedPartitionWithGDriveletter
# )

# $script:mockedPartitionListForResizeNotNeededScenario = @(
#     $script:mockedPartitionWithGDriveletter,
#     $script:mockedPartitionWithHDriveLetter
# )

# $script:mockedPartitionListForResizePossibleScenario = @(
#     $script:mockedPartitionWithGDriveletter,
#     $script:mockedPartitionWithKDriveLetter
# )

# <#
#             This condition seems to occur in some systems where the
#             same partition is reported twice with the same drive letter.
#         #>
# $script:mockedPartitionMultiple = @(
#     [PSCustomObject] @{
#         DriveLetter     = [System.Char] 'G'
#         Size            = 1GB
#         PartitionNumber = 1
#         Type            = 'Basic'
#     },
#     [PSCustomObject] @{
#         DriveLetter     = [System.Char] 'G'
#         Size            = 1GB
#         PartitionNumber = 1
#         Type            = 'Basic'
#     }
# )

# $script:mockedPartitionNoDriveLetter = [PSCustomObject] @{
#     DriveLetter     = [System.Char] $null
#     Size            = 1GB
#     PartitionNumber = 1
#     Type            = 'Basic'
#     IsReadOnly      = $false
# }

# $script:mockedPartitionNoDriveLetter50Gb = [PSCustomObject] @{
#     DriveLetter     = [System.Char] $null
#     Size            = 50GB
#     PartitionNumber = 1
#     Type            = 'Basic'
#     IsReadOnly      = $false
# }

# $script:mockedPartitionGDriveLetter40Gb = [PSCustomObject] @{
#     DriveLetter     = [System.Char] 'G'
#     Size            = $script:mockedPartitionSize40Gb
#     PartitionNumber = 1
#     Type            = 'Basic'
#     IsReadOnly      = $false
# }

# $script:mockedPartitionGDriveLetter50Gb = [PSCustomObject] @{
#     DriveLetter     = [System.Char] 'G'
#     Size            = 50GB
#     PartitionNumber = 1
#     Type            = 'Basic'
#     IsReadOnly      = $false
# }

# $script:mockedPartitionGDriveLetterAlternatePartition150Gb = [PSCustomObject] @{
#     DriveLetter     = [System.Char] 'G'
#     Size            = 161060225024
#     PartitionNumber = 1
#     Type            = 'Basic'
#     IsReadOnly      = $false
# }

# $script:mockedPartitionGDriveLetter150Gb = [PSCustomObject] @{
#     DriveLetter     = [System.Char] 'G'
#     Size            = 150Gb
#     PartitionNumber = 1
#     Type            = 'Basic'
#     IsReadOnly      = $false
# }

# $script:mockedPartitionNoDriveLetterReadOnly = [PSCustomObject] @{
#     DriveLetter     = [System.Char] $null
#     Size            = 1GB
#     PartitionNumber = 1
#     Type            = 'Basic'
#     IsReadOnly      = $true
# }

# $script:mockedVolume = [PSCustomObject] @{
#     FileSystemLabel = 'myLabel'
#     FileSystem      = 'NTFS'
#     DriveLetter     = 'G'
# }

# $script:mockedVolumeUnformatted = [PSCustomObject] @{
#     FileSystemLabel = ''
#     FileSystem      = ''
#     DriveLetter     = ''
# }

# $script:mockedVolumeNoDriveLetter = [PSCustomObject] @{
#     FileSystemLabel = 'myLabel'
#     FileSystem      = 'NTFS'
#     DriveLetter     = ''
# }

# $script:mockedVolumeReFS = [PSCustomObject] @{
#     FileSystemLabel = 'myLabel'
#     FileSystem      = 'ReFS'
#     DriveLetter     = 'G'
# }

# $script:mockedVolumeDevDrive = [PSCustomObject] @{
#     FileSystemLabel = 'myLabel'
#     FileSystem      = 'ReFS'
#     DriveLetter     = 'G'
#     UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
# }

# $script:mockedVolumeCreatedAfterNewPartiton = [PSCustomObject] @{
#     FileSystemLabel = ''
#     FileSystem      = ''
#     DriveLetter     = 'T'
#     UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
# }

# $script:mockedVolumeThatExistPriorToConfiguration = [PSCustomObject] @{
#     FileSystemLabel = 'myLabel'
#     FileSystem      = 'NTFS'
#     DriveLetter     = 'T'
#     UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
#     Size            = 50GB
# }

# $script:mockedVolumeThatExistPriorToConfigurationReFS = [PSCustomObject] @{
#     FileSystemLabel = 'myLabel'
#     FileSystem      = 'ReFS'
#     DriveLetter     = 'T'
#     UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
#     Size            = 50GB
# }

# $script:mockedVolumeThatExistPriorToConfigurationNtfs150Gb = [PSCustomObject] @{
#     FileSystemLabel = 'myLabel'
#     FileSystem      = 'NTFS'
#     DriveLetter     = 'T'
#     UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
#     Size            = 150Gb
# }

# $script:mockedVolumeThatExistPriorToConfigurationRefs150Gb = [PSCustomObject] @{
#     FileSystemLabel = 'myLabel'
#     FileSystem      = 'ReFS'
#     DriveLetter     = 'T'
#     UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
#     Size            = 150Gb
# }

# $script:parameterFilter_MockedDisk0Number = {
#     $DiskId -eq $script:mockedDisk0Gpt.Number -and $DiskIdType -eq 'Number'
# }

# $script:userDesiredSize150Gb = 150Gb

# # Alternate value in bytes that can represent a 150 Gb partition in a physical hard disk that has been formatted by Windows.
# $script:partitionFormattedByWindows150Gb = 161060225024

# $script:userDesiredSize50Gb = 50Gb

# $script:userDesiredSize40Gb = 40Gb

# $script:amountOfTimesGetDiskByIdentifierIsCalled = 0

# function Get-PartitionSupportedSizeForDevDriveScenarios
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter()]
#         [System.String]
#         $DriveLetter
#     )

#     switch ($DriveLetter)
#     {
#         'G'
#         {
#             $script:mockedPartitionSupportedSizeForGDriveletter
#         }
#         'H'
#         {
#             $script:mockedPartitionSupportedSizeForHDriveletter
#         }
#         'K'
#         {
#             $script:mockedPartitionSupportedSizeForKDriveletter
#         }
#     }
# }

# <#
#             These functions are required to be able to mock functions where
#             values are passed in via the pipeline.
#         #>
# function Set-Disk
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(ValueFromPipeline)]
#         $InputObject,

#         [Parameter()]
#         [System.Boolean]
#         $IsOffline,

#         [Parameter()]
#         [System.Boolean]
#         $IsReadOnly
#     )
# }

# function Initialize-Disk
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(ValueFromPipeline)]
#         $InputObject,

#         [Parameter()]
#         [System.String]
#         $PartitionStyle
#     )
# }

# function Get-Partition
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(ValueFromPipeline)]
#         $Disk,

#         [Parameter()]
#         [System.String]
#         $DriveLetter,

#         [Parameter()]
#         [System.UInt32]
#         $DiskNumber,

#         [Parameter()]
#         [System.UInt32]
#         $PartitionNumber
#     )
# }

# function New-Partition
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(ValueFromPipeline)]
#         $Disk,

#         [Parameter()]
#         [System.String]
#         $DriveLetter,

#         [Parameter()]
#         [System.Boolean]
#         $UseMaximumSize,

#         [Parameter()]
#         [System.UInt64]
#         $Size
#     )
# }

# function Set-Partition
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(ValueFromPipeline)]
#         $Disk,

#         [Parameter()]
#         [System.String]
#         $DriveLetter,

#         [Parameter()]
#         [System.String]
#         $NewDriveLetter
#     )
# }

# function Get-Volume
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(ValueFromPipeline)]
#         $Partition,

#         [Parameter()]
#         [System.String]
#         $DriveLetter
#     )
# }

# function Set-Volume
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(ValueFromPipeline)]
#         $InputObject,

#         [Parameter()]
#         [System.String]
#         $NewFileSystemLabel
#     )
# }

# function Format-Volume
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(ValueFromPipeline)]
#         $Partition,

#         [Parameter()]
#         [System.String]
#         $DriveLetter,

#         [Parameter()]
#         [System.String]
#         $FileSystem,

#         [Parameter()]
#         [System.Boolean]
#         $Confirm,

#         [Parameter()]
#         [System.String]
#         $NewFileSystemLabel,

#         [Parameter()]
#         [System.UInt32]
#         $AllocationUnitSize,

#         [Parameter()]
#         [Switch]
#         $Force,

#         [Parameter()]
#         [System.Boolean]
#         $DevDrive
#     )
# }

# function Get-PartitionSupportedSize
# {
#     param
#     (
#         [Parameter(ValueFromPipeline = $true)]
#         [System.String]
#         $DriveLetter
#     )
# }

# function Resize-Partition
# {
#     param
#     (
#         [Parameter(ValueFromPipeline = $true)]
#         [System.String]
#         $DriveLetter,

#         [Parameter()]
#         [System.UInt64]
#         $Size
#     )
# }

# function Clear-Disk
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(ValueFromPipeline)]
#         $Disk,

#         [Parameter()]
#         [System.UInt32]
#         $Number,

#         [Parameter()]
#         [System.String]
#         $UniqueID,

#         [Parameter()]
#         [System.String]
#         $FriendlyName,

#         [Parameter()]
#         [System.Boolean]
#         $Confirm,

#         [Parameter()]
#         [Switch]
#         $RemoveData,

#         [Parameter()]
#         [Switch]
#         $RemoveOEM
#     )
# }

# function Get-IsApiSetImplemented
# {
#     [CmdletBinding()]
#     Param
#     (
#         [OutputType([System.Boolean])]
#         [String]
#         $Contract
#     )
# }

# function Get-DeveloperDriveEnablementState
# {
#     [CmdletBinding()]
#     [OutputType([System.Enum])]
#     Param
#             ()
# }

# function Test-DevDriveVolume
# {
#     [CmdletBinding()]
#     param
#     (
#         [string]
#         $VolumeGuidPath
#     )
# }

# function Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(Mandatory = $true)]
#         [System.String]
#         $FSFormat
#     )
# }

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

    #     Context 'When online GPT disk with a partition/volume and wrong Drive Letter assigned using Disk Number' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { $script:mockedDisk0Gpt = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       =  'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = [guid]::NewGuid()
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'GPT'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { #{ $script:mockedPartition = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] 'G'
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { # $script:mockedVolume = [PSCustomObject] @{
    #     FileSystemLabel = 'myLabel'
    #     FileSystem      = 'NTFS'
    #     DriveLetter     = 'G'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName New-Partition `
    #             -ParameterFilter {
    #             $DriveLetter -eq 'H'
    #         } `
    #             -MockWith { # $script:mockedPartitionNoDriveLetter = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] $null
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    #     IsReadOnly      = $false
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Set-Partition `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk
    #         Mock -CommandName New-Partition
    #         Mock -CommandName Format-Volume

    #         It 'Should not throw an exception' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'H' `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
    #         }
    #     }

    #     Context 'When online GPT disk with a partition/volume and no Drive Letter assigned using Disk Number' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { $script:mockedDisk0Gpt = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       =  'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = [guid]::NewGuid()
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'GPT'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { # $script:mockedPartitionNoDriveLetter = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] $null
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    #     IsReadOnly      = $false
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { # $script:mockedVolume = [PSCustomObject] @{
    #     FileSystemLabel = 'myLabel'
    #     FileSystem      = 'NTFS'
    #     DriveLetter     = 'G'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Set-Partition `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk
    #         Mock -CommandName New-Partition
    #         Mock -CommandName Format-Volume

    #         It 'Should not throw an exception' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'H' `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 2
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
    #         }
    #     }

    #     Context 'When online GPT disk with a partition/volume and wrong Volume Label assigned using Disk Number' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { $script:mockedDisk0Gpt = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       =  'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = [guid]::NewGuid()
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'GPT'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { #{ $script:mockedPartition = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] 'G'
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { # $script:mockedVolume = [PSCustomObject] @{
    #     FileSystemLabel = 'myLabel'
    #     FileSystem      = 'NTFS'
    #     DriveLetter     = 'G'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Set-Volume `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk
    #         Mock -CommandName New-Partition
    #         Mock -CommandName Format-Volume
    #         Mock -CommandName Set-Partition

    #         It 'Should not throw an exception' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'G' `
    #                     -FSLabel 'NewLabel' `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
    #         }
    #     }

    #     Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume without assigned drive letter and wrong size' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { $script:mockedDisk0Gpt = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       =  'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = [guid]::NewGuid()
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'GPT'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { # $script:mockedPartitionNoDriveLetter = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] $null
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    #     IsReadOnly      = $false
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName New-Partition `
    #             -ParameterFilter {
    #             $DriveLetter -eq 'G'
    #         } `
    #             -MockWith { # $script:mockedPartitionNoDriveLetter = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] $null
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    #     IsReadOnly      = $false
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { # $script:mockedVolumeUnformatted = [PSCustomObject] @{
    #     FileSystemLabel = ''
    #     FileSystem      = ''
    #     DriveLetter     = ''
    # } } `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk
    #         Mock -CommandName Format-Volume
    #         Mock -CommandName Set-Partition
    #         Mock -CommandName Resize-Partition
    #         Mock -CommandName Get-PartitionSupportedSize
    #         Mock -CommandName Set-Volume

    #         It 'Should not throw an exception' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'G' `
    #                     -Size (1GB + 1024) `
    #                     -AllowDestructive $true `
    #                     -FSLabel 'NewLabel' `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName Set-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Set-Volume -Exactly -Times 0
    #         }
    #     }

    #     Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume but wrong size and remaining size too small' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { $script:mockedDisk0Gpt = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       =  'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = [guid]::NewGuid()
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'GPT'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { #{ $script:mockedPartition = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] 'G'
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-PartitionSupportedSize `
    #             -MockWith {
    #             return @{
    #                 SizeMin = 0
    #                 SizeMax = 1
    #             }
    #         } `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk
    #         Mock -CommandName New-Partition
    #         Mock -CommandName Format-Volume
    #         Mock -CommandName Set-Partition
    #         Mock -CommandName Get-Volume
    #         Mock -CommandName Set-Volume
    #         Mock -CommandName Resize-Partition

    #         $errorRecord = Get-InvalidArgumentRecord `
    #             -Message ($LocalizedData.FreeSpaceViolationError -f `
    #                 $script:mockedPartition.DriveLetter, $script:mockedPartition.Size, (1GB + 1024), 1) `
    #             -ArgumentName 'Size'

    #         It 'Should throw FreeSpaceViolationError' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'G' `
    #                     -Size (1GB + 1024) `
    #                     -AllowDestructive $true `
    #                     -FSLabel 'NewLabel' `
    #                     -Verbose
    #             } | Should -Throw $errorRecord
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 0
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Volume -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-PartitionSupportedSize -Exactly -Times 1
    #             Assert-MockCalled -CommandName Resize-Partition -Exactly -Times 0
    #         }
    #     }

    #     Context 'When AllowDestructive enabled with Size not specified on Online GPT disk with matching partition/volume but wrong size' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { $script:mockedDisk0Gpt = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       =  'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = [guid]::NewGuid()
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'GPT'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { #{ $script:mockedPartition = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] 'G'
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-PartitionSupportedSize `
    #             -MockWith {
    #             return @{
    #                 SizeMin = 0
    #                 SizeMax = 2GB
    #             }
    #         } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Resize-Partition `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { # $script:mockedVolume = [PSCustomObject] @{
    #     FileSystemLabel = 'myLabel'
    #     FileSystem      = 'NTFS'
    #     DriveLetter     = 'G'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Set-Volume `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk
    #         Mock -CommandName New-Partition
    #         Mock -CommandName Set-Partition
    #         Mock -CommandName Format-Volume

    #         It 'Should not throw' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'G' `
    #                     -AllowDestructive $true `
    #                     -FSLabel 'NewLabel' `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-PartitionSupportedSize -Exactly -Times 1
    #             Assert-MockCalled -CommandName Resize-Partition -Exactly -Times 1
    #         }
    #     }

    #     Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume but wrong size and ReFS' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { $script:mockedDisk0Gpt = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       =  'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = [guid]::NewGuid()
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'GPT'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { #{ $script:mockedPartition = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] 'G'
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { $script:mockedVolumeReFS } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Set-Volume `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-PartitionSupportedSize `
    #             -MockWith {
    #             return @{
    #                 SizeMin = 0
    #                 SizeMax = 1
    #             }
    #         } `
    #             -Verifiable


    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk
    #         Mock -CommandName New-Partition
    #         Mock -CommandName Format-Volume
    #         Mock -CommandName Set-Partition
    #         Mock -CommandName Resize-Partition

    #         It 'Should not throw an exception' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'G' `
    #                     -Size (1GB + 1024) `
    #                     -AllowDestructive $true `
    #                     -FSLabel 'NewLabel' `
    #                     -FSFormat 'ReFS' `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-PartitionSupportedSize -Exactly -Times 1
    #             Assert-MockCalled -CommandName Resize-Partition -Exactly -Times 0
    #         }
    #     }

    #     Context 'When AllowDestructive enabled with Online GPT disk with matching partition/volume but wrong format' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { $script:mockedDisk0Gpt = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       =  'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = [guid]::NewGuid()
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'GPT'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { #{ $script:mockedPartition = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] 'G'
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { # $script:mockedVolume = [PSCustomObject] @{
    #     FileSystemLabel = 'myLabel'
    #     FileSystem      = 'NTFS'
    #     DriveLetter     = 'G'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Set-Volume `
    #             -Verifiable

    #         Mock `
    #             -CommandName Format-Volume `
    #             -MockWith { # $script:mockedVolume = [PSCustomObject] @{
    #     FileSystemLabel = 'myLabel'
    #     FileSystem      = 'NTFS'
    #     DriveLetter     = 'G'
    # } } `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk
    #         Mock -CommandName New-Partition
    #         Mock -CommandName Set-Partition

    #         It 'Should not throw an exception' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'G' `
    #                     -Size 1GB `
    #                     -FSFormat 'ReFS' `
    #                     -FSLabel 'NewLabel' `
    #                     -AllowDestructive $true `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
    #         }
    #     }

    #     Context 'When AllowDestructive and ClearDisk enabled with Online GPT disk containing arbitrary partitions' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { $script:mockedDisk0Gpt = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       =  'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = [guid]::NewGuid()
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'GPT'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { #{ $script:mockedPartition = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] 'G'
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { # $script:mockedVolume = [PSCustomObject] @{
    #     FileSystemLabel = 'myLabel'
    #     FileSystem      = 'NTFS'
    #     DriveLetter     = 'G'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Set-Volume `
    #             -Verifiable

    #         Mock `
    #             -CommandName Clear-Disk `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk
    #         Mock -CommandName New-Partition
    #         Mock -CommandName Format-Volume
    #         Mock -CommandName Set-Partition

    #         It 'Should not throw an exception' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'G' `
    #                     -Size 1GB `
    #                     -FSLabel 'NewLabel' `
    #                     -AllowDestructive $true `
    #                     -ClearDisk $true `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 2 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName Clear-Disk -Exactly -Times 1
    #         }
    #     }

    #     Context 'When AllowDestructive and ClearDisk enabled with Online MBR disk containing arbitrary partitions but GPT required' {
    #         <#
    #                     This variable is so that we can change the behavior of the
    #                     Get-DiskByIdentifier mock after the first time it is called
    #                     in the Set-TargetResource function.
    #                 #>
    #         $script:getDiskByIdentifierCalled = $false

    #         $script:parameterFilter_MockedDisk0Number = {
    #             $DiskId -eq $script:mockedDisk0Gpt.Number -and $DiskIdType -eq 'Number'
    #         }

    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter {
    #             $DiskId -eq $script:mockedDisk0Gpt.Number `
    #                 -and $DiskIdType -eq 'Number' `
    #                 -and $script:getDiskByIdentifierCalled -eq $false
    #         } `
    #             -MockWith {
    #             $script:getDiskByIdentifierCalled = $true
    #             return # $script:mockedDisk0Mbr = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       =  'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = ''
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'MBR'
    # }
    #         } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter {
    #             $DiskId -eq $script:mockedDisk0Gpt.Number `
    #                 -and $DiskIdType -eq 'Number' `
    #                 -and $script:getDiskByIdentifierCalled -eq $true
    #         } `
    #             -MockWith {
    #             return # $script:mockedDisk0Raw = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       =  'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = ''
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'RAW'
    # }
    #         } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { #{ $script:mockedPartition = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] 'G'
    #     Size            = 1GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { # $script:mockedVolume = [PSCustomObject] @{
    #     FileSystemLabel = 'myLabel'
    #     FileSystem      = 'NTFS'
    #     DriveLetter     = 'G'
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Set-Volume `
    #             -Verifiable

    #         Mock `
    #             -CommandName Clear-Disk `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk
    #         Mock -CommandName New-Partition
    #         Mock -CommandName Format-Volume
    #         Mock -CommandName Set-Partition

    #         It 'Should not throw an exception' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'G' `
    #                     -Size 1GB `
    #                     -FSLabel 'NewLabel' `
    #                     -AllowDestructive $true `
    #                     -ClearDisk $true `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 3 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Partition -Exactly -Times 0
    #             Assert-MockCalled -CommandName Set-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName Clear-Disk -Exactly -Times 1
    #         }
    #     }

    #     Context 'When the DevDrive flag is true, the AllowDestructive flag is false and there is not enough space on the disk to create the partition' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { $script:mockedDisk0GptForDevDriveResizeNotPossibleScenario } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { $script:mockedPartitionListForResizeNotPossibleScenario } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Assert-DevDriveFeatureAvailable `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-PartitionSupportedSize `
    #             -MockWith { & Get-PartitionSupportedSizeForDevDriveScenarios -DriveLetter $DriveLetter } `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk

    #         $userDesiredSizeInGb = [Math]::Round($script:mockedPartitionSize50Gb / 1GB, 2)

    #         It 'Should throw an exception' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'T' `
    #                     -Size $script:mockedPartitionSize50Gb `
    #                     -FSLabel 'NewLabel' `
    #                     -FSFormat 'ReFS' `
    #                     -DevDrive $true `
    #                     -Verbose
    #             } | Should -Throw -ExpectedMessage ($script:localizedData.FoundNoPartitionsThatCanResizedForDevDrive -f $userDesiredSizeInGb)
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
    #         }
    #     }

    #     Context 'When the DevDrive flag is true, AllowDestructive is false and there is enough space on the disk to create the partition' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { # $script:mockedDisk0GptForDevDriveResizeNotNeededScenario = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       = 'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = [guid]::NewGuid()
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'GPT'
    #     Size           = 100Gb
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { $script:mockedPartitionListForResizeNotNeededScenario } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Assert-DevDriveFeatureAvailable `
    #             -Verifiable

    #         Mock `
    #             -CommandName Test-DevDriveVolume `
    #             -MockWith { $true } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { $script:mockedVolumeCreatedAfterNewPartiton } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-PartitionSupportedSize `
    #             -MockWith { & Get-PartitionSupportedSizeForDevDriveScenarios -DriveLetter $DriveLetter } `
    #             -Verifiable

    #         Mock `
    #             -CommandName New-Partition `
    #             -MockWith { # $script:mockedPartitionWithTDriveLetter = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] 'T'
    #     Size            = 50GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    # }} `
    #             -Verifiable

    #         Mock `
    #             -CommandName Format-Volume `
    #             -MockWith { $script:mockedVolumeCreatedAfterNewPartiton } `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk

    #         It 'Should not throw an exception' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'T' `
    #                     -Size $script:mockedPartitionSize50Gb `
    #                     -FSLabel 'NewLabel' `
    #                     -FSFormat 'ReFS' `
    #                     -DevDrive $true `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1 `
    #                 -ParameterFilter {
    #                 $DevDrive -eq $true
    #             }
    #         }
    #     }

    #     Context 'When the DevDrive flag is true, AllowDestructive flag is false and there is not enough unallocated disk space but a resize of a partition is possible to create new space' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { $script:mockedDisk0GptForDevDriveResizePossibleScenario } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { $script:mockedPartitionListForResizePossibleScenario } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Assert-DevDriveFeatureAvailable `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-PartitionSupportedSize `
    #             -MockWith { & Get-PartitionSupportedSizeForDevDriveScenarios -DriveLetter $DriveLetter } `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk

    #         It 'Should throw an exception stating that AllowDestructive flag needs to be set to resize existing partition for DevDrive' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'T' `
    #                     -Size $script:mockedPartitionSize50Gb `
    #                     -FSLabel 'NewLabel' `
    #                     -FSFormat 'ReFS' `
    #                     -DevDrive $true `
    #                     -Verbose
    #             } | Should -Throw -ExpectedMessage ($script:localizedData.AllowDestructiveNeededForDevDriveOperation -f $script:testDriveLetterK)
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
    #         }
    #     }

    #     Context 'When the DevDrive flag is true, AllowDestructive flag is true and there is not enough unallocated disk space but a resize of a partition is possible to create new space' {
    #         # verifiable (should be called) mocks

    #         $script:amountOfTimesGetDiskByIdentifierIsCalled = 0

    #         # For resize scenario we need to call Get-DiskByIdentifier twice. After the resize a disk.FreeLargestExtent is updated.
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith {
    #             $script:amountOfTimesGetDiskByIdentifierIsCalled++

    #             if ($script:amountOfTimesGetDiskByIdentifierIsCalled -eq 1)
    #             {

    #                 $script:mockedDisk0GptForDevDriveResizePossibleScenario
    #             }
    #             elseif ($script:amountOfTimesGetDiskByIdentifierIsCalled -eq 2)
    #             {

    #                 $script:mockedDisk0GptForDevDriveAfterResize
    #             }
    #             else
    #             {
    #                 $script:mockedDisk0GptForDevDriveResizePossibleScenario
    #             }
    #         } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { $script:mockedPartitionListForResizePossibleScenario } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Assert-DevDriveFeatureAvailable `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-PartitionSupportedSize `
    #             -MockWith { & Get-PartitionSupportedSizeForDevDriveScenarios -DriveLetter $DriveLetter } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Test-DevDriveVolume `
    #             -MockWith { $true } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { $script:mockedVolumeCreatedAfterNewPartiton } `
    #             -Verifiable

    #         Mock `
    #             -CommandName New-Partition `
    #             -MockWith { # $script:mockedPartitionWithTDriveLetter = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] 'T'
    #     Size            = 50GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    # }} `
    #             -Verifiable

    #         Mock `
    #             -CommandName Resize-Partition `
    #             -Verifiable

    #         Mock `
    #             -CommandName Format-Volume `
    #             -MockWith { $script:mockedVolumeCreatedAfterNewPartiton } `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk

    #         It 'Should not throw an exception' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'T' `
    #                     -Size $script:mockedPartitionSize50Gb `
    #                     -FSLabel 'NewLabel' `
    #                     -FSFormat 'ReFS' `
    #                     -DevDrive $true `
    #                     -AllowDestructive $true `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 2 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 4
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName Resize-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1 `
    #                 -ParameterFilter {
    #                 $DevDrive -eq $true
    #             }
    #             Assert-MockCalled -CommandName New-Partition -Exactly -Times 1
    #         }
    #     }

    #     Context 'When the DevDrive flag is true, AllowDestructive is true, and a Partition that matches the users drive letter exists' {
    #         # verifiable (should be called) mocks
    #         Mock `
    #             -CommandName Get-DiskByIdentifier `
    #             -ParameterFilter $script:parameterFilter_MockedDisk0Number `
    #             -MockWith { # $script:mockedDisk0GptForDevDriveResizeNotNeededScenario = [PSCustomObject] @{
    #     Number         = 1
    #     UniqueId       = 'TESTDISKUNIQUEID'
    #     FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #     SerialNumber   = 'TESTDISKSERIALNUMBER'
    #     Guid           = [guid]::NewGuid()
    #     IsOffline      = $false
    #     IsReadOnly     = $false
    #     PartitionStyle = 'GPT'
    #     Size           = 100Gb
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Test-DevDriveVolume `
    #             -MockWith { $true } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-PartitionSupportedSize `
    #             -MockWith { # $script:mockedPartitionSupportedSizeForTDriveletter = [PSCustomObject] @{
    #     DriveLetter = [System.Char] 'T'
    #     SizeMax      = 100GB
    #     SizeMin     = 10GB
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Partition `
    #             -MockWith { # $script:mockedPartitionWithTDriveLetter = [PSCustomObject] @{
    #     DriveLetter     = [System.Char] 'T'
    #     Size            = 50GB
    #     PartitionNumber = 1
    #     Type            = 'Basic'
    # }} `
    #             -Verifiable

    #         Mock `
    #             -CommandName Get-Volume `
    #             -MockWith { # $script:mockedVolumeThatExistPriorToConfiguration = [PSCustomObject] @{
    #     FileSystemLabel = 'myLabel'
    #     FileSystem      = 'NTFS'
    #     DriveLetter     = 'T'
    #     UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
    #     Size            = 50GB
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Format-Volume `
    #             -MockWith { # $script:mockedVolumeThatExistPriorToConfiguration = [PSCustomObject] @{
    #     FileSystemLabel = 'myLabel'
    #     FileSystem      = 'NTFS'
    #     DriveLetter     = 'T'
    #     UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
    #     Size            = 50GB
    # } } `
    #             -Verifiable

    #         Mock `
    #             -CommandName Assert-DevDriveFeatureAvailable `
    #             -Verifiable

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk

    #         It 'Should not throw an exception and overwrite the existing partition' {
    #             {
    #                 Set-TargetResource `
    #                     -DiskId $script:mockedDisk0Gpt.Number `
    #                     -Driveletter 'T' `
    #                     -FSLabel 'NewLabel' `
    #                     -FSFormat 'ReFS' `
    #                     -DevDrive $true `
    #                     -AllowDestructive $true `
    #                     -Verbose
    #             } | Should -Not -Throw
    #         }

    #         It 'Should call the correct mocks' {
    #             Assert-VerifiableMock
    #             Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
    #                 -ParameterFilter $script:parameterFilter_MockedDisk0Number
    #             Assert-MockCalled -CommandName Set-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Initialize-Disk -Exactly -Times 0
    #             Assert-MockCalled -CommandName Get-Partition -Exactly -Times 1
    #             Assert-MockCalled -CommandName Get-Volume -Exactly -Times 1
    #             Assert-MockCalled -CommandName Assert-DevDriveFeatureAvailable -Exactly -Times 1
    #             Assert-MockCalled -CommandName Format-Volume -Exactly -Times 1 `
    #                 -ParameterFilter {
    #                 $DevDrive -eq $true
    #             }
    #         }
    #     }

    # Context 'When the DevDrive flag is true, AllowDestructive is false, and a Partition that matches the users drive letter exists' {
    #     BeforeAll {
    #         Mock -CommandName Assert-DriveLetterValid -MockWith {
    #             'G'
    #         }

    #         Mock -CommandName Get-DiskByIdentifier -MockWith {
    #             [PSCustomObject] @{
    #                 Number         = 1
    #                 UniqueId       = 'TESTDISKUNIQUEID'
    #                 FriendlyName   = 'TESTDISKFRIENDLYNAME'
    #                 SerialNumber   = 'TESTDISKSERIALNUMBER'
    #                 Guid           = [guid]::NewGuid()
    #                 IsOffline      = $false
    #                 IsReadOnly     = $false
    #                 PartitionStyle = 'GPT'
    #                 Size           = 100Gb
    #             }
    #         }

    #         Mock -CommandName Test-DevDriveVolume -MockWith { $false }
    #         Mock -CommandName Get-PartitionSupportedSize -MockWith {
    #             [PSCustomObject] @{
    #                 DriveLetter = [System.Char] 'T'
    #                 SizeMax     = 100GB
    #                 SizeMin     = 10GB
    #             }
    #         }

    #         Mock -CommandName Get-Partition -MockWith {
    #             [PSCustomObject] @{
    #                 DriveLetter     = [System.Char] 'T'
    #                 Size            = 50GB
    #                 PartitionNumber = 1
    #                 Type            = 'Basic'
    #             }
    #         }

    #         Mock -CommandName Get-Volume -MockWith {
    #             [PSCustomObject] @{
    #                 FileSystemLabel = 'myLabel'
    #                 FileSystem      = 'NTFS'
    #                 DriveLetter     = 'T'
    #                 UniqueId        = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
    #                 Size            = 50GB
    #             }
    #         }

    #         Mock -CommandName Assert-DevDriveFeatureAvailable
    #         Mock -CommandName Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue
    #         Mock -CommandName Assert-SizeMeetsMinimumDevDriveRequirement
    #         Mock -CommandName Test-DevDriveVolume -MockWith { $false }

    #         # mocks that should not be called
    #         Mock -CommandName Set-Disk
    #         Mock -CommandName Initialize-Disk
    #         Mock -CommandName Format-Volume
    #     }

    #     It 'Should throw an exception advising that the volume was not formatted as a Dev Drive volume' {
    #         InModuleScope -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $testParams = @{
    #                 DiskId      = 1
    #                 Driveletter = 'T'
    #                 FSLabel     = 'NewLabel'
    #                 FSFormat    = 'ReFS'
    #                 DevDrive    = $true
    #             }

    #             $errorRecord = (
    #                 $script:localizedData.FailedToConfigureDevDriveVolume -f 'TESTDISKUNIQUEID', $testParams.Driveletter
    #             )

    #             $result = Set-TargetResource @testParams

    #             { $result } | Should -Throw -ExpectedMessage $errorRecord
    #         }

    #         Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
    #         Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
    #         Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
    #         Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
    #         Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
    #         Should -Invoke -CommandName Assert-DevDriveFeatureAvailable -Exactly -Times 1 -Scope It
    #         Should -Invoke -CommandName Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue -Exactly -Times 1 -Scope It
    #         Should -Invoke -CommandName Assert-SizeMeetsMinimumDevDriveRequirement -Exactly -Times 1 -Scope It
    #         Should -Invoke -CommandName Test-DevDriveVolume -Exactly -Times 1 -Scope It
    #         Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
    #             -ParameterFilter {
    #             $DevDrive -eq $true
    #         }
    #     }
    # }
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
                $result | Should -Be $false
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
