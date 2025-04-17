<#
    .SYNOPSIS
        Returns C# code that will be used to call Dev Drive related Win32 apis
#>
function Get-VirtDiskWin32HelperScript
{
    [CmdletBinding()]
    [OutputType([System.Void])]
    param
    ()

    $virtDiskDefinitions = @'

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
            public UInt32 Version;
            public Guid UniqueId;
            public UInt64 MaximumSize;
            public UInt32 BlockSizeInBytes;
            public UInt32 SectorSizeInBytes;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string ParentPath;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string SourcePath;
        }

        // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ns-virtdisk-attach_virtual_disk_parameters
        [StructLayout(LayoutKind.Sequential)]
        public struct ATTACH_VIRTUAL_DISK_PARAMETERS
        {
            public UInt32 Version;
            public UInt32 Reserved;
        }

        // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ns-virtdisk-open_virtual_disk_parameters
        [StructLayout(LayoutKind.Sequential)]
        public struct OPEN_VIRTUAL_DISK_PARAMETERS
        {
            public UInt32 Version;
            public UInt32 RWDepth;
        }

        // Define structures and constants for creating a virtual disk.
        // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-create_virtual_disk_version
        public static uint CREATE_VIRTUAL_DISK_VERSION_2 = 2;

        // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-virtual_disk_access_mask-r1
        public static uint VIRTUAL_DISK_ACCESS_NONE = 0;
        public static uint VIRTUAL_DISK_ACCESS_ALL = 0x003f0000;

        // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-create_virtual_disk_flag
        public static uint CREATE_VIRTUAL_DISK_FLAG_NONE = 0x0;
        public static uint CREATE_VIRTUAL_DISK_FLAG_FULL_PHYSICAL_ALLOCATION = 0x1;

        // Define structures and constants for attaching a virtual disk.
        // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-attach_virtual_disk_flag
        public static uint ATTACH_VIRTUAL_DISK_FLAG_PERMANENT_LIFETIME = 0x00000004;
        public static uint ATTACH_VIRTUAL_DISK_FLAG_AT_BOOT            = 0x00000400;


        // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-attach_virtual_disk_version
        public static uint ATTACH_VIRTUAL_DISK_VERSION_1 = 1;

        // Define structures and constants for opening a virtual disk.
        // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-open_virtual_disk_version
        public static uint OPEN_VIRTUAL_DISK_VERSION_1 = 1;

        // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/ne-virtdisk-open_virtual_disk_flag
        public static uint OPEN_VIRTUAL_DISK_FLAG_NONE = 0x0;

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
            UInt32 VirtualDiskAccessMask,
            IntPtr SecurityDescriptor,
            UInt32 Flags,
            UInt32 ProviderSpecificFlags,
            ref CREATE_VIRTUAL_DISK_PARAMETERS Parameters,
            IntPtr Overlapped,
            out SafeFileHandle Handle
        );

        // Declare method to attach a virtual disk
        // https://learn.microsoft.com/en-us/windows/win32/api/virtdisk/nf-virtdisk-attachvirtualdisk
        [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
        public static extern Int32 AttachVirtualDisk(
            SafeFileHandle VirtualDiskHandle,
            IntPtr SecurityDescriptor,
            UInt32 Flags,
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
            UInt32 VirtualDiskAccessMask,
            UInt32 Flags,
            ref OPEN_VIRTUAL_DISK_PARAMETERS Parameters,
            out SafeFileHandle Handle
        );
'@
    if (([System.Management.Automation.PSTypeName]'VirtDisk.Helper').Type)
    {
        $script:VirtDiskHelper = ([System.Management.Automation.PSTypeName]'VirtDisk.Helper').Type
    }
    else
    {
        $script:VirtDiskHelper = Add-Type `
            -Namespace 'VirtDisk' `
            -Name 'Helper' `
            -MemberDefinition $virtDiskDefinitions `
            -UsingNamespace `
            'System.ComponentModel',
        'Microsoft.Win32.SafeHandles'
    }

    return $script:VirtDiskHelper
}
