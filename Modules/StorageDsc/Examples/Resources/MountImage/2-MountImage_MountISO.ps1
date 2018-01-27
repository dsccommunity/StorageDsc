<#
    .EXAMPLE
        This configuration will mount an ISO file as drive S:.
#>
configuration Example
{
    Import-DscResource -ModuleName StorageDsc

    MountImage ISO
    {
        ImagePath   = 'c:\Sources\SQL.iso'
        DriveLetter = 'S'
    }

    WaitForVolume WaitForISO
    {
        DriveLetter      = 'S'
        RetryIntervalSec = 5
        RetryCount       = 10
    }
}
