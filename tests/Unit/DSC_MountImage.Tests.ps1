<#
    .SYNOPSIS
        Unit test for DSC_MountImage DSC resource.
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
    $script:dscResourceName = 'DSC_MountImage'

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

Describe 'DSC_MountImage\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            function script:Get-Partition
            {
                Param
                (
                    [CmdletBinding()]
                    [Parameter(ValueFromPipeline)]
                    $Disk,

                    [String]
                    $DriveLetter,

                    [Uint32]
                    $DiskNumber,

                    [Uint32]
                    $PartitionNumber
                )
            }

            function script:Get-Volume
            {
                Param
                (
                    [CmdletBinding()]
                    [Parameter(ValueFromPipeline)]
                    $Partition,

                    [String]
                    $DriveLetter
                )
            }
        }
    }

    Context 'When an ISO is not mounted' {
        BeforeAll {
            Mock -CommandName Get-DiskImage -MockWith {
                [PSCustomObject] @{
                    Attached    = $false
                    DevicePath  = $null
                    FileSize    = 10GB
                    ImagePath   = 'test.iso'
                    Number      = $null
                    Size        = 10GB
                    StorageType = 1 ## ISO
                }
            }

            Mock -CommandName Get-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName Get-Volume
        }

        It 'Should return expected values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath = 'test.iso'
                }

                $result = Get-TargetResource @testParams

                $result.ImagePath   | Should -Be 'test.iso'
                $result.DriveLetter | Should -BeNullOrEmpty
                $result.StorageType | Should -BeNullOrEmpty
                $result.Access      | Should -BeNullOrEmpty
                $result.Ensure      | Should -Be 'Absent'
            }

            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
        }
    }

    Context 'When an ISO is mounted' {
        BeforeAll {
            Mock -CommandName Get-DiskImage -MockWith {
                [PSCustomObject] @{
                    Attached    = $true
                    DevicePath  = '\\.\CDROM1'
                    FileSize    = 10GB
                    ImagePath   = 'test.iso'
                    Number      = 3
                    Size        = 10GB
                    StorageType = 1 ## ISO
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    DriveType       = 'CD-ROM'
                    FileSystemType  = 'Unknown'
                    ObjectId        = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Volume.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:VO:\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\"'
                    UniqueId        = '\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\'
                    DriveLetter     = 'X'
                    FileSystem      = 'UDF'
                    FileSystemLabel = 'TEST_ISO'
                    Path            = '\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\'
                    Size            = 10GB
                }
            }

            Mock -CommandName Get-Disk
            Mock -CommandName Get-Partition
        }

        It 'Should return expected values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath = 'test.iso'
                }

                $result = Get-TargetResource @testParams

                $result.ImagePath   | Should -Be 'test.iso'
                $result.DriveLetter | Should -Be 'X'
                $result.StorageType | Should -Be 'ISO'
                $result.Access      | Should -Be 'ReadOnly'
                $result.Ensure      | Should -Be 'Present'
            }

            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a VHDX is not mounted' {
        BeforeAll {
            Mock -CommandName Get-DiskImage -MockWith {
                [PSCustomObject] @{
                    Attached    = $false
                    DevicePath  = $null
                    FileSize    = 10GB
                    ImagePath   = 'test.vhdx'
                    Number      = $null
                    Size        = 10GB
                    StorageType = 3 ## VHDx
                }
            }

            Mock -CommandName Get-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName Get-Volume
        }

        It 'Should return expected values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath = 'test.vhdx'
                }

                $result = Get-TargetResource @testParams

                $result.ImagePath   | Should -Be 'test.vhdx'
                $result.DriveLetter | Should -BeNullOrEmpty
                $result.StorageType | Should -BeNullOrEmpty
                $result.Access      | Should -BeNullOrEmpty
                $result.Ensure      | Should -Be 'Absent'
            }

            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
        }
    }

    Context 'VHDX is mounted as ReadWrite' {
        BeforeAll {
            Mock -CommandName Get-DiskImage -MockWith {
                [PSCustomObject] @{
                    Attached    = $true
                    DevicePath  = '\\.\PHYSICALDRIVE3'
                    FileSize    = 10GB
                    ImagePath   = 'test.vhdx'
                    Number      = 3
                    Size        = 10GB
                    StorageType = 3 ## ISO
                }
            }

            Mock -CommandName Get-Disk -MockWith {
                [PSCustomObject] @{
                    DiskNumber     = 3
                    PartitionStyle = 'GPT'
                    ObjectId       = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Disk.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:DI:\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"'
                    AllocatedSize  = 10GB
                    FriendlyName   = 'Msft Virtual Disk'
                    IsReadOnly     = $false
                    Location       = 'test.vhdx'
                    Number         = 3
                    Path           = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    Size           = 10GB
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    Type            = 'Basic'
                    DiskPath        = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    ObjectId        = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Partition.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:PR:{00000000-0000-0000-0000-901600000000}\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"'
                    UniqueId        = '{00000000-0000-0000-0000-901600000000}600224803F9B357CABEE50D4F858D17F'
                    AccessPaths     = '{X:\, \\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\}'
                    DiskId          = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    DiskNumber      = 3
                    DriveLetter     = 'X'
                    IsReadOnly      = $false
                    PartitionNumber = 2
                    Size            = 10GB
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    DriveType       = 'Fixed'
                    FileSystemType  = 'NTFS'
                    ObjectId        = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Volume.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:VO:\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\"'
                    UniqueId        = '\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\'
                    DriveLetter     = 'X'
                    FileSystem      = 'NTFS'
                    FileSystemLabel = 'TEST_VHDX'
                    Path            = '\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\'
                    Size            = 10GB
                }
            }
        }

        It 'Should return expected values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath = 'test.vhdx'
                }

                $result = Get-TargetResource @testParams

                $result.ImagePath   | Should -Be 'test.vhdx'
                $result.DriveLetter | Should -Be 'X'
                $result.StorageType | Should -Be 'VHDX'
                $result.Access      | Should -Be 'ReadWrite'
                $result.Ensure      | Should -Be 'Present'
            }

            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a VHDX is mounted as ReadOnly' {
        BeforeAll {
            Mock -CommandName Get-DiskImage -MockWith {
                [PSCustomObject] @{
                    Attached    = $true
                    DevicePath  = '\\.\PHYSICALDRIVE3'
                    FileSize    = 10GB
                    ImagePath   = 'test.vhdx'
                    Number      = 3
                    Size        = 10GB
                    StorageType = 3 ## ISO
                }
            }

            Mock -CommandName Get-Disk -MockWith {
                [PSCustomObject] @{
                    DiskNumber     = 3
                    PartitionStyle = 'GPT'
                    ObjectId       = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Disk.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:DI:\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"'
                    AllocatedSize  = 10GB
                    FriendlyName   = 'Msft Virtual Disk'
                    IsReadOnly     = $true
                    Location       = 'test.vhdx'
                    Number         = 3
                    Path           = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    Size           = 10GB
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    Type            = 'Basic'
                    DiskPath        = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    ObjectId        = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Partition.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:PR:{00000000-0000-0000-0000-901600000000}\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"'
                    UniqueId        = '{00000000-0000-0000-0000-901600000000}600224803F9B357CABEE50D4F858D17F'
                    AccessPaths     = '{X:\, \\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\}'
                    DiskId          = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    DiskNumber      = 3
                    DriveLetter     = 'X'
                    IsReadOnly      = $false
                    PartitionNumber = 2
                    Size            = 10GB
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    DriveType       = 'Fixed'
                    FileSystemType  = 'NTFS'
                    ObjectId        = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Volume.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:VO:\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\"'
                    UniqueId        = '\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\'
                    DriveLetter     = 'X'
                    FileSystem      = 'NTFS'
                    FileSystemLabel = 'TEST_VHDX'
                    Path            = '\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\'
                    Size            = 10GB
                }
            }
        }

        It 'Should return expected values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath = 'test.vhdx'
                }

                $result = Get-TargetResource @testParams

                $result.ImagePath   | Should -Be 'test.vhdx'
                $result.DriveLetter | Should -Be 'X'
                $result.StorageType | Should -Be 'VHDX'
                $result.Access      | Should -Be 'ReadOnly'
                $result.Ensure      | Should -Be 'Present'
            }

            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_MountImage\Set-TargetResource' -Tag 'Set' {
    Context 'When an ISO is mounted as Drive Letter X and should be' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X'
                    StorageType = 'ISO'
                    Access      = 'ReadOnly'
                    Ensure      = 'Present'
                }
            }

            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'X'
            }

            Mock -CommandName Mount-DiskImageToLetter
            Mock -CommandName Dismount-DiskImage
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X:'
                    Ensure      = 'Present'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Mount-DiskImageToLetter -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Dismount-DiskImage -Exactly -Times 0 -Scope It
        }
    }

    Context 'When an ISO is mounted as Drive Letter X but should be Y' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X'
                    StorageType = 'ISO'
                    Access      = 'ReadOnly'
                    Ensure      = 'Present'
                }
            }

            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'Y'
            }

            Mock -CommandName Mount-DiskImageToLetter
            Mock -CommandName Dismount-DiskImage
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'Y'
                    Ensure      = 'Present'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Mount-DiskImageToLetter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Dismount-DiskImage -Exactly -Times 1 -Scope It
        }
    }

    Context 'When an ISO is not mounted but should be' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath = 'test.iso'
                    Ensure    = 'Absent'
                }
            }

            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'X'
            }

            Mock -CommandName Mount-DiskImageToLetter
            Mock -CommandName Dismount-DiskImage
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X:'
                    Ensure      = 'Present'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Mount-DiskImageToLetter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Dismount-DiskImage -Exactly -Times 0 -Scope It
        }
    }

    Context 'When an ISO is mounted but should not be' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X'
                    StorageType = 'ISO'
                    Access      = 'ReadOnly'
                    Ensure      = 'Present'
                }
            }

            Mock -CommandName Dismount-DiskImage
            Mock -CommandName Mount-DiskImageToLetter
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath = 'test.iso'
                    Ensure    = 'Absent'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Mount-DiskImageToLetter -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Dismount-DiskImage -Exactly -Times 1 -Scope It
        }
    }

    Context 'When an ISO is not mounted and should not be' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath = 'test.iso'
                    Ensure    = 'Absent'
                }
            }

            Mock -CommandName Dismount-DiskImage
            Mock -CommandName Mount-DiskImageToLetter
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath = 'test.iso'
                    Ensure    = 'Absent'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw

            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Mount-DiskImageToLetter -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Dismount-DiskImage -Exactly -Times 0 -Scope It
        }
    }

    Context 'When VHDX is mounted as ReadOnly but should be ReadWrite' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath   = 'test.vhdx'
                    DriveLetter = 'X'
                    StorageType = 'VHDX'
                    Access      = 'ReadOnly'
                    Ensure      = 'Present'
                }
            }

            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'X'
            }

            Mock -CommandName Mount-DiskImageToLetter
            Mock -CommandName Dismount-DiskImage
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.vhdx'
                    DriveLetter = 'X:'
                    Access      = 'ReadWrite'
                    Ensure      = 'Present'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Mount-DiskImageToLetter -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Dismount-DiskImage -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_MountImage\Test-TargetResource' -Tag 'Test' {
    Context 'When an ISO is mounted as Drive Letter X and should be' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X'
                    StorageType = 'ISO'
                    Access      = 'ReadOnly'
                    Ensure      = 'Present'
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X:'
                    Ensure      = 'Present'
                }

                Test-TargetResource @testParams | Should -BeTrue
            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When an ISO is mounted as Drive Letter X but should be Y' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X'
                    StorageType = 'ISO'
                    Access      = 'ReadOnly'
                    Ensure      = 'Present'
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'Y'
                    Ensure      = 'Present'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When an ISO is not mounted but should be' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath = 'test.iso'
                    Ensure    = 'Absent'
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X:'
                    Ensure      = 'Present'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When an ISO is mounted but should not be' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X'
                    StorageType = 'ISO'
                    Access      = 'ReadOnly'
                    Ensure      = 'Present'
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath = 'test.iso'
                    Ensure    = 'Absent'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When an ISO is not mounted and should not be' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath = 'test.iso'
                    Ensure    = 'Absent'
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath = 'test.iso'
                    Ensure    = 'Absent'
                }

                Test-TargetResource @testParams | Should -BeTrue
            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a VHDX is mounted as ReadOnly but should be ReadWrite' {
        BeforeAll {
            Mock -CommandName Test-ParameterValid
            Mock -CommandName Get-TargetResource -MockWith {
                [PSCustomObject] @{
                    ImagePath   = 'test.vhdx'
                    DriveLetter = 'X'
                    StorageType = 'VHDX'
                    Access      = 'ReadOnly'
                    Ensure      = 'Present'
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.vhdx'
                    DriveLetter = 'X:'
                    Access      = 'ReadWrite'
                    Ensure      = 'Present'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }

            Should -Invoke -CommandName Test-ParameterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_MountImage\Test-ParameterValid' -Tag 'Helper' {
    Context 'When DriveLetter passed, ensure is Absent' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.InvalidParameterSpecifiedError -f 'Absent', 'DriveLetter'
                )

                $testParams = @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X:'
                    Ensure      = 'Absent'
                }

                { Test-ParameterValid @testParams } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When StorageType passed, ensure is Absent' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.InvalidParameterSpecifiedError -f 'Absent', 'StorageType'
                )

                $testParams = @{
                    ImagePath   = 'test.iso'
                    StorageType = 'VHD'
                    Ensure      = 'Absent'
                }

                { Test-ParameterValid @testParams } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When Access passed, ensure is Absent' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.InvalidParameterSpecifiedError -f 'Absent', 'Access'
                )

                $testParams = @{
                    ImagePath = 'test.iso'
                    Access    = 'ReadOnly'
                    Ensure    = 'Absent'
                }

                { Test-ParameterValid @testParams } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When Ensure is Absent, nothing else passed' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath = 'test.iso'
                    Ensure    = 'Absent'
                }

                { Test-ParameterValid @testParams } | Should -Not -Throw
            }
        }
    }

    Context 'When ImagePath passed but not found, ensure is Present' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith { $false }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath = 'test.iso'
                    Ensure    = 'Present'
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DiskImageFileNotFoundError -f $testParams.ImagePath
                )

                { Test-ParameterValid @testParams } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When ImagePath passed and found, ensure is Present, DriveLetter missing' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith { $true }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.InvalidParameterNotSpecifiedError -f 'Present', 'DriveLetter'
                )

                $testParams = @{
                    ImagePath = 'test.iso'
                    Ensure    = 'Present'
                }

                { Test-ParameterValid @testParams } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When ImagePath passed and found, ensure is Present, DriveLetter set' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith { $true }
            Mock -CommandName Assert-DriveLetterValid
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X:'
                    Ensure      = 'Present'
                }

                { Test-ParameterValid @testParams } | Should -Not -Throw
            }
        }
    }
}

Describe 'DSC_MountImage\Mount-DiskImageToLetter' -Tag 'Helper' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            <#
                These functions are required to be able to mock functions where
                values are passed in via the pipeline.
            #>
            function script:Get-Partition
            {
                Param
                (
                    [CmdletBinding()]
                    [Parameter(ValueFromPipeline)]
                    $Disk,

                    [String]
                    $DriveLetter,

                    [Uint32]
                    $DiskNumber,

                    [Uint32]
                    $PartitionNumber
                )
            }

            function script:Get-Volume
            {
                Param
                (
                    [CmdletBinding()]
                    [Parameter(ValueFromPipeline)]
                    $Partition,

                    [String]
                    $DriveLetter
                )
            }

            function script:Set-CimInstance
            {
                Param
                (
                    [CmdletBinding()]
                    [Parameter(ValueFromPipeline)]
                    $InputObject,

                    $Property
                )
            }
        }
    }

    Context 'When an ISO is specified and gets mounted to correct Drive Letter' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'X'
            }

            Mock -CommandName Mount-DiskImage
            Mock -CommandName Get-DiskImage -MockWith {
                [PSCustomObject] @{
                    Attached    = $false
                    DevicePath  = $null
                    FileSize    = 10GB
                    ImagePath   = 'test.iso'
                    Number      = $null
                    Size        = 10GB
                    StorageType = 1 ## ISO
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    DriveType       = 'CD-ROM'
                    FileSystemType  = 'Unknown'
                    ObjectId        = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Volume.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:VO:\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\"'
                    UniqueId        = '\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\'
                    DriveLetter     = 'X'
                    FileSystem      = 'UDF'
                    FileSystemLabel = 'TEST_ISO'
                    Path            = '\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\'
                    Size            = 10GB
                }
            }

            Mock -CommandName Get-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance
            Mock -CommandName Set-CimInstance
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'X:'
                }

                { Mount-DiskImageToLetter @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Mount-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When an ISO is specified and gets mounted to the wrong Drive Letter' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'Y'
            }

            Mock -CommandName Mount-DiskImage
            Mock -CommandName Get-DiskImage -MockWith {
                [PSCustomObject] @{
                    Attached    = $false
                    DevicePath  = $null
                    FileSize    = 10GB
                    ImagePath   = 'test.iso'
                    Number      = $null
                    Size        = 10GB
                    StorageType = 1 ## ISO
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    DriveType       = 'CD-ROM'
                    FileSystemType  = 'Unknown'
                    ObjectId        = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Volume.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:VO:\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\"'
                    UniqueId        = '\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\'
                    DriveLetter     = 'X'
                    FileSystem      = 'UDF'
                    FileSystemLabel = 'TEST_ISO'
                    Path            = '\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\'
                    Size            = 10GB
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Caption     = 'X:\'
                    Name        = 'X:\'
                    DeviceID    = '\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\'
                    Capacity    = 10GB
                    DriveLetter = 'X:'
                    DriveType   = 5
                    FileSystem  = 'UDF'
                    FreeSpace   = 0
                    Label       = 'TEST_ISO'
                }
            }

            Mock -CommandName Set-CimInstance
            Mock -CommandName Get-Disk
            Mock -CommandName Get-Partition
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.iso'
                    DriveLetter = 'Y'
                }

                $result = Mount-DiskImageToLetter @testParams

                { $result } | Should -Not -Throw
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Mount-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a VHDX is specified and gets mounted to correct Drive Letter' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'X'
            }

            Mock -CommandName Mount-DiskImage
            Mock -CommandName Get-DiskImage -MockWith {
                [PSCustomObject] @{
                    Attached    = $true
                    DevicePath  = '\\.\PHYSICALDRIVE3'
                    FileSize    = 10GB
                    ImagePath   = 'test.vhdx'
                    Number      = 3
                    Size        = 10GB
                    StorageType = 3 ## ISO
                }
            }

            Mock -CommandName Get-Disk -MockWith {
                [PSCustomObject] @{
                    DiskNumber     = 3
                    PartitionStyle = 'GPT'
                    ObjectId       = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Disk.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:DI:\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"'
                    AllocatedSize  = 10GB
                    FriendlyName   = 'Msft Virtual Disk'
                    IsReadOnly     = $false
                    Location       = 'test.vhdx'
                    Number         = 3
                    Path           = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    Size           = 10GB
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    Type            = 'Basic'
                    DiskPath        = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    ObjectId        = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Partition.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:PR:{00000000-0000-0000-0000-901600000000}\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"'
                    UniqueId        = '{00000000-0000-0000-0000-901600000000}600224803F9B357CABEE50D4F858D17F'
                    AccessPaths     = '{X:\, \\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\}'
                    DiskId          = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    DiskNumber      = 3
                    DriveLetter     = 'X'
                    IsReadOnly      = $false
                    PartitionNumber = 2
                    Size            = 10GB
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    DriveType       = 'Fixed'
                    FileSystemType  = 'NTFS'
                    ObjectId        = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Volume.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:VO:\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\"'
                    UniqueId        = '\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\'
                    DriveLetter     = 'X'
                    FileSystem      = 'NTFS'
                    FileSystemLabel = 'TEST_VHDX'
                    Path            = '\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\'
                    Size            = 10GB
                }
            }

            Mock -CommandName Get-CimInstance
            Mock -CommandName Set-CimInstance
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.vhdx'
                    DriveLetter = 'X:'
                }

                { Mount-DiskImageToLetter @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Mount-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When a VHDX is specified and gets mounted to the wrong Drive Letter' {
        BeforeAll {
            Mock -CommandName Assert-DriveLetterValid -MockWith {
                'Y'
            }

            Mock -CommandName Mount-DiskImage
            Mock -CommandName Get-DiskImage -MockWith {
                [PSCustomObject] @{
                    Attached    = $true
                    DevicePath  = '\\.\PHYSICALDRIVE3'
                    FileSize    = 10GB
                    ImagePath   = 'test.vhdx'
                    Number      = 3
                    Size        = 10GB
                    StorageType = 3 ## ISO
                }
            }

            Mock -CommandName Get-Disk -MockWith {
                [PSCustomObject] @{
                    DiskNumber     = 3
                    PartitionStyle = 'GPT'
                    ObjectId       = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Disk.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:DI:\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"'
                    AllocatedSize  = 10GB
                    FriendlyName   = 'Msft Virtual Disk'
                    IsReadOnly     = $false
                    Location       = 'test.vhdx'
                    Number         = 3
                    Path           = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    Size           = 10GB
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    Type            = 'Basic'
                    DiskPath        = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    ObjectId        = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Partition.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:PR:{00000000-0000-0000-0000-901600000000}\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"'
                    UniqueId        = '{00000000-0000-0000-0000-901600000000}600224803F9B357CABEE50D4F858D17F'
                    AccessPaths     = '{X:\, \\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\}'
                    DiskId          = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
                    DiskNumber      = 3
                    DriveLetter     = 'X'
                    IsReadOnly      = $false
                    PartitionNumber = 2
                    Size            = 10GB
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    DriveType       = 'Fixed'
                    FileSystemType  = 'NTFS'
                    ObjectId        = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Volume.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:VO:\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\"'
                    UniqueId        = '\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\'
                    DriveLetter     = 'X'
                    FileSystem      = 'NTFS'
                    FileSystemLabel = 'TEST_VHDX'
                    Path            = '\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\'
                    Size            = 10GB
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Caption     = "$('X:'):\"
                    Name        = "$('X:'):\"
                    DeviceID    = '\\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\'
                    Capacity    = 10GB
                    DriveLetter = "$('X:'):"
                    DriveType   = 3
                    FileSystem  = 'NTFS'
                    FreeSpace   = 8GB
                    Label       = 'TEST_VHDX'
                }
            }

            Mock -CommandName Set-CimInstance
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    ImagePath   = 'test.vhdx'
                    Access      = 'ReadWrite'
                    DriveLetter = 'Y'
                }

                { Mount-DiskImageToLetter @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Assert-DriveLetterValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Mount-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskImage -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-CimInstance -Exactly -Times 1 -Scope It
        }
    }
}
