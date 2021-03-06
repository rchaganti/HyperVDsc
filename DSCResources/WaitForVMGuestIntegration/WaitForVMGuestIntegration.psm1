#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psd1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename WaitForVMGuestIntegration.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename WaitForVMGuestIntegration.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the WaitForVMGuestIntegration resource.

.DESCRIPTION
Gets the current state of the WaitForVMGuestIntegration resource.

.PARAMETER Id
Specifies a unique identifier that identifies a resource instance.

.PARAMETER VMName
Specifies the name of the VM for which the configuration will wait.
#>
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [String] $Id,

        [Parameter(Mandatory)]
        [String] $VMName
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }
    
    $configuration = @{
        Id = $Id
        VMName = $VMName
    }
    $configuration
}

<#
.SYNOPSIS
Sets the WaitForVMGuestIntegration resource to a desired state.

.DESCRIPTION
Sets the WaitForVMGuestIntegration resource to a desired state.

.PARAMETER Id
Specifies a unique identifier that identifies a resource instance.

.PARAMETER VMName
Specifies the name of the VM for which the configuration will wait.

.PARAMETER RetryIntervalSec
Specifies the interval in seconds to wait between retries.
Default value is 10.

.PARAMETER RetryCount
Specifies how many tries before declaring timeout.
Default value is 5.

.PARAMETER Force
Specifies if the VM should be switched on if not in a running state.
#>
function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [String] $Id,
        
        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter()]
        [UInt64] $RetryIntervalSec = 10,

        [Parameter()]
        [UInt32] $RetryCount = 5,

        [Parameter()]
        [bool] $Force
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }

    $vmIntegrationServicesRunning = $false
    Write-Verbose -Message ($localizedData.CheckGIS -f $VMName)

    $vm = Get-VM -Name $VMName

    if ($vm)
    {
        if ($vm.State -eq 'Off' -and $Force)
        {
            Write-Verbose -Message $localizedData.ForcePowerOn
            Start-VM -VM $vm
        }

        for ($count = 0; $count -lt $RetryCount; $count++)
        {
            $gis = Get-VMIntegrationService -VMName $VMName -Name 'Guest Service Interface'
            if ($gis.PrimaryStatusDescription -eq 'OK') {
                Write-Verbose -Message ($localizedData.GISRunning -f $VMName)
                $vmIntegrationServicesRunning = $true
                break
            }
            else
            {
                Write-Verbose -Message ($localizedData.GISNotRunning -f $VMName)
                Write-Verbose -Message ($localizedData.Retry -f $RetryIntervalSec)
                Start-Sleep -Seconds $RetryIntervalSec
            }
        }

        if (!$vmIntegrationServicesRunning)
        {
            throw ($localizedData.CheckError -f $VMName, $RetryIntervalSec)
        }
    }
}

<#
.SYNOPSIS
Tests if the WaitForVMGuestIntegration resource is in desired state.

.DESCRIPTION
Tests if the WaitForVMGuestIntegration resource is in desired state.

.PARAMETER Id
Specifies a unique identifier that identifies a resource instance.

.PARAMETER VMName
Specifies the name of the VM for which the configuration will wait.

.PARAMETER RetryIntervalSec
Specifies the interval in seconds to wait between retries.
Default value is 10.

.PARAMETER RetryCount
Specifies how many tries before declaring timeout.
Default value is 5.

.PARAMETER Force
Specifies if the VM should be switched on if not in a running state.
#>
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [String] $Id,

        [Parameter(Mandatory)]
        [String] $VMName,

        [Parameter()]        
        [UInt64] $RetryIntervalSec = 10,
        
        [Parameter()]        
        [UInt32] $RetryCount = 5,

        [Parameter()]
        [bool] $Force
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw $localizedData.NoHyperVModule
    }
    
    $vm = Get-VM -Name $VMName

    if ($vm)
    {
        if ($vm.State -eq 'Off' -and $Force)
        {
            Write-Verbose -Message $localizedData.ForcePowerOn
            Start-VM -VM $vm
        }    
        
        Write-Verbose -Message ($localizedData.CheckGIS -f $VMName)
        $gis = Get-VMIntegrationService -VMName $VMName -Name 'Guest Service Interface'
        if ($gis.PrimaryStatusDescription -eq 'OK') {
            Write-Verbose -Message ($localizedData.GISRunning -f $VMName)
            return $true
        }
        else
        {
            Write-Verbose -Message ($localizedData.GISNotRunning -f $VMName)
            return $false
        }
    }        
}

Export-ModuleMember -Function *-TargetResource
