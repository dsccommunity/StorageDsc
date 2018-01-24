<#
    .EXAMPLE
        This configuration will set the drive letter of the optical disk drive to 'Z'.
#>
Configuration Example
{

    Import-DSCResource -ModuleName StorageDsc

    Node localhost
    {
        OpticalDiskDriveLetter MapOpticalDiskToZ
        {
             DriveLetter = 'Z'
        }
    }
}
