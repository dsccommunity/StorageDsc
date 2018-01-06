configuration MSFT_xOpticalDiskDriveLetter_config {
    Import-DSCResource -ModuleName xStorage
    node localhost {
        xOpticalDiskDriveLetter Integration_Test {
            IsSingleInstance = 'Yes'
            DriveLetter      = $Node.DriveLetter
        }
    }
}
