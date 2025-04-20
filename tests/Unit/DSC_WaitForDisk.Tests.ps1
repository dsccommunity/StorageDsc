<#
    .SYNOPSIS
        Unit test for DSC_WaitForDisk DSC resource.
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
    $script:dscResourceName = 'DSC_WaitForDisk'

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

Describe 'DSC_WaitForDisk\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        Mock -CommandName Test-TargetResource -MockWith { return $true }
    }

    Context 'Disk is specified by Number' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByNumber = @{
                    DiskId           = 1
                    DiskIdType       = 'Number'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $result = Get-TargetResource @disk0ParametersByNumber

                { $result } | Should -Not -Throw
                $result.DiskId | Should -Be $disk0ParametersByNumber.DiskId
                $result.DiskIdType | Should -Be 'Number'
                $result.RetryIntervalSec | Should -Be $disk0ParametersByNumber.RetryIntervalSec
                $result.RetryCount | Should -Be $disk0ParametersByNumber.RetryCount
                $result.IsAvailable | Should -BeTrue
            }

            Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk is specified by Unique Id' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByUniqueId = @{
                    DiskId           = 'TESTDISKUNIQUEID'
                    DiskIdType       = 'UniqueId'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $result = Get-TargetResource @disk0ParametersByUniqueId

                { $result } | Should -Not -Throw
                $result.DiskId | Should -Be $disk0ParametersByUniqueId.DiskId
                $result.DiskIdType | Should -Be 'UniqueId'
                $result.RetryIntervalSec | Should -Be $disk0ParametersByUniqueId.RetryIntervalSec
                $result.RetryCount | Should -Be $disk0ParametersByUniqueId.RetryCount
                $result.IsAvailable | Should -BeTrue
            }

            Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk is specified by Guid' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByGptGuid = @{
                    DiskId           = [Guid]::NewGuid()
                    DiskIdType       = 'Guid'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $result = Get-TargetResource @disk0ParametersByGptGuid

                { $result } | Should -Not -Throw
                $result.DiskId | Should -Be $disk0ParametersByGptGuid.DiskId
                $result.DiskIdType | Should -Be 'Guid'
                $result.RetryIntervalSec | Should -Be $disk0ParametersByGptGuid.RetryIntervalSec
                $result.RetryCount | Should -Be $disk0ParametersByGptGuid.RetryCount
                $result.IsAvailable | Should -BeTrue
            }

            Should -Invoke -CommandName Test-TargetResource -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_WaitForDisk\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Start-Sleep
    }

    Context 'When the disk is ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier -MockWith {
                return @{
                    Number       = 1
                    UniqueId     = 'TESTDISKUNIQUEID'
                    Guid         = [Guid]::NewGuid()
                    FriendlyName = 'Test Disk'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByNumber = @{
                    DiskId           = 1
                    DiskIdType       = 'Number'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                { Set-TargetResource @disk0ParametersByNumber } | Should -Not -Throw
            }

            Should -Invoke -CommandName Start-Sleep -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
        }
    }

    Context 'When disk with Unique Id is ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier -MockWith {
                return  @{
                    Number       = 1
                    UniqueId     = 'TESTDISKUNIQUEID'
                    Guid         = [Guid]::NewGuid()
                    FriendlyName = 'Test Disk'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByUniqueId = @{
                    DiskId           = 'TESTDISKUNIQUEID'
                    DiskIdType       = 'UniqueId'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                { Set-TargetResource @disk0ParametersByUniqueId } | Should -Not -Throw
            }

            Should -Invoke -CommandName Start-Sleep -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
        }
    }

    Context 'When disk with Guid is ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier -MockWith {
                return @{
                    Number       = 1
                    UniqueId     = 'TESTDISKUNIQUEID'
                    Guid         = [Guid]::NewGuid()
                    FriendlyName = 'Test Disk'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByGptGuid = @{
                    DiskId           = [Guid]::NewGuid()
                    DiskIdType       = 'Guid'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                { Set-TargetResource @disk0ParametersByGptGuid } | Should -Not -Throw
            }

            Should -Invoke -CommandName Start-Sleep -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
        }
    }

    Context 'When disk does not become ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByNumber = @{
                    DiskId           = 1
                    DiskIdType       = 'Number'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DiskNotFoundAfterError -f 'Number', $disk0ParametersByNumber.DiskId, $disk0ParametersByNumber.RetryCount
                )

                { Set-TargetResource @disk0ParametersByNumber } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Start-Sleep -Exactly -Times 20 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 20 -Scope It
        }
    }

    Context 'When disk with Unique Id does not become ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByUniqueId = @{
                    DiskId           = 'TESTDISKUNIQUEID'
                    DiskIdType       = 'UniqueId'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DiskNotFoundAfterError -f 'UniqueId', $disk0ParametersByUniqueId.DiskId, $disk0ParametersByUniqueId.RetryCount
                )

                { Set-TargetResource @disk0ParametersByUniqueId } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Start-Sleep -Exactly -Times 20 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 20 -Scope It
        }
    }

    Context 'When disk with Guid does not become ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier
        }

        It 'Should throw DiskNotFoundAfterError' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByGptGuid = @{
                    DiskId           = [Guid]::NewGuid()
                    DiskIdType       = 'Guid'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DiskNotFoundAfterError -f 'Guid', $disk0ParametersByGptGuid.DiskId, $disk0ParametersByGptGuid.RetryCount
                )

                { Set-TargetResource @disk0ParametersByGptGuid } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Start-Sleep -Exactly -Times 20 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 20 -Scope It
        }
    }
}

Describe 'DSC_WaitForDisk\Test-TargetResource' -Tag 'Test' {
    Context 'When disk with number is ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier -MockWith {
                return @{
                    Number       = 1
                    UniqueId     = 'TESTDISKUNIQUEID'
                    Guid         = [Guid]::NewGuid()
                    FriendlyName = 'Test Disk'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByNumber = @{
                    DiskId           = 1
                    DiskIdType       = 'Number'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $result = Test-TargetResource @disk0ParametersByNumber

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk with Unique Id is ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier -MockWith {
                return                @{
                    Number       = 1
                    UniqueId     = 'TESTDISKUNIQUEID'
                    Guid         = [Guid]::NewGuid()
                    FriendlyName = 'Test Disk'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByUniqueId = @{
                    DiskId           = 'TESTDISKUNIQUEID'
                    DiskIdType       = 'UniqueId'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $result = Test-TargetResource @disk0ParametersByUniqueId

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
        }
    }

    Context 'When disk with Guid is ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier -MockWith {
                return @{
                    Number       = 1
                    UniqueId     = 'TESTDISKUNIQUEID'
                    Guid         = [Guid]::NewGuid()
                    FriendlyName = 'Test Disk'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByGptGuid = @{
                    DiskId           = [Guid]::NewGuid()
                    DiskIdType       = 'Guid'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $result = Test-TargetResource @disk0ParametersByGptGuid

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk by Number does not become ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByNumber = @{
                    DiskId           = 1
                    DiskIdType       = 'Number'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $result = Test-TargetResource @disk0ParametersByNumber

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
        }
    }


    Context 'When disk with Unique Id does not become ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByUniqueId = @{
                    DiskId           = 'TESTDISKUNIQUEID'
                    DiskIdType       = 'UniqueId'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $result = Test-TargetResource @disk0ParametersByUniqueId

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
        }
    }

    Context 'When disk with Guid does not become ready' {
        BeforeAll {
            Mock -CommandName Get-DiskByIdentifier
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $disk0ParametersByGptGuid = @{
                    DiskId           = [Guid]::NewGuid()
                    DiskIdType       = 'Guid'
                    RetryIntervalSec = 5
                    RetryCount       = 20
                }

                $result = Test-TargetResource @disk0ParametersByGptGuid

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
        }
    }
}
