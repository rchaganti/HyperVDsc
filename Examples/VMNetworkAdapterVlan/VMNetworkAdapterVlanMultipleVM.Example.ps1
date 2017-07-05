Configuration HostOSAdapterVlan
{
    Import-DscResource -ModuleName cHyper-V -Name VMNetworkAdapterVlan
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMNetworkAdapterVlan VMMgmtAdapterVlan {
        Id = 'VMManagement-NIC'
        Name = 'VMManagement-NIC'
        VMName = 'SQLVM01'
        AdapterMode = 'Access'
        VlanId = 10
    }

    #The following configuration removes any VLAN setting, if present.
    VMNetworkAdapterVlan VMiSCSIAdapterVlan {
        Id = 'VMiSCSI-NIC'
        Name = 'VMiSCSI-NIC'
        VMName = 'SQLVM01'
        AdapterMode = 'Untagged'
    }
}
