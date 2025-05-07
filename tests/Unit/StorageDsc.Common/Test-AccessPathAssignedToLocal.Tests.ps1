<#
    .SYNOPSIS
        Unit test for Test-AccessPathAssignedToLocal.
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

Describe 'StorageDsc.Common\Test-AccessPathAssignedToLocal' {
    Context 'Contains a single access path that is local' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    AccessPath = 'c:\MountPoint\'
                }

                Test-AccessPathAssignedToLocal @testParams | Should -BeTrue
            }
        }
    }

    Context 'Contains a single access path that is not local' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    AccessPath = '\\?\Volume{905551f3-33a5-421d-ac24-c993fbfb3184}\'
                }

                Test-AccessPathAssignedToLocal @testParams | Should -BeFalse
            }
        }
    }

    Context 'Contains multiple access paths where one is local' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    AccessPath = @('c:\MountPoint\', '\\?\Volume{905551f3-33a5-421d-ac24-c993fbfb3184}\')
                }

                Test-AccessPathAssignedToLocal @testParams | Should -BeTrue
            }
        }
    }

    Context 'Contains multiple access paths where none are local' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    AccessPath = @('\\?\Volume{905551f3-33a5-421d-ac24-c993fbfb3184}\', '\\?\Volume{905551f3-33a5-421d-ac24-c993fbfb3184}\')
                }

                Test-AccessPathAssignedToLocal @testParams | Should -BeFalse
            }
        }
    }
}
