<#
    .SYNOPSIS
        Creates a new virtual disk.

    .DESCRIPTION
        Calls the CreateVirtualDisk Win32 api to create a new virtual disk.
        This is used so we can mock this call easier.

    .PARAMETER VirtualStorageType
        Specifies the type and provider (vendor) of the virtual storage device.

    .PARAMETER VirtualDiskPath
        Specifies the whole path to the virtual disk file.

    .PARAMETER AccessMask
        Specifies the bitmask for specifying access rights to a virtual hard disk.

    .PARAMETER SecurityDescriptor
        Specifies the security information associated with the virtual disk.

    .PARAMETER Flags
        Specifies creation flags for the virtual disk.

    .PARAMETER ProviderSpecificFlags
        Specifies flags specific to the type of virtual disk being created.

    .PARAMETER CreateVirtualDiskParameters
        Specifies the virtual hard disk creation parameters, providing control over,
        and information about, the newly created virtual disk.

    .PARAMETER Overlapped
        Specifies the reference to an overlapped structure for asynchronous calls.

    .PARAMETER Handle
        Specifies the reference to handle object that represents the newly created virtual disk.
#>
function New-VirtualDiskUsingWin32
{
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ref]
        $VirtualStorageType,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ -not (Test-Path $_) })]
        [System.String]
        $VirtualDiskPath,

        [Parameter(Mandatory = $true)]
        [UInt32]
        $AccessMask,

        [Parameter(Mandatory = $true)]
        [System.IntPtr]
        $SecurityDescriptor,

        [Parameter(Mandatory = $true)]
        [UInt32]
        $Flags,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $ProviderSpecificFlags,

        [Parameter(Mandatory = $true)]
        [ref]
        $CreateVirtualDiskParameters,

        [Parameter(Mandatory = $true)]
        [System.IntPtr]
        $Overlapped,

        [Parameter(Mandatory = $true)]
        [ref]
        $Handle
    )

    $helper = Get-VirtDiskWin32HelperScript

    return $helper::CreateVirtualDisk(
        $virtualStorageType,
        $VirtualDiskPath,
        $AccessMask,
        $SecurityDescriptor,
        $Flags,
        $ProviderSpecificFlags,
        $CreateVirtualDiskParameters,
        $Overlapped,
        $Handle)
}
