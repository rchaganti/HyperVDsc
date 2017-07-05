Configuration HostOSAdapterSettings
{
    Import-DscResource -ModuleName HyperVDsc -Name VMNetworkAdapterSettings
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMNetworkAdapterSettings HostOSAdapterSettings
    {
        Id = 'Management-NIC'
        Name = 'Management-NIC'
        VMName = 'ManagementOS'
        SwitchName = 'SETSwitch'
        MinimumBandwidthWeight = 20
    }
}
