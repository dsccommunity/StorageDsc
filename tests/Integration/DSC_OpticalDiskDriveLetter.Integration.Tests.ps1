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
    $script:dscResourceFriendlyName = 'OpticalDiskDriveLetter'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    # Locate an optical disk in the system to use for testing
    $opticalDisks = Get-CimInstance -ClassName Win32_CDROMDrive

    if (-not $opticalDisks)
    {
        $skip = $true
    }
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'StorageDsc'
    $script:dscResourceFriendlyName = 'OpticalDiskDriveLetter'
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

Describe "$($script:dscResourceName)_Integration" -Skip:$skip {
    BeforeAll {
        # Locate an optical disk in the system to use for testing
        $opticalDisks = Get-CimInstance -ClassName Win32_CDROMDrive
        $opticalDisk = $opticalDisks[0]
        $currentDriveLetter = $opticalDisk.Drive
        $volume = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$currentDriveLetter'"

        $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
        $driveLetter = [char](([int][char]$lastDrive) + 1)

        # Change drive letter of the optical drive
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        # Dismount the optical disk from a drive letter
        $volume | Set-CimInstance -Property @{
            DriveLetter = $null
        }
    }

    AfterAll {
        # Mount the optical disk back to where it was
        if ($volume)
        {
            $volume | Set-CimInstance -Property @{
                DriveLetter = $currentDriveLetter
            }
        }
    }

    Context 'Assign a Drive Letter to an optical drive that is not mounted' {
        It 'Should compile MOF without throwing' {
            {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName    = 'localhost'
                            DiskId      = 1
                            DriveLetter = $driveLetter
                            Ensure      = 'Present'
                        }
                    )
                }

                & "$($script:dscResourceName)_Config" `
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
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }

            $current.DiskId           | Should -Be 1
            $current.DriveLetter      | Should -Be "$($driveLetter):"
        }
    }

    Context 'Assign a Drive Letter to an optical drive that is already mounted' {
        BeforeAll {
            $driveLetter = [char](([int][char]$lastDrive) + 2)
        }

        It 'Should compile the MOF without throwing' {
            {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName    = 'localhost'
                            DiskId      = 1
                            DriveLetter = $driveLetter
                            Ensure      = 'Present'
                        }
                    )
                }

                & "$($script:dscResourceName)_Config" `
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
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }

            $current.DiskId           | Should -Be 1
            $current.DriveLetter      | Should -Be "$($driveLetter):"
        }
    }

    Context 'Remove a Drive Letter from an optical drive that is already mounted' {
        It 'Should compile the MOF without throwing' {
            {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName    = 'localhost'
                            DiskId      = 1
                            DriveLetter = 'X'
                            Ensure      = 'Absent'
                        }
                    )
                }

                & "$($script:dscResourceName)_Config" `
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
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }

            $current.DiskId           | Should -Be 1
            $current.DriveLetter      | Should -Be ''
        }
    }
}
