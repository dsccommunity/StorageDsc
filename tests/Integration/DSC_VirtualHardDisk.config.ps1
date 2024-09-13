$TestFixedVirtualHardDiskVhdPath = "$($pwd.drive.name):\newTestFixedVhd.vhd"
$TestDynamicVirtualHardDiskVhdx = "$($pwd.drive.name):\newTestDynamicVhdx.vhdx"

configuration DSC_VirtualHardDisk_CreateAndAttachFixedVhd_Config {
    Import-DscResource -ModuleName StorageDsc
    node localhost {
        VirtualHardDisk Integration_Test {
            FilePath   = $TestFixedVirtualHardDiskVhdPath
            DiskSize   = 5GB
            DiskFormat = 'Vhd'
            DiskType   = 'Fixed'
            Ensure     = 'Present'
        }
    }
}

configuration DSC_VirtualHardDisk_CreateAndAttachDynamicallyExpandingVhdx_Config {
    Import-DscResource -ModuleName StorageDsc
    node localhost {
        VirtualHardDisk Integration_Test {
            FilePath   = $TestDynamicVirtualHardDiskVhdx
            DiskSize   = 10GB
            DiskFormat = 'Vhdx'
            DiskType   = 'Dynamic'
            Ensure     = 'Present'
        }
    }
}
