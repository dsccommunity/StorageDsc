Configuration StorageSpaces
{

    Import-DSCResource -ModuleName xStorage

    StoragePool SP_Test
    {
        FriendlyName = 'SP_Test'
        NumberOfDisks = 1
    }
}

$MOFPath = 'C:\MOF'
If (!(Test-Path $MOFPath)){New-Item -Path $MOFPath -ItemType Directory}
StorageSpaces -OutputPath $MOFPath
Start-DscConfiguration -Path $MOFPath -Wait -Force -Verbose

Start-Sleep -Seconds 10
Write-Host
Write-Host "Now adding disk...."
Write-Host

Configuration StorageSpacesAddDisk
{

    Import-DSCResource -ModuleName xStorage

    StoragePool SP_Test
    {
        FriendlyName = 'SP_Test'
        NumberOfDisks = 2
    }
}

$MOFPath = 'C:\MOF'
If (!(Test-Path $MOFPath)){New-Item -Path $MOFPath -ItemType Directory}
StorageSpacesAddDisk -OutputPath $MOFPath
Start-DscConfiguration -Path $MOFPath -Wait -Force -Verbose
