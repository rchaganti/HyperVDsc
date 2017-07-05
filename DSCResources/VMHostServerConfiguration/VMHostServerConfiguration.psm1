#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psm1'))
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
    }

    return $configuration
}


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
        [int]
        $MaximumStorageMigrations = 2,

        [Parameter()]
        [Boolean]
        $NumaSpanningEnabled = $true,

        [Parameter()]
        [Boolean]
        $EnableEnhancedSessionMode = $false
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
        [int]
        $MaximumStorageMigrations = 2,

        [Parameter()]
        [Boolean]
        $NumaSpanningEnabled = $true,

        [Parameter()]
        [Boolean]
        $EnableEnhancedSessionMode = $false   
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

    Write-Verbose -Message $localizedData.EverythingConfiguredAsNeeded
    return $true
}

Export-ModuleMember -Function *-TargetResource
