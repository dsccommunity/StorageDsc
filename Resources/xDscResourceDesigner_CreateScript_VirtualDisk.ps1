$modules = 'C:\Program Files\WindowsPowerShell\Modules\'
$modulename = 'xStorage'
$Description = 'This module is used to create a VirtualDisk on an existing StoragePool. Functionality is limited to create and COMPLETE destroy.'

if (!(test-path (join-path $modules $modulename))) {

    $modulefolder = mkdir (join-path $modules $modulename)
    New-ModuleManifest -Path (join-path $modulefolder "$modulename.psd1") -Guid $([system.guid]::newguid().guid) -Author 'Peppe Kerstens' -CompanyName 'ITON Services BV' -Copyright '2016' -ModuleVersion '0.1.0.0' -Description $Description -PowerShellVersion '5.0'

    $standard = @{ModuleName = $modulename
                ClassVersion = '0.1.0.0'
                Path = $modules
                }
    $P = @()
    $P += New-xDscResourceProperty -Name FriendlyName -Type String -Attribute Key -Description 'Specifies the name of the VirtualDisk te be created'
    $P += New-xDscResourceProperty -Name StoragePoolFriendlyName -Type String -Attribute Key -Description 'Specifies the StorageSpace on which the VirtualDisk has to be placed'
    $P += New-xDscResourceProperty -Name Size -Type Uint32 -Attribute Write -Description "Specifies the size of the disk (in GB)"
    $P += New-xDscResourceProperty -Name ProvisioningType -Type String -Attribute Write -ValidateSet 'Thin','Fixed' -Description "ProvisioningType of the VirtualDisk. If omitted, defaults to Fixed"
    $P += New-xDscResourceProperty -Name ResiliencySettingName -Type String -Attribute Write -ValidateSet 'Simple','Mirror','Parity' -Description "Resiliency setting of the VirtualDisk. If omitted, defaults to Mirror"
    $P += New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet 'Present','Absent' -Description 'Determines whether the setting should be applied or removed'
    New-xDscResource -Name VirtualDisk -Property $P -FriendlyName VirtualDisk @standard
}
