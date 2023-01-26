#region HEADER
$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)/$($script:subModuleName).psm1"

Import-Module $script:subModuleFile -Force -ErrorAction Stop
#endregion HEADER

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

InModuleScope $script:subModuleName {
    function Get-Disk
    {
        [CmdletBinding()]
        Param
        (
            [Parameter()]
            [System.UInt32]
            $Number,

            [Parameter()]
            [System.String]
            $UniqueId
        )
    }

    Describe 'StorageDsc.Common\Restart-SystemService' -Tag 'Restart-SystemService' {
        BeforeAll {
            Mock -CommandName Restart-Service

            $restartServiceIfExistsParams = @{
                Name = 'BITS'
            }
        }

        Context 'When service does not exist and is not restarted' {
            Mock -CommandName Get-Service

            It 'Should call the expected mocks' {
                Restart-ServiceIfExists @restartServiceIfExistsParams
                Assert-MockCalled Get-Service -Exactly -Times 1 -Scope It -ParameterFilter { $Name -eq $restartServiceIfExistsParams.Name }
                Assert-MockCalled Restart-Service -Exactly -Times 0 -Scope It
            }
        }

        Context 'When service exists and will be restarted' {
            $getService_mock = {
                @{
                    Status      = 'Running'
                    Name        = 'Servsvc'
                    DisplayName = 'Service service'
                }
            }

            Mock -CommandName Get-Service -MockWith $getService_mock

            It 'Should call the expected mocks' {
                Restart-ServiceIfExists @restartServiceIfExistsParams
                Assert-MockCalled Get-Service -Exactly -Times 1 -Scope It -ParameterFilter { $Name -eq $restartServiceIfExistsParams.Name }
                Assert-MockCalled Restart-Service -Exactly -Times 1 -Scope It
            }
        }
    }

    Describe 'StorageDsc.Common\Assert-DriveLetterValid' -Tag 'Assert-DriveLetterValid' {
        BeforeAll {
            $driveLetterGood = 'C'
            $driveLetterGoodwithColon = 'C:'
            $driveLetterBad = '1'
            $driveLetterBadColon = ':C'
            $driveLetterBadTooLong = 'FE:'

            $accessPathGood = 'c:\Good'
            $accessPathGoodWithSlash = 'c:\Good\'
            $accessPathBad = 'c:\Bad'
        }

        Context 'Drive letter is good, has no colon and colon is not required' {
            It "Should return '$driveLetterGood'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGood | Should -Be $driveLetterGood
            }
        }

        Context 'Drive letter is good, has no colon but colon is required' {
            It "Should return '$driveLetterGoodwithColon'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGood -Colon | Should -Be $driveLetterGoodwithColon
            }
        }

        Context 'Drive letter is good, has a colon but colon is not required' {
            It "Should return '$driveLetterGood'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGoodwithColon | Should -Be $driveLetterGood
            }
        }

        Context 'Drive letter is good, has a colon and colon is required' {
            It "Should return '$driveLetterGoodwithColon'" {
                Assert-DriveLetterValid -DriveLetter $driveLetterGoodwithColon -Colon | Should -Be $driveLetterGoodwithColon
            }
        }

        Context 'Drive letter is non alpha' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBad) `
                -ArgumentName 'DriveLetter'

            It 'Should throw InvalidDriveLetterFormatError' {
                { Assert-DriveLetterValid -DriveLetter $driveLetterBad } | Should -Throw $errorRecord
            }
        }

        Context 'Drive letter has a bad colon location' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBadColon) `
                -ArgumentName 'DriveLetter'

            It 'Should throw InvalidDriveLetterFormatError' {
                { Assert-DriveLetterValid -DriveLetter $driveLetterBadColon } | Should -Throw $errorRecord
            }
        }

        Context 'Drive letter is too long' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message $($LocalizedData.InvalidDriveLetterFormatError -f $driveLetterBadTooLong) `
                -ArgumentName 'DriveLetter'

            It 'Should throw InvalidDriveLetterFormatError' {
                { Assert-DriveLetterValid -DriveLetter $driveLetterBadTooLong } | Should -Throw $errorRecord
            }
        }
    }

    Describe 'StorageDsc.Common\Assert-AccessPathValid' -Tag 'Assert-AccessPathValid' {
        Mock `
            -CommandName Test-Path `
            -ModuleName StorageDsc.Common `
            -MockWith { $true }

        Context 'Path is found, trailing slash included, not required' {
            It "Should return '$accessPathGood'" {
                Assert-AccessPathValid -AccessPath $accessPathGoodWithSlash | Should -Be $accessPathGood
            }
        }

        Context 'Path is found, trailing slash included, required' {
            It "Should return '$accessPathGoodWithSlash'" {
                Assert-AccessPathValid -AccessPath $accessPathGoodWithSlash -Slash | Should -Be $accessPathGoodWithSlash
            }
        }

        Context 'Path is found, trailing slash not included, required' {
            It "Should return '$accessPathGoodWithSlash'" {
                Assert-AccessPathValid -AccessPath $accessPathGood -Slash | Should -Be $accessPathGoodWithSlash
            }
        }

        Context 'Path is found, trailing slash not included, not required' {
            It "Should return '$accessPathGood'" {
                Assert-AccessPathValid -AccessPath $accessPathGood | Should -Be $accessPathGood
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
                        -AccessPath $accessPathBad } | Should -Throw $errorRecord
            }
        }
    }

    Describe 'StorageDsc.Common\Get-DiskByIdentifier' -Tag 'Get-DiskByIdentifier' {
        BeforeAll {
            $testDiskNumber = 10
            $testDiskUniqueId = 'DiskUniqueId'
            $testDiskFriendlyName = 'DiskFriendlyName'
            $testDiskGuid = [Guid]::NewGuid().ToString()
            $testDiskLocation = 'Integrated : Adapter 0 : Port 0 : Target 0 : LUN 10'

            $mockedDisk = [pscustomobject] @{
                Number       = $testDiskNumber
                UniqueId     = $testDiskUniqueId
                FriendlyName = $testDiskFriendlyName
                Guid         = $testDiskGuid
                Location     = $testDiskLocation
            }
        }

        Context 'Disk exists that matches the specified Disk Number' {
            Mock `
                -CommandName Get-Disk `
                -MockWith { $mockedDisk } `
                -ModuleName StorageDsc.Common `
                -ParameterFilter { $Number -eq $testDiskNumber } `
                -Verifiable

            It "Should return Disk with Disk Number $testDiskNumber" {
                (Get-DiskByIdentifier -DiskId $testDiskNumber).Number | Should -Be $testDiskNumber
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
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
                Get-DiskByIdentifier -DiskId $testDiskNumber | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
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
                (Get-DiskByIdentifier -DiskId $testDiskUniqueId -DiskIdType 'UniqueId').UniqueId | Should -Be $testDiskUniqueId
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
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
                Get-DiskByIdentifier -DiskId $testDiskUniqueId -DiskIdType 'UniqueId' | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
                Assert-MockCalled `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -ParameterFilter { $UniqueId -eq $testDiskUniqueId } `
                    -Exactly `
                    -Times 1
            }
        }

        Context 'Disk exists that matches the specified Disk FriendlyName' {
            Mock `
                -CommandName Get-Disk `
                -MockWith { $mockedDisk } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            It "Should return Disk with Disk FriendlyName $testDiskFriendlyName" {
                (Get-DiskByIdentifier -DiskId $testDiskFriendlyName -DiskIdType 'FriendlyName').FriendlyName | Should -Be $testDiskFriendlyName
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
                Assert-MockCalled `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -Exactly `
                    -Times 1
            }
        }

        Context 'Disk does not exist that matches the specified Disk FriendlyName' {
            Mock `
                -CommandName Get-Disk `
                -ModuleName StorageDsc.Common `
                -Verifiable

            It "Should return Disk with Disk FriendlyName $testDiskFriendlyName" {
                Get-DiskByIdentifier -DiskId $testDiskFriendlyName -DiskIdType 'FriendlyName' | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
                Assert-MockCalled `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
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
                (Get-DiskByIdentifier -DiskId $testDiskGuid -DiskIdType 'Guid').Guid | Should -Be $testDiskGuid
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
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
                Get-DiskByIdentifier -DiskId $testDiskGuid -DiskIdType 'Guid' | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
                Assert-MockCalled `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -Exactly `
                    -Times 1
            }
        }

        Context 'Disk exists that matches the specified Disk Location' {
            Mock `
                -CommandName Get-Disk `
                -MockWith { $mockedDisk } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            It "Should return Disk with Disk Location '$testDiskLocation'" {
                (Get-DiskByIdentifier -DiskId $testDiskLocation -DiskIdType 'Location').Location | Should -Be $testDiskLocation
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
                Assert-MockCalled `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -Exactly `
                    -Times 1
            }
        }

        Context 'Disk does not exist that matches the specified Disk Location' {
            Mock `
                -CommandName Get-Disk `
                -ModuleName StorageDsc.Common `
                -Verifiable

            It "Should return Disk with Disk Location '$testDiskLocation'" {
                Get-DiskByIdentifier -DiskId $testDiskLocation -DiskIdType 'Location' | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
                Assert-MockCalled `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -Exactly `
                    -Times 1
            }
        }
    }

    Describe 'StorageDsc.Common\Test-AccessPathAssignedToLocal' -Tag 'Test-AccessPathAssignedToLocal' {
        Context 'Contains a single access path that is local' {
            It 'Should return $true' {
                Test-AccessPathAssignedToLocal `
                    -AccessPath @('c:\MountPoint\') | Should -Be $true
            }
        }

        Context 'Contains a single access path that is not local' {
            It 'Should return $false' {
                Test-AccessPathAssignedToLocal `
                    -AccessPath @('\\?\Volume{99cf0194-ac45-4a23-b36e-3e458158a63e}\') | Should -Be $false
            }
        }

        Context 'Contains multiple access paths where one is local' {
            It 'Should return $true' {
                Test-AccessPathAssignedToLocal `
                    -AccessPath @('c:\MountPoint\', '\\?\Volume{99cf0194-ac45-4a23-b36e-3e458158a63e}\') | Should -Be $true
            }
        }

        Context 'Contains multiple access paths where none are local' {
            It 'Should return $false' {
                Test-AccessPathAssignedToLocal `
                    -AccessPath @('\\?\Volume{905551f3-33a5-421d-ac24-c993fbfb3184}\', '\\?\Volume{99cf0194-ac45-4a23-b36e-3e458158a63e}\') | Should -Be $false
            }
        }
    }
}
