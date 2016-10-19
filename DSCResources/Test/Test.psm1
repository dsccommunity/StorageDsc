function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [String] $FriendlyName,

        [parameter(Mandatory)]
        [String] $StoragePoolFriendlyName,

        [UInt32] $Size = 0,

        [ValidateSet('Thin','Fixed')]
        [String] $ProvisioningType = 'Fixed',

        [ValidateSet('Simple','Mirror','Parity')]
        [String] $ResiliencySettingName = 'Mirror',

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    If ((Get-WinVersion) -lt [decimal]6.2){
        Throw "VirtualDisk resource only supported in Windows 2012 and up."
    }

    #Check storagepool
    Write-Verbose "Getting info for VirtualDisk $($FriendlyName)."
    $SP = Get-StoragePool -FriendlyName $StoragePoolFriendlyName -ErrorAction SilentlyContinue
    $VD = $SP|Get-VirtualDisk -ErrorAction SilentlyContinue | Where-Object FriendlyName -ieq $FriendlyName

    If ($VD){
        $returnValue = @{
            FriendlyName = $FriendlyName
            StorageSpaceFriendlyName = $StorageSpaceFriendlyName
            Size = ($VD.Size/1073741824)
            ProvisioningType = $VD.ProvisioningType
            ResiliencySettingName = $VD.ResiliencySettingName
            Ensure = 'Present'
        }
    }
    Else{
        $returnValue = @{
            FriendlyName = $FriendlyName
            Ensure = 'Absent'
        }
    }

    $returnValue
}

<#
.Synopsis
The Set-TargetResource function is used to either;
    - create a VirtualDisk
        if size is provided, it will try to create given size. Else is will create a maxiumsize VirtualDisk on designated StoragePool
        if optional DriveSize - if provided - is filterd first, optional NumberOfDisks - if provided - is filtered in the resulting set  
    - completely destroy a VirtualDisk
        needs Ensure value 'Absent'. Ensure value 'Absent' takes precedence over any other parameter. Other parameters are omitted, except mandatory values of course.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [String] $FriendlyName,

        [parameter(Mandatory)]
        [String] $StoragePoolFriendlyName,

        [UInt32] $Size = 0,

        [ValidateSet('Thin','Fixed')]
        [String] $ProvisioningType = 'Fixed',

        [ValidateSet('Simple','Mirror','Parity')]
        [String] $ResiliencySettingName = 'Mirror',

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )
 
    If ((Get-WinVersion) -lt [decimal]6.2){
        Throw "VirtualDisk resource only supported in Windows 2012 and up."
    }

    Try
    {
        $SP = Get-StoragePool -FriendlyName $StoragePoolFriendlyName -ErrorAction Stop
        $VD = $SP|Get-VirtualDisk -ErrorAction SilentlyContinue | Where-Object FriendlyName -ieq $FriendlyName

        If (($Ensure -ieq 'Absent') -and ($VD)) { #Removal requested
            Write-Verbose "Complete removal of VirtualDisk $($FriendlyName) requested"
            Write-Debug "Complete removal of VirtualDisk $($FriendlyName) requested"
            #Your wish is our command....destroy the virtualdisk
            $PT = Get-Disk -ErrorAction SilentlyContinue | Where-Object FriendlyName -ieq $FriendlyName|Get-Partition -ErrorAction SilentlyContinue #improve on this! can result in false results

            If ($SP.IsReadOnly -eq $true){
                $SP|Set-StoragePool -IsReadOnly $false
                Write-Verbose "StoragePool $($StoragePoolFriendlyName) has been set to read/write"
                Write-Debug "StoragePool $($StoragePoolFriendlyName) has been set to read/write"
            }
            If ($PT){
                $PT|Remove-Partition -Confirm:$false
                Write-Verbose "Partition(s) $($PT.DriveLetter) has/have been deleted"
                Write-Debug "Partition(s) $($PT.DriveLetter) has/have been deleted"
            }
            If ($VD){
                $VD|Remove-VirtualDisk -Confirm:$false
                Write-Verbose "VirtualDisk $($FriendlyName) has been deleted"
                Write-Debug "VirtualDisk $($FriendlyName) has been deleted"
            }
            return
        }

        If (($Ensure -ieq 'Present') -and (!($VD))) {#No virtualdisk found, create one
            Write-Verbose "Creation of VirtualDisk $($FriendlyName) requested"
            Write-Debug "Creation of VirtualDisk $($FriendlyName) requested"
            If ($Size -ne 0) {
                New-VirtualDisk -FriendlyName $FriendlyName `
                                -StoragePoolFriendlyName $StoragePoolFriendlyName `
                                -Size $Size*1073741824 `
                                -AutoNumberOfColumns `
                                -AutoWriteCacheSize `
                                -ProvisioningType $ProvisioningType `
                                -ResiliencySettingName $ResiliencySettingName
                Write-Verbose "VirtualDisk $($FriendlyName) has been created on StoragePool $($StoragePoolFriendlyName) with size $Size GB"
                Write-Debug "VirtualDisk $($FriendlyName) has been created on StoragePool $($StoragePoolFriendlyName) with size $Size GB"        
            }
            Else {
                New-VirtualDisk -FriendlyName $FriendlyName `
                                -StoragePoolFriendlyName $StoragePoolFriendlyName `
                                -UseMaximumSize `
                                -AutoNumberOfColumns `
                                -AutoWriteCacheSize `
                                -ProvisioningType $ProvisioningType `
                                -ResiliencySettingName $ResiliencySettingName
                $VD = $SP|Get-VirtualDisk -ErrorAction SilentlyContinue | Where-Object FriendlyName -ieq $FriendlyName
                Write-Verbose "VirtualDisk $($FriendlyName) has been created on StoragePool $($StoragePoolFriendlyName) with size $($VD.Size/1073741824) GB"
                Write-Debug "VirtualDisk $($FriendlyName) has been created on StoragePool $($StoragePoolFriendlyName) with size $($VD.Size/1073741824) GB"
            }
        }
    }
    Catch
    {
        $message = $_.Exception.Message
        Throw "VirtualDisk Set-TargetResource failed with the following error: '$($message)'"
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory)]
        [String] $FriendlyName,

        [parameter(Mandatory)]
        [String] $StoragePoolFriendlyName,

        [UInt32] $Size = 0,

        [ValidateSet('Thin','Fixed')]
        [String] $ProvisioningType = 'Fixed',

        [ValidateSet('Simple','Mirror','Parity')]
        [String] $ResiliencySettingName = 'Mirror',

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    If ((Get-WinVersion) -lt [decimal]6.2){
        Throw "VirtualDisk resource only supported in Windows 2012 and up."
    }

       Write-Verbose "Testing VirtualDisk $($FriendlyName)."

    #Check of virtualdisk already exists
    $CheckVirtualDisk = Get-TargetResource @PSBoundParameters

    If (($Ensure -ieq 'Present') -and ($CheckVirtualDisk.Ensure -ieq 'Absent')) { #No VirtualDisk found
        Write-Debug "No VirtualDisk found. Not consistent."
        Return $false
    } 
        
    If (($Ensure -ieq 'Absent') -and ($CheckVirtualDisk.Ensure -ieq 'Present')) { #Removal requested
        Write-Debug "Removal requested. Not consistent."
        Return $false
    }

    Write-Debug "Resource is consistent."
    Return $true
}

Function Get-WinVersion
{
    #not using Get-CimInstance; older versions of Windows use DCOM. Get-WmiObject works on all, so far...
    $os = (Get-WmiObject -Class Win32_OperatingSystem).Version.Split('.')
    [decimal]($os[0] + "." + $os[1])
}

Export-ModuleMember -Function *-TargetResource
