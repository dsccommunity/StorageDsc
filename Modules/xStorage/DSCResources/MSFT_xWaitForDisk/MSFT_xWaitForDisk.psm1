# Suppressed as per PSSA Rule Severity guidelines for unit/integration tests:
# https://github.com/PowerShell/DscResources/blob/master/PSSARuleSeverities.md
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param ()

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Storage Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'StorageDsc.Common' `
                                                     -ChildPath 'StorageDsc.Common.psm1'))

# Import the Storage Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'StorageDsc.ResourceHelper' `
                                                     -ChildPath 'StorageDsc.ResourceHelper.psm1'))

# Import Localization Strings
$localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xWaitForDisk' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
    Returns the current state of the wait for disk resource.

    .PARAMETER DiskId
    Specifies the disk identifier for the disk to wait for.

    .PARAMETER DiskIdType
    Specifies the identifier type the DiskId contains. Defaults to Number.

    .PARAMETER RetryIntervalSec
    Specifies the number of seconds to wait for the disk to become available.

    .PARAMETER RetryCount
    The number of times to loop the retry interval while waiting for the disk.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter()]
        [ValidateSet('Number','UniqueId','Guid')]
        [System.String]
        $DiskIdType = 'Number',

        [Parameter()]
        [System.UInt32]
        $RetryIntervalSec = 10,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 60
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.GettingWaitForDiskStatusMessage -f $DiskIdType,$DiskId)
        ) -join '' )

    $returnValue = @{
        DiskId           = $DiskId
        DiskIdType       = $DiskIdType
        RetryIntervalSec = $RetryIntervalSec
        RetryCount       = $RetryCount
    }
    return $returnValue
} # function Get-TargetResource

<#
    .SYNOPSIS
    Sets the current state of the wait for disk resource.

    .PARAMETER DiskId
    Specifies the disk identifier for the disk to wait for.

    .PARAMETER DiskIdType
    Specifies the identifier type the DiskId contains. Defaults to Number.

    .PARAMETER RetryIntervalSec
    Specifies the number of seconds to wait for the disk to become available.

    .PARAMETER RetryCount
    The number of times to loop the retry interval while waiting for the disk.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter()]
        [ValidateSet('Number','UniqueId','Guid')]
        [System.String]
        $DiskIdType = 'Number',

        [Parameter()]
        [System.UInt32]
        $RetryIntervalSec = 10,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 60
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.CheckingForDiskStatusMessage -f $DiskIdType,$DiskId)
        ) -join '' )

    $diskFound = $false


    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        # Get the Disk using the identifiers supplied
        $disk = Get-DiskByIdentifier `
            -DiskId $DiskId `
            -DiskIdType $DiskIdType

        if ($disk)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($localizedData.DiskFoundMessage -f $DiskIdType,$DiskId,$disk.FriendlyName)
                ) -join '' )

            $diskFound = $true
            break
        }
        else
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($localizedData.DiskNotFoundMessage -f $DiskIdType,$DiskId,$RetryIntervalSec)
                ) -join '' )

            Start-Sleep -Seconds $RetryIntervalSec
        } # if
    } # for

    if (-not $diskFound)
    {
        New-InvalidOperationException `
            -Message $($localizedData.DiskNotFoundAfterError -f $DiskIdType,$DiskId,$RetryCount)
    } # if
} # function Set-TargetResource

<#
    .SYNOPSIS
    Tests the current state of the wait for disk resource.

    .PARAMETER DiskId
    Specifies the disk identifier for the disk to wait for.

    .PARAMETER DiskIdType
    Specifies the identifier type the DiskId contains. Defaults to Number.

    .PARAMETER RetryIntervalSec
    Specifies the number of seconds to wait for the disk to become available.

    .PARAMETER RetryCount
    The number of times to loop the retry interval while waiting for the disk.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DiskId,

        [Parameter()]
        [ValidateSet('Number','UniqueId','Guid')]
        [System.String]
        $DiskIdType = 'Number',

        [Parameter()]
        [System.UInt32]
        $RetryIntervalSec = 10,

        [Parameter()]
        [System.UInt32]
        $RetryCount = 60
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.CheckingForDiskStatusMessage -f $DiskIdType,$DiskId)
        ) -join '' )

    # Get the Disk using the identifiers supplied
    $disk = Get-DiskByIdentifier `
        -DiskId $DiskId `
        -DiskIdType $DiskIdType

    if ($disk)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($localizedData.DiskFoundMessage -f $DiskIdType,$DiskId,$disk.FriendlyName)
            ) -join '' )

        return $true
    }

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($localizedData.DiskNotFoundMessage -f $DiskIdType,$DiskId)
        ) -join '' )

    return $false
} # function Test-TargetResource

Export-ModuleMember -Function *-TargetResource
