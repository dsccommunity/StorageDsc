<#
    .SYNOPSIS
        Unit test for DSC_VirtualHardDisk DSC resource.
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
    $script:dscResourceName = 'DSC_VirtualHardDisk'

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

# $script:DiskImageGoodVhdxPath = 'C:\test.vhdx'
# $script:DiskImageBadPath = '\\test.vhdx'
# $script:DiskImageGoodVhdPath = 'C:\test.vhd'
# $script:DiskImageNonVirtDiskPath = 'C:\test.text'
# $script:DiskImageVirtDiskPathWithoutExtension = 'C:\test'
# $script:DiskImageSizeBelowVirtDiskMinimum = 9Mb
# $script:DiskImageSizeAboveVhdMaximum = 2041Gb
# $script:DiskImageSizeAboveVhdxMaximum = 65Tb
# $script:DiskImageSize65Gb = 65Gb
# $script:MockTestPathCount = 0

# $script:mockedDiskImageMountedVhdx = [pscustomobject] @{
#     Attached   = $true
#     ImagePath  = 'C:\test.vhdx'
#     Size       = 100GB
#     DiskNumber = 2
# }

# $script:mockedDiskImageMountedVhd = [pscustomobject] @{
#     Attached   = $true
#     ImagePath  = $script:DiskImageGoodVhdPath
#     Size       = 100GB
#     DiskNumber = 2
# }

# $script:mockedDiskImageNotMountedVhdx = [pscustomobject] @{
#     Attached   = $false
#     ImagePath  = $script:DiskImageGoodVhdxPath
#     Size       = 100GB
#     DiskNumber = 2
# }

# $script:mockedDiskImageNotMountedVhd = [pscustomobject] @{
#     Attached   = $false
#     ImagePath  = $script:DiskImageGoodVhdPath
#     Size       = 100GB
#     DiskNumber = 2
# }

# $script:GetTargetOutputWhenBadPath = [pscustomobject] @{
#     FilePath   = $null
#     Attached   = $null
#     Size       = $null
#     DiskNumber = $null
#     Ensure     = 'Absent'
# }

# $script:GetTargetOutputWhenPathGood = [pscustomobject] @{
#     FilePath   = $mockedDiskImageMountedVhdx.ImagePath
#     Attached   = $mockedDiskImageMountedVhdx.Attached
#     Size       = $mockedDiskImageMountedVhdx.Size
#     DiskNumber = $mockedDiskImageMountedVhdx.DiskNumber
#     Ensure     = 'Present'
# }

# $script:mockedDiskImageEmpty = $null

# function Add-SimpleVirtualDisk
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(Mandatory = $true)]
#         [System.String]
#         $VirtualDiskPath,

#         [Parameter(Mandatory = $true)]
#         [ValidateSet('vhd', 'vhdx')]
#         [System.String]
#         $DiskFormat,

#         [Parameter()]
#         [ref]
#         $Handle
#     )
# }

# function New-SimpleVirtualDisk
# {
#     [CmdletBinding()]
#     param
#     (
#         [Parameter(Mandatory = $true)]
#         [System.String]
#         $VirtualDiskPath,

#         [Parameter(Mandatory = $true)]
#         [System.UInt64]
#         $DiskSizeInBytes,

#         [Parameter(Mandatory = $true)]
#         [ValidateSet('vhd', 'vhdx')]
#         [System.String]
#         $DiskFormat,

#         [Parameter(Mandatory = $true)]
#         [ValidateSet('fixed', 'dynamic')]
#         [System.String]
#         $DiskType
#     )
# }

Describe 'DSC_VirtualHardDisk\Get-TargetResource' -Tag 'Get' {
    Context 'When file path does not exist or was never mounted' {
        BeforeAll {
            Mock -CommandName Get-DiskImage
        }


        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath = '\\test.vhdx'
                }

                $currentState = Get-TargetResource @testParams

                $currentState.DiskNumber | Should -BeNullOrEmpty
                $currentState.FilePath | Should -BeNullOrEmpty
                $currentState.Attached | Should -BeNullOrEmpty
                $currentState.DiskSize | Should -BeNullOrEmpty
                $currentState.Ensure | Should -Be 'Absent'
            }
        }
    }

    Context 'When file path does exist and is currently mounted' {
        BeforeAll {
            Mock -CommandName Get-DiskImage -MockWith {
                @{
                    Attached   = $true
                    ImagePath  = 'C:\test.vhdx'
                    Size       = 100GB
                    DiskNumber = 2
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath = 'C:\test.vhdx'
                }

                $currentState = Get-TargetResource @testParams

                $currentState.DiskNumber | Should -Be 2
                $currentState.FilePath | Should -Be 'C:\test.vhdx'
                $currentState.Attached | Should -Be $true
                $currentState.DiskSize | Should -Be 100GB
                $currentState.Ensure | Should -Be 'Present'
            }
        }
    }
}

Describe 'DSC_VirtualHardDisk\Set-TargetResource' -Tag 'Set' {
    Context 'When not running as administrator' {
        BeforeAll {
            Mock -CommandName Assert-ParametersValid
            Mock -CommandName Assert-ElevatedUser -MockWith { throw }
        }

        It 'Should throw an error message that the user should run resource as admin' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $exception = [System.Exception]::new($script:localizedData.VirtualDiskAdminError)

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 65GB
                    DiskFormat = 'vhd'
                    Ensure     = 'Present'
                }

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage $exception.Message
            }
        }
    }

    Context 'Virtual disk is mounted and ensure set to present' {
        BeforeAll {
            Mock -CommandName Assert-ParametersValid
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    FilePath   = 'C:\test.vhdx'
                    Attached   = $true
                    DiskSize   = 100GB
                    DiskNumber = 2
                    Ensure     = 'Present'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 100GB
                    DiskFormat = 'vhdx'
                    Ensure     = 'Present'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Assert-ParametersValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-ElevatedUser -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'Virtual disk is mounted and ensure set to absent, so it should be dismounted' {
        BeforeAll {
            Mock -CommandName Assert-ParametersValid
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    FilePath   = 'C:\test.vhdx'
                    Attached   = $true
                    DiskSize   = 100GB
                    DiskNumber = 2
                    Ensure     = 'Absent'
                }
            }

            Mock -CommandName Dismount-DiskImage
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 100GB
                    DiskFormat = 'vhdx'
                    Ensure     = 'Absent'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Assert-ParametersValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-ElevatedUser -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Dismount-DiskImage -Exactly -Times 1 -Scope It
        }
    }

    Context 'Virtual disk is dismounted and ensure set to present, so it should be re-mounted' {
        BeforeAll {
            Mock -CommandName Assert-ParametersValid
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    FilePath   = 'C:\test.vhdx'
                    Attached   = $false
                    DiskSize   = 100GB
                    DiskNumber = 2
                    Ensure     = 'Present'
                }
            }

            Mock -CommandName Add-SimpleVirtualDisk
        }

        It 'Should call the expected mocks' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 100GB
                    DiskFormat = 'vhdx'
                    Ensure     = 'Present'
                }

                Set-TargetResource @testParams
            }

            Should -Invoke -CommandName Assert-ParametersValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-ElevatedUser -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-SimpleVirtualDisk -Exactly -Times 1 -Scope It
        }
    }

    Context 'Virtual disk does not exist and ensure set to present, so a new one should be created and mounted' {
        BeforeAll {
            Mock -CommandName Assert-ParametersValid
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    FilePath   = $null
                    Attached   = $false
                    DiskSize   = 100GB
                    DiskNumber = 2
                    Ensure     = 'Present'
                }
            }

            Mock -CommandName Test-Path -MockWith { $false }
            Mock -CommandName New-Item
            Mock -CommandName New-SimpleVirtualDisk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 100GB
                    DiskFormat = 'vhdx'
                    Ensure     = 'Present'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Assert-ParametersValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-ElevatedUser -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-Path -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Item -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-SimpleVirtualDisk -Exactly -Times 1 -Scope It
        }
    }

    Context 'When an exception occurs after creating the virtual disk' {
        BeforeAll {
            Mock -CommandName Assert-ParametersValid
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    FilePath   = $null
                    Attached   = $false
                    DiskSize   = 100GB
                    DiskNumber = 2
                    Ensure     = 'Present'
                }
            }

            Mock -CommandName Test-Path -MockWith { $false } -ParameterFilter { $PathType -eq 'Container' }
            Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter { $PathType -eq 'Leaf' }
            Mock -CommandName New-Item
            Mock -CommandName New-SimpleVirtualDisk -MockWith { throw }
            Mock -CommandName Remove-Item
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 100GB
                    DiskFormat = 'vhdx'
                    Ensure     = 'Present'
                }

                { Set-TargetResource @testParams } | Should -Throw
            }

            Should -Invoke -CommandName Assert-ParametersValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-ElevatedUser -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-Path -ParameterFilter { $PathType -eq 'Container' } -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Test-Path  -ParameterFilter { $PathType -eq 'Leaf' } -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Item -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-SimpleVirtualDisk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-Item -Exactly -Times 2 -Scope It
        }
    }
}

Describe 'DSC_VirtualHardDisk\Test-TargetResource' -Tag 'Test' {
    Context 'Virtual disk does not exist and ensure set to present' {
        BeforeAll {
            Mock -CommandName Assert-ParametersValid
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    FilePath   = 'C:\test.vhdx'
                    Attached   = $null
                    DiskSize   = $null
                    DiskNumber = $null
                    Ensure     = 'Absent'
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 100GB
                    DiskFormat = 'Vhdx'
                    Ensure     = 'Present'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-ParametersValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'Virtual disk does exist and ensure set to present' {
        BeforeAll {
            Mock -CommandName Assert-ParametersValid
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    FilePath   = 'C:\test.vhdx'
                    Attached   = $true
                    DiskSize   = 100GB
                    DiskNumber = 2
                    Ensure     = 'Present'
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 100GB
                    DiskFormat = 'Vhdx'
                    Ensure     = 'Present'
                }

                Test-TargetResource @testParams | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-ParametersValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'Virtual disk does not exist and ensure set to absent' {
        BeforeAll {
            Mock -CommandName Assert-ParametersValid
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    FilePath   = 'C:\test.vhdx'
                    Attached   = $null
                    DiskSize   = $null
                    DiskNumber = $null
                    Ensure     = 'Absent'
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 100GB
                    DiskFormat = 'Vhdx'
                    Ensure     = 'Absent'
                }

                Test-TargetResource @testParams | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-ParametersValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'Virtual disk does exist and ensure set to absent' {
        BeforeAll {
            Mock -CommandName Assert-ParametersValid
            Mock -CommandName Get-TargetResource -MockWith {
                @{
                    FilePath   = 'C:\test.vhdx'
                    Attached   = $true
                    DiskSize   = 100GB
                    DiskNumber = 2
                    Ensure     = 'Present'
                }
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 100GB
                    DiskFormat = 'Vhdx'
                    Ensure     = 'Absent'
                }

                Test-TargetResource @testParams | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-ParametersValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_VirtualHardDisk\Assert-ParametersValid' -Tag 'Helper' {
    Context 'When the file is not local' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = '\\test.vhdx'
                    DiskSize   = 100GB
                    DiskFormat = 'Vhdx'
                }

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.VirtualHardDiskPathError -f $testParams.FilePath
                ) -ArgumentName 'FilePath'

                { Assert-ParametersValid @testParams } | Should -Throw -ExpectedMessage $errorRecord
            }
        }
    }

    Context 'When the file does not have an extension' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test'
                    DiskSize   = 100GB
                    DiskFormat = 'Vhdx'
                }

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.VirtualHardDiskNoExtensionError -f $testParams.FilePath
                ) -ArgumentName 'FilePath'

                { Assert-ParametersValid @testParams } | Should -Throw -ExpectedMessage $errorRecord
            }
        }
    }

    Context 'When a file has an extension' {
        Context 'When the extension is not ''vhd'' or ''vhdx''' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        FilePath   = 'C:\test.txt'
                        DiskSize   = 100GB
                        DiskFormat = 'Vhdx'
                    }

                    $errorRecord = Get-InvalidArgumentRecord -Message (
                        $script:localizedData.VirtualHardDiskUnsupportedFileType -f 'txt'
                    ) -ArgumentName 'FilePath'

                    { Assert-ParametersValid @testParams } | Should -Throw -ExpectedMessage $errorRecord
                }
            }
        }

        Context 'When the extension is ''vhd'' or ''vhdx'' but does not match the disk format' {
            It 'Should not throw an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        FilePath   = 'C:\test.vhdx'
                        DiskSize   = 100GB
                        DiskFormat = 'Vhd'
                    }

                    $errorRecord = Get-InvalidArgumentRecord -Message (
                        $script:localizedData.VirtualHardDiskExtensionAndFormatMismatchError -f 'C:\test.vhdx', 'vhdx', 'Vhd'
                    ) -ArgumentName 'FilePath'

                    { Assert-ParametersValid @testParams } | Should -Throw $errorRecord
                }
            }
        }
    }

    Context 'When ''VHD'' size is too small' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhd'
                    DiskSize   = 5MB
                    DiskFormat = 'Vhd'
                }

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.VhdFormatDiskSizeInvalid -f '5.00MB'
                ) -ArgumentName 'DiskSize'

                { Assert-ParametersValid @testParams } | Should -Throw -ExpectedMessage $errorRecord
            }
        }
    }

    Context 'When ''VHD'' size is too large' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhd'
                    DiskSize   = 4096GB
                    DiskFormat = 'Vhd'
                }

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.VhdFormatDiskSizeInvalid -f '4.00TB'
                ) -ArgumentName 'DiskSize'

                { Assert-ParametersValid @testParams } | Should -Throw -ExpectedMessage $errorRecord
            }
        }
    }

    Context 'When ''VHD'' size correct' {
        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhd'
                    DiskSize   = 1024GB
                    DiskFormat = 'Vhd'
                }

                { Assert-ParametersValid @testParams } | Should -Not -Throw
            }
        }
    }

    Context 'When ''VHDX'' size is too small' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 5MB
                    DiskFormat = 'Vhdx'
                }

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.VhdxFormatDiskSizeInvalid -f '5.00MB'
                ) -ArgumentName 'DiskSize'

                { Assert-ParametersValid @testParams } | Should -Throw -ExpectedMessage $errorRecord
            }
        }
    }

    Context 'When ''VHDX'' size is too large' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 100TB
                    DiskFormat = 'Vhdx'
                }

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.VhdxFormatDiskSizeInvalid -f '100.00TB'
                ) -ArgumentName 'DiskSize'

                { Assert-ParametersValid @testParams } | Should -Throw -ExpectedMessage $errorRecord
            }
        }
    }

    Context 'When ''VHDX'' size correct' {
        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    FilePath   = 'C:\test.vhdx'
                    DiskSize   = 1024GB
                    DiskFormat = 'Vhdx'
                }

                { Assert-ParametersValid @testParams } | Should -Not -Throw
            }
        }
    }
}
