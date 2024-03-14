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
                VolumeId = 'Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}'
            }
            WrongLetter = [PSCustomObject] @{
                DriveLetter = 'W:'
                VolumeId = 'Volume{18508a20-5827-4bfa-96b3-0aeb5a2797c2}'
            }
            NoDriveLetter = [PSCustomObject] @{
                DriveLetter = ''
                VolumeId = 'Volume{8c58ce81-0f58-4bd2-a575-0eb66a993ad7}'
            }
        }

        $script:mockedOpticalDrives = [PSCustomObject] @{
            Default = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                Drive    = $script:testOpticalDrives.Default.DriveLetter
                Id       = $script:testOpticalDrives.Default.DriveLetter
            } -ClientOnly
            WrongLetter = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                Drive    = $script:testOpticalDrives.WrongLetter.DriveLetter
                Id       = $script:testOpticalDrives.WrongLetter.DriveLetter
            } -ClientOnly
            NoDriveLetter = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                # When no drive letter is assigned, the Drive property is set to the volume ID
                Drive    = $script:testOpticalDrives.NoDriveLetter.VolumeId
                Id       = $script:testOpticalDrives.NoDriveLetter.DriveLetter
            } -ClientOnly
        }

        $script:mockedVolume = [PSCustomObject] @{
            Default = New-CimInstance -ClassName Win32_Volume -Property @{
                Name = "$($script:testOpticalDrives.Default.DriveLetter)\"
                DriveLetter = $script:testOpticalDrives.Default.DriveLetter
                DriveType   = 5
                DeviceId    = "\\?\$($script:testOpticalDrives.Default.VolumeId)\"
            } -ClientOnly
            WrongLetter = New-CimInstance -ClassName Win32_Volume -Property @{
                Name = $script:testOpticalDrives.WrongLetter.DriveLetter
                DriveLetter = "$($script:testOpticalDrives.WrongLetter.DriveLetter)\"
                DriveType   = 5
                DeviceId    = "\\?\$($script:testOpticalDrives.WrongLetter.VolumeId)\"
            } -ClientOnly
            NoDriveLetter = New-CimInstance -ClassName Win32_Volume -Property @{
                Name = "$($script:testOpticalDrives.NoDriveLetter.DriveLetter)\"
                DriveLetter = ''
                DriveType   = 5
                DeviceId    = "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)\"
            } -ClientOnly
        }

        $script:mockGetDiskImage = [PSCustomObject] @{
            ManageableVirtualDrive = {
                # Throw an Microsoft.Management.Infrastructure.CimException with Message set to 'The specified disk is not a virtual disk.'
                throw [Microsoft.Management.Infrastructure.CimException]::new($localizedData.ErrorDiskIsNotAVirtualDisk)
            }
            NotManageableMountedISO = {
                # This value doesn't matter as it is not used in the function
                $true
            }
        }

        $script:getCimInstanceCdRomDrive_ParameterFilter = {
            $ClassName -eq 'Win32_CDROMDrive'
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
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.NotManageableMountedISO `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-OpticalDiskCanBeManaged `
                            -OpticalDisk $script:mockedOpticalDrives.Default `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -BeFalse
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When the optical disk drive passed is a mounted ISO without a drive letter' {
                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.NotManageableMountedISO `
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

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When the optical disk drive passed is a virtual optical drive (not a mounted ISO) with a drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-OpticalDiskCanBeManaged `
                            -OpticalDisk $script:mockedOpticalDrives.Default `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -BeTrue
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When the optical disk drive passed is a virtual optical drive (not a mounted ISO) without a drive letter' {
                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-OpticalDiskCanBeManaged `
                            -OpticalDisk $script:mockedOpticalDrives.NoDriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -BeTrue
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'DSC_OpticalDiskDriveLetter\Get-OpticalDiskDriveLetter' {
            Context 'When a single manageable optical disk drive is present and assigned a drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
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

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a single manageable optical disk drive is present and is not assiged a drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.NoDriveLetter
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-OpticalDiskDriveLetter `
                            -DiskId 1 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "DriveLetter should be empty" {
                    $script:result.DriveLetter | Should -BeNullOrEmpty
                    $script:result.DeviceId | Should -Be $script:testOpticalDrives.NoDriveLetter.VolumeId
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When multiple manageable optical disk drives are present but only the second one is assigned a drive letter and the second disk is requested' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDriveMultiDisks
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-OpticalDiskDriveLetter `
                            -DiskId 2 `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "DriveLetter should be $($script:testOpticalDrives.Default.DriveLetter)" {
                    $script:result.DriveLetter | Should -Be $script:testOpticalDrives.Default.DriveLetter
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a single manageable optical disk drive is present but a second disk is requested' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
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

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a single unmanageable optical disk drive (a mounted ISO) is present and is assigned a drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.NotManageableMountedISO `
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

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a single unmanageable optical disk drive (a mounted ISO) is present and is not assigned a drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.NoDriveLetter
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.NotManageableMountedISO `
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

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When there are manageable or unmanageable optical disk drives are present in the system but a disk is requested' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        @()
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

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'DSC_OpticalDiskDriveLetter\Get-TargetResource' {
            Context 'When a single manageable optical disk drive is present with the correct drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testOpticalDrives.Default.DriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "Should return the DriveLetter as '$($script:testOpticalDrives.Default.DriveLetter)' and Ensure is 'Present'" {
                    $script:result.DiskId | Should -Be 1
                    $script:result.DriveLetter | Should -Be $script:testOpticalDrives.Default.DriveLetter
                    $script:result.Ensure | Should -Be 'Present'
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a single manageable optical disk drive is present with an incorrect drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.WrongLetter
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.WrongLetter.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.WrongLetter
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.WrongLetter.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testOpticalDrives.Default.DriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "Should return the DriveLetter as '$($script:testOpticalDrives.WrongLetter.DriveLetter)' and Ensure is 'Present'" {
                    $script:result.DiskId | Should -Be 1
                    $script:result.DriveLetter | Should -Be $script:testOpticalDrives.WrongLetter.DriveLetter
                    $script:result.Ensure | Should -Be 'Present'
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When there are no optical disk drives present in the system' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        @()
                    } `
                    -Verifiable

                It 'Should not throw exception' {
                    {
                        $script:result = Get-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testOpticalDrives.Default.DriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "Should return the DriveLetter as empty and Ensure is 'Absent'" {
                    $script:result.DiskId | Should -Be 1
                    $script:result.DriveLetter | Should -BeNullOrEmpty
                    $script:result.Ensure | Should -Be 'Absent'
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a single unmanageable optical disk drive is present' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.NotManageableMountedISO `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testOpticalDrives.Default.DriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It "Should return the DriveLetter as empty and Ensure is 'Absent'" {
                    $script:result.DiskId | Should -Be 1
                    $script:result.DriveLetter | Should -BeNullOrEmpty
                    $script:result.Ensure | Should -Be 'Absent'
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'DSC_OpticalDiskDriveLetter\Set-TargetResource' {
            Context 'When a single manageable optical disk drive exists with the correct drive letter and Ensure is not specified (Present)' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testOpticalDrives.Default.DriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a single manageable optical disk drive exists with the correct drive letter and Ensure set to Present' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testOpticalDrives.Default.DriveLetter `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a single manageable optical disk drive exists with a drive letter when Ensure is set to Absent' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
                    -Verifiable

                Mock `
                    -CommandName Set-CimInstance `
                    -ParameterFilter {
                        [System.String]::IsNullOrWhiteSpace($Property.DriveLetter)
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testOpticalDrives.Default.DriveLetter `
                            -Ensure 'Absent' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a single manageable optical disk drive exists with the wrong drive letter and Ensure is not specified (Present)' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.WrongLetter
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.WrongLetter.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.WrongLetter
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.WrongLetter.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
                    -Verifiable

                Mock `
                    -CommandName Set-CimInstance `
                    -ParameterFilter {
                        $Property.DriveLetter -eq $script:testOpticalDrives.Default.DriveLetter
                    } `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testOpticalDrives.Default.DriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When there are no optical disk drives present and Ensure is not specified (Present)' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        $script:mockedOpticalDrives.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_Volume' -and `
                        $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
                    } `
                    -MockWith {
                        $script:mockedVolume.Default
                    } `
                    -Verifiable

                Mock `
                    -CommandName Get-DiskImage `
                    -ParameterFilter {
                        $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
                    } `
                    -MockWith $script:mockGetDiskImage.NotManageableMountedISO `
                    -Verifiable

                It 'Should not throw exception' {
                    {
                        $script:result = Set-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testOpticalDrives.Default.DriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call all the verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When there are no manageable optical disk drives present and Ensure is not specified (Present)' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
                    -MockWith {
                        @()
                    } `
                    -Verifiable

                It 'Should not throw exception' {
                    {
                        $script:result = Set-TargetResource `
                            -DiskId 1 `
                            -Driveletter $script:testOpticalDrives.Default.DriveLetter `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should call all the verifiable mocks' {
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

                It 'Should call all the verifiable mocks' {
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

                It 'Should call all the verifiable mocks' {
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

                It 'Should call all the verifiable mocks' {
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

                It 'Should call all the verifiable mocks' {
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

                It 'Should call all the verifiable mocks' {
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

                It 'Should call all the verifiable mocks' {
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

                It 'Should call all the verifiable mocks' {
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
