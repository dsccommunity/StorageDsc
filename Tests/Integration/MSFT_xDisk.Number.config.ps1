configuration MSFT_xDisk_Number_Config {

    Import-DscResource -ModuleName xStorage

    node localhost {
        xDisk Integration_Test {
            DiskNumber         = $Node.DiskNumber
            DriveLetter        = $Node.DriveLetter
            FSLabel            = $Node.FSLabel
        }
    }
}
