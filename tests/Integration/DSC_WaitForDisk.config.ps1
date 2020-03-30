configuration DSC_WaitForDisk_Config {
    Import-DscResource -ModuleName StorageDsc
    node localhost {
        WaitForDisk Integration_Test {
            DiskId           = $Node.DiskId
            DiskIdType       = $Node.DiskIdType
            RetryIntervalSec = $Node.RetryIntervalSec
            RetryCount       = $Node.RetryCount
        }
    }
}
