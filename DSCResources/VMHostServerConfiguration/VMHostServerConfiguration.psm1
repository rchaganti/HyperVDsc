#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psd1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename VMHostServerConfiguration.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename VMHostServerConfiguration.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the VMHostServerConfiguration resource.

.DESCRIPTION
Gets the current state of the VMHostServerConfiguration resource.

.PARAMETER IsSingleInstance
Specifies if this resource instance is a single instance.
The value to this parameter should always be Yes.
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
        $IsSingleInstance
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    Write-Verbose -Message $localizedData.GetVMHost
    $vmHost = Get-VMHost    
    
    $configuration = @{
        IsSingleInstance = $IsSingleInstance
        VirtualHardDiskPath = $vmHost.VirtualHardDiskPath
        VirtualMachinePath = $vmHost.VirtualMachinePath
        MaximumStorageMigrations = $vmHost.MaximumStorageMigrations
        NumaSpanningEnabled = $vmHost.NumaSpanningEnabled
        EnableEnhancedSessionMode = $vmHost.EnableEnhancedSessionMode
        VirtualMachineMigrationPerformanceOption = $vmHost.VirtualMachineMigrationPerformanceOption
    }

    return $configuration
}

<#
.SYNOPSIS
Set the VMHostServerConfiguration resource to desired state.

.DESCRIPTION
Set the VMHostServerConfiguration resource to desired state.

.PARAMETER IsSingleInstance
Specifies if this resource instance is a single instance.
The value to this parameter should always be Yes.
This is the key property.

.PARAMETER VirtualHardDiskPath
Specifies the virtual hard disk file path.
The value should be a folder path and if the path does not exist, it will be created.

.PARAMETER VirtualMachinePath
Specifies the virtual machine file path.
The value should be a folder path and if the path does not exist, it will be created.

.PARAMETER MaximumStorageMigrations
Specifies the maximum number of storage migrations.

.PARAMETER NumaSpanningEnabled
Specifies if NUMA spanning for VMs should be enabled or not. This is a Boolean value.

.PARAMETER EnableEnhancedSessionMode
Specifies if the enhanced session mode should be enabled or not. This is a boolean value.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string]
        $IsSingleInstance,

        [Parameter()]
        [String]
        $VirtualHardDiskPath,

        [Parameter()]
        [String]
        $VirtualMachinePath,     

        [Parameter()]
        [Uint32]
        $MaximumStorageMigrations = 2,

        [Parameter()]
        [Boolean]
        $NumaSpanningEnabled = $true,

        [Parameter()]
        [Boolean]
        $EnableEnhancedSessionMode = $false,

        [Parameter()]
        [ValidateSet('SMB','Compression','TCPIP')]
        [String]
        $VirtualMachineMigrationPerformanceOption = 'Compression'
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    Write-Verbose -Message $localizedData.GetVMHost
    $vmHost = Get-VMHost

    $setParameters = @{}
    $setNeeded = $false

    if ($VirtualHardDiskPath -and ($vmHost.VirtualHardDiskPath -ne $VirtualHardDiskPath))
    {        
        Write-Verbose -Message $localizedData.ChangeVhdPath
        $setParameters.Add('VirtualHardDiskPath', $VirtualHardDiskPath)
        $setNeeded = $true
    }

    if ($VirtualMachinePath -and ($vmHost.VirtualMachinePath -ne $VirtualMachinePath))
    {
        Write-Verbose -Message $localizedData.ChangeVmPath
        $setParameters.Add('VirtualMachinePath', $VirtualMachinePath)
        $setNeeded = $true
    }

    if ($vmHost.MaximumStorageMigrations -ne $MaximumStorageMigrations)
    {
        Write-Verbose -Message $localizedData.ChangeMsm
        $setParameters.Add('MaximumStorageMigrations', $MaximumStorageMigrations)
        $setNeeded = $true
    }

    if ($vmHost.NumaSpanningEnabled -ne $NumaSpanningEnabled)
    {
        $vmState = Get-VM | Select-Object -ExpandProperty State

        if($vmState -contains 'Running')
        {
            throw $localizedData.CannotChangeNse
        }
        else
        {
            Write-Verbose -Message $localizedData.ChagneNse
            $setParameters.Add('NumaSpanningEnabled', $NumaSpanningEnabled)
            $setNeeded = $true
            $flagReboot = $true  
        }
    }

    if ($vmHost.EnableEnhancedSessionMode -ne $EnableEnhancedSessionMode)
    {
        Write-Verbose -Message $localizedData.ChangeEesm
        $setParameters.Add('EnableEnhancedSessionMode', $EnableEnhancedSessionMode)
        $setNeeded = $true
    }

    if ($vmHost.VirtualMachineMigrationPerformanceOption -ne $VirtualMachineMigrationPerformanceOption)
    {
        Write-Verbose -Message $localizedData.ChangeLMOption
        $setParameters.Add('VirtualMachineMigrationPerformanceOption', $VirtualMachineMigrationPerformanceOption)
        $setNeeded = $true
    }    

    if ($setNeeded)
    {
        Write-Verbose -Message $localizedData.SetVMhost
        Set-VMHost @setParameters

        if ($flagReboot)
        {
            Write-Verbose -Message $localizedData.RebootRequired
            $Global:DSCMachineStatus = 1
        }
    }
}

<#
.SYNOPSIS
Tests if the VMHostServerConfiguration resource is in desired state or not.

.DESCRIPTION
Tests if the VMHostServerConfiguration resource is in desired state or not.

.PARAMETER IsSingleInstance
Specifies if this resource instance is a single instance.
The value to this parameter should always be Yes.
This is the key property.

.PARAMETER VirtualHardDiskPath
Specifies the virtual hard disk file path.
The value should be a folder path and if the path does not exist, it will be created.

.PARAMETER VirtualMachinePath
Specifies the virtual machine file path.
The value should be a folder path and if the path does not exist, it will be created.

.PARAMETER MaximumStorageMigrations
Specifies the maximum number of storage migrations.

.PARAMETER NumaSpanningEnabled
Specifies if NUMA spanning for VMs should be enabled or not. This is a Boolean value.

.PARAMETER EnableEnhancedSessionMode
Specifies if the enhanced session mode should be enabled or not. This is a boolean value.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string]
        $IsSingleInstance,

        [Parameter()]
        [String]
        $VirtualHardDiskPath,

        [Parameter()]
        [String]
        $VirtualMachinePath,     

        [Parameter()]
        [Uint32]
        $MaximumStorageMigrations = 2,

        [Parameter()]
        [Boolean]
        $NumaSpanningEnabled = $true,

        [Parameter()]
        [Boolean]
        $EnableEnhancedSessionMode = $false,

        [Parameter()]
        [ValidateSet('SMB','Compression','TCPIP')]
        [String]
        $VirtualMachineMigrationPerformanceOption = 'Compression'
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    Write-Verbose -Message $localizedData.GetVMHost
    $vmHost = Get-VMHost

    if ($VirtualHardDiskPath -and ($vmHost.VirtualHardDiskPath -ne $VirtualHardDiskPath))
    {
        Write-Verbose -Message $localizedData.VhdPathNotMatching
        return $false
    }

    if ($VirtualMachinePath -and ($vmHost.VirtualMachinePath -ne $VirtualMachinePath))
    {
        Write-Verbose -Message $localizedData.VmPathNotMatching
        return $false
    }

    if ($vmHost.MaximumStorageMigrations -ne $MaximumStorageMigrations)
    {
        Write-Verbose -Message $localizedData.MsmNotMatching
        return $false
    }

    if ($vmHost.NumaSpanningEnabled -ne $NumaSpanningEnabled)
    {
        Write-Verbose -Message $localizedData.NseNotMatching
        return $false
    }

    if ($vmHost.EnableEnhancedSessionMode -ne $EnableEnhancedSessionMode)
    {
        Write-Verbose -Message $localizedData.EesmNotMatching
        return $false
    }

    if ($vmHost.VirtualMachineMigrationPerformanceOption -ne $VirtualMachineMigrationPerformanceOption)
    {
        Write-Verbose -Message $localizedData.LMMigrationOptionNotMatching
        return $false
    }

    Write-Verbose -Message $localizedData.EverythingConfiguredAsNeeded
    return $true
}

Export-ModuleMember -Function *-TargetResource
