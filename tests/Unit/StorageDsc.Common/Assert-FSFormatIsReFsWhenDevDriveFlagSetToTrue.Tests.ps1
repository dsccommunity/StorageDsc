<#
    .SYNOPSIS
        Unit test for Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue.
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

Describe 'StorageDsc.Common\Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue' {
    Context 'When testing that only the ReFS file system is allowed' {
        It 'Should throw invalid argument error if a filesystem other than ReFS is passed in' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.FSFormatNotReFSWhenDevDriveFlagIsTrueError
                ) -ArgumentName 'FSFormat'

                $testParams = @{
                    FSFormat = 'test'
                }

                { Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue @testParams } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When testing Exception not thrown in Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue when ReFS file system passed in' {
        It 'Should not throw invalid argument error if ReFS filesystem is passed in' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FSFormat = 'ReFS'
                }

                { Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue @testParams } | Should -Not -Throw
            }
        }
    }
}
