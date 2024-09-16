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
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName   = 'localhost'
                        FilePath   = "$($pwd.drive.name):\newTestFixedVhd.vhd"
                        Attached   = $true
                        DiskSize   = 5GB
                        DiskFormat = 'Vhd'
                        DiskType   = 'Fixed'
                        Ensure     = 'Present'
                    }
                )
            }

            It 'Should compile the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_CreateAndAttachFixedVhd_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                } | Should -Not -Throw
            }

            It 'Should apply the MOF without throwing' {
                {
                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $currentState = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_CreateAndAttachFixedVhd_Config"
                }
                $currentState.FilePath   | Should -Be $configData.AllNodes.FilePath
                $currentState.DiskSize   | Should -Be $configData.AllNodes.DiskSize
                $currentState.Attached   | Should -Be $configData.AllNodes.Attached
                $currentState.Ensure     | Should -Be $configData.AllNodes.Ensure
            }

            AfterAll {
                Dismount-DiskImage -ImagePath $TestFixedVirtualHardDiskVhdPath -StorageType VHD
                Remove-Item -Path $TestFixedVirtualHardDiskVhdPath -Force
            }
        }
    }

    Describe "$($script:dscResourceName)_CreateAndAttachDynamicallyExpandingVhdx_Integration" {
        Context 'Create and attach a dynamically expanding virtual disk' {
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName   = 'localhost'
                        FilePath   = "$($pwd.drive.name):\newTestDynamicVhdx.vhdx"
                        Attached   = $true
                        DiskSize   = 10GB
                        DiskFormat = 'Vhdx'
                        DiskType   = 'Dynamic'
                        Ensure     = 'Present'
                    }
                )
            }

            It 'Should compile the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_CreateAndAttachDynamicallyExpandingVhdx_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                } | Should -Not -Throw
            }

            It 'Should apply the MOF without throwing' {
                {
                    Start-DscConfiguration `
                        -Path $TestDrive `
                        -ComputerName localhost `
                        -Wait `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $currentState = Get-DscConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_CreateAndAttachDynamicallyExpandingVhdx_Config"
                }
                $currentState.FilePath   | Should -Be $configData.AllNodes.FilePath
                $currentState.DiskSize   | Should -Be $configData.AllNodes.DiskSize
                $currentState.Attached   | Should -Be $configData.AllNodes.Attached
                $currentState.Ensure     | Should -Be $configData.AllNodes.Ensure
            }

            AfterAll {
                Dismount-DiskImage -ImagePath $TestDynamicVirtualHardDiskVhdx -StorageType VHDX
                Remove-Item -Path $TestDynamicVirtualHardDiskVhdx -Force
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
