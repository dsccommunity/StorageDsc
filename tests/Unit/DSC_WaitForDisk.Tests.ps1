$script:dscModuleName = 'StorageDsc'
$script:dscResourceName = 'DSC_WaitForDisk'

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
        $testDiskNumber = 1
        $testDiskUniqueId = 'TESTDISKUNIQUEID'
        $testDiskGptGuid = [guid]::NewGuid()

        $mockedDisk0 = [pscustomobject] @{
            Number       = $testDiskNumber
            UniqueId     = $testDiskUniqueId
            Guid         = $testDiskGptGuid
            FriendlyName = 'Test Disk'
        }

        $disk0ParametersByNumber = @{
            DiskId           = $testDiskNumber
            DiskIdType       = 'Number'
            RetryIntervalSec = 5
            RetryCount       = 20
        }

        $disk0ParametersByUniqueId = @{
            DiskId           = $testDiskUniqueId
            DiskIdType       = 'UniqueId'
            RetryIntervalSec = 5
            RetryCount       = 20
        }

        $disk0ParametersByGptGuid = @{
            DiskId           = $testDiskGptGuid
            DiskIdType       = 'Guid'
            RetryIntervalSec = 5
            RetryCount       = 20
        }

        Describe 'DSC_WaitForDisk\Get-TargetResource' {

            Mock `
            -CommandName Test-TargetResource `
            -MockWith { return $true } `
            -Verifiable

            Context 'Disk is specified by Number' {
                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource @disk0ParametersByNumber -Verbose
                    } | Should -Not -Throw
                }

                It "Should return a DiskId of $($disk0ParametersByNumber.DiskId)" {
                    $script:result.DiskId | Should -Be $disk0ParametersByNumber.DiskId
                }

                It 'Should return a DiskIdType of Number' {
                    $script:result.DiskIdType | Should -Be 'Number'
                }

                It "Should return a RetryIntervalSec of $($disk0ParametersByNumber.RetryIntervalSec)" {
                    $script:result.RetryIntervalSec | Should -Be $disk0ParametersByNumber.RetryIntervalSec
                }

                It "Should return a RetryIntervalSec of $($disk0ParametersByNumber.RetryCount)" {
                    $script:result.RetryCount | Should -Be $disk0ParametersByNumber.RetryCount
                }

                It "Should return a IsAvailable of true" {
                    $script:result.IsAvailable | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1
                }
            }

            Context 'Disk is specified by Unique Id' {
                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource @disk0ParametersByUniqueId -Verbose
                    } | Should -Not -Throw
                }

                It "Should return a DiskId of $($disk0ParametersByUniqueId.DiskId)" {
                    $script:result.DiskId | Should -Be $disk0ParametersByUniqueId.DiskId
                }

                It "Should return a DiskIdType of UniqueId" {
                    $script:result.DiskIdType | Should -Be 'UniqueId'
                }

                It "Should return a RetryIntervalSec of $($disk0ParametersByUniqueId.RetryIntervalSec)" {
                    $script:result.RetryIntervalSec | Should -Be $disk0ParametersByUniqueId.RetryIntervalSec
                }

                It "Should return a RetryIntervalSec of $($disk0ParametersByUniqueId.RetryCount)" {
                    $script:result.RetryCount | Should -Be $disk0ParametersByUniqueId.RetryCount
                }

                It "Should return a IsAvailable of true" {
                    $script:result.IsAvailable | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1
                }
            }

            Context 'Disk is specified by Guid' {
                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Get-TargetResource @disk0ParametersByGptGuid -Verbose
                    } | Should -Not -Throw
                }

                It "Should return a DiskId of $($disk0ParametersByGptGuid.DiskId)" {
                    $script:result.DiskId | Should -Be $disk0ParametersByGptGuid.DiskId
                }

                It "Should return a DiskIdType of Guid" {
                    $script:result.DiskIdType | Should -Be 'Guid'
                }

                It "Should return a RetryIntervalSec of $($disk0ParametersByGptGuid.RetryIntervalSec)" {
                    $script:result.RetryIntervalSec | Should -Be $disk0ParametersByGptGuid.RetryIntervalSec
                }

                It "Should return a RetryIntervalSec of $($disk0ParametersByGptGuid.RetryCount)" {
                    $script:result.RetryCount | Should -Be $disk0ParametersByGptGuid.RetryCount
                }

                It "Should return a IsAvailable of true" {
                    $script:result.IsAvailable | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Test-TargetResource -Exactly -Times 1
                }
            }
        }

        Describe 'DSC_WaitForDisk\Set-TargetResource' {
            Mock -CommandName Start-Sleep

            Context "Disk Number $testDiskNumber is ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByNumber.DiskId -and $DiskIdType -eq 'Number' } `
                    -MockWith { return $mockedDisk0 } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-targetResource @disk0ParametersByNumber -Verbose } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByNumber.DiskId -and $DiskIdType -eq 'Number' }
                }
            }

            Context "Disk with Unique Id '$testDiskUniqueId' is ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByUniqueId.DiskId -and $DiskIdType -eq 'UniqueId' } `
                    -MockWith { return $mockedDisk0 } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-targetResource @disk0ParametersByUniqueId -Verbose } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByUniqueId.DiskId -and $DiskIdType -eq 'UniqueId' }
                }
            }

            Context "Disk with Guid '$testDiskGptGuid' is ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByGptGuid.DiskId -and $DiskIdType -eq 'Guid' } `
                    -MockWith { return $mockedDisk0 } `
                    -Verifiable

                It 'Should not throw an exception' {
                    { Set-targetResource @disk0ParametersByGptGuid -Verbose } | Should -Not -Throw
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Start-Sleep -Exactly -Times 0
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByGptGuid.DiskId -and $DiskIdType -eq 'Guid' }
                }
            }

            Context "Disk Number $testDiskNumber does not become ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByNumber.DiskId -and $DiskIdType -eq 'Number' } `
                    -MockWith { } `
                    -Verifiable

                $errorRecord = Get-InvalidOperationRecord `
                    -Message $($LocalizedData.DiskNotFoundAfterError `
                        -f 'Number', $disk0ParametersByNumber.DiskId, $disk0ParametersByNumber.RetryCount)

                It 'Should throw DiskNotFoundAfterError' {
                    { Set-targetResource @disk0ParametersByNumber -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Start-Sleep -Exactly -Times $disk0ParametersByNumber.RetryCount
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times $disk0ParametersByNumber.RetryCount `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByNumber.DiskId -and $DiskIdType -eq 'Number' } `
                }
            }

            Context "Disk with Unique Id '$testDiskUniqueId' does not become ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByUniqueId.DiskId -and $DiskIdType -eq 'UniqueId' } `
                    -MockWith { } `
                    -Verifiable

                $errorRecord = Get-InvalidOperationRecord `
                    -Message $($LocalizedData.DiskNotFoundAfterError `
                        -f 'UniqueId', $disk0ParametersByUniqueId.DiskId, $disk0ParametersByUniqueId.RetryCount)

                It 'Should throw DiskNotFoundAfterError' {
                    { Set-targetResource @disk0ParametersByUniqueId -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Start-Sleep -Exactly -Times $disk0ParametersByUniqueId.RetryCount
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times $disk0ParametersByNumber.RetryCount `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByUniqueId.DiskId -and $DiskIdType -eq 'UniqueId' } `
                }
            }

            Context "Disk with Guid '$testDiskGptGuid' does not become ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByGptGuid.DiskId -and $DiskIdType -eq 'Guid' } `
                    -MockWith { } `
                    -Verifiable

                $errorRecord = Get-InvalidOperationRecord `
                    -Message $($LocalizedData.DiskNotFoundAfterError `
                        -f 'Guid', $disk0ParametersByGptGuid.DiskId, $disk0ParametersByGptGuid.RetryCount)

                It 'Should throw DiskNotFoundAfterError' {
                    { Set-targetResource @disk0ParametersByGptGuid -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Start-Sleep -Exactly -Times $disk0ParametersByGptGuid.RetryCount
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times $disk0ParametersByGptGuid.RetryCount `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByGptGuid.DiskId -and $DiskIdType -eq 'Guid' }
                }
            }
        }

        Describe 'DSC_WaitForDisk\Test-TargetResource' {
            Context "Disk Number $testDiskNumber is ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByNumber.DiskId -and $DiskIdType -eq 'Number' } `
                    -MockWith { return $mockedDisk0 } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource @disk0ParametersByNumber -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return a result of true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByNumber.DiskId -and $DiskIdType -eq 'Number' }
                }
            }

            Context "Disk with Unique Id '$testDiskUniqueId' is ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByUniqueId.DiskId -and $DiskIdType -eq 'UniqueId' } `
                    -MockWith { return $mockedDisk0 } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource @disk0ParametersByUniqueId -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return a result of true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByUniqueId.DiskId -and $DiskIdType -eq 'UniqueId' }
                }
            }

            Context "Disk with Guid '$testDiskGptGuid' is ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByGptGuid.DiskId -and $DiskIdType -eq 'Guid' } `
                    -MockWith { return $mockedDisk0 } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource @disk0ParametersByGptGuid -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return a result of true' {
                    $script:result | Should -Be $true
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByGptGuid.DiskId -and $DiskIdType -eq 'Guid' }
                }
            }

            Context "Disk Number $testDiskNumber does not become ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByNumber.DiskId -and $DiskIdType -eq 'Number' } `
                    -MockWith { } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource @disk0ParametersByNumber -Verbose
                    } | Should -Not -Throw
                }

                It 'Result Should Be false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByNumber.DiskId -and $DiskIdType -eq 'Number' }
                }
            }

            Context "Disk with Unique Id '$testDiskUniqueId' does not become ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByUniqueId.DiskId -and $DiskIdType -eq 'UniqueId' } `
                    -MockWith { } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource @disk0ParametersByUniqueId -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByUniqueId.DiskId -and $DiskIdType -eq 'UniqueId' }
                }
            }

            Context "Disk with Guid '$testDiskGptGuid' does not become ready" {
                Mock `
                    -CommandName Get-DiskByIdentifier `
                    -ParameterFilter { $DiskId -eq $disk0ParametersByGptGuid.DiskId -and $DiskIdType -eq 'Guid' } `
                    -MockWith { } `
                    -Verifiable

                $script:result = $null

                It 'Should not throw an exception' {
                    {
                        $script:result = Test-TargetResource @disk0ParametersByGptGuid -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:result | Should -Be $false
                }

                It 'Should call the correct mocks' {
                    Assert-VerifiableMock
                    Assert-MockCalled -CommandName Get-DiskByIdentifier -Exactly -Times 1 `
                        -ParameterFilter { $DiskId -eq $disk0ParametersByGptGuid.DiskId -and $DiskIdType -eq 'Guid' }
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
