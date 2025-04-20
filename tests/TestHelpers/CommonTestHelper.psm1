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
    $result = & DISKPART @('/s', $tempScriptPath)
    Write-Verbose -Message ($Result | Out-String)
    $null = Remove-Item -Path $tempScriptPath -Force
} # end function New-VDisk

Export-ModuleMember -Function New-VDisk
