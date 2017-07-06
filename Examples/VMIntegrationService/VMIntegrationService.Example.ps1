Configuration VmIntegrationService
{
    Import-DscResource -ModuleName HyperVDsc -Name VMIntegrationService
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMIntegrationService VMISDemo
    {
        VMName = 'TestVM01'
        GuestServiceInterfaceEnabled = $true
        HeartbeatEnabled = $true
        VSSEnabled = $true
        TimeSynchronizationEnabled = $true
        KVPExchangeEnabled = $true
        ShutdownEnabled = $true
    }
}
