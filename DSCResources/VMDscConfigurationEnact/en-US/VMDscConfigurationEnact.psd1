ConvertFrom-StringData @'
    RoleMissingError = Please ensure that '{0}' role is installed with its PowerShell module.
    MoreThanOneVMExistsError = More than one VM with the name '{0}' exists.
    PendingConfigurationFound = Pending configuration found. It will be enacted.
    NoPendingConfiguration = No pending configuration. Noting to enact.    
    NewPSSession = Creating a new PS Session to the VM.
    CleanUpPSSession = Cleaning up PSSession.
    VMLCMStateError = VM LCM is not in an applicable state for the remote calls. It should be either Idle or PendingReboot.
    EnactPendingConfig = Enacting Pending configuration.
    ErrorInEnact = There was an error in the enact process.
    EnactSuccess = Configuration enact was successful.
    EnactNeedsReboot = Configuration Enact needs reboot. Configuration will continue after reboot.
    WaitingForVMToStart = Waiting for the virtual machine to restart.
    EnactInProgress = Configuration Enact after reboot is in progress.
    ErrorVMSession = Error in establishing a VM PS Session.
    WaitingForEnact = Waiting for Enact to complete.
    EnactTimedout = Configuration Enact timeout. This may not indicate a failure or error in enact. Check the target node for right status.
    CheckCompliance = Checking compliance after configuration enact.
    CheckEnactStatus = Start-DscConfiguation complete. Checking the configuration status.
    WaitBetweenRetry = Waiting between retries.
'@
