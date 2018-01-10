<#
    .EXAMPLE
        This configuration will remove the drive letter of the first
        optical disk drive.
#>
Configuration Example
{
    Import-DSCResource -ModuleName xStorage

    Node localhost
    {
        xOpticalDiskDriveLetter RemoveFirstOpticalDiskDriveLetter
        {
            DiskId      = 1
            DriveLetter = 'X' # This value is ignored
            Ensure      = 'Absent'
        }
    }
}
