#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename VMNetworkAdapterSettings.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename VMNetworkAdapterSettings.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the VMNetworkAdapterSettings resource.

.DESCRIPTION
Gets the current state of the VMNetworkAdapterSettings resource.

.PARAMETER Id
Specifies a unique string to identify the VMNetworkAdapterSettings resource.

.PARAMETER Name
Specifies the Name of the VM network adapter for which the settings must be configured.

.PARAMETER SwitchName
Specifies the Name of the VM switch to which the the VM network adapter is connected.

.PARAMETER VMName
Specifies the name of the VM to which the VM network adapter is attached.
Specify the value as ManagementOS to configure VM network adapter settings in host OS.
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

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.HyperVModuleNotFound
    }

    $configuration = @{
        Id = $Id
        Name = $Name
        SwitchName = $SwitchName
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

    Write-Verbose $localizedData.GetVMNetAdapter
    $netAdapter = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue

    if ($netAdapter)
    {
        Write-Verbose $localizedData.FoundVMNetAdapter
        $configuration.Add('MacAddressSpoofing', $netAdapter.MacAddressSpoofing)
        $configuration.Add('DhcpGuard', $netAdapter.DhcpGuard)
        $configuration.Add('RouterGuard', $netAdapter.RouterGuard)
        $configuration.Add('AllowTeaming', $netAdapter.AllowTeaming)
        $configuration.Add('VmqWeight', $netAdapter.VmqWeight)
        $configuration.Add('MaximumBandwidth',$netAdapter.BandwidthSetting.MaximumBandwidth)
        $configuration.Add('MinimumBandwidthWeight',$netAdapter.BandwidthSetting.MinimumBandwidthWeight)
        $configuration.Add('MinimumBandwidthAbsolute',$netAdapter.BandwidthSetting.MinimumBandwidthAbsolute)
        $configuration.Add('IeeePriorityTag',$netAdapter.IeeePriorityTag)
        $configuration.Add('PortMirroring',$netAdapter.PortMirroringMode)
        $configuration.Add('DeviceNaming',$netAdapter.DeviceNaming)
    }
    else
    {
        Write-Warning $localizedData.NoVMNetAdapterFound
    }

    return $configuration
}

<#
.SYNOPSIS
Gets the current state of the VMNetworkAdapterSettings resource.

.DESCRIPTION
Gets the current state of the VMNetworkAdapterSettings resource.

.PARAMETER Id
Specifies a unique string to identify the VMNetworkAdapterSettings resource.

.PARAMETER Name
Specifies the Name of the VM network adapter for which the settings must be configured.

.PARAMETER SwitchName
Specifies the Name of the VM switch to which the the VM network adapter is connected.

.PARAMETER VMName
Specifies the name of the VM to which the VM network adapter is attached.
Specify the value as ManagementOS to configure VM network adapter settings in host OS.

.PARAMETER MacAddressSpoofing
Specifies if MAC Address spoofing should be enabled or not. The valid values are On and Off. Default value is Off.

.PARAMETER DhcpGuard
Specifies if DHCP guard should be enabled or not. The valid values are On and Off. Default value is Off.

.PARAMETER IeeePriorityTag
Specifies if IeeePriorityTag should be enabled or not. The valid values are On and Off. Default value is Off.

.PARAMETER RouterGuard
Specifies if RouterGuard should be enabled or not. The valid values are On and Off. Default value is Off.

.PARAMETER AllowTeaming
Specifies if AllowTeaming should be enabled or not. The valid values are On and Off. Default value is Off.

.PARAMETER DeviceNaming
Specifies if DeviceNaming should be enabled or not. The valid values are On and Off. Default value is On.

.PARAMETER MaximumBandwidth
Specifies the Maximum Bandwidth Setting on the VM network adapter. Default is 0.

.PARAMETER MinimumBandwidthWeight
Specifies the Minimum Bandwidth Weight Setting on the VM network adapter. Default is 0.

.PARAMETER MinimumBandwidthAbsolute
Specifies the Minimum Bandwidth Absolute Setting on the VM network adapter.

.PARAMETER VmqWeight
Specifies the VMQ Weight Setting on the VM network adapter. Default is 100.

.PARAMETER PortMirroring
Specifies if port mirroring is enabled or not. Valid values are None, Source, and Destination. Default value is None.
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
        [ValidateSet('On','Off')]
        [String] $MacAddressSpoofing = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $DhcpGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $IeeePriorityTag = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $RouterGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $AllowTeaming = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $DeviceNaming = 'On',

        [Parameter()]
        [uint64] $MaximumBandwidth = 0,

        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $MinimumBandwidthWeight = 0,

        [Parameter()]
        [uint32] $MinimumBandwidthAbsolute,
        
        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $VmqWeight = 100,        

        [Parameter()]
        [ValidateSet('None','Source','Destination')]
        [String] $PortMirroring = 'None'
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
        $arguments.Add('SwitchName', $SwitchName)
    }
    
    Write-Verbose $localizedData.GetVMNetAdapter
    $netAdapter = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue

    $setArguments = @{
        VMNetworkAdapter = $netAdapter
        MacAddressSpoofing = $MacAddressSpoofing
        DhcpGuard = $DhcpGuard
        RouterGuard = $RouterGuard
        VmqWeight = $VmqWeight
        MaximumBandwidth = $MaximumBandwidth
        MinimumBandwidthWeight = $MinimumBandwidthWeight
        MinimumBandwidthAbsolute= $MinimumBandwidthAbsolute
        IeeePriorityTag = $IeeePriorityTag
        AllowTeaming = $AllowTeaming
        PortMirroring = $PortMirroring
        DeviceNaming = $DeviceNaming
    }
    
    Write-Verbose $localizedData.PerformVMNetModify
    Set-VMNetworkAdapter @setArguments -ErrorAction Stop
}

<#
.SYNOPSIS
Tests if the VMNetworkAdapterSettings resource is in desired state.

.DESCRIPTION
Tests if the VMNetworkAdapterSettings resource is in desired state.

.PARAMETER Id
Specifies a unique string to identify the VMNetworkAdapterSettings resource.

.PARAMETER Name
Specifies the Name of the VM network adapter for which the settings must be configured.

.PARAMETER SwitchName
Specifies the Name of the VM switch to which the the VM network adapter is connected.

.PARAMETER VMName
Specifies the name of the VM to which the VM network adapter is attached.
Specify the value as ManagementOS to configure VM network adapter settings in host OS.

.PARAMETER MacAddressSpoofing
Specifies if MAC Address spoofing should be enabled or not. The valid values are On and Off. Default value is Off.

.PARAMETER DhcpGuard
Specifies if DHCP guard should be enabled or not. The valid values are On and Off. Default value is Off.

.PARAMETER IeeePriorityTag
Specifies if IeeePriorityTag should be enabled or not. The valid values are On and Off. Default value is Off.

.PARAMETER RouterGuard
Specifies if RouterGuard should be enabled or not. The valid values are On and Off. Default value is Off.

.PARAMETER AllowTeaming
Specifies if AllowTeaming should be enabled or not. The valid values are On and Off. Default value is Off.

.PARAMETER DeviceNaming
Specifies if DeviceNaming should be enabled or not. The valid values are On and Off. Default value is On.

.PARAMETER MaximumBandwidth
Specifies the Maximum Bandwidth Setting on the VM network adapter. Default is 0.

.PARAMETER MinimumBandwidthWeight
Specifies the Minimum Bandwidth Weight Setting on the VM network adapter. Default is 0.

.PARAMETER MinimumBandwidthAbsolute
Specifies the Minimum Bandwidth Absolute Setting on the VM network adapter.

.PARAMETER VmqWeight
Specifies the VMQ Weight Setting on the VM network adapter. Default is 100.

.PARAMETER PortMirroring
Specifies if port mirroring is enabled or not. Valid values are None, Source, and Destination. Default value is None.
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
        [ValidateSet('On','Off')]
        [String] $MacAddressSpoofing = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $DhcpGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $IeeePriorityTag = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $RouterGuard = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $AllowTeaming = 'Off',

        [Parameter()]
        [ValidateSet('On','Off')]
        [String] $DeviceNaming = 'On',

        [Parameter()]
        [uint64] $MaximumBandwidth = 0,

        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $MinimumBandwidthWeight = 0,

        [Parameter()]
        [uint32] $MinimumBandwidthAbsolute,
        
        [Parameter()]
        [ValidateRange(0,100)]
        [uint32] $VmqWeight = 100,        

        [Parameter()]
        [ValidateSet('None','Source','Destination')]
        [String] $PortMirroring = 'None'
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
        $arguments.Add('SwitchName', $SwitchName)
    }
    
    Write-Verbose $localizedData.GetVMNetAdapter
    $adapterExists = Get-VMNetworkAdapter @arguments -ErrorAction SilentlyContinue
    
    if ($adapterExists) 
    {
        Write-Verbose $localizedData.FoundVMNetAdapter
        if ($adapterExists.MacAddressSpoofing -eq $MacAddressSpoofing `
            -and $adapterExists.RouterGuard -eq $RouterGuard `
            -and $adapterExists.DhcpGuard -eq $DhcpGuard `
            -and $adapterExists.IeeePriorityTag -eq $IeeePriorityTag `
            -and $adapterExists.AllowTeaming -eq $AllowTeaming `
            -and $adapterExists.BandwidthSetting.MaximumBandwidth -eq $MaximumBandwidth `
            -and $adapterExists.BandwidthSetting.MinimumBandwidthWeight -eq $MinimumBandwidthWeight `
            -and $adapterExists.BandwidthSetting.MinimumBandwidthAbsolute -eq $MinimumBandwidthAbsolute `
            -and $adapterExists.VMQWeight -eq $VMQWeight `
            -and $adapterExists.PortMirroringMode -eq $PortMirroring `
            -and $adapterExists.DeviceNaming -eq $DeviceNaming
        )
        {
            Write-Verbose $localizedData.VMNetAdapterExistsNoActionNeeded
            return $true
        } 
        else 
        {
            Write-Verbose $localizedData.VMNetAdapterExistsWithDifferentConfiguration
            return $false
        }
    } 
    else 
    {
        throw $localizedData.VMNetAdapterDoesNotExist
    }
}

Export-ModuleMember -Function *-TargetResource
