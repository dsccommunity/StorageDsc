<#
    .SYNOPSIS
        Unit test for Get-VirtualDiskHandle.
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
    $script:subModuleName = 'StorageDsc.VirtualHardDisk.Win32Helpers'

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

Describe 'StorageDsc.VirtualHardDisk.Win32Helpers\Get-VirtualDiskHandle' {
    Context 'Opening a virtual disk file failed due to exception' {
        BeforeAll {
            Mock -CommandName Get-VirtualDiskUsingWin32 -MockWith { 5 }
            Mock -CommandName Test-Path -MockWith { $true }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    VirtualDiskPath = 'C:\test.vhdx'
                    DiskFormat      = 'Vhdx'
                }

                $win32Error = [System.ComponentModel.Win32Exception]::new(5)
                $exception = [System.Exception]::new(
                    ($script:localizedData.OpenVirtualDiskError -f $testParams.VirtualDiskPath, $win32Error.Message), $win32Error
                )

                { Get-VirtualDiskHandle @testParams } | Should -Throw -ExpectedMessage $exception.Message
            }

            Should -Invoke -CommandName Get-VirtualDiskUsingWin32 -Exactly -Times 1 -Scope It
        }
    }

    Context 'Opening a virtual disk file successfully' {
        BeforeAll {
            Mock -CommandName Get-VirtualDiskUsingWin32 -MockWith { 0 }
            Mock -CommandName Test-Path -MockWith { $true }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    VirtualDiskPath = 'C:\test.vhdx'
                    DiskFormat      = 'Vhdx'
                }

                { Get-VirtualDiskHandle @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-VirtualDiskUsingWin32 -Exactly -Times 1 -Scope It
        }
    }
}
