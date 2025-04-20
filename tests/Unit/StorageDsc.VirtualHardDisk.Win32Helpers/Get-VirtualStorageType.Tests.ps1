<#
    .SYNOPSIS
        Unit test for Get-VirtualStorageType.
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

Describe 'StorageDsc.VirtualHardDisk.Win32Helpers\Get-VirtualStorageType' {
    Context 'Storage type requested for vhd disk format' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-VirtDiskWin32HelperScript
                $virtualStorageType = New-Object -TypeName VirtDisk.Helper+VIRTUAL_STORAGE_TYPE
                $virtualStorageType.VendorId = [VirtDisk.Helper]::VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT
                $virtualStorageType.DeviceId = [VirtDisk.Helper]::VIRTUAL_STORAGE_TYPE_DEVICE_VHD

                $result = Get-VirtualStorageType -DiskFormat 'vhd'
                { $result } | Should -Not -Throw

                $result.VendorId | Should -Be $virtualStorageType.VendorId
                $result.DeviceId | Should -Be $virtualStorageType.DeviceId
            }
        }
    }

    Context 'Storage type requested for vhdx disk format' {
        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-VirtDiskWin32HelperScript
                $virtualStorageType = New-Object -TypeName VirtDisk.Helper+VIRTUAL_STORAGE_TYPE
                $virtualStorageType.VendorId = [VirtDisk.Helper]::VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT
                $virtualStorageType.DeviceId = [VirtDisk.Helper]::VIRTUAL_STORAGE_TYPE_DEVICE_VHDX

                $result = Get-VirtualStorageType -DiskFormat 'vhdx'

                { $result } | Should -Not -Throw

                $result.VendorId | Should -Be $virtualStorageType.VendorId
                $result.DeviceId | Should -Be $virtualStorageType.DeviceId
            }
        }
    }
}
