<#
    .EXAMPLE
        This configuration will mount an ISO file as drive S:.
#>
configuration Example
{
    Import-DscResource -ModuleName xStorage
    xMountImage ISO
    {
        ImagePath   = 'c:\Sources\SQL.iso'
        DriveLetter = 'S'
    }

    xWaitForVolume WaitForISO
    {
        DriveLetter      = 'S'
        RetryIntervalSec = 5
        RetryCount       = 10
    }
}
