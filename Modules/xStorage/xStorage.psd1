#
# Module manifest for module 'xStorage'
#
# Generated on: 6/14/2015
#

@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '3.0.0.0'

# ID used to uniquely identify this module
GUID = '00d73ca1-58b5-46b7-ac1a-5bfcf5814faf'

# Author of this module
Author = 'PowerShell DSC'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '2015'

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
        ReleaseNotes = '- Converted AppVeyor build process to use AppVeyor.psm1.
- Added support for auto generating wiki, help files, markdown linting
  and checking examples.
- Correct name of MSFT_xDiskAccessPath.tests.ps1.
- Move shared modules into Modules folder.
- Fixed unit tests.
- Removed support for WMI cmdlets.
- Opted in to Markdown and Example tests.
- Added CodeCov.io support.
- Removed requirement on using Pester 3.4.6 because Pester bug fixed in 4.0.3.
- Fixed unit tests for MSFT_xDiskAccessPath resource to be compatible with
  Pester 4.0.3.
- xDisk:
  - BREAKING CHANGE: Renamed parameter DiskNumber to DiskId to enable it to
    contain either DiskNumber or UniqueId - See [Issue 81](https://github.com/PowerShell/xStorage/issues/81).
  - Added DiskIdType parameter to enable specifying the type of identifer
    the DiskId parameter contains - See [Issue 81](https://github.com/PowerShell/xStorage/issues/81).
  - Changed to use xDiskAccessPath pattern to fix issue with Windows Server
    2016 - See [Issue 80](https://github.com/PowerShell/xStorage/issues/80).
  - Fixed style violations in xDisk.
  - Fixed issue when creating multiple partitions on a single disk with no size
    specified - See [Issue 86](https://github.com/PowerShell/xStorage/issues/86).
- xDiskAccessPath:
  - BREAKING CHANGE: Renamed parameter DiskNumber to DiskId to
    enable it to contain either DiskNumber or UniqueId - See [Issue 81](https://github.com/PowerShell/xStorage/issues/81).
  - Added DiskIdType parameter to enable specifying the type
    of identifer the DiskId parameter contains - See [Issue 81](https://github.com/PowerShell/xStorage/issues/81).
  - Fixed incorrect logging messages when changing volume label.
  - Fixed issue when creating multiple partitions on a single disk with no size
    specified - See [Issue 86](https://github.com/PowerShell/xStorage/issues/86).
- xWaitForDisk:
  - BREAKING CHANGE: Renamed parameter DiskNumber to DiskId to
    enable it to contain either DiskNumber or UniqueId - See [Issue 81](https://github.com/PowerShell/xStorage/issues/81).
  - Added DiskIdType parameter to enable specifying the type
    of identifer the DiskId parameter contains - See [Issue 81](https://github.com/PowerShell/xStorage/issues/81).

'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}





