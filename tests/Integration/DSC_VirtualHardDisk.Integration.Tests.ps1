[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'VirtualHardDisk'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'StorageDsc'
    $script:dscResourceFriendlyName = 'VirtualHardDisk'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe "$($script:dscResourceName)_CreateAndAttachFixedVhd_Integration" {
    BeforeAll {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop
    }

    Context 'Create and attach a fixed virtual disk' {
        BeforeAll {
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
    BeforeAll {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop
    }
    
    Context 'Create and attach a dynamically expanding virtual disk' {
        BeforeAll {
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
