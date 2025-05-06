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
    $script:dscResourceFriendlyName = 'WaitForDisk'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'StorageDsc'
    $script:dscResourceFriendlyName = 'WaitForDisk'
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

Describe "$($script:dscResourceName)_Integration" {
    BeforeAll {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        # Create a VHD and attach it to the computer
        $VHDPath = Join-Path -Path $TestDrive `
            -ChildPath 'TestDisk.vhd'
        $null = New-VDisk -Path $VHDPath -SizeInMB 1024 -Initialize
        $null = Mount-DiskImage -ImagePath $VHDPath -StorageType VHD -NoDriveLetter
        $diskImage = Get-DiskImage -ImagePath $VHDPath
        $disk = Get-Disk -Number $diskImage.Number
    }

    Context 'Wait for a Disk using Disk Number' {
        It 'Should compile and apply the MOF without throwing' {
            {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName         = 'localhost'
                            DiskId           = $disk.Number
                            DiskIdType       = 'Number'
                            RetryIntervalSec = 1
                            RetryCount       = 5
                        }
                    )
                }

                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }
            $current.DiskId           | Should -Be $disk.Number
            $current.RetryIntervalSec | Should -Be 1
            $current.RetryCount       | Should -Be 5
            $current.IsAvailable      | Should -Be $true
        }
    }

    Context 'Wait for a Disk using Disk Unique Id' {
        It 'Should compile and apply the MOF without throwing' {
            {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName         = 'localhost'
                            DiskId           = $disk.UniqueId
                            DiskIdType       = 'UniqueId'
                            RetryIntervalSec = 1
                            RetryCount       = 5
                        }
                    )
                }

                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }
            $current.DiskId           | Should -Be $disk.UniqueId
            $current.RetryIntervalSec | Should -Be 1
            $current.RetryCount       | Should -Be 5
            $current.IsAvailable      | Should -Be $true
        }
    }

    Context 'Wait for a Disk using Disk Guid' {
        It 'Should compile and apply the MOF without throwing' {
            {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName         = 'localhost'
                            DiskId           = $disk.Guid
                            DiskIdType       = 'Guid'
                            RetryIntervalSec = 1
                            RetryCount       = 5
                        }
                    )
                }

                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }
            $current.DiskId           | Should -Be $disk.Guid
            $current.RetryIntervalSec | Should -Be 1
            $current.RetryCount       | Should -Be 5
            $current.IsAvailable      | Should -Be $true
        }
    }

    AfterAll {
        Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
        Remove-Item -Path $VHDPath -Force
    }
}
