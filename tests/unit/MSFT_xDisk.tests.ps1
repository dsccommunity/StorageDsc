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

        #region Pester Test Initialization
        $global:mockedDisk0 = [pscustomobject] @{
                Number = 0
                DiskNumber = 0
                IsOffline = $false
                IsReadOnly = $false
                PartitionStyle = 'GPT'
            }

        $global:mockedDisk0Offline = [pscustomobject] @{
                Number = 0
                DiskNumber = 0
                IsOffline = $true
                IsReadOnly = $false
                PartitionStyle = 'GPT'
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

        $global:mockedVolumeReFS = [pscustomobject] @{
                FileSystemLabel = 'myLabel'
                DriveLetter = 'F'
                FileSystem = 'ReFS'
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

            $resource = Get-TargetResource -DiskNumber 0 -DriveLetter 'G' -Verbose
            It 'DiskNumber should be 0' {
                $resource.DiskNumber | should be 0
            }

            It 'DriveLetter should be F' {
                $resource.DriveLetter | should be 'F'
            }

            It 'Size should be 123' {
                $resource.Size | should be 123
            }

            It 'FSLabel should be myLabel' {
                $resource.FSLabel | should be 'myLabel'
            }

            It 'AllocationUnitSize should be 4096' {
                $resource.AllocationUnitSize | should be 4096
            }

            It 'FSFormat should be NTFS' {
                $resource.FSFormat | should be 'NTFS'
            }

            It 'all the get mocks should be called' {
                Assert-VerifiableMocks
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_xDisk\Set-TargetResource' {
            Context 'Online Formatted disk' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0Raw } `
                    -Verifiable
                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable
                Mock `
                    -CommandName Set-Partition `
                    -ParameterFilter { $DriveLetter -eq 'F' -and $NewDriveLetter -eq 'G' } `
                    -Verifiable
                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $global:mockedVolume } `
                    -Verifiable
                Mock `
                    -CommandName Initialize-Disk `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-WmiObject
                Mock -CommandName Get-CimInstance
                Mock -CommandName Set-Disk
                Mock -CommandName Format-Volume
                Mock -CommandName New-Partition

                It 'Should not throw' {
                    {
                        Set-targetResource -diskNumber 0 -driveletter G -Verbose
                    } | should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Set-Partition -Times 1 `
                        -ParameterFilter { $DriveLetter -eq 'F' -and $NewDriveLetter -eq 'G' }
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 2
                    Assert-MockCalled -CommandName Get-Partition -Times 2
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 1
                }
            }

            Context 'Online Formatted disk No Drive Letter' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0Raw } `
                    -Verifiable
                Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition } `
                    -Verifiable
                Mock `
                    -CommandName Set-Partition `
                    -ParameterFilter { $DiskNumber -eq '0' -and $NewDriveLetter -eq 'G' } `
                    -Verifiable
                Mock `
                    -CommandName Get-Volume `
                    -MockWith { $global:mockedVolumeNoLetter } `
                    -Verifiable
                Mock `
                    -CommandName Initialize-Disk `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Get-WmiObject
                Mock -CommandName Get-CimInstance
                Mock -CommandName Set-Disk
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume

                It 'Should not throw' {
                    {
                        Set-targetResource -diskNumber 0 -driveletter G -Verbose
                    } | should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Set-Partition -Times 1 `
                        -ParameterFilter { $DiskNumber -eq '0' -and $NewDriveLetter -eq 'G' }
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 2
                    Assert-MockCalled -CommandName Get-Partition -Times 2
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                    Assert-MockCalled -CommandName New-Partition -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 1
                }
            }

            Context 'Online Unformatted disk' {
                 # verifiable (should be called) mocks
                 Mock `
                    -CommandName Get-Partition `
                    -MockWith { $global:mockedPartition} `
                    -Verifiable
                 Mock `
                    -CommandName Format-Volume `
                    -Verifiable
                 Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0Raw } `
                    -Verifiable
                 Mock `
                    -CommandName Initialize-Disk `
                    -Verifiable
                 Mock `
                    -CommandName New-Partition `
                    -MockWith { [pscustomobject] @{DriveLetter='Z'} } `
                    -Verifiable
                 Mock `
                    -CommandName Get-Volume `
                    -Verifiable

                 # mocks that should not be called
                 Mock Get-WmiObject
                 Mock Get-CimInstance
                 Mock Set-Disk
                 Mock Set-Partition

                It 'Should not throw' {
                    {
                         Set-targetResource -diskNumber 0 -driveletter G -Verbose
                    } | should not throw
                 }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 1
                    Assert-MockCalled -CommandName Format-Volume -Times 1
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                }
            }

            Context 'Set changed FSLabel' {
                # verifiable (should be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $global:mockedDisk0Raw } `
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
                    -ParameterFilter { $NewFileSystemLabel -eq 'NewLabel' } `
                    -Verifiable
                Mock `
                    -CommandName Initialize-Disk `
                    -Verifiable

                # mocks that should not be called
                Mock -CommandName Set-Partition
                Mock -CommandName Get-WmiObject
                Mock -CommandName Get-CimInstance
                Mock -CommandName Set-Disk
                Mock -CommandName New-Partition
                Mock -CommandName Format-Volume

                It 'Should not throw' {
                    {
                        Set-targetResource -diskNumber 0 -driveletter F -FsLabel 'NewLabel' -Verbose
                    } | should not throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Set-Volume -Times 1 `
                        -ParameterFilter { $NewFileSystemLabel -eq 'NewLabel' }
                    Assert-MockCalled -CommandName Set-Partition -Times 0
                    Assert-MockCalled -CommandName Format-Volume -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 2
                    Assert-MockCalled -CommandName Get-Partition -Times 2
                    Assert-MockCalled -CommandName Set-Disk -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Initialize-Disk -Times 1
                    Assert-MockCalled -CommandName New-Partition -Times 0
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
                    } | should not throw
                }

                It 'result should be false' {
                    $script:result | should be $false
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
                    } | should not throw
                }

                It 'result should be false' {
                    $script:result | should be $false
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
                    } | should not throw
                }

                It 'result should be false' {
                    $script:result | should be $false
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

                # mocks that should not be called
                Mock -CommandName Get-Volume
                Mock -CommandName Get-WmiObject
                Mock -CommandName Get-CimInstance

                $script:result = $null

                It 'calling test should not throw' {
                    {
                        $script:result = Test-TargetResource `
                            -DiskNumber $global:mockedDisk0.Number `
                            -DriveLetter $global:mockedVolume.DriveLetter `
                            -AllocationUnitSize 4096 `
                            -Size 124 `
                            -Verbose
                    } | should not throw
                }

                It 'result should be false' {
                    $script:result | should be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -Times 1
                    Assert-MockCalled -CommandName Get-Partition -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 0
                    Assert-MockCalled -CommandName Get-WmiObject -Times 0
                    Assert-MockCalled -CommandName Get-CimInstance -Times 0
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
                    } | should not throw
                }

                # skipped due to:  https://github.com/PowerShell/xStorage/issues/22
                It 'result should be false' -skip {
                    $script:result | should be $false
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
                    } | should not throw
                }

                It 'result should be false' {
                    $script:result | should be $false
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
                    } | should not throw
                }

                It 'result should be false' {
                    $script:result | should be $false
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
                    } | should not throw
                }

                It 'result should be true' {
                    $script:result | should be $true
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
