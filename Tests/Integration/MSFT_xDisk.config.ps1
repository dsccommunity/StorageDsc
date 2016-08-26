$TestDisk = [PSObject] @{
    DriveLetter        = $TestDisk.DriveLetter
    FSLabel            = $TestDisk.FSLabel
    AllocationUnitSize = $TestDisk.AllocationUnitSize
}

configuration MSFT_xDisk_Config {
    Import-DscResource -ModuleName xStorage
    node $Node.Name {
        xDisk Integration_Test {
            DiskNumber         = $Node.DiskNumber
            DriveLetter        = $TestDisk.DriveLetter
            FSLabel            = $TestDisk.FSLabel
            AllocationUnitSize = $TestDisk.AllocationUnitSize
        }
    }
}
