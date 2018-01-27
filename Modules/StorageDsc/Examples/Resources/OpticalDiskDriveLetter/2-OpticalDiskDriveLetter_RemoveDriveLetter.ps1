<#
    .EXAMPLE
        This configuration will remove the drive letter of the first
        optical disk drive.
#>
Configuration Example
{
    Import-DSCResource -ModuleName StorageDsc

    Node localhost
    {
        OpticalDiskDriveLetter RemoveFirstOpticalDiskDriveLetter
        {
            DiskId      = 1
            DriveLetter = 'X' # This value is ignored
            Ensure      = 'Absent'
        }
    }
}
