<#PSScriptInfo
.VERSION 1.0.0
.GUID 3f629ab7-358f-4d82-8c0a-556e32514e3e
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/StorageDsc/blob/main/LICENSE
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
        two new Dev Drive volumes, 'E' and 'F', with 'F' using all available space after 'E' has been
        created.
#>
Configuration Disk_InitializeDiskWithADevDrive
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

        # Will create a Dev Drive of 50Gb requiring the disk to have 50Gb of unallocated space.
        Disk DevDriveVolume1
        {
            DiskId = '5E1E50A401000000001517FFFF0AEB84'
            DiskIdType = 'UniqueId'
            DriveLetter = 'E'
            FSFormat = 'ReFS'
            FSLabel = 'DevDrive'
            DevDrive = $true
            Size = 50Gb
            UseUnallocatedSpace = $true
            DependsOn = '[WaitForDisk]Disk2'
        }

        <#
            Will attempt to create a Dev Drive volume using the rest of the space on the disk assuming
            that the rest of the space is greater than the minimum size for Dev Drive volumes (50Gb).
        #>
        Disk DevDriveVolume2
        {
            DiskId = '5E1E50A401000000001517FFFF0AEB84'
            DiskIdType = 'UniqueId'
            DriveLetter = 'F'
            FSFormat = 'ReFS'
            FSLabel = 'DevDrive'
            DevDrive = $true
            DependsOn = '[Disk]DevDriveVolume1'
        }
    }
}
