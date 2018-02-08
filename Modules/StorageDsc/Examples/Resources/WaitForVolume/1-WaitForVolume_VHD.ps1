<#
    .EXAMPLE
        This configuration will mount a VHD file and wait for it to become available.
#>
configuration Example
{
    Import-DscResource -ModuleName StorageDsc

    MountImage MountVHD
    {
        ImagePath   = 'd:\Data\Disk1.vhd'
        DriveLetter = 'V'
    }

    WaitForVolume WaitForVHD
    {
        DriveLetter      = 'V'
        RetryIntervalSec = 5
        RetryCount       = 10
    }
}
