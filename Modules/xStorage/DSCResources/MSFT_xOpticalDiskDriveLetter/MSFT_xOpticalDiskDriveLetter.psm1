# Suppressed as per PSSA Rule Severity guidelines for unit/integration tests:
# https://github.com/PowerShell/DscResources/blob/master/PSSARuleSeverities.md
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Storage Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'StorageDsc.Common' `
            -ChildPath 'StorageDsc.Common.psm1'))

# Import the Storage Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'StorageDsc.ResourceHelper' `
            -ChildPath 'StorageDsc.ResourceHelper.psm1'))

# Import Localization Strings
$localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xOpticalDiskDriveLetter' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
    This helper function returns the current drive letter assigned
    to the a disk number disk found in the system.

    If the drive exists but is not mounted to a drive letter then
    it will return an empty string.

    If there are no optical disks found in the system, return null.

    .PARAMETER DiskId
    Specifies the optical disk number for the disk to return the drive
    letter of.

    .PARAMETER ReturnDeviceIdOnNoDriveLetter
    This switch will cause the Drive Letter to be returned with the
    default value that Drive is set to when no Drive Letter is assigned
    e.g. 'Volume{bba1802b-e7a1-11e3-824e-806e6f6e6963}'.

    Otherwise the Drive Letter will be empty

    .NOTES
    The Caption and DeviceID properties are checked to avoid
    mounted ISO images in Windows 2012+ and Windows 10. The
    device ID is required because a CD/DVD in a Hyper-V virtual
    machine has the same caption as a mounted ISO.

    Example DeviceID for a virtual drive in a Hyper-V VM - SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006
    Example DeviceID for a mounted ISO   in a Hyper-V VM - SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\2&1F4ADFFE&0&000002
#>
function Get-OpticalDiskDriveLetter
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter()]
        [Switch]
        $ReturnDeviceIdOnNoDriveLetter
    )

    $driveLetter = $null

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.UsingGetCimInstanceToFetchDriveLetter -f $DiskId)
        ) -join '' )

    # Get the optical disk matching the Id
    $opticalDisks = Get-CimInstance -ClassName Win32_CDROMDrive |
        Where-Object -FilterScript {
        -not (
            $_.Caption -eq 'Microsoft Virtual DVD-ROM' -and
            ($_.DeviceID.Split('\')[-1]).Length -gt 10
        )
    }

    if ($opticalDisks)
    {
        $opticalDisk = $opticalDisks[$DiskId - 1]

        if ($opticalDisk)
        {
            try
            {
                # Make sure the current DriveLetter is an actual drive letter
                $driveLetter = Assert-DriveLetterValid -DriveLetter $opticalDisk.Drive -Colon
            }
            catch
            {
                # Optical drive exists but is not mounted to a drive letter
                if ($ReturnDeviceIdOnNoDriveLetter)
                {
                    $driveLetter = $opticalDisk.Drive

                    Write-Verbose -Message ( @(
                            "$($MyInvocation.MyCommand): "
                            $($localizedData.OpticalDiskAssignedDriveLetter -f $DiskId, $driveLetter)
                        ) -join '' )
                }
                else
                {
                    $driveLetter = ''

                    Write-Verbose -Message ( @(
                            "$($MyInvocation.MyCommand): "
                            $($localizedData.OpticalDiskNotAssignedDriveLetter -f $DiskId)
                        ) -join '' )

                }
            }
        }
    }

    if ($null -eq $driveLetter)
    {
        New-InvalidArgumentException `
            -Message ($localizedData.NoOpticalDiskDriveError -f $DiskId) `
            -ArgumentName 'DiskId'
    }

    return $driveLetter
}

<#
    .SYNOPSIS
    Returns the current drive letter assigned to the optical disk.

    .PARAMETER DiskId
    Specifies the optical disk number for the disk to assign the drive
    letter to.

    .PARAMETER DriveLetter
    Specifies the drive letter to assign to the optical disk. Can be a
    single letter, optionally followed by a colon.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter
    )

    $ensure = 'Absent'

    # Get the drive letter assigned to the optical disk
    $currentDriveLetter = Get-OpticalDiskDriveLetter -DiskId $DiskId

    if ([System.String]::IsNullOrWhiteSpace($currentDriveLetter))
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($localizedData.OpticalDiskNotAssignedDriveLetter -f $DiskId)
            ) -join '' )
    }
    else
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($localizedData.OpticalDiskAssignedDriveLetter -f $DiskId, $DriveLetter)
            ) -join '' )

        $Ensure = 'Present'
    }

    $returnValue += @{
        DiskId      = $DiskId
        DriveLetter = $currentDriveLetter
        Ensure      = $ensure
    }

    return $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
    Sets the drive letter of an optical disk.

    .PARAMETER DiskId
    Specifies the optical disk number for the disk to assign the drive
    letter to.

    .PARAMETER DriveLetter
    Specifies the drive letter to assign to the optical disk. Can be a
    single letter, optionally followed by a colon.

    .PARAMETER Ensure
    Determines whether a drive letter should be assigned to the
    optical disk. Defaults to 'Present'.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    # Allow use of drive letter without colon
    $DriveLetter = Assert-DriveLetterValid -DriveLetter $DriveLetter -Colon

    # Get the drive letter assigned to the optical disk
    $currentDriveLetter = Get-OpticalDiskDriveLetter -DiskId $DiskId

    if ([System.String]::IsNullOrWhiteSpace($currentDriveLetter))
    {
        <#
            If the current drive letter is empty then the volume must be looked up by DeviceId
            The DeviceId in the volume will show as \\?\Volume{bba1802b-e7a1-11e3-824e-806e6f6e6963}\
            So we need to change the currentDriveLetter to match this value when we set the drive letter
        #>
        $deviceId = Get-OpticalDiskDriveLetter -DiskId $DiskId -ReturnDeviceIdOnNoDriveLetter

        $volume = Get-CimInstance `
            -ClassName Win32_Volume `
            -Filter "DeviceId = '\\\\?\\$deviceId\\'"
    }
    else
    {
        $volume = Get-CimInstance `
            -ClassName Win32_Volume `
            -Filter "DriveLetter = '$currentDriveLetter'"
    }

    # Does the Drive Letter need to be added or removed
    if ($Ensure -eq 'Absent')
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.AttemptingToRemoveDriveLetter -f $diskId, $currentDriveLetter)
        ) -join '' )

        $volume | Set-CimInstance -Property @{ DriveLetter = $null }
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.AttemptingToSetDriveLetter -f $diskId, $currentDriveLetter, $DriveLetter)
        ) -join '' )

        $volume | Set-CimInstance -Property @{ DriveLetter = $DriveLetter }
    }
} # Set-TargetResource

<#
    .SYNOPSIS
    Tests the disk letter assigned to an optical disk is correct.

    .PARAMETER DiskId
    Specifies the optical disk number for the disk to assign the drive
    letter to.

    .PARAMETER DriveLetter
    Specifies the drive letter to assign to the optical disk. Can be a
    single letter, optionally followed by a colon.

    .PARAMETER Ensure
    Determines whether a drive letter should be assigned to the
    optical disk. Defaults to 'Present'.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $desiredConfigurationMatch = $true

    # Allow use of drive letter without colon
    $DriveLetter = Assert-DriveLetterValid -DriveLetter $DriveLetter -Colon

    # Get the drive letter assigned to the optical disk
    $currentDriveLetter = Get-OpticalDiskDriveLetter -DiskId $DiskId

    if ($Ensure -eq 'Absent')
    {
        # The Drive Letter should be absent from the optical disk
        if ([System.String]::IsNullOrWhiteSpace($currentDriveLetter))
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($localizedData.DriveLetterDoesNotExistAndShouldNot -f $DiskId)
                ) -join '' )
        }
        else
        {
            # The Drive Letter needs to be dismounted
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($localizedData.DriveLetterExistsButShouldNot -f $DiskId, $currentDriveLetter)
                ) -join '' )

            $desiredConfigurationMatch = $false
        }
    }
    else
    {
        if ($currentDriveLetter -eq $DriveLetter)
        {
            # The optical disk drive letter is already set correctly
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($localizedData.DriverLetterExistsAndIsCorrect -f $DiskId, $DriveLetter)
                ) -join '' )
        }
        else
        {
            # Is a desired drive letter already assigned to a different drive?
            $existingVolume = Get-CimInstance `
                -ClassName Win32_Volume `
                -Filter "DriveLetter = '$DriveLetter'"

            if ($existingVolume)
            {
                # The desired drive letter is already assigned to another drive - can't proceed
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($localizedData.DriveLetterAssignedToAnotherDrive -f $DriveLetter)
                    ) -join '' )
            }
            else
            {
                # The optical drive letter needs to be changed
                Write-Verbose -Message ( @(
                        "$($MyInvocation.MyCommand): "
                        $($localizedData.DriverLetterExistsAndIsNotCorrect -f $DiskId, $currentDriveLetter, $DriveLetter)
                    ) -join '' )

                $desiredConfigurationMatch = $false
            }
        }
    }

    return $desiredConfigurationMatch
}

Export-ModuleMember -Function *-TargetResource
