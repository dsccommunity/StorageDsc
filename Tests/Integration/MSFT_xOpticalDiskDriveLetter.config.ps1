configuration MSFT_xOpticalDiskDriveLetter_config {
    Import-DSCResource -ModuleName xStorage
    node localhost {
        if ($Node.Ensure)
        {
            xOpticalDiskDriveLetter Integration_Test {
                DiskId      = $Node.DiskId
                DriveLetter = $Node.DriveLetter
                Ensure      = $Node.Ensure
            }
        }
        else
        {
            xOpticalDiskDriveLetter Integration_Test {
                DiskId      = $Node.DiskId
                DriveLetter = $Node.DriveLetter
            }
        }
    }
}
