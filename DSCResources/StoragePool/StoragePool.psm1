function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory)]
        [String] $FriendlyName,

        [String] $NewFriendlyName,

        [UInt32] $NumberOfDisks = 0,

        [UInt32] $DriveSize = 0,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    If ((Get-WinVersion) -lt [decimal]6.2){
        Throw "StoragePool resource only supported in Windows 2012 and up."
    }

    #Check storagepool
    Write-Verbose "Getting info for StoragePool $($FriendlyName)."
    $SP = Get-StoragePool -FriendlyName $FriendlyName -ErrorAction SilentlyContinue
    $PD = $SP | Get-PhysicalDisk -ErrorAction SilentlyContinue

    If ($SP){
        $returnValue = @{
            FriendlyName = $FriendlyName
            DriveSize = ($SP.AlllocatedSize/@($PD).Count/1073741824) # Average on total disks
            NumberOfDisks = @($PD).Count
            Ensure = 'Present'
            #Add total size and available?
        }
    }
    Else{
        $returnValue = @{
            FriendlyName = $FriendlyName
            Ensure = 'Absent'
        }
    }
    Write-Verbose "Detected DriveSize = $($returnValue.DriveSize)"
    Write-Verbose "Detected NumberOfDisks = $($returnValue.NumberOfDisks)"
    Write-Verbose "Detected Ensure = $($returnValue.Ensure)"
    $returnValue
}

<#
.Synopsis
The Set-TargetResource function is used to either;
    - create a StorageSpace
        needs FriendlyName, NewFriendlyName is omitted, optional DriveSize - if provided - is filterd first, optional NumberOfDisks - if provided - is filtered in the resulting set. Optionally the Ensure value 'Present'.  
    - rename an exisiting StorageSpace
        needs FriendlyName value and NewFriendlyName value. Optionally the Ensure value 'Present'. Further changes may occur depending on other given paramters (see add disk item)
    - add a disk to an existing StorageSpace
        needs FriendlyName and NumberOfDisks, optional is DriveSize - if provided - is filterd first, then NumberOfDisks is filtered in the resulting set. Optionally the Ensure value 'Present'.
    - completely destroy a StoreSpace
        needs FriendlyName value and Ensure value 'Absent'. Ensure value 'Absent' takes precedence over any other parameter. Other parameters are omitted.
    As to https://blogs.msdn.microsoft.com/powershell/2014/11/18/powershell-dsc-resource-design-and-testing-checklist/#_Toc410056135 a DSC resource should have WhatIF functionality as a best practise.
    However, the WhatIf parameter is depricated in WMF 5..... so could not test and deleted code
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [String] $FriendlyName,

        [String] $NewFriendlyName,

        [UInt32] $NumberOfDisks = 0,

        [UInt32] $DriveSize = 0,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    If ((Get-WinVersion) -lt [decimal]6.2){
        Throw "StoragePool resource only supported in Windows 2012 and up."
    }

   Try
    {
        $SP = Get-StoragePool -FriendlyName $FriendlyName -ErrorAction SilentlyContinue #Check if storagepool already exists
        
        If (($Ensure -ieq 'Absent') -and ($SP)) {#Removal requested
            #Your wish is our command....destroy the storagepool
            $VD = $SP|Get-VirtualDisk -ErrorAction SilentlyContinue
            $PT = $VD|Get-Partition -ErrorAction SilentlyContinue

            If ($SP.IsReadOnly -eq $true){$SP|Set-StoragePool -IsReadOnly $false} 
            If ($PT){$PT|Remove-Partition -Confirm:$false}
            If ($VD){$VD|Remove-VirtualDisk -Confirm:$false}
            $SP|Remove-StoragePool -Confirm:$false
            Write-Verbose "StoragePool $($FriendlyName) deleted"
            Write-Debug "StoragePool $($FriendlyName) deleted"

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
            }
            If ($NumberOfDisks -eq 0) {
                $Disks = Get-PhysicalDisk -CanPool $true
            }
            If (($NumberOfDisks -ne 0) -and ($DriveSize -ne 0)) {
                #Select the number of disks to be member of the designated pool
                $Disks = Get-PhysicalDisk -CanPool $true | Where-Object {$_.Size/1073741824 -eq $DriveSize} | Where-Object {$_.Size/1073741824 -eq $DriveSize}
            }

            If (((Get-WinVersion) -eq [decimal]6.2) -or ((Get-WinVersion) -eq [decimal]6.3)) {$StorageSubSystemUniqueId = (Get-StorageSubSystem -Model 'Storage Spaces').uniqueID}
            If ((Get-WinVersion) -ge [decimal]10.0){$StorageSubSystemUniqueId = (Get-StorageSubSystem -Model 'Windows Storage').uniqueID}

            New-StoragePool -FriendlyName $FriendlyName `
                            -StorageSubSystemUniqueId $StorageSubSystemUniqueId `
                            -PhysicalDisks $Disks
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

                Add-PhysicalDisk -PhysicalDisks $Disks -StoragePoolFriendlyName $FriendlyName
                Write-Verbose "Added $($ExtraNumberOfDisks) disk(s) to StoragePool $($FriendlyName)"
                Write-Debug "Added $($ExtraNumberOfDisks) disk(s) to StoragePool $($FriendlyName)"
            }

            If ($NewFriendlyName) {
                Set-StoragePool -FriendlyName $FriendlyName `
                                -NewFriendlyName $NewFriendlyName
                Write-Verbose "Renamed StoragePool $($FriendlyName) to $($NewFriendlyName)"
                Write-Debug "Renamed StoragePool $($FriendlyName) to $($NewFriendlyName)"
            }
        }
    }
    Catch
    {
        $message = $_.Exception.Message
        Throw "StoragePool Set-TargetResource failed with the following error: '$($message)'"
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory)]
        [String] $FriendlyName,

        [String] $NewFriendlyName,

        [UInt32] $NumberOfDisks = 0,

        [UInt32] $DriveSize = 0,

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    If ((Get-WinVersion) -lt [decimal]6.2){
        Throw "StoragePool resource only supported in Windows 2012 and up."
    }

    Write-Verbose "Testing StoragePool $($FriendlyName)."

    #Check of storagepool already exists
    $CheckStoragePool = Get-TargetResource @PSBoundParameters

    If (($Ensure -ieq 'Present') -and ($CheckStoragePool.Ensure -ieq 'Absent')) { #No storagepool found
        Write-Verbose "No StoragePool found. Not consistent."
        Write-Debug "No StoragePool found. Not consistent."

        Return $false
    } 
        
    If (($Ensure -ieq 'Present') -and ($CheckStoragePool.Ensure -ieq 'Present')){
        If ($NumberOfDisks -gt $CheckStoragePool.NumberOfDisks) { #Disk expansion requested
            Write-Verbose "Add disk requested. Not consistent."
            Write-Debug "Add disk requested. Not consistent."
            Return $false} 
        If ($NumberOfDisks -lt $CheckStoragePool.NumberOfDisks) { #Disk deletetion requested
            Write-Verbose "Remove disk requested. Not consistent. Not able to comply; function NOT implemented"
            Write-Debug "Remove disk requested. Not consistent. Not able to comply; function NOT implemented"
            Return $true} 
        If ($NewFriendlyName) { #Rename requested
            Write-Verbose "Rename requested. Not consistent."
            Write-Debug "Rename requested. Not consistent."
            Return $false
        } 
    }

    If (($Ensure -ieq 'Absent') -and ($CheckStoragePool.Ensure -ieq 'Present')) { #Removal requested
        Write-Verbose "Removal requested. Not consistent."
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