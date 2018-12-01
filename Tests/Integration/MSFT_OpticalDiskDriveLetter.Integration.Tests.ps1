$script:DSCModuleName      = 'StorageDsc'
$script:DSCResourceName    = 'MSFT_OpticalDiskDriveLetter'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Integration Test Template Version: 1.1.1
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    $opticalDisk = Get-CimInstance -ClassName Win32_CDROMDrive |
        Where-Object -FilterScript {
        -not (
            $_.Caption -eq "Microsoft Virtual DVD-ROM" -and
            ($_.DeviceID.Split("\")[-1]).Length -gt 10
        )
    }[0]

    if (-not $opticalDisk)
    {
        Write-Verbose -Message "$($script:DSCResourceName) integration tests cannot be run because there is no optical disk in the system." -Verbose
        return
    }

    $currentDriveLetter = $opticalDisk.Drive
    $volume = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$currentDriveLetter'"

    $lastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
    $driveLetter = [char](([int][char]$lastDrive) + 1)

    # Change drive letter of the optical drive
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Integration" {
        # Dismount the optical disk from a drive letter
        $volume | Set-CimInstance -Property @{ DriveLetter = $null }

        Context 'Assign a Drive Letter to an optical drive that is not mounted' {
            It 'Should compile and apply the MOF without throwing' {
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

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

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
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should -Be 1
                $current.DriveLetter      | Should -Be "$($driveLetter):"
            }
        }

        $driveLetter = [char](([int][char]$lastDrive) + 2)

        Context 'Assign a Drive Letter to an optical drive that is already mounted' {
            It 'Should compile and apply the MOF without throwing' {
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

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

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
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should -Be 1
                $current.DriveLetter      | Should -Be "$($driveLetter):"
            }
        }

        Context 'Remove a Drive Letter from an optical drive that is already mounted' {
            It 'Should compile and apply the MOF without throwing' {
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

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

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
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DiskId           | Should -Be 1
                $current.DriveLetter      | Should -Be ''
            }
        }
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    # Mount the optical disk back to where it was
    if ($volume)
    {
        $volume | Set-CimInstance -Property @{ DriveLetter = $currentDriveLetter }
    }
    #endregion
}
