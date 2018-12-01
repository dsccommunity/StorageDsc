$script:DSCModuleName      = 'StorageDsc'
$script:DSCResourceName    = 'MSFT_OpticalDiskDriveLetter'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
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
        $script:testDriveLetterNoVolume = 'Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}'
        $script:testVolumeDeviceId = '"\\?\$($script:testDriveLetterNoVolume)\"'

        $script:mockedNoOpticalDrive = $null

        $script:mockedOpticalDrive = [pscustomobject] @{
            Drive    = $script:testDriveLetter
            Caption  = 'Microsoft Virtual DVD-ROM'
            DeviceID = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006'
            Id       = $script:testDriveLetter
        }

        $script:mockedOpticalDriveNoDriveLetter = [pscustomobject] @{
            Drive    = $script:testDriveLetterNoVolume
            Caption  = 'Microsoft Virtual DVD-ROM'
            DeviceID = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006'
            Id       = $script:testDriveLetterNoVolume
        }

        $script:mockedOpticalDriveMultiDisks = @(
            $script:mockedOpticalDriveNoDriveLetter
            $script:mockedOpticalDrive
        )

        $script:mockedWrongLetterOpticalDrive = [pscustomobject] @{
            Drive    = 'W:'
            Caption  = 'Microsoft Virtual DVD-ROM'
            DeviceID = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000006'
            Id       = 'W:'
        }

        $script:mockedOpticalDriveISO = [pscustomobject] @{
            Drive    = 'I:'
            Caption  = 'Microsoft Virtual DVD-ROM'
            DeviceID = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\2&1F4ADFFE&0&000002'
            Id       = 'I:'
        }

        $script:mockedOpticalDriveIDE = [pscustomobject] @{
            Drive    = 'I:'
            Caption  = 'Msft Virtual CD/ROM ATA Device'
            DeviceID = 'IDE\CDROMMSFT_VIRTUAL_CD/ROM_____________________1.0_____\5&CFB56DE&0&1.0.0'
            Id       = 'I:'
        }

        $script:mockedVolume = [pscustomobject] @{
            DriveLetter = $script:testDriveLetter
            DriveType   = 5
            DeviceId    = '\\?\Volume{bba1802b-e7a1-11e3-824e-806e6f6e6963}\'
            Id          = $script:testDriveLetter
        }

        $script:mockedWrongVolume = [pscustomobject] @{
            DriveLetter = 'W:'
            DriveType   = 5
            DeviceId    = $script:testVolumeDeviceId
            Id          = 'W:'
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

        #region Function Get-OpticalDiskDriveLetter
        Describe 'MSFT_xOpticalDiskDriveLetter\Get-OpticalDiskDriveLetter' {
            Context 'Single optical disk drive present and assigned a drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDrive
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-OpticalDiskDriveLetter `
                            -DiskId 1 `
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

            Context 'Single optical disk drive present and not assiged a drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDriveNoDriveLetter
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-OpticalDiskDriveLetter `
                            -DiskId 1 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "DriveLetter should be empty" {
                    $script:result.DriveLetter | Should -Be ''
                    $script:result.DeviceId | Should -Be $script:testDriveLetterNoVolume
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'Multiple optical disk drives present and second one is assigned a drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDriveMultiDisks
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-OpticalDiskDriveLetter `
                            -DiskId 2 `
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

            Context 'Single optical disk drive present but second disk is requested' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDrive
                } `
                    -Verifiable

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.NoOpticalDiskDriveError -f 2) `
                    -ArgumentName 'DiskId'

                It 'Should throw expected exception' {
                    {
                        $script:result = Get-OpticalDiskDriveLetter `
                            -DiskId 2 `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'Single optical disk drive present but is mounted with ISO' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDriveISO
                } `
                    -Verifiable

                It 'Should throw expected exception' {
                    {
                        $script:result = Get-OpticalDiskDriveLetter `
                            -DiskId 1 `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }
        }
        #endregion

        #region Function Get-TargetResource
        Describe 'MSFT_OpticalDiskDriveLetter\Get-TargetResource' {
            Context 'Optical disk drive present with correct drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDrive
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "DriveLetter should be $($script:testDriveLetter)" {
                    $script:result.DriveLetter | Should -Be $script:testDriveLetter
                    $script:result.Ensure | Should -Be 'Present'
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
                    -MockWith {
                    $script:mockedWrongLetterOpticalDrive
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "DriveLetter should be $($script:testDriveLetter)" {
                    $script:result.DriveLetter | Should -Not -Be $script:testDriveLetter
                    $script:result.Ensure | Should -Be 'Present'
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
                    -MockWith {
                    $script:mockedOpticalDriveIDE
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "Should be DriveLetter $($script:testDriveLetter)" {
                    $script:result.DriveLetter | Should -Not -Be $script:testDriveLetter
                    $script:result.Ensure | Should -Be 'Present'
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
                    -MockWith {
                    $script:mockedNoOpticalDrive
                } `
                    -Verifiable

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.NoOpticalDiskDriveError -f 1) `
                    -ArgumentName 'DiskId'

                It 'Should throw expected exception' {
                    {
                        $script:result = Get-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_OpticalDiskDriveLetter\Set-TargetResource' {
            Context 'Optical disk drive exists with the correct drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDrive
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context 'Optical disk drive exists with a drive letter when Ensure is set to Absent' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDrive
                } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_Volume'
                } `
                    -MockWith {
                    $script:mockedVolume
                } `
                    -Verifiable

                Mock `
                    -CommandName Set-CimInstance `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId 1 `
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

            Context 'Optical disk drive exists with the wrong drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedWrongLetterOpticalDrive
                } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_Volume'
                } `
                    -MockWith {
                    $script:mockedWrongVolume
                } `
                    -Verifiable

                Mock `
                    -CommandName Set-CimInstance `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId 1 `
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

            Context 'IDE optical disk drive exists with the wrong drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDriveIDE
                } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance  `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_Volume'
                } `
                    -MockWith {
                    $script:mockedWrongVolume
                } `
                    -Verifiable

                Mock `
                    -CommandName Set-CimInstance `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId 1 `
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

            Context 'Optical disk drive not present' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedNoOpticalDrive
                } `
                    -Verifiable

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.NoOpticalDiskDriveError -f 1) `
                    -ArgumentName 'DiskId'

                It 'Should throw expected exception' {
                    {
                        $script:result = Set-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }
        }
        #endregion

        Describe 'MSFT_OpticalDiskDriveLetter\Test-TargetResource' {
            Context 'Optical drive exists and is assigned expected drive letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDrive
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId 1 `
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

            Context 'Optical drive exists but is assigned a drive letter but should not be' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDrive
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId 1 `
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

            Context 'The drive letter already exists on a volume that is not an optical disk drive' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedWrongLetterOpticalDrive
                } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_Volume'
                } `
                    -MockWith {
                    $script:mockedVolume
                } `
                    -Verifiable

                $errorRecord = Get-InvalidOperationRecord `
                    -Message $($localizedData.DriveLetterAssignedToAnotherDrive -f $script:testDriveLetter)

                It 'Should throw expected exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId 1 `
                            -DriveLetter $script:testDriveLetter `
                            -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'The optical drive is assigned a drive letter but should not be' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDrive
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId 1 `
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

            Context 'The optical drive is not assigned a drive letter and should not be' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDriveNoDriveLetter
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId 1 `
                            -DriveLetter $script:testDriveLetter `
                            -Ensure 'Absent' `
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

            Context 'Optical disk drive not present' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedNoOpticalDrive
                } `
                    -Verifiable

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.NoOpticalDiskDriveError -f 1) `
                    -ArgumentName 'DiskId'

                It 'Should throw expected exception' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Throw $errorRecord
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
