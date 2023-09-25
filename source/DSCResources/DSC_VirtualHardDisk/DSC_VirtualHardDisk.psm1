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

    .PARAMETER FilePath
        Specifies the complete path to the virtual disk file.
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
        $FilePath
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingVirtualDiskMessage -f $FilePath)
        ) -join '' )

    $diskImage = Get-DiskImage -ImagePath $FilePath -ErrorAction SilentlyContinue
    $Ensure = 'Present'
    if (-not $diskImage)
    {
        $Ensure = 'Absent'
    }

    # Get the virtual disk info using its path on the system
    return @{
        FilePath   = $diskImage.ImagePath
        Attached   = $diskImage.Attached
        Size       = $diskImage.Size
        DiskNumber = $diskImage.DiskNumber
        Ensure     = $Ensure
    }
} # function Get-TargetResource

<#
    .SYNOPSIS
        Returns the current state of the virtual disk.

    .PARAMETER FilePath
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
        $FilePath,

        [Parameter()]
        [ValidateScript({$_ -gt 0})]
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

    Assert-ParametersValid -FilePath $FilePath -DiskSize $DiskSize -DiskFormat $DiskFormat
    $diskImage = Get-DiskImage -ImagePath $FilePath -ErrorAction SilentlyContinue

    if ($Ensure -eq 'Present')
    {
        # Disk doesn't exist
        if (-not $diskImage)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.VirtualDiskDoesNotExistCreatingNowMessage -f $FilePath)
            ) -join '' )

            $folderPath = Split-Path -Parent $FilePath
            $wasLocationCreated = $false

            try
            {
                # Create the location if it doesn't exist.
                if (-not (Test-Path -PathType Container $folderPath))
                {
                    New-Item -ItemType Directory -Path $folderPath
                    $wasLocationCreated = $true
                }

                New-SimpleVirtualDisk -VirtualDiskPath $FilePath -DiskFormat $DiskFormat -DiskType $DiskType -DiskSizeInBytes $DiskSize
            }
            catch
            {
                 # Remove file if we created it but were unable to attach it. No handles are open when this happens.
                if (Test-Path -Path $FilePath -PathType Leaf)
                {
                    Write-Verbose -Message ($script:localizedData.VirtualRemovingCreatedFileMessage -f $folderPath)
                    Remove-Item $FilePath -verbose
                }

                if ($wasLocationCreated)
                {
                    Remove-Item -LiteralPath $folderPath
                }

                # Rethrow the exception
                throw
            }

        }
        elseif (-not $diskImage.Attached)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.VirtualDiskNotAttachedMessage -f $FilePath)
                ) -join '' )

            # Virtual disk file exists so lets attempt to attach it to the system.
            Add-SimpleVirtualDisk -VirtualDiskPath $FilePath -DiskFormat $DiskFormat
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
                        -f $FilePath)
                ) -join '' )

            Dismount-DiskImage -ImagePath $FilePath
        }
    }
} # function Set-TargetResource

<#
    .SYNOPSIS
        Returns the current state of the virtual disk.

    .PARAMETER FilePath
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
        $FilePath,

        [Parameter()]
        [ValidateScript({$_ -gt 0})]
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

    Assert-ParametersValid -FilePath $FilePath -DiskSize $DiskSize -DiskFormat $DiskFormat
    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($script:localizedData.CheckingVirtualDiskExistsMessage -f $FilePath)
    ) -join '' )

    $diskImage = Get-DiskImage -ImagePath $FilePath -ErrorAction SilentlyContinue

    if ($Ensure -eq 'Present')
    {
        # Found the virtual disk and confirmed its attached to the system.
        if ($diskImage.Attached)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.VirtualDiskCurrentlyAttachedMessage -f $FilePath)
            ) -join '' )

            return $true
        }

        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.VirtualDiskDoesNotExistMessage -f $FilePath)
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
                $($script:localizedData.VirtualDiskCurrentlyAttachedButShouldNotBeMessage -f $FilePath)
            ) -join '' )

            return $false
        }

        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.VirtualDiskDoesNotExistMessage -f $FilePath)
        ) -join '' )

        return $true
    }
} # function Test-TargetResource

<#
    .SYNOPSIS
        Validates parameters for both set and test operations.

    .PARAMETER FilePath
        Specifies the complete path to the virtual disk file.

    .PARAMETER DiskSize
        Specifies the size of new virtual disk.

    .PARAMETER DiskFormat
        Specifies the supported virtual disk format. Currently only the vhd and vhdx formats are supported.
#>
function Assert-ParametersValid
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePath,

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $DiskSize,

        [Parameter(Mandatory = $true)]
        [ValidateSet('vhd', 'vhdx')]
        [System.String]
        $DiskFormat
    )

    # We'll only support local paths with drive letters.
    if ($FilePath -notmatch '[a-zA-Z]:\\')
    {
        # AccessPath is invalid
        New-InvalidArgumentException `
            -Message $($script:localizedData.VirtualHardDiskPathError -f $FilePath) `
            -ArgumentName 'FilePath'
    }

    $extension = [System.IO.Path]::GetExtension($FilePath).TrimStart('.')
    if ($extension)
    {
        if (($extension -ne 'vhd') -and ($extension -ne 'vhdx'))
        {
            New-InvalidArgumentException `
                -Message $($script:localizedData.VirtualHardDiskUnsupportedFileType -f $extension) `
                -ArgumentName 'FilePath'
        }
        elseif ($extension -ne $DiskFormat)
        {
            New-InvalidArgumentException `
              -Message $($script:localizedData.VirtualHardExtensionAndFormatMismatchError -f $FilePath, $extension, $DiskFormat) `
              -ArgumentName 'FilePath'
        }
    }
    else
    {
        New-InvalidArgumentException `
            -Message $($script:localizedData.VirtualHardNoExtensionError -f $FilePath) `
            -ArgumentName 'FilePath'
    }

    <#
        Validate DiskFormat values. Minimum value for GPT is around ~10MB and the maximum value for
        the vhd format in 2040GB. Maximum for vhdx is 64TB
    #>
    $isVhdxFormat = $DiskFormat -eq 'vhdx'
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
} #  Assert-ParametersValid

Export-ModuleMember -Function *-TargetResource
