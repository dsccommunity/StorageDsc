# xStorage

The **xStorage** module contains the following resources:

- **xMountImage**: used to mount or unmount an ISO/VHD disk image. It can be
    mounted as read-only (ISO, VHD, VHDx) or read/write (VHD, VHDx).
- **xDisk**: used to initialize, format and mount the partition as a drive letter.
- **xDiskAccessPath**: used to initialize, format and mount the partition to a
    folder access path.
- **xWaitForDisk** wait for a disk to become available.
- **xWaitForVolume** wait for a drive to be mounted and become available.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.

## Documentation and Examples

For a full list of resources in xStorage and examples on their use, check out
the [xStorage wiki](https://github.com/PowerShell/xStorage/wiki).

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/1j95juvceu39ekm7/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xstorage/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/xStorage/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/xStorage/branch/master)

This is the branch containing the latest release - no contributions should be made
directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/1j95juvceu39ekm7/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/xstorage/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/xStorage/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/xStorage/branch/dev)

This is the development branch to which contributions should be proposed by contributors
as pull requests. This development branch will periodically be merged to the master
branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).
