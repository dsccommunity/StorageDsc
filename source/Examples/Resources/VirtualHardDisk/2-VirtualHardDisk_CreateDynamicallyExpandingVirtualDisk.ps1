<#PSScriptInfo
.VERSION 1.0.0
.GUID 56cbc9fc-4168-4662-9dec-12addcfb82da
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
        This configuration will create a dynamic sized virtual disk that is 40Gb in size and will format a
        RefS volume named 'new volume 2' that uses the drive letter F.
#>
Configuration VirtualHardDisk_CreateDynamicallyExpandingVirtualDisk
{
    Import-DSCResource -ModuleName StorageDsc

    Node localhost
    {
          # Create new virtual disk
          VirtualHardDisk newVhd2
          {
            FilePath = 'C:\myVhds\virtDisk2.vhdx'
            DiskSize = 40Gb
            DiskFormat = 'vhdx'
            DiskType = 'dynamic'
            Ensure = 'Present'
          }

          # Create new volume onto the new virtual disk
          Disk Volume1
          {
            DiskId = 'C:\myVhds\virtDisk2.vhdx'
            DiskIdType = 'Location'
            DriveLetter = 'F'
            FSLabel = 'new volume 2'
            FSFormat = 'ReFS'
            Size = 20Gb
            DependsOn = '[VirtualHardDisk]newVhd2'
          }
    }
}
