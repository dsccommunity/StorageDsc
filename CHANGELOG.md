# Versions

## Unreleased

- Converted AppVeyor build process to use AppVeyor.psm1.
- Added support for auto generating wiki, help files, markdown linting
  and checking examples.
- Correct name of MSFT_xDiskAccessPath.tests.ps1.
- Move shared modules into Modules folder.
- Fixed unit tests.
- Removed support for WMI cmdlets.
- Opted in to Markdown and Example tests.
- Added CodeCov.io support.

## 2.9.0.0

- Updated readme.md to remove markdown best practice rule violations.
- Updated readme.md to match DSCResources/DscResource.Template/README.md.
- xDiskAccessPath:
  - Fix bug when re-attaching disk after mount point removed or detatched.
  - Additional log entries added for improved diagnostics.
  - Additional integration tests added.
  - Improve timeout loop.
- Converted integration tests to use ```$TestDrive``` as working folder or
  ```temp``` folder when persistence across tests is required.
- Suppress ```PSUseShouldProcessForStateChangingFunctions``` rule violations in resources.
- Rename ```Test-AccessPath``` function to ```Assert-AccessPathValid```.
- Rename ```Test-DriveLetter``` function to ```Assert-DriveLetterValid```.
- Added ```CommonResourceHelper.psm1``` module (based on PSDscResources).
- Added ```CommonTestsHelper.psm1``` module  (based on PSDscResources).
- Converted all modules to load localization data using ```Get-LocalizedData```
  from CommonResourceHelper.
- Converted all exception calls and tests to use functions in
  ```CommonResourceHelper.psm1``` and ```CommonTestsHelper.psm1``` respectively.
- Fixed examples:
  - Sample_InitializeDataDisk.ps1
  - Sample_InitializeDataDiskWithAccessPath.ps1
  - Sample_xMountImage_DismountISO.ps1
- xDisk:
  - Improve timeout loop.

## 2.8.0.0

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

## 2.7.0.0

- Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.

## 2.6.0.0

- MSFT_xDisk: Replaced Get-WmiObject with Get-CimInstance

## 2.5.0.0

- added test for existing file system to allow simple drive letter assignment in
  MSFT_xDisk.psm1
- modified Test verbose message to correctly reflect blocksize value in
  MSFT_xDisk.psm1 line 217
- added unit test for new volume with out existing partition for MSFT_xDisk.psm1
- Fixed error propagation

## 2.4.0.0

- Fixed bug where AllocationUnitSize was not used

## 2.3.0.0

- Added support for `AllocationUnitSize` in `xDisk`.

## 2.2.0.0

- Updated documentation: changed parameter name Count to RetryCount in
  xWaitForDisk resource

## 2.1.0.0

- Fixed encoding

## 2.0.0.0

- Breaking change: Added support for following properties: DriveLetter, Size,
  FSLabel. DriveLetter is a new key property.

## 1.0.0.0

This module was previously named **xDisk**, the version is regressing to a
"1.0.0.0" release with the addition of xMountImage.

- Initial release of xStorage module with following resources (contains
  resources from deprecated xDisk module):
- xDisk (from xDisk)
- xMountImage
- xWaitForDisk (from xDisk)
