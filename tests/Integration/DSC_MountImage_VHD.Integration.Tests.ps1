[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'MountImage'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'StorageDsc'
    $script:dscResourceFriendlyName = 'MountImage'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Get a spare drive letter
    $LastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
    $script:DriveLetter = [char](([int][char]$LastDrive) + 1)

    # Create a VHD with a partition
    $script:VHDPath = Join-Path -Path $ENV:Temp -ChildPath 'TestDisk.vhd'
    $null = New-VDisk -Path $VHDPath -SizeInMB 1024
    $null = Mount-DiskImage -ImagePath $VHDPath
    $diskImage = Get-DiskImage -ImagePath $VHDPath
    $disk = Get-Disk -Number $diskImage.Number
    $null = $disk | Initialize-Disk -PartitionStyle GPT
    $partition = $disk | New-Partition -UseMaximumSize
    $null = $partition | Get-Volume | Format-Volume -FileSystem NTFS -Confirm:$false
    $null = Dismount-DiskImage -ImagePath $VHDPath

    # Create a config data object to pass to the DSC Configs
    $script:ConfigData = @{
        AllNodes = @(
            @{
                NodeName    = 'localhost'
                ImagePath   = $VHDPath
                DriveLetter = $DriveLetter
            }
        )
    }
}

AfterAll {
    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe "$($script:dscResourceName)_MountVHD_Integration" {
    BeforeAll {
        # Mount VHD
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_mount.config.ps1"
        . $configFile -Verbose -ErrorAction Stop
    }

    Context 'Mount an VHDX and assign a Drive Letter' {
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Mount_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $ConfigData
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Mount_Config"
            }

            $current.Imagepath        | Should -Be $VHDPath
            $current.DriveLetter      | Should -Be $DriveLetter
            $current.StorageType      | Should -Be 'VHD'
            $current.Access           | Should -Be 'ReadWrite'
            $current.Ensure           | Should -Be 'Present'
        }
    }
}

Describe "$($script:dscResourceName)_DismountVHD_Integration" {
    BeforeAll {
        # Dismount VHD
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_dismount.config.ps1"
        . $configFile -Verbose -ErrorAction Stop
    }

    AfterAll {
        # Delete the VHD test file created
        Remove-Item -Path $VHDPath -Force
    }

    Context 'Dismount a previously mounted ISO' {
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Dismount_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $ConfigData
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Dismount_Config"
            }

            $current.Imagepath        | Should -Be $VHDPath
            $current.Ensure           | Should -Be 'Absent'
        }
    }
}
