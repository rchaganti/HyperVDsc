Configuration VMAdapterSettings
{
    Import-DscResource -ModuleName cHyper-V -Name VMNetworkAdapterSettings
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMNetworkAdapterSettings VMAdapterSettings {
        Id = 'Management-NIC'
        Name = 'Management-NIC'
        VMName = 'DHCPVM01'
        SwitchName = 'SETSwitch'
        DhcpGuard = 'On'
    }
}
