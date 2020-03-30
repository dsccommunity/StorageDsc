configuration MSFT_OpticalDiskDriveLetter_config {
    Import-DSCResource -ModuleName StorageDsc
    node localhost {
        if ($Node.Ensure)
        {
            OpticalDiskDriveLetter Integration_Test {
                DiskId      = $Node.DiskId
                DriveLetter = $Node.DriveLetter
                Ensure      = $Node.Ensure
            }
        }
        else
        {
            OpticalDiskDriveLetter Integration_Test {
                DiskId      = $Node.DiskId
                DriveLetter = $Node.DriveLetter
            }
        }
    }
}
