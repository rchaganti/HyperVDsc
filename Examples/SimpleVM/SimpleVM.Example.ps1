Configuration SimpleVMCreation
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName HyperVDsc

    Node localhost
    {
        SimpleVM TESTVM
        {
            VMName = 'TestVM'
            CpuCount = 2
            StartupMemory = 2048MB
            VhdPath = 'D:\VHD\TestVM-VHD.vhdx'
            RemoveDefaultNetworkAdapter = $true
            State = 'Running'
            Ensure = 'Present'
        }
    }
}
