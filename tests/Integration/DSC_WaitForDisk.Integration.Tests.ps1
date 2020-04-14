$script:dscModuleName = 'StorageDsc'
$script:dscResourceName = 'DSC_WaitForDisk'

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
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile -Verbose -ErrorAction Stop

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            # Create a VHD and attach it to the computer
            $VHDPath = Join-Path -Path $TestDrive `
                -ChildPath 'TestDisk.vhd'
            $null = New-VDisk -Path $VHDPath -SizeInMB 1024 -Initialize
            $null = Mount-DiskImage -ImagePath $VHDPath -StorageType VHD -NoDriveLetter
            $diskImage = Get-DiskImage -ImagePath $VHDPath
            $disk = Get-Disk -Number $diskImage.Number
        }

        Context 'Wait for a Disk using Disk Number' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName         = 'localhost'
                                DiskId           = $disk.Number
                                DiskIdType       = 'Number'
                                RetryIntervalSec = 1
                                RetryCount       = 5
                            }
                        )
                    }

                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.DiskId           | Should -Be $disk.Number
                $current.RetryIntervalSec | Should -Be 1
                $current.RetryCount       | Should -Be 5
                $current.IsAvailable      | Should -Be $true
            }
        }

        Context 'Wait for a Disk using Disk Unique Id' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName         = 'localhost'
                                DiskId           = $disk.UniqueId
                                DiskIdType       = 'UniqueId'
                                RetryIntervalSec = 1
                                RetryCount       = 5
                            }
                        )
                    }

                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.DiskId           | Should -Be $disk.UniqueId
                $current.RetryIntervalSec | Should -Be 1
                $current.RetryCount       | Should -Be 5
                $current.IsAvailable      | Should -Be $true
            }
        }

        Context 'Wait for a Disk using Disk Guid' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    # This is to pass to the Config
                    $configData = @{
                        AllNodes = @(
                            @{
                                NodeName         = 'localhost'
                                DiskId           = $disk.Guid
                                DiskIdType       = 'Guid'
                                RetryIntervalSec = 1
                                RetryCount       = 5
                            }
                        )
                    }

                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
                    Start-DscConfiguration -Path $TestDrive -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration | Where-Object {
                    $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                }
                $current.DiskId           | Should -Be $disk.Guid
                $current.RetryIntervalSec | Should -Be 1
                $current.RetryCount       | Should -Be 5
                $current.IsAvailable      | Should -Be $true
            }
        }

        AfterAll {
            Dismount-DiskImage -ImagePath $VHDPath -StorageType VHD
            Remove-Item -Path $VHDPath -Force
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
