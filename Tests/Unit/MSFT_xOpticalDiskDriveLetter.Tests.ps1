$script:DSCModuleName = 'xStorage'
$script:DSCResourceName = 'MSFT_xOpticalDiskDriveLetter'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xStorage'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
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

        $script:mockedOpticalDrive = [pscustomobject] @{
            Drive    = $script:testDriveLetter
            Caption  = 'Microsoft Virtual DVD-ROM'
            DeviceID = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006'
            Id       = $script:testDriveLetter
        }

        $script:mockedVolume = [pscustomobject] @{
            DriveLetter = $script:testDriveLetter
            DriveType   = 5
        }

        $script:mockedWrongLetterOpticalDrive = [pscustomobject] @{
            Drive    = 'W:'
            Caption  = 'Microsoft Virtual DVD-ROM'
            DeviceID = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006'
        }

        $script:mockedWrongVolume = [pscustomobject] @{
            IsSingleInstance = 'Yes'
            DriveLetter      = 'W:'
        }

        $script:mockedVolumeNotOpticalDrive = [pscustomobject] @{
            DriveLetter = $script:testDriveLetter
            DriveType   = 3
        }

        $script:mockedOpticalDriveISO = [pscustomobject] @{
            Drive    = 'I:'
            Caption  = 'Microsoft Virtual DVD-ROM'
            DeviceID = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\2&1F4ADFFE&0&000002'
        }

        $script:mockedOpticalDriveIDE = [pscustomobject] @{
            Drive    = 'I:'
            Caption  = 'Msft Virtual CD/ROM ATA Device'
            DeviceID = 'IDE\CDROMMSFT_VIRTUAL_CD/ROM_____________________1.0_____\5&CFB56DE&0&1.0.0'
        }

        function Set-CimInstance
        {
            Param
            (
                [CmdletBinding()]
                [Parameter(ValueFromPipeline)]
                $InputObject,

                [Parameter()]
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
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedOpticalDrive } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "DriveLetter should be $($script:testDriveLetter)" {
                    $script:result.DriveLetter | Should -Be $script:testDriveLetter
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'Optical disk drive present with incorrect drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedWrongLetterOpticalDrive } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "DriveLetter should be $($script:testDriveLetter)" {
                    $script:result.DriveLetter | Should -Not -Be $script:testDriveLetter
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'IDE optical disk drive present with incorrect drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedOpticalDriveIDE } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "Should be DriveLetter $($script:testDriveLetter)" {
                    $script:result.DriveLetter | Should -Not -Be $script:testDriveLetter
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'Optical disk drive not present' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedNoOpticalDrive } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'DriveLetter should be null' {
                    $script:result.DriveLetter | Should -Be $null
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_xOpticalDiskDriveLetter\Set-TargetResource' {
            Context 'Optical disk drive with the correct drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedOpticalDrive } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'Optical disk drive with the correct drive letter when Ensure is set to Absent' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedOpticalDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_Volume'
                } `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-CimInstance `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -Driveletter $script:testDriveLetter `
                            -Ensure 'Absent' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 2
                }
            }

            Context 'Optical disk with the wrong drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedWrongLetterOpticalDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_Volume'
                } `
                    -MockWith { $script:mockedWrongVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-CimInstance `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 2
                    Assert-MockCalled -CommandName Set-CimInstance -Exactly -Times 1
                }
            }

            Context 'IDE optical disk drive with the wrong drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedOpticalDriveide } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_Volume'
                } `
                    -MockWith { $script:mockedWrongVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-CimInstance `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 2
                    Assert-MockCalled -CommandName Set-CimInstance -Exactly -Times 1
                }
            }

            # This resource does not change the drive letter of mounted ISO images.
            Context 'Mounted ISO with the wrong drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedOpticalDriveISO } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }
        }
        #endregion

        Describe 'MSFT_xOpticalDiskDriveLetter\Test-TargetResource' {
            Context 'Drive letter is a valid optical disk drive' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedOpticalDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_Volume'
                } `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -DriveLetter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -Be $true
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'Drive letter is a valid optical disk drive and $Ensure is set to Absent' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedOpticalDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_Volume'
                } `
                    -MockWith { $script:mockedVolume } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -DriveLetter $script:testDriveLetter `
                            -Ensure 'Absent' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'There is no optical disk drive' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedNoOpticalDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_Volume'
                } `
                    -MockWith { $script:mockedWrongVolume } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -DriveLetter $script:testDriveLetter `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'The drive letter already exists on a volume that is not a optical disk drive' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith { $script:mockedOpticalDrive } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_Volume'
                } `
                    -MockWith { $script:mockedVolumeNotOpticalDrive } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -IsSingleInstance 'Yes' `
                            -DriveLetter $script:testDriveLetter `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
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
