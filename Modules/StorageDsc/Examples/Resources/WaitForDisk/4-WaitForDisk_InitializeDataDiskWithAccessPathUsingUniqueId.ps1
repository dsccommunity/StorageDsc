<#
    .EXAMPLE
        This configuration will wait for disk with Unique Id '5E1E50A401000000001517FFFF0AEB84' to become
        available, and then make the disk available as two new formatted volumes mounted to folders
        c:\SQLData and c:\SQLLog, with c:\SQLLog using all available space after c:\SQLData has been created.
#>
Configuration Example
{
    Import-DSCResource -ModuleName StorageDsc

    Node localhost
    {
        WaitForDisk Disk2
        {
             DiskId = '5E1E50A401000000001517FFFF0AEB84'
             DiskIdType = 'UniqueId'
             RetryIntervalSec = 60
             RetryCount = 60
        }

        DiskAccessPath DataVolume
        {
             DiskId = '5E1E50A401000000001517FFFF0AEB84'
             DiskIdType = 'UniqueId'
             AccessPath = 'c:\SQLData'
             Size = 10GB
             FSLabel = 'SQLData1'
             DependsOn = '[WaitForDisk]Disk2'
        }

        DiskAccessPath LogVolume
        {
             DiskId = '5E1E50A401000000001517FFFF0AEB84'
             DiskIdType = 'UniqueId'
             AccessPath = 'c:\SQLLog'
             FSLabel = 'SQLLog1'
             DependsOn = '[DiskAccessPath]DataVolume'
        }
    }
}
