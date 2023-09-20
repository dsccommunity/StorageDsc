$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Storage Common Module.
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'StorageDsc.Common' `
            -ChildPath 'StorageDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')
Import-Module $PSScriptRoot\\Win32Helpers.psm1

# Import Localization Strings.
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the virtual disk.

    .PARAMETER FolderPath
        Specifies the path to the folder the virtual disk is located in.

    .PARAMETER FileName
        Specifies the file name of the virtual disk.

    .PARAMETER DiskSize
        Specifies the size of new virtual disk.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format.

    .PARAMETER DiskType
        Specifies the supported virtual disk type.

#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FolderPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FileName,

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $DiskSize,

        [Parameter()]
        [ValidateSet('vhd', 'vhdx')]
        [System.String]
        $DiskFormat = 'vhdx',

        [Parameter()]
        [ValidateSet('fixed', 'dynamic')]
        [System.String]
        $DiskType = 'dynamic'
    )

    $FolderPath = Assert-AccessPathValid -AccessPath $FolderPath -Slash
    $virtDiskPath = $($FolderPath + $FileName + "." +  $DiskFormat)
    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingVirtualDiskMessage -f $virtDiskPath)
        ) -join '' )

    <#
        Validate DiskFormat values. Minimum value for GPT is around ~10MB and the maximum value for
        the vhd format in 2040GB. Maximum for vhdx is 64TB
    #>
    $isVhdxFormat = $DiskFormat -eq 'vhdx'
    if (( -not $isVhdxFormat -and ($DiskSize -lt 10MB -bor $DiskSize -gt 2040GB)) -bor
        ($IsVhdxFormat -and ($DiskSize -lt 10MB -bor $DiskSize -gt 64TB)))
    {
        $DiskSizeString = ConvertFrom-Bytes $DiskSize
        $InvalidSizeMsg = ($isVhdxFormat) ?
            $script:localizedData.VhdxFormatDiskSizeInvalidMessage :
            $script:localizedData.VhdFormatDiskSizeInvalidMessage

        New-InvalidArgumentException `
            -Message $($InvalidSizeMsg -f $DiskSizeString) `
            -ArgumentName 'DiskSize'
    }

    # Get the virtual disk using its location on the system
    return @{
        FolderPath  = $FolderPath
        FileName    = $FileName
        DiskSize    = $DiskSize
        DiskFormat  = $DiskFormat
        DiskType    = $DiskType
    }
} # function Get-TargetResource

<#
    .SYNOPSIS
        Returns the current state of the virtual disk.

    .PARAMETER FolderPath
        Specifies the path to the folder the virtual disk is located in.

    .PARAMETER FileName
        Specifies the file name of the virtual disk.

    .PARAMETER DiskSize
        Specifies the size of new virtual disk.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format.

    .PARAMETER DiskType
        Specifies the supported virtual disk type.

#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FolderPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FileName,

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $DiskSize,

        [Parameter()]
        [ValidateSet('vhd', 'vhdx')]
        [System.String]
        $DiskFormat = 'vhdx',

        [Parameter()]
        [ValidateSet('fixed', 'dynamic')]
        [System.String]
        $DiskType = 'dynamic'
    )

    # Validate the FolderPath parameter
    $FolderPath = Assert-AccessPathValid -AccessPath $FolderPath -Slash
    $fullPathToVirtualDisk = $FolderPath + $FileName + "." + $DiskFormat

    # Create and attach virtual disk if it doesn't exist
    $virtualDiskFileExists = Test-Path -Path $fullPathToVirtualDisk -PathType Leaf
    if (-not $virtualDiskFileExists)
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.VirtualDiskDoesNotExistCreatingNowMessage -f $fullPathToVirtualDisk)
        ) -join '' )

        New-SimpleVirtualDisk -VirtualDiskPath $fullPathToVirtualDisk -DiskFormat $DiskFormat -DiskType $DiskType -DiskSizeInBytes $DiskSize
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.VirtualDiskNotAttachedMessage -f $fullPathToVirtualDisk)
            ) -join '' )

        # Virtual disk file exists so lets attempt to attach it to the system.
        Add-SimpleVirtualDisk -VirtualDiskPath $fullPathToVirtualDisk -DiskFormat $DiskFormat
    }


} # function Set-TargetResource

<#
    .SYNOPSIS
        Returns the current state of the virtual disk.
    .PARAMETER FolderPath
        Specifies the path to the folder the virtual disk is located in.

    .PARAMETER FileName
        Specifies the file name of the virtual disk.

    .PARAMETER DiskSize
        Specifies the size of new virtual disk.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format.

    .PARAMETER DiskType
        Specifies the supported virtual disk type.

#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FolderPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FileName,

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $DiskSize,

        [Parameter()]
        [ValidateSet('vhd', 'vhdx')]
        [System.String]
        $DiskFormat = 'vhdx',

        [Parameter()]
        [ValidateSet('fixed', 'dynamic')]
        [System.String]
        $DiskType = 'dynamic'
    )
    # Validate the FolderPath parameter
    $FolderPath = Assert-AccessPathValid -AccessPath $FolderPath -Slash
    $fullPathToVirtualDisk = $FolderPath + $FileName + "." + $DiskFormat
    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.CheckingVirtualDiskExistsMessage -f $fullPathToVirtualDisk)
        ) -join '' )

    #Check if virtual file exists
    if (-not (Test-Path -Path $fullPathToVirtualDisk -PathType Leaf))
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.VirtualDiskDoesNotExistMessage -f $fullPathToVirtualDisk)
        ) -join '' )

        return $false
    }

    $virtdisk = Get-DiskByIdentifier `
        -DiskId $fullPathToVirtualDisk `
        -DiskIdType 'Location'

    # Found the virtual disk and confirmed its attached to the system.
    if ($virtdisk)
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.VirtualDiskCurrentlyAttachedMessage -f $fullPathToVirtualDisk)
        ) -join '' )

        return $true
    }

    # Either the virtual disk is not attached or the file above exists but is corrupted or wasn't created properly.
    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($script:localizedData.VirtualDiskNotAttachedOrFileCorruptedMessage -f $fullPathToVirtualDisk)
    ) -join '' )

    return $false
} # function Test-TargetResource

Export-ModuleMember -Function *-TargetResource
