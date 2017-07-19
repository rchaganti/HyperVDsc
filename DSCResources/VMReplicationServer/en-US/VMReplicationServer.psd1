ConvertFrom-StringData @'
    RoleMissingError = Please ensure that '{0}' role is installed with its PowerShell module.
    GetVMReplicationServer = Getting VM replication server configuration.
    ReplicationEnabled = Replication is enabled.
    AuthenticationTypeMismatch = Authentication type is not matching. This needs an update.
    AuthenticationTypeMatch = Authentication type is configured as needed.
    KerberosAuthPortNotMatching = Kerberos authentication port is not matching. This needs an update.
    CertAuthPortNotMatching = Certificate authentication port not matching. This needs an update.
    KerbCertAuthPortNotMatching = Kerberos and Certificate authentication port not matching. This needs an update.
    ReplicationSourceNeedsUpdate = Replication source is not matching. This needs an update.
    SourceEntryMismatch = Authorized Server entries is not matching. This needs an update.
    ReplicationNotMatching = Replication enabled/disabled configuration not matching.
    AllowedAuthIsMandatory = AllowedAuthenticationType value must be provided when enabling replication.
    DefaultStorageLocationMandatoryForAllowAnyServer = Default Storage location is mandatory when allow any server is set to true.
    DefaultStorageLocationNotSupported = Default Storage location is not supported when allow any server is set to false.
    CertificateThumbprintMandatory = Certificate thumbprint is mandatory when authentication type is certificate or CertificateAndKerberos.    
    ReplicationNeedstobeEnabled = Replication is not enabled. It should be enabled.
    ReplicationConfigurationExistNoAction = Replication Configuration exists in desired state. No action needed.
    ReplicationShouldNotBeEnabled = Replication should be disabled.
    ReplicationNotEnabledNoAction = Replication is not enabled. No action needed.
    DefaultStorageLocationNotMatching = Default Storage Location is not matching. It needs to be updated.
    SetVMReplicationServer = Setting VM replication properties.
    EnableReplication = Replication will be enabled.
'@
