Configuration InternalSwitch
{
    Import-DscResource -ModuleName cHyper-V -Name VMSwitch
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMSwitch HostSwitch {
        Name = 'HostSwitch'
        Type = 'Internal'
        Ensure = 'Present'
    }
}
