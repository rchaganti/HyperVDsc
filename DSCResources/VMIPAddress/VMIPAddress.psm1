#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psd1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable localizedData -filename VMIPAddress.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable localizedData -filename VMIPAddress.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the VMIPAddress resource.

.DESCRIPTION
Gets the current state of the VMIPAddress resource.

.PARAMETER Id
Specifies the unique string for the VMIPAddress resource instance.

.PARAMETER VMName
Specifies the VM Name for which the IP Adddress needs to be configured.

.PARAMETER NetAdapterName
Specifies the VM Network adapter name for which the IP Address needs to be configured.

.PARAMETER IPAddress
Specifies the IP address of the VM Network adapter.

.PARAMETER Subnet
Specifies the Subnet of the VM Network adapter IP configuration.
#>
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (        
        [Parameter(Mandatory)]
        [String] $Id,

        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter(Mandatory)]
        [String] $NetAdapterName,

        [Parameter(Mandatory)]
        [String] $IPAddress,

        [Parameter(Mandatory)]
        [String]$Subnet
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }
    
    $configuration = @{
        Id = $Id
        VMName = $VMName
        NetAdapterName = $netAdapterName
    }
    
    Write-Verbose $localizedData.GetNetConfig
    $netAdapter = Get-VMNetworkConfiguration -vmName $VMName -netAdapterName $NetAdapterName -Verbose
    
    if (-not ($NetAdapter.Count -gt 1)) {
        $configuration.Add('IPAddress',$netAdapter.IPAddresses)
        $configuration.Add('Subnet',$netAdapter.Subnets)
        $configuration.Add('DefaultGateway',$netAdapter.DefaultGateways)
        $configuration.Add('DnsServer',$netAdapter.DnsServers)
    } else {
        throw $localizedData.MoreThanOneAdapter
    }
    
    return $configuration
}

<#
.SYNOPSIS
Sets the VMIPAddress resource to the specified desired state.

.DESCRIPTION
Sets the VMIPAddress resource to the specified desired state.

.PARAMETER Id
Specifies the unique string for the VMIPAddress resource instance.

.PARAMETER VMName
Specifies the VM Name for which the IP Adddress needs to be configured.

.PARAMETER NetAdapterName
Specifies the VM Network adapter name for which the IP Address needs to be configured.

.PARAMETER IPAddress
Specifies the IP address of the VM Network adapter. Setting this property to 'DHCP' will enable DHCP on the VM network adapter.

.PARAMETER Subnet
Specifies the Subnet of the VM Network adapter IP configuration.

.PARAMETER DefaultGateway
Specifies the DefaultGateway of the VM Network adapter IP configuration.

.PARAMETER DNSServer
Specifies the DNSServer of the VM Network adapter IP configuration.
#>
function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [String] $Id,

        [Parameter(Mandatory)]
        [String]$VMName,

        [Parameter(Mandatory)]
        [String]$NetAdapterName,

        [Parameter(Mandatory)]
        [String]$IPAddress,

        [Parameter(Mandatory)]
        [String]$Subnet,

        [Parameter()]
        [String]$DefaultGateway,

        [Parameter()]
        [String]$DNSServer
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }
    
    Write-Verbose $localizedData.GetNetAdapter
    $netAdapter = Get-VMNetworkAdapter -VMName $VMName -Name $NetAdapterName -ErrorAction SilentlyContinue
    if ($netAdapter -and $netAdapter.Count -eq 1) {
        if ($IPAddress -eq 'DHCP') {
            Write-Verbose $localizedData.SetNetConfigDHCP
            $arguments = @{
                'NetworkAdapterName' = $NetAdapterName
                'VmName' = $VMName
                'dhcp' = $true
            }
            $returnValue = Set-VMNetworkConfiguration @arguments -Verbose
            if ($returnValue) {
                Write-Verbose $localizedData.NetDHCPSuccess
            } else {
                throw $localizedData.NetDHCPFailure
            }
        } else {
            if (-not $Subnet) {
                
            } else {
                Write-Verbose $localizedData.SetNetConfigStatic
                $arguments = @{
                    'NetworkAdapterName' = $NetAdapterName
                    'VmName' = $VMName
                    'dhcp' = $false
                    'IPAddress' = $IPAddress
                    'Subnet' = $Subnet
                    'DefaultGateway' = $DefaultGateway
                    'DnsServer' = $DNSServer
                }
                $returnValue = Set-VMNetworkConfiguration @arguments -Verbose
                if ($returnValue) {
                    Write-Verbose $localizedData.NetStaticSuccess
                } else {
                    throw $localizedData.NetStaticFailure
                }
            }
        }
    }
}

<#
.SYNOPSIS
Tests if the VMIPAddress resource is in desired state.

.DESCRIPTION
Tests if the VMIPAddress resource is in desired state.

.PARAMETER Id
Specifies the unique string for the VMIPAddress resource instance.

.PARAMETER VMName
Specifies the VM Name for which the IP Adddress needs to be configured.

.PARAMETER NetAdapterName
Specifies the VM Network adapter name for which the IP Address needs to be configured.

.PARAMETER IPAddress
Specifies the IP address of the VM Network adapter. Setting this property to 'DHCP' will enable DHCP on the VM network adapter.

.PARAMETER Subnet
Specifies the Subnet of the VM Network adapter IP configuration.

.PARAMETER DefaultGateway
Specifies the DefaultGateway of the VM Network adapter IP configuration.

.PARAMETER DNSServer
Specifies the DNSServer of the VM Network adapter IP configuration.
#>
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (              
        [Parameter(Mandatory)]
        [String] $Id,

        [Parameter(Mandatory)]
        [String]$VMName,

        [Parameter(Mandatory)]
        [String]$NetAdapterName,

        [Parameter(Mandatory)]
        [String]$IPAddress,

        [Parameter(Mandatory)]
        [String]$Subnet,

        [Parameter()]
        [String]$DefaultGateway,

        [Parameter()]
        [String]$DNSServer
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }
    
    Write-Verbose $localizedData.GetNetConfig
    $netAdapter = Get-VMNetworkConfiguration -vmName $VMName -netAdapterName $NetAdapterName -Verbose

    if ($netAdapter) {
        if ($IPAddress -ne 'DHCP') {
            if (-not $Subnet) {
                throw $localizedData.SubnetMust
            }
            if (-not $netAdapter.DHCPEnabled) {
                if (($netAdapter.IPAddresses -contains $IPAddress) -and ($netAdapter.Subnets -contains $Subnet)) {
                    if ($DefaultGateway) {
                        if (-not ($netAdapter.DefaultGateways -contains $DefaultGateway)) {
                            Write-Verbose $localizedData.GWDoesnotExist
                            return $false
                        }
                    }

                    if ($DnsServer) {
                        if (-not ($netAdapter.DnsServers -contains $DnsServer)) {
                            Write-Verbose $localizedData.DnsDoesnotExist
                            return $false
                        }
                    }
                    Write-Verbose $localizedData.ConfigurationExists
                    return $true
                } else {
                    Write-Verbose $localizedData.ConfigurationDoesnotExist
                    return $false
                }
            } else {
                Write-Verbose $localizedData.StaticRequested
                return $false
            }
        } else {
            if ($netAdapter.DHCPEnabled) {
                Write-Verbose $localizedData.DHCPExists
                return $true
            } else {
                Write-Verbose $localizedData.DHCPDoesnotExist
                return $false
            }
        }
    } else {
        throw $localizedData.NetAdapterDoesnotExist
    }
}

Function Get-VMNetworkConfiguration
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory)]
        [ValidateScript({
            Get-VM -Name $_
        }
        )]
        [String]$VMName,

        [Parameter(Mandatory)]
        [String]$NetAdapterName
          
    )

    $vmObject = Get-CimInstance -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' | 
                Where-Object { $_.ElementName -eq $VMName }

    if ($vmObject.EnabledState -ne 2) {
        throw $localizedData.VMNotRunning
    } else {
        $vmSetting = Get-CimAssociatedInstance -InputObject $vmObject -ResultClassName 'Msvm_VirtualSystemSettingData'
        $netAdapter = Get-CimAssociatedInstance -InputObject $vmSetting `
                      -ResultClassName 'Msvm_SyntheticEthernetPortSettingData' | 
                           Where-Object { $_.ElementName -eq $NetAdapterName }
        if ($netadapter) {
            foreach ($adapter in $netAdapter) {
                $netConfig = Get-CimAssociatedInstance -InputObject $adapter `
                             -ResultClassName 'Msvm_GuestNetworkAdapterConfiguration' | 
                             Select-Object IPAddresses, Subnets, DefaultGateways, DNSServers, DHCPEnabled, `
                             @{Name="AdapterName";Expression={$adapter.ElementName}}
            }
        } else {
            Write-Warning $localizedData.NetAdapterDoesnotExist
            return $false
        }
    }
    
    return $netConfig
}

Function Set-VMNetworkConfiguration
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String]$NetworkAdapterName,

        [Parameter(Mandatory)]
        [String]$VMName,

        [Parameter()]
        [String[]]$IPAddress=@(),

        [Parameter()]
        [String[]]$Subnet=@(),

        [Parameter()]
        [String[]]$DefaultGateway=@(),

        [Parameter()]
        [String[]]$DNSServer=@(),

        [Parameter()]
        [Switch]$Dhcp
    )

    $networkAdapter = Get-VMNetworkAdapter -VMName $VMName -Name $NetworkAdapterName -Verbose -ErrorAction Stop
    $vm = Get-CimInstance -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' | 
          Where-Object { $_.ElementName -eq $networkAdapter.VMName } 
    $vmSettings = Get-CimAssociatedInstance -InputObject $vm -ResultClassName 'Msvm_VirtualSystemSettingData' | 
                  Where-Object { $_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized' }    
    $vmNetAdapter = Get-CimAssociatedInstance -InputObject $vmSettings `
                    -ResultClassName 'Msvm_SyntheticEthernetPortSettingData' | 
                    Where-Object { $_.ElementName -eq $networkAdapter.Name }

    $networkSettings = Get-CimAssociatedInstance -InputObject $vmNetAdapter `
                       -ResultClassName 'Msvm_GuestNetworkAdapterConfiguration'
    $networkSettings.psbase.CimInstanceProperties['ipaddresses'].Value = $IPAddress
    $networkSettings.psbase.CimInstanceProperties['Subnets'].Value = $Subnet
    $networkSettings.psbase.CimInstanceProperties['DefaultGateways'].Value = $DefaultGateway
    $networkSettings.psbase.CimInstanceProperties['DNSServers'].Value = $DNSServer
    $networkSettings.psbase.CimInstanceProperties['ProtocolIFType'].Value = 4096

    if ($Dhcp) {
        $networkSettings.psbase.CimInstanceProperties['DHCPEnabled'].Value = $true
    } else {
        $networkSettings.psbase.CimInstanceProperties['DHCPEnabled'].Value = $false
    }

    $cimSerializer = [Microsoft.Management.Infrastructure.Serialization.CimSerializer]::Create()
    $serializedInstance = $cimSerializer.Serialize(
         $networkSettings, [Microsoft.Management.Infrastructure.Serialization.InstanceSerializationOptions]::None
    )
    $embeddedInstanceString = [System.Text.Encoding]::Unicode.GetString($serializedInstance)

    $service = Get-CimInstance -Class "Msvm_VirtualSystemManagementService" -Namespace "root\virtualization\v2"

    $setIP = Invoke-CimMethod -InputObject $service -MethodName SetGuestNetworkAdapterConfiguration `
             -Arguments @{'ComputerSystem'=$vm;'NetworkConfiguration'=,$embeddedInstanceString} -Verbose

    if ($setIP.ReturnValue -eq 4096) {
        $job=[WMI]$setIP.job 

        while ($job.JobState -eq 3 -or $job.JobState -eq 4) {
            start-sleep 1
            $job=[WMI]$setIP.job
        }

        if ($job.JobState -eq 7) {
            return $true
        } else {
            throw $job.GetError()
        }
    } elseif($setip.ReturnValue -eq 0) {
        return $true       
    }
}

Export-ModuleMember -Function *-TargetResource
