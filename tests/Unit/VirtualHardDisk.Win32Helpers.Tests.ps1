#region HEADER, boilerplate used from StorageDSC.Common.Tests
$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)/$($script:subModuleName).psm1"

if (-not (Get-Module -Name $script:subModuleFile -ListAvailable)) {
    Import-Module $script:subModuleFile -Force -ErrorAction Stop
}
#endregion HEADER

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

# Begin Testing
InModuleScope $script:subModuleName {
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

    $script:DiskImageGoodVhdxPath = 'C:\test.vhdx'
    $script:AccessDeniedWin32Error = 5
    $script:vhdDiskFormat = 'vhd'
    [ref]$script:TestHandle = [System.IntPtr]::Zero
    $script:mockedParams = [pscustomobject] @{
        DiskSizeInBytes   = 65Gb
        VirtualDiskPath   = $script:DiskImageGoodVhdxPath
        DiskType          = 'dynamic'
        DiskFormat        = 'vhdx'
    }

    $script:mockedVhdParams = [pscustomobject] @{
        DiskSizeInBytes   = 65Gb
        VirtualDiskPath   = $script:DiskImageGoodVhdxPath
        DiskType          = 'dynamic'
        DiskFormat        = 'vhd'
    }

    Describe 'VirtualHardDisk.Win32Helpers\New-SimpleVirtualDisk' -Tag 'New-SimpleVirtualDisk' {
        Context 'Creating and attaching a new virtual disk (vhdx) successfully' {
            Mock `
                -CommandName New-VirtualDiskUsingWin32 `
                -MockWith { 0 } `
                -Verifiable

            Mock `
                -CommandName Add-VirtualDiskUsingWin32 `
                -MockWith { 0 } `
                -Verifiable

                It 'Should not throw an exception' {
                    {
                        New-SimpleVirtualDisk `
                            -VirtualDiskPath $script:mockedParams.VirtualDiskPath `
                            -DiskSizeInBytes $script:mockedParams.DiskSizeInBytes `
                            -DiskFormat $script:mockedParams.DiskFormat `
                            -DiskType $script:mockedParams.DiskType`
                            -Verbose
                    } | Should -Not -Throw
                }

            It 'Should only call required mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName New-VirtualDiskUsingWin32 -Exactly 1
                Assert-MockCalled -CommandName Add-VirtualDiskUsingWin32 -Exactly 1
            }
        }

        Context 'Creating and attaching a new virtual disk (vhd) successfully' {
            Mock `
                -CommandName New-VirtualDiskUsingWin32 `
                -MockWith { 0 } `
                -Verifiable

            Mock `
                -CommandName Add-VirtualDiskUsingWin32 `
                -MockWith { 0 } `
                -Verifiable

                It 'Should not throw an exception' {
                    {
                        New-SimpleVirtualDisk `
                            -VirtualDiskPath $script:mockedVhdParams.VirtualDiskPath `
                            -DiskSizeInBytes $script:mockedVhdParams.DiskSizeInBytes `
                            -DiskFormat $script:mockedVhdParams.DiskFormat `
                            -DiskType $script:mockedVhdParams.DiskType`
                            -Verbose
                    } | Should -Not -Throw
                }

            It 'Should only call required mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName New-VirtualDiskUsingWin32 -Exactly 1
                Assert-MockCalled -CommandName Add-VirtualDiskUsingWin32 -Exactly 1
            }
        }

        Context 'Creating a new virtual disk failed due to exception' {
            Mock `
                -CommandName New-VirtualDiskUsingWin32 `
                -MockWith { $script:AccessDeniedWin32Error } `
                -Verifiable
                $exception = [System.ComponentModel.Win32Exception]::new($script:AccessDeniedWin32Error)
            It 'Should throw an exception in creation method' {
                {
                    New-SimpleVirtualDisk `
                        -VirtualDiskPath $script:mockedParams.VirtualDiskPath `
                        -DiskSizeInBytes $script:mockedParams.DiskSizeInBytes `
                        -DiskFormat $script:mockedParams.DiskFormat `
                        -DiskType $script:mockedParams.DiskType`
                        -Verbose
                } | Should -Throw -ExpectedMessage $exception.Message
            }

            It 'Should only call required mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName New-VirtualDiskUsingWin32 -Exactly 1
            }
        }
    }

    Describe 'VirtualHardDisk.Win32Helpers\Add-SimpleVirtualDisk' -Tag 'Add-SimpleVirtualDisk' {
        Context 'Attaching a virtual disk failed due to exception' {

            Mock `
                -CommandName Get-VirtualDiskHandle `
                -MockWith { $script:TestHandle } `
                -Verifiable

            Mock `
                -CommandName Add-VirtualDiskUsingWin32 `
                -MockWith { $script:AccessDeniedWin32Error } `
                -Verifiable
            $exception = [System.ComponentModel.Win32Exception]::new($script:AccessDeniedWin32Error)
            It 'Should throw an exception during attach function' {
                {
                    Add-SimpleVirtualDisk `
                        -VirtualDiskPath $script:mockedParams.VirtualDiskPath `
                        -DiskFormat $script:mockedParams.DiskFormat `
                        -Verbose
                } | Should -Throw -ExpectedMessage $exception.Message
            }

            It 'Should only call required mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Add-VirtualDiskUsingWin32 -Exactly 2
                Assert-MockCalled -CommandName Get-VirtualDiskHandle -Exactly 1
            }
        }

        Context 'Attaching a virtual disk successfully' {
            Mock `
                -CommandName Add-VirtualDiskUsingWin32 `
                -MockWith { 0 } `
                -Verifiable

            Mock `
                -CommandName Get-VirtualDiskHandle `
                -MockWith { $script:TestHandle } `
                -Verifiable

            It 'Should not throw an exception' {
                {
                    Add-SimpleVirtualDisk `
                        -VirtualDiskPath $script:mockedParams.VirtualDiskPath `
                        -DiskFormat $script:mockedParams.DiskFormat `
                        -Verbose
                } | Should -Not -Throw
            }

            It 'Should only call required mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Get-VirtualDiskHandle -Exactly 1
                Assert-MockCalled -CommandName Add-VirtualDiskUsingWin32 -Exactly 1
            }
        }
    }

    Describe 'VirtualHardDisk.Win32Helpers\Get-VirtualDiskHandle' -Tag 'Get-VirtualDiskHandle' {
        Context 'Opening a virtual disk file failed due to exception' {

            Mock `
                -CommandName Get-VirtualDiskUsingWin32 `
                -MockWith { $script:AccessDeniedWin32Error } `
                -Verifiable

            $exception = [System.ComponentModel.Win32Exception]::new($script:AccessDeniedWin32Error)
            It 'Should throw an exception while attempting to open virtual disk file' {
                {
                    Get-VirtualDiskHandle `
                        -VirtualDiskPath $script:mockedParams.VirtualDiskPath `
                        -DiskFormat $script:mockedParams.DiskFormat `
                        -Verbose
                } | Should -Throw -ExpectedMessage $exception.Message
            }

            It 'Should only call required mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Get-VirtualDiskUsingWin32 -Exactly 1
            }
        }

        Context 'Opening a virtual disk file successfully' {
            Mock `
                -CommandName Get-VirtualDiskUsingWin32 `
                -MockWith { 0 } `
                -Verifiable

            It 'Should not throw an exception' {
                {
                    Get-VirtualDiskHandle `
                        -VirtualDiskPath $script:mockedParams.VirtualDiskPath `
                        -DiskFormat $script:mockedParams.DiskFormat `
                        -Verbose
                } | Should -Not -Throw
            }

            It 'Should only call required mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Get-VirtualDiskUsingWin32 -Exactly 1
            }
        }
    }

    Describe 'VirtualHardDisk.Win32Helpers\Get-VirtualStorageType' -Tag 'Get-VirtualStorageType' {
        Context 'Storage type requested for vhd disk format' {
            $result = Get-VirtualStorageType -DiskFormat $script:vhdDiskFormat
            It 'Should not throw an exception' {
                {
                    Get-VirtualStorageType `
                        -DiskFormat $script:vhdDiskFormat `
                        -Verbose
                } | Should -Not -Throw
            }
            Get-VirtDiskWin32HelperScript
            $virtualStorageType = New-Object -TypeName VirtDisk.Helper+VIRTUAL_STORAGE_TYPE
            $virtualStorageType.VendorId = [VirtDisk.Helper]::VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT
            $virtualStorageType.DeviceId = [VirtDisk.Helper]::VIRTUAL_STORAGE_TYPE_DEVICE_VHD

            It "Should return vendorId $($virtualStorageType.VendorId)" {
                $result.VendorId | Should -Be $virtualStorageType.VendorId
            }

            It "Should return DeviceId $($virtualStorageType.DeviceId)" {
                $result.DeviceId | Should -Be $virtualStorageType.DeviceId
            }
        }

        Context 'Storage type requested for vhdx disk format' {
            $result = Get-VirtualStorageType -DiskFormat $script:mockedParams.DiskFormat
            It 'Should not throw an exception' {
                {
                    Get-VirtualStorageType `
                        -DiskFormat $script:mockedParams.DiskFormat `
                        -Verbose
                } | Should -Not -Throw
            }
            Get-VirtDiskWin32HelperScript
            $virtualStorageType = New-Object -TypeName VirtDisk.Helper+VIRTUAL_STORAGE_TYPE
            $virtualStorageType.VendorId = [VirtDisk.Helper]::VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT
            $virtualStorageType.DeviceId = [VirtDisk.Helper]::VIRTUAL_STORAGE_TYPE_DEVICE_VHDX

            It "Should return vendorId $($virtualStorageType.VendorId)" {
                $result.VendorId | Should -Be $virtualStorageType.VendorId
            }

            It "Should return DeviceId $($virtualStorageType.DeviceId)" {
                $result.DeviceId | Should -Be $virtualStorageType.DeviceId
            }
        }

    }
}
