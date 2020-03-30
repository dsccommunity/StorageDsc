configuration MSFT_MountImage_Mount_Config {

    Import-DscResource -ModuleName StorageDsc

    node localhost {
        MountImage Integration_Test {
            ImagePath          = $Node.ImagePath
            DriveLetter        = $Node.DriveLetter
            Ensure             = 'Present'
        }
    }
}
