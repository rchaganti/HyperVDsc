@{
# Version number of this module.
ModuleVersion = '1.0.0.0'

# ID used to uniquely identify this module
GUID = '69ddfa32-e487-4757-b55b-af587de2460c'

# Author of this module
Author = 'Ravikanth Chaganti'

# Company or vendor of this module
CompanyName = 'PowerShell Magazine'

# Copyright statement for this module
Copyright = '(c) 2017 PowerShell Magazine. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Module with DSC Resources for Microsoft Hyper-V Host and Virtual Machine configurations.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource','Hyper-V','HyperV')

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rchaganti/DSCResources/HyperVDsc'

        # A URL to an icon representing this module.
        # IconUri = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable
}
