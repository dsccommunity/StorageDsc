<#
.Synopsis
The Get-TargetResource function is used to fetch the status of StorageSpace on the target machine.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
		[parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName,

        [System.String]
        $NewFriendlyName,

	    [System.UInt32]
		$NumberOfDisks = 0,

        [System.UInt32]
        $DriveSize = 0,

		[ValidateSet('Present','Absent')]
		[System.String]
        $Ensure = 'Present'
    )

	#Check storagepool
	Write-Verbose "Getting info for StoragePool $($FriendlyName)."
	$StoragePoolResult = Get-StoragePool -FriendlyName $FriendlyName -ErrorAction SilentlyContinue
	$DiskResult = $StoragePoolResult | Get-PhysicalDisk -ErrorAction SilentlyContinue

	If ($StoragePoolResult){
		$returnValue = @{
			FriendlyName = [System.String]$FriendlyName
			DriveSize = [System.UInt64]($DiskResult[0].Size/1024/1024/1024)
			NumberOfDisks = [System.UInt32]$DiskResult.Count
			Ensure = 'Present'
		}
	}
	Else{
		$returnValue = @{
			FriendlyName = [System.String]$FriendlyName
			DriveSize = [System.UInt64]0
			NumberOfDisks = [System.UInt32]0
			Ensure = 'Absent'
		}
	}

    $returnValue
}

<#
.Synopsis
The Set-TargetResource function is used to either;
	- create a StorageSpace
		needs FriendlyName value, NewFriendlyName value is omitted, optional DriveSize - if provided - is filterd first, optional NumberOfDisks - if provided - is filtered in the resulting set  
	- rename an exisiting StorageSpace
		needs FriendlyName value and NewFriendlyName value. Optionally the Ensure value 'Present'. Other parameters are omitted
	- completely destroy a StoreSpace
		needs FriendlyName value and Ensure value 'Absent'. Ensure value 'Absent' takes precedence over any other parameter. Other parameters are omitted.
#>
function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
		[parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName,

        [System.String]
        $NewFriendlyName,

	    [System.UInt32]
		$NumberOfDisks = 0,

        [System.UInt32]
        $DriveSize = 0,

		[ValidateSet('Present','Absent')]
		[System.String]
        $Ensure = 'Present'
    )
 
    Write-Verbose 'Creating StoragePool'

	#Check of storagepool already exists
	$CheckStoragePool = Get-TargetResource @PSBoundParameters

	If (($Ensure -ieq 'Absent') -and ($CheckStoragePool.Ensure -ieq 'Present')) {#Removal requested
		Write-Verbose "Complete removal of StoragePool $($FriendlyName) requested"
		Write-Debug "Complete removal of StoragePool $($FriendlyName) requested"
		#Your wish is our command....destroy the storagepool
		$SP = Get-StoragePool -FriendlyName $FriendlyName
		$VD = $SP|Get-VirtualDisk -ErrorAction SilentlyContinue
		$PT = $VD|Get-Partition -ErrorAction SilentlyContinue

		If ($SP.IsReadOnly -eq $true){$SP|Set-StoragePool -IsReadOnly $false -WhatIf:([bool]$WhatIfPreference.IsPresent)} 
		If ($PT){$PT|Remove-Partition -Confirm:$false -WhatIf:([bool]$WhatIfPreference.IsPresent)}
		If ($VD){$VD|Remove-VirtualDisk -Confirm:$false -WhatIf:([bool]$WhatIfPreference.IsPresent)}
		If ([bool]$WhatIfPreference.IsPresent) {
			$SP|Remove-StoragePool -WhatIf:([bool]$WhatIfPreference.IsPresent)
			Write-Verbose "StoragePool $($FriendlyName) would have been deleted"
		}
		Else {
			$SP|Remove-StoragePool -Confirm:$false
			Write-Verbose "StoragePool $($FriendlyName) deleted"
			Write-Debug "StoragePool $($FriendlyName) deleted"
		}
		#Takes precedence, do not go further
		return
	}

	If (($Ensure -ieq 'Present') -and ($CheckStoragePool.Ensure -ieq 'Absent')) {#No storagepool found, create one
		#Check of enough disks are available
		If ((Get-PhysicalDisk -CanPool $true).Count -lt $NumberOfDisks) {
			Throw 'Not enough disks available.'
		}

		If ($DriveSize -ne 0) {
			$Disks = Get-PhysicalDisk -CanPool $true | Where-Object {$_.Size/1024/1024/1024 -eq $DriveSize}
		}
		If ($NumberOfDisks -ne 0) {
			$Disks = Get-PhysicalDisk -CanPool $true|Select-Object -First $NumberOfDisks
		}
		If ($NumberOfDisks -eq 0) {
			$Disks = Get-PhysicalDisk -CanPool $true
		}
		If (($NumberOfDisks -ne 0) -and ($DriveSize -ne 0)) {
			#Select the number of disks to be member of the designated pool
			$Disks = Get-PhysicalDisk -CanPool $true | Where-Object {$_.Size/1024/1024/1024 -eq $DriveSize} | Where-Object {$_.Size/1024/1024/1024 -eq $DriveSize}
		}

    	New-StoragePool -FriendlyName $FriendlyName `
                    	-StorageSubSystemUniqueId (Get-StorageSubSystem -Model 'Windows Storage').uniqueID `
                    	-PhysicalDisks $Disks `
						-WhatIf:([bool]$WhatIfPreference.IsPresent)
 	}
	If (($Ensure -ieq 'Present') -and ($CheckStoragePool.Ensure -ieq 'Present')) {#storagepool found, try to adjust
		#Only expansion and rename is supported right now..
		If ($NumberOfDisks -gt $CheckStoragePool.NumberOfDisks) {
			$ExtraNumberOfDisks = $NumberOfDisks - $CheckStoragePool.NumberOfDisks
			If ($DriveSize -ne 0) {
				$Disks = Get-PhysicalDisk -CanPool $true | Where-Object {$_.Size/1024/1024/1024 -eq $DriveSize} |Select-Object -First $ExtraNumberOfDisks
			}
			Else{
				$Disks = Get-PhysicalDisk -CanPool $true|Select-Object -First $ExtraNumberOfDisks
			}

			Add-PhysicalDisk -PhysicalDisks $Disks -StoragePoolFriendlyName $Name -WhatIf:([bool]$WhatIfPreference.IsPresent)
		}

		If ($NewFriendlyName) {
			Set-StoragePool -FriendlyName $FriendlyName `
							-NewFriendlyName $NewFriendlyName `
							-WhatIf:([bool]$WhatIfPreference.IsPresent)
		}

	}
}



function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
		[parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName,

        [System.String]
        $NewFriendlyName,

	    [System.UInt32]
		$NumberOfDisks = 0,

        [System.UInt32]
        $DriveSize = 0,

		[ValidateSet('Present','Absent')]
		[System.String]
        $Ensure = 'Present'
    )

	Write-Verbose "Testing StoragePool $($FriendlyName)."

	#Check of storagepool already exists
	$CheckStoragePool = Get-TargetResource @PSBoundParameters

	If (($Ensure -ieq 'Present') -and ($CheckStoragePool.Ensure -ieq 'Absent')) { #No storagepool found
		Write-Debug "No StoragePool found. Not consistent."
		Return $false
	} 
		
	If (($Ensure -ieq 'Present') -and ($CheckStoragePool.Ensure -ieq 'Present')){
		If ($NumberOfDisks -gt $CheckStoragePool.NumberOfDisks) { #Disk expansion requested
			Write-Debug "Add disk requested. Not consistent."
			Return $false} 
		If ($NewFriendlyName) { #Rename requested
			Write-Debug "Rename requested. Not consistent."
			Return $false
		} 
	}

	If (($Ensure -ieq 'Absent') -and ($CheckStoragePool.Ensure -ieq 'Present')) { #Removal requested
		Write-Debug "Removal requested. Not consistent."
		Return $false
	}

	Write-Debug "Resource is consistent."
	Return $true
}


Export-ModuleMember -Function *-TargetResource

