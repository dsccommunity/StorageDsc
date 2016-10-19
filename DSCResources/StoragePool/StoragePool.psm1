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
<<<<<<< HEAD
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
=======
    - create a StorageSpace
        needs FriendlyName, NewFriendlyName is omitted, optional DriveSize - if provided - is filterd first, optional NumberOfDisks - if provided - is filtered in the resulting set. Optionally the Ensure value 'Present'.  
    - rename an exisiting StorageSpace
        needs FriendlyName value and NewFriendlyName value. Optionally the Ensure value 'Present'. Further changes may occur depending on other given paramters (see add disk item)
    - add a disk to an existing StorageSpace
        needs FriendlyName and NumberOfDisks, optional is DriveSize - if provided - is filterd first, then NumberOfDisks is filtered in the resulting set. Optionally the Ensure value 'Present'.
    - completely destroy a StoreSpace
        needs FriendlyName value and Ensure value 'Absent'. Ensure value 'Absent' takes precedence over any other parameter. Other parameters are omitted.
    As to https://blogs.msdn.microsoft.com/powershell/2014/11/18/powershell-dsc-resource-design-and-testing-checklist/#_Toc410056135 a DSC resource should have WhatIF functionality as a best practise.
    However, the WhatIf parameter is depricated in WMF 5..... so could not test  
#>
function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName,
>>>>>>> parent of 294b759... removed all WhatIf code

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
<<<<<<< HEAD
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
=======
        $SP = Get-StoragePool -FriendlyName $FriendlyName -ErrorAction SilentlyContinue #Check if storagepool already exists
        
        If (($Ensure -ieq 'Absent') -and ($SP)) {#Removal requested
            #Your wish is our command....destroy the storagepool
            $VD = $SP|Get-VirtualDisk -ErrorAction SilentlyContinue
            $PT = $VD|Get-Partition -ErrorAction SilentlyContinue

            If ([bool]$WhatIfPreference.IsPresent) {
                If ($SP.IsReadOnly -eq $true){$SP|Set-StoragePool -IsReadOnly $false -WhatIf:([bool]$WhatIfPreference.IsPresent)} 
                If ($PT){$PT|Remove-Partition -WhatIf:([bool]$WhatIfPreference.IsPresent)}
                If ($VD){$VD|Remove-VirtualDisk -WhatIf:([bool]$WhatIfPreference.IsPresent)}
                $SP|Remove-StoragePool -WhatIf:([bool]$WhatIfPreference.IsPresent)
                Write-Verbose "StoragePool $($FriendlyName) would have been deleted"
            }
            Else {
                If ($SP.IsReadOnly -eq $true){$SP|Set-StoragePool -IsReadOnly $false} 
                If ($PT){$PT|Remove-Partition -Confirm:$false}
                If ($VD){$VD|Remove-VirtualDisk -Confirm:$false}
                $SP|Remove-StoragePool -Confirm:$false
                Write-Verbose "StoragePool $($FriendlyName) deleted"
                Write-Debug "StoragePool $($FriendlyName) deleted"
            }
            #Takes precedence, do not go further
            return
        }

        If (($Ensure -ieq 'Present') -and (!($SP))) {#No storagepool found, create one
            #Check of enough disks are available
            If ((Get-PhysicalDisk -CanPool $true).Count -lt $NumberOfDisks) {
                Throw 'Not enough disks available.'
            }

            If ($DriveSize -ne 0) {
                $Disks = Get-PhysicalDisk -CanPool $true | Where-Object {$_.Size/1073741824 -eq $DriveSize}
            }
            If ($NumberOfDisks -ne 0) {
                $Disks = Get-PhysicalDisk -CanPool $true|Select-Object -First $NumberOfDisks
>>>>>>> parent of 294b759... removed all WhatIf code
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
<<<<<<< HEAD
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
=======

            If (((Get-WinVersion) -eq [decimal]6.2) -or ((Get-WinVersion) -eq [decimal]6.3)) {$StorageSubSystemUniqueId = (Get-StorageSubSystem -Model 'Storage Spaces').uniqueID}
            If ((Get-WinVersion) -ge [decimal]10.0){$StorageSubSystemUniqueId = (Get-StorageSubSystem -Model 'Windows Storage').uniqueID}

            New-StoragePool -FriendlyName $FriendlyName `
                            -StorageSubSystemUniqueId $StorageSubSystemUniqueId `
                            -PhysicalDisks $Disks #`
                            #-WhatIf:([bool]$WhatIfPreference.IsPresent) # Throws error; WhatIf not supported?!?
            Write-Verbose "StoragePool $($FriendlyName) created with $($Disks) disk(s)"
            Write-Debug "StoragePool $($FriendlyName) created with $($Disks) disk(s)"
            #Take no further action; renaming right after creation would be silly
            return
         }

        If (($Ensure -ieq 'Present') -and ($SP)) {#storagepool found, try to adjust
            #Only expansion and rename is supported right now..
            If ($NumberOfDisks -gt $CheckStoragePool.NumberOfDisks) {
                $ExtraNumberOfDisks = $NumberOfDisks - $CheckStoragePool.NumberOfDisks
                Write-Verbose "Detected $($CheckStoragePool.NumberOfDisks) attached to StoragePool $($FriendlyName)"
                If ($DriveSize -ne 0) {
                    $Disks = Get-PhysicalDisk -CanPool $true | Where-Object {$_.Size/1073741824 -eq $DriveSize} |Select-Object -First $ExtraNumberOfDisks
                }
                Else{
                    $Disks = Get-PhysicalDisk -CanPool $true|Select-Object -First $ExtraNumberOfDisks
                }

                Add-PhysicalDisk -PhysicalDisks $Disks -StoragePoolFriendlyName $FriendlyName -WhatIf:([bool]$WhatIfPreference.IsPresent)
                Write-Verbose "Added $($ExtraNumberOfDisks) disk(s) to StoragePool $($FriendlyName)"
                Write-Debug "Added $($ExtraNumberOfDisks) disk(s) to StoragePool $($FriendlyName)"
            }

            If ($NewFriendlyName) {
                Set-StoragePool -FriendlyName $FriendlyName `
                                -NewFriendlyName $NewFriendlyName `
                                -WhatIf:([bool]$WhatIfPreference.IsPresent)
                Write-Verbose "Renamed StoragePool $($FriendlyName) to $($NewFriendlyName)"
                Write-Debug "Renamed StoragePool $($FriendlyName) to $($NewFriendlyName)"
>>>>>>> parent of 294b759... removed all WhatIf code
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
