# This configuration will unmount an ISO file that is mounted in S:.
configuration Sample_xMountImage_UnmountISO
{
    Import-DscResource -ModuleName xStorage
    xMountImage ISO
    {
        Name = 'SQL Disk'
        ImagePath = 'c:\Sources\SQL.iso'
        DriveLetter = 'S'
        Ensure = 'Absent'
    }
}

Sample_xMountImage_UnmountISO
Start-DscConfiguration -Path Sample_xMountImage_UnmountISO -Wait -Force -Verbose
