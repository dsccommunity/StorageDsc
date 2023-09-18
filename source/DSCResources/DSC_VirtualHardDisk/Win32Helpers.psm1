$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

# Import virtdisk.dll and define structures and constants
Add-Type -TypeDefinition @'
    using System;
    using System.Runtime.InteropServices;

    namespace Win32
    {
        namespace VirtDisk
        {
            // Define structures and constants for creating a virtual disk.
            // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-create_virtual_disk_version
            public enum CREATE_VIRTUAL_DISK_VERSION
            {
                CREATE_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
                CREATE_VIRTUAL_DISK_VERSION_1 = 1,
                CREATE_VIRTUAL_DISK_VERSION_2 = 2,
            }

            // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ns-virtdisk-virtual_storage_type
            [StructLayout(LayoutKind.Sequential)]
            public struct VIRTUAL_STORAGE_TYPE
            {
                public UInt32 DeviceId;
                public Guid VendorId;
            }

            // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ns-virtdisk-create_virtual_disk_parameters
            [StructLayout(LayoutKind.Sequential)]
            public struct CREATE_VIRTUAL_DISK_PARAMETERS
            {
                public CREATE_VIRTUAL_DISK_VERSION Version;
                public Guid UniqueId;
                public UInt64 MaximumSize;
                public UInt32 BlockSizeInBytes;
                public UInt32 SectorSizeInBytes;
                [MarshalAs(UnmanagedType.LPWStr)]
                public string ParentPath;
                [MarshalAs(UnmanagedType.LPWStr)]
                public string SourcePath;
            }

            // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-virtual_disk_access_mask-r1
            public enum VIRTUAL_DISK_ACCESS_MASK
            {
                VIRTUAL_DISK_ACCESS_NONE = 0,
                VIRTUAL_DISK_ACCESS_ATTACH_RO = 0x00010000,
                VIRTUAL_DISK_ACCESS_ATTACH_RW = 0x00020000,
                VIRTUAL_DISK_ACCESS_DETACH = 0x00040000,
                VIRTUAL_DISK_ACCESS_GET_INFO = 0x00080000,
                VIRTUAL_DISK_ACCESS_CREATE = 0x00100000,
                VIRTUAL_DISK_ACCESS_METAOPS = 0x00200000,
                VIRTUAL_DISK_ACCESS_READ = 0x000d0000,
                VIRTUAL_DISK_ACCESS_ALL = 0x003f0000,
                VIRTUAL_DISK_ACCESS_WRITABLE = 0x00320000
            }

            // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-create_virtual_disk_flag
            public enum CREATE_VIRTUAL_DISK_FLAG
            {
                CREATE_VIRTUAL_DISK_FLAG_NONE = 0x0,
                CREATE_VIRTUAL_DISK_FLAG_FULL_PHYSICAL_ALLOCATION = 0x1,
            }

            // Define structures and constants for attaching a virtual disk.
            // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-attach_virtual_disk_flag
            public enum ATTACH_VIRTUAL_DISK_FLAG
            {
                ATTACH_VIRTUAL_DISK_FLAG_NONE                               = 0x00000000,
                ATTACH_VIRTUAL_DISK_FLAG_READ_ONLY                          = 0x00000001,
                ATTACH_VIRTUAL_DISK_FLAG_NO_DRIVE_LETTER                    = 0x00000002,
                ATTACH_VIRTUAL_DISK_FLAG_PERMANENT_LIFETIME                 = 0x00000004,
                ATTACH_VIRTUAL_DISK_FLAG_NO_LOCAL_HOST                      = 0x00000008,
                ATTACH_VIRTUAL_DISK_FLAG_NO_SECURITY_DESCRIPTOR             = 0x00000010,
                ATTACH_VIRTUAL_DISK_FLAG_BYPASS_DEFAULT_ENCRYPTION_POLICY   = 0x00000020,
                ATTACH_VIRTUAL_DISK_FLAG_NON_PNP                            = 0x00000040,
                ATTACH_VIRTUAL_DISK_FLAG_RESTRICTED_RANGE                   = 0x00000080,
                ATTACH_VIRTUAL_DISK_FLAG_SINGLE_PARTITION                   = 0x00000100,
                ATTACH_VIRTUAL_DISK_FLAG_REGISTER_VOLUME                    = 0x00000200,
                ATTACH_VIRTUAL_DISK_FLAG_AT_BOOT                            = 0x00000400,
            }

            // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-attach_virtual_disk_version
            public enum ATTACH_VIRTUAL_DISK_VERSION
            {
                ATTACH_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
                ATTACH_VIRTUAL_DISK_VERSION_1 = 1,
            }

            // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ns-virtdisk-attach_virtual_disk_parameters
            [StructLayout(LayoutKind.Sequential)]
            public struct ATTACH_VIRTUAL_DISK_PARAMETERS
            {
                public ATTACH_VIRTUAL_DISK_VERSION Version;
                public UInt32 Reserved;
            }

            // Define structures and constants for opening a virtual disk.
            // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-open_virtual_disk_version
            public enum OPEN_VIRTUAL_DISK_VERSION
            {
                OPEN_VIRTUAL_DISK_VERSION_UNSPECIFIED = 0,
                OPEN_VIRTUAL_DISK_VERSION_1 = 1,
                OPEN_VIRTUAL_DISK_VERSION_2 = 2,
            }

            // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ns-virtdisk-open_virtual_disk_parameters
            [StructLayout(LayoutKind.Sequential)]
            public struct OPEN_VIRTUAL_DISK_PARAMETERS
            {
                public OPEN_VIRTUAL_DISK_VERSION Version;
                public UInt32 RWDepth;
            }

            // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-open_virtual_disk_flag
            public enum OPEN_VIRTUAL_DISK_FLAG
            {
                OPEN_VIRTUAL_DISK_FLAG_NONE = 0x0,
                OPEN_VIRTUAL_DISK_FLAG_NO_PARENTS = 0x1,
                OPEN_VIRTUAL_DISK_FLAG_BLANK_FILE = 0x2,
                OPEN_VIRTUAL_DISK_FLAG_BOOT_DRIVE = 0x4,
            }

            public class VirtDiskHelper
            {
                // Constants found in virtdisk.h
                // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ns-virtdisk-virtual_storage_type
                public static uint VIRTUAL_STORAGE_TYPE_DEVICE_VHD  = 2U;
                public static uint VIRTUAL_STORAGE_TYPE_DEVICE_VHDX = 3U;
                public static Guid VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT = new Guid(0xEC984AEC, 0xA0F9, 0x47E9, 0x90, 0x1F, 0x71, 0x41, 0x5A, 0x66, 0x34, 0x5B);

                // Declare method to create a virtual disk
                // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/nf-virtdisk-createvirtualdisk
                [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
                public static extern Int32 CreateVirtualDisk(
                    ref VIRTUAL_STORAGE_TYPE VirtualStorageType,
                    string Path,
                    VIRTUAL_DISK_ACCESS_MASK VirtualDiskAccessMask,
                    IntPtr SecurityDescriptor,
                    CREATE_VIRTUAL_DISK_FLAG Flags,
                    UInt32 ProviderSpecificFlags,
                    ref CREATE_VIRTUAL_DISK_PARAMETERS Parameters,
                    IntPtr Overlapped,
                    ref IntPtr Handle
                );

                // Declare method to attach a virtual disk
                // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/nf-virtdisk-attachvirtualdisk
                [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
                public static extern Int32 AttachVirtualDisk(
                    IntPtr VirtualDiskHandle,
                    IntPtr SecurityDescriptor,
                    ATTACH_VIRTUAL_DISK_FLAG Flags,
                    UInt32 ProviderSpecificFlags,
                    ref ATTACH_VIRTUAL_DISK_PARAMETERS Parameters,
                    IntPtr Overlapped
                );

                // Declare function to open a handle to a virtual disk
                // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/nf-virtdisk-openvirtualdisk
                [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
                public static extern Int32 OpenVirtualDisk(
                    ref VIRTUAL_STORAGE_TYPE VirtualStorageType,
                    string Path,
                    VIRTUAL_DISK_ACCESS_MASK VirtualDiskAccessMask,
                    OPEN_VIRTUAL_DISK_FLAG Flags,
                    ref OPEN_VIRTUAL_DISK_PARAMETERS Parameters,
                    ref IntPtr Handle
                );
            }
        }

        public class Kernel32
        {
            // https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-closehandle
            [DllImport("kernel32.dll", SetLastError = true)]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool CloseHandle(IntPtr hObject);
        }
    }

'@

<#
    .SYNOPSIS
        Creates and attaches a virtual disk to the system.

    .PARAMETER VirtualDiskPath
        Specifies the whole path to the virtual disk including the file name.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format.

    .PARAMETER DiskType
        Specifies the supported virtual disk type.

    .PARAMETER DiskSizeInBytes
        Specifies the size of new virtual disk in bytes.
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
        [ValidateSet('vhd', 'vhdx')]
        [System.String]
        $DiskFormat,

        [Parameter(Mandatory = $true)]
        [ValidateSet('fixed', 'dynamic')]
        [System.String]
        $DiskType
    )
    try
    {
        Write-Verbose -Message ($script:localizedData.CreatingVirtualDiskMessage -f $VirtualDiskPath)
        $vDiskHelper = New-Object Win32.VirtDisk.VirtDiskHelper

        # Get parameters for CreateVirtualDisk function
        $virtualStorageType =  Get-VirtualStorageType -DiskFormat $DiskFormat
        $createVirtualDiskParameters = New-Object Win32.VirtDisk.CREATE_VIRTUAL_DISK_PARAMETERS
        $createVirtualDiskParameters.Version = [Win32.VirtDisk.CREATE_VIRTUAL_DISK_VERSION]::CREATE_VIRTUAL_DISK_VERSION_2
        $createVirtualDiskParameters.MaximumSize = $DiskSizeInBytes
        $securityDescriptor = [System.IntPtr]::Zero
        $accessMask = [Win32.VirtDisk.VIRTUAL_DISK_ACCESS_MASK]::VIRTUAL_DISK_ACCESS_NONE # Access mask
        $providerSpecificFlags = 0 # No Provider-specific flags.
        $handle = [System.IntPtr]::Zero # Handle to the new virtual disk

        # Virtual disk will be dynamically expanding, up to the size of $DiskSizeInBytes on the parent disk
        $flags = [Win32.VirtDisk.CREATE_VIRTUAL_DISK_FLAG]::CREATE_VIRTUAL_DISK_FLAG_NONE
        if ($DiskType -eq 'fixed')
        {
            # Virtual disk will be fixed, and will take up the up the full size of $DiskSizeInBytes on the parent disk after creation
            $flags = [Win32.VirtDisk.CREATE_VIRTUAL_DISK_FLAG]::CREATE_VIRTUAL_DISK_FLAG_FULL_PHYSICAL_ALLOCATION
        }

        $result = $vDiskHelper::CreateVirtualDisk(
            [ref]$virtualStorageType,
            $VirtualDiskPath,
            $accessMask,
            $securityDescriptor,
            $flags,
            $providerSpecificFlags,
            [ref]$createVirtualDiskParameters,
            [System.IntPtr]::Zero,
            [ref]$handle)

        if ($result -ne 0)
        {
            Write-Error -Message ($script:localizedData.CreateVirtualDiskError -f $result)
            throw [System.ComponentModel.Win32Exception]::new($result);
        }

        Write-Verbose -Message ($script:localizedData.VirtualDiskCreatedSuccessfully -f $VirtualDiskPath)
        Add-SimpleVirtualDisk -VirtualDiskPath $VirtualDiskPath -DiskFormat $DiskFormat -Handle $handle
    }
    catch
    {
        # Remove file if we created it but were unable to attach it. No handles are open when this happens.
        if (Test-Path -Path $VirtualDiskPath -PathType Leaf)
        {
            Write-Verbose -Message ($script:localizedData.VirtualRemovingCreatedFileMessage -f $VirtualDiskPath)
            Remove-Item $VirtualDiskPath -verbose
        }

        throw
    }
    finally
    {
        # Close handle
        $null = [Win32.Kernel32]::CloseHandle($handle)
    }
} # function New-VirtualDisk

<#
    .SYNOPSIS
        Attaches a virtual disk to the system.

    .PARAMETER VirtualDiskPath
        Specifies the whole path to the virtual disk including the file name.

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
        [ValidateSet('vhd', 'vhdx')]
        [System.String]
        $DiskFormat,

        [Parameter()]
        [System.IntPtr]
        $Handle = [System.IntPtr]::Zero
    )
    try
    {
        Write-Verbose -Message ($script:localizedData.AttachingVirtualDiskMessage -f $VirtualDiskPath)
        $vDiskHelper = New-Object Win32.VirtDisk.VirtDiskHelper

        # No handle passed in so we need to open the virtual disk first using $virtualDiskPath to get the handle.
        if ($Handle -eq [System.IntPtr]::Zero)
        {
            $Handle = Get-VirtualDiskHandle -VirtualDiskPath $VirtualDiskPath -DiskFormat $DiskFormat
        }

        # Build parameters for AttachVirtualDisk function
        $attachVirtualDiskParameters = New-Object Win32.VirtDisk.ATTACH_VIRTUAL_DISK_PARAMETERS
        $attachVirtualDiskParameters.Version = [Win32.VirtDisk.ATTACH_VIRTUAL_DISK_VERSION]::ATTACH_VIRTUAL_DISK_VERSION_1
        $securityDescriptor = [System.IntPtr]::Zero # Security descriptor
        $providerSpecificFlags = 0 # No Provider-specific flag
        $result = 0

        # Some builds of Windows may not have the ATTACH_VIRTUAL_DISK_FLAG_AT_BOOT flag. So we attempt to attach the virtual
        # disk with the flag first. If this fails we attach the virtual disk without the flag. The flag allows the
        # virtual disk to be attached by the system at boot time.
        for ($attempts = 0; $attempts -lt 2; $attempts++)
        {
            if ($attempts -eq 0)
            {
                $flags = [Win32.VirtDisk.ATTACH_VIRTUAL_DISK_FLAG]::ATTACH_VIRTUAL_DISK_FLAG_PERMANENT_LIFETIME -bor
                    [Win32.VirtDisk.ATTACH_VIRTUAL_DISK_FLAG]::ATTACH_VIRTUAL_DISK_FLAG_AT_BOOT
            }
            else
            {
                $flags = [Win32.VirtDisk.ATTACH_VIRTUAL_DISK_FLAG]::ATTACH_VIRTUAL_DISK_FLAG_PERMANENT_LIFETIME
            }

            $result = $vDiskHelper::AttachVirtualDisk(
                $Handle,
                $securityDescriptor,
                $flags,
                $providerSpecificFlags,
                [ref]$attachVirtualDiskParameters,
                [System.IntPtr]::Zero)

            if ($result -eq 0)
            {
                break
            }
        }

        if ($result -ne 0)
        {
            Write-Error -Message ($script:localizedData.AttachVirtualDiskError -f $result)
            throw [System.ComponentModel.Win32Exception]::new($result);
        }

        Write-Verbose -Message ($script:localizedData.VirtualDiskAttachedSuccessfully -f $VirtualDiskPath)
    }
    finally
    {
        # Close handle
        $null = [Win32.Kernel32]::CloseHandle($Handle)
    }

} # function Add-SimpleVirtualDisk

<#
    .SYNOPSIS
        Opens a handle to a virtual disk on the system.

    .PARAMETER VirtualDiskPath
        Specifies the whole path to the virtual disk including the file name.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format.
#>
function Get-VirtualDiskHandle
{
    [CmdletBinding()]
    [OutputType([System.IntPtr])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VirtualDiskPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('vhd', 'vhdx')]
        [System.String]
        $DiskFormat
    )

    Write-Verbose -Message ($script:localizedData.OpeningVirtualBeforeAttachingMessage)
    $vDiskHelper = New-Object Win32.VirtDisk.VirtDiskHelper

    # Get parameters for OpenVirtualDisk function
    $virtualStorageType =  Get-VirtualStorageType -DiskFormat $DiskFormat
    $openVirtualDiskParameters = New-Object Win32.VirtDisk.OPEN_VIRTUAL_DISK_PARAMETERS
    $openVirtualDiskParameters.Version = [Win32.VirtDisk.OPEN_VIRTUAL_DISK_VERSION]::OPEN_VIRTUAL_DISK_VERSION_1
    $accessMask = [Win32.VirtDisk.VIRTUAL_DISK_ACCESS_MASK]::VIRTUAL_DISK_ACCESS_ALL
    $flags = [Win32.VirtDisk.OPEN_VIRTUAL_DISK_FLAG]::OPEN_VIRTUAL_DISK_FLAG_NONE
    $handle = [System.IntPtr]::Zero

    $result = $vDiskHelper::OpenVirtualDisk(
        [ref]$virtualStorageType,
        $VirtualDiskPath,
        $accessMask,
        $flags,
        [ref]$openVirtualDiskParameters,
        [ref]$handle)

    if ($result -ne 0)
    {
        Write-Error -Message ($script:localizedData.OpenVirtualDiskError -f $result)
        throw [System.ComponentModel.Win32Exception]::new($result);
    }

    Write-Verbose -Message ($script:localizedData.VirtualDiskOpenedSuccessfully -f $VirtualDiskPath)

    return $handle
} # function Get-VirtualDiskHandle

<#
    .SYNOPSIS
        Gets the storage type based on the disk format.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format.
#>
function Get-VirtualStorageType
{
    [CmdletBinding()]
    [OutputType([Win32.VirtDisk.VIRTUAL_STORAGE_TYPE])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('vhd', 'vhdx')]
        [System.String]
        $DiskFormat
    )

    # Create VIRTUAL_STORAGE_TYPE structure
    $virtualStorageType = New-Object Win32.VirtDisk.VIRTUAL_STORAGE_TYPE

    # Default to the vhdx file format.
    $virtualStorageType.VendorId = [Win32.VirtDisk.VirtDiskHelper]::VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT
    $virtualStorageType.DeviceId = [Win32.VirtDisk.VirtDiskHelper]::VIRTUAL_STORAGE_TYPE_DEVICE_VHDX
    if ($DiskFormat -eq 'vhd')
    {
        $virtualStorageType.VendorId = [Win32.VirtDisk.VirtDiskHelper]::VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT
        $virtualStorageType.DeviceId = [Win32.VirtDisk.VirtDiskHelper]::VIRTUAL_STORAGE_TYPE_DEVICE_VHD
    }

    return $virtualStorageType
} # function Get-VirtualStorageType

Export-ModuleMember -Function @(
    'New-SimpleVirtualDisk',
    'Add-SimpleVirtualDisk'
)
