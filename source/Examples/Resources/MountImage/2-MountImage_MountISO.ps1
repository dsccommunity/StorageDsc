<#PSScriptInfo
.VERSION 1.0.0
.GUID 73bdd44d-4944-4217-a5ba-4f63948a1376
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/StorageDsc/blob/master/LICENSE
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
        This configuration will mount an ISO file as drive S:.
#>
configuration MountImage_MountISO
{
    Import-DscResource -ModuleName StorageDsc

    MountImage ISO
    {
        ImagePath   = 'c:\Sources\SQL.iso'
        DriveLetter = 'S'
    }

    WaitForVolume WaitForISO
    {
        DriveLetter      = 'S'
        RetryIntervalSec = 5
        RetryCount       = 10
    }
}
