# This configuration will wait for disk 2 to become available, and then make the disk available as
# two new formatted volumes, with J using all available space after 'G' has been created.
Configuration DataDisk
{

    Import-DSCResource -ModuleName xStorage

    Node localhost
    {
        xWaitforDisk Disk2
        {
             DiskNumber = 2
             RetryIntervalSec = 60
             Count = 60
        }
        xDisk GVolume
        {
             DiskNumber = 2
             DriveLetter = 'G'
             Size = 10GB
        }

        xDisk JVolume
        {
             DiskNumber = 2
             DriveLetter = 'J'
             FSLabel = 'Data'
             DependsOn = '[xDisk]GVolume'
        }

        xDisk DataVolume
        {
             DiskNumber = 3
             DriveLetter = 'S'
             Size = 100GB
             AllocationUnitSize = 64kb
        }
    }
}

DataDisk -outputpath C:\DataDisk
Start-DscConfiguration -Path C:\DataDisk -Wait -Force -Verbose
