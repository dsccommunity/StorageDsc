# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
                               -ChildPath (Join-Path -Path 'StorageDsc.ResourceHelper' `
                                                     -ChildPath 'StorageDsc.ResourceHelper.psm1'))

# Import Localization Strings
$localizedData = Get-LocalizedData `
    -ResourceName 'StorageDsc.Common' `
    -ResourcePath $PSScriptRoot

<#
    .SYNOPSIS
    Validates a Drive Letter, removing or adding the trailing colon if required.

    .PARAMETER DriveLetter
    The Drive Letter string to validate.

    .PARAMETER Colon
    Will ensure the returned string will include or exclude a colon.
#>
function Assert-DriveLetterValid
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DriveLetter,

        [Switch]
        $Colon
    )

    $Matches = @([regex]::matches($DriveLetter, '^([A-Za-z]):?$', 'IgnoreCase'))
    if (-not $Matches)
    {
        # DriveLetter format is invalid
        New-InvalidArgumentException `
            -Message $($LocalizedData.InvalidDriveLetterFormatError -f $DriveLetter) `
            -ArgumentName 'DriveLetter'
    }
    # This is the drive letter without a colon
    $DriveLetter = $Matches.Groups[1].Value
    if ($Colon)
    {
        $DriveLetter = $DriveLetter + ':'
    } # if
    return $DriveLetter
} # end function Assert-DriveLetterValid

<#
    .SYNOPSIS
    Validates an Access Path, removing or adding the trailing slash if required.
    If the Access Path does not exist or is not a folder then an exception will
    be thrown.

    .PARAMETER AccessPath
    The Access Path string to validate.

    .PARAMETER Slash
    Will ensure the returned path will include or exclude a slash.
#>
function Assert-AccessPathValid
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AccessPath,

        [Switch]
        $Slash
    )

    if (-not (Test-Path -Path $AccessPath -PathType Container))
    {
        # AccessPath is invalid
        New-InvalidArgumentException `
            -Message $($LocalizedData.InvalidAccessPathError -f $AccessPath) `
            -ArgumentName 'AccessPath'
    } # if

    # Remove or Add the trailing slash
    if($AccessPath.EndsWith('\'))
    {
        if (-not $Slash)
        {
            $AccessPath = $AccessPath.TrimEnd('\')
        } # if
    }
    else
    {
        if ($Slash)
        {
            $AccessPath = "$AccessPath\"
        } # if
    } # if

    return $AccessPath
} # end function Assert-AccessPathValid


<#
    .SYNOPSIS
    Retrieves a Disk object matching the disk Id and Id type
    provided.

    .PARAMETER DiskId
    Specifies the disk identifier for the disk to retrieve.

    .PARAMETER DiskIdType
    Specifies the identifier type the DiskId contains. Defaults to Number.
#>
function Get-DiskByIdentifier
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter()]
        [ValidateSet('Number','UniqueId','Guid')]
        [System.String]
        $DiskIdType = 'Number'
    )

    if ($DiskIdType -eq 'Guid')
    {
        # The Disk Id requested uses a Guid so have to get all disks and filter
        $disk = Get-Disk `
            -ErrorAction SilentlyContinue |
            Where-Object -Property Guid -EQ $DiskId
    }
    else
    {
        $diskIdParameter = @{
            $DiskIdType = $DiskId
        }

        $disk = Get-Disk `
            @diskIdParameter `
            -ErrorAction SilentlyContinue
    }

    return $disk
} # end function Get-DiskByIdentifier

Export-ModuleMember -Function `
    Assert-DriveLetterValid, `
    Assert-AccessPathValid, `
    Get-DiskByIdentifier
