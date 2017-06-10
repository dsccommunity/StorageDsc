# Description

The resource is used to set the drive letter of a CDROM

It is designed to ignore 'temporary' CDROMs that are created when mounting
ISOs on Windows Server 2012+

With the Device ID, we look for the length of the string after the final
backslash (crude, but appears to work so far)

Example:
    # DeviceID for a virtual drive in a Hyper-V VM - SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\**000006**
    # DeviceID for a mounted ISO   in a Hyper-V VM - SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\**2&1F4ADFFE&0&000002**