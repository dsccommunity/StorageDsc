$script:dscModuleName = 'StorageDsc'
$script:dscResourceName = 'DSC_VirtualHardDisk'

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
        $script:DiskImageGoodVhdxPath = 'C:\test.vhdx'
        $script:DiskImageBadPath = '\\test.vhdx'
        $script:DiskImageGoodVhdPath = 'C:\test.vhd'
        $script:DiskImageNonVirtDiskPath = 'C:\test.text'
        $script:DiskImageSizeBelowVirtDiskMinimum = 9Mb
        $script:DiskImageSizeAboveVhdMaximum = 2041Gb
        $script:DiskImageSizeAboveVhdxMaximum = 65Tb
        $script:DiskImageSize65Gb = 65Gb

        $script:mockedDiskImageAttachedVhdx = [pscustomobject] @{
            Attached          = $true
            ImagePath         = $script:DiskImageGoodVhdxPath
            Size              = 100GB
        }

        $script:mockedDiskImageAttachedVhd = [pscustomobject] @{
            Attached          = $true
            ImagePath         = $script:DiskImageGoodVhdPath
            Size              = 100GB
        }

        $script:mockedDiskImageNotAttachedVhdx = [pscustomobject] @{
            Attached          = $false
            ImagePath         = $script:DiskImageGoodVhdxPath
            Size              = 100GB
        }

        $script:mockedDiskImageNotAttachedVhd = [pscustomobject] @{
            Attached          = $false
            ImagePath         = $script:DiskImageGoodVhdPath
            Size              = 100GB
        }

        $script:mockedDiskImageEmpty = $null

        function Add-SimpleVirtualDisk
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true)]
                [System.String]
                $VirtualDiskPath,

                [Parameter(Mandatory = $true)]
                [ValidateSet('vhd', 'vhdx')]
                [System.String]
                $DiskFormat,

                [Parameter()]
                [ref]
                $Handle
            )
        }

        function New-SimpleVirtualDisk
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true)]
                [System.String]
                $VirtualDiskPath,

                [Parameter(Mandatory = $true)]
                [System.UInt64]
                $DiskSizeInBytes,

                [Parameter(Mandatory = $true)]
                [ValidateSet('vhd', 'vhdx')]
                [System.String]
                $DiskFormat,

                [Parameter(Mandatory = $true)]
                [ValidateSet('fixed', 'dynamic')]
                [System.String]
                $DiskType
            )
        }
        Function New-VirtualDiskUsingWin32
        {
            [CmdletBinding()]
            [OutputType([System.Int32])]
            Param
            (
                [Parameter(Mandatory = $true)]
                [ref]
                $VirtualStorageType,

                [Parameter(Mandatory = $true)]
                [System.String]
                $VirtualDiskPath,

                [Parameter(Mandatory = $true)]
                [UInt32]
                $AccessMask,

                [Parameter(Mandatory = $true)]
                [System.IntPtr]
                $SecurityDescriptor,

                [Parameter(Mandatory = $true)]
                [UInt32]
                $Flags,

                [Parameter(Mandatory = $true)]
                [System.UInt32]
                $ProviderSpecificFlags,

                [Parameter(Mandatory = $true)]
                [ref]
                $CreateVirtualDiskParameters,

                [Parameter(Mandatory = $true)]
                [System.IntPtr]
                $Overlapped,

                [Parameter(Mandatory = $true)]
                [ref]
                $Handle
            )
        }

        Function Add-VirtualDiskUsingWin32
        {
            [CmdletBinding()]
            [OutputType([System.Int32])]
            Param
            (
                [Parameter(Mandatory = $true)]
                [ref]
                $Handle,

                [Parameter(Mandatory = $true)]
                [System.IntPtr]
                $SecurityDescriptor,

                [Parameter(Mandatory = $true)]
                [System.UInt32]
                $Flags,

                [Parameter(Mandatory = $true)]
                [System.Int32]
                $ProviderSpecificFlags,

                [Parameter(Mandatory = $true)]
                [ref]
                $AttachVirtualDiskParameters,

                [Parameter(Mandatory = $true)]
                [System.IntPtr]
                $Overlapped
            )
        }

        Function Close-Win32Handle
        {

            [CmdletBinding()]
            [OutputType([System.Void])]
            Param
            (
                [Parameter(Mandatory = $true)]
                [ref]
                $Handle
            )
        }

        Function Get-VirtualDiskUsingWin32
        {

            [CmdletBinding()]
            [OutputType([System.Int32])]
            Param
            (
                [Parameter(Mandatory = $true)]
                [ref]
                $VirtualStorageType,

                [Parameter(Mandatory = $true)]
                [System.String]
                $VirtualDiskPath,

                [Parameter(Mandatory = $true)]
                [System.UInt32]
                $AccessMask,

                [Parameter(Mandatory = $true)]
                [System.UInt32]
                $Flags,

                [Parameter(Mandatory = $true)]
                [ref]
                $OpenVirtualDiskParameters,

                [Parameter(Mandatory = $true)]
                [ref]
                $Handle
            )
        }

        Describe 'DSC_VirtualHardDisk\Get-TargetResource' {
            Context 'When file path is not fully qualified' {

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.VirtualHardDiskPathError -f `
                        $DiskImageBadPath) `
                    -ArgumentName 'FilePath'

                It 'Should throw invalid argument error when path is not fully qualified' {
                    {
                        Get-TargetResource `
                            -FilePathWithExtension $DiskImageBadPath `
                            -DiskSize $DiskImageSize65Gb `
                            -Verbose
                    } | Should -Throw $errorRecord
                }
            }

            Context 'When file extension is not .vhd or .vhdx' {
                $extension = [System.IO.Path]::GetExtension($DiskImageNonVirtDiskPath).TrimStart('.')
                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.VirtualHardDiskUnsupportedFileType -f `
                        $extension) `
                    -ArgumentName 'FilePath'

                It 'Should throw invalid argument error when the file type is not supported' {
                    {
                        Get-TargetResource `
                            -FilePathWithExtension $DiskImageNonVirtDiskPath `
                            -DiskSize $DiskImageSize65Gb `
                            -Verbose
                    } | Should -Throw $errorRecord
                }
            }

            Context 'When size provided is less than the minimum size for the vhd format' {

                $minSizeInMbString = ($DiskImageSizeBelowVirtDiskMinimum / 1MB).ToString("0.00MB")
                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.VhdFormatDiskSizeInvalidMessage -f `
                        $minSizeInMbString) `
                    -ArgumentName 'DiskSize'

                It 'Should throw invalid argument error when the provided size is below the minimum for the vhd format' {
                    {
                        Get-TargetResource `
                            -FilePathWithExtension $DiskImageGoodVhdPath `
                            -DiskSize $DiskImageSizeBelowVirtDiskMinimum `
                            -Verbose
                    } | Should -Throw $errorRecord
                }
            }

            Context 'When size provided is less than the minimum size for the vhdx format' {
                $minSizeInMbString = ($DiskImageSizeBelowVirtDiskMinimum / 1MB).ToString("0.00MB")
                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.VhdxFormatDiskSizeInvalidMessage -f `
                        $minSizeInMbString) `
                    -ArgumentName 'DiskSize'

                It 'Should throw invalid argument error when the provided size is below the minimum for the vhdx format' {
                    {
                        Get-TargetResource `
                            -FilePathWithExtension $DiskImageGoodVhdxPath `
                            -DiskSize $DiskImageSizeBelowVirtDiskMinimum `
                            -Verbose
                    } | Should -Throw $errorRecord
                }
            }

            Context 'When size provided is greater than the maximum size for the vhd format' {
                $maxSizeInTbString = ($DiskImageSizeAboveVhdMaximum / 1TB).ToString("0.00TB")
                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.VhdFormatDiskSizeInvalidMessage -f `
                        $maxSizeInTbString) `
                    -ArgumentName 'DiskSize'

                It 'Should throw invalid argument error when the provided size is above the maximum for the vhd format' {
                    {
                        Get-TargetResource `
                            -FilePathWithExtension $DiskImageGoodVhdPath `
                            -DiskSize $DiskImageSizeAboveVhdMaximum `
                            -Verbose
                    } | Should -Throw $errorRecord
                }
            }

            Context 'When size provided is greater than the maximum size for the vhdx format' {
                $maxSizeInTbString = ($DiskImageSizeAboveVhdxMaximum / 1TB).ToString("0.00TB")
                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.VhdxFormatDiskSizeInvalidMessage -f `
                        $maxSizeInTbString) `
                    -ArgumentName 'DiskSize'

                It 'Should throw invalid argument error when the provided size is above the maximum for the vhdx format' {
                    {
                        Get-TargetResource `
                            -FilePathWithExtension $DiskImageGoodVhdxPath `
                            -DiskSize $DiskImageSizeAboveVhdxMaximum `
                            -Verbose
                    } | Should -Throw $errorRecord
                }
            }

            Context 'When file path to vhdx file is fully qualified' {
                It 'Should not throw invalid argument error when path is fully qualified' {
                    {
                        Get-TargetResource `
                            -FilePathWithExtension $DiskImageGoodVhdxPath `
                            -DiskSize $DiskImageSize65Gb `
                            -Verbose
                    } | Should -Not -Throw
                }
            }

            Context 'When file path to vhd is fully qualified' {
                It 'Should not throw invalid argument error when path is fully qualified' {
                    {
                        Get-TargetResource `
                            -FilePathWithExtension $DiskImageGoodVhdPath `
                            -DiskSize $DiskImageSize65Gb `
                            -Verbose
                    } | Should -Not -Throw
                }
            }
        }

        Describe 'DSC_VirtualHardDisk\Set-TargetResource' {

            Context 'Virtual disk is mounted and ensure set to present' {

                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageAttachedVhdx } `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -FilePathWithExtension $script:mockedDiskImageAttachedVhdx.ImagePath `
                            -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                            -DiskFormat $extension `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                }
            }

            Context 'Virtual disk is mounted and ensure set to absent, so it should be dismounted' {

                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageAttachedVhdx } `
                    -Verifiable

                Mock `
                    -CommandName Dismount-DiskImage `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should dismount the virtual disk' {
                    {
                        Set-TargetResource `
                            -FilePathWithExtension $script:mockedDiskImageAttachedVhdx.ImagePath `
                            -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                            -DiskFormat $extension `
                            -Ensure 'Absent' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                    Assert-MockCalled -CommandName Dismount-DiskImage -Exactly 1
                }
            }

            Context 'Virtual disk is dismounted and ensure set to present, so it should be re-mounted' {
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageNotAttachedVhdx } `
                    -Verifiable

                Mock `
                    -CommandName Add-SimpleVirtualDisk `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should Not throw exception' {
                    {
                        Set-TargetResource `
                            -FilePathWithExtension $script:mockedDiskImageAttachedVhdx.ImagePath `
                            -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                            -DiskFormat $extension `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                    Assert-MockCalled -CommandName Add-SimpleVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual disk does not exist and ensure set to present, so a new one should be created.' {
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageEmpty } `
                    -Verifiable

                Mock `
                    -CommandName New-SimpleVirtualDisk `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -FilePathWithExtension $script:mockedDiskImageAttachedVhdx.ImagePath `
                            -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                            -DiskFormat $extension `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                    Assert-MockCalled -CommandName New-SimpleVirtualDisk -Exactly 1
                }
            }

            Context 'Virtual disk does not exist and ensure set to present But exception happened after virtual disk file was created' {
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageEmpty } `
                    -Verifiable

                Mock `
                    -CommandName New-SimpleVirtualDisk `
                    -MockWith { throw } `
                    -Verifiable

                Mock `
                    -CommandName Test-Path `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName Remove-Item `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should not throw an exception and should remove the created virtual disk file.' {
                    {
                        Set-TargetResource `
                            -FilePathWithExtension $script:mockedDiskImageAttachedVhdx.ImagePath `
                            -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                            -DiskFormat $extension `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Not -Throw
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                    Assert-MockCalled -CommandName New-SimpleVirtualDisk -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 1
                    Assert-MockCalled -CommandName Remove-Item -Exactly 1
                }
            }
        }

        Describe 'DSC_VirtualHardDisk\Test-TargetResource' {
            Context 'Virtual disk does not exist and ensure set to present' {
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageEmpty } `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should return false.' {
                    Test-TargetResource `
                        -FilePathWithExtension $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'Present' `
                        -Verbose
                    | Should -Be $false
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                }
            }

            Context 'Virtual disk exists but is not mounted while ensure set to present' {
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageNotAttachedVhdx } `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should return false.' {
                    Test-TargetResource `
                        -FilePathWithExtension $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'Present' `
                        -Verbose
                    | Should -Be $false
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                }
            }

            Context 'Virtual disk does not exist and ensure set to absent' {
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageEmpty } `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should return true' {
                    Test-TargetResource `
                        -FilePathWithExtension $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'Absent' `
                        -Verbose
                    | Should -Be $true
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                }
            }

            Context 'Virtual disk exists, is mounted and ensure set to present' {
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageAttachedVhdx } `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should return true' {
                    Test-TargetResource `
                        -FilePathWithExtension $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'Present' `
                        -Verbose
                    | Should -Be $true
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                }
            }

            Context 'Virtual disk exists but is mounted while ensure set to absent' {
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageAttachedVhdx } `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should return false.' {
                    Test-TargetResource `
                        -FilePathWithExtension $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'absent' `
                        -Verbose
                    | Should -Be $false
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                }
            }

            Context 'Virtual disk exists but is not mounted while ensure set to absent' {
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageNotAttachedVhdx } `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should return true.' {
                    Test-TargetResource `
                        -FilePathWithExtension $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'absent' `
                        -Verbose
                    | Should -Be $true
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                }
            }

        }
        #endregion
    }
}
finally
{
    Invoke-TestCleanup
}
