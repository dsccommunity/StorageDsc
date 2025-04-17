<#
    .SYNOPSIS
        Validates that a volume is a Dev Drive volume. This is temporary until a way to do
        this is added to the Storage Powershell library to query whether the volume is a Dev Drive volume
        or not.

    .PARAMETER VolumeGuidPath
        The guid path of the volume that will be queried.
#>
function Test-DevDriveVolume
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VolumeGuidPath
    )

    $devDriveHelper = Get-DevDriveWin32HelperScript

    return Invoke-DeviceIoControlWrapperForDevDriveQuery -VolumeGuidPath $VolumeGuidPath
}
