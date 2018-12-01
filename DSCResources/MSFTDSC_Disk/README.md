# Description

The resource is used to initialize, format and mount the partition/volume as a drive
letter.
The disk to add the partition/volume to is selected by specifying the _DiskId_ and
optionally _DiskIdType_.
The _DiskId_ value can be a _Disk Number_, _Unique Id_ or _Guid_.

**Important: The _Disk Number_ is not a reliable method of selecting a disk because
it has been shown to change between reboots in some environments.
It is recommended to use the _Unique Id_ if possible.**

The _Disk Number_, _Unique Id_ and _Guid_ can be identified for a disk by using the
PowerShell command:

```powershell
Get-Disk | Select-Object -Property FriendlyName,DiskNumber,UniqueId,Guid
```

Note: The _Guid_ identifier method of specifying disks is only supported as an
identifier for disks with `GPT` partition table format. If the disk is `RAW`
(e.g. the disk has been initialized) then the _Guid_ identifier method can not
be used. This is because the _Guid_ for a disk is only assigned once the partition
table for the disk has been created.

## Known Issues

The 'defragsvc' service ('Optimize Drives') may cause the following errors when
enabled with this resource. The following error may occur when testing the state
of the resource:

```text
PartitionSupportedSize
+ CategoryInfo : NotSpecified: (StorageWMI:) [], CimException
+ FullyQualifiedErrorId : StorageWMI 4,Get-PartitionSupportedSize
+ PSComputerName : localhost
```

The 'defragsvc' service should be stopped and set to manual start up to prevent
this error. Use the `Service` resource in either the 'xPSDesiredStateConfgiuration'
or 'PSDSCResources' resource module to set the 'defragsvc' service is always
stopped and set to manual start up.
