ConvertFrom-StringData @'
    CheckingVirtualDiskExists = Checking virtual hard disk at location '{0}' exists and is mounted.
    VirtualHardDiskMayNotExistOrNotMounted = The virtual hard disk at location '{0}' does not exist or is not mounted.
    VirtualHardDiskDoesNotExistCreatingNow = The virtual hard disk at location '{0}' does not exist. Creating virtual hard disk now.
    VirtualHardDiskCurrentlyMounted = The virtual hard disk at location '{0}' was found and is mounted to the system.
    VirtualHardDiskCurrentlyMountedButShouldNotBe = The virtual hard disk at location '{0}' was found and is mounted to the system but it should not be.
    VhdFormatDiskSizeInvalid = The virtual hard disk size '{0}' was invalid for the 'vhd' format. Min supported value is 10 Mb and max supported value 2040 Gb.
    VhdxFormatDiskSizeInvalid = The virtual hard disk size '{0}' was invalid for the 'vhdx' format. Min supported value is 10 Mb and max supported value 64 Tb.
    VirtualDiskNotMounted = The virtual hard disk at location '{0}' is not mounted. Mounting virtual hard disk now.
    VirtualHardDiskDetachingImage = The virtual hard disk located at '{0}' is detaching.
    VirtualHardDiskUnsupportedFileType = The file type .{0} is not supported. Only .vhd and .vhdx file types are supported.
    VirtualHardDiskPathError = The path '{0}' must be a fully qualified path that starts with a Drive Letter.
    VirtualHardDiskExtensionAndFormatMismatchError = The path you entered '{0}' has extension '{1}' but the disk format entered is '{2}'. Both the extension and format must match.
    VirtualHardDiskNoExtensionError = The path '{0}' does not contain an extension. Supported extension types are '.vhd' and '.vhdx'.
    GettingVirtualHardDisk = Getting virtual hard disk information for virtual hard disk located at '{0}.
    RemovingCreatedVirtualHardDiskFile = The virtual hard disk file at location '{0}' is being removed due to an error while attempting to mount it to the system.
    VirtualDiskAdminError = Creating and mounting a virtual disk requires running PowerShell as an Administrator. Please launch PowerShell as Administrator and try again.
'@
