$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

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

    $virtDiskDefinitions =  @'

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
} # end function Get-VirtDiskWin32HelperScript

<#
    .SYNOPSIS
        Calls Win32 CreateVirtualDisk api. This is used so we can mock this call
        easier.

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
} # end function New-VirtualDiskUsingWin32

<#
    .SYNOPSIS
        Calls Win32 AttachVirtualDisk api. This is used so we can mock this call
        easier.

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
} # end function Add-VirtualDiskUsingWin32

<#
    .SYNOPSIS
        Calls Win32 CloseHandle api. This is used so we can mock this call
        easier.

    .PARAMETER Handle
        Specifies a reference to handle for a file.
#>
function Close-Win32Handle
{
    [CmdletBinding()]
    [OutputType([System.Void])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ref]
        $Handle
    )

    $helper = Get-VirtDiskWin32HelperScript
    if ($Handle.Value)
    {
        $null = $helper::CloseHandle($Handle.value)
    }
} # end function Close-Win32Handle

<#
    .SYNOPSIS
        Calls Win32 OpenVirtualDisk api. This is used so we can mock this call
        easier.

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
} # end function Get-VirtualDiskUsingWin32

<#
    .SYNOPSIS
        Creates and attaches a virtual disk to the system.

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
    [ref]$createVirtualDiskParameters = New-Object VirtDisk.Helper+CREATE_VIRTUAL_DISK_PARAMETERS
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
        $result = New-VirtualDiskUsingWin32 `
            $virtualStorageType `
            $VirtualDiskPath `
            $accessMask `
            $securityDescriptor `
            $flags `
            $providerSpecificFlags `
            $createVirtualDiskParameters `
            ([System.IntPtr]::Zero) `
            $handle

        if ($result -ne 0)
        {
            $win32Error = [System.ComponentModel.Win32Exception]::new($result)
            throw [System.Exception]::new( `
                ($script:localizedData.CreateVirtualDiskError -f $win32Error.Message), `
                $win32Error)
        }

        Write-Verbose -Message ($script:localizedData.VirtualDiskCreatedSuccessfully -f $VirtualDiskPath)
        Add-SimpleVirtualDisk -VirtualDiskPath $VirtualDiskPath -DiskFormat $DiskFormat -Handle $handle
    }
    finally
    {
        # Close handle
        if ($handle.Value)
        {
            $handle.Value.Close()
        }
    }
} # function New-SimpleVirtualDisk

<#
    .SYNOPSIS
        Attaches a virtual disk to the system.

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
        Write-Verbose -Message ($script:localizedData.AttachingVirtualDiskMessage -f $VirtualDiskPath)

        $vDiskHelper = Get-VirtDiskWin32HelperScript

        # No handle passed in so we need to open the virtual disk first using $virtualDiskPath to get the handle.
        if ($null -eq $Handle)
        {
            $Handle = Get-VirtualDiskHandle -VirtualDiskPath $VirtualDiskPath -DiskFormat $DiskFormat
        }

        # Build parameters for AttachVirtualDisk function.
        [ref]$attachVirtualDiskParameters = New-Object VirtDisk.Helper+ATTACH_VIRTUAL_DISK_PARAMETERS
        $attachVirtualDiskParameters.Value.Version = [VirtDisk.Helper]::ATTACH_VIRTUAL_DISK_VERSION_1
        $securityDescriptor = [System.IntPtr]::Zero
        $providerSpecificFlags = 0
        $result = 0

        <#
            Some builds of Windows may not have the ATTACH_VIRTUAL_DISK_FLAG_AT_BOOT flag. So we attempt to attach the virtual
            disk with the flag first. If this fails we attach the virtual disk without the flag. The flag allows the
            virtual disk to be attached by the system at boot time.
        #>
        for ($attempts = 0; $attempts -lt 2; $attempts++)
        {
            if ($attempts -eq 0)
            {
                $flags = [VirtDisk.Helper]::ATTACH_VIRTUAL_DISK_FLAG_PERMANENT_LIFETIME -bor
                    [VirtDisk.Helper]::ATTACH_VIRTUAL_DISK_FLAG_AT_BOOT
            }
            else
            {
                $flags = [VirtDisk.Helper]::ATTACH_VIRTUAL_DISK_FLAG_PERMANENT_LIFETIME
            }

            $result = Add-VirtualDiskUsingWin32 `
                $Handle `
                $securityDescriptor `
                $flags `
                $providerSpecificFlags `
                $attachVirtualDiskParameters `
                ([System.IntPtr]::Zero)

            if ($result -eq 0)
            {
                break
            }
        }

        if ($result -ne 0)
        {
            $win32Error = [System.ComponentModel.Win32Exception]::new($result)
            throw [System.Exception]::new( `
                ($script:localizedData.AttachVirtualDiskError -f $win32Error.Message), `
                $win32Error)
        }

        Write-Verbose -Message ($script:localizedData.VirtualDiskAttachedSuccessfully -f $VirtualDiskPath)
    }
    finally
    {
        # Close handle
        if ($handle.Value)
        {
            $handle.Value.Close()
        }
    }

} # function Add-SimpleVirtualDisk

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

    Write-Verbose -Message ($script:localizedData.OpeningVirtualBeforeAttachingMessage)
    $vDiskHelper = Get-VirtDiskWin32HelperScript

    # Get parameters for OpenVirtualDisk function.
    [ref]$virtualStorageType =  Get-VirtualStorageType -DiskFormat $DiskFormat
    [ref]$openVirtualDiskParameters = New-Object VirtDisk.Helper+OPEN_VIRTUAL_DISK_PARAMETERS
    $openVirtualDiskParameters.Value.Version = [VirtDisk.Helper]::OPEN_VIRTUAL_DISK_VERSION_1
    $accessMask = [VirtDisk.Helper]::VIRTUAL_DISK_ACCESS_ALL
    $flags = [VirtDisk.Helper]::OPEN_VIRTUAL_DISK_FLAG_NONE

    # Handle to the virtual disk.
    [ref]$handle = [Microsoft.Win32.SafeHandles.SafeFileHandle]::Zero

    $result = Get-VirtualDiskUsingWin32 `
        $virtualStorageType `
        $VirtualDiskPath `
        $accessMask `
        $flags `
        $openVirtualDiskParameters `
        $handle

    if ($result -ne 0)
    {
        $win32Error = [System.ComponentModel.Win32Exception]::new($result)
        throw [System.Exception]::new( `
            ($script:localizedData.OpenVirtualDiskError -f $win32Error.Message), `
            $win32Error)
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
} # function Get-VirtualStorageType

Export-ModuleMember -Function @(
    'New-SimpleVirtualDisk',
    'Add-SimpleVirtualDisk',
    'Get-VirtualDiskHandle',
    'Get-VirtualStorageType',
    'Get-VirtDiskWin32HelperScript',
    'New-VirtualDiskUsingWin32',
    'Add-VirtualDiskUsingWin32',
    'Get-VirtualDiskUsingWin32'
)
