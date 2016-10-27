#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename StorageCommon.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename StorageCommon.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
    .SYNOPSIS
    Throws an InvalidOperation custom exception.

    .PARAMETER ErrorId
    The error Id of the exception.

    .PARAMETER ErrorMessage
    The error message text to set in the exception.
#>
function New-InvalidOperationError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorMessage
    )

    $exception = New-Object -TypeName System.InvalidOperationException `
        -ArgumentList $ErrorMessage
    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
        -ArgumentList $exception, $ErrorId, $errorCategory, $null
    throw $errorRecord
} # end function New-InvalidOperationError

<#
    .SYNOPSIS
    Throws an InvalidArgument custom exception.

    .PARAMETER ErrorId
    The error Id of the exception.

    .PARAMETER ErrorMessage
    The error message text to set in the exception.
#>
function New-InvalidArgumentError
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorMessage
    )

    $exception = New-Object -TypeName System.ArgumentException `
        -ArgumentList $ErrorMessage
    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
        -ArgumentList $exception, $ErrorId, $errorCategory, $null
    throw $errorRecord
} # end function New-InvalidArgumentError

<#
    .SYNOPSIS
    Validates a Drive Letter, removing or adding the trailing colon if required.

    .PARAMETER DriveLetter
    The Drive Letter string to validate.

    .PARAMETER Colon
    Will ensure the returned string will include or exclude a colon.
#>
function Test-DriveLetter
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DriveLetter,

        [Switch]
        $Colon
    )

    $Matches = @([regex]::matches($DriveLetter, '^([A-Za-z]):?$', 'IgnoreCase'))
    if (-not $Matches)
    {
        # DriveLetter format is invalid
        New-InvalidArgumentError `
            -ErrorId 'InvalidDriveLetterFormatError' `
            -ErrorMessage $($LocalizedData.InvalidDriveLetterFormatError -f $DriveLetter)
    }
    # This is the drive letter without a colon
    $DriveLetter = $Matches.Groups[1].Value
    if ($Colon)
    {
        $DriveLetter = $DriveLetter + ':'
    } # if
    return $DriveLetter
} # end function Test-DriveLetter

<#
    .SYNOPSIS
    Validates an Access Path, removing or adding the trailing slash if required.
    If the Access Path does not exist or is not a folder then an exception will
    be thrown.

    .PARAMETER AccessPath
    The Access Path string to validate.

    .PARAMETER Slash
    Will ensure the returned path will include or exclude a slash.
#>
function Test-AccessPath
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AccessPath,

        [Switch]
        $Slash
    )

    if (-not (Test-Path -Path $AccessPath -PathType Container))
    {
        # AccessPath is invalid
        New-InvalidArgumentError `
            -ErrorId 'InvalidAccessPathError' `
            -ErrorMessage $($LocalizedData.InvalidAccessPathError -f $AccessPath)
    } # if

    # Remove or Add the trailing slash
    if($AccessPath.EndsWith('\'))
    {
        if (-not $Slash)
        {
            $AccessPath = $AccessPath.TrimEnd('\')
        } # if
    }
    else
    {
        if ($Slash)
        {
            $AccessPath = "$AccessPath\"
        } # if
    } # if

    return $AccessPath
} # end function Test-AccessPath
