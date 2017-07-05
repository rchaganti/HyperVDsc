#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename VMDscConfigurationEnact.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename VMDscConfigurationEnact.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the VMDscConfigurationEnact resource. Works only on Windows Server 2016.

.DESCRIPTION
Gets the current state of the VMDscConfigurationEnact resource. 
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
Sets the VMDscConfigurationEnact resource to a desired state. Works only on Windows Server 2016.

.DESCRIPTION
Sets the VMDscConfigurationEnact resource to a desired state. 

.PARAMETER VMName
Specifies the name of the VM.

.PARAMETER VMCredential
Specifies the credentials that must be used for VMDirect sessions.

.PARAMETER FallbackVMCredential
Specifies the credentials to be used for VM Direct sessions in case the VMCredential isn't valid.
The FallbackVMCredential will be useful when DSC configuration inside VM is used to domain join after
which the initial VMCredential will be invalid.

.PARAMETER EnactTimeoutSeconds
Specifies how long to wait before declaring a timeout of configuration enact.

.PARAMETER RetryIntervalSeconds
Specifies how long to wait between retries until the EnactTimeoutSeconds expires.
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
        [pscredential] $FallbackVMCredential,

        [Parameter()]
        [Int] $EnactTimeoutSeconds = 600,

        [Parameter()]
        [int] $RetryIntervalSeconds = 10
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).count -gt 1)
    {
       Throw ($localizedData.MoreThanOneVMExistsError -f $VMName)
    }

    try
    {
        #Create a session over PSDirect
        Write-Verbose -Message $localizedData.NewPSSession
        $PSSession = New-VMPSSession -VMName $VMName -VMCredential $VMCredential -FallbackVMCredential $FallbackVMCredential

        if ((Get-DscLCMState -PSSession $PSSession) -eq 'PendingConfiguration')
        {
            #Start the configuration enact and wait for the job to finish
            Write-Verbose -Message $localizedData.EnactPendingConfig
            Invoke-Command -Session $PSSession -ScriptBlock {
                Start-DscConfiguration -UseExisting -Wait -Verbose -Force
            }
            
            Write-Verbose -Message $localizedData.CheckEnactStatus
            $startTime = Get-Date
            $enactComplete = $false

            While ((((Get-Date) - $startTime).Seconds -le $EnactTimeoutSeconds) -and (-not $enactComplete))
            {
                if (-not ($PSSession.State -eq 'Opened'))
                {
                    Write-Verbose -Message $localizedData.NewPSSession
                    $PSSession = New-VMPSSession -VMName $VMName -VMCredential $VMCredential -FallbackVMCredential $FallbackVMCredential
                }
                
                switch (Get-DscLCMState -PSSession $PSSession)
                {
                    "Idle" {
                        Write-Verbose -Message $localizedData.CheckCompliance
                        $compliance = Invoke-Command -Session $PSSession -ScriptBlock {
                            Test-DscConfiguration -Detailed -Verbose    
                        }

                        if (-not ($compliance.InDesiredState))
                        {
                            throw Write-Verbose -Message $localizedData.ErrorInEnact
                        }
                        else {
                            Write-Verbose -Message $localizedData.EnactSuccess
                            $enactComplete = $true
                        }
                    }

                    "PendingReboot" {
                        Write-Verbose -Message $localizedData.EnactNeedsReboot
                        $vmObj = Stop-VM -VMName $VMName -Force -Passthru
                        $vm = Start-VM -VM $vmObj -Passthru                

                        #Wait for VM integration services to start
                        Write-Verbose -Message $localizedData.WaitingForVMToStart
                        While ($vm.VMIntegrationService.Where({$_.Name -eq 'Heartbeat'}).PrimaryStatusDescription -ne 'OK')
                        {
                            Start-Sleep -Seconds 1 
                        }
                        $enactComplete = $false
                    }            

                    "Busy" {
                        Write-Verbose -Message $localizedData.EnactInProgress
                        $enactComplete = $false
                    }
                }

                #Sleep for a few seconds if enact is not complete
                if (-not $enactComplete)
                {
                    Write-Verbose -Message $localizedData.WaitBetweenRetry
                    Start-Sleep -Seconds $RetryIntervalSeconds                
                }
            }
        
            Write-Verbose -Message $localizedData.CleanUpPSSession
            Remove-PSSession -Session $PSSession
        }

        if (-not($enactComplete))
        {
            Write-Warning -Message $localizedData.EnactTimedout
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
Tests if the VMDscConfigurationEnact resource is in desired state. Works only on Windows Server 2016.

.DESCRIPTION
Tests if the VMDscConfigurationEnact resource is in desired state. 

.PARAMETER VMName
Specifies the name of the VM.

.PARAMETER VMCredential
Specifies the credentials that must be used for VMDirect sessions.

.PARAMETER FallbackVMCredential
Specifies the credentials to be used for VM Direct sessions in case the VMCredential isn't valid.
The FallbackVMCredential will be useful when DSC configuration inside VM is used to domain join after
which the initial VMCredential will be invalid.

.PARAMETER EnactTimeoutSeconds
Specifies how long to wait before declaring a timeout of configuration enact.

.PARAMETER RetryIntervalSeconds
Specifies how long to wait between retries until the EnactTimeoutSeconds expires.
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
        [pscredential] $FallbackVMCredential,

        [Parameter()]
        [Int] $EnactTimeoutSeconds = 600,

        [Parameter()]
        [int] $RetryIntervalSeconds = 10
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    if((Get-VM -Name $VMName -ErrorAction SilentlyContinue).count -gt 1)
    {
       Throw ($localizedData.MoreThanOneVMExistsError -f $VMName)
    }

    try
    {
        #Create a session over PSDirect
        Write-Verbose -Message $localizedData.NewPSSession
        $PSSession = New-VMPSSession -VMName $VMName -VMCredential $VMCredential -FallbackVMCredential $FallbackVMCredential

        #Copy the modules and MOF over PSSession; we will clean it up later
        #modules get copied to C:\Windows\Temp and then extracted
        if ((Get-DscLCMState -PSSession $PSSession) -eq 'PendingConfiguration')
        {
            Write-Verbose -Message $localizedData.PendingConfigurationFound
            $false
        }
        else {
            Write-Verbose -Message $localizedData.NoPendingConfiguration
            $true
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

function Get-DscLCMState
{
    [CmdletBinding()]
    param (
        $PSSession
    )

    return (Invoke-Command -Session $PSSession -ScriptBlock { (Get-DscLocalConfigurationManager).LCMState })
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

function Wait-ForEnactToComplete
{
    [CmdletBinding()]
    param (
        [String] $VmName,
        [pscredential] $VMCredential,
        [pscredential] $FallbackVMCredential,
        [int] $EnactTimeoutSeconds = 600,
        [int] $RetryIntervalSeconds = 10
    )

    #Start a timeout loop
    Write-Verbose -Message $localizedData.WaitingForEnact
    $startTime = Get-Date

    While (((Get-Date) - $startTime).Seconds -ne $EnactTimeoutSeconds)
    {
        Write-Verbose -Message $localizedData.NewPSSession
        $PSSession = New-VMPSSession -VMName $VMName -VMCredential $VMCredential -FallbackVMCredential $FallbackVMCredential
        $lcmState = Get-DscLCMState -PSSession $PSSession

        switch ($lcmState)
        {
            "Idle" {
                $compliance = Invoke-Command -Session $PSSession -ScriptBlock {
                    Test-DscConfiguration -Detailed -Verbose    
                }

                if (-not ($compliance.InDesiredState))
                {
                    return 'Failed'
                }
                else {
                    return 'Success'
                }
            }

            "PendingReboot" {
                Write-Verbose -Message $localizedData.EnactNeedsReboot
                $vmObj = Stop-VM -VMName $VMName -Force -Passthru
                $vm = Start-VM -VM $vmObj -Passthru
                
                Write-Verbose -Message $localizedData.WaitingForVMToStart
                Start-Sleep -Seconds 60 
                #Wait for VM integration services to start
                While ($vm.VMIntegrationService.Where({$_.Name -eq 'Heartbeat'}).PrimaryStatusDescription -ne 'OK')
                {
                    Write-Verbose -Message $localizedData.WaitingForVMToStart
                    Start-Sleep -Seconds 5
                }
                $enactNotComplete = $true
            }            

            "Busy" {
                    Write-Verbose -Message $localizedData.EnactInProgress
                    $enactNotComplete = $true
            }
        }
        
        Write-Verbose -Message $localizedData.CleanUpPSSession
        Remove-PSSession -Session $PSSession

        #Sleep for a few seconds
        Start-Sleep -Seconds $RetryIntervalSeconds
    }

    if ($enactNotComplete)
    {
        return 'Timeout'
    }
}

Export-ModuleMember -Function *-TargetResource
