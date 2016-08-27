# This configuration will mount a VHD file and wait for it to become available.
configuration Sample_MountVHD
{
    Import-DscResource -ModuleName xStorage
    xMountImage MountVHD
    {
        Name        = 'Data1'
        ImagePath   = 'd:\Data\Disk1.vhdx'
        DriveLetter = 'V'
    }

    xWaitForVolume WaitForVHD
    {
        DriveLetter      = 'V'
        RetryIntervalSec = 5
        RetryCount       = 10
    }
}

Sample_MountVHD
Start-DscConfiguration -Path Sample_MountVHD -Wait -Force -Verbose
