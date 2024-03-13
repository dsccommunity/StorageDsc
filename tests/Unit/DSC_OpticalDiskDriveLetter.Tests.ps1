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
        $script:testOpticalDrives = [PSCustomObject] @{
            Default = [PSCustomObject] @{
                DriveLetter = 'X:'
                DriveLetterNoColon = 'X'
                VolumeId = 'Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}'
            }
            ISO = [PSCustomObject] @{
                DriveLetter = 'I:'
                DriveLetterNoColon = 'I'
                VolumeId = 'Volume{0365fab8-a4e1-4f87-b1ef-b3c32515138b}'
            }
            WrongLetter = [PSCustomObject] @{
                DriveLetter = 'W:'
                DriveLetterNoColon = 'W'
                VolumeId = 'Volume{18508a20-5827-4bfa-96b3-0aeb5a2797c2}'
            }
            NoDriveLetter = [PSCustomObject] @{
                DriveLetter = 'Volume{8c58ce81-0f58-4bd2-a575-0eb66a993ad7}'
                VolumeId = 'Volume{8c58ce81-0f58-4bd2-a575-0eb66a993ad7}'
            }
        }

        $script:mockedOpticalDrives = [PSCustomObject] @{
            Default = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                Drive    = $script:testOpticalDrives.Default.DriveLetter
                Id       = $script:testOpticalDrives.Default.DriveLetter
            } -ClientOnly
            ISO = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                Drive    = $script:testOpticalDrives.ISO.DriveLetter
                Id       = $script:testOpticalDrives.ISO.DriveLetter
            } -ClientOnly
            WrongLetter = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                Drive    = $script:testOpticalDrives.WrongLetter.DriveLetter
                Id       = $script:testOpticalDrives.WrongLetter.DriveLetter
            } -ClientOnly
            NoDriveLetter = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                Drive    = $script:testOpticalDrives.NoDriveLetter.DriveLetter
                Id       = $script:testOpticalDrives.NoDriveLetter.DriveLetter
            } -ClientOnly
        }

        $script:mockedVolume = [PSCustomObject] @{
            Default = New-CimInstance -ClassName Win32_Volume -Property @{
                Name = $script:testOpticalDrives.Default.DriveLetter
                DriveType   = 5
                DeviceId    = "\\?\$($script:testOpticalDrives.Default.VolumeId)\"
            } -ClientOnly
            ISO = New-CimInstance -ClassName Win32_Volume -Property @{
                Name = $script:testOpticalDrives.ISO.DriveLetter
                DriveType   = 5
                DeviceId    = "\\?\$($script:testOpticalDrives.ISO.VolumeId)\"
            } -ClientOnly
            WrongLetter = New-CimInstance -ClassName Win32_Volume -Property @{
                Name = $script:testOpticalDrives.WrongLetter.DriveLetter
                DriveType   = 5
                DeviceId    = "\\?\$($script:testOpticalDrives.WrongLetter.VolumeId)\"
            } -ClientOnly
            NoDriveLetter = New-CimInstance -ClassName Win32_Volume -Property @{
                Name = $script:testOpticalDrives.NoDriveLetter.DriveLetter
                DriveType   = 5
                DeviceId    = "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)\"
            } -ClientOnly
        }

        $script:mockedOpticalDriveNone = $null

        $script:mockedOpticalDriveMultiDisks = @(
            $script:mockedOpticalDrives.NoDriveLetter
            $script:mockedOpticalDrives.Default
        )

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

        Describe 'DSC_OpticalDiskDriveLetter\Test-OpticalDiskCanBeManaged' {
            Context 'When the optical disk drive passed is a mounted ISO with a drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.ISO.DriveLetterNoColon)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.ISO
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.ISO.VolumeId)"
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-OpticalDiskCanBeManaged `
                            -OpticalDisk $script:mockedOpticalDrives.ISO `
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

            Context 'When the optical disk drive passed is a mounted ISO without a drive letter' {
                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)"
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-OpticalDiskCanBeManaged `
                            -OpticalDisk $script:mockedOpticalDrives.NoDriveLetter `
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

            Context 'When the optical disk drive passed is a virtual optical drive (not a mounted ISO) with a drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.ISO.DriveLetterNoColon)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.ISO
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.ISO.VolumeId)"
                    } `
                    -MockWith {
                        # Throw an Microsoft.Management.Infrastructure.CimException with Exception.MessageId set 'HRESULT 0xc03a0015'
                        throw [Microsoft.Management.Infrastructure.CimException]::new('The specified disk is not a virtual disk.')
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-OpticalDiskCanBeManaged `
                            -OpticalDisk $script:mockedOpticalDrives.ISO `
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

        Describe 'DSC_OpticalDiskDriveLetter\Get-OpticalDiskDriveLetter' {
            Context 'When a single optical disk drive is present and assigned a drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_CDROMDrive'
                    } `
                    -MockWith {
                        $script:mockedOpticalDrives.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith {
                        $script:mockedOpticalDrives.Default
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-OpticalDiskDriveLetter `
                            -DiskId 1 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "DriveLetter should be $($script:testOpticalDrives.Default.DriveLetter)" {
                    $script:result.DriveLetter | Should -Be $script:testOpticalDrives.Default.DriveLetter
                }

                It 'Should call all the Get mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a single optical disk drive is present and is not assiged a drive letter' {
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

            Context 'When a single optical disk drive is present and assigned a drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDriveWs2022AzureGen2
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

            Context 'When a single optical disk drive is present but a second disk is requested' {
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
                        $script:mockedOpticalDriveNone
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
                        $script:mockedOpticalDriveNone
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
                        $script:mockedOpticalDriveNone
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
                        $script:mockedOpticalDriveNone
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
                        $script:mockedOpticalDriveNone
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
