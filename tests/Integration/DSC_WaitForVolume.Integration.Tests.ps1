#region HEADER
$script:dscModuleName = 'StorageDsc'
$script:dscResourceName = 'MSFT_WaitForVolume'

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
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:dscResourceName)_Integration" {
        Context 'Wait for a Volume' {
            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" -OutputPath $TestDrive
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
                $current.DriveLetter      | Should -Be $TestWaitForVolume.DriveLetter
                $current.RetryIntervalSec | Should -Be $TestWaitForVolume.RetryIntervalSec
                $current.RetryCount       | Should -Be $TestWaitForVolume.RetryCount
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
