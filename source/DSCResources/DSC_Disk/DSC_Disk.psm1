$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Storage Common Module.
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'StorageDsc.Common' `
            -ChildPath 'StorageDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings.
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the Disk and Partition.

    .PARAMETER DriveLetter
        Specifies the preferred letter to assign to the disk volume.

    .PARAMETER DiskId
        Specifies the disk identifier for the disk to modify.

    .PARAMETER DiskIdType
        Specifies the identifier type the DiskId contains. Defaults to Number.

    .PARAMETER PartitionStyle
        Specifies the partition style of the disk. Defaults to GPT.
        This parameter is not used in Get-TargetResource.

    .PARAMETER Size
        Specifies the size of new volume (use all available space on disk if not provided).
        This parameter is not used in Get-TargetResource.

    .PARAMETER FSLabel
        Specifies the volume label to assign to the volume.
        This parameter is not used in Get-TargetResource.

    .PARAMETER AllocationUnitSize
        Specifies the allocation unit size to use when formatting the volume.
        This parameter is not used in Get-TargetResource.

    .PARAMETER FSFormat
        Specifies the file system format of the new volume.
        This parameter is not used in Get-TargetResource.

    .PARAMETER AllowDestructive
        Specifies if potentially destructive operations may occur.
        This parameter is not used in Get-TargetResource.

    .PARAMETER ClearDisk
        Specifies if the disks partition schema should be removed entirely, even if data and OEM
        partitions are present. Only possible with AllowDestructive enabled.
        This parameter is not used in Get-TargetResource.

    .PARAMETER DevDrive
        Specifies if the volume is formatted as a Dev Drive.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter()]
        [ValidateSet('Number', 'UniqueId', 'Guid', 'Location', 'FriendlyName', 'SerialNumber')]
        [System.String]
        $DiskIdType = 'Number',

        [Parameter()]
        [ValidateSet('GPT', 'MBR')]
        [System.String]
        $PartitionStyle = 'GPT',

        [Parameter()]
        [System.UInt64]
        $Size,

        [Parameter()]
        [System.String]
        $FSLabel,

        [Parameter()]
        [System.UInt32]
        $AllocationUnitSize,

        [Parameter()]
        [ValidateSet('NTFS', 'ReFS')]
        [System.String]
        $FSFormat = 'NTFS',

        [Parameter()]
        [System.Boolean]
        $AllowDestructive,

        [Parameter()]
        [System.Boolean]
        $ClearDisk,

        [Parameter()]
        [System.Boolean]
        $DevDrive
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingDiskMessage -f $DiskIdType, $DiskId, $DriveLetter)
        ) -join '' )

    # Validate the DriveLetter parameter
    $DriveLetter = Assert-DriveLetterValid -DriveLetter $DriveLetter

    # Get the Disk using the identifiers supplied
    $disk = Get-DiskByIdentifier `
        -DiskId $DiskId `
        -DiskIdType $DiskIdType

    $partition = Get-Partition `
        -DriveLetter $DriveLetter `
        -ErrorAction SilentlyContinue | Select-Object -First 1

    $volume = Get-Volume `
        -DriveLetter $DriveLetter `
        -ErrorAction SilentlyContinue

    $blockSize = (Get-CimInstance `
            -Query "SELECT BlockSize from Win32_Volume WHERE DriveLetter = '$($DriveLetter):'" `
            -ErrorAction SilentlyContinue).BlockSize

    $DevDrive = $false
    if ($volume.UniqueId)
    {
        $DevDrive = Test-DevDriveVolume `
            -VolumeGuidPath $volume.UniqueId `
            -ErrorAction SilentlyContinue
    }

    return @{
        DiskId             = $DiskId
        DiskIdType         = $DiskIdType
        DriveLetter        = $partition.DriveLetter
        PartitionStyle     = $disk.PartitionStyle
        Size               = $partition.Size
        FSLabel            = $volume.FileSystemLabel
        AllocationUnitSize = $blockSize
        FSFormat           = $volume.FileSystem
        DevDrive           = $DevDrive
    }
} # Get-TargetResource

<#
    .SYNOPSIS
        Initializes the Disk and Partition and assigns the drive letter.

    .PARAMETER DriveLetter
        Specifies the preferred letter to assign to the disk volume.

    .PARAMETER DiskId
        Specifies the disk identifier for the disk to modify.

    .PARAMETER DiskIdType
        Specifies the identifier type the DiskId contains. Defaults to Number.

    .PARAMETER PartitionStyle
        Specifies the partition style of the disk. Defaults to GPT.

    .PARAMETER Size
        Specifies the size of new volume. Leave empty to use the remaining free space.

    .PARAMETER FSLabel
        Specifies the volume label to assign to the volume.

    .PARAMETER AllocationUnitSize
        Specifies the allocation unit size to use when formatting the volume.

    .PARAMETER FSFormat
        Specifies the file system format of the new volume.

    .PARAMETER AllowDestructive
        Specifies if potentially destructive operations may occur.

    .PARAMETER ClearDisk
        Specifies if the disks partition schema should be removed entirely, even if data and OEM
        partitions are present. Only possible with AllowDestructive enabled.

    .PARAMETER DevDrive
        Specifies if the volume should be formatted as a Dev Drive.
#>
function Set-TargetResource
{
    # Should process is called in a helper functions but not directly in Set-TargetResource
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter()]
        [ValidateSet('Number', 'UniqueId', 'Guid', 'Location', 'FriendlyName', 'SerialNumber')]
        [System.String]
        $DiskIdType = 'Number',

        [Parameter()]
        [ValidateSet('GPT', 'MBR')]
        [System.String]
        $PartitionStyle = 'GPT',

        [Parameter()]
        [System.UInt64]
        $Size,

        [Parameter()]
        [System.String]
        $FSLabel,

        [Parameter()]
        [System.UInt32]
        $AllocationUnitSize,

        [Parameter()]
        [ValidateSet('NTFS', 'ReFS')]
        [System.String]
        $FSFormat = 'NTFS',

        [Parameter()]
        [System.Boolean]
        $AllowDestructive,

        [Parameter()]
        [System.Boolean]
        $ClearDisk,

        [Parameter()]
        [System.Boolean]
        $DevDrive
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.SettingDiskMessage -f $DiskIdType, $DiskId, $DriveLetter)
        ) -join '' )

    # Validate the DriveLetter parameter
    $DriveLetter = Assert-DriveLetterValid -DriveLetter $DriveLetter

    # Get the Disk using the identifiers supplied
    $disk = Get-DiskByIdentifier `
        -DiskId $DiskId `
        -DiskIdType $DiskIdType

    if ($disk.IsOffline)
    {
        # Disk is offline, so bring it online
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.SetDiskOnlineMessage -f $DiskIdType, $DiskId)
            ) -join '' )

        $disk | Set-Disk -IsOffline $false
    } # if

    if ($disk.IsReadOnly)
    {
        # Disk is read-only, so make it read/write
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.SetDiskReadWriteMessage -f $DiskIdType, $DiskId)
            ) -join '' )

        $disk | Set-Disk -IsReadOnly $false
    } # if

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.CheckingDiskPartitionStyleMessage -f $DiskIdType, $DiskId)
        ) -join '' )

    if ($AllowDestructive -and $ClearDisk -and $disk.PartitionStyle -ne 'RAW')
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.ClearingDiskMessage -f $DiskIdType, $DiskId)
            ) -join '' )

        $disk | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false

        # Requery the disk
        $disk = Get-DiskByIdentifier `
            -DiskId $DiskId `
            -DiskIdType $DiskIdType
    }

    if ($disk.PartitionStyle -eq 'RAW')
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.InitializingDiskMessage -f $DiskIdType, $DiskId, $PartitionStyle)
            ) -join '' )

        $disk | Initialize-Disk -PartitionStyle $PartitionStyle

        # Requery the disk
        $disk = Get-DiskByIdentifier `
            -DiskId $DiskId `
            -DiskIdType $DiskIdType
    }
    else
    {
        if ($disk.PartitionStyle -eq $PartitionStyle)
        {
            # The disk partition is already initialized with the correct partition style
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.DiskAlreadyInitializedMessage `
                            -f $DiskIdType, $DiskId, $disk.PartitionStyle)
                ) -join '' )

        }
        else
        {
            # This disk is initialized but with the incorrect partition style
            New-InvalidOperationException `
                -Message ($script:localizedData.DiskInitializedWithWrongPartitionStyleError `
                    -f $DiskIdType, $DiskId, $disk.PartitionStyle, $PartitionStyle)
        }
    }

    <#
        Check Dev Drive assertions.
    #>
    if ($DevDrive)
    {
        Assert-DevDriveFeatureAvailable
        Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue -FSFormat $FSFormat

        <#
            We validate the case where the user does not specify a size later on, should we need to create a new
            partition.
        #>
        if ($Size)
        {
            Assert-SizeMeetsMinimumDevDriveRequirement -UserDesiredSize $Size
        }
    }

    # Get the partitions on the disk
    $partition = $disk | Get-Partition -ErrorAction SilentlyContinue

    # Check if the disk has an existing partition assigned to the drive letter
    $assignedPartition = $partition |
        Where-Object -Property DriveLetter -eq $DriveLetter

    <#
        Get the current max unallocated space in bytes. Round up to nearest Gb so we can do better comparisons
        with the Size parameter.
    #>
    $currentMaxUnallocatedSpaceInBytes = [Math]::Round($disk.LargestFreeExtent / 1GB, 2) * 1GB

    # Check if existing partition already has file system on it
    if ($null -eq $assignedPartition)
    {
        # There is no partiton with this drive letter
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.DriveNotFoundOnPartitionMessage `
                        -f $DiskIdType, $DiskId, $DriveLetter)
            ) -join '' )

        # Are there any partitions defined on this disk?
        if ($partition)
        {
            # There are partitions defined - identify if one matches the size required
            if ($Size)
            {
                if ($DevDrive)
                {
                    Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.AttemptingToFindAPartitionToResizeForDevDrive)
                    ) -join '' )

                    <#
                        Find the first partition whose max - min supported partition size is greater than or equal
                        to the size the user wants so we can resize it later. The max size also includes any
                        unallocated space next to the partition.
                    #>
                    $partitionToResizeForDevDriveScenario = $null
                    $amountToDecreasePartitionBy = 0
                    $isResizeNeeded = $true
                    foreach ($tempPartition in $partition)
                    {
                        $shouldNotBeResized = ($tempPartition.Type -in 'System','Reserved','Recovery')

                        $doesNotHaveDriveLetter = (-not $tempPartition.DriveLetter -or `
                            $tempPartition.DriveLetter -eq '')

                        if ($shouldNotBeResized -or $doesNotHaveDriveLetter)
                        {
                            continue
                        }

                        $supportedSize = Get-PartitionSupportedSize -DriveLetter $tempPartition.DriveLetter

                        Write-Verbose -Message ( @(
                            "$($MyInvocation.MyCommand): "
                            $($script:localizedData.CheckingIfPartitionCanBeResizedForDevDrive -f $tempPartition.DriveLetter)
                            ) -join '' )

                        if (($supportedSize.SizeMax - $supportedSize.SizeMin) -ge $Size)
                        {
                            $unallocatedSpaceNextToPartition = $supportedSize.SizeMax - $tempPartition.Size

                            if ($unallocatedSpaceNextToPartition -ge $Size)
                            {
                                <#
                                    The size of the unallocated space next to the partition is already big enough
                                    to create a Dev Drive volume on, so we don't need to resize any partitions.
                                #>
                                Write-Verbose -Message ( @(
                                    "$($MyInvocation.MyCommand): "
                                    $($script:localizedData.NoPartitionResizeNeededForDevDrive)
                                    ) -join '' )

                                $isResizeNeeded = $false
                                break
                            }

                            Write-Verbose -Message ( @(
                                "$($MyInvocation.MyCommand): "
                                $($script:localizedData.PartitionFoundThatCanBeResizedForDevDrive -f $tempPartition.DriveLetter)
                                ) -join '' )


                            $partitionToResizeForDevDriveScenario = $tempPartition
                            $amountToDecreasePartitionBy = $Size - $unallocatedSpaceNextToPartition
                            break
                        }

                        Write-Verbose -Message ( @(
                            "$($MyInvocation.MyCommand): "
                            $($script:localizedData.PartitionCantBeResizedForDevDrive -f $tempPartition.DriveLetter)
                            ) -join '' )
                    }

                    $partition = $partitionToResizeForDevDriveScenario

                    if ($isResizeNeeded -and (-not $partition) -and $currentMaxUnallocatedSpaceInBytes -lt $Size)
                    {
                        $SizeInGb = [Math]::Round($Size / 1GB, 2)
                        throw ($script:localizedData.FoundNoPartitionsThatCanResizedForDevDrive -f $SizeInGb)
                    }
                }
                else
                {
                    <#
                        When not in the Dev Drive scenario we attempt to find the first basic partition matching
                        the size and use that as the partition.
                    #>
                    $partition = $partition |
                        Where-Object -FilterScript { $_.Type -eq 'Basic' -and $_.Size -eq $Size } |
                        Select-Object -First 1
                }

                if ($partition)
                {
                    # A partition matching the required size was found
                    Write-Verbose -Message ($script:localizedData.MatchingPartitionFoundMessage `
                            -f $DiskIdType, $DiskId, $partition.PartitionNumber)
                }
                else
                {
                    # A partition matching the required size was not found
                    Write-Verbose -Message ($script:localizedData.MatchingPartitionNotFoundMessage `
                            -f $DiskIdType, $DiskId)
                } # if
            }
            else
            {
                <#
                    No size specified, so see if there is a partition that has a volume
                    matching the file system type that is not assigned to a drive letter.
                #>
                Write-Verbose -Message ($script:localizedData.MatchingPartitionNoSizeMessage `
                        -f $DiskIdType, $DiskId)

                $searchPartitions = $partition | Where-Object -FilterScript {
                    $_.Type -eq 'Basic' -and -not [System.Char]::IsLetter($_.DriveLetter)
                }

                $partition = $null

                foreach ($searchPartition in $searchPartitions)
                {
                    # Look for the volume in the partition.
                    Write-Verbose -Message ($script:localizedData.SearchForVolumeMessage `
                            -f $DiskIdType, $DiskId, $searchPartition.PartitionNumber, $FSFormat)

                    $searchVolumes = $searchPartition | Get-Volume

                    $volumeMatch = $searchVolumes | Where-Object -FilterScript {
                        $_.FileSystem -eq $FSFormat
                    }

                    if ($volumeMatch)
                    {
                        <#
                            Found a partition with a volume that matches file system
                            type and not assigned a drive letter.
                        #>
                        $partition = $searchPartition

                        Write-Verbose -Message ($script:localizedData.VolumeFoundMessage `
                                -f $DiskIdType, $DiskId, $searchPartition.PartitionNumber, $FSFormat)

                        break
                    } # if
                } # foreach
            } # if
        } # if

        <#
            We can't find a partition with the required drive letter, so we may need to make a new one.
            First we need to check if there is already enough unallocated space on the disk.
        #>
        $enoughUnallocatedSpace = ($currentMaxUnallocatedSpaceInBytes -ge $Size)

        if ($DevDrive -and $Size -and $partition -and (-not $enoughUnallocatedSpace))
        {
            <#
                Resize the partition that has the largest max - min supported size. This will create
                enough new unallocated space for the  Dev Drive volume to be created on.
            #>
            if ($AllowDestructive)
            {
                $newPartitionSize = ($partition.Size - $amountToDecreasePartitionBy)
                $newPartitionSizeInGb = [Math]::Round($newPartitionSize / 1GB, 2)
                $SizeInGb = [Math]::Round($Size / 1GB, 2)

                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                        $($script:localizedData.ResizingPartitionToMakeSpaceForDevDriveVolume `
                        -f $partition.DriveLetter, $newPartitionSizeInGb, $SizeInGb)
                    ) -join '' )

                $partition | Resize-Partition -Size $newPartitionSize

                # Requery the disk since we resized a partition
                $disk = Get-DiskByIdentifier `
                    -DiskId $DiskId `
                    -DiskIdType $DiskIdType
            }
            else
            {
                # Allow Destructive is not set to true, so throw an exception.
                throw  ($script:localizedData.AllowDestructiveNeededForDevDriveOperation -f $partition.DriveLetter)
            }

            # We no longer need to use the resized partition as we now have enough unallocated space.
            $partition = $null
        }

        <#
            We enter here if there are no partitions on the disk or when we need to create a new partition
            using unallocated space.
        #>
        if (-not $partition)
        {
            # Attempt to create a new partition
            $partitionParams = @{
                DriveLetter = $DriveLetter
            }

            if ($Size)
            {
                # Use only a specific size
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.CreatingPartitionMessage `
                                -f $DiskIdType, $DiskId, $DriveLetter, "$($Size/1KB) KB")
                    ) -join '' )

                if ($DevDrive)
                {
                    <#
                        If size is slightly larger in bytes due to low level rounding differences than the max
                        free extent there won't be any capacity to create the new partition. So if the values
                        are the same in GB after rounding, we'll update size to be the max free extent
                    #>
                    if (Compare-SizeUsingGB -SizeAInBytes $Size -SizeBInBytes $disk.LargestFreeExtent)
                    {
                        $Size = $disk.LargestFreeExtent
                    }

                    Assert-SizeMeetsMinimumDevDriveRequirement -UserDesiredSize $Size
                }

                $partitionParams['Size'] = $Size
            }
            else
            {
                # Use the entire disk
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.CreatingPartitionMessage `
                                -f $DiskIdType, $DiskId, $DriveLetter, 'all free space')
                    ) -join '' )

                if ($DevDrive)
                {
                    Assert-SizeMeetsMinimumDevDriveRequirement -UserDesiredSize $currentMaxUnallocatedSpaceInBytes
                }

                $partitionParams['UseMaximumSize'] = $true
            } # if

            # Create the partition.
            $partition = $disk | New-Partition @partitionParams

            <#
                After creating the partition it can take a few seconds for it to become writeable
                Wait for up to 30 seconds for the parition to become writeable
            #>
            $timeAtStart = Get-Date
            $minimumTimeToWait = $timeAtStart + (New-Timespan -Second 3)
            $maximumTimeToWait = $timeAtStart + (New-Timespan -Second 30)

            while (($partitionstate.IsReadOnly -and (Get-Date) -lt $maximumTimeToWait) `
                -or ((Get-Date) -lt $minimumTimeToWait))
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        ($script:localizedData.NewPartitionIsReadOnlyMessage `
                                -f $DiskIdType, $DiskId, $partition.PartitionNumber)
                    ) -join '' )

                Start-Sleep -Seconds 1

                # Pull the partition details again to check if it is readonly
                $partitionstate = $partition | Get-Partition
            } # while
        } # if

        if ($partition.IsReadOnly)
        {
            # The partition is still readonly - throw an exception
            New-InvalidOperationException `
                -Message ($script:localizedData.NewParitionIsReadOnlyError `
                    -f $DiskIdType, $DiskId, $partition.PartitionNumber)
        } # if

        $assignDriveLetter = $true
    }
    else
    {
        # The disk already has a partition on it that is assigned to the Drive Letter
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.PartitionAlreadyAssignedMessage `
                        -f $DriveLetter, $assignedPartition.PartitionNumber)
            ) -join '' )

        $assignDriveLetter = $false

        $supportedSize = $assignedPartition | Get-PartitionSupportedSize

        <#
            If the partition size was not specified then try and make the partition
            use all possible space on the disk.
        #>
        if (-not ($PSBoundParameters.ContainsKey('Size')))
        {
            $Size = $supportedSize.SizeMax
        }

        if ($assignedPartition.Size -ne $Size)
        {
            # A partition resize is required
            if ($AllowDestructive)
            {
                if ($FSFormat -eq 'ReFS')
                {
                    Write-Warning -Message ( @(
                            "$($MyInvocation.MyCommand): "
                            $($script:localizedData.ResizeRefsNotPossibleMessage `
                                    -f $DriveLetter, $assignedPartition.Size, $Size)
                        ) -join '' )

                }
                else
                {
                    Write-Verbose -Message ( @(
                            "$($MyInvocation.MyCommand): "
                            $($script:localizedData.SizeMismatchCorrectionMessage `
                                    -f $DriveLetter, $assignedPartition.Size, $Size)
                        ) -join '' )

                    if ($Size -gt $supportedSize.SizeMax)
                    {
                        New-InvalidArgumentException -Message ( @(
                                "$($MyInvocation.MyCommand): "
                                $($script:localizedData.FreeSpaceViolationError `
                                        -f $DriveLetter, $assignedPartition.Size, $Size, $supportedSize.SizeMax)
                            ) -join '' ) -ArgumentName 'Size' -ErrorAction Stop
                    }

                    $assignedPartition | Resize-Partition -Size $Size
                }
            }
            else
            {
                # A partition resize was required but is not allowed
                Write-Warning -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.ResizeNotAllowedMessage `
                                -f $DriveLetter, $assignedPartition.Size, $Size)
                    ) -join '' )
            }
        }
    }

    <#
        If the Set-TargetResource function is run as a standalone function, and $assignedPartition is not null
        and there are multiple partitions in $partition, then '$partition | Get-Volume', will give $volume back
        the first volume on the first partition. If $assignedPartition is after that one, then we could
        potentially format a different volume. So we need to make sure that $partition is equal to
        $assignedPartition before we call Get-Volume.
    #>
    if ($assignedPartition)
    {
        $partition = $assignedPartition
    }

    # Get the Volume on the partition
    $volume = $partition | Get-Volume

    # Is the volume already formatted?
    if ($volume.FileSystem -eq '')
    {
        # The volume is not formatted
        $formatVolumeParameters = @{
            FileSystem = $FSFormat
            Confirm    = $false
        }

        if ($FSLabel)
        {
            # Set the File System label on the new volume
            $formatVolumeParameters['NewFileSystemLabel'] = $FSLabel
        } # if

        if ($AllocationUnitSize)
        {
            # Set the Allocation Unit Size on the new volume
            $formatVolumeParameters['AllocationUnitSize'] = $AllocationUnitSize
        } # if

        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.FormattingVolumeMessage -f $formatVolumeParameters.FileSystem)
            ) -join '' )

        if ($DevDrive)
        {
            # Confirm that the partition size meets the minimum requirements for a Dev Drive volume.
            Assert-SizeMeetsMinimumDevDriveRequirement -UserDesiredSize $partition.Size

            $formatVolumeParameters['DevDrive'] = $DevDrive
        }

        # Format the volume
        $volume = $partition | Format-Volume @formatVolumeParameters
    }
    else
    {
        # The volume is already formatted
        if ($PSBoundParameters.ContainsKey('FSFormat'))
        {
            # Check the filesystem format
            $fileSystem = $volume.FileSystem
            if ($fileSystem -ne $FSFormat)
            {
                # The file system format does not match
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.FileSystemFormatMismatch `
                                -f $DriveLetter, $fileSystem, $FSFormat)
                    ) -join '' )

                if ($AllowDestructive)
                {
                    Write-Verbose -Message ( @(
                            "$($MyInvocation.MyCommand): "
                            $($script:localizedData.VolumeFormatInProgressMessage `
                                    -f $DriveLetter, $fileSystem, $FSFormat)
                        ) -join '' )

                    $formatParam = @{
                        FileSystem = $FSFormat
                        Force      = $true
                    }

                    if ($PSBoundParameters.ContainsKey('AllocationUnitSize'))
                    {
                        $formatParam.Add('AllocationUnitSize', $AllocationUnitSize)
                    }

                    if ($DevDrive)
                    {
                        # Confirm that the volume size meets the minimum requirements for a Dev Drive volume.
                        Assert-SizeMeetsMinimumDevDriveRequirement -UserDesiredSize $volume.Size

                        $formatParam.Add('DevDrive', $DevDrive)
                    }

                    # Update the volume with the new format information.
                    $volume = $volume | Format-Volume @formatParam
                }
            } # if
        } # if

        # Check the volume label
        if ($PSBoundParameters.ContainsKey('FSLabel'))
        {
            # The volume should have a label assigned
            if ($volume.FileSystemLabel -ne $FSLabel)
            {
                # The volume lable needs to be changed because it is different.
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.ChangingVolumeLabelMessage `
                                -f $DriveLetter, $FSLabel)
                    ) -join '' )

                $volume | Set-Volume -NewFileSystemLabel $FSLabel
            } # if
        } # if
    } # if

    # Assign the Drive Letter if it isn't assigned
    if ($assignDriveLetter -and ($partition.DriveLetter -ne $DriveLetter))
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.AssigningDriveLetterMessage -f $DriveLetter)
            ) -join '' )

        $null = $partition | Set-Partition -NewDriveLetter $DriveLetter

        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.SuccessfullyInitializedMessage -f $DriveLetter)
            ) -join '' )
    } # if

    # Confirm that the volume is now actually formatted as a Dev Drive volume.
    if ($DevDrive)
    {
        $isDevDriveVolume = Test-DevDriveVolume -VolumeGuidPath $volume.UniqueId -ErrorAction SilentlyContinue

        if ($isDevDriveVolume)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.SuccessfullyConfiguredDevDriveVolume `
                        -f $volume.UniqueId, $volume.DriveLetter)
                ) -join '' )
        }
        else
        {
            throw ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.FailedToConfigureDevDriveVolume `
                        -f $volume.UniqueId, $volume.DriveLetter)
                ) -join '' )
        }
    }
} # Set-TargetResource

<#
    .SYNOPSIS
        Tests if the disk is initialized, the partion exists and the drive letter is assigned.

    .PARAMETER DriveLetter
        Specifies the preferred letter to assign to the disk volume.

    .PARAMETER DiskId
        Specifies the disk identifier for the disk to modify.

    .PARAMETER DiskIdType
        Specifies the identifier type the DiskId contains. Defaults to Number.

    .PARAMETER PartitionStyle
        Specifies the partition style of the disk. Defaults to GPT.

    .PARAMETER Size
        Specifies the size of new volume. Leave empty to use the remaining free space.

    .PARAMETER FSLabel
        Specifies the volume label to assign to the volume.

    .PARAMETER AllocationUnitSize
        Specifies the allocation unit size to use when formatting the volume.

    .PARAMETER FSFormat
        Specifies the file system format of the new volume.

    .PARAMETER AllowDestructive
        Specifies if potentially destructive operations may occur.

    .PARAMETER ClearDisk
        Specifies if the disks partition schema should be removed entirely, even if data and OEM
        partitions are present. Only possible with AllowDestructive enabled.

    .PARAMETER DevDrive
        Specifies if the volume should be formatted as a Dev Drive.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter()]
        [ValidateSet('Number', 'UniqueId', 'Guid', 'Location', 'FriendlyName', 'SerialNumber')]
        [System.String]
        $DiskIdType = 'Number',

        [Parameter()]
        [ValidateSet('GPT', 'MBR')]
        [System.String]
        $PartitionStyle = 'GPT',

        [Parameter()]
        [System.UInt64]
        $Size,

        [Parameter()]
        [System.String]
        $FSLabel,

        [Parameter()]
        [System.UInt32]
        $AllocationUnitSize,

        [Parameter()]
        [ValidateSet('NTFS', 'ReFS')]
        [System.String]
        $FSFormat = 'NTFS',

        [Parameter()]
        [System.Boolean]
        $AllowDestructive,

        [Parameter()]
        [System.Boolean]
        $ClearDisk,

        [Parameter()]
        [System.Boolean]
        $DevDrive
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.TestingDiskMessage -f $DiskIdType, $DiskId, $DriveLetter)
        ) -join '' )

    # Validate the DriveLetter parameter
    $DriveLetter = Assert-DriveLetterValid -DriveLetter $DriveLetter

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.CheckDiskInitializedMessage -f $DiskIdType, $DiskId)
        ) -join '' )

    # Get the Disk using the identifiers supplied
    $disk = Get-DiskByIdentifier `
        -DiskId $DiskId `
        -DiskIdType $DiskIdType

    if (-not $disk)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.DiskNotFoundMessage -f $DiskIdType, $DiskId)
            ) -join '' )

        return $false
    } # if

    if ($disk.IsOffline)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.DiskNotOnlineMessage -f $DiskIdType, $DiskId)
            ) -join '' )

        return $false
    } # if

    if ($disk.IsReadOnly)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.DiskReadOnlyMessage `
                        -f $DiskIdType, $DiskId)
            ) -join '' )

        return $false
    } # if

    if ($disk.PartitionStyle -ne $PartitionStyle)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.DiskPartitionStyleNotMatchMessage `
                        -f $DiskIdType, $DiskId, $disk.PartitionStyle, $PartitionStyle)
            ) -join '' )

        if ($disk.PartitionStyle -eq 'RAW' -or ($AllowDestructive -and $ClearDisk))
        {
            return $false
        }
        else
        {
            # This disk is initialized but with the incorrect partition style
            New-InvalidOperationException `
                -Message ($script:localizedData.DiskInitializedWithWrongPartitionStyleError `
                    -f $DiskIdType, $DiskId, $disk.PartitionStyle, $PartitionStyle)
        }
    } # if

    $partition = Get-Partition `
        -DriveLetter $DriveLetter `
        -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($partition.DriveLetter -ne $DriveLetter)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.DriveLetterNotFoundMessage -f $DriveLetter)
            ) -join '' )

        return $false
    } # if

    # Check the partition size
    if ($partition -and -not ($PSBoundParameters.ContainsKey('Size')))
    {
        $supportedSize = ($partition | Get-PartitionSupportedSize)

        <#
            If the difference in size between the supported partition size
            and the current partition size is less than 1MB then set the
            desired partition size to the current size. This will prevent
            any size difference less than 1MB from trying to contiuously
            resize. See https://github.com/dsccommunity/StorageDsc/issues/181
        #>
        if (($supportedSize.SizeMax - $partition.Size) -lt 1MB)
        {
            $Size = $partition.Size
        }
        else
        {
            $Size = $supportedSize.SizeMax
        }
    }

    if ($Size)
    {
        if ($partition.Size -ne $Size)
        {
            # The partition size mismatches
            if ($AllowDestructive)
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.SizeMismatchWithAllowDestructiveMessage `
                                -f $DriveLetter, $Partition.Size, $Size)
                    ) -join '' )

                if ($DevDrive)
                {
                    <#
                        In the Dev Drive scenario we may resize a partition to create new unallocated space, so
                        that we can create a new Dev Drive. When this is done we create a new partition on the
                        largest free extent on the disk. However, Though the value is equivalent they aren't
                        always the same. E.g 150Gb in powershell cmdline is 161061273600 bytes.
                        But $disk.LargestFreeExtent could be 161060225024 bytes. Which is different but they are
                        both 150Gb when you convert them.

                        See the 'Size' parameter in:
                        https://learn.microsoft.com/en-us/windows-hardware/drivers/storage/createpartition-msft-disk
                        for more information. But to some it up, what the user enters and what the New-Partition
                        cmdlet is able to allocate can be different in bytes. So to keep idempotence, we only
                        return false when they arent the same in GB. Also if the volume already is formatted as
                        a ReFS, there is no point in returning false for size mismatches since they can't be
                        resized with resize-partition.
                    #>

                    $partitionSizeEqualToSizeParam = Compare-SizeUsingGB `
                        -SizeAInBytes $Size `
                        -SizeBInBytes $partition.Size

                    $volume = $partition | Get-Volume

                    if ((-not $partitionSizeEqualToSizeParam) -and $volume.FileSystem -ne 'ReFS')
                    {
                        return $false
                    }
                }
                else
                {
                    return $false
                }
            }
            else
            {
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($script:localizedData.SizeMismatchMessage `
                                -f $DriveLetter, $Partition.Size, $Size)
                    ) -join '' )
            }
        } # if

        if ($DevDrive)
        {
            Assert-SizeMeetsMinimumDevDriveRequirement -UserDesiredSize $Size
        }
    } # if

    $blockSize = (Get-CimInstance `
            -Query "SELECT BlockSize from Win32_Volume WHERE DriveLetter = '$($DriveLetter):'" `
            -ErrorAction SilentlyContinue).BlockSize

    if ($blockSize -gt 0 -and $AllocationUnitSize -ne 0)
    {
        if ($AllocationUnitSize -ne $blockSize)
        {
            # The allocation unit size mismatches
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.AllocationUnitSizeMismatchMessage `
                            -f $DriveLetter, $($blockSize.BlockSize / 1KB), $($AllocationUnitSize / 1KB))
                ) -join '' )

            if ($AllowDestructive)
            {
                return $false
            }
        } # if
    } # if

    # Get the volume so the properties can be checked
    $volume = Get-Volume `
        -DriveLetter $DriveLetter `
        -ErrorAction SilentlyContinue

    if ($PSBoundParameters.ContainsKey('FSFormat'))
    {
        # Check the filesystem format
        $fileSystem = $volume.FileSystem
        if ($fileSystem -ne $FSFormat)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.FileSystemFormatMismatch `
                            -f $DriveLetter, $fileSystem, $FSFormat)
                ) -join '' )

            if ($AllowDestructive)
            {
                return $false
            }
        } # if
    } # if

    if ($PSBoundParameters.ContainsKey('FSLabel'))
    {
        # Check the volume label
        $label = $volume.FileSystemLabel
        if ($label -ne $FSLabel)
        {
            # The assigned volume label is different and needs updating
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.DriveLabelMismatch `
                            -f $DriveLetter, $label, $FSLabel)
                ) -join '' )

            return $false
        } # if
    } # if

    if ($DevDrive)
    {
        # User requested to configure the volume as a Dev Drive volume. So we check that the assertions are met.
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.CheckingDevDriveAssertions)
        ) -join '' )

        Assert-DevDriveFeatureAvailable
        Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue -FSFormat $FSFormat

        $isDevDriveVolume = Test-DevDriveVolume -VolumeGuidPath $volume.UniqueId -ErrorAction SilentlyContinue

        if ($isDevDriveVolume)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.TheVolumeIsCurrentlyConfiguredAsADevDriveVolume `
                    -f $volume.UniqueId, $volume.DriveLetter)
            ) -join '' )
        }
        else
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.TheVolumeIsNotConfiguredAsADevDriveVolume `
                    -f $volume.UniqueId, $volume.DriveLetter)
            ) -join '' )

            return $false
        }
    }

    return $true
} # Test-TargetResource

Export-ModuleMember -Function *-TargetResource
