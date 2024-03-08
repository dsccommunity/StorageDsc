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

Warning: Adding and removing optical drive devices to a system may cause the
order the optical drives appear in the system to change. Therefore, the
drive ordinal number may be affected in these situations.

## Detection of Optical Disk Drives

This resource is not intended to be used to manage _temporary_ optical disk
drives that are created when mounting ISOs on Windows Server 2012 and newer.
Mounted ISO drives should be managed by the `DSC_MountImage` resource.

However, to detect whether a drive is a mounted ISO, the resource uses the
`DeviceID` and the `Caption` of the CIM Instance representing the drive.
This is not a 100% reliable method, but it is currently the best method available.

The following is a table of sample captions and device IDs for some common
optical drive configurations. The items in bold are the strings used to
determine if the drive is a mounted ISO.

| Type | Caption | DeviceID | Manage using |
| ---- | ------- | -------- | ----------- |
| Mounted ISO | **Microsoft Virtual DVD-ROM** | SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\\**2&1F4ADFFE&0&000004** | `DSC_MountImage`* |
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

The resource will use the following logic when determining if a drive is
a mounted ISO and therefore should **not** be mnanaged by this resource:

- If the `Caption` is 'Microsoft Virtual DVD-ROM'
- And the length of the string after the final backslash in the `DeviceID`
  is greater than 6 characters and less than 20 characters.

Note: This is not a 100% reliable method and improvements to this detection
method are welcome.
