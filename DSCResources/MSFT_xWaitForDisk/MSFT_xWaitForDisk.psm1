#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_xWaitForDisk.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_xWaitForDisk.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

# Import the common storage functions
Import-Module -Name ( Join-Path `
    -Path (Split-Path -Path $PSScriptRoot -Parent) `
    -ChildPath '\StorageCommon\StorageCommon.psm1' )

<#
    .SYNOPSIS
    Returns the current state of the wait for disk resource.

    .PARAMETER DiskNumber
    Specifies the identifier for which disk to wait for.

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
        [parameter(Mandatory)]
        [UInt32] $DiskNumber,

        [UInt32] $RetryIntervalSec = 10,

        [UInt32] $RetryCount = 60
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingWaitForDiskStatusMessage -f $DiskNumber)
        ) -join '' )

    $returnValue = @{
        DiskNumber       = $DiskNumber
        RetryIntervalSec = $RetryIntervalSec
        RetryCount       = $RetryCount
    }
    return $returnValue
} # function Get-TargetResource

<#
    .SYNOPSIS
    Sets the current state of the wait for disk resource.

    .PARAMETER DiskNumber
    Specifies the identifier for which disk to wait for.

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
        [parameter(Mandatory)]
        [UInt32] $DiskNumber,

        [UInt32] $RetryIntervalSec = 10,

        [UInt32] $RetryCount = 60
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.CheckingForDiskMessage -f $DiskNumber)
        ) -join '' )

    $diskFound = $false

    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        $disk = Get-Disk -Number $DiskNumber -ErrorAction SilentlyContinue
        if ($disk)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.DiskFoundMessage -f $DiskNumber,$disk.FriendlyName)
                ) -join '' )

            $diskFound = $true
            break
        }
        else
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.DiskNotFoundMessage -f $DiskNumber,$RetryIntervalSec)
                ) -join '' )

            Start-Sleep -Seconds $RetryIntervalSec
        } # if
    } # for

    if (-not $diskFound)
    {
        New-InvalidOperationError `
            -ErrorId 'DiskNotFoundAfterError' `
            -ErrorMessage $($LocalizedData.DiskNotFoundAfterError -f $DiskNumber,$RetryCount)
    } # if
} # function Set-TargetResource

<#
    .SYNOPSIS
    Tests the current state of the wait for disk resource.

    .PARAMETER DiskNumber
    Specifies the identifier for which disk to wait for.

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
        [parameter(Mandatory)]
        [UInt32] $DiskNumber,

        [UInt32] $RetryIntervalSec = 10,

        [UInt32] $RetryCount = 60
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.CheckingForDiskMessage -f $DiskNumber)
        ) -join '' )

    $disk = Get-Disk -Number $DiskNumber -ErrorAction SilentlyContinue
    if ($disk)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.DiskFoundMessage -f $DiskNumber,$disk.FriendlyName)
            ) -join '' )

        return $true
    }

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.DiskNotFoundMessage -f $DiskNumber)
        ) -join '' )

    return $false
} # function Test-TargetResource

Export-ModuleMember -Function *-TargetResource
