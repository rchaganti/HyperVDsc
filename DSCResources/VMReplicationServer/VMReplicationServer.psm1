#region helper modules
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
                               -ChildPath (Join-Path -Path 'HyperVDsc.Helper' `
                                                     -ChildPath 'HyperVDsc.Helper.psm1'))
#endregion

#region localizeddata
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData -BindingVariable LocalizedData -filename VMReplicationServer.psd1 `
                         -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
} 
else
{
    #fallback to en-US
    Import-LocalizedData -BindingVariable LocalizedData -filename VMReplicationServer.psd1 `
                         -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

<#
.SYNOPSIS
Gets the current state of the VMReplicationServer resource.

.DESCRIPTION
Gets the current state of the VMReplicationServer resource.

.PARAMETER IsSingleInstance
Specifies if this resource instance is a single instance.
The value to this parameter should always be Yes.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    Write-Verbose -Message $localizedData.GetVMReplicationServer
    $vmReplicationServer = Get-VMReplicationServer

    $configuration = @{
        IsSingleInstance = $IsSingleInstance
        ReplicationEnabled = $vmReplicationServer.ReplicationEnabled
        AllowedAuthenticationType = $vmReplicationServer.AllowedAuthenticationType
        KerberosAuthenticationPort = $vmReplicationServer.KerberosAuthenticationPort
        CertificateAuthenticationPort = $vmReplicationServer.CertificateAuthenticationPort
        DefaultStorageLocation = $vmReplicationServer.DefaultStorageLocation
        ReplicationAllowedFromAnyServer = $vmReplicationServer.ReplicationAllowedFromAnyServer
    }

    return $configuration
}

<#
.SYNOPSIS
Sets the VMReplicationServer resource to desired state.

.DESCRIPTION
Sets the VMReplicationServer resource to desired state.

.PARAMETER IsSingleInstance
Specifies if this resource instance is a single instance.
The value to this parameter should always be Yes.
This is the key property.

.PARAMETER ReplicationEnabled
Specifies if Replication is enabled or not. Default value is $false.

.PARAMETER AllowedAuthenticationType
Specifies the allowed authentication type.
Allowed values are 'Kerberos', 'Certificate', 'CertificateAndKerberos'.

.PARAMETER DefaultStorageLocation
Specifies the location for replicated files.

.PARAMETER CertificateThumbprint
Specifies the certificate thumbprint for the certificate based authentication.

.PARAMETER ReplicationAllowedFromAnyServer
Specifies if the replication is allowed from any server.
This should be set to $false if there are specified servers only should be allowed.
Default value is $true.

.PARAMETER CertificateAuthenticationPort
Specifies the port number for certificate based authentication. Default port is 443.

.PARAMETER KerberosAuthenticationPort
Specifies the port number for Kerberos based authentication. Default port is 80.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string]
        $IsSingleInstance,

        [Parameter()]
        [Boolean]
        $ReplicationEnabled = $false,

        [Parameter()]
        [String]
        [ValidateSet('Kerberos', 'Certificate', 'CertificateAndKerberos')]
        $AllowedAuthenticationType,

        [Parameter()]
        [String]
        $DefaultStorageLocation,

        [Parameter()]
        [String]
        $CertificateThumbprint,

        [Parameter()]
        [Boolean]
        $ReplicationAllowedFromAnyServer = $true,

        [Parameter()]
        [Int]
        $CertificateAuthenticationPort = 443,

        [Parameter()]
        [Int]
        $KerberosAuthenticationPort = 80
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    Write-Verbose -Message $localizedData.GetVMReplicationServer
    $vmReplicationServer = Get-VMReplicationServer

    #Parameter checks; this can go into a common function later [TODO]
    if ($ReplicationEnabled)
    {
        if (!$AllowedAuthenticationType)
        {
            throw $localizedData.AllowedAuthIsMandatory
        }
        
        if ($ReplicationAllowedFromAnyServer -and !$DefaultStorageLocation)
        {
            throw $localizedData.DefaultStorageLocationMandatoryForAllowAnyServer
        }

        if (!$ReplicationAllowedFromAnyServer -and $DefaultStorageLocation)
        {
            throw $localizedData.DefaultStorageLocationNotSupported
        }

        if ((($AllowedAuthenticationType -eq 'Certifiacte') -or ($AllowedAuthenticationType -eq 'CertificateAndKerberos')) -and !$CertificateThumbprint)
        {
            throw $localizedData.CertificateThumbprintMandatory
        }
    }

    #We don't need to check for mismatches in condfiguration. 
    #Create the right argument list and set
    Write-Verbose -Message $localizedData.SetVMReplicationServer

    $setParameters = @{
        ReplicationEnabled = $ReplicationEnabled
    }

    if ($ReplicationEnabled)
    {
        Write-Verbose -Message $localizedData.EnableReplication
        $setParameters.Add('AllowedAuthenticationType', $AllowedAuthenticationType)
        $setParameters.Add('ReplicationAllowedFromAnyServer', $ReplicationAllowedFromAnyServer)

        switch ($AllowedAuthenticationType)
        {
            "Kerberos" {
                $setParameters.Add('KerberosAuthenticationPort', $KerberosAuthenticationPort)
            }

            "Certificate" {
                $setParameters.Add('CertificateAuthenticationPort', $CertificateAuthenticationPort)
                $setParameters.Add('CertificateThumbprint', $CertificateThumbprint)
            }

            "CertificateAndKerberos" {
                $setParameters.Add('KerberosAuthenticationPort', $KerberosAuthenticationPort)
                $setParameters.Add('CertificateAuthenticationPort', $CertificateAuthenticationPort)
                $setParameters.Add('CertificateThumbprint', $CertificateThumbprint)
            }
        }

        if ($ReplicationAllowedFromAnyServer)
        {
            $setParameters.Add('DefaultStorageLocation', $DefaultStorageLocation)
        }
    }

    Write-Verbose -Message $localizedData.SetVMReplicationServer
    Set-VMReplicationServer @setParameters
}

<#
.SYNOPSIS
Tests if the VMReplicationServer resource is in desired state or not.

.DESCRIPTION
Tests if the VMReplicationServer resource is in desired state or not.

.PARAMETER IsSingleInstance
Specifies if this resource instance is a single instance.
The value to this parameter should always be Yes.
This is the key property.

.PARAMETER ReplicationEnabled
Specifies if Replication is enabled or not. Default value is $false.

.PARAMETER AllowedAuthenticationType
Specifies the allowed authentication type.
Allowed values are 'Kerberos', 'Certificate', 'CertificateAndKerberos'.

.PARAMETER DefaultStorageLocation
Specifies the location for replicated files.

.PARAMETER CertificateThumbprint
Specifies the certificate thumbprint for the certificate based authentication.

.PARAMETER ReplicationAllowedFromAnyServer
Specifies if the replication is allowed from any server.
This should be set to $false if there are specified servers only should be allowed.
Default value is $true.

.PARAMETER CertificateAuthenticationPort
Specifies the port number for certificate based authentication. Default port is 443.

.PARAMETER KerberosAuthenticationPort
Specifies the port number for Kerberos based authentication. Default port is 80.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string]
        $IsSingleInstance,

        [Parameter()]
        [Boolean]
        $ReplicationEnabled = $false,

        [Parameter()]
        [String]
        [ValidateSet('Kerberos', 'Certificate', 'CertificateAndKerberos')]
        $AllowedAuthenticationType,

        [Parameter()]
        [String]
        $DefaultStorageLocation,

        [Parameter()]
        [String]
        $CertificateThumbprint,

        [Parameter()]
        [Boolean]
        $ReplicationAllowedFromAnyServer = $true,

        [Parameter()]
        [Int]
        $CertificateAuthenticationPort = 443,

        [Parameter()]
        [Int]
        $KerberosAuthenticationPort = 80
    )

    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw ($localizedData.RoleMissingError -f 'Hyper-V')
    }

    #Parameter checks; this can go into a common function later [TODO]
    if ($ReplicationEnabled)
    {
        if (!$AllowedAuthenticationType)
        {
            throw $localizedData.AllowedAuthIsMandatory
        }
        
        if ($ReplicationAllowedFromAnyServer -and !$DefaultStorageLocation)
        {
            throw $localizedData.DefaultStorageLocationMandatoryForAllowAnyServer
        }

        if (!$ReplicationAllowedFromAnyServer -and $DefaultStorageLocation)
        {
            throw $localizedData.DefaultStorageLocationNotSupported
        }

        if ((($AllowedAuthenticationType -eq 'Certifiacte') -or ($AllowedAuthenticationType -eq 'CertificateAndKerberos')) -and !$CertificateThumbprint)
        {
            throw $localizedData.CertificateThumbprintMandatory
        }
    }

    Write-Verbose -Message $localizedData.GetVMReplicationServer
    $vmReplicationServer = Get-VMReplicationServer

    if ($ReplicationEnabled)
    {
        if ($vmReplicationServer.ReplicationEnabled)
        {
            Write-Verbose -Message $localizedData.ReplicationEnabled

            #Check if other properties match. Start with Authentication Type.
            if ($AllowedAuthenticationType -ne $vmReplicationServer.AllowedAuthenticationType)
            {
                Write-Verbose -Message $localizedData.AuthenticationTypeMismatch
                return $false
            }
            else
            {
                Write-Verbose -Message $localizedData.AuthenticationTypeMatch

                #Check othe properties relevant to the authentication type
                switch ($AllowedAuthenticationType)
                {
                    "Kerberos" {
                        if ($KerberosAuthenticationPort -ne $vmReplicationServer.KerberosAuthenticationPort)
                        {
                            Write-Verbose -Message $localizedData.KerberosAuthPortNotMatching
                            return $false
                        }
                    }

                    "Certificate" {
                        if ($CertificateAuthenticationPort -ne $vmReplicationServer.CertificateAuthenticationPort)
                        {
                            Write-Verbose -Message $localizedData.CertAuthPortNotMatching
                            return $false
                        }
                    }

                    "CertificateAndKerberos" {
                        if (($CertificateAuthenticationPort -ne $vmReplicationServer.CertificateAuthenticationPort) -and ($KerberosAuthenticationPort -ne $vmReplicationServer.KerberosAuthenticationPort))
                        {
                            Write-Verbose -Message $localizedData.KerbCertAuthPortNotMatching
                            return $false
                        }
                    }
                }
            }

            #Check if replication is enabled from any server
            if ($ReplicationAllowedFromAnyServer -ne $vmReplicationServer.ReplicationAllowedFromAnyServer)
            {
                Write-Verbose -Message $localizedData.ReplicationSourceNeedsUpdate
                return $false
            }

            if ($DefaultStorageLocation -ne $vmReplicationServer.DefaultStorageLocation)
            {
                Write-Verbose -Message $localizedData.DefaultStorageLocationNotMatching
                return $false
            }
            
            Write-Verbose -Message $localizedData.ReplicationConfigurationExistNoAction
            return $true
        }
        else
        {
            Write-Verbose -Message $localizedData.ReplicationNeedstobeEnabled
            return $false
        }
    }
    else
    {
        if ($vmReplicationServer.ReplicationEnabled)
        {
            Write-Verbose -Message $localizedData.ReplicationShouldNotBeEnabled
            return $false
        }
        else
        {
            Write-Verbose -Message $localizedData.ReplicationNotEnabledNoAction
            return $true
        }

    }
}

Export-ModuleMember -Function *-TargetResource
