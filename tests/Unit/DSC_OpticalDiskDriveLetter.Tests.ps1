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

Describe 'DSC_OpticalDiskDriveLetter\Get-TargetResource' -Tag 'Get' {
    Context 'When the resource is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                @{
                    DriveLetter = 'X:'
                    DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'X:'
                }

                $result = Get-TargetResource @testParams

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.DiskId | Should -Be 1
                $result.DriveLetter | Should -Be 'X:'
                $result.Ensure | Should -Be 'Present'
            }
        }
    }

    Context 'When the resource is not in the desired state' {
        Context 'When the ''DeviceId'' is empty' {
            BeforeAll {
                Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                    @{
                        DriveLetter = ''
                        DeviceId    = ''
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        DiskId      = 1
                        DriveLetter = 'X:'
                    }

                    $result = Get-TargetResource @testParams

                    $result | Should -BeOfType [System.Collections.Hashtable]
                    $result.DiskId | Should -Be 1
                    $result.DriveLetter | Should -BeNullOrEmpty
                    $result.Ensure | Should -Be 'Absent'
                }
            }
        }

        Context 'When the ''DriveLetter'' is empty' {
            BeforeAll {
                Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                    @{
                        DriveLetter = ''
                        DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        DiskId      = 1
                        DriveLetter = 'X:'
                    }

                    $result = Get-TargetResource @testParams

                    $result | Should -BeOfType [System.Collections.Hashtable]
                    $result.DiskId | Should -Be 1
                    $result.DriveLetter | Should -BeNullOrEmpty
                    $result.Ensure | Should -Be 'Absent'
                }
            }
        }
    }
}

Describe 'DSC_OpticalDiskDriveLetter\Set-TargetResource' -Tag 'Set' {
    Context 'When the ''DriveLetter'' is incorrect' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith { 'X:' }
            Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                @{
                    DriveLetter = 'Y:'
                    DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                New-CimInstance -ClassName Win32_Volume -Property @{
                    Name        = 'Y:\'
                    DriveLetter = 'Y:\'
                    DriveType   = 5
                    DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                } -ClientOnly
            }

            Mock -CommandName Set-CimInstance
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'X:'
                    Ensure      = 'Present'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-OpticalDiskDriveLetter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the ''DriveLetter'' is not set' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith { 'X:' }
            Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                @{
                    DriveLetter = ''
                    DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                New-CimInstance -ClassName Win32_Volume -Property @{
                    Name        = ''
                    DriveLetter = ''
                    DriveType   = 5
                    DeviceId    = '\\?\Volume{8c58ce81-0f58-4bd2-a575-0eb66a993ad7}\'
                } -ClientOnly
            }

            Mock -CommandName Set-CimInstance
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'X:'
                    Ensure      = 'Present'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-OpticalDiskDriveLetter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the ''DriveLetter'' should not be set' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith { 'X:' }
            Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                @{
                    DriveLetter = 'Y:'
                    DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                New-CimInstance -ClassName Win32_Volume -Property @{
                    Name        = 'Y:\'
                    DriveLetter = 'Y:\'
                    DriveType   = 5
                    DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                } -ClientOnly
            }

            Mock -CommandName Set-CimInstance
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId      = 1
                    DriveLetter = 'X:'
                    Ensure      = 'Absent'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-OpticalDiskDriveLetter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-CimInstance -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_OpticalDiskDriveLetter\Test-TargetResource' -Tag 'Test' {
    Context 'When the resource is in the desired state' {
        Context 'When the resource should be ''Present''' {
            BeforeAll {
                Mock -CommandName Assert-DriveLetterValid -MockWith { 'X:' }
                Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                    @{
                        DriveLetter = 'X:'
                        DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                    }
                }
            }

            It 'Should return the correct result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        DiskId      = 1
                        DriveLetter = 'X:'
                        Ensure      = 'Present'
                    }

                    Test-TargetResource @testParams | Should -BeTrue
                }
            }
        }
    }

    Context 'When the resource is not in the desired state' {
        Context 'When the resource should be ''Present''' {
            Context 'When the optical disk does not exist' {
                BeforeAll {
                    Mock -CommandName Assert-DriveLetterValid -MockWith { 'X:' }
                    Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                        @{
                            DriveLetter = ''
                            DeviceId    = ''
                        }
                    }
                }

                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            DiskId      = 1
                            DriveLetter = 'X:'
                            Ensure      = 'Present'
                        }

                        $errorRecordParams = @{
                            Message      = ($script:localizedData.NoOpticalDiskDriveError -f $testParams.DiskId)
                            ArgumentName = 'DiskId'
                        }

                        $errorRecord = Get-InvalidArgumentRecord @errorRecordParams

                        { Test-TargetResource @testParams } | Should -Throw -ExpectedMessage $errorRecord
                    }
                }
            }

            Context 'When the optical disk is not available' {
                BeforeAll {
                    Mock -CommandName Assert-DriveLetterValid -MockWith { 'X:' }
                    Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                        @{
                            DriveLetter = 'Y:'
                            DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                        }
                    }

                    Mock -CommandName Get-CimInstance -MockWith {
                        New-CimInstance -ClassName Win32_Volume -Property @{
                            Name        = 'Y:\'
                            DriveLetter = 'Y:\'
                            DriveType   = 5
                            DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                        } -ClientOnly
                    }
                }

                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            DiskId      = 1
                            DriveLetter = 'X:'
                            Ensure      = 'Present'
                        }

                        $errorRecordParams = @{
                            Message = ($script:localizedData.DriveLetterAssignedToAnotherDrive -f $testParams.DriveLetter)
                        }

                        $errorRecord = Get-InvalidOperationRecord @errorRecordParams

                        { Test-TargetResource @testParams } | Should -Throw -ExpectedMessage $errorRecord
                    }
                }
            }

            Context 'When the optical disk not have the correct DriveLetter' {
                BeforeAll {
                    Mock -CommandName Assert-DriveLetterValid -MockWith { 'X:' }
                    Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                        @{
                            DriveLetter = 'Y:'
                            DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                        }
                    }

                    Mock -CommandName Get-CimInstance
                }

                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            DiskId      = 1
                            DriveLetter = 'X:'
                            Ensure      = 'Present'
                        }

                        Test-TargetResource @testParams | Should -BeFalse
                    }
                }
            }
        }

        Context 'When the resource should be ''Absent''' {
            Context 'When the resource should be ''Absent'' and the DriveLetter is empty' {
                BeforeAll {
                    Mock -CommandName Assert-DriveLetterValid -MockWith { 'X:' }
                    Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                        @{
                            DriveLetter = ''
                            DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                        }
                    }
                }

                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            DiskId      = 1
                            DriveLetter = 'X:'
                            Ensure      = 'Absent'
                        }

                        $result = Test-TargetResource @testParams

                        $result | Should -BeTrue
                    }
                }
            }

            Context 'When the resource should be ''Absent'' and the DriveLetter is not empty' {
                BeforeAll {
                    Mock -CommandName Assert-DriveLetterValid -MockWith { 'X:' }
                    Mock -CommandName Get-OpticalDiskDriveLetter -MockWith {
                        @{
                            DriveLetter = 'X:'
                            DeviceId    = '\\?\Volume{47b90a5d-f340-11e7-80fd-806e6f6e6963}\'
                        }
                    }
                }

                It 'Should return the correct result' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testParams = @{
                            DiskId      = 1
                            DriveLetter = 'X:'
                            Ensure      = 'Absent'
                        }

                        $result = Test-TargetResource @testParams

                        $result | Should -BeFalse
                    }
                }
            }
        }
    }
}

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

    Context 'When a disk does not exist' {
        BeforeAll {
            Mock -CommandName Get-CimInstance
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId = 1
                }

                $result = Get-OpticalDiskDriveLetter @testParams

                { $result } | Should -Not -Throw
                $result.DriveLetter | Should -BeNullOrEmpty
                $result.DeviceId | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }
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
