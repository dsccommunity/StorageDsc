# StorageDsc

[![Build Status](https://dev.azure.com/dsccommunity/StorageDsc/_apis/build/status/dsccommunity.StorageDsc?branchName=main)](https://dev.azure.com/dsccommunity/StorageDsc/_build/latest?definitionId=30&branchName=main)
![Code Coverage](https://img.shields.io/azure-devops/coverage/dsccommunity/StorageDsc/30/main)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/StorageDsc/30/main)](https://dsccommunity.visualstudio.com/StorageDsc/_test/analytics?definitionId=30&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/StorageDsc?label=StorageDsc%20Preview)](https://www.powershellgallery.com/packages/StorageDsc/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/StorageDsc?label=StorageDsc)](https://www.powershellgallery.com/packages/StorageDsc/)
[![codecov](https://codecov.io/gh/dsccommunity/StorageDsc/branch/main/graph/badge.svg)](https://codecov.io/gh/dsccommunity/StorageDsc)

## Code of Conduct

This project has adopted [this code of conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `main` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

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
- **VirtualHardDisk** used to create and attach a virtual hard disk.

This project has adopted [this code of conduct](CODE_OF_CONDUCT.md).

## Documentation and Examples

For a full list of resources in StorageDsc and examples on their use, check out
the [StorageDsc wiki](https://github.com/dsccommunity/StorageDsc/wiki).
