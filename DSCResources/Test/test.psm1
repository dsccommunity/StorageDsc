function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [String] $FriendlyName,

        [parameter(Mandatory)]
        [String] $StoragePoolFriendlyName,

        [UInt32] $Size = 0,

        [ValidateSet('Thin','Fixed')]
        [String] $ProvisioningType = 'Fixed',

        [ValidateSet('Simple','Mirror','Parity')]
        [String] $ResiliencySettingName = 'Mirror',

        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )
}