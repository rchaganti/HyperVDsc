#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename SimpleVM.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename SimpleVM.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the SimpleVM resource

.DESCRIPTION
Gets the current state of the SimpleVM resource on a Hyper-V host.

.PARAMETER VMName
Specifies the name of the virtual machine in the SimpleVM resource configuration.
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

    Write-Verbose -Message $localizedData.CheckVM
    $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
    
    # Check if 1 or 0 VM with name = $VMname exist
    if($vm.count -gt 1)
    {
       Throw ($localizedData.MoreThanOneVMExistsError -f $VMName) 
    }
        
    $configuration = @{
        VMName           = $VMName
    }

    if ($vm)
    {
        $configuration.Add('State',$vm.State)
        $configuration.Add('Generation', $vm.Generation)
        $configuration.Add('StartupMemory',($vm.MemoryStartup)/1MB)
        $configuration.Add('CPUCount', $vm.ProcessorCount)
        $configuration.Add('VhdPath',$vm.HardDrives[0].Path)
        $configuration.Add('VhdSizeInBytes',(Get-VHD -Path $vm.HardDrives[0].Path).Size)
        $configuration.Add('Ensure','Present')
    }
    else
    {
        $configuration.Add('Ensure','Absent')
    }

    return $configuration
}

<#
.SYNOPSIS
Sets the SimpleVM resource to a desired state.

.DESCRIPTION
Sets the SimpleVM resource to a desired state on a Hyper-V host.

.PARAMETER VMName
Specifies the name of the virtual machine in the SimpleVM resource configuration.

.PARAMETER VhdPath
Specifies the full VHD or VHDX path that must exist for attaching to the VM.

.PARAMETER NewVhdPath
Specifies the full VHD or VHDX path that will be created and attached to the VM.
The VhdPath and NewVhdPath parameters are mutually exclusive.

.PARAMETER VhdSizeInBytes
Specifies the VHD size in Bytes for the NewVhdPath. Valid only with the NewVhdPath parameter.
Default value is 10GB. This should be specified in the GB. For example, 10GB, 20GB, and etc.

.PARAMETER State
Specifies the state of the VM at the desired state. Valid values are Off and Running.
Default value is Running.

.PARAMETER Generation
Specifies the generation of the VM that needs to be created or maitained at desired state. The valid values are 1 and 2.
Default value is 2. When Generation is 2, the VHD specified by VhdPath and NewVhdPath parameters should be VHDX.

.PARAMETER StartupMemory
Specifies the StartupMemory for the VM. This should be specified in MB. For example, 1024MB, 2048MB, and etc.
Default Value is 1024MB.

.PARAMETER CpuCount
Specifies the number of virtual processors that must be attached to the VM. Default value is 1. 

.PARAMETER RemoveDefaultNetworkAdapter
Specifies if the default network adapter named as 'Network Adapter' should be removed or kept attached to the VM.
By default, this default network adapter will be removed after VM creation. This is a boolean parameter.

.PARAMETER Force
Specifies if the VM can be force shutdown for any updates to configuration that are required to bring the resource to desired state.
This is a boolean parameter. Default value is false.

.PARAMETER Ensure
Specifies if the VM should be present or should be removed. Valid values are present and absent. Default value is present. 
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [String] $VMName,
        
        [parameter()]
        [String] $VhdPath,

        [parameter()]
        [String] $NewVhdPath,  

        [parameter()]
        [uint64] $VhdSizeInBytes = 10GB,              

        [Parameter()]
        [AllowNull()]
        [ValidateSet('Running','Off')]
        [String] $State = 'Running',

        [Parameter()]
        [ValidateRange(1,2)]
        [UInt32] $Generation = 2,

        [Parameter()]
        [ValidateRange(32MB,12582912MB)]
        [UInt64] $StartupMemory = 1024MB,

        [Parameter()]
        [UInt32] $CpuCount = 1,

        [Parameter()]
        [Boolean] $RemoveDefaultNetworkAdapter = $true,

        [Parameter()]
        [Boolean] $Force = $false,

        [Parameter()]
        [ValidateSet('Present','Absent')]
        [String] $Ensure = 'Present'
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).count -gt 1)
    {
       Throw ($localizedData.MoreThanOneVMExistsError -f $VMName)
    }
    
    if ($NewVhdPath -and $VhdPath)
    {
        Throw ($localizedData.VhdAndNewVhdAreExclusive)
    }

    if ($NewVhdPath -and (Test-Path -Path $NewVhdPath))
    {
        Throw $localizedData.NewVHDPathShouldNotExist
    }

    if ($VhdPath -and (!(Test-Path $VhdPath)))
    {
        Throw ($localizedData.VhdPathDoesNotExistError -f $VhdPath)
    }  
    
    if ($Generation -eq 2)
    {
        if (($VhdPath -and $VhdPath.Split('.')[-1] -eq 'vhd') -or ($NewVhdPath -and $NewVhdPath.Split('.')[-1] -eq 'vhd'))
        {
            Throw $localizedData.VhdUnsupportedOnGen2VMError
        }
    }

    try {
        Write-Verbose -Message $localizedData.CheckVM        
        $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if($vm)
        {
            Write-Verbose -Message ($localizedData.VMExists -f $VMName)
            if($Ensure -eq 'Absent')
            {
                Write-Verbose -Message $localizedData.VMShouldNotExist
                if ($vm.State -eq 'Running')
                {
                    if ($force)
                    {
                        Write-Verbose -Message $localizedData.StopRemoveVM
                        Stop-VM -VM $vm -Force
                        Remove-VM -VM $vm -Force
                    }
                    else 
                    {
                        throw $localizedData.ForceNotSpecified
                    }
                }
                else 
                {
                    Write-Verbose -Message $localizedData.RemoveVM
                    Remove-VM -VM $vm -Force
                }
            }
            else
            {
                $setArguments = @{
                    VM = $vm
                }

                if ($VhdPath -and ($vm.HardDrives.Path -notcontains $VhdPath))
                {
                    Write-Verbose -Message $localizedData.VhdPathNotAttached
                    Add-VMHardDiskDrive -VM $vm -Path $VhdPath -ErrorAction Stop
                }

                if ($NewVhdPath -and ($vm.HardDrives.Path -notcontains $NewVhdPath))
                {
                    Write-Verbose -Message $localizedData.NewVhdNotAttached
                    $newVHD = New-VHD -Path  $NewVhdPath -Dynamic -SizeBytes $VhdSizeInBytes -ErrorAction Stop
                    Add-VMHardDiskDrive -VM $vm -Path $newVHD -ErrorAction Stop
                }

                #VM does not have the right startup memory setting
                if ($StartupMemory -ne $vm.MemoryStartup)
                {
                    $setArguments.Add('MemoryStartup', $StartupMemory)
                    $updateVM = $true
                    $rebootNeeded = $true
                }

                #VM does not have the right processor count
                if($vm.ProcessorCount -ne $CpuCount)
                {
                    $setArguments.Add('ProcessorCount', $CpuCount)
                    $updateVM = $true
                    $rebootNeeded = $true
                }

                #Update VM for anything that requires a state change
                if ($updateVM)
                {
                    if ($rebootNeeded -and ($vm.State -ne 'Off'))
                    {
                        if ($Force)
                        {
                            $restoreState = $vm.State

                            Write-Verbose -Message $localizedData.StopVM
                            Stop-VM -VM $vm -Force
                        }
                        else
                        {
                            throw $localizedData.ForceNotSpecified
                        }
                    }

                    #Set the VM properties
                    Write-Verbose -Message $localizedData.UpdateVM
                    Set-VM @setArguments -Verbose -ErrorAction Stop
                    
                    if ($restoreState -eq 'Running')
                    {
                        Write-Verbose -Message $localizedData.RestoreVMState
                        Start-VM -VM $vm -ErrorAction Stop
                    }
                }

                if($State -and ($vm.State -ne $State))
                {
                    Write-Verbose -Message $localizedData.VMStateChange
                    Set-VMState -VMName $VMName -CurrentState $vm.State -DesiredState $State
                }

                if ($RemoveDefaultNetworkAdapter -and ($vm.NetworkAdapters.Name -contains 'Network Adapter'))
                {
                    Write-Verbose -Message $localizedData.RemoveDefaultNetworkAdapter
                    Remove-VMNetworkAdapter -VM $vm -Name 'Network Adapter' -ErrorAction Stop
                }
            }
        }
        else
        {
            Write-Verbose -Message ($localizedData.VMDoesNotExist -f $VMName)
            if($Ensure -eq "Present")
            {
                Write-Verbose -Message ($localizedData.CreatingVM -f $VMName)
                
                $parameters = @{
                    "Name" = $VMName
                    "Generation" = $Generation
                    "MemoryStartupBytes" = $StartupMemory
                }

                if ($VhdPath)
                {
                    $parameters.Add('VhdPath', $VhdPath)
                }
                elseif ($newVHDPath)
                {
                    $parameters.Add('NewVhdPath', $NewVhdPath)
                }
                else {
                    Write-Verbose -Message $localizedData.VMWithNoVHD
                    $parameters.Add('NoVHD',$true)
                }

                #Create the VM and grab the passthru object
                $vm = New-VM @parameters -ErrorAction Stop

                if ($vm)
                {
                    $setParameters = @{
                        Name = $VMName
                    }
                    if($CpuCount -ne $vm.ProcessorCount)
                    {
                        $setParameters["ProcessorCount"] = $CpuCount
                    }

                    $null = Set-VM @setParameters
                    Write-Verbose -Message $localizedData.VMCreated

                    if ($RemoveDefaultNetworkAdapter)
                    {
                        Write-Verbose -Message $localizedData.RemoveDefaultNetworkAdapter
                        Remove-VMNetworkAdapter -VM $vm -Name 'Network Adapter' -Verbose -ErrorAction Stop
                    }

                    if ($State -ne $vm.State)
                    {
                        Write-Verbose -Message $localizedData.VMStateChange
                        Set-VMState -VMName $VMName -CurrentState $vm.State -DesiredState $State
                    }
                }
            }
        }
    }
    catch
    {
        Write-Error $_
    }
}

<#
.SYNOPSIS
Tests if a SimpleVM resource is in desired state or not.

.DESCRIPTION
Tests if a SimpleVM resource is in desired state or not. Returns $true if the resource is in desired state and $false otherwise.

.PARAMETER VMName
Specifies the name of the virtual machine in the SimpleVM resource configuration.

.PARAMETER VhdPath
Specifies the full VHD or VHDX path that must exist for attaching to the VM.

.PARAMETER NewVhdPath
Specifies the full VHD or VHDX path that will be created and attached to the VM.
The VhdPath and NewVhdPath parameters are mutually exclusive.

.PARAMETER VhdSizeInBytes
Specifies the VHD size in Bytes for the NewVhdPath. Valid only with the NewVhdPath parameter.
Default value is 10GB. This should be specified in the GB. For example, 10GB, 20GB, and etc.

.PARAMETER State
Specifies the state of the VM at the desired state. Valid values are Off and Running.
Default value is Running.

.PARAMETER Generation
Specifies the generation of the VM that needs to be created or maitained at desired state. The valid values are 1 and 2.
Default value is 2. When Generation is 2, the VHD specified by VhdPath and NewVhdPath parameters should be VHDX.

.PARAMETER StartupMemory
Specifies the StartupMemory for the VM. This should be specified in MB. For example, 1024MB, 2048MB, and etc.
Default Value is 1024MB.

.PARAMETER CpuCount
Specifies the number of virtual processors that must be attached to the VM. Default value is 1. 

.PARAMETER RemoveDefaultNetworkAdapter
Specifies if the default network adapter named as 'Network Adapter' should be removed or kept attached to the VM.
By default, this default network adapter will be removed after VM creation. This is a boolean parameter.

.PARAMETER Force
Specifies if the VM can be force shutdown for any updates to configuration that are required to bring the resource to desired state.
This is a boolean parameter. Default value is false.

.PARAMETER Ensure
Specifies if the VM should be present or should be removed. Valid values are present and absent. Default value is present. 
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory)]
        [String] $VMName,
        
        [parameter()]
        [String] $VhdPath,
        
        [parameter()]
        [String] $NewVhdPath,  

        [parameter()]
        [uint64] $VhdSizeInBytes = 10GB, 

        [Parameter()]
        [ValidateSet('Running','Off')]
        [String] $State = 'Running',
        
        [Parameter()]
        [ValidateRange(1,2)]
        [UInt32] $Generation = 2,

        [Parameter()]
        [ValidateRange(32MB,12582912MB)]
        [UInt64] $StartupMemory = 1024MB,

        [Parameter()]
        [UInt32] $CpuCount = 1,

        [Parameter()]
        [bool] $RemoveDefaultNetworkAdapter = $true,

        [Parameter()]
        [Boolean] $Force = $false,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [String] $Ensure = 'Present'        
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).count -gt 1)
    {
       Throw ($localizedData.MoreThanOneVMExistsError -f $VMName)
    }

    if ($NewVhdPath -and $VhdPath)
    {
        Throw ($localizedData.VhdAndNewVhdAreExclusive)
    }

    if ($NewVhdPath -and (Test-Path -Path $NewVhdPath))
    {
        Throw $localizedData.NewVHDPathShouldNotExist
    }

    if ($VhdPath -and (!(Test-Path $VhdPath)))
    {
        Throw ($localizedData.VhdPathDoesNotExistError -f $VhdPath)
    }  
    
    if(($Generation -eq 2) -and $VhdPath)
    {
        if ($VhdPath.Split('.')[-1] -eq 'vhd')
        {
            Throw ($localizedData.VhdUnsupportedOnGen2VMError)
        }
    }

    try
    {
        Write-Verbose -Message $localizedData.CheckVM
        $vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue
        if ($vm)
        {
            if ($Ensure -eq 'Present')
            {
                Write-Verbose -Message $localizedData.VMExists

                #check if CPU count matches or not
                if ($vm.ProcessorCount -ne $CpuCount)
                {
                    Write-Verbose -Message $localizedData.vmCPUCountDifferent
                    return $false
                }

                #Check if memory matches or not
                if ($vm.MemoryStartup -ne $StartupMemory)
                {
                    Write-Verbose -Message $localizedData.vmStartupMemoryDifferent
                    return $true                
                }

                if ($vm.State -ne $State)
                {
                    Write-Verbose -Message $localizedData.vmStateDifferent
                    return $false
                }

                if ($RemoveDefaultNetworkAdapter)
                {
                    if ($vm.NetworkAdapters.Name -contains 'Network Adapter')
                    {
                        Write-Verbose -Message $localizedData.vmDefaultNetAdapterPresent
                        return $false                    
                    }
                }

                if ($NewVhdPath -and ($vm.HardDrives.Path -notcontains $NewVhdPath))
                {
                    Write-Verbose -Message $localizedData.NewVhdNotAttached
                    return $false
                }

                if ($VhdPath -and ($vm.HardDrives.Path -notcontains $VhdPath))
                {
                    Write-Verbose -Message $localizedData.VhdNotAttached
                    return $false
                }

                Write-Verbose -Message $localizedData.VMExistsNoActionNeeded
                return $true
            }
            else
            {
                Write-Verbose -Message $localizedData.VMShouldNotExist
                return $false
            }            
        }
        else 
        {
            if ($Ensure -eq 'Present')
            {
                Write-Verbose -Message $localizedData.VMShouldExist
                return $false
            }
            else 
            {
                Write-Verbose -Message $localizedData.VMDoesNotExistNoActionNeeded
                return $true
            }
        }
    }
    catch
    {
        throw $_
    }
}

Export-ModuleMember -Function *-TargetResource
