<#PSScriptInfo
.VERSION 1.0.0
.GUID f7d8127c-90fa-46ef-8dc7-42667a63f4db
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
        This configuration will remove the drive letter of the first
        optical disk drive.
#>
Configuration OpticalDiskDriveLetter_RemoveDriveLetter
{
    Import-DSCResource -ModuleName StorageDsc

    Node localhost
    {
        OpticalDiskDriveLetter RemoveFirstOpticalDiskDriveLetter
        {
            DiskId      = 1
            DriveLetter = 'X' # This value is ignored
            Ensure      = 'Absent'
        }
    }
}
