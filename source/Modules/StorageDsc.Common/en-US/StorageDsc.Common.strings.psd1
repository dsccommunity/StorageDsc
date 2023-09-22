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
    DevDriveMinimumSizeError = Dev Drive volumes must be 50Gb or more in size.
    DevDriveNotEnoughSpaceToCreateDevDriveError = There is not enough unallocated space '{2}Gb' to create a Dev Drive volume of size '{1}Gb' on disk '{0}'.
    DevDriveOnlyAvailableForReFsError = "Only 'ReFS' is supported for Dev Drive volumes."
'@
