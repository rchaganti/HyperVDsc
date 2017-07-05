Configuration WaitForIC
{
    Import-DscResource -Name WaitForVMGuestIntegration -ModuleName cHyper-V
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
    WaitForVMGuestIntegration VM01
    {
        Id = 'VM01-IC01'
        VMName = 'VM01'
        Force = $true
    }
}
