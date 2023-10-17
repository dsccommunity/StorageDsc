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
        Returns the current state of the virtual hard disk.

    .PARAMETER FilePath
        Specifies the complete path to the virtual hard disk file.
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
            $($script:localizedData.GettingVirtualHardDisk -f $FilePath)
        ) -join '' )

    $diskImage = Get-DiskImage -ImagePath $FilePath -ErrorAction SilentlyContinue
    $Ensure = 'Present'

    if (-not $diskImage)
    {
        $Ensure = 'Absent'
    }

    # Get the virtual hard disk info using its path on the system
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
        Returns the current state of the virtual hard disk.

    .PARAMETER FilePath
        Specifies the complete path to the virtual hard disk file.

    .PARAMETER DiskSize
        Specifies the size of new virtual hard disk.

    .PARAMETER DiskFormat
        Specifies the supported virtual hard disk format. Currently only the vhd and vhdx formats are supported.

    .PARAMETER DiskType
        Specifies the supported virtual hard disk type.

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
        [ValidateSet('Vhd', 'Vhdx')]
        [System.String]
        $DiskFormat,

        [Parameter()]
        [ValidateSet('Fixed', 'Dynamic')]
        [System.String]
        $DiskType = 'Dynamic',

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Assert-ParametersValid -FilePath $FilePath -DiskSize $DiskSize -DiskFormat $DiskFormat

    $resource = Get-TargetResource -FilePath $FilePath

    if ($Ensure -eq 'Present')
    {
        # Disk doesn't exist
        if (-not $resource.FilePath)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.VirtualHardDiskDoesNotExistCreatingNow -f $FilePath)
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
                    Write-Verbose -Message ($script:localizedData.RemovingCreatedVirtualHardDiskFile -f $FilePath)
                    Remove-Item $FilePath -verbose
                }

                if ($wasLocationCreated)
                {
                    Remove-Item -LiteralPath $folderPath -verbose
                }

                # Rethrow the exception
                throw
            }

        }
        elseif (-not $resource.Attached)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.VirtualDiskNotAttached -f $FilePath)
                ) -join '' )

            # Virtual hard disk file exists so lets attempt to attach it to the system.
            Add-SimpleVirtualDisk -VirtualDiskPath $FilePath -DiskFormat $DiskFormat
        }
    }
    else
    {
        # Detach the virtual hard disk if its not suppose to be attached.
        if ($resource.Attached)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($script:localizedData.VirtualHardDiskDetachingImage `
                        -f $FilePath)
                ) -join '' )

            Dismount-DiskImage -ImagePath $FilePath
        }
    }
} # function Set-TargetResource

<#
    .SYNOPSIS
        Returns the current state of the virtual hard disk.

    .PARAMETER FilePath
        Specifies the complete path to the virtual hard disk file.

    .PARAMETER DiskSize
        Specifies the size of new virtual hard disk.

    .PARAMETER DiskFormat
        Specifies the supported virtual hard disk format. Currently only the vhd and vhdx formats are supported.

    .PARAMETER DiskType
        Specifies the supported virtual hard disk type.

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
        [ValidateSet('Vhd', 'Vhdx')]
        [System.String]
        $DiskFormat,

        [Parameter()]
        [ValidateSet('Fixed', 'Dynamic')]
        [System.String]
        $DiskType = 'Dynamic',

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Assert-ParametersValid -FilePath $FilePath -DiskSize $DiskSize -DiskFormat $DiskFormat

    $resource = Get-TargetResource -FilePath $FilePath

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($script:localizedData.CheckingVirtualDiskExists -f $FilePath)
    ) -join '' )

    if ($Ensure -eq 'Present')
    {
        # Found the virtual hard disk and confirmed its attached to the system.
        if ($resource.Attached)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.VirtualHardDiskCurrentlyAttached -f $FilePath)
            ) -join '' )

            return $true
        }

        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.VirtualHardDiskMayNotExistOrNotAttached -f $FilePath)
        ) -join '' )

        return $false
    }
    else
    {
        # Found the virtual hard disk and confirmed its attached to the system but ensure variable set to 'Absent'.
        if ($resource.Attached)
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.VirtualHardDiskCurrentlyAttachedButShouldNotBe -f $FilePath)
            ) -join '' )

            return $false
        }

        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.VirtualHardDiskMayNotExistOrNotAttached -f $FilePath)
        ) -join '' )

        return $true
    }
} # function Test-TargetResource

<#
    .SYNOPSIS
        Validates parameters for both set and test operations.

    .PARAMETER FilePath
        Specifies the complete path to the virtual hard disk file.

    .PARAMETER DiskSize
        Specifies the size of new virtual hard disk.

    .PARAMETER DiskFormat
        Specifies the supported virtual hard disk format. Currently only the vhd and vhdx formats are supported.
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
        [ValidateSet('Vhd', 'Vhdx')]
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
              -Message $($script:localizedData.VirtualHardDiskExtensionAndFormatMismatchError -f $FilePath, $extension, $DiskFormat) `
              -ArgumentName 'FilePath'
        }
    }
    else
    {
        New-InvalidArgumentException `
            -Message $($script:localizedData.VirtualHardDiskNoExtensionError -f $FilePath) `
            -ArgumentName 'FilePath'
    }

    <#
        Validate DiskFormat values. Minimum value for GPT is around ~10MB and the maximum value for
        the vhd format in 2040GB. Maximum for the vhdx format is 64TB.
    #>
    $isVhdxFormat = $DiskFormat -eq 'Vhdx'
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

        $InvalidSizeMsg = $script:localizedData.VhdFormatDiskSizeInvalid
        if ($isVhdxFormat)
        {
            $InvalidSizeMsg = $script:localizedData.VhdxFormatDiskSizeInvalid
        }

        New-InvalidArgumentException `
            -Message $($InvalidSizeMsg -f $DiskSizeString) `
            -ArgumentName 'DiskSize'
    }
} #  Assert-ParametersValid

Export-ModuleMember -Function *-TargetResource
