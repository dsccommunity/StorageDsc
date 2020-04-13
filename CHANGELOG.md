# Change log for StorageDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
