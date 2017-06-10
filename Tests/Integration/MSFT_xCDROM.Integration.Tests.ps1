$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xCDROM'

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
    $DriveLetter = 'Z'

    # Create a config data object to pass to the DSC Configs
    $ConfigData = @{
        AllNodes = @(
            @{
                NodeName    = 'localhost'
                DriveLetter = $DriveLetter
            }
        )
    }

    # Change drive letter of CDROM
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

        Context 'Assign a Drive Letter to the CDROM' {
            #region DEFAULT TESTS
            It 'should compile and apply the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $ConfigData
                    Start-DscConfiguration -Path $TestDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should not throw
            }

            It 'should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
            }
            #endregion

            if ($currentDriveLetter)
            {
                It 'Should have set the resource and all the parameters should match' {
                    $current = Get-DscConfiguration | Where-Object {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    $current.DriveLetter      | Should Be $DriveLetter
                    $current.Ensure           | Should Be 'Present'
                }
            }
            else {
                Write-Verbose 'A cdrom is required to test the resource sets all the parameters correctly.  Mounted ISOs are ignored'
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
