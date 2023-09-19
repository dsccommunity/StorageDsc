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
        Validates whether the Dev Drive feature is available and enabled on the system.
#>
function Assert-DevDriveFeatureAvailable
{
    [CmdletBinding()]
    [OutputType([System.Void])]
    param
    ()

    $DevDriveDefinitions = @'
        using  System.Runtime.InteropServices;
        namespace  DevDrive
        {
            public enum DEVELOPER_DRIVE_ENABLEMENT_STATE
            {
                DeveloperDriveEnablementStateError = 0,
                DeveloperDriveEnabled = 1,
                DeveloperDriveDisabledBySystemPolicy = 2,
                DeveloperDriveDisabledByGroupPolicy = 3,
            }

            public class DevDriveHelper
            {
                [DllImport("api-ms-win-core-apiquery-l2-1-0.dll", ExactSpelling = true)]
                [DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
                public static extern bool IsApiSetImplemented(string Contract);

                [DllImport("api-ms-win-core-sysinfo-l1-2-6.dll")]
                public static extern DEVELOPER_DRIVE_ENABLEMENT_STATE GetDeveloperDriveEnablementState();
            }
        }
'@

    Add-Type -TypeDefinition $DevDriveDefinitions

    $IsApiSetImplemented = [DevDrive.DevDriveHelper]::IsApiSetImplemented("api-ms-win-core-sysinfo-l1-2-6")

    if ($IsApiSetImplemented)
    {
        switch ([DevDrive.DevDriveHelper]::GetDeveloperDriveEnablementState())
        {
            ([DevDrive.DEVELOPER_DRIVE_ENABLEMENT_STATE]::DeveloperDriveEnablementStateError)
            {
                throw $script:localizedData.DevDriveEnablementUnknownError;
            }
            ([DevDrive.DEVELOPER_DRIVE_ENABLEMENT_STATE]::DeveloperDriveDisabledBySystemPolicy)
            {
                throw $script:localizedData.DevDriveDisabledBySystemPolicyError;
            }
            ([DevDrive.DEVELOPER_DRIVE_ENABLEMENT_STATE]::DeveloperDriveDisabledByGroupPolicy)
            {
                throw $script:localizedData.DevDriveDisabledByGroupPolicyError;
            }
            ([DevDrive.DEVELOPER_DRIVE_ENABLEMENT_STATE]::DeveloperDriveEnabled)
            {
                return;
            }
            Default {
                throw $script:localizedData.DevDriveEnablementUnknownError;
            }
        }
    }

    # If apiset isn't implemented we should throw since the feature isn't available here.
    throw $script:localizedData.DevDriveFeatureNotImplementedError;

} # end function Assert-DevDriveFeatureAvailable

<#
    .SYNOPSIS
        Validates that ReFs is supplied when attempting to format a volume as a Dev Drive.

    .PARAMETER FSFormat
        Specifies the file system format of the new volume.
#>
function Assert-DevDriveFormatOnReFsFileSystemOnly
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('NTFS', 'ReFS')]
        [System.String]
        $FSFormat
    )

    if ($FSFormat -ne 'ReFS')
    {

        New-InvalidArgumentException `
            -Message $($script:localizedData.DevDriveOnlyAvailableForReFsError -f 'ReFS', $FSFormat) `
            -ArgumentName 'FSFormat'
    }

} # end function Assert-DevDriveFormatOnReFsFileSystemOnly

Export-ModuleMember -Function @(
    'Restart-ServiceIfExists',
    'Assert-DriveLetterValid',
    'Assert-AccessPathValid',
    'Get-DiskByIdentifier',
    'Test-AccessPathAssignedToLocal',
    'Assert-DevDriveFeatureAvailable',
    'Assert-DevDriveFormatOnReFsFileSystemOnly'
)
