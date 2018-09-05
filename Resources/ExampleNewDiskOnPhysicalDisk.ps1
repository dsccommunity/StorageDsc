Configuration NewDiskOnPhysicalDisk
{

    Import-DSCResource -ModuleName xStorage

    xDisk 'E'
    {
        DiskNumber = 1
        DriveLetter =  'E'
    }
}

$MOFPath = 'C:\MOF'
If (!(Test-Path $MOFPath)){New-Item -Path $MOFPath -ItemType Directory}
NewDiskOnPhysicalDisk -OutputPath $MOFPath
Start-DscConfiguration -Path $MOFPath -Wait -Force -Verbose
