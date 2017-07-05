Configuration SimpleNetAdaptervSwitch
{
    Import-DscResource -ModuleName HyperVDsc -Name VMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMSwitch HostSwitch
    {
        Name = 'HostSwitch'
        Type = 'External'
        AllowManagementOS = $true
        NetAdapterName = 'NIC1'
        Ensure = 'Present'
    }
}
