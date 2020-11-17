# StorageSpacesDsc
Multiple PowerShell DSC Resources to deploy and manage Storage Spaces

# DSC Resources
## VirtualDisk
### Parameters
|Parameter|Attribute|DataType|Description|Allowed Values|
|---------|---------|--------|-----------|--------------|
|VirtualDiskName|Key|String|FriendlyName of the Virtual Disk to create||
|StoragePoolName|Write|String|FriendlyName of the Storage Pool to create the vDisk in| |
|SizeBytes|Write|int64|Desired size of the Virtual Disk||
|UniqueId|NotConfigurable|String|UniqueId of the Virtual Disk||

### Description
The VirtualDisk Class DSC Resource allows to create a Virtual Disk on an existing Storage Pool.

### Examples
``` 
configuration example_docker_install {
    param (
        # Node Name
        [Parameter(Mandatory=$false)]
        [string]
        $NodeName = 'localhost',

        # Setup Credential
        [Parameter(Mandatory)]
        [PSCredential]$SetupCredential
    )

    Import-DscResource -ModuleName MultisiteClusterDsc
    Import-DscResource -ModuleName StorageSpacesDirect

    node $NodeName
    {
        #region Enable Storage Spaces Direct
        StorageSpacesDirect 'cluster-s2d' {
            State = 'Enabled'
            ClusterName = 'exampleCluster'
            PsDscRunAsCredential = $SetupCredential
            SkipChecks = $true
        }
        #endregion

        #region Virtual Disk
        VirtualDisk ClusterDisk01 {
            VirtualDiskName = "disk1"
            StoragePoolName = "S2D on GLIMSQAAPP"
            SizeBytes=5GB
        }
        #endregion
    }
}
```