ConvertFrom-StringData @'
    UsingGetCimInstanceToFetchDriveLetter = Using Get-CimInstance to get the drive letter of optical disks in the system.
    NoOpticalDiskDrive = Without an optical disk in the system, this resource has nothing to do.  Note that this resource does not change the drive letter of mounted ISOs.
    OpticalDriveSetAsRequested = Optical disk drive letter is currently set to {0} as requested.
    OpticalDriveNotSetAsRequested = Optical disk drive letter is currently set to {0}, not {1} as requested.

    AttemptingToSetDriveLetter = The current drive letter is {0}, attempting to set to {1}.

    OpticalDiskDriveFound = Optical disk found with device id: {0}.
    DriveLetterVolumeType = Volume with driveletter {0} is type '{1}' (type '5' is an optical disk).
    DriveLetterExistsButNotOptical = Volume with driveletter {0} is already present but is not a optical disk.
'@
