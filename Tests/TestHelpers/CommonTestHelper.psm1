<#
    .SYNOPSIS
        Returns an invalid argument exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
function Get-InvalidArgumentRecord
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' -ArgumentList @( $Message,
        $ArgumentName )
    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $argumentException, $ArgumentName, 'InvalidArgument', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
        Returns an invalid operation exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error
#>
function Get-InvalidOperationRecord
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $Message)
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException'
    }
    elseif ($null -eq $ErrorRecord)
    {
        $invalidOperationException =
            New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message )
    }
    else
    {
        $invalidOperationException =
            New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message,
                $ErrorRecord.Exception )
    }

    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $invalidOperationException.ToString(), 'MachineStateIncorrect',
            'InvalidOperation', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
    Creates a new VHD using DISKPART.
    DISKPART is used because New-VHD is only available if Hyper-V is installed.

    .PARAMETER Path
    The path to the VHD file to create.

    .PARAMETER SizeInMB
    The size of the VHD disk to create.

    .PARAMETER Initialize
    Should the disk be initialized? This is for testing matching disks by GUID.
#>
function New-VDisk
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True)]
        [String]
        $Path,

        [Parameter()]
        [Uint32]
        $SizeInMB,

        [Parameter()]
        [Switch]
        $Initialize
    )

    $tempScriptPath = Join-Path -Path $ENV:Temp -ChildPath 'DiskPartVdiskScript.txt'
    Write-Verbose -Message ('Creating DISKPART script {0}' -f $tempScriptPath)

    $diskPartScript = "CREATE VDISK FILE=`"$Path`" TYPE=EXPANDABLE MAXIMUM=$SizeInMB"

    if ($Initialize)
    {
        # The disk will be initialized with GPT (first blank line required because we're adding to existing string)
        $diskPartScript += @"

SELECT VDISK FILE=`"$Path`"
ATTACH VDISK
CONVERT GPT
DETACH VDISK
"@
    }

    Set-Content `
        -Path $tempScriptPath `
        -Value $diskPartScript `
        -Encoding Ascii
    $result = & DISKPART @('/s',$tempScriptPath)
    Write-Verbose -Message ($Result | Out-String)
    $null = Remove-Item -Path $tempScriptPath -Force
} # end function New-VDisk

Export-ModuleMember -Function `
    New-VDisk, `
    Get-InvalidArgumentRecord, `
    Get-InvalidOperationRecord
