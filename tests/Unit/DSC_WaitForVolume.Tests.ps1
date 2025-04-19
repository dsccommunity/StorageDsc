<#
    .SYNOPSIS
        Unit test for DSC_WaitForVolume DSC resource.
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
    $script:dscResourceName = 'DSC_WaitForVolume'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_WaitForVolume\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Assert-DriveLetterValid -MockWith {
            'C'
        }
    }

    It 'Should return the correct result' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $driveCParameters = @{
                DriveLetter      = 'C'
                RetryIntervalSec = 5
                RetryCount       = 20
            }

            $resource = Get-TargetResource @driveCParameters

            $resource.DriveLetter | Should -Be $driveCParameters.DriveLetter
            $resource.RetryIntervalSec | Should -Be $driveCParameters.RetryIntervalSec
            $resource.RetryCount | Should -Be $driveCParameters.RetryCount
        }

        Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
    }
}

Describe 'DSC_WaitForVolume\Set-TargetResource' -Tag 'Set' {
    Context 'When drive C is ready' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'C'
            }

            Mock -CommandName Start-Sleep
            Mock -CommandName Get-PSDrive
            Mock -CommandName Get-Volume -MockWith {
                @{
                    DriveLetter = 'C'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $driveCParameters = @{
                    DriveLetter      = 'C'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                { Set-TargetResource @driveCParameters } | Should -Not -Throw

            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Sleep -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 0 -Scope It
        }
    }

    Context 'When drive C does not become ready' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'C'
            }

            Mock -CommandName Start-Sleep
            Mock -CommandName Get-PSDrive
            Mock -CommandName Get-Volume
        }

        It 'Should throw VolumeNotFoundAfterError' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $driveCParameters = @{
                    DriveLetter      = 'C'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.VolumeNotFoundAfterError -f $driveCParameters.DriveLetter, $driveCParameters.RetryCount
                )

                { Set-TargetResource @driveCParameters } | Should -Throw $errorRecord

            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 20 -Scope It
            Should -Invoke -CommandName Start-Sleep -Exactly -Times 20 -Scope It
            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 20 -Scope It
        }
    }
}

Describe 'DSC_WaitForVolume\Test-TargetResource' -Tag 'Test' {
    Context 'When drive C is ready' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'C'
            }

            Mock -CommandName Get-PSDrive
            Mock -CommandName Get-Volume -MockWith {
                @{
                    DriveLetter = 'C'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $driveCParameters = @{
                    DriveLetter      = 'C'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                Test-TargetResource @driveCParameters | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
        }
    }

    Context 'When drive C is not ready' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'C'
            }

            Mock -CommandName Get-PSDrive
            Mock -CommandName Get-Volume
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $driveCParameters = @{
                    DriveLetter      = 'C'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                Test-TargetResource @driveCParameters | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-PSDrive -Exactly -Times 1 -Scope It
        }
    }
}
