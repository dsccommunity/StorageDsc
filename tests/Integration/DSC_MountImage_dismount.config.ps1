configuration MSFT_MountImage_Dismount_Config {

    Import-DscResource -ModuleName StorageDsc

    node localhost {
        MountImage Integration_Test {
            ImagePath          = $Node.ImagePath
            Ensure             = 'Absent'
        }
    }
}
