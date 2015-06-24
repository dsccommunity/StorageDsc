#
# xComputer: DSC resource to initialize, partition, and format disks.
#

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [uint32] $DiskNumber,
        [string] $DriveLetter,
        [UInt64] $Size,
        [string] $FSLabel
    )

    $Disk = Get-Disk -Number $DiskNumber -ErrorAction SilentlyContinue
    
    $Partition = Get-Partition -DriveLetter $DriveLetter -ErrorAction SilentlyContinue

    $FSLabel = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FileSystemLabel


    $returnValue = @{
        DiskNumber = $Disk.Number
        DriveLetter = $Partition.DriveLetter
        Size = $Partition.Size
        FSLabel = $FSLabel
    }
    $returnValue
}

function Set-TargetResource
{
    param
    (
        [parameter(Mandatory)]
        [uint32] $DiskNumber,
        [string] $DriveLetter,
        [UInt64] $Size,
        [string] $FSLabel
    )
    
    try
    {
        $Disk = Get-Disk -Number $DiskNumber -ErrorAction Stop
    
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
            Throw "Disk '$($DiskNumber)' is already initialised with '$($Disk.PartitionStyle)'"
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
                Write-Verbose -Message "Disk number '$($DiskNumber)' is already configured for 'GPT'"
            }
        }

        Write-Verbose -Message "Creating the partition..."
        if ($DriveLetter -and $Size )
        {
            $Partition = $Disk | New-Partition -DriveLetter $DriveLetter -Size $Size
        }
        elseif ($DriveLetter -and (-not $Size))
        {
            $Partition = $Disk | New-Partition -DriveLetter $DriveLetter -UseMaximumSize
        }
        elseif ($Size -and (-not $DriveLetter))
        {
            $Partition = $Disk | New-Partition -AssignDriveLetter -Size $Size
        }
        else
        {
            $Partition = $Disk | New-Partition -AssignDriveLetter -UseMaximumSize
        }

        # Sometimes the disk will still be read-only after the call to New-Partition returns.
        Start-Sleep -Seconds 5

        Write-Verbose -Message "Formatting the volume..."
        if ($FSLabel)
        {
            $Volume = $Partition | Format-Volume -FileSystem NTFS -NewFileSystemLabel $FSLabel -Confirm:$false 
        }
        else
        {
            $Volume = $Partition | Format-Volume -FileSystem NTFS -Confirm:$false
        }

        Write-Verbose -Message "Successfully initialized disk number '$($DiskNumber)'."
        
        $global:DSCMachineStatus = 1
    }
    catch
    {
        Throw "Disk Set-TargetResource failed with the following error: '$($Error[0])'"
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory)]
        [uint32] $DiskNumber,
        [string] $DriveLetter,
        [UInt64] $Size,
        [string] $FSLabel
    )

    Write-Verbose -Message "Checking if disk number '$($DiskNumber)' is initialized..."
    $Disk = Get-Disk -Number $DiskNumber -ErrorAction SilentlyContinue

    if (-not $Disk)
    {
        Write-Error "Disk number '$($DiskNumber)' does not exist."
        return $false
    }

    if ($Disk.IsOffline -eq $true)
    {
        Write-Error 'Disk is not Online'
        return $false
    }
    
    if ($Disk.IsReadOnly -eq $true)
    {
        Write-Error 'Disk set as ReadOnly'
        return $false
    }

    if ($Disk.PartitionStyle -ne "GPT")
    {
        Write-Error "Disk '$($DiskNumber)' is initialised with '$($Disk.PartitionStyle)' partition style"
        return $false
    }

    # DriveLetter
    if ($DriveLetter)
    {
        $Partition = Get-Partition -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
        if ( -not $Partition)
        {
            Write-Error "Drive $DriveLetter was not found"
        }    return $false
    }

    # Drive size
    if ($Size)
    {
        if ($Partition.Size -ne $Size)
        {
            Write-Error "Drive $DriveLetter size does not match defined value"
            return $false
        }
    }

    # Volume label
    if ($FSLabel)
    {
        $Label = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FileSystemLabel
        if ($Label -ne $FSLabel)
        {
            Write-Error "Volume $DriveLetter label does not match defined value"
            return $false
        }
    }

    return $true
}


Export-ModuleMember -Function *-TargetResource

