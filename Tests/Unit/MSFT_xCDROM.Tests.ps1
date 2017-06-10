$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xCDROM'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
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
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $script:DSCResourceName {

        $script:testDriveLetter = 'X:'

        $script:mockedNoCDROM = [pscustomobject] @{}

        $script:mockedCDROM = [pscustomobject] @{
                Drive       = $script:testDriveLetter
                Caption     = 'Microsoft Virtual DVD-ROM'
                DeviceID    = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006'
            }

        $script:mockedVolume = [pscustomobject] @{
                DriveLetter  = $script:testDriveLetter
            }

        $script:mockedWrongLetterCDROM = [pscustomobject] @{
                Drive          = 'W:'
                Caption        = 'Microsoft Virtual DVD-ROM'
                DeviceID       = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006'
            }

        $script:mockedWrongVolume = [pscustomobject] @{
                DriveLetter       = 'W:'
            }

        $script:mockedCDROMiso = [pscustomobject] @{
                Drive          = 'I:'
                Caption        = 'Microsoft Virtual DVD-ROM'
                DeviceID       = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\2&1F4ADFFE&0&000002'
            }

        $script:mockedCDROMide = [pscustomobject] @{
                Drive          = 'I:'
                Caption        = 'Msft Virtual CD/ROM ATA Device'
                DeviceID       = 'IDE\CDROMMSFT_VIRTUAL_CD/ROM_____________________1.0_____\5&CFB56DE&0&1.0.0'
            }
        
        function Set-CimInstance {
            Param
            (
                [CmdletBinding()]
                [Parameter(ValueFromPipeline)]
                $InputObject,

                [hashtable]
                $Property                
            )
        }

        #region Function Get-TargetResource
        Describe 'MSFT_xCDROM\Get-TargetResource' {
            Context 'CDROM drive present with correct drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedCDROM } `
                    -Verifiable

                $resource = Get-TargetResource `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "DriveLetter should be $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should Be $script:testDriveLetter
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                }
            }

            Context 'CDROM drive present with incorrect drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedWrongLetterCDROM } `
                    -Verifiable

                $resource = Get-TargetResource `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "DriveLetter should be $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should Not Be $script:testDriveLetter
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                }
            }


            Context 'IDE CDROM drive present with incorrect drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedCDROMide } `
                    -Verifiable

                $resource = Get-TargetResource `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "DriveLetter should be $($script:testDriveLetter)" {
                    $resource.DriveLetter | Should Not Be $script:testDriveLetter
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                }
            }

            Context 'CDROM drive not present' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedNoCDROM } `
                    -Verifiable

                $resource = Get-TargetResource `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose

                It "DriveLetter should be null" {
                    $resource.DriveLetter | Should Be $null
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                }
            }            
        }

        #region Function Set-TargetResource
        Describe 'MSFT_xDisk\Set-TargetResource' {
            Context 'CDROM with the correct drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedCDROM } `
                    -Verifiable

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1                    
                }
            }

            Context 'CDROM with the wrong drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedWrongLetterCDROM } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                        $ClassName -eq "win32_volume"
                    } `
                    -MockWith { $script:mockedWrongVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-CimInstance `
                    -MockWith {  } `
                    -Verifiable

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-CimInstance -Times 2
                    Assert-MockCalled -CommandName Set-CimInstance -Times 1               
                }
            }

            Context 'IDE CDROM with the wrong drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedCDROMide } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                        $ClassName -eq "win32_volume"
                    } `
                    -MockWith { $script:mockedWrongVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-CimInstance `
                    -MockWith { } `
                    -Verifiable

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-CimInstance -Times 2
                    Assert-MockCalled -CommandName Set-CimInstance -Times 1               
                }
            }

            # This resource does not change the drive letter of mounted ISO images.
            Context 'Mounted ISO with the wrong drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedCDROMiso } `
                    -Verifiable

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1                    
                }
            }                        
        }
        #endregion
    }
} 
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
