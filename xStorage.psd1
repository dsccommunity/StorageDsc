#
# Module manifest for module 'xStorage'
#
# Generated on: 6/14/2015
#

@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '2.8.0.0'

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
        ReleaseNotes = '* added test for existing file system and no drive letter assignment to allow simple drive letter assignment in MSFT_xDisk.psm1
* added unit test for volume with existing partition and no drive letter assigned for MSFT_xDisk.psm1
* xMountImage: Fixed mounting disk images on Windows 10 Anniversary Edition
* Updated to meet HQRM guidelines.
* Moved all strings into localization files.
* Fixed examples to import xStorage module.
* Fixed Readme.md layout issues.
* xWaitForDisk:
  - Added support for setting DriveLetter parameter with or without colon.
  - MOF Class version updated to 1.0.0.0.
* xWaitForVolume:
  - Added new resource.
* StorageCommon:
  - Added helper function module.
  - Corrected name of unit tests file.
* xDisk:
  - Added validation of DriveLetter parameter.
  - Added support for setting DriveLetter parameter with or without colon.
  - Removed obfuscation of drive/partition errors by eliminating try/catch block.
  - Improved code commenting.
  - Reordered tests so they are in same order as module functions to ease creation.
  - Added FSFormat parameter to allow disk format to be specified.
  - Size or AllocationUnitSize mismatches no longer trigger Set-TargetResource because these values can"t be changed (yet).
  - MOF Class version updated to 1.0.0.0.
  - Unit tests changed to match xDiskAccessPath methods.
  - Added additional unit tests to Get-TargetResource.
  - Fixed bug in Get-TargetResource when disk did not contain any partitions.
  - Added missing cmdletbinding() to functions.
* xMountImage (Breaking Change):
  - Removed Name parameter (Breaking Change)
  - Added validation of DriveLetter parameter.
  - Added support for setting DriveLetter parameter with or without colon.
  - MOF Class version updated to 1.0.0.0.
  - Enabled mounting of VHD/VHDx/VHDSet disk images.
  - Added StorageType and Access parameters to allow mounting VHD and VHDx disks as read/write.
* xDiskAccessPath:
  - Added new resource.
  - Added support for changing/setting volume label.

'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}



