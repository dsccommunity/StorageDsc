<#
    .SYNOPSIS
        Unit test for DSC_DiskAccessPath DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'StorageDsc'
    $script:dscResourceName = 'DSC_DiskAccessPath'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

Describe 'DSC_DiskAccessPath\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            function script:Get-Partition
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    $Disk,

                    [Parameter()]
                    [System.Uint32]
                    $PartitionNumber
                )
            }

            function script:Get-Volume
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    $Partition
                )
            }
        }
    }

    Context 'When using online GPT disk with a partition/volume and correct Access Path assigned specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $true
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 1
                    AccessPath = 'c:\TestAccessPath'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be $testParams.DiskId
                $result.AccessPath | Should -Be 'c:\TestAccessPath\'
                $result.Size | Should -Be 1GB
                $result.FSLabel | Should -Be 'myLabel'
                $result.AllocationUnitSize | Should -Be 4096
                $result.FSFormat | Should -Be 'NTFS'
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using online GPT disk with a partition/volume and correct Access Path assigned specified by Disk Unique Id' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $true
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 'TESTDISKUNIQUEID'
                    DiskIdType = 'UniqueId'
                    AccessPath = 'c:\TestAccessPath'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be 'TESTDISKUNIQUEID'
                $result.AccessPath | Should -Be 'c:\TestAccessPath\'
                $result.Size | Should -Be 1GB
                $result.FSLabel | Should -Be 'myLabel'
                $result.AllocationUnitSize | Should -Be 4096
                $result.FSFormat | Should -Be 'NTFS'
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using online GPT disk with a partition/volume and correct Access Path assigned specified by Disk Guid' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = '0459e66c-89a5-4c5e-a43c-0f485f2c7fc3'
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $true
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                }
            }

            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    BlockSize = 4096
                }
            }
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = '0459e66c-89a5-4c5e-a43c-0f485f2c7fc3'
                    DiskIdType = 'Guid'
                    AccessPath = 'c:\TestAccessPath'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be '0459e66c-89a5-4c5e-a43c-0f485f2c7fc3'
                $result.AccessPath | Should -Be 'c:\TestAccessPath\'
                $result.Size | Should -Be 1GB
                $result.FSLabel | Should -Be 'myLabel'
                $result.AllocationUnitSize | Should -Be 4096
                $result.FSFormat | Should -Be 'NTFS'
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using online GPT disk with no partition specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-CimInstance
            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition

            # mocks that should not be called
            Mock -CommandName Get-Volume
        }

        It 'Should return the current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 1
                    AccessPath = 'c:\TestAccessPath'
                }

                $result = Get-TargetResource @testParams

                $result.DiskId | Should -Be 1
                $result.AccessPath | Should -Be 'c:\TestAccessPath\'
                $result.Size | Should -BeNullOrEmpty
                $result.FSLabel | Should -BeNullOrEmpty
                $result.AllocationUnitSize | Should -BeNullOrEmpty
                $result.FSFormat | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_DiskAccessPath\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            function script:Set-Disk
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    $InputObject,

                    [Parameter()]
                    [System.Boolean]
                    $IsOffline,

                    [Parameter()]
                    [System.Boolean]
                    $IsReadOnly
                )
            }

            function script:Initialize-Disk
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    $InputObject,

                    [Parameter()]
                    [System.String]
                    $PartitionStyle
                )
            }

            function script:Get-Partition
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    $Disk,

                    [Parameter()]
                    [System.Uint32]
                    $PartitionNumber
                )
            }

            function script:Get-Volume
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    $Partition
                )
            }

            function script:New-Partition
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline)]
                    $Disk,

                    [Parameter()]
                    [System.Boolean]
                    $UseMaximumSize,

                    [Parameter()]
                    [UInt64]
                    $Size
                )
            }

            function script:Format-Volume
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    $Partition,

                    [Parameter()]
                    [System.String]
                    $FileSystem,

                    [Parameter()]
                    [System.Boolean]
                    $Confirm,

                    [Parameter()]
                    [System.Uint32]
                    $AllocationUnitSize
                )
            }

            function script:Set-Volume
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    $InputObject,

                    [Parameter()]
                    [System.String]
                    $NewFileSystemLabel
                )
            }
        }
    }

    Context 'When using offline GPT disk with NoDefaultDriveLetter set to False specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Add-PartitionAccessPath
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 1
                    AccessPath = 'c:\TestAccessPath'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using offline GPT disk with NoDefaultDriveLetter set to False specified by Disk Unique Id' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Add-PartitionAccessPath
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 'TESTDISKUNIQUEID'
                    DiskIdType           = 'UniqueId'
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using offline GPT disk specified by Disk Guid' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = '0459e66c-89a5-4c5e-a43c-0f485f2c7fc3'
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Add-PartitionAccessPath
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = '0459e66c-89a5-4c5e-a43c-0f485f2c7fc3'
                    DiskIdType = 'Guid'
                    AccessPath = 'c:\TestAccessPath'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using readonly GPT disk specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $true
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $false
                }
            }

            Mock -CommandName Set-Partition
            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Add-PartitionAccessPath

            # mocks that should not be called
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 1
                    AccessPath = 'c:\TestAccessPath'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using offline RAW disk specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = ''
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'Raw'
                }
            }

            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Add-PartitionAccessPath
            Mock -CommandName Set-Partition
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 1
                    AccessPath = 'c:\TestAccessPath'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using online RAW disk with Size specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = ''
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'Raw'
                }
            }

            Mock -CommandName Initialize-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Add-PartitionAccessPath
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Set-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 1
                    AccessPath = 'c:\TestAccessPath'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using online GPT disk with no partitions specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = ''
                    FileSystem      = ''
                }
            }

            Mock -CommandName Format-Volume
            Mock -CommandName Add-PartitionAccessPath
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using online MBR disk specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = '123456'
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'MBR'
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Get-Volume
            Mock -CommandName Add-PartitionAccessPath
        }

        It 'Should throw DiskAlreadyInitializedError' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 1
                    AccessPath = 'c:\TestAccessPath'
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DiskAlreadyInitializedError -f 'Number', $testParams.DiskId, 'MBR'
                )

                { Set-TargetResource @testParams } | Should -Throw -ExpectedMessage $errorRecord
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 0 -Scope It
        }
    }

    Context 'When using online MBR disk specified by Disk Unique Id' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = '123456'
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'MBR'
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Get-Volume
            Mock -CommandName Add-PartitionAccessPath
        }

        It 'Should throw DiskAlreadyInitializedError' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 'TESTDISKUNIQUEID'
                    DiskIdType = 'UniqueId'
                    AccessPath = 'c:\TestAccessPath'
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DiskAlreadyInitializedError -f 'UniqueId', $testParams.DiskId, 'MBR'
                )

                { Set-TargetResource @testParams } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 0 -Scope It
        }
    }

    Context 'When using online MBR disk specified by Disk Guid' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = '123456'
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'MBR'
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName Get-Partition
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Get-Volume
            Mock -CommandName Add-PartitionAccessPath
        }

        It 'Should throw DiskAlreadyInitializedError' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId     = 123456
                    DiskIdType = 'Guid'
                    AccessPath = 'c:\TestAccessPath'
                }

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.DiskAlreadyInitializedError -f 'Guid', $testParams.DiskId, 'MBR'
                )

                { Set-TargetResource @testParams } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 0 -Scope It
        }
    }

    Context 'When using online GPT disk with partition/volume already assigned and NoDefaultDriveLetter set to False specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $true
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                }
            }

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Add-PartitionAccessPath
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 0 -Scope It
        }
    }

    Context 'When using online GPT disk containing matching partition but not assigned specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                }
            }

            Mock -CommandName Add-PartitionAccessPath
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                    Size                 = 1GB
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using online GPT disk containing matching partition but not assigned with no size parameter specified with NoDefaultDriveLetter set to False' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $false
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                }
            }

            Mock -CommandName Add-PartitionAccessPath
            Mock -CommandName Set-Partition

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using online GPT disk with correct partition/volume but wrong Volume Label assigned specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Test-AccessPathInPSDrive
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $true
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                }
            }

            Mock -CommandName Set-Volume

            # mocks that should not be called
            Mock -CommandName Set-Disk
            Mock -CommandName Initialize-Disk
            Mock -CommandName New-Partition
            Mock -CommandName Format-Volume
            Mock -CommandName Add-PartitionAccessPath
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                    FSLabel              = 'NewLabel'
                }

                { Set-TargetResource @testParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-AccessPathInPSDrive -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Initialize-Disk -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Format-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Set-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-PartitionAccessPath -Exactly -Times 0 -Scope It
        }
    }
}

Describe 'DSC_DiskAccessPath\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Get-CimInstance -MockWith {
            [PSCustomObject] @{
                BlockSize = 4096
            }
        }
    }
    Context 'When using disk not initialized specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Partition
            Mock -CommandName Get-Volume
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    AccessPath         = 'c:\TestAccessPath'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When using disk not initialized specified by Disk Unique Id' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 'TESTDISKUNIQUEID'
                    DiskIdType         = 'UniqueId'
                    AccessPath         = 'c:\TestAccessPath'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When using disk not initialized specified by Disk Guid' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = '9c428290-42a7-41f1-9f8a-d6e32d5170a5'
                    IsOffline      = $true
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = '9c428290-42a7-41f1-9f8a-d6e32d5170a5'
                    DiskIdType         = 'Guid'
                    AccessPath         = 'c:\TestAccessPath'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When using disk read only specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $true
                    PartitionStyle = 'GPT'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    AccessPath         = 'c:\TestAccessPath'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When using online unformatted disk specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = ''
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'Raw'
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
            Mock -CommandName Get-Partition
            Mock -CommandName Get-CimInstance
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId             = 1
                    AccessPath         = 'c:\TestAccessPath'
                    AllocationUnitSize = 4096
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When using mismatching partition size specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $true
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                    AllocationUnitSize   = 4096
                    Size                 = 124
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using mismatched AllocationUnitSize specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $true
                }
            }

            # mocks that should not be called
            Mock -CommandName Get-Volume
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                    AllocationUnitSize   = 4097
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw

                <#
                    Mismatching AllocationUnitSize should not trigger a change until
                    AllowDestructive and ClearDisk switches implemented. See:
                    https://github.com/PowerShell/StorageDsc/issues/200
                    Until implemented this test should return true.
                #>
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using mismatching FSFormat specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $true
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                    FSFormat             = 'ReFS'
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using mismatching FSLabel specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $true
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                    FSLabel              = 'NewLabel'
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using mismatching NoDefaultDriveLetter specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $false
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                    FSLabel              = 'myLabel'
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using all disk properties matching specified by Disk Number' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\TestAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $true
                }
            }

            Mock -CommandName Get-Volume -MockWith {
                [PSCustomObject] @{
                    FileSystemLabel = 'myLabel'
                    FileSystem      = 'NTFS'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                    AllocationUnitSize   = 4096
                    Size                 = 1GB
                    FSFormat             = 'NTFS'
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the disk does not exist' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier
            Mock -CommandName Get-Partition
            Mock -CommandName Get-Volume
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                    AllocationUnitSize   = 4096
                    Size                 = 1GB
                    FSFormat             = 'NTFS'
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the access path is not found' {
        BeforeAll {
            Mock -CommandName Assert-AccessPathValid -MockWith {
                'c:\TestAccessPath\'
            }

            Mock -CommandName Get-DiskByIdentifier -MockWith {
                [PSCustomObject] @{
                    Number         = 1
                    UniqueId       = 'TESTDISKUNIQUEID'
                    Guid           = [guid]::NewGuid()
                    IsOffline      = $false
                    IsReadOnly     = $false
                    PartitionStyle = 'GPT'
                }
            }

            Mock -CommandName Get-Partition -MockWith {
                [PSCustomObject] @{
                    AccessPaths          = @(
                        '\\?\Volume{2d313fdd-e4a4-4f31-9784-dad758e0030f}\'
                        'c:\BadAccessPath\'
                    )
                    Size                 = 1GB
                    PartitionNumber      = 1
                    Type                 = 'Basic'
                    NoDefaultDriveLetter = $true
                }
            }

            Mock -CommandName Get-Volume
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    DiskId               = 1
                    AccessPath           = 'c:\TestAccessPath'
                    NoDefaultDriveLetter = $true
                    AllocationUnitSize   = 4096
                    Size                 = 1GB
                    FSFormat             = 'NTFS'
                }

                $result = Test-TargetResource @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Assert-AccessPathValid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DiskByIdentifier -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Partition -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Volume -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 0 -Scope It
        }
    }
}

Describe 'DSC_DiskAccessPath\Test-AccessPathInPSDrive' -Tag 'Helper' {
    Context 'When the access path is found' {
        BeforeAll {
            Mock -CommandName Get-PSDrive -MockWith {
                @(
                    [PSCustomObject] @{
                        Name = 'C'
                    }
                )
            } -ParameterFilter {
                $Name -eq 'c:\TestAccessPath'.Split(':')[0]
            }

            Mock -CommandName Get-PSDrive -ParameterFilter {
                $null -eq $Name
            }

        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    AccessPath = 'c:\TestAccessPath'
                }

                $result = Test-AccessPathInPSDrive @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Get-PSDrive -ParameterFilter {
                $Name -eq 'c:\TestAccessPath'.Split(':')[0]
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Get-PSDrive -ParameterFilter {
                $null -eq $Name
            } -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the access path is not found in the PSDrive list and not found after refresh' {
        BeforeAll {
            Mock -CommandName Get-PSDrive -MockWith {
                throw 'Cannot find drive.'
            } -ParameterFilter {
                $Name -eq 'c:\TestAccessPath'.Split(':')[0]
            }

            Mock -CommandName Get-PSDrive -ParameterFilter {
                $null -eq $Name
            }
        }

        It 'Should the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    AccessPath = 'c:\TestAccessPath'
                }

                $result = Test-AccessPathInPSDrive @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Get-PSDrive -ParameterFilter {
                $Name -eq 'c:\TestAccessPath'.Split(':')[0]
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Get-PSDrive -ParameterFilter {
                $null -eq $Name
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the access path is not found in the PSDrive list but is found after refresh' {
        BeforeAll {
            Mock -CommandName Get-PSDrive -MockWith {
                throw 'Cannot find drive.'
            } -ParameterFilter {
                $Name -eq 'c:\TestAccessPath'.Split(':')[0]
            }

            Mock -CommandName Get-PSDrive -MockWith {
                @(
                    [PSCustomObject] @{
                        Name = 'C'
                    }
                )
            } -ParameterFilter {
                $null -eq $Name
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParams = @{
                    AccessPath = 'c:\TestAccessPath'
                }

                $result = Test-AccessPathInPSDrive @testParams

                { $result } | Should -Not -Throw
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Get-PSDrive -ParameterFilter {
                $Name -eq 'c:\TestAccessPath'.Split(':')[0]
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Get-PSDrive -ParameterFilter {
                $null -eq $Name
            } -Exactly -Times 1 -Scope It
        }
    }
}
