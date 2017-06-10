Configuration MSFT_xCDROM_config {

    Import-DSCResource -ModuleName xStorage

    node localhost {
        xCDROM Integration_Test
        {
             DriveLetter = "Z"
        }
    }
}
