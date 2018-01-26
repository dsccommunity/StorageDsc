<#
    .EXAMPLE
        This configuration will wait for disk 2 to become available, and then make the disk available as
        two new formatted volumes mounted to folders c:\SQLData and c:\SQLLog, with c:\SQLLog using all
        available space after c:\SQLData has been created.
#>
Configuration Example
{
    Import-DSCResource -ModuleName StorageDsc

    Node localhost
    {
        WaitForDisk Disk2
        {
             DiskId = 2
             RetryIntervalSec = 60
             RetryCount = 60
        }

        DiskAccessPath DataVolume
        {
             DiskId = 2
             AccessPath = 'c:\SQLData'
             Size = 10GB
             FSLabel = 'SQLData1'
             DependsOn = '[WaitForDisk]Disk2'
        }

        DiskAccessPath LogVolume
        {
             DiskId = 2
             AccessPath = 'c:\SQLLog'
             FSLabel = 'SQLLog1'
             DependsOn = '[DiskAccessPath]DataVolume'
        }
    }
}
