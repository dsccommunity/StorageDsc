$script:ModuleName = 'StorageDsc.Common'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1')

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xStorage'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
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
    #endregion

    #region Function Assert-DriveLetterValid
    Describe "StorageDsc.Common\Assert-DriveLetterValid" {
        Context 'drive letter is good, has no colon and colon is not required' {
            It "should return '$driveLetterGood'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGood | Should Be $driveLetterGood
            }
        }

        Context 'drive letter is good, has no colon but colon is required' {
            It "should return '$driveLetterGoodwithColon'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGood -Colon | Should Be $driveLetterGoodwithColon
            }
        }

        Context 'drive letter is good, has a colon but colon is not required' {
            It "should return '$driveLetterGood'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGoodwithColon | Should Be $driveLetterGood
            }
        }

        Context 'drive letter is good, has a colon and colon is required' {
            It "should return '$driveLetterGoodwithColon'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGoodwithColon -Colon | Should Be $driveLetterGoodwithColon
            }
        }

        Context 'drive letter is non alpha' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBad) `
                -ArgumentName 'DriveLetter'

            It 'should throw InvalidDriveLetterFormatError' {
                { Assert-DriveLetterValid -DriveLetter $driveLetterBad } | Should Throw $errorRecord
            }
        }

        Context 'drive letter has a bad colon location' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBadColon) `
                -ArgumentName 'DriveLetter'

            It 'should throw InvalidDriveLetterFormatError' {
                { Assert-DriveLetterValid -DriveLetter $driveLetterBadColon } | Should Throw $errorRecord
            }
        }

        Context 'drive letter is too long' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBadTooLong) `
                -ArgumentName 'DriveLetter'

            It 'should throw InvalidDriveLetterFormatError' {
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
            -MockWith { $True }

        Context 'path is found, trailing slash included, not required' {
            It "should return '$accessPathGood'" {
                Assert-AccessPathValid -AccessPath $accessPathGoodWithSlash | Should Be $accessPathGood
            }
        }

        Context 'path is found, trailing slash included, required' {
            It "should return '$accessPathGoodWithSlash'" {
                Assert-AccessPathValid -AccessPath $accessPathGoodWithSlash -Slash | Should Be $accessPathGoodWithSlash
            }
        }

        Context 'path is found, trailing slash not included, required' {
            It "should return '$accessPathGoodWithSlash'" {
                Assert-AccessPathValid -AccessPath $accessPathGood -Slash | Should Be $accessPathGoodWithSlash
            }
        }

        Context 'path is found, trailing slash not included, not required' {
            It "should return '$accessPathGood'" {
                Assert-AccessPathValid -AccessPath $accessPathGood | Should Be $accessPathGood
            }
        }

        Mock `
            -CommandName Test-Path `
            -ModuleName StorageDsc.Common `
            -MockWith { $False }

        Context 'drive is not found' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message $($LocalizedData.InvalidAccessPathError -f $accessPathBad) `
                -ArgumentName 'AccessPath'

            It 'should throw InvalidAccessPathError' {
                { Assert-AccessPathValid `
                    -AccessPath $accessPathBad } | Should Throw $errorRecord
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    #endregion
}
