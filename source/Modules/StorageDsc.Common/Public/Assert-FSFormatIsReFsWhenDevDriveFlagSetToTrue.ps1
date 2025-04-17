<#
    .SYNOPSIS
        Validates that ReFs is supplied when attempting to format a volume as a Dev Drive.

    .PARAMETER FSFormat
        Specifies the file system format of the new volume.
#>
function Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FSFormat
    )

    if ($FSFormat -ne 'ReFS')
    {
        New-InvalidArgumentException `
            -Message $($script:localizedData.FSFormatNotReFSWhenDevDriveFlagIsTrueError -f 'ReFS', $FSFormat) `
            -ArgumentName 'FSFormat'
    }

}
