$TestWaitForVolume = @{
    DriveLetter      = 'C'
    RetryIntervalSec = 1
    RetryCount       = 2
}

configuration MSFT_WaitForVolume_Config {
    Import-DscResource -ModuleName StorageDsc
    node localhost {
        WaitForVolume Integration_Test {
            DriveLetter      = $TestWaitForVolume.DriveLetter
            RetryIntervalSec = $TestWaitForVolume.RetryIntervalSec
            RetryCount       = $TestWaitForVolume.RetryCount
        }
    }
}
