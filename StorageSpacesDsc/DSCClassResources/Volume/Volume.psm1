[DscResource()]
class Volume {
    [DscProperty(Mandatory)]
    [string] $VirtualDiskName

    [DscProperty(Key)]
    [string]$DriveLetter

    [DscProperty(Mandatory=$false)]
    [string]$FileSystemType = "NTFS"

    [DscProperty(NotConfigurable)]
    [string]$OperationalStatus
    
    # Gets the resource's current state.
    [Volume] Get() {
        $ErrorActionPreference = 'Stop'
        try {
            $volumeObj = Get-Partition -DiskPath (Get-Disk -FriendlyName $this.VirtualDiskName).path | Where-Object {$this.DriveLetter -eq $_.DriveLetter} | Get-Volume
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            throw "No matching disk found"
        }

        $this.FileSystemType = $volumeObj.FileSystemType
        $this.OperationalStatus = $volumeObj.OperationalStatus
        return $this
    }
    
    # Sets the desired state of the resource.
    [void] Set() {
        # Check for Cluster
        $diskObject = Get-Disk -FriendlyName $this.VirtualDiskName
        $isClustered = $false
        if ($diskObject.IsClustered) {
            $isClustered = $true
            write-verbose "Disk Resource is clustered. Will set to maintenance mode."
            Get-ClusterResource -Name "Cluster Virtual Disk ($($this.VirtualDiskName))" | Suspend-ClusterResource
        }
        else {
            write-verbose "Disk Resource is not clustered."
        }

        try {
            Write-Verbose "Partitioning Volume: $($this.DriveLetter)"
            Get-Partition -DriveLetter $this.DriveLetter | Format-Volume -FileSystem $this.FileSystemType -NewFileSystemLabel $this.VirtualDiskName
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            throw "Could not format partition"
        }

        if ($isClustered) {
            Write-Verbose "Disabling Maintenance Mode on Disk: $($this.VirtualDiskName)"
            Get-ClusterResource -Name "Cluster Virtual Disk ($($this.VirtualDiskName))" | Resume-ClusterResource
        }
    }
    
    # Tests if the resource is in the desired state.
    [bool] Test() {
        $ErrorActionPreference = 'Stop'
        $volume = $this.Get()
        if ($volume.OperationalStatus -eq "OK") {
            return $true
        }
        else {
            return $false
        }
    }
}