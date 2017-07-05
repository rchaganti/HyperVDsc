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

Export-ModuleMember -Function *
