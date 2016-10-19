Configuration StorageSpaces
{

    Import-DSCResource -ModuleName xStorage

    StoragePool SP_Test
    {
        FriendlyName = 'SP_Test'
        NumberOfDisks = 1
    }

    VirtualDisk VD_Test
    {
        FriendlyName = 'VD_Test'
        StoragePoolFriendlyName =  'SP_Test'
        ResiliencySettingName = 'Simple'
    }
}

$MOFPath = 'C:\MOF'
If (!(Test-Path $MOFPath)){New-Item -Path $MOFPath -ItemType Directory}
StorageSpaces -OutputPath $MOFPath
Start-DscConfiguration -Path $MOFPath  -Wait -Force -Verbose
    