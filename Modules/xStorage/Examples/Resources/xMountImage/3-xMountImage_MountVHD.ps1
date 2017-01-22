<#
    .EXAMPLE
        This configuration will mount a VHD file and wait for it to become available.
#>
configuration Example
{
    Import-DscResource -ModuleName xStorage
    xMountImage MountVHD
    {
        ImagePath   = 'd:\Data\Disk1.vhd'
        DriveLetter = 'V'
    }

    xWaitForVolume WaitForVHD
    {
        DriveLetter      = 'V'
        RetryIntervalSec = 5
        RetryCount       = 10
    }
}
