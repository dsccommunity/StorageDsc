<#
    .SYNOPSIS
        Unit test for DSC_OpticalDiskDriveLetter DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'StorageDsc'
    $script:dscResourceName = 'DSC_OpticalDiskDriveLetter'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

# $script:testOpticalDrives = [PSCustomObject] @{
#     Default       = [PSCustomObject] @{
#         DriveLetter = 'X:'
#         VolumeId    = 'Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}'
#     }
#     WrongLetter   = [PSCustomObject] @{
#         DriveLetter = 'W:'
#         VolumeId    = 'Volume{18508a20-5827-4bfa-96b3-0aeb5a2797c2}'
#     }
#     NoDriveLetter = [PSCustomObject] @{
#         DriveLetter = ''
#         VolumeId    = 'Volume{8c58ce81-0f58-4bd2-a575-0eb66a993ad7}'
#     }
#     Issue289      = [PSCustomObject] @{
#         DriveLetter = 'CdRom0'
#         VolumeId    = 'Volume{52a193f8-18db-11ef-8403-806e6f6e6963}'
#     }
# }

# $script:mockedOpticalDrives = [PSCustomObject] @{
#     Default       = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
#         Drive = 'X:'
#         Id    = 'X:'
#     } -ClientOnly
#     WrongLetter   = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
#         Drive = 'W:'
#         Id    = 'W:'
#     } -ClientOnly
#     NoDriveLetter = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
#         # When no drive letter is assigned, the Drive property is set to the volume ID
#         Drive = 'Volume{8c58ce81-0f58-4bd2-a575-0eb66a993ad7}'
#         Id    = ''
#     } -ClientOnly
#     Issue289      = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
#         <#
#                     It is possible for OS to report oprtical drive exists, but matching volume is not found
#                     This prevents disk from being maanged by this resource. See https://github.com/dsccommunity/StorageDsc/issues/289
#                 #>
#         Drive    = 'CdRom0'
#         Id       = 'CdRom0'
#         Caption  = 'Msft Virtual CD/ROM ATA Device'
#         Name     = 'Msft Virtual CD/ROM ATA Device'
#         DeviceID = 'IDE\CDROMMSFT_VIRTUAL_CD/ROM_____________________1.0_____\5&CFB56DE&0&1.0.0'
#     } -ClientOnly
# }

# $script:mockedVolume = [PSCustomObject] @{
#     Default       = New-CimInstance -ClassName Win32_Volume -Property @{
#         Name        = "X:\"
#         DriveLetter = "X:\"
#         DriveType   = 5
#         DeviceId    = "\\?\$('Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}')\"
#     } -ClientOnly
#     WrongLetter   = New-CimInstance -ClassName Win32_Volume -Property @{
#         Name        = $script:testOpticalDrives.WrongLetter.DriveLetter
#         DriveLetter = "$($script:testOpticalDrives.WrongLetter.DriveLetter)\"
#         DriveType   = 5
#         DeviceId    = "\\?\$($script:testOpticalDrives.WrongLetter.VolumeId)\"
#     } -ClientOnly
#     NoDriveLetter = New-CimInstance -ClassName Win32_Volume -Property @{
#         Name        = "$($script:testOpticalDrives.NoDriveLetter.DriveLetter)\"
#         DriveLetter = ''
#         DriveType   = 5
#         DeviceId    = "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)\"
#     } -ClientOnly
#     Issue289      = New-CimInstance -ClassName Win32_Volume -Property @{
#         Name        = "$($script:testOpticalDrives.Issue289.DriveLetter)\"
#         DriveLetter = ''
#         DriveType   = 5
#         DeviceId    = "\\?\$($script:testOpticalDrives.Issue289.VolumeId)\"
#     } -ClientOnly
# }

# $script:mockGetDiskImage = [PSCustomObject] @{
#     ManageableVirtualDrive  = {
#         # Throw an Microsoft.Management.Infrastructure.CimException with Message set to 'The specified disk is not a virtual disk.'
#         throw [Microsoft.Management.Infrastructure.CimException]::new($localizedData.DiskIsNotAVirtualDiskError)
#     }
#     NotManageableMountedISO = {
#         # This value doesn't matter as it is not used in the function
#         $true
#     }
# }

# $script:getCimInstanceCdRomDrive_ParameterFilter = {
#     $ClassName -eq 'Win32_CDROMDrive'
# }

# $script:mockedOpticalDriveNone = $null

# $script:mockedOpticalDriveMultiDisks = @(
#     $script:mockedOpticalDrives.NoDriveLetter
#     $script:mockedOpticalDrives.Default
# )

# Describe 'DSC_OpticalDiskDriveLetter\Get-TargetResource' {
#     Context 'When a single manageable optical disk drive is present with the correct drive letter' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 $script:result = Get-TargetResource `
#                     -DiskId 1 `
#                     -Driveletter $script:testOpticalDrives.Default.DriveLetter `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It "Should return the DriveLetter as '$($script:testOpticalDrives.Default.DriveLetter)' and Ensure is 'Present'" {
#             $script:result.DiskId | Should -Be 1
#             $script:result.DriveLetter | Should -Be $script:testOpticalDrives.Default.DriveLetter
#             $script:result.Ensure | Should -Be 'Present'
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When a single manageable optical disk drive is present with an incorrect drive letter' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.WrongLetter
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.WrongLetter.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.WrongLetter
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.WrongLetter.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 $script:result = Get-TargetResource `
#                     -DiskId 1 `
#                     -Driveletter $script:testOpticalDrives.Default.DriveLetter `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It "Should return the DriveLetter as '$($script:testOpticalDrives.WrongLetter.DriveLetter)' and Ensure is 'Present'" {
#             $script:result.DiskId | Should -Be 1
#             $script:result.DriveLetter | Should -Be $script:testOpticalDrives.WrongLetter.DriveLetter
#             $script:result.Ensure | Should -Be 'Present'
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When there are no optical disk drives present in the system' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             @()
#         } `
#             -Verifiable

#         It 'Should not throw exception' {
#             {
#                 $script:result = Get-TargetResource `
#                     -DiskId 1 `
#                     -Driveletter $script:testOpticalDrives.Default.DriveLetter `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It "Should return the DriveLetter as empty and Ensure is 'Absent'" {
#             $script:result.DiskId | Should -Be 1
#             $script:result.DriveLetter | Should -BeNullOrEmpty
#             $script:result.Ensure | Should -Be 'Absent'
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When a single unmanageable optical disk drive is present' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.NotManageableMountedISO `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 $script:result = Get-TargetResource `
#                     -DiskId 1 `
#                     -Driveletter $script:testOpticalDrives.Default.DriveLetter `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It "Should return the DriveLetter as empty and Ensure is 'Absent'" {
#             $script:result.DiskId | Should -Be 1
#             $script:result.DriveLetter | Should -BeNullOrEmpty
#             $script:result.Ensure | Should -Be 'Absent'
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }
# }

# Describe 'DSC_OpticalDiskDriveLetter\Set-TargetResource' {
#     Context 'When a single manageable optical disk drive exists with the correct drive letter and Ensure is not specified (Present)' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 Set-TargetResource `
#                     -DiskId 1 `
#                     -Driveletter $script:testOpticalDrives.Default.DriveLetter `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When a single manageable optical disk drive exists with the correct drive letter and Ensure set to Present' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 Set-TargetResource `
#                     -DiskId 1 `
#                     -Driveletter $script:testOpticalDrives.Default.DriveLetter `
#                     -Ensure 'Present' `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When a single manageable optical disk drive exists with a drive letter when Ensure is set to Absent' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
#             -Verifiable

#         Mock `
#             -CommandName Set-CimInstance `
#             -ParameterFilter {
#             [System.String]::IsNullOrWhiteSpace($Property.DriveLetter)
#         } `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 Set-TargetResource `
#                     -DiskId 1 `
#                     -Driveletter $script:testOpticalDrives.Default.DriveLetter `
#                     -Ensure 'Absent' `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When a single manageable optical disk drive exists with the wrong drive letter and Ensure is not specified (Present)' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.WrongLetter
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.WrongLetter.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.WrongLetter
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.WrongLetter.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
#             -Verifiable

#         Mock `
#             -CommandName Set-CimInstance `
#             -ParameterFilter {
#             $Property.DriveLetter -eq $script:testOpticalDrives.Default.DriveLetter
#         } `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 Set-TargetResource `
#                     -DiskId 1 `
#                     -Driveletter $script:testOpticalDrives.Default.DriveLetter `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When there are no optical disk drives present and Ensure is not specified (Present)' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.NotManageableMountedISO `
#             -Verifiable

#         It 'Should not throw exception' {
#             {
#                 $script:result = Set-TargetResource `
#                     -DiskId 1 `
#                     -Driveletter $script:testOpticalDrives.Default.DriveLetter `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When there are no manageable optical disk drives present and Ensure is not specified (Present)' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             @()
#         } `
#             -Verifiable

#         It 'Should not throw exception' {
#             {
#                 $script:result = Set-TargetResource `
#                     -DiskId 1 `
#                     -Driveletter $script:testOpticalDrives.Default.DriveLetter `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }
# }

# Describe 'DSC_OpticalDiskDriveLetter\Test-TargetResource' {
#     Context 'When a single manageable optical drive exists and is assigned the expected drive letter and Ensure is not specified (Present)' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 $script:result = Test-TargetResource `
#                     -DiskId 1 `
#                     -DriveLetter $script:testOpticalDrives.Default.DriveLetter `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It 'Should return $true' {
#             $script:result | Should -BeTrue
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When a single manageable optical drive exists but is assigned a drive letter but Ensure is set to Absent' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 $script:result = Test-TargetResource `
#                     -DiskId 1 `
#                     -DriveLetter $script:testOpticalDrives.Default.DriveLetter `
#                     -Ensure 'Absent' `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It 'Should return $false' {
#             $script:result | Should -BeFalse
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When a single manageable optical drive exists but the drive letter already exists on a volume that is not an optical disk drive' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.WrongLetter
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.WrongLetter.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.WrongLetter
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.WrongLetter.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
#             -Verifiable

#         $errorRecord = Get-InvalidOperationRecord `
#             -Message $($localizedData.DriveLetterAssignedToAnotherDrive -f $script:testOpticalDrives.Default.DriveLetter)

#         It 'Should throw expected exception' {
#             {
#                 $script:result = Test-TargetResource `
#                     -DiskId 1 `
#                     -DriveLetter $script:testOpticalDrives.Default.DriveLetter `
#                     -Verbose
#             } | Should -Throw $errorRecord
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When a single manageable optical drive exists and is assigned a drive letter but should not be because Ensure is Absent' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter {
#             $ClassName -eq 'Win32_Volume' -and `
#                 $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
#         } `
#             -MockWith {
#             $script:mockedVolume.Default
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 $script:result = Test-TargetResource `
#                     -DiskId 1 `
#                     -DriveLetter $script:testOpticalDrives.Default.DriveLetter `
#                     -Ensure 'Absent' `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It 'Should return $false' {
#             $script:result | Should -BeFalse
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When a single manageable optical drive exists and is not assigned a drive letter and should not be because Ensure is Absent' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             $script:mockedOpticalDrives.NoDriveLetter
#         } `
#             -Verifiable

#         Mock `
#             -CommandName Get-DiskImage `
#             -ParameterFilter {
#             $DevicePath -eq "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)"
#         } `
#             -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 $script:result = Test-TargetResource `
#                     -DiskId 1 `
#                     -DriveLetter $script:testOpticalDrives.Default.DriveLetter `
#                     -Ensure 'Absent' `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It 'Should return $true' {
#             $script:result | Should -BeTrue
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When there are no manageable optical drives in the system and Ensure is Present' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             @()
#         } `
#             -Verifiable

#         $errorRecord = Get-InvalidArgumentRecord `
#             -Message ($LocalizedData.NoOpticalDiskDriveError -f 1) `
#             -ArgumentName 'DiskId'

#         It 'Should throw expected exception' {
#             {
#                 $script:result = Test-TargetResource `
#                     -DiskId 1 `
#                     -Driveletter $script:testOpticalDrives.Default.DriveLetter `
#                     -Verbose
#             } | Should -Throw $errorRecord
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }

#     Context 'When there are no manageable optical drives in the system and Ensure is Absent' {
#         Mock `
#             -CommandName Get-CimInstance `
#             -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
#             -MockWith {
#             @()
#         } `
#             -Verifiable

#         It 'Should not throw an exception' {
#             {
#                 $script:result = Test-TargetResource `
#                     -DiskId 1 `
#                     -DriveLetter $script:testOpticalDrives.Default.DriveLetter `
#                     -Ensure 'Absent' `
#                     -Verbose
#             } | Should -Not -Throw
#         }

#         It 'Should return $true' {
#             $script:result | Should -BeTrue
#         }

#         It 'Should call all the verifiable mocks' {
#             Assert-VerifiableMock
#         }
#     }
# }

Describe 'DSC_OpticalDiskDriveLetter\Get-OpticalDiskDriveLetter' -Tag 'Helper' {
    Context 'When a single manageable optical disk drive is present and assigned a drive letter' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                    Drive = 'X:'
                    Id    = 'X:'
                } -ClientOnly
            }

            Mock -CommandName Test-OpticalDiskCanBeManaged -MockWith { $true }
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'X:'
            }
        }

        It 'Should return the correct drive letter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId = 1
                }

                $result = Get-OpticalDiskDriveLetter @testParams

                { $result } | Should -Not -Throw
                $result.DriveLetter | Should -Be 'X:'
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-OpticalDiskCanBeManaged -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a single manageable optical disk drive is present and is not assigned a drive letter' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                    # When no drive letter is assigned, the Drive property is set to the volume ID
                    Drive = 'Volume{8c58ce81-0f58-4bd2-a575-0eb66a993ad7}'
                    Id    = ''
                } -ClientOnly
            }

            Mock -CommandName Test-OpticalDiskCanBeManaged -MockWith { $true }
            Mock -CommandName Assert-DriveLetterValid -MockWith { throw }
        }

        It 'Should return the an empty DriveLetter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId = 1
                }

                $result = Get-OpticalDiskDriveLetter @testParams

                { $result } | Should -Not -Throw
                $result.DriveLetter | Should -BeNullOrEmpty
                $result.DeviceId | Should -Be 'Volume{8c58ce81-0f58-4bd2-a575-0eb66a993ad7}'
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-OpticalDiskCanBeManaged -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
        }
    }

    # Context 'When multiple manageable optical disk drives are present but only the second one is assigned a drive letter and the second disk is requested' {
    #     BeforeAll {
    #         Mock -CommandName Get-CimInstance -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter -MockWith {
    #             $script:mockedOpticalDriveMultiDisks
    #         }

    #         Mock -CommandName Get-CimInstance -ParameterFilter {
    #             $ClassName -eq 'Win32_Volume' -and
    #             $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
    #         } -MockWith {
    #             $script:mockedVolume.Default
    #         }

    #         Mock -CommandName Get-DiskImage -ParameterFilter {
    #             $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
    #         } -MockWith $script:mockGetDiskImage.ManageableVirtualDrive

    #         Mock -CommandName Get-DiskImage -ParameterFilter {
    #             $DevicePath -eq "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)"
    #         } -MockWith $script:mockGetDiskImage.ManageableVirtualDrive
    #     }

    #     It 'Should return the correct drive letter' {
    #         InModuleScope -ScriptBlock {
    #             Set-StrictMode -Version 1.0

    #             $testParams = @{
    #                 DiskId = 2
    #             }

    #             $result = Get-OpticalDiskDriveLetter @testParams

    #             { $result } | Should -Not -Throw
    #             $result.DriveLetter | Should -Be 'X:'
    #         }
    #     }
    # }

    # Context 'When a single manageable optical disk drive is present but a second disk is requested' {
    #     Mock `
    #         -CommandName Get-CimInstance `
    #         -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
    #         -MockWith {
    #         $script:mockedOpticalDrives.Default
    #     } `
    #         -Verifiable

    #     Mock `
    #         -CommandName Get-CimInstance `
    #         -ParameterFilter {
    #         $ClassName -eq 'Win32_Volume' -and `
    #             $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
    #     } `
    #         -MockWith {
    #         $script:mockedVolume.Default
    #     } `
    #         -Verifiable

    #     Mock `
    #         -CommandName Get-DiskImage `
    #         -ParameterFilter {
    #         $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
    #     } `
    #         -MockWith $script:mockGetDiskImage.ManageableVirtualDrive `
    #         -Verifiable

    #     It 'Should not throw exception' {
    #         {
    #             $script:result = Get-OpticalDiskDriveLetter `
    #                 -DiskId 2 `
    #                 -Verbose
    #         } | Should -Not -Throw
    #     }

    #     It 'DeviceId should be empty' {
    #         $script:result.DeviceId | Should -BeNullOrEmpty
    #     }

    #     It 'Should call all the verifiable mocks' {
    #         Assert-VerifiableMock
    #     }
    # }

    # Context 'When a single unmanageable optical disk drive (a mounted ISO) is present and is assigned a drive letter' {
    #     Mock `
    #         -CommandName Get-CimInstance `
    #         -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
    #         -MockWith {
    #         $script:mockedOpticalDrives.Default
    #     } `
    #         -Verifiable

    #     Mock `
    #         -CommandName Get-CimInstance `
    #         -ParameterFilter {
    #         $ClassName -eq 'Win32_Volume' -and `
    #             $Filter -eq "DriveLetter = '$($script:testOpticalDrives.Default.DriveLetter)'"
    #     } `
    #         -MockWith {
    #         $script:mockedVolume.Default
    #     } `
    #         -Verifiable

    #     Mock `
    #         -CommandName Get-DiskImage `
    #         -ParameterFilter {
    #         $DevicePath -eq "\\?\$($script:testOpticalDrives.Default.VolumeId)"
    #     } `
    #         -MockWith $script:mockGetDiskImage.NotManageableMountedISO `
    #         -Verifiable

    #     It 'Should not throw exception' {
    #         {
    #             $script:result = Get-OpticalDiskDriveLetter `
    #                 -DiskId 1 `
    #                 -Verbose
    #         } | Should -Not -Throw
    #     }

    #     It 'DeviceId should be empty' {
    #         $script:result.DeviceId | Should -BeNullOrEmpty
    #     }

    #     It 'Should call all the verifiable mocks' {
    #         Assert-VerifiableMock
    #     }
    # }

    # Context 'When a single unmanageable optical disk drive (a mounted ISO) is present and is not assigned a drive letter' {
    #     Mock `
    #         -CommandName Get-CimInstance `
    #         -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
    #         -MockWith {
    #         $script:mockedOpticalDrives.NoDriveLetter
    #     } `
    #         -Verifiable

    #     Mock `
    #         -CommandName Get-DiskImage `
    #         -ParameterFilter {
    #         $DevicePath -eq "\\?\$($script:testOpticalDrives.NoDriveLetter.VolumeId)"
    #     } `
    #         -MockWith $script:mockGetDiskImage.NotManageableMountedISO `
    #         -Verifiable

    #     It 'Should not throw exception' {
    #         {
    #             $script:result = Get-OpticalDiskDriveLetter `
    #                 -DiskId 1 `
    #                 -Verbose
    #         } | Should -Not -Throw
    #     }

    #     It 'DeviceId should be empty' {
    #         $script:result.DeviceId | Should -BeNullOrEmpty
    #     }

    #     It 'Should call all the verifiable mocks' {
    #         Assert-VerifiableMock
    #     }
    # }

    # Context 'When there are manageable or unmanageable optical disk drives are present in the system but a disk is requested' {
    #     Mock `
    #         -CommandName Get-CimInstance `
    #         -ParameterFilter $script:getCimInstanceCdRomDrive_ParameterFilter `
    #         -MockWith {
    #         @()
    #     } `
    #         -Verifiable

    #     It 'Should not throw exception' {
    #         {
    #             $script:result = Get-OpticalDiskDriveLetter `
    #                 -DiskId 1 `
    #                 -Verbose
    #         } | Should -Not -Throw
    #     }

    #     It 'DeviceId should be empty' {
    #         $script:result.DeviceId | Should -BeNullOrEmpty
    #     }

    #     It 'Should call all the verifiable mocks' {
    #         Assert-VerifiableMock
    #     }
    # }
}

Describe 'DSC_OpticalDiskDriveLetter\Test-OpticalDiskCanBeManaged' -Tag 'Helper' {
    Context 'When the optical disk drive passed is a mounted ISO with a drive letter' {
        BeforeAll {
            $script:opticalInstance = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                Drive = 'X:'
                Id    = 'X:'
            } -ClientOnly

            Mock -CommandName Get-CimInstance -MockWith {
                $opticalInstance
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -Parameters @{
                OpticalDisk = $script:opticalInstance
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    OpticalDisk = $OpticalDisk
                }

                $result = Test-OpticalDiskCanBeManaged @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the optical disk drive passed is a mounted ISO without a drive letter' {
        BeforeAll {
            Mock -CommandName Get-DiskImage -MockWith { $true }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    OpticalDisk = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                        # When no drive letter is assigned, the Drive property is set to the volume ID
                        Drive = 'Volume{8c58ce81-0f58-4bd2-a575-0eb66a993ad7}'
                        Id    = ''
                    } -ClientOnly
                }

                $result = Test-OpticalDiskCanBeManaged @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the optical disk drive passed is a virtual optical drive (not a mounted ISO) with a drive letter' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                New-CimInstance -ClassName Win32_Volume -Property @{
                    Name        = 'X:\'
                    DriveLetter = 'X:\'
                    DriveType   = 5
                    DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                } -ClientOnly
            }

            Mock -CommandName Get-DiskImage -MockWith {
                # Throw an Microsoft.Management.Infrastructure.CimException with Message set to 'The specified disk is not a virtual disk.'
                throw [Microsoft.Management.Infrastructure.CimException]::new('The specified disk is not a virtual disk.')
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    OpticalDisk = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                        Drive = 'X:'
                        Id    = 'X:'
                    } -ClientOnly
                }

                $result = Test-OpticalDiskCanBeManaged @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the optical disk drive passed is a virtual optical drive (not a mounted ISO) without a drive letter' {
        BeforeAll {
            Mock -CommandName Get-DiskImage -MockWith {
                # Throw an Microsoft.Management.Infrastructure.CimException with Message set to 'The specified disk is not a virtual disk.'
                throw [Microsoft.Management.Infrastructure.CimException]::new('The specified disk is not a virtual disk.')
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    OpticalDisk = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                        # When no drive letter is assigned, the Drive property is set to the volume ID
                        Drive = 'Volume{8c58ce81-0f58-4bd2-a575-0eb66a993ad7}'
                        Id    = ''
                    } -ClientOnly
                }

                $result = Test-OpticalDiskCanBeManaged @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the optical disk drive passed has DriveLetter set to "CdRom0" and so the volume can not be matched' {
        BeforeAll {
            Mock -CommandName Get-CimInstance
            # Get-DiskImage should not be called in this test, but if it is, it should throw an exception
            Mock -CommandName Get-DiskImage -MockWith {
                throw "Cannot bind argument to parameter 'DevicePath' because it is null."
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    OpticalDisk = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                        <#
                            It is possible for OS to report optical drive exists, but matching volume is not found
                            This prevents disk from being managed by this resource. See https://github.com/dsccommunity/StorageDsc/issues/289
                        #>
                        Drive    = 'CdRom0'
                        Id       = 'CdRom0'
                        Caption  = 'Msft Virtual CD/ROM ATA Device'
                        Name     = 'Msft Virtual CD/ROM ATA Device'
                        DeviceID = 'IDE\CDROMMSFT_VIRTUAL_CD/ROM_____________________1.0_____\5&CFB56DE&0&1.0.0'
                    } -ClientOnly
                }

                $result = Test-OpticalDiskCanBeManaged @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the optical disk drive passed is a virtual optical drive (not a mounted ISO) without a drive letter and Get-DiskImage throws an unknown exception' {
        BeforeAll {
            Mock -CommandName Get-DiskImage -MockWith {
                throw [Microsoft.Management.Infrastructure.CimException]::new('Another Message')
            }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    OpticalDisk = New-CimInstance -ClassName Win32_CDROMDrive -Property @{
                        # When no drive letter is assigned, the Drive property is set to the volume ID
                        Drive = 'Volume{8c58ce81-0f58-4bd2-a575-0eb66a993ad7}'
                        Id    = ''
                    } -ClientOnly
                }

                { Test-OpticalDiskCanBeManaged @testParams } | Should -Throw
            }

            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
        }
    }
}
