$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xWaitForDisk'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xStorage'
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
        $script:testDiskUniqueId = 'TESTDISKUNIQUEID'

        $mockedDisk0 = [pscustomobject] @{
            Number = 0
            UniqueId = $script:testDiskUniqueId
            FriendlyName = 'Test Disk'
        }

        $disk0ParametersByNumber = @{
            DiskId = 0
            RetryIntervalSec = 5
            RetryCount = 20
        }

        $disk0ParametersByUniqueId = @{
            DiskId = $script:testDiskUniqueId
            DiskIdType = 'UniqueId'
            RetryIntervalSec = 5
            RetryCount = 20
        }
        #endregion

        #region Function Get-TargetResource
        Describe "MSFT_xWaitForDisk\Get-TargetResource" {
            Context 'disk is specified by Number' {
                $script:result = $null

                It 'Should Not Throw' {
                    {
                        $script:result = Get-TargetResource @disk0ParametersByNumber -Verbose
                    } | Should Not Throw
                }

                It "should return a DiskId of $($disk0ParametersByNumber.DiskId)" {
                    $script:result.DiskId | Should Be $disk0ParametersByNumber.DiskId
                }

                It "should return a DiskIdType of Number" {
                    $script:result.DiskIdType | Should Be 'Number'
                }

                It "should return a RetryIntervalSec of $($disk0ParametersByNumber.RetryIntervalSec)" {
                    $script:result.RetryIntervalSec | Should Be $disk0ParametersByNumber.RetryIntervalSec
                }

                It "should return a RetryIntervalSec of $($disk0ParametersByNumber.RetryCount)" {
                    $script:result.RetryCount | Should Be $disk0ParametersByNumber.RetryCount
                }
            }

            Context 'disk is specified by Unique Id' {
                $script:result = $null

                It 'Should Not Throw' {
                    {
                        $script:result = Get-TargetResource @disk0ParametersByUniqueId -Verbose
                    } | Should Not Throw
                }

                It "should return a DiskId of $($disk0ParametersByUniqueId.DiskId)" {
                    $script:result.DiskId | Should Be $disk0ParametersByUniqueId.DiskId
                }

                It "should return a DiskIdType of UniqueId" {
                    $script:result.DiskIdType | Should Be 'UniqueId'
                }

                It "should return a RetryIntervalSec of $($disk0ParametersByUniqueId.RetryIntervalSec)" {
                    $script:result.RetryIntervalSec | Should Be $disk0ParametersByUniqueId.RetryIntervalSec
                }

                It "should return a RetryIntervalSec of $($disk0ParametersByUniqueId.RetryCount)" {
                    $script:result.RetryCount | Should Be $disk0ParametersByUniqueId.RetryCount
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_xWaitForDisk\Set-TargetResource' {
            Mock -CommandName Start-Sleep

            Context 'disk number 0 is ready' {
                # verifiable (Should Be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -ParameterFilter { $Number[0] -eq 0 } `
                    -MockWith { return $mockedDisk0 } `
                    -Verifiable

                It 'Should Not Throw' {
                    { Set-targetResource @disk0ParametersByNumber -Verbose } | Should Not throw
                }

                It 'should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Start-Sleep -Times 0
                    Assert-MockCalled -CommandName Get-Disk -ParameterFilter { $Number[0] -eq 0 } -Times 1
                }
            }

            Context "disk with unique id '$script:testDiskUniqueId' is ready" {
                # verifiable (Should Be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -ParameterFilter { $UniqueId -eq $script:testDiskUniqueId } `
                    -MockWith { return $mockedDisk0 } `
                    -Verifiable

                It 'Should Not Throw' {
                    { Set-targetResource @disk0ParametersByUniqueId -Verbose } | Should Not throw
                }

                It 'should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Start-Sleep -Times 0
                    Assert-MockCalled -CommandName Get-Disk -ParameterFilter { $UniqueId -eq $script:testDiskUniqueId } -Times 1
                }
            }

            Context 'disk number 0 does not become ready' {
                # verifiable (Should Be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -ParameterFilter { $Number[0] -eq 0 } `
                    -MockWith { } `
                    -Verifiable

                $errorRecord = Get-InvalidOperationRecord `
                    -Message $($LocalizedData.DiskNotFoundAfterError `
                        -f 'Number',$disk0ParametersByNumber.DiskId,$disk0ParametersByNumber.RetryCount)

                It 'should throw DiskNotFoundAfterError' {
                    { Set-targetResource @disk0ParametersByNumber -Verbose } | Should Throw $errorRecord
                }

                It 'should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Start-Sleep -Times $disk0ParametersByNumber.RetryCount
                    Assert-MockCalled -CommandName Get-Disk -ParameterFilter { $Number[0] -eq 0 } -Times 1
                }
            }

            Context "disk with unique id '$script:testDiskUniqueId' does not become ready" {
                # verifiable (Should Be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -ParameterFilter { $UniqueId -eq $script:testDiskUniqueId } `
                    -MockWith { } `
                    -Verifiable

                $errorRecord = Get-InvalidOperationRecord `
                    -Message $($LocalizedData.DiskNotFoundAfterError `
                        -f 'UniqueId',$disk0ParametersByUniqueId.DiskId,$disk0ParametersByUniqueId.RetryCount)

                It 'should throw DiskNotFoundAfterError' {
                    { Set-targetResource @disk0ParametersByUniqueId -Verbose } | Should Throw $errorRecord
                }

                It 'should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Start-Sleep -Times $disk0ParametersByUniqueId.RetryCount
                    Assert-MockCalled -CommandName Get-Disk -ParameterFilter { $UniqueId -eq $script:testDiskUniqueId } -Times 1
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe 'MSFT_xWaitForDisk\Test-TargetResource' {
            Context 'disk number 0 is ready' {
                # verifiable (Should Be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -ParameterFilter { $Number[0] -eq 0 } `
                    -MockWith { return $mockedDisk0 } `
                    -Verifiable

                $script:result = $null

                It 'Should Not Throw' {
                    {
                        $script:result = Test-TargetResource @disk0ParametersByNumber -Verbose
                    } | Should Not Throw
                }

                It "should return a result of true" {
                    $script:result | Should Be $true
                }

                It 'should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -ParameterFilter { $Number[0] -eq 0 } -Times 1
                }
            }

            Context "disk with unique id '$script:testDiskUniqueId' is ready" {
                # verifiable (Should Be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -ParameterFilter { $UniqueId -eq $script:testDiskUniqueId } `
                    -MockWith { return $mockedDisk0 } `
                    -Verifiable

                $script:result = $null

                It 'Should Not Throw' {
                    {
                        $script:result = Test-TargetResource @disk0ParametersByUniqueId -Verbose
                    } | Should Not Throw
                }

                It "should return a result of true" {
                    $script:result | Should Be $true
                }

                It 'should call the correct mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -ParameterFilter { $UniqueId -eq $script:testDiskUniqueId } -Times 1
                }
            }

            Context 'disk number 0 does not become ready' {
                # verifiable (Should Be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -ParameterFilter { $Number[0] -eq 0 } `
                    -MockWith { } `
                    -Verifiable

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource @disk0ParametersByNumber -Verbose
                    } | Should Not Throw
                }

                It 'result Should Be false' {
                    $script:result | Should Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -ParameterFilter { $Number[0] -eq 0 } -Times 1
                }
            }

            Context "disk with unique id '$script:testDiskUniqueId' does not become ready" {
                # verifiable (Should Be called) mocks
                Mock `
                    -CommandName Get-Disk `
                    -ParameterFilter { $UniqueId -eq $script:testDiskUniqueId } `
                    -MockWith { } `
                    -Verifiable

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource @disk0ParametersByUniqueId -Verbose
                    } | Should Not Throw
                }

                It 'result Should Be false' {
                    $script:result | Should Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Get-Disk -ParameterFilter { $UniqueId -eq $script:testDiskUniqueId } -Times 1
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
