ConvertFrom-StringData @'
    GettingDiskMessage = Getting Disk '{0}' status for drive letter '{1}'.

    SettingDiskMessage = Setting Disk '{0}' status for drive letter '{1}'.
    SetDiskOnlineMessage = Setting disk number '{0}' is online.
    SetDiskReadwriteMessage = Setting disk number '{0}' to read/write.
    CheckingDiskPartitionStyleMessage = Checking disk number '{0}' partition style.
    InitializingDiskMessage = Initializing disk number '{0}'.
    DiskAlreadyInitializedMessage = Disk number '{0}' is already initialized with GPT.
    CreatingPartitionMessage = Creating partition on disk number '{0}' with drive letter '{1}' using {2}.
    DiskAlreadyInitializedError = Disk number '{0}' is already initialized with {1}.
    FormattingVolumeMessage = Formatting the volume as '{0}'.
    SuccessfullyInitializedMessage = Successfully initialized '{0}'.
    ChangingDriveLetterMessage = The volume already exists, setting drive letter to '{0}'.

    TestingDiskMessage = Testing Disk '{0}' status for drive letter '{1}'.
    CheckDiskInitializedMessage = Checking if disk number '{0}' is initialized.
    DiskNotFoundMessage = Disk number '{0}' was not found.
    DiskNotOnlineMessage = Disk number '{0}' is not online.
    DiskReadOnlyMessage = Disk number '{0}' is readonly.
    DiskNotGPTMessage = Disk number '{0}' is initialised with '{1}' partition style. GPT required.
    DriveLetterNotFoundMessage = Drive {0} was not found.
    DriveSizeMismatchMessage = Drive {0} size {1} does not match expected size {2}.
    DriveAllocationUnitSizeMismatchMessage = Drive {0} allocation unit size {1} kb does not match expected allocation unit size {2} kb.
    DriveLabelMismatch = Drive {0} label '{1}' does not match expected label '{2}'.
'@