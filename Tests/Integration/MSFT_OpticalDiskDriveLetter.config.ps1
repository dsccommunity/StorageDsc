configuration MSFT_x\OpticalDiskDriveLetter_config {
    Import-DSCResource -ModuleName StorageDsc
    node localhost {
        OpticalDiskDriveLetter Integration_Test {
            DriveLetter = $Node.DriveLetter
        }
    }
}
