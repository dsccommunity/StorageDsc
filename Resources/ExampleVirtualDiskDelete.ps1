Configuration StorageSpaces
{

    Import-DSCResource -ModuleName xStorage

    VirtualDisk VD_Test
    {
        FriendlyName = 'VD_Test'
        StoragePoolFriendlyName =  'SP_Test'
        Ensure = 'Absent'
    }
}

$MOFPath = 'C:\MOF'
If (!(Test-Path $MOFPath)){New-Item -Path $MOFPath -ItemType Directory}
StorageSpaces -OutputPath $MOFPath
Start-DscConfiguration -Path $MOFPath -Wait -Force -Verbose
