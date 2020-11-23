[DscResource()]
class Volume {
    [DscProperty(Key)]
    [string] $VirtualDiskName

    [DscProperty(NotConfigurable)]
    [int64]$SizeBytes

    [DscProperty(Mandatory)]
    [string]$DriveLetter

    [DscProperty(Mandatory=$false)]
    [string]$FileSystem = "NTFS"

    [DscProperty(NotConfigurable)]
    [String]$DiskId
    
    # Gets the resource's current state.
    [Volume] Get() {
        $ErrorActionPreference = 'Stop'
        try {
            write-Verbose "Looking up Virtual Disk: $($this.VirtualDiskName)"
            $diskObject = Get-Disk -FriendlyName $this.VirtualDiskName
            $this.DiskId = $diskObject.Path
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            throw "No matching disk found"
        }
        try {
            Write-Verbose "Reading partitions from virtual disk with Drive Letter: $($this.DriveLetter)"
            $partitionObj = Get-Partition -DiskId $diskObject.Path | Where-Object {$_.DriveLetter -eq $this.DriveLetter}
        }
        catch {
            throw "No matching partition found"
        }
        try {
            $volume = $partitionObj | Get-Volume
            $this.SizeBytes = $volume.Size
            $this.FileSystem = $volume.FileSystem
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            Write-Warning "No matching volume found"
            $this.SizeBytes = $null
            $this.FileSystem = $null
        }
        return $this
    }
    
    # Sets the desired state of the resource.
    [void] Set() {
        $ErrorActionPreference = 'Stop'
        try {
            $diskObject = Get-Disk -FriendlyName $this.VirtualDiskName
            $diskObject | New-Partition -UseMaximumSize -DriveLetter $this.DriveLetter
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            throw "Could not create Partition: $($error[0].exception.message)"
        }
        
        # Check for Cluster
        $isClustered = $false
        if ($diskObject.IsClustered) {
            $isClustered = $true
            write-verbose "Disk Resource is clustered. Will set to maintenance mode."
            Get-ClusterResource -Name "Cluster Virtual Disk ($($this.VirtualDiskName))" | Suspend-ClusterResource
        }
        else {
            write-verbose "Disk Resource is not clustered. Will set to maintenance mode."
        }

        try {
            Write-Verbose "Partitioning Volume: $($this.DriveLetter)"
            Get-Partition -DriveLetter $this.DriveLetter | Format-Volume -FileSystem $this.FileSystem -NewFileSystemLabel $this.VirtualDiskName
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
        if ($volume.FileSystem -eq $this.FileSystem) {
            return $true
        }
        else {
            return $false
        }
    }
}