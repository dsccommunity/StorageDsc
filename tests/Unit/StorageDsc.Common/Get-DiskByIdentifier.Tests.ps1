<#
    .SYNOPSIS
        Unit test for Get-DiskByIdentifier.
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

Describe 'StorageDsc.Common\Get-DiskByIdentifier' {
    Context 'Disk exists that matches the specified Disk Number' {
        BeforeAll {
            Mock -CommandName Get-Disk -MockWith {
                @{
                    Number       = 10
                    UniqueId     = 'DiskUniqueId'
                    FriendlyName = 'DiskFriendlyName'
                    SerialNumber = 'DiskSerialNumber'
                    Guid         = [Guid]::NewGuid().ToString()
                    Location     = 'Integrated : Adapter 0 : Port 0 : Target 0 : LUN 10'
                }
            } -ParameterFilter { $Number -eq 10 }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId = 10
                }

                $result = Get-DiskByIdentifier @testParams

                $result.Number | Should -Be $testParams.DiskId
            }

            Should -Invoke -CommandName Get-Disk -ParameterFilter { $Number -eq 10 } -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk does not exist that matches the specified Disk Number' {
        BeforeAll {
            Mock -CommandName Get-Disk -ParameterFilter { $Number -eq 10 }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId = 10
                }

                Get-DiskByIdentifier @testParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Disk -ParameterFilter { $Number -eq 10 } -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk exists that matches the specified Disk Unique Id' {
        BeforeAll {
            Mock -CommandName Get-Disk -MockWith {
                @{
                    Number       = 10
                    UniqueId     = 'DiskUniqueId'
                    FriendlyName = 'DiskFriendlyName'
                    SerialNumber = 'DiskSerialNumber'
                    Guid         = [Guid]::NewGuid().ToString()
                    Location     = 'Integrated : Adapter 0 : Port 0 : Target 0 : LUN 10'
                }
            } -ParameterFilter { $UniqueId -eq 'DiskUniqueId' }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 'DiskUniqueId'
                    DiskIdType = 'UniqueId'
                }

                $result = Get-DiskByIdentifier @testParams

                $result.UniqueId | Should -Be $testParams.DiskId
            }

            Should -Invoke -CommandName Get-Disk -ParameterFilter { $UniqueId -eq 'DiskUniqueId' } -Exactly -Times 1
        }
    }

    Context 'Disk does not exist that matches the specified Disk Unique Id' {
        BeforeAll {
            Mock -CommandName Get-Disk -ParameterFilter { $UniqueId -eq 'DiskUniqueId' }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 'DiskUniqueId'
                    DiskIdType = 'UniqueId'
                }

                Get-DiskByIdentifier @testParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Disk -ParameterFilter { $UniqueId -eq 'DiskUniqueId' } -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk exists that matches the specified Disk Friendly Name' {
        BeforeAll {
            Mock -CommandName Get-Disk -MockWith {
                @{
                    Number       = 10
                    UniqueId     = 'DiskUniqueId'
                    FriendlyName = 'DiskFriendlyName'
                    SerialNumber = 'DiskSerialNumber'
                    Guid         = [Guid]::NewGuid().ToString()
                    Location     = 'Integrated : Adapter 0 : Port 0 : Target 0 : LUN 10'
                }
            } -ParameterFilter { $FriendlyName -eq 'DiskFriendlyName' }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 'DiskFriendlyName'
                    DiskIdType = 'FriendlyName'
                }

                $result = Get-DiskByIdentifier @testParams

                $result.FriendlyName | Should -Be $testParams.DiskId
            }

            Should -Invoke -CommandName Get-Disk -ParameterFilter { $FriendlyName -eq 'DiskFriendlyName' } -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk does not exist that matches the specified Disk Friendly Name' {
        BeforeAll {
            Mock -CommandName Get-Disk -ParameterFilter { $FriendlyName -eq 'DiskFriendlyName' }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 'DiskFriendlyName'
                    DiskIdType = 'FriendlyName'
                }

                Get-DiskByIdentifier @testParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Disk -ParameterFilter { $FriendlyName -eq 'DiskFriendlyName' } -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk exists that matches the specified Disk Serial Number' {
        BeforeAll {
            Mock -CommandName Get-Disk -MockWith {
                @{
                    Number       = 10
                    UniqueId     = 'DiskUniqueId'
                    FriendlyName = 'DiskFriendlyName'
                    SerialNumber = 'DiskSerialNumber'
                    Guid         = [Guid]::NewGuid().ToString()
                    Location     = 'Integrated : Adapter 0 : Port 0 : Target 0 : LUN 10'
                }
            } -ParameterFilter { $SerialNumber -eq 'DiskSerialNumber' }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 'DiskSerialNumber'
                    DiskIdType = 'SerialNumber'
                }

                $result = Get-DiskByIdentifier @testParams

                $result.SerialNumber | Should -Be $testParams.DiskId
            }

            Should -Invoke -CommandName Get-Disk -ParameterFilter { $SerialNumber -eq 'DiskSerialNumber' } -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk does not exist that matches the specified Disk Serial Number' {
        BeforeAll {
            Mock -CommandName Get-Disk -ParameterFilter { $SerialNumber -eq 'DiskSerialNumber' }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 'DiskSerialNumber'
                    DiskIdType = 'SerialNumber'
                }

                Get-DiskByIdentifier @testParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Disk -ParameterFilter { $SerialNumber -eq 'DiskSerialNumber' } -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk exists that matches the specified Disk Guid' {
        BeforeAll {
            $testDiskGuid = [Guid]::NewGuid().ToString()

            Mock -CommandName Get-Disk -MockWith {
                @{
                    Number       = 10
                    UniqueId     = 'DiskUniqueId'
                    FriendlyName = 'DiskFriendlyName'
                    SerialNumber = 'DiskSerialNumber'
                    Guid         = $testDiskGuid
                    Location     = 'Integrated : Adapter 0 : Port 0 : Target 0 : LUN 10'
                }
            }

            InModuleScope -Parameters @{
                testDiskGuid = $testDiskGuid
            } -ScriptBlock {
                $script:testDiskGuid = $testDiskGuid
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = $testDiskGuid
                    DiskIdType = 'Guid'
                }

                $result = Get-DiskByIdentifier @testParams

                $result.Guid | Should -Be $testParams.DiskId
            }

            Should -Invoke -CommandName Get-Disk -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk does not exist that matches the specified Disk Guid' {
        BeforeAll {
            Mock -CommandName Get-Disk
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = [Guid]::NewGuid().ToString()
                    DiskIdType = 'Guid'
                }

                Get-DiskByIdentifier @testParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Disk -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk exists that matches the specified Disk Location' {
        BeforeAll {
            Mock -CommandName Get-Disk -MockWith {
                @{
                    Number       = 10
                    UniqueId     = 'DiskUniqueId'
                    FriendlyName = 'DiskFriendlyName'
                    SerialNumber = 'DiskSerialNumber'
                    Guid         = [Guid]::NewGuid().ToString()
                    Location     = 'Integrated : Adapter 0 : Port 0 : Target 0 : LUN 10'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 'Integrated : Adapter 0 : Port 0 : Target 0 : LUN 10'
                    DiskIdType = 'Location'
                }

                $result = Get-DiskByIdentifier @testParams

                $result.Location | Should -Be $testParams.DiskId
            }

            Should -Invoke -CommandName Get-Disk -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disk does not exist that matches the specified Disk Location' {
        BeforeAll {
            Mock -CommandName Get-Disk
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 'Integrated : Adapter 0 : Port 0 : Target 0 : LUN 10'
                    DiskIdType = 'Location'
                }

                Get-DiskByIdentifier @testParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-Disk -Exactly -Times 1 -Scope It
        }
    }
}
