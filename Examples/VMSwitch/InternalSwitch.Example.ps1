Configuration InternalSwitch
{
    Import-DscResource -ModuleName HyperVDsc -Name VMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMSwitch HostSwitch
    {
        Name = 'HostSwitch'
        Type = 'Internal'
        Ensure = 'Present'
    }
}
