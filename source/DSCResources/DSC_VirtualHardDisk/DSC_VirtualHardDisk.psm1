$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Storage Common Module.
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'StorageDsc.Common' `
            -ChildPath 'StorageDsc.Common.psm1'))

# Import the VirtualHardDisk Win32Helpers Module.
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'VirtualHardDisk.Win32Helpers' `
            -ChildPath 'VirtualHardDisk.Win32Helpers.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings.
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the current state of the virtual disk.

    .PARAMETER FilePathWithExtension
        Specifies the complete path to the virtual disk file.

    .PARAMETER DiskSize
        Specifies the size the new virtual disk.

    .PARAMETER DiskType
        Specifies the supported virtual disk type.

    .PARAMETER Ensure
        Determines whether the setting should be applied or removed.
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
        $FilePathWithExtension,

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $DiskSize,

        [Parameter()]
        [ValidateSet('fixed', 'dynamic')]
        [System.String]
        $DiskType = 'dynamic',

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

     # We'll only support local paths with drive letters.
    if ($FilePathWithExtension -notmatch '[a-zA-Z]:\\')
    {
        # AccessPath is invalid
        New-InvalidArgumentException `
            -Message $($script:localizedData.VirtualHardDiskPathError -f $FilePathWithExtension) `
            -ArgumentName 'FilePath'
    }

    $extension = [System.IO.Path]::GetExtension($FilePathWithExtension).TrimStart('.')
    if (($extension -ne 'vhd') -and ($extension -ne 'vhdx'))
    {
        New-InvalidArgumentException `
            -Message $($script:localizedData.VirtualHardDiskUnsupportedFileType -f $extension) `
            -ArgumentName 'FilePath'
    }

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingVirtualDiskMessage -f $FilePathWithExtension)
        ) -join '' )

    <#
        Validate DiskFormat values. Minimum value for GPT is around ~10MB and the maximum value for
        the vhd format in 2040GB. Maximum for vhdx is 64TB
    #>
    $isVhdxFormat = $extension -eq 'vhdx'
    $isInValidSizeForVhdFormat = ($DiskSize -lt 10MB -bor $DiskSize -gt 2040GB)
    $isInValidSizeForVhdxFormat = ($DiskSize -lt 10MB -bor $DiskSize -gt 64TB)
    if ((-not $isVhdxFormat -and $isInValidSizeForVhdFormat) -bor
        ($IsVhdxFormat -and $isInValidSizeForVhdxFormat))
    {
        if ($DiskSize -lt 1GB)
        {
            $DiskSizeString =  ($DiskSize / 1MB).ToString("0.00MB")
        }
        else
        {
            $DiskSizeString =  ($DiskSize / 1TB).ToString("0.00TB")
        }

        $InvalidSizeMsg = $script:localizedData.VhdFormatDiskSizeInvalidMessage
        if ($isVhdxFormat)
        {
            $InvalidSizeMsg = $script:localizedData.VhdxFormatDiskSizeInvalidMessage
        }

        New-InvalidArgumentException `
            -Message $($InvalidSizeMsg -f $DiskSizeString) `
            -ArgumentName 'DiskSize'
    }

    # Get the virtual disk using its location on the system
    return @{
        FilePathWithExtension   = $FilePathWithExtension
        DiskSize                = $DiskSize
        DiskFormat              = $extension
        DiskType                = $DiskType
        Ensure                  = $Ensure
    }
} # function Get-TargetResource

<#
    .SYNOPSIS
        Returns the current state of the virtual disk.

    .PARAMETER FilePathWithExtension
        Specifies the complete path to the virtual disk file.

    .PARAMETER DiskSize
        Specifies the size of new virtual disk.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format. Currently only the vhd and vhdx formats are supported.

    .PARAMETER DiskType
        Specifies the supported virtual disk type.

    .PARAMETER Ensure
        Determines whether the setting should be applied or removed.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePathWithExtension,

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $DiskSize,

        [Parameter()]
        [ValidateSet('vhd', 'vhdx')]
        [System.String]
        $DiskFormat,

        [Parameter()]
        [ValidateSet('fixed', 'dynamic')]
        [System.String]
        $DiskType = 'dynamic',

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    $diskImage = Get-DiskImage -ImagePath $FilePathWithExtension
    if ($Ensure -eq 'Present')
    {
        # Disk doesn't exist
        if (-not $diskImage)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.VirtualDiskDoesNotExistCreatingNowMessage -f $FilePathWithExtension)
            ) -join '' )

            $folderPath = Split-Path -Parent $FilePathWithExtension
            $wasLocationCreated = $false

            try
            {
                # Create the location if it doesn't exist.
                if (-not (Test-Path -PathType Container $folderPath))
                {
                    New-Item -ItemType Directory -Path $folderPath
                    $wasLocationCreated = $true
                }

                New-SimpleVirtualDisk -VirtualDiskPath $FilePathWithExtension -DiskFormat $diskFormat -DiskType $DiskType -DiskSizeInBytes $DiskSize
            }
            catch
            {
                 # Remove file if we created it but were unable to attach it. No handles are open when this happens.
                if (Test-Path -Path $FilePathWithExtension -PathType Leaf)
                {
                    Write-Verbose -Message ($script:localizedData.VirtualRemovingCreatedFileMessage -f $VirtualDiskPath)
                    Remove-Item $FilePathWithExtension -verbose
                }

                if ($wasLocationCreated)
                {
                    Remove-Item -LiteralPath $folderPath
                }
            }

        }
        elseif (-not $diskImage.Attached)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.VirtualDiskNotAttachedMessage -f $FilePathWithExtension)
                ) -join '' )

            # Virtual disk file exists so lets attempt to attach it to the system.
            Add-SimpleVirtualDisk -VirtualDiskPath $FilePathWithExtension -DiskFormat $diskFormat
        }
    }
    else
    {
        # Detach the virtual disk if its not suppose to be mounted
        if ($diskImage.Attached)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.VirtualDiskDismountingImageMessage `
                        -f $FilePathWithExtension)
                ) -join '' )

            Dismount-DiskImage -ImagePath $FilePathWithExtension
        }
    }
} # function Set-TargetResource

<#
    .SYNOPSIS
        Returns the current state of the virtual disk.

    .PARAMETER FilePathWithExtension
        Specifies the complete path to the virtual disk file.

    .PARAMETER DiskSize
        Specifies the size of new virtual disk.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format. Currently only the vhd and vhdx formats are supported.

    .PARAMETER DiskType
        Specifies the supported virtual disk type.

    .PARAMETER Ensure
        Determines whether the setting should be applied or removed.
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
        $FilePathWithExtension,

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $DiskSize,

        [Parameter()]
        [ValidateSet('vhd', 'vhdx')]
        [System.String]
        $DiskFormat,

        [Parameter()]
        [ValidateSet('fixed', 'dynamic')]
        [System.String]
        $DiskType = 'dynamic',

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.CheckingVirtualDiskExistsMessage -f $FilePathWithExtension)
        ) -join '' )

    $diskImage = Get-DiskImage -ImagePath $FilePathWithExtension

    if ($Ensure -eq 'Present')
    {
        # Found the virtual disk and confirmed its attached to the system.
        if ($diskImage.Attached)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.VirtualDiskCurrentlyAttachedMessage -f $FilePathWithExtension)
            ) -join '' )

            return $true
        }

        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.VirtualDiskDoesNotExistMessage -f $FilePathWithExtension)
        ) -join '' )

        return $false
    }
    else
    {
        # Found the virtual disk and confirmed its attached to the system but ensure variable set to absent.
        if ($diskImage.Attached)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.VirtualDiskCurrentlyAttachedButShouldNotBeMessage -f $FilePathWithExtension)
            ) -join '' )

            return $false
        }

        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.VirtualDiskDoesNotExistMessage -f $FilePathWithExtension)
        ) -join '' )

        return $true
    }
} # function Test-TargetResource

Export-ModuleMember -Function *-TargetResource
