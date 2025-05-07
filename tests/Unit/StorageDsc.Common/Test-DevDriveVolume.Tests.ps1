<#
    .SYNOPSIS
        Unit test for Test-DevDriveVolume.
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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'StorageDsc.Common\Test-DevDriveVolume' {
    Context 'When testing whether a volume is a Dev Drive volume and the volume is a Dev Drive volume' {
        BeforeAll {
            Mock -CommandName Invoke-DeviceIoControlWrapperForDevDriveQuery -MockWith { $true }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    VolumeGuidPath = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                }

                Test-DevDriveVolume @testParams | Should -BeTrue
            }

            Should -Invoke -CommandName Invoke-DeviceIoControlWrapperForDevDriveQuery -Exactly -Times 1 -Scope It
        }
    }

    Context 'When testing whether a volume is a Dev Drive volume and the volume is not a Dev Drive volume' {
        BeforeAll {
            Mock -CommandName Invoke-DeviceIoControlWrapperForDevDriveQuery -MockWith { $false }
        }


        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    VolumeGuidPath = '\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\'
                }

                Test-DevDriveVolume @testParams | Should -BeFalse
            }

            Should -Invoke -CommandName Invoke-DeviceIoControlWrapperForDevDriveQuery -Exactly -Times 1 -Scope It
        }
    }
}
