<#
    .SYNOPSIS
        Compares two values that are in bytes to see whether they are equal when converted to gigabytes.
        We return true if they are equal and false if they are not.

    .PARAMETER SizeAInBytes
        The size of the first value in bytes.

    .PARAMETER SizeBInBytes
        The size of the second value in bytes.
#>
function Compare-SizeUsingGB
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $SizeAInBytes,

        [Parameter(Mandatory = $true)]
        [System.UInt64]
        $SizeBInBytes
    )

    $SizeAInGb = [Math]::Round($SizeAInBytes / 1GB, 2)
    $SizeBInGb = [Math]::Round($SizeBInBytes / 1GB, 2)

    return $SizeAInGb -eq $SizeBInGb

}
