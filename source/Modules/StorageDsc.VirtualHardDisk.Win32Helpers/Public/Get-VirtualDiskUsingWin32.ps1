<#
    .SYNOPSIS
        Opens an existing virtual disk.

    .DESCRIPTION
        Calls the OpenVirtualDisk Win32 api to open an existing virtual disk.
        This is used so we can mock this call easier.

    .PARAMETER VirtualStorageType
        Specifies the type and provider (vendor) of the virtual storage device.

    .PARAMETER VirtualDiskPath
        Specifies the whole path to the virtual disk file.

    .PARAMETER AccessMask
        Specifies the bitmask for specifying access rights to a virtual hard disk.

    .PARAMETER Flags
        Specifies Open virtual disk flags for the virtual disk.

    .PARAMETER CreateVirtualDiskParameters
        Specifies the virtual hard disk open request parameters.

    .PARAMETER Handle
        Specifies the reference to handle object that represents the a virtual disk file.
#>
function Get-VirtualDiskUsingWin32
{
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ref]
        $VirtualStorageType,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [System.String]
        $VirtualDiskPath,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $AccessMask,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Flags,

        [Parameter(Mandatory = $true)]
        [ref]
        $OpenVirtualDiskParameters,

        [Parameter(Mandatory = $true)]
        [ref]
        $Handle
    )

    $helper = Get-VirtDiskWin32HelperScript

    return $helper::OpenVirtualDisk(
        $VirtualStorageType,
        $VirtualDiskPath,
        $AccessMask,
        $Flags,
        $OpenVirtualDiskParameters,
        $Handle)
}
