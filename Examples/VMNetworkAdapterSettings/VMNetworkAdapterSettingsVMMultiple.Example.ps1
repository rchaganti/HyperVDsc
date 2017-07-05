Configuration VMAdapterSettings
{
    Import-DscResource -ModuleName cHyper-V -Name VMNetworkAdapterSettings
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMNetworkAdapterSettings VMAdapterSettings01 {
        Id = 'Management-NIC'
        Name = 'Management-NIC'
        VMName = 'DHCPVM01'
        SwitchName = 'SETSwitch'
        DhcpGuard = 'On'
        DeviceNaming = 'On'
    }

    VMNetworkAdapterSettings VMAdapterSettings02 {
        Id = 'App-NIC'
        Name = 'App-NIC'
        VMName = 'DHCPVM01'
        SwitchName = 'SETSwitch'
        DeviceNaming = 'On'
    }
}
