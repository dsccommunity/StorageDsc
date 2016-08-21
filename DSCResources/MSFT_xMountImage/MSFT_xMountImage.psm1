#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_xMountImage.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_xMountImage.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

# Import the common storage functions
Import-Module -Name ( Join-Path `
    -Path (Split-Path -Path $PSScriptRoot -Parent) `
    -ChildPath '\MSFT_xStorageCommon\MSFT_xStorageCommon.psm1' )

<#
    .SYNOPSIS
    Returns the current state of the mounted image.
    .PARAMETER Name
    This setting provides a unique name for the configuration.
    .PARAMETER ImagePath
    Specifies the path of the VHD or ISO file.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ImagePath
    )

    # Validate driveletter has a ":"
    if ($DriveLetter -match "^[A-Za-z][:]$")
    {
        Write-Verbose "DriveLetter validation passed."
    }
    else
    {
        Throw "DriveLetter did not pass validation.  Ensure DriveLetter contains a letter and a colon."
    } # if

    # Test for Image mounted. If not mounted mount
    $Image = Get-DiskImage -ImagePath $ImagePath | Get-Volume

    if ($Image)
    {
        $EnsureResult = 'Present'
        $Name = $Name
    }
    Eese
    {
        $EnsureResult = 'Absent'
        $Name = $null
    }

    $returnValue = @{
        Name = [System.String]$Name
        ImagePath = [System.String]$ImagePath
        DriveLetter = [System.String]$Image.DriveLetter
        Ensure = [System.String]$EnsureResult
    }

    $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
    Mounts or dismounts the ISO.
    .PARAMETER Name
    This setting provides a unique name for the configuration.
    .PARAMETER ImagePath
    Specifies the path of the VHD or ISO file.
    .PARAMETER DriveLetter
    Specifies the drive letter after the ISO is mounted.
    .PARAMETER Ensure
    Determines whether the setting should be applied or removed.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ImagePath,

        [System.String]
        $DriveLetter,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present'
    )

    # Validate driveletter has a ":"
    if ($DriveLetter -match "^[A-Za-z][:]$")
    {
        Write-Verbose "DriveLetter validation passed."
    }
    else
    {
        Throw "DriveLetter did not pass validation. Ensure DriveLetter contains a letter and a colon."
    } # if

    # Test for Image mounted. If not mounted mount
    $Image = Get-DiskImage -ImagePath $ImagePath | Get-Volume

    if ($Ensure -eq 'Present')
    {
        $Image = Get-DiskImage -ImagePath $ImagePath | Get-Volume
        if (!$Image)
        {
            Write-Verbose "Image is not mounted. Mounting image $ImagePath"
            $Image = Mount-DiskImage -ImagePath $ImagePath -PassThru | Get-Volume
        } # if

        #Verify drive letter
        $CimVolume = Get-CimInstance -ClassName Win32_Volume |
            Where-Object -FilterScript  {$_.DeviceId -eq $Image.ObjectId}
        if ($CimVolume.DriveLetter -ne $DriveLetter)
        {
            Write-Verbose "Drive letter does not match expected value. Expected DriveLetter $DriveLetter Actual DriverLetter $($CimVolume.DriveLetter)"
            Write-Verbose "Changing drive letter to $DriveLetter"
            Set-CimInstance -InputObject $CimVolume -Property @{DriveLetter = $DriveLetter}
        } # if
    }
    else
    {
        Write-Verbose "Dismounting $ImagePath"
        Dismount-DiskImage -ImagePath $ImagePath
    } # if
} # Set-TargetResource

<#
    .SYNOPSIS
    Tests if the ISO mount is in the correct state.
    .PARAMETER Name
    This setting provides a unique name for the configuration.
    .PARAMETER ImagePath
    Specifies the path of the VHD or ISO file.
    .PARAMETER DriveLetter
    Specifies the drive letter after the ISO is mounted.
    .PARAMETER Ensure
    Determines whether the setting should be applied or removed.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ImagePath,

        [System.String]
        $DriveLetter,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present'
    )

    # Validate driveletter has a ":"
    if ($DriveLetter -match "^[A-Za-z][:]$")
    {
        Write-Verbose "DriveLetter validation passed."
    }
    else
    {
        Throw "DriveLetter did not pass validation.  Ensure DriveLetter contains a letter and a colon."
    } # if

    #Test for Image mounted. If not mounted mount
    $Image = Get-DiskImage -ImagePath $ImagePath | Get-Volume

    if ($Ensure -eq 'Present')
    {
        $Image = Get-DiskImage -ImagePath $ImagePath | Get-Volume
        if (!$Image)
        {
            Write-Verbose "Image is not mounted. Mounting image $ImagePath"
            return $false
        } # if

        # Verify drive letter
        $CimVolume = Get-CimInstance -ClassName Win32_Volume | where {$_.DeviceId -eq $Image.ObjectId}
        if ($CimVolume.DriveLetter -ne $DriveLetter)
        {
            Write-Verbose "Drive letter does not match expected value. Expected DriveLetter $DriveLetter Actual DriverLetter $($CimVolume.DriveLetter)"

            return $false
        } # if
        # If the script made it this far the ISO is mounted and has the desired DriveLetter

        return $true
    } # if

    if ($Ensure -eq 'Absent' -and $Image)
    {
        Write-Verbose "Expect ISO to be dismounted. Actual is mounted with drive letter $($Image.DriveLetter)"
        return $false
    }
    else
    {
        return $true
    } # if
} # Test-TargetResource

Export-ModuleMember -Function *-TargetResource
