$script:dscModuleName = 'StorageDsc'
$script:dscResourceName = 'DSC_VirtualHardDisk'

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile -Verbose -ErrorAction Stop

    Describe "$($script:dscResourceName)_CreateAndAttachFixedVhd_Integration" {
        Context 'Create and attach a fixed virtual disk' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_CreateAndAttachFixedVhd_Config" -OutputPath $TestDrive
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $currentState = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_CreateAndAttachFixedVhd_Config"
                }
                $currentState.FilePath   | Should -Be $script:TestFixedVirtualHardDiskVhd.FilePath
                $currentState.DiskSize   | Should -Be 5Gb
                $currentState.Ensure     | Should -Be 'Present'
            }

            AfterAll {
                Dismount-DiskImage -ImagePath $script:TestFixedVirtualHardDiskVhd.FilePath -StorageType VHD
                Remove-Item -Path $script:TestFixedVirtualHardDiskVhd.FilePath -Force
            }
        }
    }

    Describe "$($script:dscResourceName)_CreateAndAttachDynamicallyExpandingVhdx_Integration" {
        Context 'Create and attach a dynamically expanding virtual disk' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_CreateAndAttachDynamicallyExpandingVhdx_Config" -OutputPath $TestDrive
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $currentState = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_CreateAndAttachDynamicallyExpandingVhdx_Config"
                }
                $currentState.FilePath   | Should -Be $script:TestDynamicVirtualHardDiskVhdx.FilePath
                $currentState.DiskSize   | Should -Be 10Gb
                $currentState.Ensure     | Should -Be 'Present'
            }

            AfterAll {
                Dismount-DiskImage -ImagePath $script:TestDynamicVirtualHardDiskVhdx.FilePath -StorageType VHDX
                Remove-Item -Path $script:TestDynamicVirtualHardDiskVhdx.FilePath -Force
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
