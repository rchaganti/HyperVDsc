Configuration VMIPAddress
{
    Import-DscResource -ModuleName HyperVDsc -Name VMIPAddress
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMIPAddress VMAdapter1IPAddress
    {
        Id = 'VMMgmt-NIC'
        NetAdapterName = 'VMMgmt-NIC'
        VMName = 'SQLVM01'
        IPAddress = 'DHCP'
    }
}
