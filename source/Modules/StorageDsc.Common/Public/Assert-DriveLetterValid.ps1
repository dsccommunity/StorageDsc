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
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DriveLetter,

        [Parameter()]
        [Switch]
        $Colon
    )

    $matches = @([regex]::matches($DriveLetter, '^([A-Za-z]):?$', 'IgnoreCase'))

    if (-not $matches)
    {
        # DriveLetter format is invalid
        New-ArgumentException `
            -Message $($script:localizedData.InvalidDriveLetterFormatError -f $DriveLetter) `
            -ArgumentName 'DriveLetter'
    }

    # This is the drive letter without a colon
    $DriveLetter = $matches.Groups[1].Value

    if ($Colon)
    {
        $DriveLetter = $DriveLetter + ':'
    } # if

    return $DriveLetter
}
