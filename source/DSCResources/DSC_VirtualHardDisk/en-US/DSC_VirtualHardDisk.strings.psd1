ConvertFrom-StringData @'
    CheckingVirtualDiskExistsMessage = Checking virtual disk at location '{0}' exists and is attached.
    VirtualDiskDoesNotExistMessage = The virtual disk at location '{0}' does not exist.
    VirtualDiskDoesNotExistCreatingNowMessage = The virtual disk at location '{0}' does not exist. Creating virtual disk now.
    VirtualDiskNotAttachedOrFileCorruptedMessage = The virtual disk at location '{0}' is not attached to the system. The file exists but maybe corrupted.
    VirtualDiskCurrentlyAttachedMessage = The virtual disk at location '{0}' was found and is attached to the system.
    VhdFormatDiskSizeInvalidMessage = The virtual disk size '{0}' was invalid for the 'vhd' format. Min supported value is 10Mb and max supported value 2040Gb.
    VhdxFormatDiskSizeInvalidMessage = The virtual disk size '{0}' was invalid for the 'vhdx' format. Min supported value is 10Mb and max supported value 64Tb.
    VirtualDiskNotAttachedMessage = The virtual disk at location '{0}' is not attached. Attaching virtual disk now.
'@
