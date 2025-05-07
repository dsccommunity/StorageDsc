<#
    .SYNOPSIS
        Unit test for Assert-SizeMeetsMinimumDevDriveRequirement.
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

Describe 'StorageDsc.Common\Assert-SizeMeetsMinimumDevDriveRequirement' {
    Context 'When UserDesiredSize does not meet the minimum size for Dev Drive volumes' {
        It 'Should throw invalid argument error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $UserDesired10Gb = 10GB
                $ExpectedMessage = ($script:localizedData.MinimumSizeNeededToCreateDevDriveVolumeError -f ([Math]::Round($UserDesired10Gb / 1GB, 2)))

                $testParams = @{
                    UserDesiredSize = $UserDesired10Gb
                }

                { Assert-SizeMeetsMinimumDevDriveRequirement @testParams } | Should -Throw -ExpectedMessage $ExpectedMessage
            }
        }
    }

    Context 'When UserDesiredSize meets the minimum size for Dev Drive volumes' {
        It 'Should not throw invalid argument error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    UserDesiredSize = 50GB
                }

                { Assert-SizeMeetsMinimumDevDriveRequirement @testParams } | Should -Not -Throw
            }
        }
    }
}
