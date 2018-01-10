<#
    .EXAMPLE
        This configuration will set the drive letter of the first
        optical disk drive in the system to 'Y'. It will set the
        drive letter of the second optical disk drive to 'Z'. It
        will remove the drive letter from the third optical disk
        drive in the system.
#>
Configuration Example
{
    Import-DSCResource -ModuleName xStorage

    Node localhost
    {
        xOpticalDiskDriveLetter SetFirstOpticalDiskDriveLetterToY
        {
            DiskId      = 1
            DriveLetter = 'Y'
        }

        xOpticalDiskDriveLetter SetSecondOpticalDiskDriveLetterToZ
        {
            DiskId      = 2
            DriveLetter = 'Z'
        }

        xOpticalDiskDriveLetter RemoveThurdOpticalDiskDriveLetter
        {
            DiskId      = 3
            DriveLetter = 'A'
            Ensure      = 'Absent'
        }
    }
}
