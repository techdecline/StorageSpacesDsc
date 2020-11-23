[DscResource()]
class VirtualDisk {
    [DscProperty(Key)]
    [string] $VirtualDiskName

    [DscProperty(Mandatory)]
    [String]$StoragePoolName

    [DscProperty(Mandatory)]
    [int64]$SizeBytes

    [DscProperty(NotConfigurable)]
    [String]$UniqueId


    
    # Gets the resource's current state.
    [VirtualDisk] Get() {
        $ErrorActionPreference = 'Stop'
        try {
            $vDiskObject = Get-VirtualDisk |Where-Object {$_.FriendlyName -eq $this.VirtualDiskName}
            $this.ResiliencySettingName = $vDiskObject.ResiliencySettingName
            $this.UniqueId = $vDiskObject.UniqueId
        }
        catch {
            throw "Could not get disk properties"
        }
        return $this
    }
    
    # Sets the desired state of the resource.
    [void] Set() {
        $ErrorActionPreference = 'Stop'
        try {
            $storagePool = Get-StoragePool -FriendlyName $this.StoragePoolName
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            throw "Could not find Storage Pool: $($this.StoragePoolName)"
        }
        try {
            New-VirtualDisk -StoragePoolFriendlyName $this.StoragePoolName -FriendlyName $this.VirtualDiskName -Size $this.SizeBytes
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            throw "Could not create Virtual Disk: $($error[0].exception.message)"
        }
    }
    
    # Tests if the resource is in the desired state.
    [bool] Test() {
        $ErrorActionPreference = 'Stop'
        $vDiskObject = Get-VirtualDisk |Where-Object {$_.FriendlyName -eq $this.VirtualDiskName}
        if ($vDiskObject) {
            return $true
        }
        else {
            return $false
        }
    }
}