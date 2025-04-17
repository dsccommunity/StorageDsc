<#
    .SYNOPSIS
        Validates whether the Dev Drive feature is available and enabled on the system.
#>
function Assert-DevDriveFeatureAvailable
{
    [CmdletBinding()]
    [OutputType([System.Void])]
    param
    ()

    $devDriveHelper = Get-DevDriveWin32HelperScript
    Write-Verbose -Message ($script:localizedData.CheckingDevDriveEnablementMessage)

    $IsApiSetImplemented = Invoke-IsApiSetImplemented('api-ms-win-core-sysinfo-l1-2-6')
    $DevDriveEnablementType = [DevDrive.DevDriveHelper+DEVELOPER_DRIVE_ENABLEMENT_STATE]

    if ($IsApiSetImplemented)
    {
        try
        {
            # Based on the enablement result we will throw an error or return without doing anything.
            switch (Get-DevDriveEnablementState)
            {
                ($DevDriveEnablementType::DeveloperDriveEnablementStateError)
                {
                    throw $script:localizedData.DevDriveEnablementUnknownError
                }
                ($DevDriveEnablementType::DeveloperDriveDisabledBySystemPolicy)
                {
                    throw $script:localizedData.DevDriveDisabledBySystemPolicyError
                }
                ($DevDriveEnablementType::DeveloperDriveDisabledByGroupPolicy)
                {
                    throw $script:localizedData.DevDriveDisabledByGroupPolicyError
                }
                ($DevDriveEnablementType::DeveloperDriveEnabled)
                {
                    Write-Verbose -Message ($script:localizedData.DevDriveEnabledMessage)
                    return
                }
                default
                {
                    throw $script:localizedData.DevDriveEnablementUnknownError
                }
            }
        }
        # function may not exist in some versions of Windows in the apiset dll.
        catch [System.EntryPointNotFoundException]
        {
            Write-Verbose $_.Exception.Message
        }
    }

    <#
        If apiset isn't implemented or we get the EntryPointNotFoundException we should throw
        since the feature isn't available here.
    #>
    throw $script:localizedData.DevDriveFeatureNotImplementedError
}
