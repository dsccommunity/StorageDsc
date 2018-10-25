configuration MSFTDSC_Disk_Config {

    Import-DscResource -ModuleName StorageDsc

    node localhost {
        if ($Node.Size)
        {
            Disk Integration_Test
            {
                DiskId          = $Node.DiskId
                DiskIdType      = $Node.DiskIdType
                PartitionStyle  = $Node.PartitionStyle
                DriveLetter     = $Node.DriveLetter
                FSLabel         = $Node.FSLabel
                Size            = $Node.Size
            }
        }
        else
        {
            Disk Integration_Test
            {
                DiskId          = $Node.DiskId
                DiskIdType      = $Node.DiskIdType
                PartitionStyle  = $Node.PartitionStyle
                DriveLetter     = $Node.DriveLetter
                FSLabel         = $Node.FSLabel
            }
        }
    }
}

configuration MSFTDSC_Disk_ConfigAllowDestructive {

    Import-DscResource -ModuleName StorageDsc

    node localhost {
        if ($Node.Size)
        {
            Disk Integration_Test
            {
                DiskId           = $Node.DiskId
                DiskIdType       = $Node.DiskIdType
                PartitionStyle   = $Node.PartitionStyle
                DriveLetter      = $Node.DriveLetter
                FSLabel          = $Node.FSLabel
                Size             = $Node.Size
                FSFormat         = $Node.FSFormat
                AllowDestructive = $true
            }
        }
        else
        {
            Disk Integration_Test
            {
                DiskId           = $Node.DiskId
                DiskIdType       = $Node.DiskIdType
                PartitionStyle   = $Node.PartitionStyle
                DriveLetter      = $Node.DriveLetter
                FSLabel          = $Node.FSLabel
                FSFormat         = $Node.FSFormat
                AllowDestructive = $true
            }
        }
    }
}

configuration MSFTDSC_Disk_ConfigClearDisk {

    Import-DscResource -ModuleName StorageDsc

    node localhost {
        if ($Node.Size)
        {
            Disk Integration_Test
            {
                DiskId           = $Node.DiskId
                DiskIdType       = $Node.DiskIdType
                PartitionStyle   = $Node.PartitionStyle
                DriveLetter      = $Node.DriveLetter
                FSLabel          = $Node.FSLabel
                Size             = $Node.Size
                FSFormat         = $Node.FSFormat
                AllowDestructive = $true
                ClearDisk        = $true
            }
        }
        else
        {
            Disk Integration_Test
            {
                DiskId           = $Node.DiskId
                DiskIdType       = $Node.DiskIdType
                PartitionStyle   = $Node.PartitionStyle
                DriveLetter      = $Node.DriveLetter
                FSLabel          = $Node.FSLabel
                FSFormat         = $Node.FSFormat
                AllowDestructive = $true
                ClearDisk        = $true
            }
        }
    }
}
