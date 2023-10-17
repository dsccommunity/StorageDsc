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
        This configuration will create a fixed sized virtual disk that is 40Gb in size and will format a
        NTFS volume named 'new volume' that uses the drive letter E. If the folder path in the FilePath
        property does not exist, it will be created.
#>
Configuration VirtualHardDisk_CreateFixedSizedVirtualDisk
{
    Import-DSCResource -ModuleName StorageDsc

    Node localhost
    {
          # Create new virtual disk
          VirtualHardDisk newVhd
          {
            FilePath = 'C:\myVhds\virtDisk1.vhd'
            DiskSize = 40Gb
            DiskFormat = 'Vhd'
            DiskType = 'Fixed'
            Ensure = 'Present'
          }

          # Create new volume onto the new virtual disk
          Disk Volume1
          {
            DiskId = 'C:\myVhds\virtDisk1.vhd'
            DiskIdType = 'Location'
            DriveLetter = 'E'
            FSLabel = 'new volume'
            Size = 20Gb
            DependsOn = '[VirtualHardDisk]newVhd'
          }
    }
}
