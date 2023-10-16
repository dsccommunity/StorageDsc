$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Restarts a System Service

    .PARAMETER Name
        Name of the service to be restarted.
#>
function Restart-ServiceIfExists
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $Name
    )

    Write-Verbose -Message ($script:localizedData.GetServiceInformation -f $Name) -Verbose
    $servicesService = Get-Service @PSBoundParameters -ErrorAction Continue

    if ($servicesService)
    {
        Write-Verbose -Message ($script:localizedData.RestartService -f $Name) -Verbose
        $servicesService | Restart-Service -Force -ErrorAction Stop -Verbose
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.UnknownService -f $Name) -Verbose
    }
}

<#
    .SYNOPSIS
        Validates a Drive Letter, removing or adding the trailing colon if required.

    .PARAMETER DriveLetter
        The Drive Letter string to validate.

    .PARAMETER Colon
        Will ensure the returned string will include or exclude a colon.
#>
function Assert-DriveLetterValid
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DriveLetter,

        [Parameter()]
        [Switch]
        $Colon
    )

    $matches = @([regex]::matches($DriveLetter, '^([A-Za-z]):?$', 'IgnoreCase'))

    if (-not $matches)
    {
        # DriveLetter format is invalid
        New-InvalidArgumentException `
            -Message $($script:localizedData.InvalidDriveLetterFormatError -f $DriveLetter) `
            -ArgumentName 'DriveLetter'
    }

    # This is the drive letter without a colon
    $DriveLetter = $matches.Groups[1].Value

    if ($Colon)
    {
        $DriveLetter = $DriveLetter + ':'
    } # if

    return $DriveLetter
} # end function Assert-DriveLetterValid

<#
    .SYNOPSIS
        Validates an Access Path, removing or adding the trailing slash if required.
        If the Access Path does not exist or is not a folder then an exception will
        be thrown.

    .PARAMETER AccessPath
        The Access Path string to validate.

    .PARAMETER Slash
        Will ensure the returned path will include or exclude a slash.
#>
function Assert-AccessPathValid
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AccessPath,

        [Parameter()]
        [Switch]
        $Slash
    )

    if (-not (Test-Path -Path $AccessPath -PathType Container))
    {
        # AccessPath is invalid
        New-InvalidArgumentException `
            -Message $($script:localizedData.InvalidAccessPathError -f $AccessPath) `
            -ArgumentName 'AccessPath'
    } # if

    # Remove or Add the trailing slash
    if ($AccessPath.EndsWith('\'))
    {
        if (-not $Slash)
        {
            $AccessPath = $AccessPath.TrimEnd('\')
        } # if
    }
    else
    {
        if ($Slash)
        {
            $AccessPath = "$AccessPath\"
        } # if
    } # if

    return $AccessPath
} # end function Assert-AccessPathValid

<#
    .SYNOPSIS
        Retrieves a Disk object matching the disk Id and Id type
        provided.

    .PARAMETER DiskId
        Specifies the disk identifier for the disk to retrieve.

    .PARAMETER DiskIdType
        Specifies the identifier type the DiskId contains. Defaults to Number.
#>
function Get-DiskByIdentifier
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter()]
        [ValidateSet('Number','UniqueId','Guid','Location','FriendlyName','SerialNumber')]
        [System.String]
        $DiskIdType = 'Number'
    )

    switch -regex ($DiskIdType)
    {
        'Number|UniqueId|FriendlyName|SerialNumber' # for filters supported by the Get-Disk CmdLet
        {
            $diskIdParameter = @{
                $DiskIdType = $DiskId
            }

            $disk = Get-Disk `
                @diskIdParameter `
                -ErrorAction SilentlyContinue
            break
        }

        default # for filters requiring Where-Object
        {
            $disk = Get-Disk -ErrorAction SilentlyContinue |
                    Where-Object -Property $DiskIdType -EQ $DiskId
        }
    }

    return $disk
} # end function Get-DiskByIdentifier

<#
    .SYNOPSIS
        Tests if any of the access paths from a partition are assigned
        to a local path.

    .PARAMETER AccessPath
        Specifies the access paths that are assigned to the partition.
#>
function Test-AccessPathAssignedToLocal
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $AccessPath
    )

    $accessPathAssigned = $false

    foreach ($path in $AccessPath)
    {
        if ($path -match '[a-zA-Z]:\\')
        {
            $accessPathAssigned = $true
            break
        }
    }

    return $accessPathAssigned
} # end function Test-AccessPathLocal

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

    $DevDriveHelperDefinitions =  @'

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
} # end function Get-DevDriveWin32HelperScript

<#
    .SYNOPSIS
        Invokes win32 IsApiSetImplemented function.

    .PARAMETER Contract
        Specifies the contract string for the dll that houses the win32 function.
#>
function Invoke-IsApiSetImplemented
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Contract
    )

    $helper = Get-DevDriveWin32HelperScript
    return $helper::IsApiSetImplemented($Contract)
} # end function Invoke-IsApiSetImplemented

<#
    .SYNOPSIS
        Invokes win32 GetDeveloperDriveEnablementState function.
#>
function Get-DevDriveEnablementState
{
    [CmdletBinding()]
    [OutputType([System.Enum])]
    param
    ()

    $helper = Get-DevDriveWin32HelperScript
    return $helper::GetDeveloperDriveEnablementState()
} # end function Get-DevDriveEnablementState

<#
    .SYNOPSIS
        Validates whether the Dev Drive feature is available and enabled on the system.
#>
function Assert-DevDriveFeatureAvailable
{
    [CmdletBinding()]
    [OutputType([System.Void])]
    param
    ()

    $devDriveHelper = Get-DevDriveWin32HelperScript
    Write-Verbose -Message ($script:localizedData.CheckingDevDriveEnablementMessage)

    $IsApiSetImplemented = Invoke-IsApiSetImplemented('api-ms-win-core-sysinfo-l1-2-6')
    $DevDriveEnablementType = [DevDrive.DevDriveHelper+DEVELOPER_DRIVE_ENABLEMENT_STATE]

    if ($IsApiSetImplemented)
    {
        try
        {
            # Based on the enablement result we will throw an error or return without doing anything.
            switch (Get-DevDriveEnablementState)
            {
                ($DevDriveEnablementType::DeveloperDriveEnablementStateError)
                {
                    throw $script:localizedData.DevDriveEnablementUnknownError
                }
                ($DevDriveEnablementType::DeveloperDriveDisabledBySystemPolicy)
                {
                    throw $script:localizedData.DevDriveDisabledBySystemPolicyError
                }
                ($DevDriveEnablementType::DeveloperDriveDisabledByGroupPolicy)
                {
                    throw $script:localizedData.DevDriveDisabledByGroupPolicyError
                }
                ($DevDriveEnablementType::DeveloperDriveEnabled)
                {
                    Write-Verbose -Message ($script:localizedData.DevDriveEnabledMessage)
                    return
                }
                default
                {
                    throw $script:localizedData.DevDriveEnablementUnknownError
                }
            }
        }
        # function may not exist in some versions of Windows in the apiset dll.
        catch [System.EntryPointNotFoundException]
        {
            Write-Verbose $_.Exception.Message
        }
    }

    <#
        If apiset isn't implemented or we get the EntryPointNotFoundException we should throw
        since the feature isn't available here.
    #>
    throw $script:localizedData.DevDriveFeatureNotImplementedError
} # end function Assert-DevDriveFeatureAvailable

<#
    .SYNOPSIS
        Validates that ReFs is supplied when attempting to format a volume as a Dev Drive.

    .PARAMETER FSFormat
        Specifies the file system format of the new volume.
#>
function Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FSFormat
    )

    if ($FSFormat -ne 'ReFS')
    {
        New-InvalidArgumentException `
            -Message $($script:localizedData.FSFormatNotReFSWhenDevDriveFlagIsTrueError -f 'ReFS', $FSFormat) `
            -ArgumentName 'FSFormat'
    }

} # end function Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue

<#
    .SYNOPSIS
        Validates that the user entered a size greater than the minimum for Dev Drive volumes.
        (The minimum is 50 Gb)

    .PARAMETER UserDesiredSize
        Specifies the size the user wants to create the Dev Drive volume with.
#>
function Assert-SizeMeetsMinimumDevDriveRequirement
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $UserDesiredSize
    )

    # 50 Gb is the minimum size for Dev Drive volumes.
    $UserDesiredSizeInGb = [Math]::Round($UserDesiredSize / 1GB, 2)
    $minimumSizeForDevDriveInGb = 50

    if ($UserDesiredSizeInGb -lt $minimumSizeForDevDriveInGb)
    {
        throw ($script:localizedData.MinimumSizeNeededToCreateDevDriveVolumeError -F $UserDesiredSizeInGb )
    }

} # end function Assert-SizeMeetsMinimumDevDriveRequirement

<#
.SYNOPSIS
    Invokes the wrapper for the DeviceIoControl Win32 API function.

.PARAMETER VolumeGuidPath
    The guid path of the volume that will be queried.
#>
function Invoke-DeviceIoControlWrapperForDevDriveQuery
{
    [CmdletBinding()]
    [OutputType([System.boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VolumeGuidPath
    )

    $devDriveHelper = Get-DevDriveWin32HelperScript

    return $devDriveHelper::DeviceIoControlWrapperForDevDriveQuery($VolumeGuidPath)

}# end function Invoke-DeviceIoControlWrapperForDevDriveQuery

<#
    .SYNOPSIS
        Validates that a volume is a Dev Drive volume. This is temporary until a way to do
        this is added to the Storage Powershell library to query whether the volume is a Dev Drive volume
        or not.

    .PARAMETER VolumeGuidPath
        The guid path of the volume that will be queried.
#>
function Test-DevDriveVolume
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VolumeGuidPath
    )

    $devDriveHelper = Get-DevDriveWin32HelperScript

    return Invoke-DeviceIoControlWrapperForDevDriveQuery -VolumeGuidPath $VolumeGuidPath
}# end function Test-DevDriveVolume

Export-ModuleMember -Function @(
    'Restart-ServiceIfExists',
    'Assert-DriveLetterValid',
    'Assert-AccessPathValid',
    'Get-DiskByIdentifier',
    'Test-AccessPathAssignedToLocal',
    'Assert-DevDriveFeatureAvailable',
    'Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue',
    'Assert-SizeMeetsMinimumDevDriveRequirement',
    'Get-DevDriveWin32HelperScript',
    'Invoke-IsApiSetImplemented',
    'Get-DevDriveEnablementState',
    'Test-DevDriveVolume',
    'Invoke-DeviceIoControlWrapperForDevDriveQuery'
)
