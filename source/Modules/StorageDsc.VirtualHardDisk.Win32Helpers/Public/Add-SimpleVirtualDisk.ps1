<#
    .SYNOPSIS
        Mounts a virtual disk to the system.

    .PARAMETER VirtualDiskPath
        Specifies the whole path to the virtual disk file.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format.

    .PARAMETER Handle
        Specifies a reference to a win32 handle that points to a virtual disk
#>
function Add-SimpleVirtualDisk
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
        $DiskFormat,

        [Parameter()]
        [ref]
        $Handle
    )
    try
    {
        Write-Verbose -Message ($script:localizedData.MountingVirtualDiskMessage -f $VirtualDiskPath)

        $vDiskHelper = Get-VirtDiskWin32HelperScript

        # No handle passed in so we need to open the virtual disk first using $virtualDiskPath to get the handle.
        if ($null -eq $Handle)
        {
            $Handle = Get-VirtualDiskHandle -VirtualDiskPath $VirtualDiskPath -DiskFormat $DiskFormat
        }

        # Build parameters for AttachVirtualDisk function.
        [ref]$attachVirtualDiskParameters = New-Object -TypeName VirtDisk.Helper+ATTACH_VIRTUAL_DISK_PARAMETERS
        $attachVirtualDiskParameters.Value.Version = [VirtDisk.Helper]::ATTACH_VIRTUAL_DISK_VERSION_1
        $securityDescriptor = [System.IntPtr]::Zero
        $providerSpecificFlags = 0
        $result = 0

        <#
            Some builds of Windows may not have the ATTACH_VIRTUAL_DISK_FLAG_AT_BOOT flag. So we attempt to mount the virtual
            disk with the flag first. If this fails we mount the virtual disk without the flag. The flag allows the
            virtual disk to be auto-mounted by the system at boot time.
        #>
        $combinedFlags = [VirtDisk.Helper]::ATTACH_VIRTUAL_DISK_FLAG_PERMANENT_LIFETIME -bor [VirtDisk.Helper]::ATTACH_VIRTUAL_DISK_FLAG_AT_BOOT
        $attemptFlagValues = @($combinedFlags, [VirtDisk.Helper]::ATTACH_VIRTUAL_DISK_FLAG_PERMANENT_LIFETIME)

        foreach ($flags in $attemptFlagValues)
        {
            $result = Add-VirtualDiskUsingWin32 `
                -Handle $Handle `
                -SecurityDescriptor $securityDescriptor `
                -Flags $flags `
                -ProviderSpecificFlags $providerSpecificFlags `
                -AttachVirtualDiskParameters $attachVirtualDiskParameters `
                -Overlapped ([System.IntPtr]::Zero)

            if ($result -eq 0)
            {
                break
            }
        }

        if ($result -ne 0)
        {
            $win32Error = [System.ComponentModel.Win32Exception]::new($result)
            throw [System.Exception]::new( `
                ($script:localizedData.MountVirtualDiskError -f $VirtualDiskPath, $win32Error.Message), `
                    $win32Error)
        }

        Write-Verbose -Message ($script:localizedData.VirtualDiskMountedSuccessfully -f $VirtualDiskPath)
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
