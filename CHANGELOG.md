# Change log for StorageDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Updated DSC_Disk to allow volumes to be formatted as Dev Drives - Fixes [Issue #276](https://github.com/dsccommunity/StorageDsc/issues/276)

## [5.1.0] - 2023-02-22

### Changed

- Renamed `master` branch to `main` - Fixes [Issue #250](https://github.com/dsccommunity/StorageDsc/issues/250).
- Added support for publishing code coverage to `CodeCov.io` and
  Azure Pipelines - Fixes [Issue #255](https://github.com/dsccommunity/StorageDsc/issues/255).
- Updated build to use `Sampler.GitHubTasks` - Fixes [Issue #254](https://github.com/dsccommunity/StorageDsc/issues/254).
- Updated pipeline tasks to latest pattern.
- Updated .github issue templates to standard - Fixes [Issue #263](https://github.com/dsccommunity/StorageDsc/issues/263).
- Added Create_ChangeLog_GitHub_PR task to publish stage of build pipeline.
- Added SECURITY.md.
- Updated pipeline Deploy_Module anb Code_Coverage jobs to use ubuntu-latest
  images - Fixes [Issue #262](https://github.com/dsccommunity/StorageDsc/issues/262).
- Updated pipeline unit tests and integration tests to use Windows Server 2019 and
  Windows Server 2022 images - Fixes [Issue #262](https://github.com/dsccommunity/StorageDsc/issues/262).
- Added support to use disk FriendlyName as a disk identifer - Fixes [Issue #268](https://github.com/dsccommunity/StorageDsc/issues/268).
- Pin Azure build agent vmImage to ubuntu-20.04  - Fixes [Issue #270] (https://github.com/dsccommunity/StorageDsc/issues/270).
- Remove confirmation prompt when Clear-Disk is called.
- Add mock Clear-Disk function and verification tests.
- Added support to use disk SerialNumber as a disk identifer - Fixes [Issue #259](https://github.com/dsccommunity/StorageDsc/issues/259).

### Fixed

- MountImage:
  - Corrected example `1-MountImage_DismountISO.ps1` for dismounting
    ISO - Fixes [Issue #221](https://github.com/dsccommunity/StorageDsc/issues/221).
- Updated `GitVersion.yml` to latest pattern - Fixes [Issue #252](https://github.com/dsccommunity/StorageDsc/issues/252).
- Fixed pipeline by replacing the GitVersion task in the `azure-pipelines.yml`
  with a script.

## [5.0.1] - 2020-08-03

### Changed

- Fixed build failures caused by changes in `ModuleBuilder` module v1.7.0
  by changing `CopyDirectories` to `CopyPaths` - Fixes [Issue #237](https://github.com/dsccommunity/StorageDsc/issues/237).
- Updated to use the common module _DscResource.Common_ - Fixes [Issue #234](https://github.com/dsccommunity/StorageDsc/issues/234).
- Pin `Pester` module to 4.10.1 because Pester 5.0 is missing code
  coverage - Fixes [Issue #238](https://github.com/dsccommunity/StorageDsc/issues/238).
- OpticalDiskDriveLetter:
  - Removed integration test that tests when a disk is not in the
    system as it is not a useful test, does not work correctly
    and is covered by unit tests - Fixes [Issue #240](https://github.com/dsccommunity/StorageDsc/issues/240).
- StorageDsc
  - Automatically publish documentation to GitHub Wiki - Fixes [Issue #241](https://github.com/dsccommunity/StorageDsc/issues/241).

### Fixed

- Disk:
  - Fix bug when multiple partitions with the same drive letter are
    reported by the disk subsystem - Fixes [Issue #210](https://github.com/dsccommunity/StorageDsc/issues/210).

## [5.0.0] - 2020-05-05

### Changed

- Fixed hash table style violations - fixes [Issue #219](https://github.com/dsccommunity/StorageDsc/issues/219).
- Disk:
  - Updated example with size as a number in bytes and without unit of measurement
    like GB or MB - fixes [Issue #214](https://github.com/dsccommunity/StorageDsc/pull/214).
- BREAKING CHANGE: Changed resource prefix from MSFT to DSC.
- BREAKING CHANGE: Changed Disk resource prefix from MSFTDSC to DSC as there
  would no longer be a conflict with the built in MSFT_Disk CIM class.
- Updated to use continuous delivery pattern using Azure DevOps - fixes
  [Issue #225](https://github.com/dsccommunity/StorageDsc/issues/225).
- Updated Examples and Module Manifest to be DSC Community from Microsoft.
- Added Integration tests on Windows Server 2019.
- WaitForVolume:
  - Improved unit tests to use virtual disk instead of physical disk.
- Disk:
  - Added `Invalid Parameter` exception being reported when ReFS volumes are
    used with Windows Server 2019 as a known issue to README.MD - fixes
    [Issue #227](https://github.com/dsccommunity/StorageDsc/issues/227).
- Updated build badges in README.md.
- Change Azure DevOps Pipeline definition to include `source/*` - Fixes [Issue #231](https://github.com/dsccommunity/StorageDsc/issues/231).
- Updated pipeline to use `latest` version of `ModuleBuilder` - Fixes [Issue #231](https://github.com/dsccommunity/StorageDsc/issues/231).
- Merge `HISTORIC_CHANGELOG.md` into `CHANGELOG.md` - Fixes [Issue #232](https://github.com/dsccommunity/StorageDsc/issues/232).
- OpticalDiskDriveLetter:
  - Suppress exception when requested optical disk drive does not exist
    and Ensure is set to `Absent` - Fixes [Issue #194](https://github.com/dsccommunity/StorageDsc/issues/194).

## [4.9.0.0] - 2019-10-30

### Changed

- Disk:
  - Added `Location` as a possible value for `DiskIdType`. This will select the
    disk based on the `Location` property returned by `Get-Disk`
  - Maximum size calculation now uses workaround so that
    Test-TargetResource works properly - workaround for
    [Issue #181](https://github.com/dsccommunity/StorageDsc/issues/181).
- DiskAccessPath:
  - Added `Location` as a possible value for `DiskIdType`. This will select the
    disk based on the `Location` property returned by `Get-Disk`
- WaitForDisk:
  - Added `Location` as a possible value for `DiskIdType`. This will select the
    disk based on the `Location` property returned by `Get-Disk`

## [4.8.0.0] - 2019-08-08

### Changed

- Removed suppression of `PSUseShouldProcessForStateChangingFunctions` PSSA rule
  because it is no longer required.
- Combined all `StorageDsc.ResourceHelper` module functions into
  `StorageDsc.Common` module and removed `StorageDsc.ResourceHelper`.
- Opted into Common Tests 'Common Tests - Validate Localization' -
  fixes [Issue #206](https://github.com/dsccommunity/StorageDsc/issues/206).
- Refactored tests for `StorageDsc.Common` to meet latest standards.
- Minor style corrections.
- Removed unused localization strings from resources.
- DiskAccessPath:
  - Added function to force refresh of disk subsystem at the start of
    Set-TargetResource to prevent errors occuring when the disk access
    path is already assigned - See [Issue 121](https://github.com/dsccommunity/StorageDsc/issues/121)

## [4.7.0.0] - 2019-05-15

### Changed

- DiskAccessPath:
  - Added a Get-Partition to properly handle setting the NoDefaultDriveLetter
    parameter - fixes [Issue #198](https://github.com/dsccommunity/StorageDsc/pull/198).

## [4.6.0.0] - 2019-04-03

### Changed

- Fix example publish to PowerShell Gallery by adding `gallery_api`
  environment variable to `AppVeyor.yml` - fixes [Issue #202](https://github.com/dsccommunity/StorageDsc/issues/202).
- Added 'DscResourcesToExport' to manifest to improve information in
  PowerShell Gallery and removed wildcards from 'FunctionsToExport',
  'CmdletsToExport', 'VariablesToExport' and 'AliasesToExport' - fixes
  [Issue #192](https://github.com/dsccommunity/StorageDsc/issues/192).
- Clean up module manifest to correct Author and Company - fixes
  [Issue #191](https://github.com/dsccommunity/StorageDsc/issues/191).
- Correct unit tests for DiskAccessPath to test exact number of
  mocks called - fixes [Issue #199](https://github.com/dsccommunity/StorageDsc/issues/199).
- Disk:
  - Added minimum timetowate of 3s after new-partition using the while loop.
    The problem occurs when the partition is created and the format-volume
    is attempted before the volume has completed.
    There appears to be no property to determine if the partition is
    sufficiently ready to format and it will often format as a raw volume when
    the error occurs - fixes [Issue #85](https://github.com/dsccommunity/StorageDsc/issues/85).

## [4.5.0.0] - 2019-02-20

### Changed

- Opt-in to Example publishing to PowerShell Gallery - fixes [Issue #186](https://github.com/dsccommunity/StorageDsc/issues/186).
- DiskAccessPath:
  - Updated the resource to not assign a drive letter by default when adding
    a disk access path. Adding a Set-Partition -NoDefaultDriveLetter
    $NoDefaultDriveLetter block defaulting to true.
    When adding access paths the disks will no longer have
    drive letters automatically assigned on next reboot which is the desired
    behavior - Fixes [Issue #145](https://github.com/dsccommunity/StorageDsc/issues/145).

## [4.4.0.0] - 2019-01-10

### Changed

- Refactored module folder structure to move resource to root folder of
  repository and remove test harness - fixes [Issue #169](https://github.com/dsccommunity/StorageDsc/issues/169).
- Updated Examples to support deployment to PowerShell Gallery scripts.
- Removed limitation on using Pester 4.0.8 during AppVeyor CI.
- Moved the Code of Conduct text out of the README.md and into a
  CODE\_OF\_CONDUCT.md file.
- Explicitly removed extra hidden files from release package

## [4.3.0.0] - 2018-11-29

### Changed

- WaitForDisk:
  - Added readonly-property isAvailable which shows the current state
    of the disk as a boolean - fixes [Issue #158](https://github.com/dsccommunity/StorageDsc/issues/158).

## [4.2.0.0] - 2018-10-25

### Changed

- Disk:
  - Added `PartitionStyle` parameter - Fixes [Issue #137](https://github.com/dsccommunity/StorageDsc/issues/37).
  - Changed MOF name from `MSFT_Disk` to `MSFTDSC_Disk` to remove conflict
    with Windows built-in CIM class - Fixes [Issue #167](https://github.com/dsccommunity/StorageDsc/issues/167).
- Opt-in to Common Tests:
  - Common Tests - Validate Example Files To Be Published
  - Common Tests - Validate Markdown Links
  - Common Tests - Relative Path Length
- Added .VSCode settings for applying DSC PSSA rules - fixes [Issue #168](https://github.com/dsccommunity/StorageDsc/issues/168).
- Disk:
  - Added 'defragsvc' service conflict known issue to README.MD - fixes
    [Issue #172](https://github.com/dsccommunity/StorageDsc/issues/172).
- Corrected style violations in StorageDsc.Common module - fixes [Issue #153](https://github.com/dsccommunity/StorageDsc/issues/153).
- Corrected style violations in StorageDsc.ResourceHelper module.

## [4.1.0.0] - 2018-09-05

### Changed

- Enabled PSSA rule violations to fail build - Fixes [Issue #149](https://github.com/dsccommunity/StorageDsc/issues/149).
- Fixed markdown rule violations in CHANGELOG.MD.
- Disk:
  - Corrected message strings.
  - Added message when partition resize required but `AllowDestructive`
    parameter is not enabled.
  - Fix error when `Size` not specified and `AllowDestructive` is `$true`
    and partition can be expanded - Fixes [Issue #162](https://github.com/dsccommunity/StorageDsc/issues/162).
  - Fix incorrect error displaying when newly created partition is not
    made Read/Write.
  - Change verbose messages to show warnings when a partition resize would
    have occured but the `AllowDestructive` flag is set to `$false`.

## [4.0.0.0] - 2018-02-08

### Changed

- BREAKING CHANGE:
  - Renamed xStorage to StorageDsc
  - Renamed MSFT_xDisk to MSFT_Disk
  - Renamed MSFT_xDiskAccessPath to MSFT_DiskAccessPath
  - Renamed MSFT_xMountImage to MSFT_MountImage
  - Renamed MSFT_xOpticalDiskDriveLetter to MSFT_OpticalDiskDriveLetter
  - Renamed MSFT_xWaitForDisk to MSFT_WaitForDisk
  - Renamed MSFT_xWaitForVolume to MSFT_WaitforVolume
  - Deleted xStorage folder under StorageDsc/Modules
  - See [Issue 129](https://github.com/dsccommunity/xStorage/issues/129)

## [3.4.0.0] - 2017-12-20

### Changed

- xDisk:
  - Removed duplicate integration tests for Guid Disk Id type.
  - Added new contexts to integration tests improve clarity.
  - Fix bug when size not specified and disk partitioned and
    formatted but not assigned drive letter - See [Issue 103](https://github.com/dsccommunity/xStorage/issues/103).
- xDiskAccessPath:
  - Added new contexts to integration tests improve clarity.
  - Fix bug when size not specified and disk partitioned and
    formatted but not assigned to path - See [Issue 103](https://github.com/dsccommunity/xStorage/issues/103).

## [3.3.0.0] - 2017-11-15

### Changed

- Opted into common tests for Module and Script files - See [Issue 115](https://github.com/dsccommunity/xStorage/issues/115).
- xDisk:
  - Added support for Guid Disk Id type - See [Issue 104](https://github.com/dsccommunity/xStorage/issues/104).
  - Added parameter AllowDestructive - See [Issue 11](https://github.com/dsccommunity/xStorage/issues/11).
  - Added parameter ClearDisk - See [Issue 50](https://github.com/dsccommunity/xStorage/issues/50).
- xDiskAccessPath:
  - Added support for Guid Disk Id type - See [Issue 104](https://github.com/dsccommunity/xStorage/issues/104).
- xWaitForDisk:
  - Added support for Guid Disk Id type - See [Issue 104](https://github.com/dsccommunity/xStorage/issues/104).
- Added .markdownlint.json file to configure markdown rules to validate.
- Clean up Badge area in README.MD - See [Issue 110](https://github.com/dsccommunity/xStorage/issues/110).
- Disabled MD013 rule checking to enable badge table.
- Added .github support files:
  - CONTRIBUTING.md
  - ISSUE_TEMPLATE.md
  - PULL_REQUEST_TEMPLATE.md
- Changed license year to 2017 and set company name to Microsoft
  Corporation in LICENSE.MD and module manifest - See [Issue 111](https://github.com/dsccommunity/xStorage/issues/111).
- Set Visual Studio Code setting "powershell.codeFormatting.preset" to
  "custom" - See [Issue 108](https://github.com/dsccommunity/xStorage/issues/108)
- Added `Documentation and Examples` section to Readme.md file - see
  [issue #116](https://github.com/dsccommunity/xStorage/issues/116).
- Prevent unit tests from DSCResource.Tests from running during test
  execution - fixes [Issue #118](https://github.com/dsccommunity/xStorage/issues/118).
- Updated tests to meet Pester V4 guidelines - fixes [Issue #120](https://github.com/dsccommunity/xStorage/issues/120).

## [3.2.0.0] - 2017-07-12

### Changed

- xDisk:
  - Fix error message when new partition does not become writable before timeout.
  - Removed unneeded timeout initialization code.
- xDiskAccessPath:
  - Fix error message when new partition does not become writable before timeout.
  - Removed unneeded timeout initialization code.
  - Fix error when used on Windows Server 2012 R2 - See [Issue 102](https://github.com/dsccommunity/xStorage/issues/102).
- Added the VS Code PowerShell extension formatting settings that cause PowerShell
  files to be formatted as per the DSC Resource kit style guidelines.
- Removed requirement on Hyper-V PowerShell module to execute integration tests.
- xMountImage:
  - Fix error when mounting VHD on Windows Server 2012 R2 - See [Issue 105](https://github.com/dsccommunity/xStorage/issues/105)

## [3.1.0.0] - 2017-06-01

### Changed

- Added integration test to test for conflicts with other common resource kit modules.
- Prevented ResourceHelper and Common module cmdlets from being exported to resolve
  conflicts with other resource modules.

## [3.0.0.0] - 2017-05-31

### Changed

- Converted AppVeyor build process to use AppVeyor.psm1.
- Added support for auto generating wiki, help files, markdown linting
  and checking examples.
- Correct name of MSFT_xDiskAccessPath.tests.ps1.
- Move shared modules into Modules folder.
- Fixed unit tests.
- Removed support for WMI cmdlets.
- Opted in to Markdown and Example tests.
- Added CodeCov.io support.
- Removed requirement on using Pester 3.4.6 because Pester bug fixed in 4.0.3.
- Fixed unit tests for MSFT_xDiskAccessPath resource to be compatible with
  Pester 4.0.3.
- xDisk:
  - BREAKING CHANGE: Renamed parameter DiskNumber to DiskId to enable it to
    contain either DiskNumber or UniqueId - See [Issue 81](https://github.com/dsccommunity/xStorage/issues/81).
  - Added DiskIdType parameter to enable specifying the type of identifer
    the DiskId parameter contains - See [Issue 81](https://github.com/dsccommunity/xStorage/issues/81).
  - Changed to use xDiskAccessPath pattern to fix issue with Windows Server
    2016 - See [Issue 80](https://github.com/dsccommunity/xStorage/issues/80).
  - Fixed style violations in xDisk.
  - Fixed issue when creating multiple partitions on a single disk with no size
    specified - See [Issue 86](https://github.com/dsccommunity/xStorage/issues/86).
- xDiskAccessPath:
  - BREAKING CHANGE: Renamed parameter DiskNumber to DiskId to
    enable it to contain either DiskNumber or UniqueId - See [Issue 81](https://github.com/dsccommunity/xStorage/issues/81).
  - Added DiskIdType parameter to enable specifying the type
    of identifer the DiskId parameter contains - See [Issue 81](https://github.com/dsccommunity/xStorage/issues/81).
  - Fixed incorrect logging messages when changing volume label.
  - Fixed issue when creating multiple partitions on a single disk with no size
    specified - See [Issue 86](https://github.com/dsccommunity/xStorage/issues/86).
- xWaitForDisk:
  - BREAKING CHANGE: Renamed parameter DiskNumber to DiskId to
    enable it to contain either DiskNumber or UniqueId - See [Issue 81](https://github.com/dsccommunity/xStorage/issues/81).
  - Added DiskIdType parameter to enable specifying the type
    of identifer the DiskId parameter contains - See [Issue 81](https://github.com/dsccommunity/xStorage/issues/81).

## [2.9.0.0] - 2016-12-14

### Changed

- Updated readme.md to remove markdown best practice rule violations.
- Updated readme.md to match DSCResources/DscResource.Template/README.md.
- xDiskAccessPath:
  - Fix bug when re-attaching disk after mount point removed or detatched.
  - Additional log entries added for improved diagnostics.
  - Additional integration tests added.
  - Improve timeout loop.
- Converted integration tests to use ```$TestDrive``` as working folder
  or ```temp``` folder when persistence across tests is required.
- Suppress ```PSUseShouldProcessForStateChangingFunctions``` rule violations in resources.
- Rename ```Test-AccessPath``` function to ```Assert-AccessPathValid```.
- Rename ```Test-DriveLetter``` function to ```Assert-DriveLetterValid```.
- Added ```CommonResourceHelper.psm1``` module (based on PSDscResources).
- Added ```CommonTestsHelper.psm1``` module  (based on PSDscResources).
- Converted all modules to load localization data using ```Get-LocalizedData```
  from CommonResourceHelper.
- Converted all exception calls and tests to use functions
  in ```CommonResourceHelper.psm1``` and ```CommonTestsHelper.psm1``` respectively.
- Fixed examples:
  - Sample_InitializeDataDisk.ps1
  - Sample_InitializeDataDiskWithAccessPath.ps1
  - Sample_xMountImage_DismountISO.ps1
- xDisk:
  - Improve timeout loop.

## [2.8.0.0] - 2016-11-02

### Changed

- added test for existing file system and no drive letter assignment to allow
  simple drive letter assignment in MSFT_xDisk.psm1
- added unit test for volume with existing partition and no drive letter
  assigned for MSFT_xDisk.psm1
- xMountImage: Fixed mounting disk images on Windows 10 Anniversary Edition
- Updated to meet HQRM guidelines.
- Moved all strings into localization files.
- Fixed examples to import xStorage module.
- Fixed Readme.md layout issues.
- xWaitForDisk:
  - Added support for setting DriveLetter parameter with or without colon.
  - MOF Class version updated to 1.0.0.0.
- xWaitForVolume:
  - Added new resource.
- StorageCommon:
  - Added helper function module.
  - Corrected name of unit tests file.
- xDisk:
  - Added validation of DriveLetter parameter.
  - Added support for setting DriveLetter parameter with or without colon.
  - Removed obfuscation of drive/partition errors by eliminating try/catch block.
  - Improved code commenting.
  - Reordered tests so they are in same order as module functions to ease creation.
  - Added FSFormat parameter to allow disk format to be specified.
  - Size or AllocationUnitSize mismatches no longer trigger Set-TargetResource
    because these values can't be changed (yet).
  - MOF Class version updated to 1.0.0.0.
  - Unit tests changed to match xDiskAccessPath methods.
  - Added additional unit tests to Get-TargetResource.
  - Fixed bug in Get-TargetResource when disk did not contain any partitions.
  - Added missing cmdletbinding() to functions.
- xMountImage (Breaking Change):
  - Removed Name parameter (Breaking Change)
  - Added validation of DriveLetter parameter.
  - Added support for setting DriveLetter parameter with or without colon.
  - MOF Class version updated to 1.0.0.0.
  - Enabled mounting of VHD/VHDx/VHDSet disk images.
  - Added StorageType and Access parameters to allow mounting VHD and VHDx disks
    as read/write.
- xDiskAccessPath:
  - Added new resource.
  - Added support for changing/setting volume label.

## [2.7.0.0] - 2016-09-21

### Changed

- Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.

## [2.6.0.0] - 2016-05-18

### Changed

- MSFT_xDisk: Replaced Get-WmiObject with Get-CimInstance

## [2.5.0.0] - 2016-03-31

### Changed

- added test for existing file system to allow simple drive letter assignment in
  MSFT_xDisk.psm1
- modified Test verbose message to correctly reflect blocksize value in
  MSFT_xDisk.psm1 line 217
- added unit test for new volume with out existing partition for MSFT_xDisk.psm1
- Fixed error propagation

## [2.4.0.0] - 2016-02-03

### Changed

- Fixed bug where AllocationUnitSize was not used

## [2.3.0.0] - 2015-12-03

### Changed

- Added support for `AllocationUnitSize` in `xDisk`.

## [2.2.0.0] - 2015-10-22

### Changed

- Updated documentation: changed parameter name Count to RetryCount in
  xWaitForDisk resource

## [2.1.0.0] - 2015-09-11

### Changed

- Fixed encoding

## [2.0.0.0] - 2015-07-24

### Changed

- Breaking change: Added support for following properties: DriveLetter, Size,
  FSLabel. DriveLetter is a new key property.

## [1.0.0.0] - 2015-06-17

### Changed

This module was previously named **xDisk**, the version is regressing to a
"1.0.0.0" release with the addition of xMountImage.

- Initial release of xStorage module with following resources (contains
  resources from deprecated xDisk module):
- xDisk (from xDisk)
- xMountImage
- xWaitForDisk (from xDisk)
