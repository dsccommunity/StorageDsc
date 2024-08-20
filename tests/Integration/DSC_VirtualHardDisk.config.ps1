$TestFixedVirtualHardDiskVhd = @{
    FilePath   = "$($pwd.drive.name):\newTestFixedVhd.vhd"
    DiskSize   = 5GB
    DiskFormat = 'Vhd'
    DiskType = 'Fixed'
}

$TestDynamicVirtualHardDiskVhdx = @{
    FilePath   = "$($pwd.drive.name):\newTestDynamicVhdx.vhdx"
    DiskSize   = 10GB
    DiskFormat = 'Vhdx'
    DiskType = 'Dynamic'
}

configuration DSC_VirtualHardDisk_CreateAndAttachFixedVhd_Config {
    Import-DscResource -ModuleName StorageDsc
    node localhost {
        VirtualHardDisk Integration_Test {
                FilePath   = $TestFixedVirtualHardDiskVhd.FilePath
                DiskSize   = $TestFixedVirtualHardDiskVhd.DiskSize
                DiskFormat = $TestFixedVirtualHardDiskVhd.DiskFormat
                DiskType = $TestFixedVirtualHardDiskVhd.DiskType
                Ensure = 'Present'
            }
    }
}

configuration DSC_VirtualHardDisk_CreateAndAttachDynamicallyExpandingVhdx_Config {
    Import-DscResource -ModuleName StorageDsc
    node localhost {

        VirtualHardDisk Integration_Test {
                FilePath   = $TestDynamicVirtualHardDiskVhdx.FilePath
                DiskSize   = $TestDynamicVirtualHardDiskVhdx.DiskSize
                DiskFormat = $TestDynamicVirtualHardDiskVhdx.DiskFormat
                DiskType = $TestDynamicVirtualHardDiskVhdx.DiskType
                Ensure = 'Present'
            }
    }
}
