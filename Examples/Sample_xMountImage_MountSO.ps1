# This configuration will mount an ISO file as drive S:.
configuration Sample_xMountImage_MountISO
{
    Import-DscResource -ModuleName xStorage
    xMountImage ISO
    {
        ImagePath   = 'c:\Sources\SQL.iso'
        DriveLetter = 'S'
    }
}

Sample_xMountImage_MountISO
Start-DscConfiguration -Path Sample_xMountImage_MountISO -Wait -Force -Verbose
