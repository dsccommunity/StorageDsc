configuration MSFT_xDisk_Config {

    Import-DscResource -ModuleName xStorage

    node localhost {
        if ($Node.Size)
        {
            xDisk Integration_Test
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
            xDisk Integration_Test
            {
                DiskId      = $Node.DiskId
                DiskIdType  = $Node.DiskIdType
                DriveLetter = $Node.DriveLetter
                FSLabel     = $Node.FSLabel
            }
        }
    }
}

configuration MSFT_xDisk_ConfigDestructive {

    Import-DscResource -ModuleName xStorage

    node localhost {
        if ($Node.Size)
        {
            xDisk Integration_Test
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
            xDisk Integration_Test
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
