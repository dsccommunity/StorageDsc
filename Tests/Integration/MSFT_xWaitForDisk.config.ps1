configuration MSFT_xWaitForDisk_Config {
    Import-DscResource -ModuleName xStorage
    node localhost {
        xWaitForDisk Integration_Test {
            DiskId           = $Node.DiskId
            DiskIdType       = $Node.DiskIdType
            RetryIntervalSec = $Node.RetryIntervalSec
            RetryCount       = $Node.RetryCount
        }
    }
}
