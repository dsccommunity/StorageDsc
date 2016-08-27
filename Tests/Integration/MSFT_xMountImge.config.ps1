configuration MSFT_xMountImage_Config {
    Import-DscResource -ModuleName xStorage
    node localhost {
        xMountImage Integration_Test {
            ImagePath          = $Node.ImagePath
            DriveLetter        = $Node.DriveLetter
            Ensure             = 'Present'
        }
    }
}
