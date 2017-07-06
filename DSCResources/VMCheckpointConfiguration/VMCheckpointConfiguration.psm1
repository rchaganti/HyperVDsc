#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename VMCheckpointConfiguration.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename VMCheckpointConfiguration.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the VMCheckpointConfiguration resource.

.DESCRIPTION
Gets the current state of the VMCheckpointConfiguration resource.

.PARAMETER VMName
Specifies the VM for which the checkpoint configuration state needs to be retrieved.
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

        Write-Verbose -Message $localizedData.GetVMCheckPointConfiguration
        $configuration.Add('CheckpointType', $vm.CheckpointType)
        $configuration.Add('CheckpointFileLocation', $vm.CheckpointFileLocation)
        return $configuration
    }
    else
    {
        throw $localizedData.NoVMFound    
    }
}

<#
.SYNOPSIS
Sets the VMCheckpointConfiguration resource to desired state.

.DESCRIPTION
Sets the VMCheckpointConfiguration resource to desired state.

.PARAMETER VMName
Specifies the VM for which the checkpoint configuration state needs to be configured.

.PARAMETER CheckpointType
Specifies the checkpoint type that needs to be configured.
Allowed values are 'Disabled','Production','ProductionOnly','Standard'. Production is default.

.PARAMETER CheckpointFileLocation
Specifies the Checkpoint file location. 
If the VM already has existing snapshots, this property cannot be changed without deleting the snapshots.
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
        [String]
        [ValidateSet('Disabled','Production','ProductionOnly','Standard')]
        $CheckpointType = 'Production',

        [Parameter()]
        [String]
        $CheckpointFileLocation
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    if ($CheckpointType -ne 'Disabled' -and (-not $CheckpointFileLocation))
    {
        throw $localizedData.CheckpointLocationNotSpecified
    }

    Write-Verbose -Message $localizedData.GetVM
    $vm = Get-VM -Name $VMName

    if ($vm)
    {
        $setNeeded = $false
        $setParameters = @{
            VMName = $VMName
        }

        if ($CheckpointType -ne $vm.CheckpointType)
        {
            Write-Verbose -Message $localizedData.UpdateCheckpointType
            $setParameters.Add('CheckpointType', $CheckpointType)
            $setNeeded = $true
        }

        if ($CheckpointFileLocation -ne $vm.CheckpointFileLocation)
        {
            if ((Get-VMSnapshot -VM $vm).Count -eq 0)
            {
                Write-Verbose -Message $localizedData.UpdateCheckpointFileLocation
                $setParameters.Add('SnapshotFileLocation', $CheckpointFileLocation)
                $setNeeded = $true
            }
            else
            {
                Write-Verbose -Message $localizedData.CheckpointFileLocationCannotChange
            }
        }

        if ($setNeeded)
        {
            Write-Verbose -Message $localizedData.PerformCheckPointUpdate
            Set-VM @setParameters -Verbose
        }
    }
    else
    {
        throw $localizedData.NoVMFound    
    }
}

<#
.SYNOPSIS
Tests if the VMCheckpointConfiguration resource is in  desired state.

.DESCRIPTION
Tests if the VMCheckpointConfiguration resource is in desired state.

.PARAMETER VMName
Specifies the VM for which the checkpoint configuration state needs to be configured.

.PARAMETER CheckpointType
Specifies the checkpoint type that needs to be configured.
Allowed values are 'Disabled','Production','ProductionOnly','Standard'. Production is default.

.PARAMETER CheckpointFileLocation
Specifies the Checkpoint file location. 
If the VM already has existing snapshots, this property cannot be changed without deleting the snapshots.
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
        [String]
        [ValidateSet('Disabled','Production','ProductionOnly','Standard')]
        $CheckpointType = 'Production',

        [Parameter()]
        [String]
        $CheckpointFileLocation      
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    if ($CheckpointType -ne 'Disabled' -and (-not $CheckpointFileLocation))
    {
        throw $localizedData.CheckpointLocationNotSpecified
    }

    Write-Verbose -Message $localizedData.GetVM
    $vm = Get-VM -Name $VMName

    if ($vm)
    {
        if ($CheckpointType -ne $vm.CheckpointType)
        {
            Write-Verbose -Message $localizedData.CheckpointTypeNotMatching        
            return $false
        }
        
        if ($CheckpointFileLocation -ne $vm.CheckpointFileLocation)
        {
            if ((Get-VMSnapshot -VM $vm).Count -eq 0)
            {
                Write-Verbose -Message $localizedData.CheckpointFileLocationNotMatching
                return $false
            }
            else
            {
                Write-Warning -Message $localizedData.CheckpointFileLocationCannotChange
                return $true
            }
        }        

        Write-Verbose -Message $localizedData.VMCheckpointInDesiredState
        return $true
    }
    else
    {
        throw $localizedData.NoVMFound    
    } 
}

Export-ModuleMember -Function *-TargetResource
