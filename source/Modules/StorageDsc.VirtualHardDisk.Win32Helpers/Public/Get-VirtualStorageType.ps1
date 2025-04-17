<#
    .SYNOPSIS
        Gets the storage type based on the disk format.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format.
#>
function Get-VirtualStorageType
{
    [CmdletBinding()]
    [OutputType([VirtDisk.Helper+VIRTUAL_STORAGE_TYPE])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Vhd', 'Vhdx')]
        [System.String]
        $DiskFormat
    )

    # Create VIRTUAL_STORAGE_TYPE structure.
    $virtualStorageType = New-Object -TypeName VirtDisk.Helper+VIRTUAL_STORAGE_TYPE

    # Default to the vhdx file format.
    $virtualStorageType.VendorId = [VirtDisk.Helper]::VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT
    $virtualStorageType.DeviceId = [VirtDisk.Helper]::VIRTUAL_STORAGE_TYPE_DEVICE_VHDX

    if ($DiskFormat -eq 'Vhd')
    {
        $virtualStorageType.DeviceId = [VirtDisk.Helper]::VIRTUAL_STORAGE_TYPE_DEVICE_VHD
    }

    return $virtualStorageType
}
