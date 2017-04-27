configuration MSFT_xDisk_Config {

    Import-DscResource -ModuleName xStorage

    node localhost {
        if ($Node.Size)
        {
            xDisk Integration_Test {
                DiskId             = $Node.DiskId
                DiskIdType         = $Node.DiskIdType
                DriveLetter        = $Node.DriveLetter
                FSLabel            = $Node.FSLabel
                Size               = $Node.Size
            }
        }
        else
        {
            xDisk Integration_Test {
                DiskId             = $Node.DiskId
                DiskIdType         = $Node.DiskIdType
                DriveLetter        = $Node.DriveLetter
                FSLabel            = $Node.FSLabel
            }
        }
    }
}
