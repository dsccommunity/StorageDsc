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

        $script:virtualDevices = [pscustomobject] @{
            MountedIso = [pscustomobject] @{
                Description = 'Mounted ISO - should not be managed by the resource'
                DeviceID    = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\2&1F4ADFFE&0&000004'
                Caption     = 'Microsoft Virtual DVD-ROM'
                CanManage   = $false
            }

            PhysicalDevice = [pscustomobject] @{
                Description = 'Physical device'
                DeviceID    = 'SCSI\CDROM&VEN_MATSHITA&PROD_BD-MLT_UJ260AF\4&23A5A6AC&0&000200'
                Caption     = 'MATSHITA BD-MLT UJ260AF'
                CanManage   = $true
            }

            VirtualAtaDvdRomWs2019HyperVGen1 = [pscustomobject] @{
                Description = 'Hyper-V Gen1 (BIOS/IDE) VM - Windows Server 2019'
                DeviceID    = 'IDE\CDROMMSFT_VIRTUAL_CD/ROM_____________________1.0_____\5&CFB56DE&0&1.0.0'
                Caption     = 'Msft Virtual CD/ROM ATA Device'
                CanManage   = $true
            }

            VirtualScsiDvdRomWs2019HyperVGen2 = [pscustomobject] @{
                Description = 'Hyper-V Gen2 (UEFI/SCSI) VM - Windows Server 2019'
                DeviceID    = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\000001'
                Caption     = 'Microsoft Virtual DVD-ROM'
                CanManage   = $true
            }

            VirtualAtaDvdRomWs2022AzureGen1 = [pscustomobject] @{
                Description = 'Azure Gen1 (BIOS/IDE) VM – Windows Server 2022 Azure Edition'
                DeviceID    = 'IDE\CDROMMSFT_VIRTUAL_CD/ROM_____________________1.0_____\5&CFB56DE&0&1.0.0'
                Caption     = 'Msft Virtual CD/ROM ATA Device'
                CanManage   = $true
            }

            VirtualScsiDvdRomWs2022AzureGen2 = [pscustomobject] @{
                Description = 'Azure Gen2 (UEFI/SCSI) VM – Windows Server 2022 Azure Edition'
                DeviceID    = 'SCSI\CDROM&VEN_MSFT&PROD_VIRTUAL_DVD-ROM\5&394B69D0&0&000002'
                Caption     = 'Microsoft Virtual DVD-ROM'
                CanManage   = $true
            }
        }

        $script:mockedOpticalDrive = [pscustomobject] @{
            Drive    = $script:testDriveLetter
            Caption  = $script:virtualDevices.VirtualScsiDvdRom.Caption
            DeviceID = $script:virtualDevices.VirtualScsiDvdRom.DeviceID
            Id       = $script:testDriveLetter
        }

        $script:mockedOpticalDriveNoDriveLetter = [pscustomobject] @{
            Drive    = $script:testDriveLetterNoVolume
            Caption  = $script:virtualDevices.VirtualScsiDvdRom.Caption
            DeviceID = $script:virtualDevices.VirtualScsiDvdRom.DeviceID
            Id       = $script:testDriveLetterNoVolume
        }

        $script:mockedOpticalDriveMultiDisks = @(
            $script:mockedOpticalDriveNoDriveLetter
            $script:mockedOpticalDrive
        )

        $script:mockedWrongLetterOpticalDrive = [pscustomobject] @{
            Drive    = 'W:'
            Caption  = $script:virtualDevices.VirtualScsiDvdRom.Caption
            DeviceID = $script:virtualDevices.VirtualScsiDvdRom.DeviceID
            Id       = 'W:'
        }

        $script:mockedOpticalDriveISO = [pscustomobject] @{
            Drive    = 'I:'
            Caption  = $script:virtualDevices.MountedIso.Caption
            DeviceID = $script:virtualDevices.MountedIso.DeviceID
            Id       = 'I:'
        }

        $script:mockedOpticalDriveIDE = [pscustomobject] @{
            Drive    = 'I:'
            Caption  = $script:virtualDevices.VirtualAtaDvdRomWs2022AzureGen1.Caption
            DeviceID = $script:virtualDevices.VirtualAtaDvdRomWs2022AzureGen1.DeviceID
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

        Describe 'DSC_OpticalDiskDriveLetter\Test-OpticalDiskCanBeManaged' {
            foreach ($virtualDevice in $script:virtualDevices.Values)
            {
                Context "When the optical drive is a $($virtualDevice.Description)" {
                    It 'Should return $($virtualDevice.CanManage)' {
                        Test-OpticalDiskCanBeManaged `
                            -OpticalDisk $virtualDevice `
                            -Verbose | Should -Be $virtualDevice.CanManage
                    }
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

            Context 'When a single optical disk drive is present in a Windows Server 2022 Azure Gen 2 VM and assigned a drive letter' {
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

            Context 'When a single optical disk drive is present in a Windows Server 2022 Azure Gen 2 VM and not assiged a drive letter' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                    $ClassName -eq 'Win32_CDROMDrive'
                } `
                    -MockWith {
                    $script:mockedOpticalDriveNoDriveLetterGen2
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

            Context 'When a single optical disk drive is present in a Windows Server 2022 Azure Gen 2 VM but second disk is requested' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter {
                        $ClassName -eq 'Win32_CDROMDrive'
                    } `
                        -MockWith {
                        $script:mockedOpticalDriveWs2022AzureGen2
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
