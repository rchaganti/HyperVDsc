#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psd1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename VMHostLiveMigration.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename VMHostLiveMigration.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the VMHostLiveMigration resource.

.DESCRIPTION
Gets the current state of the VMHostLiveMigration resource.

.PARAMETER IsSingleInstance
Specifies if this resource instance is a single instance.
The value to this parameter should always be Yes.

.PARAMETER VirtualMachineMigrationEnabled
Specifies if live migration settings are enabled or not.
This is a boolean value and must be specified in a configuration.

.PARAMETER UseAnyNetworkForMigration
Specifies if all networks are enabled for live migration.
This is a boolean value and must be specified in a configuration.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $VirtualMachineMigrationEnabled
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    Write-Verbose -Message $localizedData.GetVMMigration
    $vmHostSettings = Get-VMHost

    $configuration = @{
        IsSingleInstance = $IsSingleInstance
        VirtualMachineMigrationEnabled = $vmHostSettings.VirtualMachineMigrationEnabled
        UseAnyNetworkForMigration = $vmHostSettings.UseAnyNetworkForMigration
        VirtualMachineMigrationAuthenticationType = $vmHostSettings.VirtualMachineMigrationAuthenticationType
        MaximumVirtualMachineMigrations = $vmHostSettings.MaximumVirtualMachineMigrations
    }

    return $configuration
}

<#
.SYNOPSIS
Sets the VMHostLiveMigration resource to desired state.

.DESCRIPTION
Sets the VMHostLiveMigration resource to desired state.

.PARAMETER IsSingleInstance
Specifies if this resource instance is a single instance.
The value to this parameter should always be Yes.
This is the key property.

.PARAMETER VirtualMachineMigrationEnabled
Specifies if live migration settings are enabled or not.
This is a boolean value and must be specified in a configuration.

.PARAMETER UseAnyNetworkForMigration
Specifies if all networks are enabled for live migration.
This is a boolean value and default value is True.

.PARAMETER VirtualMachineMigrationAuthenticationType
Specifies the authentication method for live migrations.
The valid values are Kerberos and CredSSP. Default value is CredSSP.

.PARAMETER MaximumVirtualMachineMigrations
Specifies the maximum number of concurrent live migrations.
Default value is 2.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $VirtualMachineMigrationEnabled,

        [Parameter()]
        [Boolean]
        $UseAnyNetworkForMigration,

        [Parameter()]
        [String]
        [ValidateSet('Kerberos','CredSSP')]
        $VirtualMachineMigrationAuthenticationType = 'CredSSP',

        [Parameter()]
        [UInt32]
        $MaximumVirtualMachineMigrations = 2
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    Write-Verbose -Message $localizedData.GetVMMigration
    $vmHostSettings = Get-VMHost

    #Parameter checks; this can go into a common function later [TODO]
    if ($VirtualMachineMigrationEnabled)
    {
        if (-not ($vmHostSettings.VirtualMachineMigrationEnabled))
        {
            Write-Verbose -Message $localizedData.EnableVMLiveMigration
            Enable-VMMigration -Verbose
        }
        
        if ($UseAnyNetworkForMigration -and -not ($vmHostSettings.UseAnyNetworkForMigration))
        {
            Write-Verbose -Message $localizedData.SetAnyNetworkForLiveMigration
            Set-VM
        }

    }

}

<#
.SYNOPSIS
Tests if the VMHostLiveMigration resource is in desired state or not.

.DESCRIPTION
Tests if the VMHostLiveMigration resource is in desired state or not.

.PARAMETER IsSingleInstance
Specifies if this resource instance is a single instance.
The value to this parameter should always be Yes.

.PARAMETER VirtualMachineMigrationEnabled
Specifies if live migration settings are enabled or not.
This is a boolean value and must be specified in a configuration.

.PARAMETER UseAnyNetworkForMigration
Specifies if all networks are enabled for live migration.
This is a boolean value and default value is True.

.PARAMETER VirtualMachineMigrationAuthenticationType
Specifies the authentication method for live migrations.
The valid values are Kerberos and CredSSP. Default value is CredSSP.

.PARAMETER MaximumVirtualMachineMigrations
Specifies the maximum number of concurrent live migrations.
Default value is 2.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [Boolean]
        $VirtualMachineMigrationEnabled,

        [Parameter()]
        [Boolean]
        $UseAnyNetworkForMigration = $true,

        [Parameter()]
        [String]
        [ValidateSet('Kerberos','CredSSP')]
        $VirtualMachineMigrationAuthenticationType = 'CredSSP',

        [Parameter()]
        [UInt32]
        $MaximumVirtualMachineMigrations = 2
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    Write-Verbose -Message $localizedData.GetVMMigration
    $vmHostSettings = Get-VMHost

    if ($vmHostSettings.VirtualMachineMigrationEnabled)
    {
        if ($VirtualMachineMigrationEnabled)
        {
            Write-Verbose -Message $localizedData.VMLMEnabled

            #Check if other properties match. Start with Authentication Type.
            if ($VirtualMachineMigrationAuthenticationType -ne $vmHostSettings.VirtualMachineMigrationAuthenticationType)
            {
                Write-Verbose -Message $localizedData.AuthenticationTypeMismatch
                return $false
            }

            #Check if network settings are matching
            if ($UseAnyNetworkForMigration -ne $vmHostSettings.UseAnyNetworkForMigration)
            {
                Write-Verbose -Message $localizedData.UseAnyNetworkNotMatching
                return $false
            }

            if ($MaximumVirtualMachineMigrations -ne $vmHostSettings.MaximumVirtualMachineMigrations)
            {
                Write-Verbose -Message $localizedData.concurrentMigrationsNotMatching
                return $false
            }
            
            Write-Verbose -Message $localizedData.MigrationConfigurationExistNoAction
            return $true
        }
        else
        {
            Write-Verbose -Message $localizedData.VMMigrationNeedsToBeDisabled
            return $false
        }
    }
    else
    {
        if ($VirtualMachineMigrationEnabled)
        {
            Write-Verbose -Message $localizedData.VMMigrationShouldBeEnabled
            return $false
        }
        else
        {
            Write-Verbose -Message $localizedData.MigrationConfigurationExistNoAction
            return $true
        }
    }
}

Export-ModuleMember -Function *-TargetResource
