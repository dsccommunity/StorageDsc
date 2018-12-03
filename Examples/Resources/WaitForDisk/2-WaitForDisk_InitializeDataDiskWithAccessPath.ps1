<#PSScriptInfo
.VERSION 1.0.0
.GUID fd2dee3d-0f92-4f7c-8ee3-5d94bd0db380
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/StorageDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/StorageDsc
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
        two new formatted volumes mounted to folders c:\SQLData and c:\SQLLog, with c:\SQLLog using all
        available space after c:\SQLData has been created.
#>
Configuration WaitForDisk_InitializeDataDiskWithAccessPath
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
