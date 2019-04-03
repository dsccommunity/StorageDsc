@{
    # Script module or binary module file associated with this manifest.
    # RootModule = ''

    # Version number of this module.
    moduleVersion = '4.6.0.0'

    # ID used to uniquely identify this module
    GUID                 = '00d73ca1-58b5-46b7-ac1a-5bfcf5814faf'

    # Author of this module
    Author               = 'Microsoft Corporation'

    # Company or vendor of this module
    CompanyName          = 'Microsoft Corporation'

    # Copyright statement for this module
    Copyright            = '(c) Microsoft Corporation. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'This module contains all resources related to the PowerShell Storage module, or pertaining to disk management.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '4.0'

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
    FunctionsToExport    = @()

    # Cmdlets to export from this module
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @(
        'DiskAccessPath',
        'MountImage',
        'OpticalDiskDriveLetter',
        'WaitForDisk',
        'WaitForVolume',
        'Disk'
    )

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/PowerShell/StorageDsc/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/PowerShell/StorageDsc'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
        ReleaseNotes = '- Fix example publish to PowerShell Gallery by adding `gallery_api`
  environment variable to `AppVeyor.yml` - fixes [Issue 202](https://github.com/PowerShell/StorageDsc/issues/202).
- Added "DscResourcesToExport" to manifest to improve information in
  PowerShell Gallery and removed wildcards from "FunctionsToExport",
  "CmdletsToExport", "VariablesToExport" and "AliasesToExport" - fixes
  [Issue 192](https://github.com/PowerShell/StorageDsc/issues/192).
- Clean up module manifest to correct Author and Company - fixes
  [Issue 191](https://github.com/PowerShell/StorageDsc/issues/191).
- Correct unit tests for DiskAccessPath to test exact number of
  mocks called - fixes [Issue 199](https://github.com/PowerShell/StorageDsc/issues/199).
- Disk:
  - Added minimum timetowate of 3s after new-partition using the while loop.
    The problem occurs when the partition is created and the format-volume
    is attempted before the volume has completed.
    There appears to be no property to determine if the partition is
    sufficiently ready to format and it will often format as a raw volume when
    the error occurs - fixes [Issue 85](https://github.com/PowerShell/StorageDsc/issues/85).

'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}

