$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xMountImage'

#region HEADER
# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $script:DSCResourceName {
        # Function to create a exception object for testing output exceptions
        function Get-InvalidOperationError
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $ErrorId,

                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [System.String]
                $ErrorMessage
            )

            $exception = New-Object -TypeName System.InvalidOperationException `
                -ArgumentList $ErrorMessage
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $exception, $ErrorId, $errorCategory, $null
            return $errorRecord
        } # end function Get-InvalidOperationError

        #region Pester Test Initialization
        $script:DiskImageISOPath = 'test.iso'

        $script:DiskImageVHDXPath = 'test.vhdx'

        $script:mockedDiskImageISO = [pscustomobject] @{
            Attached          = $false
            DevicePath        = $null
            FileSize          = 10GB
            ImagePath         = $script:DiskImageISOPath
            Number            = $null
            Size              = 10GB
            StorageType       = 1 ## ISO
        }
        $script:mockedDiskImageAttachedISO = [pscustomobject] @{
            Attached          = $true
            DevicePath        = '\\.\CDROM1'
            FileSize          = 10GB
            ImagePath         = $script:DiskImageISOPath
            Number            = 3
            Size              = 10GB
            StorageType       = 1 ## ISO
        }

        $script:mockedDiskImageVHDX = [pscustomobject] @{
            Attached          = $false
            DevicePath        = $null
            FileSize          = 10GB
            ImagePath         = $script:DiskImageVHDXPath
            Number            = $null
            Size              = 10GB
            StorageType       = 3 ## VHDx
        }

        $script:mockedDiskImageAttachedVHDX = [pscustomobject] @{
            Attached          = $true
            DevicePath        = '\\.\PHYSICALDRIVE3'
            FileSize          = 10GB
            ImagePath         = $script:DiskImageVHDXPath
            Number            = 3
            Size              = 10GB
            StorageType       = 3 ## ISO
        }

        $script:mockedVolumeISO = [pscustomobject] @{
            DriveType         = 'CD-ROM'
            FileSystemType    = 'Unknown'
            ObjectId          = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Volume.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:VO:\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\"'
            UniqueId          = '\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\'
            DriveLetter       = 'X'
            FileSystem        = 'UDF'
            FileSystemLabel   = 'TEST_ISO'
            Path              = '\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\'
            Size              = 10GB
        }

        $script:mockedDiskVHDX = [pscustomobject] @{
            DiskNumber         = 3
            PartitionStyle     = 'GPT'
            ObjectId           = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Disk.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:DI:\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"'
            AllocatedSize      = 10GB
            FriendlyName       = 'Msft Virtual Disk'
            IsReadOnly         = $False
            Location           = $script:DiskImageVHDXPath
            Number             = 3
            Path               = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
            Size               = 10GB
        }

        $script:mockedDiskVHDXReadOnly = [pscustomobject] @{
            DiskNumber         = 3
            PartitionStyle     = 'GPT'
            ObjectId           = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Disk.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:DI:\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"'
            AllocatedSize      = 10GB
            FriendlyName       = 'Msft Virtual Disk'
            IsReadOnly         = $True
            Location           = $script:DiskImageVHDXPath
            Number             = 3
            Path               = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
            Size               = 10GB
        }

        $script:mockedPartitionVHDX = [pscustomobject] @{
            Type               = 'Basic'
            DiskPath           = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
            ObjectId           = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Partition.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:PR:{00000000-0000-0000-0000-901600000000}\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}"'
            UniqueId           = '{00000000-0000-0000-0000-901600000000}600224803F9B357CABEE50D4F858D17F'
            AccessPaths        = '{X:\, \\?\Volume{73496e75-5f0e-4d1d-9161-9931d7b1bb2f}\}'
            DiskId             = '\\?\scsi#disk&ven_msft&prod_virtual_disk#2&1f4adffe&0&000003#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}'
            DiskNumber         = 3
            DriveLetter        = 'X'
            IsReadOnly         = $False
            PartitionNumber    = 2
            Size               = 10GB
        }

        $script:mockedVolumeVHDX = [pscustomobject] @{
            DriveType         = 'CD-ROM'
            FileSystemType    = 'Unknown'
            ObjectId          = '{1}\\TEST\root/Microsoft/Windows/Storage/Providers_v2\WSP_Volume.ObjectId="{bba18018-e7a1-11e3-824e-806e6f6e6963}:VO:\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\"'
            UniqueId          = '\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\'
            DriveLetter       = 'X'
            FileSystem        = 'UDF'
            FileSystemLabel   = 'TEST_ISO'
            Path              = '\\?\Volume{cdb2a580-492f-11e5-82e9-40167e85b135}\'
            Size              = 10GB
        }
        #endregion

        #region functions for mocking pipeline
        # These functions are required to be able to mock functions where
        # values are passed in via the pipeline.
        function Get-Partition {
            Param
            (
                [cmdletbinding()]
                [Parameter(ValueFromPipeline)]
                $Disk,

                [String]
                $DriveLetter,

                [Uint32]
                $DiskNumber,

                [Uint32]
                $ParitionNumber
            )
        }

        function Get-Volume {
            Param
            (
                [cmdletbinding()]
                [Parameter(ValueFromPipeline)]
                $Partition,

                [String]
                $DriveLetter
            )
        }
        #endregion

        #region Function Get-TargetResource
        Describe 'MSFT_xMountImage\Get-TargetResource' {
            Context 'ISO is not mounted' {
                # Verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageISO } `
                    -Verifiable

                # Mocks that should not be called
                Mock -CommandName Get-Disk
                Mock -CommandName Get-Partition
                Mock -CommandName Get-Volume

                $resource = Get-TargetResource `
                    -ImagePath $script:DiskImageISOPath `
                    -Verbose

                It 'Should return expected values' {
                    $resource.ImagePath   | Should Be $script:DiskImageISOPath
                    $resource.Ensure      | Should Be 'Absent'
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                    Assert-MockCalled -CommandName Get-Disk -Exactly 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly 0
                }
            }

            Context 'ISO is mounted' {
                # Verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageAttachedISO } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeISO } `
                    -Verifiable

                # Mocks that should not be called
                Mock -CommandName Get-Disk
                Mock -CommandName Get-Partition

                $resource = Get-TargetResource `
                    -ImagePath $script:DiskImageISOPath `
                    -Verbose

                It 'Should return expected values' {
                    $resource.ImagePath   | Should Be $script:DiskImageISOPath
                    $resource.DriveLetter | Should Be $script:mockedVolumeISO.DriveLetter
                    $resource.StorageType | Should Be 'ISO'
                    $resource.Access      | Should Be 'ReadOnly'
                    $resource.Ensure      | Should Be 'Present'
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                    Assert-MockCalled -CommandName Get-Disk -Exactly 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'VHDX is not mounted' {
                # Verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageVHDX } `
                    -Verifiable

                # Mocks that should not be called
                Mock -CommandName Get-Disk
                Mock -CommandName Get-Partition
                Mock -CommandName Get-Volume

                $resource = Get-TargetResource `
                    -ImagePath $script:DiskImageVHDXPath `
                    -Verbose

                It 'Should return expected values' {
                    $resource.ImagePath   | Should Be $script:DiskImageVHDXPath
                    $resource.Ensure      | Should Be 'Absent'
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                    Assert-MockCalled -CommandName Get-Disk -Exactly 0
                    Assert-MockCalled -CommandName Get-Partition -Exactly 0
                    Assert-MockCalled -CommandName Get-Volume -Exactly 0
                }
            }

            Context 'VHDX is mounted as ReadWrite' {
                # Verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageAttachedVHDX } `
                    -Verifiable

                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDiskVHDX } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionVHDX } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeVHDX } `
                    -Verifiable


                $resource = Get-TargetResource `
                    -ImagePath $script:DiskImageVHDXPath `
                    -Verbose

                It 'Should return expected values' {
                    $resource.ImagePath   | Should Be $script:DiskImageVHDXPath
                    $resource.DriveLetter | Should Be $script:mockedVolumeVHDX.DriveLetter
                    $resource.StorageType | Should Be 'VHDX'
                    $resource.Access      | Should Be 'ReadWrite'
                    $resource.Ensure      | Should Be 'Present'
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                    Assert-MockCalled -CommandName Get-Disk -Exactly 1
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }

            Context 'VHDX is mounted as ReadOnly' {
                # Verifiable (should be called) mocks
                Mock `
                    -CommandName Get-DiskImage `
                    -MockWith { $script:mockedDiskImageAttachedVHDX } `
                    -Verifiable

                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $script:mockedDiskVHDXReadOnly } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $script:mockedPartitionVHDX } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $script:mockedVolumeVHDX } `
                    -Verifiable


                $resource = Get-TargetResource `
                    -ImagePath $script:DiskImageVHDXPath `
                    -Verbose

                It 'Should return expected values' {
                    $resource.ImagePath   | Should Be $script:DiskImageVHDXPath
                    $resource.DriveLetter | Should Be $script:mockedVolumeVHDX.DriveLetter
                    $resource.StorageType | Should Be 'VHDX'
                    $resource.Access      | Should Be 'ReadOnly'
                    $resource.Ensure      | Should Be 'Present'
                }

                It 'all the get mocks should be called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-DiskImage -Exactly 1
                    Assert-MockCalled -CommandName Get-Disk -Exactly 1
                    Assert-MockCalled -CommandName Get-Partition -Exactly 1
                    Assert-MockCalled -CommandName Get-Volume -Exactly 1
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_xMountImage\Set-TargetResource' {
        }
        #endregion

        #region Function Test-TargetResource
        Describe 'MSFT_xMountImage\Test-TargetResource' {
        }
        #endregion

        #region Function Test-ParameterValid
        Describe 'MSFT_xMountImage\Test-ParameterValid' {
            Context 'DriveLetter passed, ensure is Absent' {
                It 'Should throw InvalidParameterSpecifiedError exception' {
                    $errorRecord = Get-InvalidOperationError `
                        -ErrorId 'InvalidParameterSpecifiedError' `
                        -ErrorMessage ($LocalizedData.InvalidParameterSpecifiedError -f `
                            'Absent','DriveLetter')

                    {
                        Test-ParameterValid `
                            -ImagePath $script:DiskImageISOPath `
                            -DriveLetter 'X' `
                            -Ensure 'Absent'
                    } | Should Throw $errorRecord
                }
            }

            Context 'StorageType passed, ensure is Absent' {
                It 'Should throw InvalidParameterSpecifiedError exception' {
                    $errorRecord = Get-InvalidOperationError `
                        -ErrorId 'InvalidParameterSpecifiedError' `
                        -ErrorMessage ($LocalizedData.InvalidParameterSpecifiedError -f `
                            'Absent','StorageType')

                    {
                        Test-ParameterValid `
                            -ImagePath $script:DiskImageISOPath `
                            -StorageType 'VHD' `
                            -Ensure 'Absent'
                    } | Should Throw $errorRecord
                }
            }

            Context 'Access passed, ensure is Absent' {
                It 'Should throw InvalidParameterSpecifiedError exception' {
                    $errorRecord = Get-InvalidOperationError `
                        -ErrorId 'InvalidParameterSpecifiedError' `
                        -ErrorMessage ($LocalizedData.InvalidParameterSpecifiedError -f `
                            'Absent','Access')

                    {
                        Test-ParameterValid `
                            -ImagePath $script:DiskImageISOPath `
                            -Access 'ReadOnly' `
                            -Ensure 'Absent'
                    } | Should Throw $errorRecord
                }
            }

            Context 'Ensure is Absent, nothing else passed' {
                It 'Should not throw exception' {
                    {
                        Test-ParameterValid `
                            -ImagePath $script:DiskImageISOPath `
                            -Ensure 'Absent'
                    } | Should Not Throw
                }
            }

            Context 'ImagePath passed but not found, ensure is Present' {
                It 'Should throw InvalidParameterSpecifiedError exception' {
                    Mock `
                        -CommandName Test-Path `
                        -MockWith { $false }

                    $errorRecord = Get-InvalidOperationError `
                        -ErrorId 'DiskImageFileNotFoundError' `
                        -ErrorMessage ($LocalizedData.DiskImageFileNotFoundError -f `
                            $script:DiskImageISOPath)

                    {
                        Test-ParameterValid `
                            -ImagePath $script:DiskImageISOPath `
                            -Ensure 'Present'
                    } | Should Throw $errorRecord
                }
            }

            Context 'ImagePath passed and found, ensure is Present, DriveLetter missing' {
                It 'Should throw InvalidParameterSpecifiedError exception' {
                    Mock `
                        -CommandName Test-Path `
                        -MockWith { $true }

                    $errorRecord = Get-InvalidOperationError `
                        -ErrorId 'InvalidParameterNotSpecifiedError' `
                        -ErrorMessage ($LocalizedData.InvalidParameterNotSpecifiedError -f `
                            'Present','DriveLetter')

                    {
                        Test-ParameterValid `
                            -ImagePath $script:DiskImageISOPath `
                            -Ensure 'Present'
                    } | Should Throw $errorRecord
                }
            }

            Context 'ImagePath passed and found, ensure is Present, DriveLetter set' {
                It 'Should not throw exception' {
                    Mock `
                        -CommandName Test-Path `
                        -MockWith { $true }
                    {
                        Test-ParameterValid `
                            -ImagePath $script:DiskImageISOPath `
                            -DriveLetter 'X' `
                            -Ensure 'Present'
                    } | Should Not Throw
                }
            }

        }
        #endregion

        #region Function Mount-DiskImageToLetter
        Describe 'MSFT_xMountImage\Mount-DiskImageToLetter' {
        }
        #endregion
    }
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
