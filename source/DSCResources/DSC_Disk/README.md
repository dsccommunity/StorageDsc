# Description

The resource is used to initialize, format and mount the partition/volume as a drive
letter.
The disk to add the partition/volume to is selected by specifying the _DiskId_ and
optionally _DiskIdType_.
The _DiskId_ value can be a _Disk Number_, _Unique Id_,  _Guid_, _Location_, _FriendlyName_ or _SerialNumber_.

**Important: The _Disk Number_ is not a reliable method of selecting a disk because
it has been shown to change between reboots in some environments.
It is recommended to use the _Unique Id_ if possible.**

The _Disk Number_, _Unique Id_, _Guid_, _Location_, _FriendlyName_ and _SerialNumber_ can be identified for a
disk by using the PowerShell command:

```powershell
Get-Disk | Select-Object -Property FriendlyName,DiskNumber,UniqueId,Guid,Location,SerialNumber
```

Note: The _Guid_ identifier method of specifying disks is only supported as an
identifier for disks with `GPT` partition table format. If the disk is `RAW`
(e.g. the disk has been initialized) then the _Guid_ identifier method can not
be used. This is because the _Guid_ for a disk is only assigned once the partition
table for the disk has been created.

## Dev Drive

The Dev Drive feature is currently available on Windows 11 in builds 10.0.22621.2338 or later. See [the Dev Drive documentation for the latest in formation](https://learn.microsoft.com/en-us/windows/dev-drive/).

### What is a Dev Drive volume and how is it different from regular volumes?

Dev Drive volumes from a storage perspective are just like regular ReFS volumes on a Windows machine. The difference However, is that most of the filter drivers except the antivirus filter will not attach to the volume at boot time by default. This is a low-level concept that most users will never need to interact with but for further reading, see the documentation [here](https://learn.microsoft.com/en-us/windows/dev-drive/#how-do-i-configure-additional-filters-on-dev-drive) for further reading.

### What is the default state of the Dev Drive flag in this resource?

By default, the Dev Drive flag is set to **false**. This means that a Dev Drive volume will not be created with the inputted parameters. This is used to create/reconfigure non Dev Drive volumes. Setting the flag to **true** will attempt to create/reconfigure a volume as a Dev Drive volume using the users' inputted parameters.

### Can more than one Dev Drive be mounted at a time?

Yes, more than one Dev Drive volume can be mounted at a time. You can have as many Dev Drive volumes as the physical storage amount on the disk permits. Though, it should be noted, that the `minimum size` for a single Dev Drive volume is `50 Gb`.

### If I have a non Dev Drive volume that is 50 Gb or more can it be reformatted as a Dev Drive volume?

Yes, since the Dev Drive volume is just like any other volume storage wise to the Windows operating system, a non Dev Drive ReFS volume can be reformatted as a Dev Drive volume. An NTFS volume can also be reformatted as a Dev Drive volume. Note, the Disk resource will throw an exception, should you also attempt to resize a ReFS volume while attempting to reformat it as a Dev Drive volume since ReFS volumes cannot be resized. As Dev Drive volumes are also ReFS volumes, they carry the same restrictions, see: [Resilient File System (ReFS) overview | Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/storage/refs/refs-overview)

### If I don't have any unallocated space available to create a Dev Drive volume, what will happen?

The Disk resource uses the Get-PartitionSupportedSize cmdlet to know which volume can be be resized to a safe size to create enough unallocated space for the Dev Drive volume to be created. As long as the size parameter is used, the Disk resource will shrink the first non ReFS Drive whose (MaxSize - MinSize) is greater than or equal to the size entered in the size parameter.

If unallocated space exists but isn't enough to create a Dev Drive volume with, The Disk Resource will only shrink the volume noted above by the minimum size needed, to add to the existing unallocated space so it can be equal to the size parameter. For example, if you wanted to create a new 50 Gb Dev Drive volume on disk 0, and let's say on disk 0 there was only a 'C' drive that was 800 Gb in size. Next to the 'C' drive there was only 40 Gb of free contiguous unallocated space. The Disk resource would shrink the 'C' drive by 10 Gb,  creating an addition 10 Gb of unallocated space. Now the unallocated space would be 50 Gb in size. The disk resource would then create a new partition and create the Dev Drive volume into this new partition.

**Note: if no size is entered the disk resource will throw an error stating that size is 0 gb, so no partitions can be resized.**

### Dev Drive requirements for this resource

There are only five requirements:

1. The Dev Drive feature must be available on the machine. We assert that this is true in order to format a Dev Drive volume onto a partition.
2. The Dev Drive feature is enabled on the machine. Note: the feature could be disabled by either a group or system policy, so if ran in an enterprise environment this should be checked. Note, once a Dev Drive volume is created, its functionality will not change and will not be affected should the feature become disabled afterwards. Disablement would only prevent new Dev Drive volumes from being created. However, this could affect the `idempotence` for the Drive. For example, changes to this drive after disablement (e.g., reformatting the volume as an NTFS volume) would not be corrected by rerunning the configuration. Since the feature is disabled, attempting reformat the volume as a Dev Drive volume will throw an error advising you that it is not possible due to the feature being disabled.
3. If the `size` parameter is entered, the value must be greater than or equal to 50 Gb in size. We assert that this is true in order to format a Dev Drive volume onto a partition.
4. Currently today, if the `size` parameter is not entered then the Disk resource will use the maximum space available on the Disk. When the `DevDrive` flag is set to `$true`, then we assert that the maximum available free unallocated space on the Disk should be `50 Gb or more in size`. This assertion only comes into play if the volume doesn't already exist.
5. The `FSformat` parameter must be set to 'ReFS', when the `DevDrive` flag is set to true. We assert that this is true and throw an exception if it is not.

# Testing
Note: Integration tests are not run for the Disk resource when SerialNumber
is used since the virtual disk that is created does not have a serial number.

There are no Dev Drive integration tests as the feature is not available in Server
2019 and 2022.

## Known Issues

### Defragsvc Conflict

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

### Null Location

The _Location_ for a disk may be `null` for some types of disk,
e.g. file-based virtual disks. Physical disks or Virtual disks provided via a
hypervisor or other hardware virtualization platform should not be affected.

### Maximum Supported Partition Size

On some disks the _maximum supported partition size_ may differ from the actual
size of a partition created when specifying the maximum size. This difference
in reported size is always less than **1MB**, so if the reported _maximum supported
partition size_ is less than **1MB** then the partition will be considered to be
in the correct state. This is a work around for [this issue](https://windowsserver.uservoice.com/forums/301869-powershell/suggestions/36967870-get-partitionsupportedsize-and-msft-partition-clas)
that has been reported on user voice and also discussed in [issue #181](https://github.com/dsccommunity/StorageDsc/issues/181).

### ReFS on Windows Server 2019

On Windows Server 2019 (build 17763 and above), `Format-Volume` throws an
'Invalid Parameter' exception when called with `ReFS` as the `FileSystem`
parameter. This results in an 'Invalid Parameter' exception being thrown
in the `Set` in the 'Disk' resource.
There is currently no known work around for this issue. It is being tracked
in [issue #227](https://github.com/dsccommunity/StorageDsc/issues/227).
