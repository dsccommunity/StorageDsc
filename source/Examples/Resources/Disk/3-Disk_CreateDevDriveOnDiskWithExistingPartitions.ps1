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
        For this scenario we want to create two 60 Gb Dev Drive volumes. We know that disk 2 has 3 existing
        NTFS volumes and we prefer not to remove them. At most we only want the disk DSC resource to shrink any
        of them should there not be enough space for any of the Dev Drive volumes to be created. We also know that the
        the 3 existing volumes are 100Gb, 200Gb and 300Gb in size and disk 2 is 600 Gb in size. Since all the space
        is being used by the existing volumes, The Disk Dsc resource will resize the existing volumes to create
        space for our new Dev Drive volumes. An example of what could happen is the Disk resource could resize the
        300Gb volume to 240Gb for the first Dev Drive volume and then resize the 240Gb volume again to 180Gb for the second.
        Thats just one combination, the disk Dsc resource uses the Get-PartitionSupportedSize cmdlet to know which volume
        can be be resized to a safe size to create enough unallocated space for the Dev Drive volume to be created. Note:
        ReFS volumes cannot be resized, so if the existing volumes were all ReFS volumes, the Disk Dsc resource would not be able
        to resize any volumes and would instead throw an exception.

        This configuration below will wait for disk 2 to become available, and then create two new 60 Gb Dev Drive volumes,
        'E' and 'F'. The volumes will be formatted as ReFS volumes and labeled 'Dev Drive 1' and 'Dev Drive 2' respectively.
        Note: setting 'AllowDestructive' to $true will not cause the disk to be cleared, as the flag is only used when there
        is a need to resize an existing partition. It is used as confirmation that you agree to the resizing which will
        create the necessary space for the Dev Drive volume. This flag is **NOT** needed if you already know there is enough
        unallocated space on the disk to create the Dev Drive volume. If this flag is not used and there is not enough space
        to create the Dev Drive volume an error will be thrown and the Dev Drive will not be created. Its important to be very
        careful not to add the 'ClearDisk' flag while using the 'AllowDestructive' flag, as this will cause the disk to be cleared,
        and all data lost on the disk (even existing volumes).
#>
Configuration Disk_CreateDevDriveOnDiskWithExistingPartitions
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

        # Will create a Dev Drive volume of 60 Gb called Dev Drive 1.
        Disk DevDrive1
        {
            DiskId = '5E1E50A401000000001517FFFF0AEB84'
            DiskIdType = 'UniqueId'
            DriveLetter = 'E'
            FSFormat = 'ReFS'
            FSLabel = 'DevDrive 1'
            DevDrive = $true
            AllowDestructive = $true
            Size = 60Gb
            DependsOn = '[WaitForDisk]Disk2'
        }

        # Will create a Dev Drive volume of 60 Gb called Dev Drive 2.
        Disk DevDrive2
        {
            DiskId = '5E1E50A401000000001517FFFF0AEB84'
            DiskIdType = 'UniqueId'
            DriveLetter = 'F'
            FSFormat = 'ReFS'
            FSLabel = 'DevDrive 2'
            DevDrive = $true
            AllowDestructive = $true
            Size = 60Gb
            DependsOn = '[Disk]DevDrive1'
        }
    }
}
