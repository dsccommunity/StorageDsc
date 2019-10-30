$script:ModuleName = 'StorageDsc.Common'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1')

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module -Name (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath $script:ModuleName)) -ChildPath "$script:ModuleName.psm1") -Force
#endregion HEADER

InModuleScope 'StorageDsc.Common' {
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

    Describe 'StorageDsc.Common\Test-DscParameterState' -Tag TestDscParameterState {
        Context -Name 'When passing values' -Fixture {
            It 'Should return true for two identical tables' {
                $mockDesiredValues = @{ Example = 'test' }

                $testParameters = @{
                    CurrentValues = $mockDesiredValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when a value is different for [System.String]' {
                $mockCurrentValues = @{ Example = [System.String] 'something' }
                $mockDesiredValues = @{ Example = [System.String] 'test' }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is different for [System.Int32]' {
                $mockCurrentValues = @{ Example = [System.Int32] 1 }
                $mockDesiredValues = @{ Example = [System.Int32] 2 }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is different for [Int16]' {
                $mockCurrentValues = @{ Example = [System.Int16] 1 }
                $mockDesiredValues = @{ Example = [System.Int16] 2 }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is different for [UInt16]' {
                $mockCurrentValues = @{ Example = [System.UInt16] 1 }
                $mockDesiredValues = @{ Example = [System.UInt16] 2 }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is different for [Boolean]' {
                $mockCurrentValues = @{ Example = [System.Boolean] $true }
                $mockDesiredValues = @{ Example = [System.Boolean] $false }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is missing' {
                $mockCurrentValues = @{ }
                $mockDesiredValues = @{ Example = 'test' }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return true when only a specified value matches, but other non-listed values do not' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = 'true' }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = 'false' }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('Example')
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when only specified values do not match, but other non-listed values do ' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = 'true' }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = 'false' }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('SecondExample')
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when an empty hash table is used in the current values' {
                $mockCurrentValues = @{ }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = 'false' }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return true when evaluating a table against a CimInstance' {
                $mockCurrentValues = @{ Handle = '0'; ProcessId = '1000' }

                $mockWin32ProcessProperties = @{
                    Handle    = 0
                    ProcessId = 1000
                }

                $mockNewCimInstanceParameters = @{
                    ClassName  = 'Win32_Process'
                    Property   = $mockWin32ProcessProperties
                    Key        = 'Handle'
                    ClientOnly = $true
                }

                $mockDesiredValues = New-CimInstance @mockNewCimInstanceParameters

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('Handle', 'ProcessId')
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when evaluating a table against a CimInstance and a value is wrong' {
                $mockCurrentValues = @{ Handle = '1'; ProcessId = '1000' }

                $mockWin32ProcessProperties = @{
                    Handle    = 0
                    ProcessId = 1000
                }

                $mockNewCimInstanceParameters = @{
                    ClassName  = 'Win32_Process'
                    Property   = $mockWin32ProcessProperties
                    Key        = 'Handle'
                    ClientOnly = $true
                }

                $mockDesiredValues = New-CimInstance @mockNewCimInstanceParameters

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('Handle', 'ProcessId')
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return true when evaluating a hash table containing an array' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = @('1', '2') }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1', '2') }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when evaluating a hash table containing an array with wrong values' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = @('A', 'B') }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1', '2') }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when evaluating a hash table containing an array, but the CurrentValues are missing an array' {
                $mockCurrentValues = @{ Example = 'test' }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1', '2') }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when evaluating a hash table containing an array, but the property i CurrentValues is $null' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = $null }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1', '2') }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }
        }

        Context -Name 'When passing invalid types for DesiredValues' -Fixture {
            It 'Should throw the correct error when DesiredValues is of wrong type' {
                $mockCurrentValues = @{ Example = 'something' }
                $mockDesiredValues = 'NotHashTable'

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                $mockCorrectErrorMessage = ($script:localizedData.PropertyTypeInvalidForDesiredValues -f $testParameters.DesiredValues.GetType().Name)
                { Test-DscParameterState @testParameters } | Should -Throw $mockCorrectErrorMessage
            }

            It 'Should write a warning when DesiredValues contain an unsupported type' {
                Mock -CommandName Write-Warning -Verifiable

                # This is a dummy type to test with a type that could never be a correct one.
                class MockUnknownType
                {
                    [ValidateNotNullOrEmpty()]
                    [System.String]
                    $Property1

                    [ValidateNotNullOrEmpty()]
                    [System.String]
                    $Property2

                    MockUnknownType()
                    {
                    }
                }

                $mockCurrentValues = @{ Example = New-Object -TypeName MockUnknownType }
                $mockDesiredValues = @{ Example = New-Object -TypeName MockUnknownType }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false

                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1
            }
        }

        Context -Name 'When passing an CimInstance as DesiredValue and ValuesToCheck is $null' -Fixture {
            It 'Should throw the correct error' {
                $mockCurrentValues = @{ Example = 'something' }

                $mockWin32ProcessProperties = @{
                    Handle    = 0
                    ProcessId = 1000
                }

                $mockNewCimInstanceParameters = @{
                    ClassName  = 'Win32_Process'
                    Property   = $mockWin32ProcessProperties
                    Key        = 'Handle'
                    ClientOnly = $true
                }

                $mockDesiredValues = New-CimInstance @mockNewCimInstanceParameters

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = $null
                }

                $mockCorrectErrorMessage = $script:localizedData.PropertyTypeInvalidForValuesToCheck
                { Test-DscParameterState @testParameters } | Should -Throw $mockCorrectErrorMessage
            }
        }

        Assert-VerifiableMock
    }

    Describe 'StorageDsc.Common\Get-LocalizedData' {
        $mockTestPath = {
            return $mockTestPathReturnValue
        }

        $mockImportLocalizedData = {
            $BaseDirectory | Should -Be $mockExpectedLanguagePath
        }

        BeforeEach {
            Mock -CommandName Test-Path -MockWith $mockTestPath -Verifiable
            Mock -CommandName Import-LocalizedData -MockWith $mockImportLocalizedData -Verifiable
        }

        Context 'When loading localized data for Swedish' {
            $mockExpectedLanguagePath = 'sv-SE'
            $mockTestPathReturnValue = $true

            It 'Should call Import-LocalizedData with sv-SE language' {
                Mock -CommandName Join-Path -MockWith {
                    return 'sv-SE'
                } -Verifiable

                { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                Assert-MockCalled -CommandName Join-Path -Exactly -Times 3 -Scope It
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
            }

            $mockExpectedLanguagePath = 'en-US'
            $mockTestPathReturnValue = $false

            It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                Mock -CommandName Join-Path -MockWith {
                    return $ChildPath
                } -Verifiable

                { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                Assert-MockCalled -CommandName Join-Path -Exactly -Times 4 -Scope It
                Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
            }

            Context 'When $ScriptRoot is set to a path' {
                $mockExpectedLanguagePath = 'sv-SE'
                $mockTestPathReturnValue = $true

                It 'Should call Import-LocalizedData with sv-SE language' {
                    Mock -CommandName Join-Path -MockWith {
                        return 'sv-SE'
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $false

                It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                    Mock -CommandName Join-Path -MockWith {
                        return $ChildPath
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 2 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When loading localized data for English' {
            Mock -CommandName Join-Path -MockWith {
                return 'en-US'
            } -Verifiable

            $mockExpectedLanguagePath = 'en-US'
            $mockTestPathReturnValue = $true

            It 'Should call Import-LocalizedData with en-US language' {
                { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw
            }
        }

        Assert-VerifiableMock
    }

    Describe 'StorageDsc.Common\New-InvalidResultException' {
        Context 'When calling with Message parameter only' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'

                { New-InvalidResultException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
            }
        }

        Context 'When calling with both the Message and ErrorRecord parameter' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'
                $mockExceptionErrorMessage = 'Mocked exception error message'

                $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                { New-InvalidResultException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.Exception: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
            }
        }

        Assert-VerifiableMock
    }

    Describe 'StorageDsc.Common\New-ObjectNotFoundException' {
        Context 'When calling with Message parameter only' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'

                { New-ObjectNotFoundException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
            }
        }

        Context 'When calling with both the Message and ErrorRecord parameter' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'
                $mockExceptionErrorMessage = 'Mocked exception error message'

                $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                { New-ObjectNotFoundException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.Exception: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
            }
        }

        Assert-VerifiableMock
    }

    Describe 'StorageDsc.Common\New-InvalidOperationException' {
        Context 'When calling with Message parameter only' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'

                { New-InvalidOperationException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
            }
        }

        Context 'When calling with both the Message and ErrorRecord parameter' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'
                $mockExceptionErrorMessage = 'Mocked exception error message'

                $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                { New-InvalidOperationException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.InvalidOperationException: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
            }
        }

        Assert-VerifiableMock
    }

    Describe 'StorageDsc.Common\New-NotImplementedException' {
        Context 'When called with Message parameter only' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'

                { New-NotImplementedException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
            }
        }

        Context 'When called with both the Message and ErrorRecord parameter' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'
                $mockExceptionErrorMessage = 'Mocked exception error message'

                $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                { New-NotImplementedException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.NotImplementedException: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
            }
        }

        Assert-VerifiableMock
    }

    Describe 'StorageDsc.Common\New-InvalidArgumentException' {
        Context 'When calling with both the Message and ArgumentName parameter' {
            It 'Should throw the correct error' {
                $mockErrorMessage = 'Mocked error'
                $mockArgumentName = 'MockArgument'

                { New-InvalidArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } | Should -Throw ('Parameter name: {0}' -f $mockArgumentName)
            }
        }

        Assert-VerifiableMock
    }

    Describe 'StorageDsc.Common\Restart-SystemService' {
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

    Describe 'StorageDsc.Common\Assert-DriveLetterValid' {
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

    Describe "StorageDsc.Common\Assert-AccessPathValid" {
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

    Describe 'StorageDsc.Common\Get-DiskByIdentifier' {
        BeforeAll {
            $testDiskNumber = 10
            $testDiskUniqueId = 'DiskUniqueId'
            $testDiskGuid = [Guid]::NewGuid().ToString()
            $testDiskLocation = 'Integrated : Adapter 0 : Port 0 : Target 0 : LUN 10'

            $mockedDisk = [pscustomobject] @{
                Number   = $testDiskNumber
                UniqueId = $testDiskUniqueId
                Guid     = $testDiskGuid
                Location = $testDiskLocation
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

    Describe "StorageDsc.Common\Test-AccessPathAssignedToLocal" {
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
