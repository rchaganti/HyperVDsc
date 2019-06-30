#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psd1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable localizedData -filename VMNetworkAdapterVlan.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable localizedData -filename VMNetworkAdapterVlan.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the VMNetworkAdapterVlan resource.

.DESCRIPTION
Gets the current state of the VMNetworkAdapterVlan resource.

.PARAMETER Id
Specifies an unique identifier for the resource instance.

.PARAMETER Name
Specifies the name of the VM Network adapter for which the VLAN configuration needs to be done.

.PARAMETER VMName
Specifies the VM Name to which the VM network adapter is connected. 
Specify ManagementOS as the VM name if you want configure an adapter connected to host OS.
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
        [String] $VMName        
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }

    $configuration = @{
        Id = $Id
        Name = $Name
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
    }

    try {
        Write-Verbose $localizedData.GetVMNetAdapter
        $adapterExists = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue

        if ($adapterExists)
        {
            Write-Verbose $localizedData.FoundVMNetAdapter
            $configuration.Add('AdapterMode',$adapterExists.VlanSetting.OperationMode)
            $configuration.Add('VlanId',$adapterExists.VlanSetting.AccessVlanId)
            $configuration.Add('NativeVlanId',$adapterExists.VlanSetting.NativeVlanId)
            $configuration.Add('PrimaryVlanId',$adapterExists.VlanSetting.PrimaryVlanId)
            $configuration.Add('SecondaryVlanId',$adapterExists.VlanSetting.SecondaryVlanId)
            $configuration.Add('SecondaryVlanIdList',$adapterExists.VlanSetting.SecondaryVlanIdListString)
            $configuration.Add('AllowedVlanIdList',$adapterExists.VlanSetting.AllowedVlanIdListString)
        }
    } 
    catch
    {
        Write-Error $_
    }

    return $configuration
}

<#
.SYNOPSIS
Sets the VMNetworkAdapterVlan resource to a desired state.

.DESCRIPTION
Sets the VMNetworkAdapterVlan resource to a desired state.s

.PARAMETER Id
Specifies an unique identifier for the resource instance.

.PARAMETER Name
Specifies the name of the VM Network adapter for which the VLAN configuration needs to be done.

.PARAMETER VMName
Specifies the VM Name to which the VM network adapter is connected. 
Specify ManagementOS as the VM name if you want configure an adapter connected to host OS.

.PARAMETER AdapterMode
Specifies type of VLAN. Allowed values are "Untagged","Access","Trunk","Community","Isolated","Promiscuous".
Default value is Untagged.

.PARAMETER VlanId
Specifies the VLAN ID that needs to be configured on the VM network adapter.
Not valid when AdapterMode set to Untagged.

.PARAMETER NativeVlanId
Specifies the native VLAN ID that needs to be configured on the VM network adapter.
Valid only when AdapterMode set to Trunk.

.PARAMETER AllowedVlanIdList
Specifies the VLAN ID list that needs to be configured on the VM network adapter.
Valid only when AdapterMode set to Trunk.

.PARAMETER PrimaryVlanId
Specifies the primary VLAN ID that needs to be configured on the VM network adapter.
Valid only when AdapterMode set to Community or Isolated or Promiscuous.

.PARAMETER SecondaryVlanId
Specifies the secondary VLAN ID that needs to be configured on the VM network adapter.
Valid only when AdapterMode set to Community or Isolated or Promiscuous.

.PARAMETER SecondaryVlanIdList
Specifies the primary VLAN ID list that needs to be configured on the VM network adapter.
Valid only when AdapterMode set to Community or Isolated or Promiscuous.
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
        [String] $VMName,

        [Parameter()]
        [ValidateSet('Untagged','Access','Trunk','Community','Isolated','Promiscuous')]
        [String] $AdapterMode = 'Untagged',

        [Parameter()]
        [uint32] $VlanId,

        [Parameter()]
        [uint32] $NativeVlanId,

        [Parameter()]
        [String] $AllowedVlanIdList,
        
        [Parameter()]
        [uint32] $PrimaryVlanId,

        [Parameter()]
        [uint32] $SecondaryVlanId,

        [Parameter()]
        [String] $SecondaryVlanIdList
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
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
    }

    try 
    {
        Write-Verbose $localizedData.GetVMNetAdapter
        $adapterExists = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue
        if ($adapterExists) 
        {
            Write-Verbose $localizedData.FoundVMNetAdapter
            $setArguments = $arguments
            $setArguments.Remove('Name')
            $setArguments.Add('VMNetworkAdapterName',$Name)
            switch ($AdapterMode) 
            {
                'Untagged' 
                {
                    $setArguments.Add('Untagged',$true)
                    break
                }
    
                'Access' 
                {
                    $setArguments.Add('Access',$true)
                    $setArguments.Add('VlanId',$VlanId)
                    break
                }
    
                'Trunk' 
                {
                    $setArguments.Add('Trunk',$true)
                    $setArguments.Add('NativeVlanId',$NativeVlanId)
                    if ($AllowedVlanIdList) 
                    {
                        $setArguments.Add('AllowedVlanIdList',$AllowedVlanIdList)
                    }
                    break
                }
    
                'Community' 
                {
                    $setArguments.Add('Community',$true)
                    $setArguments.Add('PrimaryVlanId',$PrimaryVlanId)
                    if ($SecondaryVlanId) 
                    {
                        $setArguments.Add('SecondaryVlanId',$SecondaryVlanId)
                    }
                    break
                }
    
                'Isolated' 
                {
                    $setArguments.Add('Isolated',$true)
                    $setArguments.Add('PrimaryVlanId',$PrimaryVlanId)
                    if ($SecondaryVlanId) 
                    {
                        $setArguments.Add('SecondaryVlanId',$SecondaryVlanId)
                    }
                    break
                }
    
                'Promiscuous' 
                {
                    $setArguments.Add('Promiscuous',$true)
                    $setArguments.Add('PrimaryVlanId', $PrimaryVlanId)
                    if ($SecondaryVlanIdList) 
                    {
                        $setArguments.Add('SecondaryVlanIdList', $SecondaryVlanIdList)
                    }
                    break
                }
            }
            Write-Verbose $localizedData.PerformVMVlanSet
            Set-VMNetworkAdapterVlan @setArguments -ErrorAction Stop
        }
        else 
        {
            throw $localizedData.NoVMNetAdapterFound
        }
    }
    catch 
    {
        Write-Error $_
    }
}

<#
.SYNOPSIS
Tests if the VMNetworkAdapterVlan resource is in desired state.

.DESCRIPTION
Tests if VMNetworkAdapterVlan resource is in desired state.

.PARAMETER Id
Specifies an unique identifier for the resource instance.

.PARAMETER Name
Specifies the name of the VM Network adapter for which the VLAN configuration needs to be done.

.PARAMETER VMName
Specifies the VM Name to which the VM network adapter is connected. 
Specify ManagementOS as the VM name if you want configure an adapter connected to host OS.

.PARAMETER AdapterMode
Specifies type of VLAN. Allowed values are "Untagged","Access","Trunk","Community","Isolated","Promiscuous".
Default value is Untagged.

.PARAMETER VlanId
Specifies the VLAN ID that needs to be configured on the VM network adapter.
Not valid when AdapterMode set to Untagged.

.PARAMETER NativeVlanId
Specifies the native VLAN ID that needs to be configured on the VM network adapter.
Valid only when AdapterMode set to Trunk.

.PARAMETER AllowedVlanIdList
Specifies the VLAN ID list that needs to be configured on the VM network adapter.
Valid only when AdapterMode set to Trunk.

.PARAMETER PrimaryVlanId
Specifies the primary VLAN ID that needs to be configured on the VM network adapter.
Valid only when AdapterMode set to Community or Isolated or Promiscuous.

.PARAMETER SecondaryVlanId
Specifies the secondary VLAN ID that needs to be configured on the VM network adapter.
Valid only when AdapterMode set to Community or Isolated or Promiscuous.

.PARAMETER SecondaryVlanIdList
Specifies the primary VLAN ID list that needs to be configured on the VM network adapter.
Valid only when AdapterMode set to Community or Isolated or Promiscuous.
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
        [String] $VMName,

        [Parameter()]
        [ValidateSet('Untagged','Access','Trunk','Community','Isolated','Promiscuous')]
        [String] $AdapterMode = 'Untagged',

        [Parameter()]
        [uint32] $VlanId,

        [Parameter()]
        [uint32] $NativeVlanId,

        [Parameter()]
        [String] $AllowedVlanIdList,
        
        [Parameter()]
        [uint32] $PrimaryVlanId,

        [Parameter()]
        [uint32] $SecondaryVlanId,

        [Parameter()]
        [String] $SecondaryVlanIdList
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
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
    }
    
    switch ($AdapterMode) 
    {
        'Untagged' 
        {
            if ($VlanId -or $NativeVlanId -or $PrimaryVlanId -or $SecondaryVlanId -or $AllowedVlanIdList -or $SecondaryVlanIdList) 
            {
                Write-Verbose $localizedData.IgnoreVlan
            }
            break
        }

        'Access' 
        {
            if (-not $VlanId)
            {
                throw $localizedData.VlanIdRequiredInAccess
            }
            break
        }

        'Trunk' 
        {
            if (-not $NativeVlanId) 
            {
                throw $localizedData.MustProvideNativeVlanId
            }
            break
        }

        'Community' 
        {
            if (-not $PrimaryVlanId) 
            {
                throw $localizedData.PrimaryVlanIdRequired    
            }
            break
        }

        'Isolated' 
        {
            if (-not $PrimaryVlanId)
            {
                throw $localizedData.PrimaryVlanIdRequired
            }
            break
        }

        'Promiscuous' 
        {
            if (-not $PrimaryVlanId) 
            {
                throw $localizedData.PrimaryVlanIdRequired
            }
            break
        }
    }

    try 
    {
        #There is a remote timing issue that occurs when VLAN is set just after creating a VM Adapter. This needs more investigation. Sleep until then.
        #Start-Sleep -Seconds 10
        Write-Verbose $localizedData.GetVMNetAdapter
        $adapterExists = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue
    
        if ($adapterExists) 
        {
            Write-Verbose $localizedData.FoundVMNetAdapter
            if ($adapterExists.VlanSetting.OperationMode -eq $AdapterMode) 
            {
                switch ($adapterExists.VlanSetting.OperationMode) 
                {
                    'Access' 
                    {
                        if ($VlanId -ne $adapterExists.VlanSetting.AccessVlanId) 
                        {
                            Write-Verbose $localizedData.AccessVlanMustChange
                            return $false
                        } 
                        else 
                        {
                            Write-Verbose $localizedData.AdaptersExistsWithVlan
                            return $true
                        }
                        break
                    }

                    'Trunk' 
                    {
                        if ($NativeVlanId -ne $adapterExists.VlanSetting.NativeVlanId) 
                        {
                            Write-Verbose $localizedData.NativeVlanMustChange
                            return $false
                        } 
                        elseif ($AllowedVlanIdList -ne $AdapterMode.VlanSetting.AllowedVlanIdListString) 
                        {
                            Write-Verbose $localizedData.AllowedVlanListMustChange
                            return $false
                        } 
                        else 
                        {
                            Write-Verbose $localizedData.AdaptersExistsWithVlan
                            return $true
                        }
                        break
                    }

                    'Untagged' 
                    {
                        if ($AdapterMode -eq 'Untagged') 
                        {
                            Write-Verbose $localizedData.AdaptersExistsWithVlan
                            Write-Verbose $localizedData.IgnoreVlan
                            return $true
                        }
                        break
                    }

                    ('Community' -or 'isolated') 
                    {
                        if ($PrimaryVlanId -ne $adapterExists.VlanSetting.PrimaryVlanId) 
                        {
                            Write-Verbose $localizedData.PrimaryVlanMustChange
                            return $false
                        } 
                        elseif ($SecondaryVlanId -ne $adapterExists.VlanSetting.SecondaryVlanId) 
                        {
                            Write-Verbose $localizedData.SecondaryVlanMustChange
                            return $false
                        } 
                        else 
                        {
                            Write-Verbose $localizedData.AdaptersExistsWithVlan
                            return $true
                        }
                        break
                    }

                    'Promiscuous' 
                    {
                        if ($PrimaryVlanId -ne $adapterExists.VlanSetting.PrimaryVlanId) 
                        {
                            Write-Verbose $localizedData.PrimaryVlanMustChange
                            return $false
                        } 
                        elseif ($SecondaryVlanIdList -ne $adapterExists.VlanSetting.SecondaryVlanIdListString) 
                        {
                            Write-Verbose $localizedData.SecondaryVlanListMustChange
                            return $false
                        } 
                        else 
                        {
                            Write-Verbose $localizedData.AdaptersExistsWithVlan
                            return $true
                        }
                    }
                }
            } 
            else 
            {
                Write-Verbose $localizedData.AdapterExistsWithDifferentVlanMode
                return $false
            }
        }
        else 
        {
            throw $localizedData.VMNetAdapterDoesNotExist
        }
    }
    catch 
    {
        Write-Error $_
    }
}

Export-ModuleMember -Function *-TargetResource
