$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xDisk'

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
        $global:mockedDisk0 = [pscustomobject] @{
                Number = 0
                DiskNumber = 0
                IsOffline = $false
                IsReadOnly = $false
                PartitionStyle = 'GPT'
            }
        $global:mockedDisk0Mbr = [pscustomobject] @{
                Number = 0
                DiskNumber = 0
                IsOffline = $false
                IsReadOnly = $false
                PartitionStyle = 'MBR'
            }

        $global:mockedDisk0Offline = [pscustomobject] @{
                Number = 0
                DiskNumber = 0
                IsOffline = $true
                IsReadOnly = $false
                PartitionStyle = 'GPT'
            }

        $global:mockedDisk0OfflineRaw = [pscustomobject] @{
                Number = 0
                DiskNumber = 0
                IsOffline = $true
                IsReadOnly = $false
                PartitionStyle = 'Raw'
            }

        $global:mockedDisk0Readonly = [pscustomobject] @{
                Number = 0
                DiskNumber = 0
                IsOffline = $false
                IsReadOnly = $true
                PartitionStyle = 'GPT'
            }

        $global:mockedDisk0Raw = [pscustomobject] @{
                Number = 0
                DiskNumber = 0
                IsOffline = $false
                IsReadOnly = $false
                PartitionStyle = 'Raw'
            }

        $global:mockedWmi = [pscustomobject] @{BlockSize=4096}

        $global:mockedPartition = [pscustomobject] @{
                DriveLetter='F'
                Size=123
            }

        $global:mockedVolume = [pscustomobject] @{
                FileSystemLabel = 'myLabel'
                DriveLetter = 'F'
                FileSystem = 'NTFS'
            }

        $global:mockedVolumeNoDriveLetter = [pscustomobject] @{
                FileSystemLabel = 'myLabel'
                DriveLetter = ''
                FileSystem = 'NTFS'
            }

        $global:mockedVolumeReFS = [pscustomobject] @{
                FileSystemLabel = 'myLabel'
                DriveLetter = 'F'
                FileSystem = 'ReFS'
            }
        #endregion

        #region functions for mocking pipeline
        # These functions are required to be able to mock functions where
        # values are passed in via the pipeline.
        function Set-Disk {
            Param
            (
                [cmdletbinding()]
                [Parameter(ValueFromPipeline)]
                $InputObject,

                [Boolean]
                $IsOffline,

                [Boolean]
                $IsReadOnly
            )
        }

        function Initialize-Disk {
            Param
            (
                [cmdletbinding()]
                [Parameter(ValueFromPipeline)]
                $InputObject,

                [String]
                $PartitionStyle
            )
        }

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

        function Set-Volume {
            Param
            (
                [cmdletbinding()]
                [Parameter(ValueFromPipeline)]
                $InputObject,

                [String]
                $NewFileSystemLabel
            )
        }

        function Format-Volume {
            Param
            (
                [cmdletbinding()]
                [Parameter(ValueFromPipeline)]
                $Partition,

                [String]
                $DriveLetter,

                [String]
                $FileSystem,

                [Boolean]
                $Confirm,

                [String]
                $NewFileSystemLabel,

                [Uint32]
                $AllocationUnitSize
            )
        }
        #endregion

        #region Function Get-TargetResource
        Describe 'MSFT_xDisk\Get-TargetResource' {
            # verifiable (should be called) mocks
            Mock `
                -CommandName Get-CimInstance `
                -MockWith { $global:mockedWmi } `
                -Verifiable

            Mock `
                -CommandName Get-Disk `
                -MockWith { $global:mockedDisk0 } `
                -Verifiable

            Mock `
                -CommandName Get-Partition `
                -MockWith { $global:mockedPartition } `
                -Verifiable

            Mock `
                -CommandName Get-Volume `
                -MockWith { $global:mockedVolume } `
                -Verifiable

            # mocks that should not be called
            Mock -CommandName Get-WmiObject

            $resource = Get-TargetResource `
                -DiskNumber 0 `
                -DriveLetter 'G' `
                -Verbose
            It 'DiskNumber should be 0' {
                $resource.DiskNumber | Should be 0
            }

            It 'DriveLetter should be F' {
                $resource.DriveLetter | Should be 'F'
            }

            It 'Size should be 123' {
                $resource.Size | Should be 123
            }

            It 'FSLabel should be myLabel' {
                $resource.FSLabel | Should be 'myLabel'
            }

            It 'AllocationUnitSize should be 4096' {
                $resource.AllocationUnitSize | Should be 4096
            }

            It 'FSFormat should be NTFS' {
                $resource.FSFormat | Should be 'NTFS'
            }

            It 'all the get mocks should be called' {
                Assert-VerifiableMocks
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_xDisk\Set-TargetResource' {
            Context 'Offline GPT disk' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0Offline } `
                    -Verifiable

                Mock `
                    -CommandName Set-Disk `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                        $DriveLetter -eq 'G'
                    } `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Initialize-Disk
                Mock -CommandName Get-Volume
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-targetResource `
                            -DiskNumber 0 `
                            -Driveletter 'G' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                            $DriveLetter -eq 'G'
                        }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                }
            }

            Context 'Readonly GPT disk' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0Readonly } `
                    -Verifiable

                Mock `
                    -CommandName Set-Disk `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                        $DriveLetter -eq 'G'
                    } `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Initialize-Disk
                Mock -CommandName Get-Volume
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-targetResource `
                            -DiskNumber 0 `
                            -Driveletter 'G' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                            $DriveLetter -eq 'G'
                        }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                }
            }

            Context 'Offline RAW disk' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0OfflineRaw } `
                    -Verifiable

                Mock `
                    -CommandName Set-Disk `
                    -Verifiable

                Mock `
                    -CommandName Initialize-Disk `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                        $DriveLetter -eq 'G'
                    } `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-targetResource `
                            -DiskNumber 0 `
                            -Driveletter 'G' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 1
                    Assert-MockCalled -CommandName Initialize-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                            $DriveLetter -eq 'G'
                        }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                }
            }

            Context 'Online RAW disk' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0Raw } `
                    -Verifiable

                Mock `
                    -CommandName Initialize-Disk `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                        $DriveLetter -eq 'G'
                    } `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Get-Volume
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-targetResource `
                            -DiskNumber 0 `
                            -Driveletter 'G' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                            $DriveLetter -eq 'G'
                        }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                }
            }

            Context 'Online GPT disk with no partitions' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -Verifiable

                Mock `
                    -CommandName New-Partition `
                    -ParameterFilter {
                        $DriveLetter -eq 'G'
                    } `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Format-Volume `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Get-Volume
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-targetResource `
                            -DiskNumber 0 `
                            -Driveletter 'G' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 1 `
                        -ParameterFilter {
                            $DriveLetter -eq 'G'
                        }
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                }
            }

            Context 'Online MBR disk' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0Mbr } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Get-Partition
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume
                Mock -CommandName Get-Volume
                Mock -CommandName Set-Partition

                $errorRecord = Get-InvalidOperationError `
                    -ErrorId 'DiskAlreadyInitializedError' `
                    -ErrorMessage ($LocalizedData.DiskAlreadyInitializedError -f `
                        0,$global:mockedDisk0Mbr.PartitionStyle)

                It 'Should throw DiskAlreadyInitializedError' {
                    {
                        Set-targetResource `
                            -DiskNumber 0 `
                            -Driveletter 'G' `
                            -Verbose
                    } | Should Throw $errorRecord
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                }
            }

            Context 'Online GPT disk with a partition/volume' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $global:mockedVolume } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Format-Volume
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-targetResource `
                            -DiskNumber 0 `
                            -Driveletter 'F' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                }
            }

            Context 'Online GPT disk with a partition/volume and no Drive Letter assigned' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $global:mockedVolumeNoDriveLetter } `
                    -Verifiable

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Format-Volume

                It 'Should not throw' {
                    {
                        Set-targetResource `
                            -DiskNumber 0 `
                            -Driveletter 'F' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                }
            }

            Context 'Online GPT disk with a partition/volume and wrong Drive Letter assigned' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $global:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-Partition `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Format-Volume

                It 'Should not throw' {
                    {
                        Set-targetResource `
                            -DiskNumber 0 `
                            -Driveletter 'G' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 1
                }
            }

            Context 'Online GPT disk with a partition/volume and wrong Volume Label assigned' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $global:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Set-Volume `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Disk
                Mock -CommandName Initialize-Disk
                Mock -CommandName Format-Volume
                Mock -CommandName Set-Partition

                It 'Should not throw' {
                    {
                        Set-targetResource `
                            -DiskNumber 0 `
                            -Driveletter 'F' `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 0
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                    Assert-MockCalled -CommandName Set-Volume -Times 1
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe 'MSFT_xDisk\Test-TargetResource' {
            Mock `
                -CommandName Get-CimInstance `
                -MockWith { $global:mockedWmi }

            Context 'Test disk not initialized' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0Offline } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-WmiObject
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'calling test should not throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskNumber $global:mockedDisk0Offline.Number `
                            -DriveLetter $global:mockedVolume.DriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test disk read only' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0Readonly } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-WmiObject
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'calling test should not throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskNumber $global:mockedDisk0Readonly.Number `
                            -DriveLetter $global:mockedVolume.DriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test online unformatted disk' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0Raw } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-Partition
                Mock -CommandName Get-WmiObject
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'calling test should not throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskNumber $global:mockedDisk0Raw.Number `
                            -DriveLetter $global:mockedVolume.DriveLetter `
                            -AllocationUnitSize 4096 `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                }
            }

            Context 'Test mismatching partition size' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $global:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $global:mockedWmi } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-WmiObject

                $script:result = $null

                It 'calling test should not throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskNumber $global:mockedDisk0.Number `
                            -DriveLetter $global:mockedVolume.DriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size 124 `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be true' {
                    $script:result | Should be $true
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test mismatched AllocationUnitSize' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $global:mockedWmi } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-WmiObject

                $script:result = $null

                It 'calling test should not throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskNumber $global:mockedDisk0.Number `
                            -DriveLetter $global:mockedVolume.DriveLetter `
                            -AllocationUnitSize 4097 `
                            -Verbose
                    } | Should not throw
                }

                # skipped due to:  https://github.com/PowerShell/xStorage/issues/22
                It 'result should be false' -skip {
                    $script:result | Should be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test mismatching FSFormat' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $global:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $global:mockedWmi } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-WmiObject

                $script:result = $null

                It 'calling test should not throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskNumber $global:mockedDisk0.Number `
                            -DriveLetter $global:mockedVolume.DriveLetter `
                            -FSFormat 'ReFS' `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be true' {
                    $script:result | Should be $true
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test mismatching FSLabel' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $global:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $global:mockedWmi } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-WmiObject

                $script:result = $null

                It 'calling test should not throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskNumber $global:mockedDisk0.Number `
                            -DriveLetter $global:mockedVolume.DriveLetter `
                            -FSLabel 'NewLabel' `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be false' {
                    $script:result | Should be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }

            Context 'Test all disk properties matching' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0 } `
                    -Verifiable

                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable

                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $global:mockedVolume } `
                    -Verifiable

                Mock `
                    -CommandName Get-CimInstance `
                    -MockWith { $global:mockedWmi } `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-WmiObject

                $script:result = $null

                It 'calling test should not throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskNumber $global:mockedDisk0.Number `
                            -DriveLetter $global:mockedVolume.DriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size $global:mockedPartition.Size `
                            -FSLabel $global:mockedVolume.FileSystemLabel `
                            -FSFormat $global:mockedVolume.FileSystem `
                            -Verbose
                    } | Should not throw
                }

                It 'result should be true' {
                    $script:result | Should be $true
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1
                }
            }
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
