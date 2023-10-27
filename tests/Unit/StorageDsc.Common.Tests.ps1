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

    $script:mockedSizesForDevDriveScenario = [pscustomobject] @{
        UserDesired0Gb = 0Gb
        UserDesired10Gb = 10Gb
        UserDesired50Gb = 50Gb
        UserDesired60Gb = 60Gb
        CurrentDiskFreeSpace40Gb = 40Gb
        CurrentDiskFreeSpace50Gb = 50Gb
        CurrentDiskFreeSpace60Gb = 60Gb

        # Alternate value in bytes that can represent a 150 Gb partition in a physical hard disk that has been formatted by Windows.
        SizeAEffectively150GbInBytes = 161060225024

        SizeB150GbInBytes = 150Gb
        SizeBInBytesFor49Point99Scenario = 49.99Gb
    }

    $script:mockedDiskNumber = 1

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
            $UniqueId,

            [Parameter()]
            [System.String]
            $FriendlyName,

            [Parameter()]
            [System.String]
            $SerialNumber
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
            $testDiskSerialNumber = 'DiskSerialNumber'
            $testDiskGuid = [Guid]::NewGuid().ToString()
            $testDiskLocation = 'Integrated : Adapter 0 : Port 0 : Target 0 : LUN 10'

            $mockedDisk = [pscustomobject] @{
                Number       = $testDiskNumber
                UniqueId     = $testDiskUniqueId
                FriendlyName = $testDiskFriendlyName
                SerialNumber = $testDiskSerialNumber
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

        Context 'Disk exists that matches the specified Disk Friendly Name' {
            Mock `
                -CommandName Get-Disk `
                -MockWith { $mockedDisk } `
                -ModuleName StorageDsc.Common `
                -ParameterFilter { $FriendlyName -eq $testDiskFriendlyName } `
                -Verifiable

            It "Should return Disk with Disk Friendly Name $testDiskFriendlyName" {
                (Get-DiskByIdentifier -DiskId $testDiskFriendlyName -DiskIdType 'FriendlyName').FriendlyName | Should -Be $testDiskFriendlyName
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
                Assert-MockCalled `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -ParameterFilter { $FriendlyName -eq $testDiskFriendlyName } `
                    -Exactly `
                    -Times 1
            }
        }

        Context 'Disk does not exist that matches the specified Disk Friendly Name' {
            Mock `
                -CommandName Get-Disk `
                -ModuleName StorageDsc.Common `
                -ParameterFilter { $FriendlyName -eq $testDiskFriendlyName } `
                -Verifiable

            It "Should return Disk with Disk Friendly Name $testDiskFriendlyName" {
                Get-DiskByIdentifier -DiskId $testDiskFriendlyName -DiskIdType 'FriendlyName' | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
                Assert-MockCalled `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -ParameterFilter { $FriendlyName -eq $testDiskFriendlyName } `
                    -Exactly `
                    -Times 1
            }
        }

        Context 'Disk exists that matches the specified Disk Serial Number' {
            Mock `
                -CommandName Get-Disk `
                -MockWith { $mockedDisk } `
                -ModuleName StorageDsc.Common `
                -ParameterFilter { $SerialNumber -eq $testDiskSerialNumber } `
                -Verifiable

            It "Should return Disk with Disk Serial Number $testDiskSerialNumber" {
                (Get-DiskByIdentifier -DiskId $testDiskSerialNumber -DiskIdType 'SerialNumber').SerialNumber | Should -Be $testDiskSerialNumber
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
                Assert-MockCalled `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -ParameterFilter { $SerialNumber -eq $testDiskSerialNumber } `
                    -Exactly `
                    -Times 1
            }
        }

        Context 'Disk does not exist that matches the specified Disk Serial Number' {
            Mock `
                -CommandName Get-Disk `
                -ModuleName StorageDsc.Common `
                -ParameterFilter { $SerialNumber -eq $testDiskSerialNumber } `
                -Verifiable

            It "Should return Disk with Disk Serial Number $testDiskSerialNumber" {
                Get-DiskByIdentifier -DiskId $testDiskSerialNumber -DiskIdType 'SerialNumber' | Should -BeNullOrEmpty
            }

            It 'Should call expected mocks' {
                Assert-VerifiableMock
                Assert-MockCalled `
                    -CommandName Get-Disk `
                    -ModuleName StorageDsc.Common `
                    -ParameterFilter { $SerialNumber -eq $testDiskSerialNumber } `
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

    Describe 'StorageDsc.Common\Assert-DevDriveFeatureAvailable' -Tag 'Assert-DevDriveFeatureAvailable' {
        Context 'When testing the Dev Drive enablement state and the dev drive feature not implemented' {
            Mock `
                -CommandName Invoke-IsApiSetImplemented `
                -MockWith { $false } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            It 'Should throw with DevDriveFeatureNotImplementedError' {
                {
                    Assert-DevDriveFeatureAvailable -Verbose
                } | Should -Throw -ExpectedMessage $LocalizedData.DevDriveFeatureNotImplementedError
            }

            It 'Should call the correct mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1
            }
        }

        Context 'When testing the Dev Drive enablement state returns an enablement state not defined in the enum' {
            Mock `
                -CommandName Invoke-IsApiSetImplemented `
                -MockWith { $true } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            Mock `
                -CommandName Get-DevDriveEnablementState `
                -MockWith { $null } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            It 'Should throw with DevDriveEnablementUnknownError' {
                {
                    Assert-DevDriveFeatureAvailable -Verbose
                } | Should -Throw -ExpectedMessage $LocalizedData.DevDriveEnablementUnknownError
            }

            It 'Should call the correct mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1
                Assert-MockCalled -CommandName Get-DevDriveEnablementState -Exactly -Times 1
            }
        }

        Context 'When testing the Dev Drive enablement state and the dev drive feature is disabled by group policy' {
            Get-DevDriveWin32HelperScript
            $DevDriveEnablementType = [DevDrive.DevDriveHelper+DEVELOPER_DRIVE_ENABLEMENT_STATE]

            Mock `
                -CommandName Invoke-IsApiSetImplemented `
                -MockWith { $true } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            Mock `
                -CommandName Get-DevDriveEnablementState `
                -MockWith { $DevDriveEnablementType::DeveloperDriveDisabledByGroupPolicy } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            It 'Should throw with DevDriveDisabledByGroupPolicyError' {
                {
                    Assert-DevDriveFeatureAvailable -Verbose
                } | Should -Throw -ExpectedMessage $LocalizedData.DevDriveDisabledByGroupPolicyError
            }

            It 'Should call the correct mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1
                Assert-MockCalled -CommandName Get-DevDriveEnablementState -Exactly -Times 1
            }
        }

        Context 'When testing the Dev Drive enablement state and the dev drive feature is disabled by system policy' {
            Mock `
                -CommandName Invoke-IsApiSetImplemented `
                -MockWith { $true } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            Mock `
                -CommandName Get-DevDriveEnablementState `
                -MockWith { $DevDriveEnablementType::DeveloperDriveDisabledBySystemPolicy } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            It 'Should throw with DeveloperDriveDisabledBySystemPolicy' {
                {
                    Assert-DevDriveFeatureAvailable -Verbose
                } | Should -Throw -ExpectedMessage $LocalizedData.DeveloperDriveDisabledBySystemPolicy
            }

            It 'Should call the correct mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1
                Assert-MockCalled -CommandName Get-DevDriveEnablementState -Exactly -Times 1
            }
        }

        Context 'When testing the Dev Drive enablement state and the enablement state is unknown' {
            Mock `
                -CommandName Invoke-IsApiSetImplemented `
                -MockWith { $true } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            Mock `
                -CommandName Get-DevDriveEnablementState `
                -MockWith { $DevDriveEnablementType::DeveloperDriveEnablementStateError } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            It 'Should throw with DevDriveEnablementUnknownError' {
                {
                    Assert-DevDriveFeatureAvailable -Verbose
                } | Should -Throw -ExpectedMessage $LocalizedData.DevDriveEnablementUnknownError
            }

            It 'Should call the correct mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1
                Assert-MockCalled -CommandName Get-DevDriveEnablementState -Exactly -Times 1
            }
        }

        Context 'When testing Dev Drive enablement state and the enablement state is set to enabled' {
            Mock `
                -CommandName Invoke-IsApiSetImplemented `
                -MockWith { $true } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            Mock `
                -CommandName Get-DevDriveEnablementState `
                -MockWith { $DevDriveEnablementType::DeveloperDriveEnabled } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            It 'Should not throw' {
                {
                    Assert-DevDriveFeatureAvailable -Verbose
                } | Should -Not -Throw
            }

            It 'Should call the correct mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Invoke-IsApiSetImplemented -Exactly -Times 1
                Assert-MockCalled -CommandName Get-DevDriveEnablementState -Exactly -Times 1
            }
        }
    }

    Describe 'StorageDsc.Common\Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue' -Tag 'Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue' {
        Context 'When testing that only the ReFS file system is allowed' {

            $errorRecord = Get-InvalidArgumentRecord `
                -Message ($script:localizedData.FSFormatNotReFSWhenDevDriveFlagIsTrueError ) `
                -ArgumentName 'FSFormat'

            It 'Should throw invalid argument error if a filesystem other than ReFS is passed in' {
                {
                    Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue -FSFormat "test" -Verbose
                } | Should -Throw $errorRecord
            }
        }

        Context 'When testing Exception not thrown in Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue when ReFS file system passed in' {

            It 'Should not throw invalid argument error if ReFS filesystem is passed in' {
                {
                    Assert-FSFormatIsReFsWhenDevDriveFlagSetToTrue -FSFormat "ReFS" -Verbose
                } | Should -Not -Throw
            }
        }
    }

    Describe 'StorageDsc.Common\Assert-SizeMeetsMinimumDevDriveRequirement' -Tag 'Assert-SizeMeetsMinimumDevDriveRequirement' {
        Context 'When UserDesiredSize does not meet the minimum size for Dev Drive volumes' {

            $UserDesiredSizeInGb = [Math]::Round($mockedSizesForDevDriveScenario.UserDesired10Gb / 1GB, 2)
            It 'Should throw invalid argument error' {
                {
                    Assert-SizeMeetsMinimumDevDriveRequirement `
                        -UserDesiredSize $mockedSizesForDevDriveScenario.UserDesired10Gb `
                        -Verbose
                } | Should -Throw -ExpectedMessage ($script:localizedCommonStrings.MinimumSizeNeededToCreateDevDriveVolumeError -f $UserDesiredSizeInGb)
            }
        }

        Context 'When UserDesiredSize meets the minimum size for Dev Drive volumes' {

            It 'Should not throw invalid argument error' {
                {
                    Assert-SizeMeetsMinimumDevDriveRequirement `
                        -UserDesiredSize $mockedSizesForDevDriveScenario.UserDesired50Gb `
                        -Verbose
                } | Should -Not -Throw
            }
        }
    }

    Describe 'StorageDsc.Common\Test-DevDriveVolume' -Tag 'Test-DevDriveVolume' {
        Context 'When testing whether a volume is a Dev Drive volume and the volume is a Dev Drive volume' {

            Mock `
                -CommandName Invoke-DeviceIoControlWrapperForDevDriveQuery `
                -MockWith { $true } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            $result = Test-DevDriveVolume -VolumeGuidPath "\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7924}\" -Verbose
            It 'Should return true' {
                $result | Should -Be $true
            }

            It 'Should call the correct mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Invoke-DeviceIoControlWrapperForDevDriveQuery -Exactly -Times 1
            }

        }

        Context 'When testing whether a volume is a Dev Drive volume and the volume is not a Dev Drive volume' {

            Mock `
                -CommandName Invoke-DeviceIoControlWrapperForDevDriveQuery `
                -MockWith { $false } `
                -ModuleName StorageDsc.Common `
                -Verifiable

            $result = Test-DevDriveVolume -VolumeGuidPath "\\?\Volume{3a244a32-efba-4b7e-9a19-7293fc7c7923}\" -Verbose
            It 'Should return false' {
                $result | Should -Be $false
            }

            It 'Should call the correct mocks' {
                Assert-VerifiableMock
                Assert-MockCalled -CommandName Invoke-DeviceIoControlWrapperForDevDriveQuery -Exactly -Times 1
            }
        }
    }

    Describe 'StorageDsc.Common\Compare-SizeUsingGB' -Tag 'Compare-SizeUsingGB' {
        Context 'When comparing whether SizeAInBytes is equal to SizeBInBytes when SizeAInBytes is effectively equal to SizeBInBytes when both are converted to Gb' {

            $result = Compare-SizeUsingGB `
                -SizeAInBytes $mockedSizesForDevDriveScenario.SizeB150GbInBytes `
                -SizeBInBytes $mockedSizesForDevDriveScenario.SizeAEffectively150GbInBytes

            It 'Should return true' {
                $result | Should -BeTrue
            }
        }

        Context 'When comparing whether SizeAInBytes is equal to SizeBInBytes when SizeAInBytes is equal to SizeBInBytes when both are converted to Gb' {

            $result = Compare-SizeUsingGB `
                -SizeAInBytes $mockedSizesForDevDriveScenario.UserDesired50Gb `
                -SizeBInBytes $mockedSizesForDevDriveScenario.CurrentDiskFreeSpace50Gb

            It 'Should return true' {
                $result | Should -BeTrue
            }
        }

        Context 'When comparing whether SizeAInBytes is equal to SizeBInBytes when SizeAInBytes is not equal to SizeBInBytes when both are converted to Gb' {

            $result = Compare-SizeUsingGB `
                -SizeAInBytes $mockedSizesForDevDriveScenario.UserDesired50Gb `
                -SizeBInBytes $mockedSizesForDevDriveScenario.SizeBInBytesFor49Point99Scenario

            It 'Should return false' {
                $result | Should -BeFalse
            }
        }
    }
}
