<#PSScriptInfo
.VERSION 1.0.0
.GUID 3f629ab7-358f-4d82-8c0a-556e32514e3e
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/StorageDsc/blob/master/LICENSE
.PROJECTURI https://github.com/dsccommunity/StorageDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module StorageDsc

<#
    .DESCRIPTION
        This configuration will wait for disk 2 to become available, and then make the disk available as
        two new formatted volumes, 'G' and 'J', with 'J' using all available space after 'G' has been
        created. It also creates a new ReFS formated volume on disk 3 attached as drive letter 'S'.
#>
Configuration Disk_InitializeDataDisk
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

        Disk GVolume
        {
             DiskId = 2
             DriveLetter = 'G'
             Size = 10737418240
             DependsOn = '[WaitForDisk]Disk2'
        }

        Disk JVolume
        {
             DiskId = 2
             DriveLetter = 'J'
             FSLabel = 'Data'
             DependsOn = '[Disk]GVolume'
        }

        WaitForDisk Disk3
        {
             DiskId = 3
             RetryIntervalSec = 60
             RetryCount = 60
        }

        Disk SVolume
        {
             DiskId = 3
             DriveLetter = 'S'
             Size = 107374182400
             FSFormat = 'ReFS'
             AllocationUnitSize = 64KB
             DependsOn = '[WaitForDisk]Disk3'
        }
    }
}
