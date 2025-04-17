$script:dscResourceCommonModulePath = Join-Path -Path $PSScriptRoot -ChildPath '../DscResource.Common'

Import-Module -Name $script:dscResourceCommonModulePath

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
