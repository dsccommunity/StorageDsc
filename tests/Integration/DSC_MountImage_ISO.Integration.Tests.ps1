# <#
#     In order to run these tests, a basic ISO file called 'test.iso' must be put
#     in the same folder as this file. The ISO file must be a valid ISO file that can
#     normally be mounted. If the test.iso file is not found the tests will not run.
#     The ISO is not included with this repository because of size contstraints.
#     It is up to the user or mechanism running these tests to put a valid 'test.iso'
#     into this folder.
# #>
# $script:dscModuleName = 'StorageDsc'
# $script:dscResourceName = 'DSC_MountImage'

# try
# {
#     Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
# }
# catch [System.IO.FileNotFoundException]
# {
#     throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
# }

# $script:testEnvironment = Initialize-TestEnvironment `
#     -DSCModuleName $script:dscModuleName `
#     -DSCResourceName $script:dscResourceName `
#     -ResourceType 'Mof' `
#     -TestType 'Integration'

# Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

# try
# {
#     $ISOPath = Join-Path -Path $PSScriptRoot -ChildPath 'test.iso'

#     # Ensure that the ISO tests can be performed on this computer
#     if (-not (Test-Path -Path $ISOPath))
#     {
#         Write-Verbose -Message "$($script:dscResourceName) integration tests cannot be run because the ISO File '$ISOPath' is not available." -Verbose
#         return
#     } # if

#     # Get a spare drive letter
#     $LastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
#     $DriveLetter = [char](([int][char]$LastDrive)+1)

#     # Create a config data object to pass to the DSC Configs
#     $ConfigData = @{
#         AllNodes = @(
#             @{
#                 NodeName    = 'localhost'
#                 ImagePath   = $ISOPath
#                 DriveLetter = $DriveLetter
#             }
#         )
#     }

#     # Mount ISO
#     $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_mount.config.ps1"
#     . $configFile -Verbose -ErrorAction Stop

#     Describe "$($script:dscResourceName)_MountISO_Integration" {
#         Context 'Mount an ISO and assign a Drive Letter' {
#             It 'Should compile and apply the MOF without throwing' {
#                 {
#                     & "$($script:dscResourceName)_Mount_Config" `
#                         -OutputPath $TestDrive `
#                         -ConfigurationData $ConfigData
#                     Start-DscConfiguration -Path $TestDrive `
#                         -ComputerName localhost -Wait -Verbose -Force
#                 } | Should -Not -Throw
#             }

#             It 'Should be able to call Get-DscConfiguration without throwing' {
#                 { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
#             }

#             It 'Should have set the resource and all the parameters should match' {
#                 $current = Get-DscConfiguration | Where-Object {
#                     $_.ConfigurationName -eq "$($script:dscResourceName)_Mount_Config"
#                 }
#                 $current.Imagepath        | Should -Be $ISOPath
#                 $current.DriveLetter      | Should -Be $DriveLetter
#                 $current.StorageType      | Should -Be 'ISO'
#                 $current.Access           | Should -Be 'ReadOnly'
#                 $current.Ensure           | Should -Be 'Present'
#             }
#         }
#     }

#     # Dismount ISO
#     $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_dismount.config.ps1"
#     . $configFile -Verbose -ErrorAction Stop

#     Describe "$($script:dscResourceName)_DismountISO_Integration" {
#         Context 'Dismount a previously mounted ISO' {
#             It 'Should compile and apply the MOF without throwing' {
#                 {
#                     & "$($script:dscResourceName)_Dismount_Config" `
#                         -OutputPath $TestDrive `
#                         -ConfigurationData $ConfigData
#                     Start-DscConfiguration -Path $TestDrive `
#                         -ComputerName localhost -Wait -Verbose -Force
#                 } | Should -Not -Throw
#             }

#             It 'Should be able to call Get-DscConfiguration without throwing' {
#                 { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
#             }

#             It 'Should have set the resource and all the parameters should match' {
#                 $current = Get-DscConfiguration | Where-Object {
#                     $_.ConfigurationName -eq "$($script:dscResourceName)_Dismount_Config"
#                 }
#                 $current.Imagepath        | Should -Be $ISOPath
#                 $current.Ensure           | Should -Be 'Absent'
#             }
#         }
#     }
# }
# finally
# {
#     Restore-TestEnvironment -TestEnvironment $script:testEnvironment
# }
