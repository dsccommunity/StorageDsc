<#
    .EXAMPLE
        This configuration will set the drive letter of the CD to 'Z'.
#>
Configuration Example
{

    Import-DSCResource -ModuleName xStorage

    Node localhost
    {
        xCDROM MapCDROMToZ
        {
             DriveLetter = "Z"
        }
    }
}
