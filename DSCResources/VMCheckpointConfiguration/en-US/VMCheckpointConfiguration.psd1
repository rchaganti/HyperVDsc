ConvertFrom-StringData @'
    RoleMissingError = Please ensure that '{0}' role is installed with its PowerShell module.
    GetVM = Get Virtual machine information.
    NoVMFound = Specified VM does not exist.
    GetVMCheckPointConfiguration = Getting VM Checkpoint configuration.
    CheckpointLocationNotSpecified = Checkpoint file location is mandatory when checkpoint type is not Disabled.
    VMCheckpointInDesiredState = VM checkpoint configuration is in desired state.
    CheckpointTypeNotMatching = VM Checkpoint type is not matching. It needs to be updated.
    CheckpointFileLocationNotMatching = VM Checkpoint file location is not matching. It needs to be updated.
    UpdateCheckpointType = Checkpoint type will be configured.
    UpdateCheckpointFileLocation = Checkpoint filelocation will be configured.
    PerformCheckPointUpdate = Performing Checkpoint configuration update.
    CheckpointFileLocationCannotChange = Checkpoint file location cannot be changed while there are existing snapshots.
'@
