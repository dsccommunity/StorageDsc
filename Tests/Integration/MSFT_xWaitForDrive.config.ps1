$TestWaitForDrive = [PSObject] @{
    DriveName        = 'C'
    RetryIntervalSec = 1
    RetryCount       = 2
}

configuration MSFT_xWaitForDrive_Config {
    Import-DscResource -ModuleName xStorage
    node localhost {
        xWaitForDrive Integration_Test {
            DriveName        = $TestWaitForDrive.DriveName
            RetryIntervalSec = $TestWaitForDrive.RetryIntervalSec
            RetryCount       = $TestWaitForDrive.RetryCount
        }
    }
}
