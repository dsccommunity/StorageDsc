$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xOpticalDiskDriveLetter'

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

        $script:mockedNoOpticalDrive = $null

        $script:mockedOpticalDrive  = [pscustomobject] @{
                Drive        = $script:testDriveLetter
                Caption      = 'Microsoft Virtual DVD-ROM'
                DeviceID     = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006'
                Id           = $script:testDriveLetter
            }

        $script:mockedVolume = [pscustomobject] @{
                DriveLetter  = $script:testDriveLetter
                DriveType    = 5
            }

        $script:mockedWrongLetterOpticalDrive = [pscustomobject] @{
                Drive          = 'W:'
                Caption        = 'Microsoft Virtual DVD-ROM'
                DeviceID       = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006'
            }

        $script:mockedWrongVolume = [pscustomobject] @{
                DriveLetter       = 'W:'
            }

        $script:mockedVolumeNotOpticalDrive = [pscustomobject] @{
                DriveLetter  =  $script:testDriveLetter
                DriveType    = 3
            }

        $script:mockedOpticalDriveISO = [pscustomobject] @{
                Drive          = 'I:'
                Caption        = 'Microsoft Virtual DVD-ROM'
                DeviceID       = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\2&1F4ADFFE&0&000002'
            }

        $script:mockedOpticalDriveIDE = [pscustomobject] @{
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
        Describe 'MSFT_xOpticalDiskDriveLetter\Get-TargetResource' {
            Context 'Optical disk drive present with correct drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedOpticalDrive } `
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

            Context 'Optical disk drive present with incorrect drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedWrongLetterOpticalDrive } `
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


            Context 'IDE optical disk drive present with incorrect drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedOpticalDriveIDE } `
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

            Context 'Optical disk drive not present' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedNoOpticalDrive } `
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
        Describe 'MSFT_xOpticalDiskDriveLetter\Set-TargetResource' {
            Context 'Optical disk drive with the correct drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedOpticalDrive } `
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

            Context 'Optical disk drive with the correct drive letter when Ensure is set to Absent' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedOpticalDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                        $ClassName -eq "win32_volume"
                    } `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-CimInstance `
                    -MockWith {  } `
                    -Verifiable

                It 'Should not throw' {
                    {
                        Set-TargetResource `
                            -Driveletter $script:testDriveLetter `
                            -Ensure 'Absent' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Optical disk with the wrong drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedWrongLetterOpticalDrive } `
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

            Context 'IDE optical disk drive with the wrong drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedOpticalDriveide } `
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
                    -MockWith { $script:mockedOpticalDriveISO } `
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

        Describe 'MSFT_xOpticalDiskDriveLetter\Test-TargetResource' {

            Context 'Drive letter is a valid optical disk drive' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedOpticalDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                        $ClassName -eq "win32_volume"
                    } `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                $resource = Test-TargetResource `
                    -DriveLetter $script:testDriveLetter `
                    -Verbose | Should Be $true

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                }
            }

            Context 'Drive letter is a valid optical disk drive and $Ensure is set to Absent' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedOpticalDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                        $ClassName -eq "win32_volume"
                    } `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                $resource = Test-TargetResource `
                    -DriveLetter $script:testDriveLetter `
                    -Ensure 'Absent' `
                    -Verbose | Should Be $false

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                }
            }

            Context 'There is no optical disk drive' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedNoOpticalDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                        $ClassName -eq "win32_volume"
                    } `
                    -MockWith { $script:mockedWrongVolume } `
                    -Verifiable

                $resource = Test-TargetResource `
                    -DriveLetter $script:testDriveLetter `
                    -Ensure 'Present' `
                    -Verbose | Should Be $false

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                }
            }

            Context 'The drive letter already exists on a volume that is not a optical disk drive' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq "win32_cdromdrive"
                    } `
                    -MockWith { $script:mockedOpticalDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                        $ClassName -eq "win32_volume"
                    } `
                    -MockWith { $script:mockedVolumeNotOpticalDrive } `
                    -Verifiable

                $resource = Test-TargetResource `
                    -DriveLetter $script:testDriveLetter `
                    -Ensure 'Present' `
                    -Verbose | Should Be $false

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
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
