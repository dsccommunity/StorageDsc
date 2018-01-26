<#
    .EXAMPLE
        This configuration will wait for disk 2 with Unique Id '5E1E50A401000000001517FFFF0AEB84' to become
        available, and then make the disk available as two new formatted volumes, 'G' and 'J', with 'J'
        using all available space after 'G' has been created. It also creates a new ReFS formated
        volume on disk 3 with Unique Id '5E1E50A4010000000029AB39450AC9A5' attached as drive letter 'S'.
#>
Configuration Example
{
    Import-DSCResource -ModuleName StorageDsc

    Node localhost
    {
        WaitForDisk Disk2
        {
             DiskId = '5E1E50A401000000001517FFFF0AEB84' # Disk 2
             DiskIdType = 'UniqueId'
             RetryIntervalSec = 60
             RetryCount = 60
        }

        Disk GVolume
        {
             DiskId = '5E1E50A401000000001517FFFF0AEB84' # Disk 2
             DiskIdType = 'UniqueId'
             DriveLetter = 'G'
             Size = 10GB
             DependsOn = '[WaitForDisk]Disk2'
        }

        Disk JVolume
        {
             DiskId = '5E1E50A401000000001517FFFF0AEB84' # Disk 2
             DiskIdType = 'UniqueId'
             DriveLetter = 'J'
             FSLabel = 'Data'
             DependsOn = '[Disk]GVolume'
        }

        WaitForDisk Disk3
        {
             DiskId = '5E1E50A4010000000029AB39450AC9A5' # Disk 3
             DiskIdType = 'UniqueId'
             RetryIntervalSec = 60
             RetryCount = 60
        }

        Disk SVolume
        {
             DiskId = '5E1E50A4010000000029AB39450AC9A5' # Disk 3
             DiskIdType = 'UniqueId'
             DriveLetter = 'S'
             Size = 100GB
             FSFormat = 'ReFS'
             AllocationUnitSize = 64KB
             DependsOn = '[WaitForDisk]Disk3'
        }
    }
}
