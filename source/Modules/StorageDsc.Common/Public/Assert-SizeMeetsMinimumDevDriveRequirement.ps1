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
        throw ($script:localizedData.MinimumSizeNeededToCreateDevDriveVolumeError -f $UserDesiredSizeInGb )
    }

}
