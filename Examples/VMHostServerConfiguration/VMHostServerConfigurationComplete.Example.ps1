Configuration CompleteVMHostServerConfiguration
{
    Import-DscResource -ModuleName HyperVDsc -Name VMHostServerConfiguration
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMHostServerConfiguration MyHostConfig
    {
        IsSingleInstance = 'Yes'
        VirtualMachinePath = 'D:\VM'
        VirtualHardDiskPath = 'D:\VHD'
        MaximumStorageMigrations = 10
        NumaSpanningEnabled = $false
        EnableEnhancedSessionMode = $true
    }
}
