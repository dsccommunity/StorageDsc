<#
    .SYNOPSIS
        Mounts an existing virtual disk to the system.

    .DESCRIPTION
        Calls the AttachVirtualDisk Win32 api to mount an existing virtual disk
        to the system. This is used so we can mock this call easier.

    .PARAMETER Handle
        Specifies the reference to a handle to a virtual disk file.

    .PARAMETER SecurityDescriptor
        Specifies the security information associated with the virtual disk.

    .PARAMETER Flags
        Specifies attachment flags for the virtual disk.

    .PARAMETER ProviderSpecificFlags
        Specifies flags specific to the type of virtual disk being created.

    .PARAMETER AttachVirtualDiskParameters
        Specifies the virtual hard disk attach request parameters.

    .PARAMETER Overlapped
        Specifies the reference to an overlapped structure for asynchronous calls.

#>
function Add-VirtualDiskUsingWin32
{
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ref]
        $Handle,

        [Parameter(Mandatory = $true)]
        [System.IntPtr]
        $SecurityDescriptor,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Flags,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $ProviderSpecificFlags,

        [Parameter(Mandatory = $true)]
        [ref]
        $AttachVirtualDiskParameters,

        [Parameter(Mandatory = $true)]
        [System.IntPtr]
        $Overlapped
    )

    $helper = Get-VirtDiskWin32HelperScript

    return $helper::AttachVirtualDisk(
        $Handle.Value,
        $SecurityDescriptor,
        $Flags,
        $ProviderSpecificFlags,
        $AttachVirtualDiskParameters,
        $Overlapped)
}
