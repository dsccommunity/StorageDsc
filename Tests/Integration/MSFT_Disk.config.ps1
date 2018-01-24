configuration MSFT_Disk_Config {

    Import-DscResource -ModuleName StorageDsc

    node localhost {
        if ($Node.Size)
        {
            Disk Integration_Test
            {
                DiskId      = $Node.DiskId
                DiskIdType  = $Node.DiskIdType
                DriveLetter = $Node.DriveLetter
                FSLabel     = $Node.FSLabel
                Size        = $Node.Size
            }
        }
        else
        {
            Disk Integration_Test
            {
                DiskId      = $Node.DiskId
                DiskIdType  = $Node.DiskIdType
                DriveLetter = $Node.DriveLetter
                FSLabel     = $Node.FSLabel
            }
        }
    }
}

configuration MSFT_Disk_ConfigDestructive {

    Import-DscResource -ModuleName StorageDsc

    node localhost {
        if ($Node.Size)
        {
            Disk Integration_Test
            {
                DiskId           = $Node.DiskId
                DiskIdType       = $Node.DiskIdType
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
                DriveLetter      = $Node.DriveLetter
                FSLabel          = $Node.FSLabel
                FSFormat         = $Node.FSFormat
                AllowDestructive = $true
                ClearDisk        = $true
            }
        }
    }
}
