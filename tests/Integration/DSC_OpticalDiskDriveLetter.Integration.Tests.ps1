$script:dscModuleName = 'StorageDsc'
$script:dscResourceName = 'DSC_OpticalDiskDriveLetter'

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
    # Locate an optical disk in the system to use for testing
    $opticalDisk = (Get-CimInstance -ClassName Win32_CDROMDrive)[0]

    if (-not $opticalDisk)
    {
        Write-Verbose -Message "$($script:dscResourceName) integration tests cannot be run because there is no optical disk in the system." -Verbose
        return
    }

    $currentDriveLetter = $opticalDisk.Drive
    $volume = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$currentDriveLetter'"

    $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
    $driveLetter = [char](([int][char]$lastDrive) + 1)

    # Change drive letter of the optical drive
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile -Verbose -ErrorAction Stop

    Describe "$($script:dscResourceName)_Integration" {
        # Dismount the optical disk from a drive letter
        $volume | Set-CimInstance -Property @{
            DriveLetter = $null
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

        $driveLetter = [char](([int][char]$lastDrive) + 2)

        Context 'Assign a Drive Letter to an optical drive that is already mounted' {
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
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Mount the optical disk back to where it was
    if ($volume)
    {
        $volume | Set-CimInstance -Property @{
            DriveLetter = $currentDriveLetter
        }
    }
}
