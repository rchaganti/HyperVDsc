#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename VMNetworkAdapter.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename VMNetworkAdapter.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the VMNetworkAdapter resource.

.DESCRIPTION
Gets the current state of the VMNetworkAdapter resource.

.PARAMETER Id
Specifies a unique string to identify the VMNetworkAdapter resource instance.

.PARAMETER Name
Specifies the Name of the VM Network Adapter. 

.PARAMETER SwitchName
Specifies the name of the switch to which the VM Network adapter will be connected to.

.PARAMETER VMName
Specifies the name of the VM to which the adapter will be attached.
Specifying ManagementOS as value will attach to the Host OS.
#>
Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param (
        [Parameter(Mandatory)]
        [String] $Id, 

        [Parameter(Mandatory)]
        [String] $Name,        

        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [String] $VMName
    )

    $configuration = @{
        Id = $Id
        Name = $Name
        SwitchName = $SwitchName
        VMName = $VMName
    }

    $arguments = @{
        Name = $Name
    }

    if ($VMName -ne 'ManagementOS')
    {
        $arguments.Add('VMName',$VMName)
    }
    else
    {
        $arguments.Add('ManagementOS', $true)
        $arguments.Add('SwitchName', $SwitchName)
    }

    Write-Verbose -Message $localizedData.GetVMNetAdapter
    $netAdapter = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue

    if ($netAdapter)
    {
        Write-Verbose $localizedData.FoundVMNetAdapter
        if ($VMName -eq 'ManagementOS')
        {
            $configuration.Add('MacAddress', $netAdapter.MacAddress)
            $configuration.Add('DynamicMacAddress', $false)
        }
        elseif ($netAdapter.VMName)
        {
            $configuration.Add('MacAddress', $netAdapter.MacAddress)   
            $configuration.Add('DynamicMacAddress', $netAdapter.DynamicMacAddressEnabled)
        }
        $configuration.Add('Ensure','Present')
    }
    else
    {
        Write-Verbose -Message $localizedData.NoVMNetAdapterFound
        $configuration.Add('Ensure','Absent')
    }

    return $configuration
}

<#
.SYNOPSIS
Sets the VMNetworkAdapter resource to a specified desired state.

.DESCRIPTION
Sets the VMNetworkAdapter resource to a specified desired state.

.PARAMETER Id
Specifies a unique string to identify the VMNetworkAdapter resource instance.

.PARAMETER Name
Specifies the Name of the VM Network Adapter. 

.PARAMETER SwitchName
Specifies the name of the switch to which the VM Network adapter will be connected to.

.PARAMETER VMName
Specifies the name of the VM to which the adapter will be attached.
Specifying ManagementOS as value will attach to the Host OS.

.PARAMETER MacAddress
Specifies the static MAC Address that must be configured on the network adapter.

.PARAMETER Ensure
Specifies if the VM Network adapter should be Present or Absent. Default is Present.
#>
Function Set-TargetResource
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String] $Id, 

        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter()]
        [String] $MacAddress,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure='Present'
    )

    $arguments = @{
        Name = $Name
    }

    if ($VMName -ne 'ManagementOS')
    {
        $arguments.Add('VMName',$VMName)
    }
    else
    {
        $arguments.Add('ManagementOS', $true)
        $arguments.Add('SwitchName', $SwitchName)
    }
    
    Write-Verbose $localizedData.GetVMNetAdapter
    $netAdapterExists = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue
    
    if ($Ensure -eq 'Present')
    {
        if ($netAdapterExists)
        {
            Write-Verbose $localizedData.FoundVMNetAdapter
            if (($VMName -ne 'ManagementOS'))
            {
                if ($MacAddress)
                {
                    if ($netAdapterExists.DynamicMacAddressEnabled)
                    {
                        Write-Verbose -Message $localizedData.EnableStaticMacAddress
                        $updateMacAddress = $true
                    }
                    elseif ($MacAddress -ne $netAdapterExists.StaicMacAddress)
                    {
                        Write-Verbose -Message $localizedData.EnableStaticMacAddress
                        $updateMacAddress = $true
                    }
                }
                else
                {
                    if (-not $netAdapterExists.DynamicMacAddressEnabled)
                    {
                        Write-Verbose $localizedData.EnableDynamicMacAddress
                        $updateMacAddress = $true
                    }
                }
                
                if ($netAdapterExists.SwitchName -ne $SwitchName)
                {
                    Write-Verbose $localizedData.PerformSwitchConnect
                    Connect-VMNetworkAdapter -VMNetworkAdapter $netAdapterExists -SwitchName $SwitchName -ErrorAction Stop -Verbose
                }
                
                if (($updateMacAddress))
                {
                    Write-Verbose $localizedData.PerformVMNetModify

                    $setArguments = @{ }
                    $setArguments.Add('VMNetworkAdapter',$netAdapterExists)
                    if ($MacAddress)
                    {
                        $setArguments.Add('StaticMacAddress',$MacAddress)
                    }
                    else
                    {
                        $setArguments.Add('DynamicMacAddress', $true)
                    }
                    Set-VMNetworkAdapter @setArguments -ErrorAction Stop
                }
            }
        }
        else
        {
            if ($VMName -ne 'ManagementOS')
            {
                if (-not $MacAddress)
                {
                    $arguments.Add('DynamicMacAddress',$true)
                }
                else
                {
                    $arguments.Add('StaticMacAddress',$MacAddress)
                }
                $arguments.Add('SwitchName',$SwitchName)
            }
            Write-Verbose $localizedData.AddVMNetAdapter
            Add-VMNetworkAdapter @arguments -ErrorAction Stop
        }
    }
    else
    {
        Write-Verbose $localizedData.RemoveVMNetAdapter
        Remove-VMNetworkAdapter @arguments -ErrorAction Stop
    }
}

<#
.SYNOPSIS
Tests if the VMNetworkAdapter resource is in desired state.

.DESCRIPTION
Tests if the VMNetworkAdapter resource is in desired state.

.PARAMETER Id
Specifies a unique string to identify the VMNetworkAdapter resource instance.

.PARAMETER Name
Specifies the Name of the VM Network Adapter. 

.PARAMETER SwitchName
Specifies the name of the switch to which the VM Network adapter will be connected to.

.PARAMETER VMName
Specifies the name of the VM to which the adapter will be attached.
Specifying ManagementOS as value will attach to the Host OS.

.PARAMETER MacAddress
Specifies the static MAC Address that must be configured on the network adapter.

.PARAMETER Ensure
Specifies if the VM Network adapter should be Present or Absent. Default is Present.
#>
Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory)]
        [String] $Id, 
                
        [Parameter(Mandatory)]
        [String] $Name,

        [Parameter(Mandatory)]
        [String] $SwitchName,

        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter()]
        [String] $MacAddress,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure='Present'
    )

    $arguments = @{
        Name = $Name
    }

    if ($VMName -ne 'ManagementOS')
    {
        $arguments.Add('VMName',$VMName)
    }
    else
    {
        $arguments.Add('ManagementOS', $true)
        $arguments.Add('SwitchName', $SwitchName)
    }
    
    Write-Verbose $localizedData.GetVMNetAdapter
    $netAdapterExists = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue

    if ($Ensure -eq 'Present')
    {
        if ($netAdapterExists)
        {
            if ($VMName -ne 'ManagementOS')
            {
                if ($MacAddress)
                {
                    if ($netAdapterExists.DynamicMacAddressEnabled)
                    {
                        Write-Verbose $localizedData.EnableStaticMacAddress
                        return $false
                    }
                    elseif ($netAdapterExists.MacAddress -ne $MacAddress)
                    {
                        Write-Verbose $localizedData.StaticAddressDoesNotMatch
                        return $false
                    }
                }
                else
                {
                    if (-not $netAdapterExists.DynamicMacAddressEnabled)
                    {
                        Write-Verbose $localizedData.EnableDynamicMacAddress
                        return $false
                    }
                } 
                
                if ($netAdapterExists.SwitchName -ne $SwitchName)
                {
                    Write-Verbose $localizedData.SwitchIsDifferent
                    return $false
                } 
                else
                {
                    Write-Verbose $localizedData.VMNetAdapterExistsNoActionNeeded
                    return $true
                }
            }
            else
            {
                Write-Verbose $localizedData.VMNetAdapterExistsNoActionNeeded
                return $true
            }
        } 
        else
        {
            Write-Verbose $localizedData.VMNetAdapterDoesNotExistShouldAdd
            return $false
        }
    }
    else
    {
        if ($netAdapterExists)
        {
            Write-Verbose $localizedData.VMNetAdapterExistsShouldRemove
            return $false
        }
        else
        {
            Write-Verbose $localizedData.VMNetAdapterDoesNotExistNoActionNeeded
            return $true
        }
    }
}

Export-ModuleMember -Function *-TargetResource
