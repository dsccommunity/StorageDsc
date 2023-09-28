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

        public enum DEVELOPER_DRIVE_ENABLEMENT_STATE
        {
            DeveloperDriveEnablementStateError = 0,
            DeveloperDriveEnabled = 1,
            DeveloperDriveDisabledBySystemPolicy = 2,
            DeveloperDriveDisabledByGroupPolicy = 3,
        }

        [DllImport("api-ms-win-core-apiquery-l2-1-0.dll", ExactSpelling = true)]
        [DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
        public static extern bool IsApiSetImplemented(string Contract);

        [DllImport("api-ms-win-core-sysinfo-l1-2-6.dll")]
        public static extern DEVELOPER_DRIVE_ENABLEMENT_STATE GetDeveloperDriveEnablementState();

'@
    if (([System.Management.Automation.PSTypeName]'DevDrive.DevDriveHelper').Type)
    {
        $script:DevDriveWin32Helper = ([System.Management.Automation.PSTypeName]'DevDrive.DevDriveHelper').Type
    }
    else
    {
        $script:DevDriveWin32Helper = Add-Type `
            -Namespace 'DevDrive' `
            -Name 'DevDriveHelper' `
            -MemberDefinition $DevDriveHelperDefinitions
    }

    return $script:DevDriveWin32Helper
} # end function Get-DevDriveWin32HelperScript

<#
    .SYNOPSIS
        Invokes win32 IsApiSetImplemented function

    .PARAMETER AccessPath
        Specifies the contract string for the dll that houses the win32 function
#>
function Get-IsApiSetImplemented
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
} # end function Get-IsApiSetImplemented

<#
    .SYNOPSIS
        Invokes win32 GetDeveloperDriveEnablementState function
#>
function Get-DeveloperDriveEnablementState
{
    [CmdletBinding()]
    [OutputType([System.Enum])]
    param
    ()

    $helper = Get-DevDriveWin32HelperScript
    return $helper::GetDeveloperDriveEnablementState()
} # end function Get-DeveloperDriveEnablementState

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

    $IsApiSetImplemented = Get-IsApiSetImplemented("api-ms-win-core-sysinfo-l1-2-6")
    $DevDriveEnablementType = [DevDrive.DevDriveHelper+DEVELOPER_DRIVE_ENABLEMENT_STATE]
    if ($IsApiSetImplemented)
    {
        try
        {
            # Based on the enablement result we will throw an error or return without doing anything.
            switch (Get-DeveloperDriveEnablementState)
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
function Assert-DevDriveFormatOnReFsFileSystemOnly
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
            -Message $($script:localizedData.DevDriveOnlyAvailableForReFsError -f 'ReFS', $FSFormat) `
            -ArgumentName 'FSFormat'
    }

} # end function Assert-DevDriveFormatOnReFsFileSystemOnly

<#
    .SYNOPSIS
        Validates that the user has enough space on the disk to create a Dev Drive volume.

    .PARAMETER UserDesiredSize
        Specifies the size the user wants to create the Dev Drive volume with.

    .PARAMETER CurrentDiskFreeSpace
        Specifies the maximum free space that can be used to create a partition on the disk with.

    .PARAMETER DiskNumber
        Specifies the the disk number the user what to create the Dev Drive volume inside.
#>
function Assert-DiskHasEnoughSpaceToCreateDevDrive
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $UserDesiredSize,

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $CurrentDiskFreeSpace,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $DiskNumber
    )

    <#
        50 Gb is the minimum size for Dev Drive volumes. When size is 0 the user wants to use all
        the available space on the disk.
    #>
    $notEnoughSpace = $false
    if (-not $UserDesiredSize)
    {
        <#
            The user wants to use all the available space on the disk. We will check if they have at least 50 Gb
            of free space available.
        #>
        $notEnoughSpace = ($CurrentDiskFreeSpace -lt 50Gb)
        $UserDesiredSize = 50Gb
    }

    if ($notEnoughSpace -or ($UserDesiredSize -gt $CurrentDiskFreeSpace))
    {
        $DesiredSizeInGb = [Math]::Round($UserDesiredSize / 1GB, 2)
        $CurrentDiskFreeSpaceInGb = [Math]::Round($CurrentDiskFreeSpace / 1GB, 2)
        New-InvalidArgumentException `
            -Message $($script:localizedData.DevDriveNotEnoughSpaceToCreateDevDriveError -f `
                $DiskNumber, $DesiredSizeInGb, $CurrentDiskFreeSpaceInGb) `
                -ArgumentName 'UserDesiredSize'
    }
} # end function Assert-DiskHasEnoughSpaceToCreateDevDrive

<#
    .SYNOPSIS
        Validates that the user entered a size greater than the minimum for Dev Drive volumes.
        (The minimum is 50 Gb)

    .PARAMETER UserDesiredSize
        Specifies the size the user wants to create the Dev Drive volume with.
#>
function Assert-DevDriveSizeMeetsMinimumRequirement
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $UserDesiredSize
    )

    <#
        50 Gb is the minimum size for Dev Drive volumes. The case where no size is
        provided is covered in Assert-DiskHasEnoughSpaceToCreateDevDrive.
    #>
    if ($UserDesiredSize -and $UserDesiredSize -lt 50Gb)
    {
        New-InvalidArgumentException `
            -Message $($script:localizedData.DevDriveMinimumSizeError) `
            -ArgumentName 'UserDesiredSize'
    }

} # end function Assert-DevDriveSizeMeetsMinimumRequirement

Export-ModuleMember -Function @(
    'Restart-ServiceIfExists',
    'Assert-DriveLetterValid',
    'Assert-AccessPathValid',
    'Get-DiskByIdentifier',
    'Test-AccessPathAssignedToLocal',
    'Assert-DevDriveFeatureAvailable',
    'Assert-DevDriveFormatOnReFsFileSystemOnly',
    'Assert-DevDriveSizeMeetsMinimumRequirement',
    'Get-DevDriveWin32HelperScript',
    'Get-IsApiSetImplemented',
    'Get-DeveloperDriveEnablementState',
    'Assert-DiskHasEnoughSpaceToCreateDevDrive'
)
