<#PSScriptInfo
.VERSION 1.0.0
.GUID c4b48b7c-2a0f-4d18-9806-9c1063b8de83
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
        This configuration will mount a VHD file and wait for it to become available.
#>
configuration MountImage_MountVHD
{
    Import-DscResource -ModuleName StorageDsc

    MountImage MountVHD
    {
        ImagePath   = 'd:\Data\Disk1.vhd'
        DriveLetter = 'V'
    }

    WaitForVolume WaitForVHD
    {
        DriveLetter      = 'V'
        RetryIntervalSec = 5
        RetryCount       = 10
    }
}
