#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_xWaitForDrive.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_xWaitForDrive.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

# Import the common storage functions
Import-Module -Name ( Join-Path `
    -Path (Split-Path -Path $PSScriptRoot -Parent) `
    -ChildPath '\MSFT_xStorageCommon\MSFT_xStorageCommon.psm1' )

<#
    .SYNOPSIS
    Returns the current state of the wait for drive resource.
    .PARAMETER DriveName
    Specifies the name of the drive to wait for.
    .PARAMETER RetryIntervalSec
    Specifies the number of seconds to wait for the drive to become available.
    .PARAMETER RetryCount
    The number of times to loop the retry interval while waiting for the drive.
#>
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [String] $DriveName,

        [UInt32] $RetryIntervalSec = 10,

        [UInt32] $RetryCount = 60
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingWaitForDriveStatusMessage -f $DriveName)
        ) -join '' )

    $returnValue = @{
        DriveName        = $DriveName
        RetryIntervalSec = $RetryIntervalSec
        RetryCount       = $RetryCount
    }
    return $returnValue
} # function Get-TargetResource

<#
    .SYNOPSIS
    Sets the current state of the wait for drive resource.
    .PARAMETER DriveName
    Specifies the name of the drive to wait for.
    .PARAMETER RetryIntervalSec
    Specifies the number of seconds to wait for the drive to become available.
    .PARAMETER RetryCount
    The number of times to loop the retry interval while waiting for the drive.
#>
function Set-TargetResource
{
    param
    (
        [parameter(Mandatory)]
        [String] $DriveName,

        [UInt32] $RetryIntervalSec = 10,

        [UInt32] $RetryCount = 60
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.CheckingForDriveMessage -f $DriveName)
        ) -join '' )

    $driveFound = $false

    for ($count = 0; $count -lt $RetryCount; $count++)
    {
        $drive = Get-PSDrive -Name $DriveName -ErrorAction SilentlyContinue
        if ($drive)
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.DriveFoundMessage -f $DriveName)
                ) -join '' )

            $driveFound = $true
            break
        }
        else
        {
            Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.DriveNotFoundMessage -f $DriveName,$RetryIntervalSec)
                ) -join '' )

            Start-Sleep -Seconds $RetryIntervalSec
        } # if
    } # for

    if (-not $driveFound)
    {
        New-InvalidOperationError `
            -ErrorId 'DriveNotFoundAfterError' `
            -ErrorMessage $($LocalizedData.DriveNotFoundAfterError -f $DriveName,$RetryCount)
    } # if
} # function Set-TargetResource

<#
    .SYNOPSIS
    Tests the current state of the wait for drive resource.
    .PARAMETER DriveName
    Specifies the name of the drive to wait for.
    .PARAMETER RetryIntervalSec
    Specifies the number of seconds to wait for the drive to become available.
    .PARAMETER RetryCount
    The number of times to loop the retry interval while waiting for the drive.
#>
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory)]
        [String] $DriveName,

        [UInt32] $RetryIntervalSec = 10,

        [UInt32] $RetryCount = 60
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.CheckingForDriveMessage -f $DriveNumber)
        ) -join '' )

    $drive = Get-PSDrive -Name $DriveName -ErrorAction SilentlyContinue
    if ($drive)
    {
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.DriveFoundMessage -f $DriveName)
            ) -join '' )

        return $true
    }

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.DriveNotFoundMessage -f $DriveName)
        ) -join '' )

    return $false
} # function Test-TargetResource

Export-ModuleMember -Function *-TargetResource
