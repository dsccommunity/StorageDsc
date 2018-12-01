# StorageDsc

The **StorageDsc** module contains the following resources:

- **MountImage**: used to mount or unmount an ISO/VHD disk image. It can be
    mounted as read-only (ISO, VHD, VHDx) or read/write (VHD, VHDx).
- **Disk**: used to initialize, format and mount the partition as a drive letter.
- **DiskAccessPath**: used to initialize, format and mount the partition to a
    folder access path.
- **OpticalDiskDriveLetter**: used to change the drive letter of an optical
    disk drive (e.g. a CDROM or DVD drive).  This resource ignores mounted ISOs.
- **WaitForDisk** wait for a disk to become available.
- **WaitForVolume** wait for a drive to be mounted and become available.

This project has adopted [this code of conduct](CODE_OF_CONDUCT.md).

## Documentation and Examples

For a full list of resources in StorageDsc and examples on their use, check out
the [StorageDsc wiki](https://github.com/PowerShell/StorageDsc/wiki).

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/1j95juvceu39ekm7/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/StorageDsc/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/StorageDsc/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/StorageDsc/branch/master)

This is the branch containing the latest release - no contributions should be made
directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/1j95juvceu39ekm7/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/StorageDsc/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/StorageDsc/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/StorageDsc/branch/dev)

This is the development branch to which contributions should be proposed by contributors
as pull requests. This development branch will periodically be merged to the master
branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).
