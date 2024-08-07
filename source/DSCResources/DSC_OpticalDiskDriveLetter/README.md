# Description

The resource is used to set the drive letter of an optical disk drive (e.g.
a CDROM or DVD drive).

It can be used to set the drive letter of a specific optical disk drive if
there are multiple in the system by specifying a value greater than 1 for
the `DiskId` parameter.

In a system with a single optical disk drive then the `DiskId` should
be set to 1.

In systems with multiple optical disks, the `DiskId` should be set to
the ordinal number of the required optical disk found in the list
returned when executing the following cmdlet:

```powershell
Get-CimInstance -ClassName Win32_CDROMDrive
```

> Warning: Adding and removing optical drive devices to a system may cause the
> order the optical drives appear in the system to change. Therefore, the
> drive ordinal number may be affected in these situations.

If the `DiskId` that is specified is greater than the number of manageable
optical disk drives in the system, then the resource will write a warning to
the log and will not attempt to set the drive letter. This will also occur
if there are no manageable optical disk drives in the system.

If the `DriveLetter` that should be assigned to the optical disk drive is
already assigned to another device, then the resource will throw an exception.

## Detection of Manageable Optical Disk Drives

This resource is intended to manage _permanent_ optical disk drives that are
either physically present in the system or are presented to the system by
hypervisors or other virtualization platforms. It is not intended to be used
to manage _temporary_ optical disk drives that are created when mounting ISOs
on Windows Server 2012 and newer. Mounted ISO drives should be managed by the
`DSC_MountImage` resource.

To detect whether a drive is a mounted ISO the following logic is used.
For a CIM instance of a `cimv2:Win32_CDROMDrive` class representing an
optical disk drive:

1. Get the _drive letter_ assigned to the drive in the `cimv2:Win32_CDROMDrive`.
   If the drive letter is set, query the volume information using the
   ``cimv2:Win32_Volume` CIM class for the device using _drive letter_ and get
   the _device path_.
1. If the drive letter is not set, then just create the _device path_ from the
   `drive` property.
1. Look up the disk image using the _device path_ using the `Get-DiskImage` cmdlet.
1. If no error occurs then the device is a mounted ISO and should not be
   used with this resource. If a "The specified disk is not a virtual
   disk." error occurs then it is not an ISO and can be managed by this
   resource.

### Old Detection Method

> Note: This method is no longer used because it is unreliable, but is documented
> here for reference.

In older versions (prior to v6.0.0) of the resource, the `DSC_OpticalDiskDriveLetter`
resource used the `DeviceID` and the `Caption` of the CIM Instance representing
the drive. This was not a 100% reliable method, and in recent versions of Windows
Server, it was found that the `DeviceID` and `Caption` of the CIM Instance
representing the drive were not unique enough to determine if the drive was a
mounted ISO or not.

The following is a table of sample captions and device IDs for some common
optical drive configurations. The items in bold are the strings used to
determine if the drive is a mounted ISO.

| Type | Caption | DeviceID | Manage using |
| ---- | ------- | -------- | ----------- |
| Mounted ISO in Windows Server 2019 | Microsoft Virtual DVD-ROM | SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\2&1F4ADFFE&0&000004 | `DSC_MountImage`* |
| Physical device | MATSHITA BD-MLT UJ260AF | SCSI\CDROM&VEN_MATSHITA&PROD_BD-MLT_UJ260AF\4&23A5A6AC&0&000200 | `DSC_OpticalDiskDriveLetter` |
| Hyper-V Gen1 (BIOS/IDE) VM - Windows Server 2019 | Msft Virtual CD/ROM ATA Device | IDE\CDROMMSFT_VIRTUAL_CD/ROM_____________________1.0_____\5&CFB56DE&0&1.0.0 | `DSC_OpticalDiskDriveLetter` |
| Hyper-V Gen2 (UEFI/SCSI) VM - Windows Server 2019 | Microsoft Virtual DVD-ROM | SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000001 | `DSC_OpticalDiskDriveLetter` |
| Hyper-V Gen1 (BIOS/IDE) VM - Windows Server 2022 | Msft Virtual CD/ROM ATA Device | IDE\CDROMMSFT_VIRTUAL_CD/ROM_____________________1.0_____\5&CFB56DE&0&1.0.0 | `DSC_OpticalDiskDriveLetter` |
| Hyper-V Gen2 (UEFI/SCSI) VM - Windows Server 2022 | Microsoft Virtual DVD-ROM | ... | `DSC_OpticalDiskDriveLetter` |
| Azure Gen1 (BIOS/IDE) VM – Windows Server 2022 Azure Edition | Msft Virtual CD/ROM ATA Device | IDE\CDROMMSFT_VIRTUAL_CD/ROM_____________________1.0_____\5&CFB56DE&0&1.0.0 | `DSC_OpticalDiskDriveLetter` |
| Azure Gen2 (UEFI/SCSI) VM – Windows Server 2022 Azure Edition | Microsoft Virtual DVD-ROM | SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\5&394B69D0&0&000002 | `DSC_pticalDiskDriveLetter` |

\* Don't manage with this resource, use `DSC_MountImage` instead.

This is not a complete list, as some other virtual devices from other vendors
might not be available for testing.

## Known Issues

Some operating systems report the optical disk in the Win32_CDROMDrive list,
but a volume that matches either the DeviceId or DriveLetter can not be found.
The DriveLetter value appears as 'CdRom0' in the Win32_CDROMDrive list.
This prevents the resource from matching the optical disk to a volume if the
volume is not mounted.

This appears to only be an issue with IDE optical drives. SCSI optical drives
do not appear to have this issue.

Therefore, this resource will not manage the optical disk if the volume can not
be found and is not already mounted. The verbose logs will report this condition
if detected. See [Issue #289](https://github.com/dsccommunity/StorageDsc/issues/289)
for more information.
