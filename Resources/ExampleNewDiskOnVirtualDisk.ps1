Configuration NewDiskOnVirtualDisk
{

    Import-DSCResource -ModuleName xStorage

    xDisk 'E'
    {
        Disk = 'VD_Test'
        DriveLetter =  'E'
    }
}

$MOFPath = 'C:\Support\MOF'
If (!(Test-Path $MOFPath)){New-Item -Path $MOFPath -ItemType Directory}
NewDiskOnVirtualDisk -OutputPath $MOFPath
Start-DscConfiguration -Path $MOFPath -Wait -Force -Verbose