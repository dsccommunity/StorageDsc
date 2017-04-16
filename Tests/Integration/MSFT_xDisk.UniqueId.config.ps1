configuration MSFT_xDisk_UniqueId_Config {

    Import-DscResource -ModuleName xStorage

    node localhost {
        xDisk Integration_Test {
            DiskUniqueId       = $Node.DiskUniqueId
            DriveLetter        = $Node.DriveLetter
            FSLabel            = $Node.FSLabel
        }
    }
}
