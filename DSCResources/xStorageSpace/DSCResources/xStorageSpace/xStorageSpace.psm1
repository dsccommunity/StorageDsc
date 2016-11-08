function Get-TargetResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [String] $FriendlyName

    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.GettingStorageSpace -f $FriendlyName)
        ) -join '' )

    $returnValue = @{
        FriendlyName = $FriendlyName
    }
    return $returnValue
}
function Set-TargetResource {

    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName
    )

        $code = New-StoragePool -FriendlyName $FriendlyName -StorageSubSystemUniqueId (Get-StorageSubSystem -FriendlyName '*Space*').uniqueID -PhysicalDisks (Get-PhysicalDisk -CanPool $true) 
    {
          
    }
}

$code

# The Set-TargetResource function is used to create, delete or configure resources on the target machine.
function Test-TargetResource {
[CmdletBinding()]
   [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName
    )

    try
        {
            $pool = Get-StoragePool -FriendlyName $FriendlyName -ErrorAction Ignore
            if (!$pool) {
                $result = $false
            } else {
                $result = $true
            }
        }
        catch [System.Exception]
        {
            $result = $false
        }

        return $result
     }
   

