Configuration VMCheckpoint
{
    Import-DscResource -ModuleName HyperVDsc -Name VMCheckpointConfiguration
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    VMCheckpointConfiguration VMCheckpoint
    {
        VMName = 'TestVM01'
        CheckpointType = 'ProductionOnly'
        CheckpointFileLocation = 'D:\Checkpoints'
    }
}
