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

# $mockedDriveC = [pscustomobject] @{
#     DriveLetter = 'C'
# }

# $driveCParameters = @{
#     DriveLetter      = 'C'
#     RetryIntervalSec = 5
#     RetryCount       = 20
# }

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

# Describe 'DSC_WaitForVolume\Set-TargetResource' {
#     Mock Start-Sleep
#     Mock Get-PSDrive

#     Context 'drive C is ready' {
#         Mock Get-Volume -MockWith { return $mockedDriveC } -Verifiable

#         It 'Should not throw an exception' {
#             { Set-targetResource @driveCParameters -Verbose } | Should -Not -Throw
#         }

#         It 'the correct mocks were called' {
#             Assert-VerifiableMock
#             Assert-MockCalled -CommandName Start-Sleep -Times 0
#             Assert-MockCalled -CommandName Get-PSDrive -Times 0
#             Assert-MockCalled -CommandName Get-Volume -Times 1
#         }
#     }
#     Context 'drive C does not become ready' {
#         Mock Get-Volume -MockWith { } -Verifiable

#         $errorRecord = Get-InvalidOperationRecord `
#             -Message $($LocalizedData.VolumeNotFoundAfterError `
#                 -f $driveCParameters.DriveLetter, $driveCParameters.RetryCount)

#         It 'should throw VolumeNotFoundAfterError' {
#             { Set-targetResource @driveCParameters -Verbose } | Should -Throw $errorRecord
#         }

#         It 'the correct mocks were called' {
#             Assert-VerifiableMock
#             Assert-MockCalled -CommandName Start-Sleep -Times $driveCParameters.RetryCount
#             Assert-MockCalled -CommandName Get-PSDrive -Times $driveCParameters.RetryCount
#             Assert-MockCalled -CommandName Get-Volume -Times $driveCParameters.RetryCount
#         }
#     }
# }

# Describe 'DSC_WaitForVolume\Test-TargetResource' {
#     Mock Get-PSDrive

#     Context 'drive C is ready' {
#         Mock Get-Volume -MockWith { return $mockedDriveC } -Verifiable

#         $script:result = $null

#         It 'calling test Should Not Throw' {
#             {
#                 $script:result = Test-TargetResource @driveCParameters -Verbose
#             } | Should -Not -Throw
#         }

#         It 'result Should Be true' {
#             $script:result | Should -Be $true
#         }

#         It 'the correct mocks were called' {
#             Assert-VerifiableMock
#             Assert-MockCalled -CommandName Get-PSDrive -Times 1
#             Assert-MockCalled -CommandName Get-Volume -Times 1
#         }
#     }
#     Context 'drive C is not ready' {
#         Mock Get-Volume -MockWith { } -Verifiable

#         $script:result = $null

#         It 'calling test Should Not Throw' {
#             {
#                 $script:result = Test-TargetResource @driveCParameters -Verbose
#             } | Should -Not -Throw
#         }

#         It 'result Should Be false' {
#             $script:result | Should -Be $false
#         }

#         It 'the correct mocks were called' {
#             Assert-VerifiableMock
#             Assert-MockCalled -CommandName Get-PSDrive -Times 1
#             Assert-MockCalled -CommandName Get-Volume -Times 1
#         }
#     }
# }
#endregion
