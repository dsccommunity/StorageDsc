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
        $script:DiskImageVirtDiskPathWithoutExtension = 'C:\test'
        $script:DiskImageSizeBelowVirtDiskMinimum = 9Mb
        $script:DiskImageSizeAboveVhdMaximum = 2041Gb
        $script:DiskImageSizeAboveVhdxMaximum = 65Tb
        $script:DiskImageSize65Gb = 65Gb
        $script:MockTestPathCount = 0

        $script:mockedDiskImageAttachedVhdx = [pscustomobject] @{
            Attached              = $true
            ImagePath             = $script:DiskImageGoodVhdxPath
            Size                  = 100GB
            DiskNumber            = 2
        }

        $script:mockedDiskImageAttachedVhd = [pscustomobject] @{
            Attached              = $true
            ImagePath             = $script:DiskImageGoodVhdPath
            Size                  = 100GB
            DiskNumber            = 2
        }

        $script:mockedDiskImageNotAttachedVhdx = [pscustomobject] @{
            Attached              = $false
            ImagePath             = $script:DiskImageGoodVhdxPath
            Size                  = 100GB
            DiskNumber            = 2
        }

        $script:mockedDiskImageNotAttachedVhd = [pscustomobject] @{
            Attached              = $false
            ImagePath             = $script:DiskImageGoodVhdPath
            Size                  = 100GB
            DiskNumber            = 2
        }

        $script:GetTargetOutputWhenBadPath = [pscustomobject] @{
            FilePath    = $null
            Attached    = $null
            Size        = $null
            DiskNumber  = $null
            Ensure      = 'Absent'
        }

        $script:GetTargetOutputWhenPathGood = [pscustomobject] @{
            FilePath     = $mockedDiskImageAttachedVhdx.ImagePath
            Attached    = $mockedDiskImageAttachedVhdx.Attached
            Size        = $mockedDiskImageAttachedVhdx.Size
            DiskNumber  = $mockedDiskImageAttachedVhdx.DiskNumber
            Ensure      = 'Present'
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

        Describe 'DSC_VirtualHardDisk\Get-TargetResource' {
            Context 'When file path does not exist or was never mounted' {

                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageEmpty } `
                    -Verifiable

                $resource = Get-TargetResource -FilePath $script:DiskImageBadPath -Verbose

                It "Should return DiskNumber $($script:GetTargetOutputWhenBadPath.DiskNumber)" {
                    $resource.DiskNumber | Should -Be $script:GetTargetOutputWhenBadPath.DiskNumber
                }

                It "Should return FilePath $($script:GetTargetOutputWhenBadPath.FilePath)" {
                    $resource.FilePath | Should -Be $script:GetTargetOutputWhenBadPath.FilePath
                }

                It "Should return Attached $($script:GetTargetOutputWhenBadPath.Attached)" {
                    $resource.Attached | Should -Be $script:GetTargetOutputWhenBadPath.Attached
                }

                It "Should return Size $($script:GetTargetOutputWhenBadPath.Size)" {
                    $resource.Size | Should -Be $script:GetTargetOutputWhenBadPath.Size
                }

                It "Should return Ensure $($script:GetTargetOutputWhenBadPath.Ensure)" {
                    $resource.Ensure | Should -Be $script:GetTargetOutputWhenBadPath.Ensure
                }
            }

            Context 'When file path does exist and was mounted at one point' {
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageAttachedVhdx } `
                    -Verifiable

                $resource = Get-TargetResource -FilePath $script:DiskImageGoodVhdxPath -Verbose

                It "Should return DiskNumber $($script:GetTargetOutputWhenPathGood.DiskNumber)" {
                    $resource.DiskNumber | Should -Be $script:GetTargetOutputWhenPathGood.DiskNumber
                }

                It "Should return FilePath $($script:GetTargetOutputWhenPathGood.FilePath)" {
                    $resource.FilePath | Should -Be $script:GetTargetOutputWhenPathGood.FilePath
                }

                It "Should return Attached $($script:GetTargetOutputWhenPathGood.Attached)" {
                    $resource.Attached | Should -Be $script:GetTargetOutputWhenPathGood.Attached
                }

                It "Should return Size $($script:GetTargetOutputWhenPathGood.Size)" {
                    $resource.Size | Should -Be $script:GetTargetOutputWhenPathGood.Size
                }

                It "Should return Ensure $($script:GetTargetOutputWhenPathGood.Ensure)" {
                    $resource.Ensure | Should -Be $script:GetTargetOutputWhenPathGood.Ensure
                }
            }
        }

        Describe 'DSC_VirtualHardDisk\Set-TargetResource' {

            Context 'When file path is not fully qualified' {

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.VirtualHardDiskPathError -f `
                        $DiskImageBadPath) `
                    -ArgumentName 'FilePath'

                It 'Should throw invalid argument error when path is not fully qualified' {
                    {
                        Set-TargetResource `
                            -FilePath $DiskImageBadPath `
                            -DiskSize $DiskImageSize65Gb `
                            -DiskFormat 'vhdx' `
                            -Ensure 'Present' `
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
                        Set-TargetResource `
                            -FilePath $DiskImageNonVirtDiskPath `
                            -DiskSize $DiskImageSize65Gb `
                            -DiskFormat 'vhdx' `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Throw $errorRecord
                }
            }

            Context 'When file extension does not match the disk format' {
                $extension = [System.IO.Path]::GetExtension($DiskImageGoodVhdPath).TrimStart('.')
                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.VirtualHardExtensionAndFormatMismatchError -f `
                        $DiskImageGoodVhdPath, $extension, 'vhdx') `
                    -ArgumentName 'FilePath'

                It 'Should throw invalid argument error when the file type and filepath extension do not match' {
                    {
                        Set-TargetResource `
                            -FilePath $DiskImageGoodVhdPath `
                            -DiskSize $DiskImageSize65Gb `
                            -DiskFormat 'vhdx' `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Throw $errorRecord
                }
            }

            Context 'When file extension is not present in the file path' {
                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.VirtualHardNoExtensionError -f `
                    $script:DiskImageVirtDiskPathWithoutExtension) `
                    -ArgumentName 'FilePath'

                It 'Should throw invalid argument error when the file type and filepath extension do not match' {
                    {
                        Set-TargetResource `
                            -FilePath $script:DiskImageVirtDiskPathWithoutExtension `
                            -DiskSize $DiskImageSize65Gb `
                            -DiskFormat 'vhdx' `
                            -Ensure 'Present' `
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
                        Set-TargetResource `
                            -FilePath $DiskImageGoodVhdPath `
                            -DiskSize $DiskImageSizeBelowVirtDiskMinimum `
                            -DiskFormat 'vhd' `
                            -Ensure 'Present' `
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
                        Set-TargetResource `
                            -FilePath $DiskImageGoodVhdxPath `
                            -DiskSize $DiskImageSizeBelowVirtDiskMinimum `
                            -DiskFormat 'vhdx' `
                            -Ensure 'Present' `
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
                        Set-TargetResource `
                            -FilePath $DiskImageGoodVhdPath `
                            -DiskSize $DiskImageSizeAboveVhdMaximum `
                            -DiskFormat 'vhd' `
                            -Ensure 'Present' `
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
                        Set-TargetResource `
                            -FilePath $DiskImageGoodVhdxPath `
                            -DiskSize $DiskImageSizeAboveVhdxMaximum `
                            -DiskFormat 'vhdx' `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Throw $errorRecord
                }
            }

            Context 'When file path to vhdx file is fully qualified' {
                It 'Should not throw invalid argument error when path is fully qualified' {
                    {
                        Set-TargetResource `
                            -FilePath $DiskImageGoodVhdxPath `
                            -DiskSize $DiskImageSize65Gb `
                            -DiskFormat 'vhdx' `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Not -Throw
                }
            }

            Context 'When file path to vhd is fully qualified' {
                It 'Should not throw invalid argument error when path is fully qualified' {
                    {
                        Set-TargetResource `
                            -FilePath $DiskImageGoodVhdPath `
                            -DiskSize $DiskImageSize65Gb `
                            -DiskFormat 'vhd' `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Not -Throw
                }
            }

            Context 'Virtual disk is mounted and ensure set to present' {

                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageAttachedVhdx } `
                    -Verifiable

                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                It 'Should not throw an exception' {
                    {
                        Set-TargetResource `
                            -FilePath $script:mockedDiskImageAttachedVhdx.ImagePath `
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
                            -FilePath $script:mockedDiskImageAttachedVhdx.ImagePath `
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
                            -FilePath $script:mockedDiskImageAttachedVhdx.ImagePath `
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
                            -FilePath $script:mockedDiskImageAttachedVhdx.ImagePath `
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

            Context 'When folder does not exist in user provided path but an exception occurs after creating the virtual disk' {

                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageEmpty } `
                    -Verifiable

                # Folder does not exist on system so return false to go into if block that creates the folder
                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter { $script:MockTestPathCount -eq 0 } `
                    -MockWith { $script:MockTestPathCount++; $false } `
                    -Verifiable

                # File was created and exists on system so return true to go into if block that deletes file
                Mock `
                    -CommandName Test-Path `
                    -ParameterFilter { $script:MockTestPathCount -eq 1 } `
                    -MockWith { $true } `
                    -Verifiable

                Mock `
                    -CommandName New-SimpleVirtualDisk `
                    -MockWith { throw [System.ComponentModel.Win32Exception]::new($script:AccessDeniedWin32Error) } `
                    -Verifiable

                Mock `
                    -CommandName New-Item `
                    -Verifiable

                Mock `
                    -CommandName Remove-Item `
                    -Verifiable

                $script:MockTestPathCount = 0
                $extension = [System.IO.Path]::GetExtension($script:mockedDiskImageAttachedVhdx.ImagePath).TrimStart('.')
                $exception = [System.ComponentModel.Win32Exception]::new($script:AccessDeniedWin32Error)
                It 'Should not let exception escape and new folder and file should be deleted' {
                    {
                        Set-TargetResource `
                            -FilePath $script:mockedDiskImageAttachedVhdx.ImagePath `
                            -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                            -DiskFormat $extension `
                            -Ensure 'Present' `
                            -Verbose
                    } | Should -Throw -ExpectedMessage $exception.Message
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                    Assert-MockCalled -CommandName New-Item -Exactly 1
                    Assert-MockCalled -CommandName Test-Path -Exactly 2
                    Assert-MockCalled -CommandName Remove-Item -Exactly 2
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
                        -FilePath $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'Present' `
                        -Verbose | Should -Be $false
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
                        -FilePath $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'Present' `
                        -Verbose | Should -Be $false
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
                        -FilePath $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'Absent' `
                        -Verbose | Should -Be $true
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
                        -FilePath $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'Present' `
                        -Verbose | Should -Be $true
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
                        -FilePath $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'absent' `
                        -Verbose | Should -Be $false
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
                        -FilePath $script:mockedDiskImageAttachedVhdx.ImagePath `
                        -DiskSize $script:mockedDiskImageAttachedVhdx.Size `
                        -DiskFormat $extension `
                        -Ensure 'absent' `
                        -Verbose | Should -Be $true
                }

                It 'Should only call required mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
