<#
    .SYNOPSIS
        Unit test for Assert-DevDriveFeatureAvailable.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'StorageDsc'
    $script:subModuleName = 'StorageDsc.Common'

    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force
}

Describe 'StorageDsc.Common\Assert-DevDriveFeatureAvailable' {
    Context 'When testing the Dev Drive enablement state and the dev drive feature not implemented' {
        BeforeAll {
            Mock -CommandName Invoke-IsApiSetImplemented -MockWith { $false }
        }

        It 'Should throw with the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Assert-DevDriveFeatureAvailable } | Should -Throw -ExpectedMessage $script:localizedData.DevDriveFeatureNotImplementedError
            }

            Should -Invoke -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing the Dev Drive enablement state returns an enablement state not defined in the enum' {
        BeforeAll {
            Mock -CommandName Invoke-IsApiSetImplemented -MockWith { $true }
            Mock -CommandName Get-DevDriveEnablementState -MockWith { $null }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Assert-DevDriveFeatureAvailable } | Should -Throw -ExpectedMessage $script:localizedData.DevDriveEnablementUnknownError
            }

            Should -Invoke -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DevDriveEnablementState -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing the Dev Drive enablement state and the dev drive feature is disabled by group policy' {
        BeforeAll {
            Get-DevDriveWin32HelperScript
            $DevDriveEnablementType = [DevDrive.DevDriveHelper+DEVELOPER_DRIVE_ENABLEMENT_STATE]

            Mock -CommandName Invoke-IsApiSetImplemented -MockWith { $true }
            Mock -CommandName Get-DevDriveEnablementState -MockWith { $DevDriveEnablementType::DeveloperDriveDisabledByGroupPolicy }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Assert-DevDriveFeatureAvailable } | Should -Throw -ExpectedMessage $script:localizedData.DevDriveDisabledByGroupPolicyError
            }

            Should -Invoke -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DevDriveEnablementState -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing the Dev Drive enablement state and the dev drive feature is disabled by system policy' {
        BeforeAll {
            Get-DevDriveWin32HelperScript
            $DevDriveEnablementType = [DevDrive.DevDriveHelper+DEVELOPER_DRIVE_ENABLEMENT_STATE]

            Mock -CommandName Invoke-IsApiSetImplemented -MockWith { $true }
            Mock -CommandName Get-DevDriveEnablementState -MockWith { $DevDriveEnablementType::DeveloperDriveDisabledBySystemPolicy }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Assert-DevDriveFeatureAvailable } | Should -Throw -ExpectedMessage $script:localizedData.DeveloperDriveDisabledBySystemPolicy
            }

            Should -Invoke -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DevDriveEnablementState -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing the Dev Drive enablement state and the enablement state is unknown' {
        BeforeAll {
            Get-DevDriveWin32HelperScript
            $DevDriveEnablementType = [DevDrive.DevDriveHelper+DEVELOPER_DRIVE_ENABLEMENT_STATE]

            Mock -CommandName Invoke-IsApiSetImplemented -MockWith { $true }
            Mock -CommandName Get-DevDriveEnablementState -MockWith { $DevDriveEnablementType::DeveloperDriveEnablementStateError }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Assert-DevDriveFeatureAvailable } | Should -Throw -ExpectedMessage $script:localizedData.DevDriveEnablementUnknownError
            }

            Should -Invoke -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DevDriveEnablementState -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing Dev Drive enablement state and the enablement state is set to enabled' {
        BeforeAll {
            Get-DevDriveWin32HelperScript
            $DevDriveEnablementType = [DevDrive.DevDriveHelper+DEVELOPER_DRIVE_ENABLEMENT_STATE]
            
            Mock -CommandName Invoke-IsApiSetImplemented -MockWith { $true }
            Mock -CommandName Get-DevDriveEnablementState -MockWith { $DevDriveEnablementType::DeveloperDriveEnabled }
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Assert-DevDriveFeatureAvailable } | Should -Not -Throw
            }

            Should -Invoke -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DevDriveEnablementState -Exactly -Times 1 -Scope It
        }
    }
}
