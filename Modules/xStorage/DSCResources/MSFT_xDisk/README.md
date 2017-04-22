# Description

The resource is used to initialize, format and mount the partition/volume as a drive
letter.
The disk to add the partition/volume to is selected by specifying the _DiskId_ and
optionally _DiskIdType_.
The _DiskId_ value can be a _Disk Number_ or _Unique Id_.

**Important: The _Disk Number_ is not a reliable method of selecting a disk because
it has been shown to change between reboots in some environments.
It is recommended to use the _Unique Id_ if possible.**

The _Disk Number_ or _Unique Id_ can be identified for a disk by using the PowerShell
command:

```powershell
Get-Disk | Select-Object -Property FriendlyName,DiskNumber,UniqueId
```
