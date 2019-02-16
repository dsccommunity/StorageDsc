@{
    # Script module or binary module file associated with this manifest.
    # RootModule = ''

    # Version number of this module.
    moduleVersion     = '4.5.0.0'

    # ID used to uniquely identify this module
    GUID              = '00d73ca1-58b5-46b7-ac1a-5bfcf5814faf'

    # Author of this module
    Author            = 'Microsoft Corporation'

    # Company or vendor of this module
    CompanyName       = 'Microsoft Corporation'

    # Copyright statement for this module
    Copyright         = '(c) Microsoft Corporation. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'This module contains all resources related to the PowerShell Storage module, or pertaining to disk management.'

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
    FunctionsToExport = @()

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

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
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/PowerShell/StorageDsc/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/PowerShell/StorageDsc'

            # A URL to an icon representing this module.
            # IconUri = ''

<<<<<<< HEAD
        # ReleaseNotes of this module
        ReleaseNotes = '- Opt-in to Example publishing to PowerShell Gallery - fixes [Issue 186](https://github.com/PowerShell/StorageDsc/issues/186).
- DiskAccessPath:
  - Updated the resource to not assign a drive letter by default when adding
    a disk access path. Adding a Set-Partition -NoDefaultDriveLetter
    $NoDefaultDriveLetter block defaulting to true.
    When adding access paths the disks will no longer have
    drive letters automatically assigned on next reboot which is the desired
    behavior - Fixes [Issue 145](https://github.com/PowerShell/StorageDsc/issues/145).
=======
            # ReleaseNotes of this module
            ReleaseNotes = '- Refactored module folder structure to move resource to root folder of
  repository and remove test harness - fixes [Issue 169](https://github.com/PowerShell/StorageDsc/issues/169).
- Updated Examples to support deployment to PowerShell Gallery scripts.
- Removed limitation on using Pester 4.0.8 during AppVeyor CI.
- Moved the Code of Conduct text out of the README.md and into a
  CODE\_OF\_CONDUCT.md file.
- Explicitly removed extra hidden files from release package
>>>>>>> Clean up Module Manifest

'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
<<<<<<< HEAD















=======
>>>>>>> Clean up Module Manifest
