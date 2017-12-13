#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename HyperVDsc.Helper.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename HyperVDsc.Helper.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

function Set-VMState
{
    param
    (
        [Parameter(Mandatory)]
        [String]$VMName,

        [Parameter(Mandatory)]
        [ValidateSet("Running","Paused","Off")]
        [String]$DesiredState,

        [Parameter(Mandatory)]
        [String]$CurrentState        
    )

    switch ($DesiredState)
    {
        'Running'
        {   
            Write-Verbose -Message $localizedData.VMRunningDesired
            # If VM is in paused state, use resume-vm to make it running
            if ($CurrentState -eq 'Paused')
            {
                Write-Verbose -Message $localizedData.ResumeVM
                Resume-VM -Name $VMName
            }

            # If VM is Off, use start-vm to make it running
            elseif ($CurrentState -eq "Off")
            {
                Write-Verbose -Message $localizedData.StartVM
                Start-VM -Name $VMName
            }
        }

        'Paused'
        {
            Write-Verbose -Message $localizedData.VMPausedDesired
            if($CurrentState -ne 'Off')
            {
                Write-Verbose -Message $localizedData.SuspendVM
                Suspend-VM -Name $VMName
            }
        }

        'Off'
        {
            Write-Verbose -Message $localizedData.StopVM
            Stop-VM -Name $Name -Force -WarningAction SilentlyContinue
        }
    }
}

function Set-VMIntegrationService
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]
        $VMName,

        [Parameter(Mandatory)]
        [String]
        $IntegrationServiceName,

        [Parameter(Mandatory)]
        [Boolean]
        $Enable
    )

    if ($Enabled)
    {
        Write-Verbose -Message ($localizedData.EnableService -f $IntegrationServiceName)
        Enable-VMIntegrationService -VMName $VMName -Name $IntegrationServiceName -Verbose
    }
    else
    {
        Write-Verbose -Message ($localizedData.DisableService -f $IntegrationServiceName)
        Disable-VMIntegrationService -VMName $VMName -Name $IntegrationServiceName -Verbose        
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

Export-ModuleMember -Function *
