$script:dscModuleName = 'StorageDsc'
$script:dscResourceName = 'DSC_OpticalDiskDriveLetter'

function Invoke-TestSetup
{
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
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
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

        $script:mockedOSPreServer2022 = [pscustomobject] @{
            BuildNumber = 17763
        }

        $script:mockedOSServer2022 = [pscustomobject] @{
            BuildNumber = 20348
        }

        $script:opticalDeviceIdMaxLengthPreServer2022 = 10
        $script:opticalDeviceIdMaxLengthServer2022 = 20

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

        Describe 'DSC_xOpticalDiskDriveLetter\Get-OpticalDeviceIdMaxLength' {
            Context 'When OS is pre Windows Server 2022' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'WIN32_OperatingSystem'
                } `
                    -MockWith {
                    $script:mockedOSPreServer2022
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-OpticalDeviceIdMaxLength
                    } | Should -Not -Throw
                }

                It "Optical DeviceId max length should be $($script:opticalDeviceIdMaxLengthPreServer2022)" {
                    $script:result | Should -Be $script:opticalDeviceIdMaxLengthPreServer2022
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When OS is Windows Server 2022' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'WIN32_OperatingSystem'
                } `
                    -MockWith {
                    $script:mockedOSServer2022
                } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-OpticalDeviceIdMaxLength
                    } | Should -Not -Throw
                }

                It "Optical DeviceId max length should be $($script:opticalDeviceIdMaxLengthServer2022)" {
                    $script:result | Should -Be $script:opticalDeviceIdMaxLengthServer2022
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'DSC_xOpticalDiskDriveLetter\Get-OpticalDiskDriveLetter' {
            Context 'When a single optical disk drive is present and assigned a drive letter' {
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

            Context 'When a single optical disk drive is present and not assiged a drive letter' {
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

            Context 'When multiple optical disk drives are present and second one is assigned a drive letter' {
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

            Context 'When a single optical disk drive is present but second disk is requested' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_CDROMDrive'
                    } `
                        -MockWith {
                        $script:mockedOpticalDrive
                    } `
                    -Verifiable

                It 'Should not throw exception' {
                    {
                        $script:result = Get-OpticalDiskDriveLetter `
                            -DiskId 2 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'DeviceId should be empty' {
                    $script:result.DeviceId | Should -BeNullOrEmpty
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a single optical disk drive is present but is mounted with ISO' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_CDROMDrive'
                    } `
                        -MockWith {
                        $script:mockedOpticalDriveISO
                    } `
                    -Verifiable

                It 'Should not throw exception' {
                    {
                        $script:result = Get-OpticalDiskDriveLetter `
                            -DiskId 1 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'DeviceId should be empty' {
                    $script:result.DeviceId | Should -BeNullOrEmpty
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When no optical disk drives are present in the system' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_CDROMDrive'
                    } `
                        -MockWith {
                        $script:mockedNoOpticalDrive
                    } `
                    -Verifiable

                It 'Should not throw exception' {
                    {
                        $script:result = Get-OpticalDiskDriveLetter `
                            -DiskId 1 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'DeviceId should be empty' {
                    $script:result.DeviceId | Should -BeNullOrEmpty
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'DSC_OpticalDiskDriveLetter\Get-TargetResource' {
            Context 'When an optical disk drive is present with correct drive letter' {
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

            Context 'When an optical disk drive is present with incorrect drive letter' {
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

            Context 'When an IDE optical disk drive is present with incorrect drive letter' {
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

            Context 'When an optical disk drive is not present' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_CDROMDrive'
                    } `
                        -MockWith {
                        $script:mockedNoOpticalDrive
                    } `
                    -Verifiable

                It 'Should not throw exception' {
                    {
                        $script:result = Get-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should have an empty DriveLetter and Ensure is Absent' {
                    $script:result.DriveLetter | Should -BeNullOrEmpty
                    $script:result.DiskId | Should -Be 1
                    $script:result.Ensure | Should -Be 'Absent'
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'DSC_OpticalDiskDriveLetter\Set-TargetResource' {
            Context 'When an optical disk drive exists with the correct drive letter' {
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

            Context 'When an optical disk drive exists with a drive letter when Ensure is set to Absent' {
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

            Context 'When an optical disk drive exists with the wrong drive letter' {
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

            Context 'When an IDE optical disk drive exists with the wrong drive letter' {
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

            Context 'When an optical disk drive is not present' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_CDROMDrive'
                    } `
                        -MockWith {
                        $script:mockedNoOpticalDrive
                    } `
                    -Verifiable

                It 'Should not throw exception' {
                    {
                        $script:result = Set-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'DSC_OpticalDiskDriveLetter\Test-TargetResource' {
            Context 'When the optical drive exists and is assigned expected drive letter' {
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
                    $script:result | Should -BeTrue
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When the optical drive exists but is assigned a drive letter but should not be' {
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
                    $script:result | Should -BeFalse
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When the drive letter already exists on a volume that is not an optical disk drive' {
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

            Context 'When the optical drive is assigned a drive letter but should not be' {
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
                    $script:result | Should -BeFalse
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When the optical drive is not assigned a drive letter and should not be' {
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
                    $script:result | Should -BeTrue
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When the optical drive does not exist and Ensure is Present' {
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

            Context 'When the optical drive does not exist and Ensure is Absent' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_CDROMDrive'
                    } `
                    -MockWith {
                        $script:mockedNoOpticalDrive
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
                    $script:result | Should -BeTrue
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
