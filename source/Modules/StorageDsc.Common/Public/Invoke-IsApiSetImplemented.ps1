<#
    .SYNOPSIS
        Invokes win32 IsApiSetImplemented function.

    .PARAMETER Contract
        Specifies the contract string for the dll that houses the win32 function.
#>
function Invoke-IsApiSetImplemented
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
} # end function Invoke-IsApiSetImplemented

<#
    .SYNOPSIS
        Invokes win32 GetDeveloperDriveEnablementState function.
#>
function Get-DevDriveEnablementState
{
    [CmdletBinding()]
    [OutputType([System.Enum])]
    param
    ()

    $helper = Get-DevDriveWin32HelperScript
    return $helper::GetDeveloperDriveEnablementState()
}
