#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename VMDscConfigurationPublish.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename VMDscConfigurationPublish.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the VMDscConfigurationPublish resource. Works only on Windows Server 2016.

.DESCRIPTION
Gets the current state of the VMDscConfigurationPublish resource. 
This returns only the VMName and VMCredential in the configuration hash.

.PARAMETER VMName
Specifies the name of the VM.

.PARAMETER VMCredential
Specifies the credentials that must be used for VMDirect sessions.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [string] $VMName,

        [Parameter(Mandatory)]
        [pscredential] $VMCredential
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).count -gt 1)
    {
       Throw ($localizedData.MoreThanOneVMExistsError -f $VMName)
    }

    @{
        VMName = $VMName
        VMCredential = $VMCredential
    }
}

<#
.SYNOPSIS
Sets the VMDscConfigurationPublish resource to desired state. Works only on Windows Server 2016.

.DESCRIPTION
Sets the VMDscConfigurationPublish resource to desired state.

.PARAMETER VMName
Specifies the name of the VM.

.PARAMETER VMCredential
Specifies the credentials that must be used for VMDirect sessions.

.PARAMETER ConfigurationMof
Specifies the node configuration MOF that needs to be published as pending.mof.

.PARAMETER MetaConfigurationMof
Specifies the node meta configuration MOF that needs to be published as MetaConfig.Mof.

.PARAMETER ModuleZip
Spevifies the path to the modules ZIP that contains any custom resource modules required for the node configuration enact.

.PARAMETER FallbackVMCredential
Specifies the credentials to be used for VM Direct sessions in case the VMCredential isn't valid.
The FallbackVMCredential will be useful when DSC configuration inside VM is used to domain join after
which the initial VMCredential will be invalid.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [string] $VMName,

        [Parameter(Mandatory)]
        [pscredential] $VMCredential,

        [Parameter()]
        [string] $ConfigurationMof,

        [Parameter()]
        [string] $MetaConfigurationMof,        

        [Parameter()]
        [string] $ModuleZip,

        [Parameter()]
        [pscredential] $FallbackVMCredential
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).count -gt 1)
    {
       Throw ($localizedData.MoreThanOneVMExistsError -f $VMName)
    }

    if ($ModuleZip -and (!(Test-Path -Path $ModuleZip)))
    {
        throw $localizedData.ModulesNotFound
    }

    if ($ConfigurationMof -and !(Test-Path -Path $ConfigurationMof))
    {
        throw $localizedData.ConfigMofNotFound
    }

    if ($MetaConfigurationMof -and !(Test-Path -Path $MetaConfigurationMof))
    {
        throw $localizedData.MetaConfigMofNotFound
    }

    if ((-not $moduleZipName) -and (-not $ConfigurationMof) -and (-not $MetaConfigurationMof))
    {
        throw $localizedData.NothingToPublish
    }

    try
    {
        #Create a session over PSDirect
        Write-Verbose -Message $localizedData.NewPSSession
        $PSSession = New-VMPSSession -VMName $VMName -VMCredential $VMCredential -FallbackVMCredential $FallbackVMCredential

        #Copy the meta configuration if it is provided
        if ($MetaConfigurationMof)
        {
            Write-Verbose -Message $localizedData.CheckExistingMetaMof
            $metaMofExists = Invoke-Command -Session $PSSession -ScriptBlock { Test-Path -Path C:\Windows\System32\Configuration\MetaConfig.mof }
            
            if ($metaMofExists)
            {
                Write-Verbose -Message $localizedData.BackupExistingMetaMof
                Invoke-Command -Session $PSSession -ScriptBlock { Copy-Item -path C:\Windows\System32\Configuration\MetaConfig.mof -Destination C:\Windows\System32\Configuration\MetaConfig.backup.mof -Force }
            }
            
            Write-Verbose -Message $localizedData.CopyMetaMof
            Copy-Item -ToSession $PSSession -Path $MetaConfigurationMof -Destination C:\Windows\System32\Configuration\MetaConfig.mof -Force
        }        

        #Copy the modules and MOF over PSSession; we will clean it up later
        #modules get copied to C:\Windows\Temp and then extracted
        if (@('Idle', 'PendingReboot') -contains (Get-DscLCMState -PSSession $PSSession))
        {
            if ($ModuleZip)
            {
                #Checks here to ensure the checksum matches
                $localCheckSum = (Get-FileHash -Path $moduleZip).Hash                
                $moduleZipName = Split-Path -Path $ModuleZip -Leaf

                #Check if remote file exists and get hash
                $remoteChecksum = invoke-Command -Session $PSSession -ScriptBlock { 
                    if (Test-Path -Path "C:\Windows\Temp\$($using:moduleZipName)") {
                        (Get-FileHash -Path "C:\Windows\Temp\$($using:moduleZipName)").Hash 
                    }
                }

                if ($remoteChecksum)
                {
                    #File exists with the same name; lets check if it is same as local file
                    if ($remoteChecksum -eq $localCheckSum)
                    {
                        Write-Verbose -Message $localizedData.ModuleFileMatching
                    }
                    else {
                        Write-Verbose -Message $localizedData.ModuleFileMatchingButNotHash
                        $moduleZipName = "1_${moduleZipName}"
                        Copy-Item -Path $ModuleZip -Destination "C:\Windows\Temp\${moduleZipName}" -Force -ToSession $PSSession
                    }
                }
                else {
                    Write-Verbose -Message $localizedData.CopyModuleZip
                    Copy-Item -Path $ModuleZip -Destination C:\Windows\Temp -Force -ToSession $PSSession                    
                }

                Write-Verbose -Message $localizedData.ExtractModules
                Invoke-Command -Session $PSSession -ScriptBlock { 
                    $moduleSet = Invoke-DscResource -Name Archive -Method Set `
                                -ModuleName PSDesiredStateConfiguration `
                                                    -Property @{
                                'Path'="C:\Windows\Temp\$($using:moduleZipName)"
                                'Destination'='C:\Program Files\WindowsPowerShell\Modules'
                                'Ensure' = 'Present'
                                'Force'=$true
                            }
                }
            }
        
            #Copy MOF
            if ($ConfigurationMof)
            {
                $configMofName = Split-Path -Path $ConfigurationMof -Leaf
                Write-Verbose -Message $localizedData.CopyMOF
                Copy-Item -Path $ConfigurationMof -Destination C:\Windows\System32\Configuration\pending.mof -Force -ToSession $PSSession
            }
        }
        else
        {
            Throw $localizedData.VMLCMStateError
        }

        #Clean up PSSession
        Write-Verbose -Message $localizedData.CleanUpPSSession
        Remove-PSSession -Session $PSSession
    }

    catch
    {
        Write-Error $_
    }
}

<#
.SYNOPSIS
Sets the VMDscConfigurationPublish resource to desired state. Works only on Windows Server 2016.

.DESCRIPTION
Sets the VMDscConfigurationPublish resource to desired state.

.PARAMETER VMName
Specifies the name of the VM.

.PARAMETER VMCredential
Specifies the credentials that must be used for VMDirect sessions.

.PARAMETER ConfigurationMof
Specifies the node configuration MOF that needs to be published as pending.mof.

.PARAMETER MetaConfigurationMof
Specifies the node meta configuration MOF that needs to be published as MetaConfig.Mof.

.PARAMETER ModuleZip
Spevifies the path to the modules ZIP that contains any custom resource modules required for the node configuration enact.

.PARAMETER FallbackVMCredential
Specifies the credentials to be used for VM Direct sessions in case the VMCredential isn't valid.
The FallbackVMCredential will be useful when DSC configuration inside VM is used to domain join after
which the initial VMCredential will be invalid.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [string] $VMName,

        [Parameter(Mandatory)]
        [pscredential] $VMCredential,

        [Parameter()]
        [string] $ConfigurationMof,

        [Parameter()]
        [string] $MetaConfigurationMof,        

        [Parameter()]
        [string] $ModuleZip,

        [Parameter()]
        [pscredential] $FallbackVMCredential
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).count -gt 1)
    {
       Throw ($localizedData.MoreThanOneVMExistsError -f $VMName)
    }

    if ($ModuleZip -and (!(Test-Path -Path $ModuleZip)))
    {
        throw $localizedData.ModulesNotFound
    }

    if ($ConfigurationMof -and (!(Test-Path -Path $ConfigurationMof)))
    {
        throw $localizedData.ConfigMofNotFound
    }

    if ($MetaConfigurationMof -and (!(Test-Path -Path $MetaConfigurationMof)))
    {
        throw $localizedData.MetaConfigMofNotFound
    }

    try
    {
        #Create a session over PSDirect
        Write-Verbose -Message $localizedData.NewPSSession
        $PSSession = New-VMPSSession -VMName $VMName -VMCredential $VMCredential -FallbackVMCredential $FallbackVMCredential

        #Copy the modules and MOF over PSSession; we will clean it up later
        #modules get copied to C:\Windows\Temp and then extracted
        if (@('Idle', 'PendingReboot') -contains (Get-DscLCMState -PSSession $PSSession))
        {
            if ($ModuleZip)
            {
                Write-Verbose -Message $localizedData.CopyModuleZip
                Copy-Item -Path $ModuleZip -Destination C:\Windows\Temp -Force -ToSession $PSSession

                #Extract Modules
                $moduleZipName = Split-Path -Path $ModuleZip -Leaf
                Write-Verbose -Message $localizedData.ExtractModules
                Invoke-Command -Session $PSSession -ScriptBlock {           
                    $moduleSet = Invoke-DscResource -Name Archive -Method Set `
                                -ModuleName PSDesiredStateConfiguration `
                                -Property @{
                                    'Path'="C:\Windows\Temp\$($using:moduleZipName)"
                                    'Destination'='C:\Program Files\WindowsPowerShell\Modules'
                                    'Ensure' = 'Present'
                                    'Force'=$true
                    }
                }
            }

            #Copy MOF
            $configMofName = Split-Path -Path $ConfigurationMof -Leaf
            Write-Verbose -Message $localizedData.CopyMOF
            Copy-Item -Path $ConfigurationMof -Destination C:\Windows\Temp -Force -ToSession $PSSession

            #test complaince with test-dscConfiguration against a reference mOF
            $complaince = Invoke-Command -Session $PSSession -ScriptBlock {
                Test-DscConfiguration -ReferenceConfiguration "C:\Windows\Temp\$($using:configMofName)"
            }
        }
        else
        {
            Throw $localizedData.VMLCMStateError
        }

        #Clean up PSSession
        Write-Verbose -Message $localizedData.CleanUpPSSession
        Remove-PSSession -Session $PSSession

        if ($complaince)
        {          
            if ($complaince.InDesiredState)
            {
                Write-Verbose -Message $localizedData.SystemInCompliance
                return $true
            }
            else
            {
                Write-Verbose -Message $localizedData.SystemNotInCompliance
                return $false
            }
        }
    }

    catch
    {
        Write-Error $_
    }
}

function New-VMPSSession
{
    [CmdletBinding()]
    param (
        [string] $VMName,
        [pscredential] $VMCredential,
        [pscredential] $FallbackVMCredential
    )

    $PSSession = New-PSSession -VMName $VMName -Credential $VMCredential -ErrorAction SilentlyContinue
    if ($PSSession)
    {
        return $PSSession
    }
    elseif ($FallbackVMCredential) {
        #Try fallback creds; needed for domain join computers
        $PSSession = New-PSSession -VMName $VMName -Credential $FallbackVMCredential -ErrorAction Stop
        return $PSSession
    }
    else {
        Throw $localizedData.ErrorVMSession
    }
}

function Get-DscLCMState
{
    [CmdletBinding()]
    param (
        $PSSession
    )

    return (Invoke-Command -Session $PSSession -ScriptBlock { (Get-DscLocalConfigurationManager).LCMState })
}

Export-ModuleMember -Function *-TargetResource
