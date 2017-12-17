#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psd1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename VMNetworkAdapterTeamMapping.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename VMNetworkAdapterTeamMapping.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER VMNetworkAdapterName
Parameter description

.PARAMETER PhysicalNetAdapterName
Parameter description

.PARAMETER VMName
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param (
        [Parameter(Mandatory = $true)]
        [String]
        $VMNetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [String]
        $PhysicalNetAdapterName,

        [Parameter(Mandatory = $true)]
        [String]
        $VMName
    )

    $configuration = @{
        VMNetworkAdapterName = $VMNetworkAdapterName
        PhysicalNetAdapterName = $PhysicalNetAdapterName
        VMName = $VMName
    }

    $netAdapterMapping = Test-VMNetworkAdapterTeamMapping -VMNetworkAdapterName $VMNetworkAdapterName -PhysicalNetAdapterName $PhysicalNetAdapterName -VMName $VMName
    if ($netAdapterMapping)
    {
        $configuration.Add('Ensure', 'Present')
    }
    else
    {
        $configuration.Add('Ensure', 'Absent')    
    }
    
    return $configuration
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER VMNetworkAdapterName
Parameter description

.PARAMETER PhysicalNetAdapterName
Parameter description

.PARAMETER VMName
Parameter description

.PARAMETER Ensure
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
Function Set-TargetResource
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]
        $VMNetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [String]
        $PhysicalNetAdapterName,

        [Parameter(Mandatory = $true)]
        [String]
        $VMName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )
    
    $netAdapterMapping = Test-VMNetworkAdapterTeamMapping -VMNetworkAdapterName $VMNetworkAdapterName -PhysicalNetAdapterName $PhysicalNetAdapterName -VMName $VMName

    if ($Ensure -eq 'Present')
    {
        if (-not $netAdapterMapping)
        {
            Write-Verbose -Message $localizedData.SetMapping

            $params = @{
                VMNetworkAdapterName = $VMNetworkAdapterName
                PhysicalNetAdapterName = $PhysicalNetAdapterName                
            }

            if ($VMName -eq 'ManagementOS')
            {
                $params.Add('ManagementOS', $true)
            }
            else
            {
                $params.Add('VMName', $VMName)    
            }

            Set-VMNetworkAdapterTeamMapping @params -Verbose
        }
    }
    else
    {
        if ($netAdapterMapping)
        {
            Write-Verbose -Message $localizedData.RemoveMapping

            $params = @{
                Name = $VMNetworkAdapterName
            }

            if ($VMName -eq 'ManagementOS')
            {
                $params.Add('ManagementOS', $true)
            }
            else
            {
                $params.Add('VmName', $VMName)
            }

            Remove-VMNetworkAdapterTeamMapping @params -Verbose
        }    
    }
}

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER VMNetworkAdapterName
Parameter description

.PARAMETER PhysicalNetAdapterName
Parameter description

.PARAMETER VMName
Parameter description

.PARAMETER Ensure
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param (
        [Parameter(Mandatory = $true)]
        [String]
        $VMNetworkAdapterName,

        [Parameter(Mandatory = $true)]
        [String]
        $PhysicalNetAdapterName,

        [Parameter(Mandatory = $true)]
        [String]
        $VMName,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure = 'Present'
    )

    $netAdapterMapping = Test-VMNetworkAdapterTeamMapping -VMNetworkAdapterName $VMNetworkAdapterName -PhysicalNetAdapterName $PhysicalNetAdapterName -VMName $VMName

    if ($Ensure -eq 'Present')
    {
        if ($netAdapterMapping)
        {
            Write-Verbose -Message $localizedData.MappingExistsNoAction
            return $true
        }
        else
        {
            Write-Verbose -Message $localizedData.MappingShouldExist
            return $false
        }
    }
    else
    {
        if ($netAdapterMapping)
        {
            Write-Verbose -Message $localizedData.MappingShouldNotExist
            return $false
        }
        else
        {
            Write-Verbose -Message $localizedData.MappingDoesNotExistNoAction
            return $true                
        }
    }
}

Export-ModuleMember -Function *-TargetResource
