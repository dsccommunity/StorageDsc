Configuration NewDiskOnPhysicalDisk
{

    Import-DSCResource -ModuleName xStorage

    xDisk 'E'
    {
        Disk = 1
        DriveLetter =  'E'
    }
}

$MOFPath = 'C:\Support\MOF'
If (!(Test-Path $MOFPath)){New-Item -Path $MOFPath -ItemType Directory}
NewDiskOnPhysicalDisk -OutputPath $MOFPath
Start-DscConfiguration -Path $MOFPath -Wait -Force -Verbose