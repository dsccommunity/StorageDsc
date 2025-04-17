<#
    .SYNOPSIS
        Returns C# code that will be used to call Dev Drive related Win32 apis.
#>
function Get-DevDriveWin32HelperScript
{
    [OutputType([System.Type])]
    [CmdletBinding()]
    param
    ()

    $DevDriveHelperDefinitions = @'

        // https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/ne-sysinfoapi-developer_drive_enablement_state
        public enum DEVELOPER_DRIVE_ENABLEMENT_STATE
        {
            DeveloperDriveEnablementStateError = 0,
            DeveloperDriveEnabled = 1,
            DeveloperDriveDisabledBySystemPolicy = 2,
            DeveloperDriveDisabledByGroupPolicy = 3,
        }

        // https://learn.microsoft.com/en-us/windows/win32/api/apiquery2/nf-apiquery2-isapisetimplemented
        [DllImport("api-ms-win-core-apiquery-l2-1-0.dll", ExactSpelling = true)]
        [DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
        public static extern bool IsApiSetImplemented(string Contract);

        // https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getdeveloperdriveenablementstate
        [DllImport("api-ms-win-core-sysinfo-l1-2-6.dll")]
        public static extern DEVELOPER_DRIVE_ENABLEMENT_STATE GetDeveloperDriveEnablementState();


        // https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilew
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        public static extern SafeFileHandle CreateFile(
            string lpFileName,
            uint dwDesiredAccess,
            uint dwShareMode,
            IntPtr lpSecurityAttributes,
            uint dwCreationDisposition,
            uint dwFlagsAndAttributes,
            IntPtr hTemplateFile);

        // https://learn.microsoft.com/en-us/windows/win32/api/ioapiset/nf-ioapiset-deviceiocontrol
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool DeviceIoControl(
            SafeFileHandle hDevice,
            uint dwIoControlCode,
            IntPtr lpInBuffer,
            uint nInBufferSize,
            IntPtr lpOutBuffer,
            uint nOutBufferSize,
            out uint lpBytesReturned,
            IntPtr lpOverlapped);

        // https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntifs/ns-ntifs-_file_fs_persistent_volume_information
        [StructLayout(LayoutKind.Sequential)]
        public struct FILE_FS_PERSISTENT_VOLUME_INFORMATION
        {
            public uint VolumeFlags;
            public uint FlagMask;
            public uint Version;
            public uint Reserved;
        }

        // https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntifs/ns-ntifs-_file_fs_persistent_volume_information
        public const uint FSCTL_QUERY_PERSISTENT_VOLUME_STATE = 590396U;
        public const uint PERSISTENT_VOLUME_STATE_DEV_VOLUME = 0x00002000;

        // https://learn.microsoft.com/en-us/windows/win32/fileio/creating-and-opening-files
        public const uint FILE_READ_ATTRIBUTES = 0x0080;
        public const uint FILE_WRITE_ATTRIBUTES = 0x0100;
        public const uint FILE_SHARE_READ = 0x00000001;
        public const uint FILE_SHARE_WRITE = 0x00000002;
        public const uint OPEN_EXISTING = 3;
        public const uint FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;

        // To call the win32 function without having to allocate memory in powershell
        public static bool DeviceIoControlWrapperForDevDriveQuery(string volumeGuidPath)
        {
            uint notUsedSize = 0;
            var outputVolumeInfo = new FILE_FS_PERSISTENT_VOLUME_INFORMATION { };
            var inputVolumeInfo = new FILE_FS_PERSISTENT_VOLUME_INFORMATION { };
            inputVolumeInfo.FlagMask = PERSISTENT_VOLUME_STATE_DEV_VOLUME;
            inputVolumeInfo.Version = 1;

            var volumeFileHandle = CreateFile(
                volumeGuidPath,
                FILE_READ_ATTRIBUTES | FILE_WRITE_ATTRIBUTES,
                FILE_SHARE_READ | FILE_SHARE_WRITE,
                IntPtr.Zero,
                OPEN_EXISTING,
                FILE_FLAG_BACKUP_SEMANTICS,
                IntPtr.Zero);

            if (volumeFileHandle.IsInvalid)
            {
                // Handle is invalid.
                throw new Exception("CreateFile unable to get file handle for volume to check if its a Dev Drive volume",
                    new Win32Exception(Marshal.GetLastWin32Error()));
            }

            // We need to allocated memory for the structures so we can marshal and unmarshal them.
            IntPtr inputVolptr = Marshal.AllocHGlobal(Marshal.SizeOf(inputVolumeInfo));
            IntPtr outputVolptr = Marshal.AllocHGlobal(Marshal.SizeOf(outputVolumeInfo));

            try
            {
                Marshal.StructureToPtr(inputVolumeInfo, inputVolptr, false);

                var result = DeviceIoControl(
                    volumeFileHandle,
                    FSCTL_QUERY_PERSISTENT_VOLUME_STATE,
                    inputVolptr,
                    (uint)Marshal.SizeOf(inputVolumeInfo),
                    outputVolptr,
                    (uint)Marshal.SizeOf(outputVolumeInfo),
                    out notUsedSize,
                    IntPtr.Zero);

                if (!result)
                {
                    // Can't query volume.
                    throw new Exception("DeviceIoControl unable to query if volume is a Dev Drive volume",
                        new Win32Exception(Marshal.GetLastWin32Error()));
                }

                // Unmarshal the output structure
                outputVolumeInfo = (FILE_FS_PERSISTENT_VOLUME_INFORMATION) Marshal.PtrToStructure(
                    outputVolptr,
                    typeof(FILE_FS_PERSISTENT_VOLUME_INFORMATION)
                );

                // Check that the output flag is set to Dev Drive volume.
                if ((outputVolumeInfo.VolumeFlags & PERSISTENT_VOLUME_STATE_DEV_VOLUME) > 0)
                {
                    // Volume is a Dev Drive volume.
                    return true;
                }

                return false;
            }
            finally
            {
                // Free the memory we allocated.
                Marshal.FreeHGlobal(inputVolptr);
                Marshal.FreeHGlobal(outputVolptr);
                volumeFileHandle.Close();
            }
        }
'@
    if (([System.Management.Automation.PSTypeName]'DevDrive.DevDriveHelper').Type)
    {
        $script:DevDriveWin32Helper = ([System.Management.Automation.PSTypeName]'DevDrive.DevDriveHelper').Type
    }
    else
    {
        # Note: when recompiling changes to the C# code above you'll need to close the powershell session and reopen a new one.
        $script:DevDriveWin32Helper = Add-Type `
            -Namespace 'DevDrive' `
            -Name 'DevDriveHelper' `
            -MemberDefinition $DevDriveHelperDefinitions `
            -UsingNamespace `
            'System.ComponentModel',
        'Microsoft.Win32.SafeHandles'
    }

    return $script:DevDriveWin32Helper
}
