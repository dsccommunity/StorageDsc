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
    Returns the current drive letter assigned to the optical disk.

    .PARAMETER DriveLetter
    Specifies the preferred letter to assign to the optical disk.

#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        # specify the drive letter as a single letter, optionally include the colon
        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter
    )

    # allow use of drive letter without colon
    $DriveLetter = Assert-DriveLetterValid -DriveLetter $DriveLetter -Colon

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($localizedData.UsingGetCimInstanceToFetchDriveLetter)
    ) -join '' )

    $currentDriveLetter = Get-OpticalDiskDriveLetter

    if (-not $currentDriveLetter)
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.NoOpticalDiskDrive)
        ) -join '' )

        $Ensure = 'Present'
    }
    else {
        # check if $driveletter is the location of the optical disk
        if ($currentDriveLetter -eq $DriveLetter)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($localizedData.OpticalDriveSetAsRequested -f $DriveLetter)
            ) -join '' )

            $Ensure = 'Present'
        }
        else
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($localizedData.OpticalDriveNotSetAsRequested -f $currentDriveLetter,$DriveLetter)
            ) -join '' )

            $Ensure = 'Absent'
        }
    }

    $returnValue = @{
    DriveLetter = $currentDriveLetter
    Ensure = $Ensure
    }

    $returnValue

} # Get-TargetResource

<#
    .SYNOPSIS
    Sets the drive letter of the optical disk.

    .PARAMETER DriveLetter
    Specifies the drive letter to assign to the optical disk.

    .PARAMETER Ensure
    Determines whether the setting should be applied or removed.
#>
function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$True,
                   ConfirmImpact='Low')]
    param
    (
        # specify the drive letter as a single letter, optionally include the colon
        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    # allow use of drive letter without colon
    $DriveLetter = Assert-DriveLetterValid -DriveLetter $DriveLetter -Colon

    $currentDriveLetter = Get-OpticalDiskDriveLetter

    if ($currentDriveLetter -eq $DriveLetter -and $Ensure -eq 'Present')
    {
        return
    }

    # assuming a drive letter is found
    if ($currentDriveLetter)
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.AttemptingToSetDriveLetter -f $currentDriveLetter,$DriveLetter)
        ) -join '' )

        if ($PSCmdlet.ShouldProcess("Setting optical disk letter to $DriveLetter"))
        {

            # if $Ensure -eq Absent this will remove the drive letter from the optical disk
            if ($Ensure -eq 'Absent')
            {
                $DriveLetter = $null
            }
            Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$currentDriveLetter'" |
                Set-CimInstance -Property @{ DriveLetter = $DriveLetter }
        }
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.NoOpticalDiskDrive)
        ) -join '' )
    }
} # Set-TargetResource

<#
    .SYNOPSIS
    Tests the optical disk letter is set as expected

    .PARAMETER DriveLetter
    Specifies the drive letter to test if it is assigned to the optical disk.

    .PARAMETER Ensure
    Determines whether the setting should be applied or removed.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        # specify the drive letter as a single letter, optionally include the colon
        [Parameter(Mandatory = $true)]
        [System.String]
        $DriveLetter,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    # allow use of drive letter without colon
    $DriveLetter = Assert-DriveLetterValid -DriveLetter $DriveLetter -Colon

    # is there a optical disk
    $opticalDrive = Get-CimInstance -ClassName Win32_cdromdrive -Property Id
    # what type of drive is attached to $driveletter
    $volumeDriveType = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$DriveLetter'" -Property DriveType

    # check there is a optical disk
    if ($opticalDrive)
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.OpticalDiskDriveFound -f $opticaDrive.id)
        ) -join '' )

        if ($volumeDriveType.DriveType -eq 5)
        {

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($localizedData.DriveLetterVolumeType -f $driveletter, $volumeDriveType.DriveType)
            ) -join '' )

        }
        else
        {

            Write-Warning -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($localizedData.DriveLetterExistsButNotOptical -f $driveletter)
            ) -join '' )

        }

        # return true if the drive letter is a optical disk resource
        $result = [System.Boolean]($volumeDriveType.DriveType -eq 5)

        # return false if the drive letter specified is a optical disk resource & $Ensure -eq 'Absent'
        if ($Ensure -eq 'Absent')
        {
            $result = -not $result
        }
    }
    else
    {
        # return true if there is no optical disk - can't set what isn't there!
        Write-Warning -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.NoOpticalDiskDrive)
        ) -join '' )

        $result = $false
    }

    $result
}

Export-ModuleMember -Function *-TargetResource

