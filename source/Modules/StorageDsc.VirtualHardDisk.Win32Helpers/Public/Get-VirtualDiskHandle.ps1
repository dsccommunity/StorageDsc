<#
    .SYNOPSIS
        Opens a handle to a virtual disk on the system.

    .PARAMETER VirtualDiskPath
        Specifies the whole path to the virtual disk file.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format.
#>
function Get-VirtualDiskHandle
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VirtualDiskPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Vhd', 'Vhdx')]
        [System.String]
        $DiskFormat
    )

    Write-Verbose -Message ($script:localizedData.OpeningVirtualBeforeMountingMessage)
    $vDiskHelper = Get-VirtDiskWin32HelperScript

    # Get parameters for OpenVirtualDisk function.
    [ref]$virtualStorageType = Get-VirtualStorageType -DiskFormat $DiskFormat
    [ref]$openVirtualDiskParameters = New-Object -TypeName VirtDisk.Helper+OPEN_VIRTUAL_DISK_PARAMETERS
    $openVirtualDiskParameters.Value.Version = [VirtDisk.Helper]::OPEN_VIRTUAL_DISK_VERSION_1
    $accessMask = [VirtDisk.Helper]::VIRTUAL_DISK_ACCESS_ALL
    $flags = [VirtDisk.Helper]::OPEN_VIRTUAL_DISK_FLAG_NONE

    # Handle to the virtual disk.
    [ref]$handle = [Microsoft.Win32.SafeHandles.SafeFileHandle]::Zero

    $result = Get-VirtualDiskUsingWin32 `
        -VirtualStorageType $virtualStorageType `
        -VirtualDiskPath $VirtualDiskPath `
        -AccessMask $accessMask `
        -Flags $flags `
        -OpenVirtualDiskParameters $openVirtualDiskParameters `
        -Handle $handle

    if ($result -ne 0)
    {
        $win32Error = [System.ComponentModel.Win32Exception]::new($result)
        throw [System.Exception]::new( `
            ($script:localizedData.OpenVirtualDiskError -f $VirtualDiskPath, $win32Error.Message), `
                $win32Error)
    }

    Write-Verbose -Message ($script:localizedData.VirtualDiskOpenedSuccessfully -f $VirtualDiskPath)

    return $handle
}
