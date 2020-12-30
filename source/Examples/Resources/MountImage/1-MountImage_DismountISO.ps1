<#PSScriptInfo
.VERSION 1.1.0
.GUID 12106838-fad0-44c7-b49f-51bfe7109135
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
        This configuration will unmount the ISO file 'c:\Sources\SQL.iso'
        if mounted as a drive.
#>
configuration MountImage_DismountISO
{
    Import-DscResource -ModuleName StorageDsc

    MountImage ISO
    {
        ImagePath = 'c:\Sources\SQL.iso'
        Ensure = 'Absent'
    }
}
