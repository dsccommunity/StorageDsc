$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xOpticalDiskDriveLetter'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Integration Test Template Version: 1.1.1
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xStorage'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    $LastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
    $DriveLetter = [char](([int][char]$LastDrive)+1)

    # Change drive letter of the optical drive
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Integration" {
        BeforeAll {
            $currentDriveLetter = (Get-CimInstance -ClassName win32_cdromdrive | Where-Object {
                                -not (
                                        $_.Caption -eq "Microsoft Virtual DVD-ROM" -and
                                        ($_.DeviceID.Split("\")[-1]).Length -gt 10
                                    )
                                }
                                ).Drive
        }

        Context 'Assign a Drive Letter to the optical drive' {
            #region DEFAULT TESTS

            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName    = 'localhost'
                                DriveLetter = $DriveLetter
                            }
                        )
                    }

                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }
            #endregion

            if ($currentDriveLetter -eq $null)
            {
                Write-Verbose 'An optical drive is required to run the drive letter integration test.  Mounted ISOs are ignored'
                $skipTests = @{ Skip = $true }
            }

            It 'Should have set the resource and all the parameters should match' @skipTests {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                }
                $current.DriveLetter      | Should Be $DriveLetter
                $current.Ensure           | Should Be 'Present'
            }
        }
    }

    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
