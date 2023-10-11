ConvertFrom-StringData @'
    GetServiceInformation = Retrieving {0} service information.
    RestartService = Restarting the {0} service.
    UnknownService = Unable to find the desired service.
    InvalidDriveLetterFormatError = Drive Letter format '{0}' is not valid.
    InvalidAccessPathError = Access Path '{0}' is not found.
    DevDriveEnablementUnknownError = Unable to get Dev Drive enablement status.
    DevDriveDisabledBySystemPolicyError = Dev Drive feature disabled due to system policy.
    DevDriveDisabledByGroupPolicyError =  Dev Drive feature disabled due to group policy.
    DevDriveEnabledMessage = Dev Drive feature is enabled on this system.
    CheckingDevDriveEnablementMessage = Checking if the Dev Drive feature is available and enabled on the system.
    DevDriveFeatureNotImplementedError = Dev Drive feature is not implemented on this system.
    MinimumSizeNeededToCreateDevDriveVolumeError = To configure a volume as a Dev Drive volume the size parameter must be 50 Gb or more. Size of '{0} Gb' was specified.
    FSFormatNotReFSWhenDevDriveFlagIsTrueError = Only the 'ReFS' file system can be used with FSFormat when the Dev Drive flag is set to true.
'@
