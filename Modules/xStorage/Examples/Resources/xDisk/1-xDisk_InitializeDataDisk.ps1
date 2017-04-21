<#
    .EXAMPLE
        This configuration will wait for disk 2 to become available, and then make the disk available as
        two new formatted volumes, 'G' and 'J', with 'J' using all available space after 'G' has been
        created. It also creates a new ReFS formated volume on Disk 3 attached as drive letter 'S'.
#>
Configuration Example
{

    Import-DSCResource -ModuleName xStorage

    Node localhost
    {
        xWaitforDisk Disk2
        {
             DiskId = 2
             RetryIntervalSec = 60
             RetryCount = 60
        }

        xDisk GVolume
        {
             DiskId = 2
             DriveLetter = 'G'
             Size = 10GB
        }

        xDisk JVolume
        {
             DiskId = 2
             DriveLetter = 'J'
             FSLabel = 'Data'
             DependsOn = '[xDisk]GVolume'
        }

        xDisk DataVolume
        {
             DiskId = 3
             DriveLetter = 'S'
             Size = 100GB
             FSFormat = 'ReFS'
             AllocationUnitSize = 64KB
        }
    }
}
