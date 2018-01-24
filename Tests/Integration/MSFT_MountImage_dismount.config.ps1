configuration MSFT_MountImage_Dismount_Config {

    Import-DscResource -ModuleName StorageDsc

    node localhost {
        xMountImage Integration_Test {
            ImagePath          = $Node.ImagePath
            Ensure             = 'Absent'
        }
    }
}
