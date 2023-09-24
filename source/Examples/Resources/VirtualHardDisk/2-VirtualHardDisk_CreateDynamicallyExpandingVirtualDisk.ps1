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
        This configuration will wait for disk 2 with Unique Id '5E1E50A401000000001517FFFF0AEB84' to become
        available, and then make the disk available as two new formatted volumes, 'G' and 'J', with 'J'
        using all available space after 'G' has been created. It also creates a new ReFS formated
        volume on disk 3 with Unique Id '5E1E50A4010000000029AB39450AC9A5' attached as drive letter 'S'.
#>
Configuration VirtualHardDisk_CreateDynamicallyExpandingVirtualDisk
{
    Import-DSCResource -ModuleName StorageDsc


    Node localhost
    {
        # Create new virtual disk
        VirtualHardDisk newVhd
        {
            FolderPath = C:\myVhds
            FileName = myVHD
            DiskSize = 40Gb
            DiskFormat = vhdx
            DiskType = dynamic
        }

        # Create new volume onto the new virtual disk
        Disk Volume1
        {
            DiskId = ‘C:\myVhds\myVHD.vhdx’
            DiskIdType = 'Location'
            DriveLetter = 'E'
            FSLabel = 'new volume'
            Size = 20Gb
            DependsOn = '[VirtualHardDisk]newVhd'
        }
    }
}
