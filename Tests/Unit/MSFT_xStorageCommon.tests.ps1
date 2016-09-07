$script:DSCModuleName      = 'xStorage'
$script:DSCResourceName    = 'MSFT_xStorageCommon'

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

    $LocalizedData = InModuleScope $script:DSCResourceName {
        $LocalizedData
    }

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

    function Get-InvalidArgumentError
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

        $exception = New-Object -TypeName System.ArgumentException `
            -ArgumentList $ErrorMessage
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $ErrorId, $errorCategory, $null
        return $errorRecord
    } # end function Get-InvalidArgumentError

    #region Pester Test Initialization
    $driveLetterGood = 'C'
    $driveLetterGoodwithColon = 'C:'
    $driveLetterBad = '1'
    $driveLetterBadColon = ':C'
    $driveLetterBadTooLong = 'FE:'
    #endregion

    #region Function Test-DriveLetter
    Describe "MSFT_xStorageCommon\Test-DriveLetter" {
        Context 'drive letter is good, has no colon and colon is not required' {
            It "should return '$driveLetterGood'" {
                Test-DriveLetter -DriveLetter $driveLetterGood | Should Be $driveLetterGood
            }
        }

        Context 'drive letter is good, has no colon but colon is required' {
            It "should return '$driveLetterGoodwithColon'" {
                Test-DriveLetter -DriveLetter $driveLetterGood -Colon | Should Be $driveLetterGoodwithColon
            }
        }

        Context 'drive letter is good, has a colon but colon is not required' {
            It "should return '$driveLetterGood'" {
                Test-DriveLetter -DriveLetter $driveLetterGoodwithColon | Should Be $driveLetterGood
            }
        }

        Context 'drive letter is good, has a colon and colon is required' {
            It "should return '$driveLetterGoodwithColon'" {
                Test-DriveLetter -DriveLetter $driveLetterGoodwithColon -Colon | Should Be $driveLetterGoodwithColon
            }
        }

        Context 'drive letter is non alpha' {
            $errorRecord = Get-InvalidArgumentError `
                -ErrorId 'InvalidDriveLetterFormatError' `
                -ErrorMessage $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBad)

            It 'should throw InvalidDriveLetterFormatError' {
                { Test-DriveLetter -DriveLetter $driveLetterBad } | Should Throw $errorRecord
            }
        }

        Context 'drive letter has a bad colon location' {
            $errorRecord = Get-InvalidArgumentError `
                -ErrorId 'InvalidDriveLetterFormatError' `
                -ErrorMessage $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBadColon)

            It 'should throw InvalidDriveLetterFormatError' {
                { Test-DriveLetter -DriveLetter $driveLetterBadColon } | Should Throw $errorRecord
            }
        }

        Context 'drive letter is too long' {
            $errorRecord = Get-InvalidArgumentError `
                -ErrorId 'InvalidDriveLetterFormatError' `
                -ErrorMessage $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBadTooLong)

            It 'should throw InvalidDriveLetterFormatError' {
                { Test-DriveLetter -DriveLetter $driveLetterBadTooLong } | Should Throw $errorRecord
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion

}