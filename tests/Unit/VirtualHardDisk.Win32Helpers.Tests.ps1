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
    function Get-VirtualDiskHandle
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
            $DiskFormat
        )
    }


    $script:DiskImageGoodVhdxPath = 'C:\test.vhdx'
    $script:AccessDeniedWin32Error = 5
    [ref]$script:TestHandle = [System.IntPtr]::Zero
    $script:mockedParams = [pscustomobject] @{
        DiskSizeInBytes   = 65Gb
        VirtualDiskPath   = $script:DiskImageGoodVhdxPath
        DiskType          = 'dynamic'
        DiskFormat        = 'vhdx'
    }

    Describe 'VirtualHardDisk.Win32Helpers\New-SimpleVirtualDisk' -Tag 'New-SimpleVirtualDisk' {
        Context 'Creating and attaching a new virtual disk successfully' {
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

        Context 'Creating a new virtual disk failed due to exception' {
            Mock `
                -CommandName New-VirtualDiskUsingWin32 `
                -MockWith { throw [System.ComponentModel.Win32Exception]::new($AccessDeniedWin32Error) } `
                -Verifiable

                It 'Should throw an exception in creation method' {
                    {
                        New-SimpleVirtualDisk `
                            -VirtualDiskPath $script:mockedParams.VirtualDiskPath `
                            -DiskSizeInBytes $script:mockedParams.DiskSizeInBytes `
                            -DiskFormat $script:mockedParams.DiskFormat `
                            -DiskType $script:mockedParams.DiskType`
                            -Verbose
                    } | Should -Throw
                }

            It 'Should only call required mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName New-VirtualDiskUsingWin32 -Exactly 1
            }
        }
    }
<#
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

                It 'Should throw an exception during attach function' {
                    {
                        Add-SimpleVirtualDisk `
                            -VirtualDiskPath $script:mockedParams.VirtualDiskPath `
                            -DiskFormat $script:mockedParams.DiskFormat `
                            -Handle $script:TestHandle `
                            -Verbose
                    } | Should -Throw
                }

            It 'Should only call required mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Add-VirtualDiskUsingWin32 -Exactly 1
                Assert-MockCalled -CommandName Get-VirtualDiskHandle -Exactly 1
            }
        }
    }

    Describe 'VirtualHardDisk.Win32Helpers\Get-VirtualStorageType' -Tag 'Get-VirtualStorageType' {
        Context 'When creating Vhd' {

            Mock `
                -CommandName Get-VirtualDiskHandle `
                -MockWith { $script:TestHandle } `
                -Verifiable

            Mock `
                -CommandName Add-VirtualDiskUsingWin32 `
                -MockWith { throw [System.ComponentModel.Win32Exception]::new($AccessDeniedWin32Error) } `
                -Verifiable

                It 'Should throw an exception during attach function' {
                    {
                        Add-SimpleVirtualDisk `
                            -VirtualDiskPath $script:mockedParams.VirtualDiskPath `
                            -DiskFormat $script:mockedParams.DiskFormat `
                            -Handle $script:TestHandle `
                            -Verbose
                    } | Should -Throw
                }

            It 'Should only call required mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Get-VirtualDiskUsingWin32 -Exactly 1
                Assert-MockCalled -CommandName Add-VirtualDiskUsingWin32 -Exactly 1
            }
        }
    }#>
}
