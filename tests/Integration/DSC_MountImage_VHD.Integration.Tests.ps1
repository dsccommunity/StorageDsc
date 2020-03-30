#region HEADER
$script:dscModuleName = 'StorageDsc'
$script:dscResourceName = 'DSC_MountImage'

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
    # Get a spare drive letter
    $LastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
    $DriveLetter = [char](([int][char]$LastDrive)+1)

    # Create a VHD with a partition
    $VHDPath = Join-Path -Path $ENV:Temp `
        -ChildPath 'TestDisk.vhd'
    $null = New-VDisk -Path $VHDPath -SizeInMB 1024
    $null = Mount-DiskImage -ImagePath $VHDPath
    $diskImage = Get-DiskImage -ImagePath $VHDPath
    $disk = Get-Disk -Number $diskImage.Number
    $null = $disk | Initialize-Disk -PartitionStyle GPT
    $partition = $disk | New-Partition -UseMaximumSize
    $null = $partition | Get-Volume | Format-Volume -FileSystem NTFS -Confirm:$false
    $null = Dismount-Diskimage -ImagePath $VHDPath

    # Create a config data object to pass to the DSC Configs
    $ConfigData = @{
        AllNodes = @(
            @{
                NodeName    = 'localhost'
                ImagePath   = $VHDPath
                DriveLetter = $DriveLetter
            }
        )
    }

    # Mount VHD
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_mount.config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:dscResourceName)_MountVHD_Integration" {
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

    # Dismount VHD
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName)_dismount.config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:dscResourceName)_DismountVHD_Integration" {
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

    # Delete the VHD test file created
    Remove-Item -Path $VHDPath -Force
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
