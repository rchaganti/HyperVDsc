ConvertFrom-StringData @'
    RoleMissingError = Please ensure that '{0}' role is installed with its PowerShell module.
    MoreThanOneVMExistsError = More than one VM with the name '{0}' exists.
    ModulesNotFound = ModulesZip is not found at the path specified.
    ConfigMofNotFound = ConfigurationMof is not found.
    MetaConfigMofNotFound = Meta Configuration MOF is not found.
    NewPSSession = Creating a new PS Session to the VM.
    CopyModuleZip = Copying modules zip folder to the VM.
    CopyMetaMof = Copying meta configuration mof.
    NothingToPublish = The specified configuration does not specify anything to publish.
    CheckExistingMetaMof = Checking if there is an existing meta mof.
    BackupExistingMetaMof = Backing up existing meta mof.
    ExtractModules = Extract Modules zip folder inside VM.
    CopyMOF = Copying MOF file into the VM.
    TestCompliance = Testing configuration compliance in the VM.
    CleanUpFiles = Cleaning up copied files.
    CleanUpPSSession = Cleaning up PSSession.
    SystemInCompliance = System in complaince with configuration supplied. No action needed.
    SystemNotInCompliance = System not in compliance with configuration supplied. It will be enacted.
    VMLCMStateError = VM LCM is not in an applicable state for the remote calls. It should be either Idle or PendingReboot.
    ModuleFileMatching = Module zip is same across local and remote sessions. No need to copy again.
    ModuleFileMatchingButNotHash = Module zip name is same across local and remote sessions but hash is not matching. ModuleZip will be copied to remote session.
'@