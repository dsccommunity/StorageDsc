<#
.SYNOPSIS
    Invokes the wrapper for the DeviceIoControl Win32 API function.

.PARAMETER VolumeGuidPath
    The guid path of the volume that will be queried.
#>
function Invoke-DeviceIoControlWrapperForDevDriveQuery
{
    [CmdletBinding()]
    [OutputType([System.boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VolumeGuidPath
    )

    $devDriveHelper = Get-DevDriveWin32HelperScript

    return $devDriveHelper::DeviceIoControlWrapperForDevDriveQuery($VolumeGuidPath)

}
