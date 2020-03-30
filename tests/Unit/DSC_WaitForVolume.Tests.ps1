$script:dscModuleName = 'StorageDsc'
$script:dscResourceName = 'DSC_WaitForVolume'

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
        $mockedDriveC = [pscustomobject] @{
            DriveLetter      = 'C'
        }
        $driveCParameters = @{
            DriveLetter      = 'C'
            RetryIntervalSec = 5
            RetryCount       = 20
        }

        Describe "MSFT_WaitForVolume\Get-TargetResource" {
            $resource = Get-TargetResource @driveCParameters -Verbose
            It "DriveLetter Should Be $($driveCParameters.DriveLetter)" {
                $resource.DriveLetter | Should -Be $driveCParameters.DriveLetter
            }

            It "RetryIntervalSec Should Be $($driveCParameters.RetryIntervalSec)" {
                $resource.RetryIntervalSec | Should -Be $driveCParameters.RetryIntervalSec
            }

            It "RetryIntervalSec Should Be $($driveCParameters.RetryCount)" {
                $resource.RetryCount | Should -Be $driveCParameters.RetryCount
            }

            It 'the correct mocks were called' {
                Assert-VerifiableMock
            }
        }

        Describe 'MSFT_WaitForVolume\Set-TargetResource' {
            Mock Start-Sleep
            Mock Get-PSDrive

            Context 'drive C is ready' {
                Mock Get-Volume -MockWith { return $mockedDriveC } -Verifiable

                It 'Should not throw an exception' {
                    { Set-targetResource @driveCParameters -Verbose } | Should -Not -Throw
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Start-Sleep -Times 0
                    Assert-MockCalled -CommandName Get-PSDrive -Times 0
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                }
            }
            Context 'drive C does not become ready' {
                Mock Get-Volume -MockWith { } -Verifiable

                $errorRecord = Get-InvalidOperationRecord `
                    -Message $($LocalizedData.VolumeNotFoundAfterError `
                        -f $driveCParameters.DriveLetter,$driveCParameters.RetryCount)

                It 'should throw VolumeNotFoundAfterError' {
                    { Set-targetResource @driveCParameters -Verbose } | Should -Throw $errorRecord
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Start-Sleep -Times $driveCParameters.RetryCount
                    Assert-MockCalled -CommandName Get-PSDrive -Times $driveCParameters.RetryCount
                    Assert-MockCalled -CommandName Get-Volume -Times $driveCParameters.RetryCount
                }
            }
        }

        Describe 'MSFT_WaitForVolume\Test-TargetResource' {
            Mock Get-PSDrive

            Context 'drive C is ready' {
                Mock Get-Volume -MockWith { return $mockedDriveC } -Verifiable

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource @driveCParameters -Verbose
                    } | Should -Not -Throw
                }

                It "result Should Be true" {
                    $script:result | Should -Be $true
                }

                It "the correct mocks were called" {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-PSDrive -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
                }
            }
            Context 'drive C is not ready' {
                Mock Get-Volume -MockWith { } -Verifiable

                $script:result = $null

                It 'calling test Should Not Throw' {
                    {
                        $script:result = Test-TargetResource @driveCParameters -Verbose
                    } | Should -Not -Throw
                }

                It 'result Should Be false' {
                    $script:result | Should -Be $false
                }

                It 'the correct mocks were called' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-PSDrive -Times 1
                    Assert-MockCalled -CommandName Get-Volume -Times 1
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
