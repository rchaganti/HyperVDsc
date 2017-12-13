#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psd1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename VMIntegrationService.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename VMIntegrationService.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the VMIntegrationService resource.

.DESCRIPTION
Gets the current state of the VMIntegrationService resource.

.PARAMETER VMName
Specifies the VM for which the the intergration service state needs to be retrieved.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [System.String]
        $VMName
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    Write-Verbose -Message $localizedData.GetVM
    $vm = Get-VM -Name $VMName 
            
    if ($vm)
    {
        $configuration = @{
            VMName = $VMName
        }

        Write-Verbose -Message $localizedData.GetVMIntegrationService
        $vmIntegrationService = $vm.VMIntegrationService
        $configuration.Add('GuestServiceInterfaceEnabled', $vmIntegrationService.Where({$_.Name -eq 'Guest Service Interface'}).Enabled)
        $configuration.Add('HeartbeatEnabled', $vmIntegrationService.Where({$_.Name -eq 'Heartbeat'}).Enabled)
        $configuration.Add('KVPExchangeEnabled', $vmIntegrationService.Where({$_.Name -eq 'Key-Value Pair Exchange'}).Enabled)
        $configuration.Add('ShutdownEnabled', $vmIntegrationService.Where({$_.Name -eq 'Shutdown'}).Enabled)
        $configuration.Add('TimeSynchronizationEnabled', $vmIntegrationService.Where({$_.Name -eq 'Time Synchronization'}).Enabled)
        $configuration.Add('VSSEnabled', $vmIntegrationService.Where({$_.Name -eq 'VSS'}).Enabled)
        return $configuration
    }
    else
    {
        throw $localizedData.NoVMFound    
    }
}

<#
.SYNOPSIS
Sets the VMIntegrationService resource to desired state.

.DESCRIPTION
Sets the VMIntegrationService resource to desired state.

.PARAMETER VMName
Specifies the VM for which the the intergration service state needs to be set into a desired state.

.PARAMETER GuestServiceInterfaceEnabled
Specifies if the Guest Service Interface should be enabled or disabled. This is a boolean property.

.PARAMETER HeartbeatEnabled
Specifies if the heartbeat should be enabled or disabled. This is a boolean property.

.PARAMETER KVPExchangeEnabled
Specifies if the Key-Value Pair Exchange should be enabled or disabled. This is a boolean property.

.PARAMETER ShutdownEnabled
Specifies if the shutdown should be enabled or disabled. This is a boolean property.

.PARAMETER TimeSynchronizationEnabled
Specifies if the Time Synchronization should be enabled or disabled. This is a boolean property.

.PARAMETER VSSEnabled
Specifies if the VSS should be enabled or disabled. This is a boolean property.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VMName,

        [Parameter()]
        [Boolean]
        $GuestServiceInterfaceEnabled = $false,

        [Parameter()]
        [Boolean]
        $HeartbeatEnabled = $true,

        [Parameter()]
        [Boolean]
        $KVPExchangeEnabled = $true,

        [Parameter()]
        [Boolean]
        $ShutdownEnabled = $true,

        [Parameter()]
        [Boolean]
        $TimeSynchronizationEnabled = $true,

        [Parameter()]
        [Boolean]
        $VSSEnabled = $true
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    Write-Verbose -Message $localizedData.GetVM
    $vm = Get-VM -Name $VMName

    if ($vm)
    {
        Write-Verbose -Message $localizedData.GetVMIntegrationService
        $vmIntegrationService = $vm.VMIntegrationService

        if ($GuestServiceInterfaceEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'Guest Service Interface'}).Enabled)
        {
            Write-Verbose -Message $localizedData.UpdateGSI
            Set-VMIntegrationService -VMName $VMName -IntegrationServiceName 'Guest Service Interface' -Enable $GuestServiceInterfaceEnabled -Verbose
        }

        if ($HeartbeatEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'Heartbeat'}).Enabled)
        {
            Write-Verbose -Message $localizedData.UpdateHB
            Set-VMIntegrationService -VMName $VMName -IntegrationServiceName 'Heartbeat' -Enable $HeartbeatEnabled -Verbose
        }

        if ($KVPExchangeEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'Key-Value Pair Exchange'}).Enabled)
        {
            Write-Verbose -Message $localizedData.UpdateKVP
            Set-VMIntegrationService -VMName $VMName -IntegrationServiceName 'Key-Value Pair Exchange' -Enable $KVPExchangeEnabled -Verbose
        }

        if ($ShutdownEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'Shutdown'}).Enabled)
        {
            Write-Verbose -Message $localizedData.UpdateShutdown
            Set-VMIntegrationService -VMName $VMName -IntegrationServiceName 'Shutdown' -Enable $ShutdownEnabled -Verbose
        }                    

        if ($TimeSynchronizationEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'Time Synchronization'}).Enabled)
        {
            Write-Verbose -Message $localizedData.UpdateTS
            Set-VMIntegrationService -VMName $VMName -IntegrationServiceName 'Time Synchronization' -Enable $TimeSynchronizationEnabled -Verbose
        }

        if ($VSSEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'VSS'}).Enabled)
        {
            Write-Verbose -Message $localizedData.UpdateVSS
            Set-VMIntegrationService -VMName $VMName -IntegrationServiceName 'VSS' -Enable $VSSEnabled -Verbose
        }
    }
    else
    {
        throw $localizedData.NoVMFound    
    }    
}

<#
.SYNOPSIS
Tests if the VMIntegrationService resource is in desired state.

.DESCRIPTION
Tests if the VMIntegrationService resource is in desired state.

.PARAMETER VMName
Specifies the VM for which the the intergration service state needs to be set into a desired state.

.PARAMETER GuestServiceInterfaceEnabled
Specifies if the Guest Service Interface should be enabled or disabled. This is a boolean property.

.PARAMETER HeartbeatEnabled
Specifies if the heartbeat should be enabled or disabled. This is a boolean property.

.PARAMETER KVPExchangeEnabled
Specifies if the Key-Value Pair Exchange should be enabled or disabled. This is a boolean property.

.PARAMETER ShutdownEnabled
Specifies if the shutdown should be enabled or disabled. This is a boolean property.

.PARAMETER TimeSynchronizationEnabled
Specifies if the Time Synchronization should be enabled or disabled. This is a boolean property.

.PARAMETER VSSEnabled
Specifies if the VSS should be enabled or disabled. This is a boolean property.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $VMName,

        [Parameter()]
        [Boolean]
        $GuestServiceInterfaceEnabled = $false,

        [Parameter()]
        [Boolean]
        $HeartbeatEnabled = $true,

        [Parameter()]
        [Boolean]
        $KVPExchangeEnabled = $true,

        [Parameter()]
        [Boolean]
        $ShutdownEnabled = $true,

        [Parameter()]
        [Boolean]
        $TimeSynchronizationEnabled = $true,

        [Parameter()]
        [Boolean]
        $VSSEnabled = $true        
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    Write-Verbose -Message $localizedData.GetVM
    $vm = Get-VM -Name $VMName

    if ($vm)
    {
        Write-Verbose -Message $localizedData.GetVMIntegrationService
        $vmIntegrationService = $vm.VMIntegrationService

        if ($GuestServiceInterfaceEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'Guest Service Interface'}).Enabled)
        {
            Write-Verbose -Message $localizedData.GSINotMatching
            return $false
        }

        if ($HeartbeatEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'Heartbeat'}).Enabled)
        {
            Write-Verbose -Message $localizedData.HBNotMatching
            return $false
        }

        if ($KVPExchangeEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'Key-Value Pair Exchange'}).Enabled)
        {
            Write-Verbose -Message $localizedData.KVPNotMatching
            return $false
        }

        if ($ShutdownEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'Shutdown'}).Enabled)
        {
            Write-Verbose -Message $localizedData.ShutdownNotMatching
            return $false
        }                    

        if ($TimeSynchronizationEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'Time Synchronization'}).Enabled)
        {
            Write-Verbose -Message $localizedData.TSNotMatching
            return $false
        }

        if ($VSSEnabled -ne $vmIntegrationService.Where({$_.Name -eq 'VSS'}).Enabled)
        {
            Write-Verbose -Message $localizedData.VSSNotMatching
            return $false
        }

        Write-Verbose -Message $localizedData.VMIntegrationServiceInDesiredState  
        return $true
    }
    else
    {
        throw $localizedData.NoVMFound    
    } 
}

Export-ModuleMember -Function *-TargetResource
