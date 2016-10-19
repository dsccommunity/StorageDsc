#
# xDisk: DSC resource to initialize, partition, and format disks.
#

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [UInt32] $DiskNumber,

		[String] $DiskFriendlyName,

        [parameter(Mandatory)]
        [string] $DriveLetter,

        [UInt64] $Size,
        [string] $FSLabel,
        [UInt32] $AllocationUnitSize
    )

	If ((Get-WinVersion) -lt [decimal]6.2){
		Throw "xDisk resource only supported in Windows 2012 and up."
	}
	If (($DiskNumber) -and ($DiskFriendlyName)){
		Throw "DiskNumber and DiskFriendlyName cannot be used together. Please delete one parameter depending on wanted function in configuration."
	}
	If ($DiskNumber){$Disk = Get-Disk -Number $DiskNumber -ErrorAction SilentlyContinue}
	If ($DiskFriendlyName){

		IIf (((Get-WinVersion) -eq [decimal]6.2) -or ((Get-WinVersion) -eq [decimal]6.3)) {
			$Disk = Get-Disk -UniqueId ((Get-VirtualDisk -FriendlyName $DiskFriendlyName).UniqueId) -ErrorAction SilentlyContinue
		}
		If ((Get-WinVersion) -ge [decimal]10.0){
			$Disk = Get-Disk -FriendlyName $DiskFriendlyName -ErrorAction SilentlyContinue
		}
	}
	If (!($DiskNumber) -and !($DiskFriendlyName)){
		Throw "DiskNumber or DiskFriendlyName parameter required. Please add parameter in configuration."
	}

    $Partition = Get-Partition -DriveLetter $DriveLetter -ErrorAction SilentlyContinue

    $FSLabel = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FileSystemLabel

    $BlockSize = Get-CimInstance -Query "SELECT BlockSize from Win32_Volume WHERE DriveLetter = '$($DriveLetter):'" -ErrorAction SilentlyContinue | select -ExpandProperty BlockSize
    
    if($BlockSize){
        $AllocationUnitSize = $BlockSize
    } else {
        # If Get-CimInstance did not return a value, try again with Get-WmiObject
        $BlockSize = Get-WmiObject -Query "SELECT BlockSize from Win32_Volume WHERE DriveLetter = '$($DriveLetter):'" -ErrorAction SilentlyContinue | select -ExpandProperty BlockSize
        $AllocationUnitSize = $BlockSize
    }

    $returnValue = @{
        DiskNumber = $Disk.Number
        DriveLetter = $Partition.DriveLetter
        Size = $Partition.Size
        FSLabel = $FSLabel
        AllocationUnitSize = $AllocationUnitSize
    }
    $returnValue
}

function Set-TargetResource
{
    param
    (
        [UInt32] $DiskNumber,

		[String] $DiskFriendlyName,

        [parameter(Mandatory)]
        [string] $DriveLetter,

        [UInt64] $Size,
        [string] $FSLabel,
        [UInt32] $AllocationUnitSize
    )
    
	If ((Get-WinVersion) -lt [decimal]6.2){
		Throw "xDisk resource only supported in Windows 2012 and up."
	}
    try
    {
		If (($DiskNumber) -and ($DiskFriendlyName)){
			Throw "DiskNumber and DiskFriendlyName cannot be used together. Please delete one parameter depending on wanted function in configuration."
		}
		If ($DiskNumber){$Disk = Get-Disk -Number $DiskNumber -ErrorAction Stop}
		If ($DiskFriendlyName){
			If (((Get-WinVersion) -eq [decimal]6.2) -or ((Get-WinVersion) -eq [decimal]6.3)) {
				$Disk = Get-Disk -UniqueId ((Get-VirtualDisk -FriendlyName $DiskFriendlyName).UniqueId) -ErrorAction Stop
			}
			If ((Get-WinVersion) -ge [decimal]10.0){
				$Disk = Get-Disk -FriendlyName $DiskFriendlyName -ErrorAction Stop
			}
		}
		If (!($DiskNumber) -and !($DiskFriendlyName)){
			Throw "DiskNumber or DiskFriendlyName parameter required. Please add parameter in configuration."
		}

        if ($Disk.IsOffline -eq $true)
        {
            Write-Verbose 'Setting disk Online'
            $Disk | Set-Disk -IsOffline $false
        }
        
        if ($Disk.IsReadOnly -eq $true)
        {
            Write-Verbose 'Setting disk to not ReadOnly'
            $Disk | Set-Disk -IsReadOnly $false
        }

        Write-Verbose -Message "Checking existing disk partition style..."
        if (($Disk.PartitionStyle -ne "GPT") -and ($Disk.PartitionStyle -ne "RAW"))
        {
            Throw "Disk number '$($DiskNumber)' is already initialised with '$($Disk.PartitionStyle)'"
        }
        else
        {
            if ($Disk.PartitionStyle -eq "RAW")
            {
                Write-Verbose -Message "Initializing disk number '$($DiskNumber)'..."
                $Disk | Initialize-Disk -PartitionStyle "GPT" -PassThru
            }
            else
            {
                Write-Verbose -Message "Disk '$($Disk)' is already configured for 'GPT'"
            }
        }

        # Check if existing partition already has file system on it
        
        if (($Disk | Get-Partition | Get-Volume ) -eq $null)
        {


            Write-Verbose -Message "Creating the partition..."
            $PartParams = @{
                            DriveLetter = $DriveLetter;
							DiskNumber = $Disk.Number
                            }

            if ($Size)
            {
                $PartParams["Size"] = $Size
            }
            else
            {
                $PartParams["UseMaximumSize"] = $true
            }

            $Partition = New-Partition @PartParams
            
            # Sometimes the disk will still be read-only after the call to New-Partition returns.
            Start-Sleep -Seconds 5

            Write-Verbose -Message "Formatting the volume..."
            $VolParams = @{
                        FileSystem = "NTFS";
                        Confirm = $false
                        }

            if ($FSLabel)
            {
                $VolParams["NewFileSystemLabel"] = $FSLabel
            }
            if($AllocationUnitSize)
            {
                $VolParams["AllocationUnitSize"] = $AllocationUnitSize 
            }

            $Volume = $Partition | Format-Volume @VolParams


            if ($Volume)
            {
                Write-Verbose -Message "Successfully initialized '$($DriveLetter)'."
            }
        }
        else 
        {
            $Volume = ($Disk | Get-Partition | Get-Volume)

            if ($Volume.DriveLetter)
            {
                if($Volume.DriveLetter -ne $DriveLetter)
                {
                    Write-Verbose -Message "The volume already exists, adjusting drive letter..."
                    Set-Partition -DriveLetter $Volume.DriveLetter -NewDriveLetter $DriveLetter
                }
            }
            else
            {
                # volume doesn't have an assigned letter
                Write-Verbose -Message "Assigning drive letter..."
				Set-Partition -DiskNumber $DiskNumber -PartitionNumber 2 -NewDriveLetter $DriveLetter
            }

            if($PSBoundParameters.ContainsKey('FSLabel'))
            {
                if($Volume.FileSystemLabel -ne $FSLabel)
                {
                    Write-Verbose -Message "Changing volume '$($Volume.DriveLetter)' label to $FsLabel"
                    $Volume | Set-Volume -NewFileSystemLabel $FSLabel
                }
            }
        }
    }    
    catch
    {
        $message = $_.Exception.Message
        Throw "Disk Set-TargetResource failed with the following error: '$($message)'"
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    [cmdletbinding()]
    param
    (
        [UInt32] $DiskNumber,

		[String] $DiskFriendlyName,

        [parameter(Mandatory)]
        [string] $DriveLetter,

        [UInt64] $Size,
        [string] $FSLabel,
        [UInt32] $AllocationUnitSize
    )

	If ((Get-WinVersion) -lt [decimal]6.2){
		Throw "xDisk resource only supported in Windows 2012 and up."
	}
	If (($DiskNumber) -and ($DiskFriendlyName)){
		Throw "DiskNumber and DiskFriendlyName cannot be used together. Please delete one parameter depending on wanted function in configuration."
	}
	If ($DiskNumber){$Disk = Get-Disk -Number $DiskNumber -ErrorAction SilentlyContinue}
	If ($DiskFriendlyName){
		If ((Get-WinVersion) -lt [decimal]6.2){
			Throw "DiskFriendlyName parameter only supported in Windows 2012 and up. Please delete parameter in configuration"
		}
		If (((Get-WinVersion) -eq [decimal]6.2) -or ((Get-WinVersion) -eq [decimal]6.3)) {
			$Disk = Get-Disk -UniqueId ((Get-VirtualDisk -FriendlyName $DiskFriendlyName).UniqueId) -ErrorAction SilentlyContinue
		}
		If ((Get-WinVersion) -ge [decimal]10.0){
			$Disk = Get-Disk -FriendlyName $DiskFriendlyName -ErrorAction SilentlyContinue
		}
	}
	If (!($DiskNumber) -and !($DiskFriendlyName)){
		Throw "DiskNumber or DiskFriendlyName parameter required. Please add parameter in configuration."
	}

    Write-Verbose -Message "Checking if disk number '$($DiskNumber)' is initialized..."

    if (-not $Disk)
    {
        Write-Verbose "Disk number '$($DiskNumber)' was not found."
        return $false
    }

    if ($Disk.IsOffline -eq $true)
    {
        Write-Verbose 'Disk is not Online'
        return $false
    }
    
    if ($Disk.IsReadOnly -eq $true)
    {
        Write-Verbose 'Disk set as ReadOnly'
        return $false
    }

    if ($Disk.PartitionStyle -ne "GPT")
    {
        Write-Verbose "Disk number '$($Disk.Number)' is initialised with '$($Disk.PartitionStyle)' partition style"
        return $false
    }

    $Partition = Get-Partition -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
    if (-not $Partition.DriveLetter -eq $DriveLetter)
    {
        Write-Verbose "Drive $DriveLetter was not found"
        return $false
    }

    # Drive size
    if ($Size)
    {
        if ($Partition.Size -ne $Size)
        {
            Write-Verbose "Drive $DriveLetter size does not match expected value. Current: $($Partition.Size) Expected: $Size"
            return $false
        }
    }

    $BlockSize = Get-CimInstance -Query "SELECT BlockSize from Win32_Volume WHERE DriveLetter = '$($DriveLetter):'" -ErrorAction SilentlyContinue  | select -ExpandProperty BlockSize
    if (-not($BlockSize)){
        # If Get-CimInstance did not return a value, try again with Get-WmiObject
        $BlockSize = Get-WmiObject -Query "SELECT BlockSize from Win32_Volume WHERE DriveLetter = '$($DriveLetter):'" -ErrorAction SilentlyContinue  | select -ExpandProperty BlockSize
    }

    if($BlockSize -gt 0 -and $AllocationUnitSize -ne 0)
    {
        if($AllocationUnitSize -ne $BlockSize)
        {
            # Just write a warning, we will not try to reformat a drive due to invalid allocation unit sizes
            Write-Verbose "Drive $DriveLetter allocation unit size does not match expected value. Current: $($BlockSize.BlockSize/1kb)kb Expected: $($AllocationUnitSize/1kb)kb"
        }    
    }

    # Volume label
    if (-not [string]::IsNullOrEmpty($FSLabel))
    {
        $Label = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FileSystemLabel
        if ($Label -ne $FSLabel)
        {
            Write-Verbose "Volume $DriveLetter label does not match expected value. Current: $Label Expected: $FSLabel)"
            return $false
        }
    }

    return $true
}

Function Get-WinVersion
{
    #not using Get-CimInstance; older versions of Windows use DCOM. Get-WmiObject works on all, so far...
    $os = (Get-WmiObject -Class Win32_OperatingSystem).Version.Split('.')
    [decimal]($os[0] + "." + $os[1])
}

Export-ModuleMember -Function *-TargetResource
