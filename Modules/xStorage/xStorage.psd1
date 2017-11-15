#
# Module manifest for module 'xStorage'
#
# Generated on: 6/14/2015
#

@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '3.3.0.0'

# ID used to uniquely identify this module
GUID = '00d73ca1-58b5-46b7-ac1a-5bfcf5814faf'

# Author of this module
Author = 'PowerShell DSC'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '2017'

# Description of the functionality provided by this module
Description = 'This module contains all resources related to the PowerShell Storage module, or pertaining to disk management.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/xStorage/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xStorage'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '- Opted into common tests for Module and Script files - See [Issue 115](https://github.com/PowerShell/xStorage/issues/115).
- xDisk:
  - Added support for Guid Disk Id type - See [Issue 104](https://github.com/PowerShell/xStorage/issues/104).
  - Added parameter AllowDestructive - See [Issue 11](https://github.com/PowerShell/xStorage/issues/11).
  - Added parameter ClearDisk - See [Issue 50](https://github.com/PowerShell/xStorage/issues/50).
- xDiskAccessPath:
  - Added support for Guid Disk Id type - See [Issue 104](https://github.com/PowerShell/xStorage/issues/104).
- xWaitForDisk:
  - Added support for Guid Disk Id type - See [Issue 104](https://github.com/PowerShell/xStorage/issues/104).
- Added .markdownlint.json file to configure markdown rules to validate.
- Clean up Badge area in README.MD - See [Issue 110](https://github.com/PowerShell/xStorage/issues/110).
- Disabled MD013 rule checking to enable badge table.
- Added .github support files:
  - CONTRIBUTING.md
  - ISSUE_TEMPLATE.md
  - PULL_REQUEST_TEMPLATE.md
- Changed license year to 2017 and set company name to Microsoft
  Corporation in LICENSE.MD and module manifest - See [Issue 111](https://github.com/PowerShell/xStorage/issues/111).
- Set Visual Studio Code setting "powershell.codeFormatting.preset" to
  "custom" - See [Issue 108](https://github.com/PowerShell/xStorage/issues/108)
- Added `Documentation and Examples` section to Readme.md file - see
  [issue 116](https://github.com/PowerShell/xStorage/issues/116).
- Prevent unit tests from DSCResource.Tests from running during test
  execution - fixes [Issue 118](https://github.com/PowerShell/xStorage/issues/118).

'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}








