#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_xDisk.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_xDisk.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

# Import the common storage functions
Import-Module -Name ( Join-Path `
    -Path (Split-Path -Path $PSScriptRoot -Parent) `
    -ChildPath '\MSFT_xStorageCommon\MSFT_xStorageCommon.psm1' )

<#
    .SYNOPSIS
    Returns the current state of the Disk and Partition.
    .PARAMETER DiskNumber
    Specifies the identifier for which disk to modify.
    .PARAMETER DriveLetter
    Specifies the preferred letter to assign to the disk volume.
    .PARAMETER Size
    Specifies the size of new volume (use all available space on disk if not provided).
    .PARAMETER FSLabel
    Define volume label if required.
    .PARAMETER AllocationUnitSize
    Specifies the allocation unit size to use when formatting the volume.
#>
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [uint32] $DiskNumber,

        [parameter(Mandatory)]
        [string] $DriveLetter,

        [UInt64] $Size,

        [string] $FSLabel,

        [UInt32] $AllocationUnitSize
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingDiskMessage -f $DiskNumber,$DriveLetter)
        ) -join '' )

    $disk = Get-Disk -Number $DiskNumber -ErrorAction SilentlyContinue

    $partition = Get-Partition -DriveLetter $DriveLetter -ErrorAction SilentlyContinue

    $FSLabel = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FileSystemLabel

    $blockSize = Get-CimInstance `
        -Query "SELECT BlockSize from Win32_Volume WHERE DriveLetter = '$($DriveLetter):'" `
        -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty BlockSize

    if ($blockSize)
    {
        $allocationUnitSize = $blockSize
    }
    else
    {
        # If Get-CimInstance did not return a value, try again with Get-WmiObject
        $blockSize = Get-WmiObject `
            -Query "SELECT BlockSize from Win32_Volume WHERE DriveLetter = '$($DriveLetter):'" `
            -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty BlockSize
        $allocationUnitSize = $blockSize
    } # if

    $returnValue = @{
        DiskNumber = $disk.Number
        DriveLetter = $partition.DriveLetter
        Size = $partition.Size
        FSLabel = $FSLabel
        AllocationUnitSize = $allocationUnitSize
    }
    $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
    Initializes the Disk and Partition and assigns the drive letter.
    .PARAMETER DiskNumber
    Specifies the identifier for which disk to modify.
    .PARAMETER DriveLetter
    Specifies the preferred letter to assign to the disk volume.
    .PARAMETER Size
    Specifies the size of new volume (use all available space on disk if not provided).
    .PARAMETER FSLabel
    Define volume label if required.
    .PARAMETER AllocationUnitSize
    Specifies the allocation unit size to use when formatting the volume.
#>
function Set-TargetResource
{
    param
    (
        [parameter(Mandatory)]
        [uint32] $DiskNumber,

        [parameter(Mandatory)]
        [string] $DriveLetter,

        [UInt64] $Size,

        [string] $FSLabel,

        [UInt32] $AllocationUnitSize
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.SettingDiskMessage -f $DiskNumber,$DriveLetter)
        ) -join '' )

    $disk = Get-Disk `
        -Number $DiskNumber `
        -ErrorAction Stop

    if ($disk.IsOffline -eq $true)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.SetDiskOnlineMessage -f $DiskNumber)
            ) -join '' )

        $disk | Set-Disk -IsOffline $false
    } # if

    if ($disk.IsReadOnly -eq $true)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.SetDiskReadwriteMessage -f $DiskNumber)
            ) -join '' )

        $disk | Set-Disk -IsReadOnly $false
    } # if

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.CheckingDiskPartitionStyleMessage -f $DiskNumber)
        ) -join '' )

    switch ($disk.PartitionStyle)
    {
        "RAW"
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.InitializingDiskMessage -f $DiskNumber)
                ) -join '' )

            $disk | Initialize-Disk -PartitionStyle "GPT" -PassThru
        }
        "GPT"
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.DiskAlreadyInitializedMessage -f $DiskNumber)
                ) -join '' )
        }
        default
        {
            New-InvalidOperationError `
                -ErrorId 'DiskAlreadyInitializedError' `
                -ErrorMessage ($LocalizedData.DiskAlreadyInitializedError -f `
                    $DiskNumber,$Disk.PartitionStyle)
        }
    } # switch

    # Check if existing partition already has file system on it
    if ($null -eq ($disk | Get-Partition | Get-Volume ))
    {
        $partParams = @{
            DriveLetter = $DriveLetter;
            DiskNumber = $DiskNumber
        }

        if ($Size)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.CreatingPartitionMessage -f $DiskNumber,$DriveLetter,"$($Size/1kb) kb")
                ) -join '' )
            $partParams["Size"] = $Size
        }
        else
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.CreatingPartitionMessage -f $DiskNumber,$DriveLetter,'all free space')
                ) -join '' )
            $partParams["UseMaximumSize"] = $true
        } # if

        $partition = New-Partition @PartParams

        # Sometimes the disk will still be read-only after the call to New-Partition returns.
        Start-Sleep -Seconds 5

        $volParams = @{
            FileSystem = "NTFS";
            Confirm = $false
        }

        if ($FSLabel)
        {
            $volParams["NewFileSystemLabel"] = $FSLabel
        } # if
        if($AllocationUnitSize)
        {
            $volParams["AllocationUnitSize"] = $AllocationUnitSize
        } # if

        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.FormattingVolumeMessage -f $VolParams.FileSystem)
            ) -join '' )

        $volume = $partition | Format-Volume @VolParams

        if ($volume)
        {

            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.SuccessfullyInitializedMessage -f $DriveLetter)
                ) -join '' )
        } # if
    }
    else
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.ChangingDriveLetterMessage -f $DriveLetter)
            ) -join '' )

        $VolumeDriveLetter = ($disk | Get-Partition | Get-Volume).driveletter

        if ($null -eq $volumeDriveLetter)
        {
            Set-Partition `
                -DiskNumber $DiskNumber `
                -PartitionNumber 2 `
                -NewDriveLetter $DriveLetter
        }
        else
        {
            Set-Partition `
                -DriveLetter $volumeDriveLetter `
                -NewDriveLetter $DriveLetter
        } # if
    } # if
} # Set-TargetResource

<#
    .SYNOPSIS
    Tests if the disk is initialized, the partion exists and the drive letter is assigned.
    .PARAMETER DiskNumber
    Specifies the identifier for which disk to modify.
    .PARAMETER DriveLetter
    Specifies the preferred letter to assign to the disk volume.
    .PARAMETER Size
    Specifies the size of new volume (use all available space on disk if not provided).
    .PARAMETER FSLabel
    Define volume label if required.
    .PARAMETER AllocationUnitSize
    Specifies the allocation unit size to use when formatting the volume.
#>
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory)]
        [uint32] $DiskNumber,

        [parameter(Mandatory)]
        [string] $DriveLetter,

        [UInt64] $Size,

        [string] $FSLabel,

        [UInt32] $AllocationUnitSize
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.TestingDiskMessage -f $DiskNumber,$DriveLetter)
        ) -join '' )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.CheckDiskInitializedMessage -f $DiskNumber)
        ) -join '' )

    $disk = Get-Disk `
        -Number $DiskNumber `
        -ErrorAction SilentlyContinue

    if (-not $disk)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.DiskNotFoundMessage -f $DiskNumber)
            ) -join '' )
        return $false
    } # if

    if ($disk.IsOffline -eq $true)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.DiskNotOnlineMessage -f $DiskNumber)
            ) -join '' )
        return $false
    } # if

    if ($disk.IsReadOnly -eq $true)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.DiskReadOnlyMessage -f $DiskNumber)
            ) -join '' )
        return $false
    } # if

    if ($disk.PartitionStyle -ne "GPT")
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.DiskNotGPTMessage -f $DiskNumber,$Disk.PartitionStyle)
            ) -join '' )
        return $false
    } # if

    $partition = Get-Partition `
        -DriveLetter $DriveLetter `
        -ErrorAction SilentlyContinue
    if ($partition.DriveLetter -ne $DriveLetter)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.DriveLetterNotFoundMessage -f $DriveLetter)
            ) -join '' )
        return $false
    } # if

    # Drive size
    if ($Size)
    {
        if ($partition.Size -ne $Size)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.DriveSizeMismatchMessage -f `
                        $DriveLetter,$Partition.Size,$Size)
                ) -join '' )
            return $false
        } # if
    } # if

    $blockSize = Get-CimInstance `
        -Query "SELECT BlockSize from Win32_Volume WHERE DriveLetter = '$($DriveLetter):'" `
        -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty BlockSize
    if (-not ($blockSize))
    {
        # If Get-CimInstance did not return a value, try again with Get-WmiObject
        $blockSize = Get-WmiObject `
            -Query "SELECT BlockSize from Win32_Volume WHERE DriveLetter = '$($DriveLetter):'" `
            -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty BlockSize
    } # if

    if($BlockSize -gt 0 -and $AllocationUnitSize -ne 0)
    {
        if($AllocationUnitSize -ne $BlockSize)
        {
            # Just write a warning, we will not try to reformat a drive due to invalid allocation
            # unit sizes
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.DriveAllocationUnitSizeMismatchMessage -f `
                        $DriveLetter,$($BlockSize.BlockSize/1kb),$($AllocationUnitSize/1kb))
                ) -join '' )
        } # if
    } # if

    # Volume label
    if (-not [string]::IsNullOrEmpty($FSLabel))
    {
        $label = Get-Volume `
            -DriveLetter $DriveLetter `
            -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FileSystemLabel
        if ($label -ne $FSLabel)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.DriveLabelMismatch -f `
                        $DriveLetter,$Label,$FSLabel)
                ) -join '' )
            return $false
        } # if
    } # if

    return $true
} # Test-TargetResource

Export-ModuleMember -Function *-TargetResource
