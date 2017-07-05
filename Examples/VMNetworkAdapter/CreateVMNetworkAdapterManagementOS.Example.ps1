﻿Configuration HostOSAdapter
{
    Import-DscResource -ModuleName HyperVDsc -Name VMNetworkAdapter
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMNetworkAdapter HostOSAdapter
    {
        Id = 'Management-NIC'
        Name = 'Management-NIC'
        SwitchName = 'SETSwitch'
        VMName = 'ManagementOS'
        Ensure = 'Present'
    }
}
