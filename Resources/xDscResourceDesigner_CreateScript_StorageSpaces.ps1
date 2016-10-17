$modules = 'C:\Program Files\WindowsPowerShell\Modules\'
$modulename = 'xStorage'
$Description = 'This module is used to create a StorageSpace. Functionality is limited to create, add a disk to existing, a rename of existing and COMPLETE destroy. It can only filter on disk size and/or numberofdisks'

if (!(test-path (join-path $modules $modulename))) {

    $modulefolder = mkdir (join-path $modules $modulename)
    New-ModuleManifest -Path (join-path $modulefolder "$modulename.psd1") -Guid $([system.guid]::newguid().guid) -Author 'Peppe Kerstens' -CompanyName 'ITON Services BV' -Copyright '2016' -ModuleVersion '0.1.0.0' -Description $Description -PowerShellVersion '5.0'

    $standard = @{ModuleName = $modulename
                ClassVersion = '0.1.0.0'
                Path = $modules
                }
    $P = @()
    $P += New-xDscResourceProperty -Name FriendlyName -Type String -Attribute Key -Description 'This setting provides a unique name for the configuration'
    $P += New-xDscResourceProperty -Name NewFriendlyName -Type String -Attribute Write -Description 'Specifies the new name of an existing StorageSpace configuration'
    $P += New-xDscResourceProperty -Name NumberOfDisks -Type Uint32 -Attribute Write -Description "Specifies the number of disks to be added, adds any 'canpool' disk"
    $P += New-xDscResourceProperty -Name DriveSize -Type Uint32 -Attribute Write -Description "Specifies the size of the disk to filter on in the 'canpool' collection."
    $P += New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet 'Present','Absent' -Description 'Determines whether the setting should be applied or removed'
    New-xDscResource -Name StorageSpaces -Property $P -FriendlyName StorageSpaces @standard
}
