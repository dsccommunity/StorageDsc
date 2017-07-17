$script:ModuleName = 'StorageDsc.Common'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1')

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xStorage'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath $script:ModuleName)) -ChildPath "$script:ModuleName.psm1") -Force
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    $LocalizedData = InModuleScope $script:ModuleName {
        $LocalizedData
    }

    #region Pester Test Initialization
    $driveLetterGood = 'C'
    $driveLetterGoodwithColon = 'C:'
    $driveLetterBad = '1'
    $driveLetterBadColon = ':C'
    $driveLetterBadTooLong = 'FE:'

    $accessPathGood = 'c:\Good'
    $accessPathGoodWithSlash = 'c:\Good\'
    $accessPathBad = 'c:\Bad'

    #region Functions To Mock
    function Get-Disk
    {
        [CmdletBinding()]
        Param
        (
            [System.UInt32]
            $Number,

            [System.String]
            $UniqueId
        )
    }
    #endregion

    #region Function Assert-DriveLetterValid
    Describe 'StorageDsc.Common\Assert-DriveLetterValid' {
        Context 'Drive letter is good, has no colon and colon is not required' {
            It "Should return '$driveLetterGood'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGood | Should Be $driveLetterGood
            }
        }

        Context 'Drive letter is good, has no colon but colon is required' {
            It "Should return '$driveLetterGoodwithColon'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGood -Colon | Should Be $driveLetterGoodwithColon
            }
        }

        Context 'Drive letter is good, has a colon but colon is not required' {
            It "Should return '$driveLetterGood'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGoodwithColon | Should Be $driveLetterGood
            }
        }

        Context 'Drive letter is good, has a colon and colon is required' {
            It "Should return '$driveLetterGoodwithColon'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGoodwithColon -Colon | Should Be $driveLetterGoodwithColon
            }
        }

        Context 'Drive letter is non alpha' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBad) `
                -ArgumentName 'DriveLetter'

            It 'Should throw InvalidDriveLetterFormatError' {
                { Assert-DriveLetterValid -DriveLetter $driveLetterBad } | Should Throw $errorRecord
            }
        }

        Context 'Drive letter has a bad colon location' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBadColon) `
                -ArgumentName 'DriveLetter'

            It 'Should throw InvalidDriveLetterFormatError' {
                { Assert-DriveLetterValid -DriveLetter $driveLetterBadColon } | Should Throw $errorRecord
            }
        }

        Context 'Drive letter is too long' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBadTooLong) `
                -ArgumentName 'DriveLetter'

            It 'Should throw InvalidDriveLetterFormatError' {
                { Assert-DriveLetterValid -DriveLetter $driveLetterBadTooLong } | Should Throw $errorRecord
            }
        }
    }
    #endregion

    #region Function Assert-AccessPathValid
    Describe "StorageDsc.Common\Assert-AccessPathValid" {
        Mock `
            -CommandName Test-Path `
            -ModuleName StorageDsc.Common `
            -MockWith { $true }

        Context 'Path is found, trailing slash included, not required' {
            It "Should return '$accessPathGood'" {
                Assert-AccessPathValid -AccessPath $accessPathGoodWithSlash | Should Be $accessPathGood
            }
        }

        Context 'Path is found, trailing slash included, required' {
            It "Should return '$accessPathGoodWithSlash'" {
                Assert-AccessPathValid -AccessPath $accessPathGoodWithSlash -Slash | Should Be $accessPathGoodWithSlash
            }
        }

        Context 'Path is found, trailing slash not included, required' {
            It "Should return '$accessPathGoodWithSlash'" {
                Assert-AccessPathValid -AccessPath $accessPathGood -Slash | Should Be $accessPathGoodWithSlash
            }
        }

        Context 'Path is found, trailing slash not included, not required' {
            It "Should return '$accessPathGood'" {
                Assert-AccessPathValid -AccessPath $accessPathGood | Should Be $accessPathGood
            }
        }

        Mock `
            -CommandName Test-Path `
            -ModuleName StorageDsc.Common `
            -MockWith { $false }

        Context 'Drive is not found' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message $($LocalizedData.InvalidAccessPathError -f $accessPathBad) `
                -ArgumentName 'AccessPath'

            It 'Should throw InvalidAccessPathError' {
                { Assert-AccessPathValid `
                        -AccessPath $accessPathBad } | Should Throw $errorRecord
            }
        }
    }
    #endregion

    #region Function Get-DiskByIdentifier
    InModuleScope $script:ModuleName {
        $testDiskNumber = 10
        $testDiskUniqueId = 'DiskUniqueId'
        $testDiskGuid = [Guid]::NewGuid().ToString()

        $mockedDisk = [pscustomobject] @{
            Number   = $testDiskNumber
            UniqueId = $testDiskUniqueId
            Guid     = $testDiskGuid
        }

        Describe 'StorageDsc.Common\Get-DiskByIdentifier' {
            Context 'Disk exists that matches the specified Disk Number' {
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $mockedDisk } `
                    -ModuleName StorageDsc.Common `
                    -ParameterFilter { $Number -eq $testDiskNumber } `
                    -Verifiable

                It "Should return Disk with Disk Number $testDiskNumber" {
                    (Get-DiskByIdentifier -DiskId $testDiskNumber).Number | Should Be $testDiskNumber
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled `
                        -CommandName Get-Disk `
                        -ModuleName StorageDsc.Common `
                        -ParameterFilter { $Number -eq $testDiskNumber } `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'Disk does not exist that matches the specified Disk Number' {
                Mock `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -ParameterFilter { $Number -eq $testDiskNumber } `
                    -Verifiable

                It "Should return Disk with Disk Number $testDiskNumber" {
                    Get-DiskByIdentifier -DiskId $testDiskNumber | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled `
                        -CommandName Get-Disk `
                        -ModuleName StorageDsc.Common `
                        -ParameterFilter { $Number -eq $testDiskNumber } `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'Disk exists that matches the specified Disk Unique Id' {
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $mockedDisk } `
                    -ModuleName StorageDsc.Common `
                    -ParameterFilter { $UniqueId -eq $testDiskUniqueId } `
                    -Verifiable

                It "Should return Disk with Disk Unique Id $testDiskUniqueId" {
                    (Get-DiskByIdentifier -DiskId $testDiskUniqueId -DiskIdType 'UniqueId').UniqueId | Should Be $testDiskUniqueId
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled `
                        -CommandName Get-Disk `
                        -ModuleName StorageDsc.Common `
                        -ParameterFilter { $UniqueId -eq $testDiskUniqueId } `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'Disk does not exist that matches the specified Disk Unique Id' {
                Mock `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -ParameterFilter { $UniqueId -eq $testDiskUniqueId } `
                    -Verifiable

                It "Should return Disk with Disk Unique Id $testDiskUniqueId" {
                    Get-DiskByIdentifier -DiskId $testDiskUniqueId -DiskIdType 'UniqueId' | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled `
                        -CommandName Get-Disk `
                        -ModuleName StorageDsc.Common `
                        -ParameterFilter { $UniqueId -eq $testDiskUniqueId } `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'Disk exists that matches the specified Disk Guid' {
                Mock `
                    -CommandName Get-Disk `
                    -MockWith { $mockedDisk } `
                    -ModuleName StorageDsc.Common `
                    -Verifiable

                It "Should return Disk with Disk Guid $testDiskGuid" {
                    (Get-DiskByIdentifier -DiskId $testDiskGuid -DiskIdType 'Guid').Guid | Should Be $testDiskGuid
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled `
                        -CommandName Get-Disk `
                        -ModuleName StorageDsc.Common `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'Disk does not exist that matches the specified Disk Guid' {
                Mock `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -Verifiable

                It "Should return Disk with Disk Guid $testDiskGuid" {
                    Get-DiskByIdentifier -DiskId $testDiskGuid -DiskIdType 'Guid' | Should BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-VerifiableMocks
                    Assert-MockCalled `
                        -CommandName Get-Disk `
                        -ModuleName StorageDsc.Common `
                        -Exactly `
                        -Times 1
                }
            }
        }
        #endregion Function Get-DiskByIdentifier
    }
    #endregion Pester Tests
}
finally
{
    #region FOOTER
    #endregion
}
