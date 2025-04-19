<#
    .SYNOPSIS
        Unit test for Assert-DriveLetterValid.
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

Describe 'StorageDsc.Common\Assert-DriveLetterValid' {
    BeforeAll {
        $driveLetterGood = 'C'
        $driveLetterGoodwithColon = 'C:'
        $driveLetterBad = '1'
        $driveLetterBadColon = ':C'
        $driveLetterBadTooLong = 'FE:'

        $accessPathGood = 'c:\Good'
        $accessPathGoodWithSlash = 'c:\Good\'
        $accessPathBad = 'c:\Bad'
    }

    Context 'Drive letter is good, has no colon and colon is not required' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DriveLetter = 'C'
                }

                Assert-DriveLetterValid @testParams | Should -Be $testParams.DriveLetter
            }
        }
    }

    Context 'Drive letter is good, has no colon but colon is required' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DriveLetter = 'C'
                    Colon       = $true
                }

                Assert-DriveLetterValid @testParams | Should -Be 'C:'
            }
        }
    }

    Context 'Drive letter is good, has a colon but colon is not required' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DriveLetter = 'C:'
                }

                Assert-DriveLetterValid @testParams | Should -Be 'C'
            }
        }
    }

    Context 'Drive letter is good, has a colon and colon is required' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DriveLetter = 'C:'
                    Colon       = $true
                }

                Assert-DriveLetterValid @testParams | Should -Be $testParams.DriveLetter
            }
        }
    }

    Context 'Drive letter is non alpha' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DriveLetter = '1'
                }

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.InvalidDriveLetterFormatError -f $testParams.DriveLetter
                ) -ArgumentName 'DriveLetter'

                { Assert-DriveLetterValid @testParams } | Should -Throw $errorRecord
            }
        }
    }

    Context 'Drive letter has a bad colon location' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DriveLetter = ':C'
                }

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.InvalidDriveLetterFormatError -f $testParams.DriveLetter
                ) -ArgumentName 'DriveLetter'

                { Assert-DriveLetterValid @testParams } | Should -Throw $errorRecord
            }
        }
    }

    Context 'Drive letter is too long' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DriveLetter = 'FE:'
                }

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.InvalidDriveLetterFormatError -f $testParams.DriveLetter
                ) -ArgumentName 'DriveLetter'

                { Assert-DriveLetterValid @testParams } | Should -Throw $errorRecord
            }
        }
    }
}
