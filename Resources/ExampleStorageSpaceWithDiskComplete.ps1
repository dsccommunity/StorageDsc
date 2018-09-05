Configuration SPWithDisk
{

    Import-DSCResource -ModuleName xStorage

    StoragePool SP_Test
    {
        FriendlyName = 'SP_Test'
        NumberOfDisks = 2
    }

    VirtualDisk VD_Test
    {
        FriendlyName = 'VD_Test'
        StoragePoolFriendlyName =  'SP_Test'
        ResiliencySettingName = 'Mirror'
        DependsOn = '[StoragePool]SP_Test'
    }

    cDisk 'F'
    {
        DiskFriendlyName = 'VD_Test'
        DriveLetter =  'F'
        DependsOn = '[VirtualDisk]VD_Test'
    }
}

$MOFPath = 'C:\MOF'
If (!(Test-Path $MOFPath)){New-Item -Path $MOFPath -ItemType Directory}
SPWithDisk -OutputPath $MOFPath
Start-DscConfiguration -Path $MOFPath -Wait -Force -Verbose
