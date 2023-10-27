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
        For this scenario we want to create 2 Non Dev Drive volumes and 2 Dev Drive volumes on a new 1 Tb disk
        (disk 1) with no partitions. The first non Dev Drive volume will be an NTFS volume of 100 Gb called 'Data'.
        The second non Dev Drive volume will be a ReFS volume of 200 Gb called 'Logs'. The first Dev Drive volume
        will be a ReFS volume of 300 Gb called 'Dev Drive 1'. The second Dev Drive volume will be a ReFS volume of
        400 Gb called 'Dev Drive 2'. Note: The Dev Drive volumes will be created after the non Dev Drive volumes are
        created but the order does not matter, we could have created the Dev Drive volumes first and then the non Dev
        Drive volumes or even interleave them. Since this is a new disk and we know there are no existing partitions,
        we do not need to set the 'AllowDestructive' flag for the Dev Drive volumes like in
        3-Disk_CreateDevDriveOnDiskWithExistingPartitions.ps1.

        This configuration below will wait for disk 1 to become available, and then create two new non Dev Drive volumes
        called Data and Logs with Drive letters G and J respectively. The D drive is an NTFS drive and the J drive is an
        ReFS drive. It also create two new Dev Drive volumes which are assigned drive letters K and L respectively.
        The Dev Drive volumes are formatted as ReFS volumes and labeled 'Dev Drive 1' and 'Dev Drive 2' respectively.
#>
Configuration Disk_InitializeDiskWithMultipleDrivesIncludingDevDrives
{
    Import-DSCResource -ModuleName StorageDsc

    Node localhost
    {
        WaitForDisk Disk1
        {
            DiskId = '5E1E50A401000000001517FFFF0AEB81' # Disk 1
            DiskIdType = 'UniqueId'
            RetryIntervalSec = 60
            RetryCount = 60
        }

        # Will create a NTFS volume of 100 Gb called Data.
        Disk DataVolume
        {
            DiskId = '5E1E50A401000000001517FFFF0AEB81'
            DiskIdType = 'UniqueId'
            DriveLetter = 'G'
            FSFormat = 'NTFS'
            FSLabel = 'Data'
            Size = 100Gb
            DependsOn = '[WaitForDisk]Disk1'
        }

        # Will create a ReFS volume of 200 Gb called Logs.
        Disk LogsVolume
        {
            DiskId = '5E1E50A401000000001517FFFF0AEB81'
            DiskIdType = 'UniqueId'
            DriveLetter = 'J'
            FSFormat = 'ReFS'
            FSLabel = 'Logs'
            Size = 200Gb
            DependsOn = '[Disk]DataVolume'
        }

        # Will create a Dev Drive volume of 300 Gb called Dev Drive 1.
        Disk DevDrive1
        {
            DiskId = '5E1E50A401000000001517FFFF0AEB81'
            DiskIdType = 'UniqueId'
            DriveLetter = 'K'
            FSFormat = 'ReFS'
            FSLabel = 'DevDrive 1'
            DevDrive = $true
            Size = 300Gb
            DependsOn = '[Disk]LogsVolume'
        }

        # Will create a Dev Drive volume of 400 Gb called Dev Drive 2.
        Disk DevDrive2
        {
            DiskId = '5E1E50A401000000001517FFFF0AEB81'
            DiskIdType = 'UniqueId'
            DriveLetter = 'L'
            FSFormat = 'ReFS'
            FSLabel = 'DevDrive 2'
            DevDrive = $true
            Size = 400Gb
            DependsOn = '[Disk]DevDrive1'
        }
    }
}
