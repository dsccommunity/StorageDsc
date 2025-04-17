<#
    .SYNOPSIS
        Creates and mounts a virtual disk to the system.

    .PARAMETER VirtualDiskPath
        Specifies the whole path to the virtual disk file.

    .PARAMETER DiskSizeInBytes
        Specifies the size of new virtual disk in bytes.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format.

    .PARAMETER DiskType
        Specifies the supported virtual disk type.
#>
function New-SimpleVirtualDisk
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VirtualDiskPath,

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $DiskSizeInBytes,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Vhd', 'Vhdx')]
        [System.String]
        $DiskFormat,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Fixed', 'Dynamic')]
        [System.String]
        $DiskType
    )

    Write-Verbose -Message ($script:localizedData.CreatingVirtualDiskMessage -f $VirtualDiskPath)
    $vDiskHelper = Get-VirtDiskWin32HelperScript

    # Get parameters for CreateVirtualDisk function
    [ref]$virtualStorageType = Get-VirtualStorageType -DiskFormat $DiskFormat
    [ref]$createVirtualDiskParameters = New-Object -TypeName VirtDisk.Helper+CREATE_VIRTUAL_DISK_PARAMETERS
    $createVirtualDiskParameters.Value.Version = [VirtDisk.Helper]::CREATE_VIRTUAL_DISK_VERSION_2
    $createVirtualDiskParameters.Value.MaximumSize = $DiskSizeInBytes
    $securityDescriptor = [System.IntPtr]::Zero
    $accessMask = [VirtDisk.Helper]::VIRTUAL_DISK_ACCESS_NONE
    $providerSpecificFlags = 0

    # Handle to the new virtual disk
    [ref]$handle = [Microsoft.Win32.SafeHandles.SafeFileHandle]::Zero

    # Virtual disk will be dynamically expanding, up to the size of $DiskSizeInBytes on the parent disk
    $flags = [VirtDisk.Helper]::CREATE_VIRTUAL_DISK_FLAG_NONE

    if ($DiskType -eq 'Fixed')
    {
        # Virtual disk will be fixed, and will take up the up the full size of $DiskSizeInBytes on the parent disk after creation
        $flags = [VirtDisk.Helper]::CREATE_VIRTUAL_DISK_FLAG_FULL_PHYSICAL_ALLOCATION
    }

    try
    {
        # create the virtual disk
        $result = New-VirtualDiskUsingWin32 `
            -VirtualStorageType $virtualStorageType `
            -VirtualDiskPath $VirtualDiskPath `
            -AccessMask $accessMask `
            -SecurityDescriptor $securityDescriptor `
            -Flags $flags `
            -ProviderSpecificFlags $providerSpecificFlags `
            -CreateVirtualDiskParameters $createVirtualDiskParameters `
            -Overlapped ([System.IntPtr]::Zero) `
            -Handle $handle

        if ($result -ne 0)
        {
            $win32Error = [System.ComponentModel.Win32Exception]::new($result)
            throw [System.Exception]::new( `
                ($script:localizedData.CreateVirtualDiskError -f $VirtualDiskPath, $win32Error.Message), `
                    $win32Error)
        }

        Write-Verbose -Message ($script:localizedData.VirtualDiskCreatedSuccessfully -f $VirtualDiskPath)

        # Mount the newly created virtual disk
        Add-SimpleVirtualDisk `
            -VirtualDiskPath $VirtualDiskPath `
            -DiskFormat $DiskFormat `
            -Handle $handle
    }
    finally
    {
        # Close handle
        if ($handle.Value)
        {
            $handle.Value.Close()
        }
    }
}
