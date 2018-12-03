<#PSScriptInfo
.VERSION 1.0.0
.GUID ddd99b70-781a-4807-9b40-8281d92ed67e
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
        This configuration will set the drive letter of the first
        optical disk drive in the system to 'Y'. It will set the
        drive letter of the second optical disk drive to 'Z'. It
        will remove the drive letter from the third optical disk
        drive in the system.
#>
Configuration OpticalDiskDriveLetter_SetDriveLetterMulti
{
    Import-DSCResource -ModuleName StorageDsc

    Node localhost
    {
        OpticalDiskDriveLetter SetFirstOpticalDiskDriveLetterToY
        {
            DiskId      = 1
            DriveLetter = 'Y'
        }

        OpticalDiskDriveLetter SetSecondOpticalDiskDriveLetterToZ
        {
            DiskId      = 2
            DriveLetter = 'Z'
        }

        OpticalDiskDriveLetter RemoveThirdOpticalDiskDriveLetter
        {
            DiskId      = 3
            DriveLetter = 'A'
            Ensure      = 'Absent'
        }
    }
}
