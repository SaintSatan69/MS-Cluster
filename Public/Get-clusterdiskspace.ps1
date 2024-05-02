#attempts to gather the amount of free space on cluster volumes
#MARK: Get-clusterdiskspace


<#
    .SYNOPSIS
    This cmdlet is to retrive all cluster storage volumes and their current amount of free space.

    .DESCRIPTION
    This cmdlet is to retrive all cluster storage volumes and their current amount of free space.
    Has 3 parameters, Cluster, ClusterVolumeLable, and Autosort.

    .PARAMETER Cluster
    A required parameter to point the cmdlets to the clusters virtual network name account in AD.

    .PARAMETER ClusterVolumeLabe
    Optional parameter for the script to look for volumes that don't have the CSVFS file system of clusters that are used by the cluster.

    .PARAMETER autosort
    Optional Switch, when supplied will sort the return object in order of free space.

    .PARAMETER GibiByteMode
    Optional switch, when supplied will convert the capacity into GibiBytes instead of Bytes

    .INPUTS
    Doesn't Support pipeline inputs.

    .OUTPUTS
    system.psobject. returns a PSobject that will hold all the cluster volumes and their respective Free space in Bytes.

    .EXAMPLE
    PS> get-clusterdiskspace -cluster Production-fc -verbose
    VERBOSE: Volume Volume2 is the most free at 928.560108184814 GiBi
    Volume      Freespace
    ------      ---------
    Volume1  217502851072
    volume2  997033824256

    .EXAMPLE
    PS> get-clusterdiskspace -cluster Production-fc -autosort:$true -debug
    DEBUG:<debugging messages>
    Volume      Freespace
    ------      ---------
    volume2  997033824256
    Volume1  217502851072

#>
function Get-ClusterDiskSpace{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$cluster,

        [string]$ClusterVolumeLable,

        [switch]$autosort,

        [switch]$GibiByteMode
    )

    Write-Debug "Parameters provided:`nAutosort:$($autosort)`nClustername:$($cluster)`nCluser volume label:$($ClusterVolumeLable)`nUsername is $(((whoami).split("\"))[-1])`nUserdomain is $($env:USERDOMAIN)"
    #attempts to connect to a cluster and retrive all nodes, which ever one it gets at the top of the list will have a command run on it.
    Write-Verbose "Attempting to connect to cluster $($cluster)"
    $nodes = get-clusternode -cluster $cluster -ErrorAction silentlycontinue -Verbose:$false
    #Nodes will be null if theres an issue contacting the cluster provided.
    if($null -eq $nodes){
        throw "Failed to contact cluster $($cluster)."
    }
    $node = ($nodes[0]).Name
    write-debug "Nodes gathered from cluster are $($nodes) Node elected for gathering volume information is $($node)"
    Write-Verbose "Connection Sucess! Node:$($node) has been selected"
    try{
        Write-Debug "Invoking command on node $($node)"
        #runs a command one that node that uses WMI to retrive the amount of free space on any volume that contains the lable for clustered volumes or any volume formatted into the cluster file system
        $volumes = Invoke-Command -verbose:$false -ComputerName $node -ScriptBlock {Get-CimInstance win32_volume | Where-Object {($_.label -like "*$ClusterVolumeLable*") -or ($_.Filesystem -like "CSVFS*")} | Select-Object Label,FreeSpace} -Verbose:$false
        Write-Verbose "Connected to Node $($node) and have gathered cluster volume information"
    }
    catch{
        Write-Debug "Node connection FAILURE"
        throw "Failed to connect to node $($node) to gather volume information, Verify Network connectivity and security permissons."
    }
    #initalizing some variables so logic doesn't break
    $max_size_rem = 0
    $most_free_volume = $null
    $fullobj = @()
    write-verbose "Processing Volume data"
    #this interates over all the volumes gathered from the node to determine which volume has the more free space and throws all volumes into an array for output
    foreach($volume in $volumes){
        Write-Debug "Processing volume $($volume.label) which has a free space value of $($volume.FreeSpace)bytes"
        if($GibiByteMode -eq $false){
            $space = $volume.FreeSpace
        }
        else{
            $space = ([unint](((($volume.FreeSpace) / 1024) / 1024) / 1024))
        }
        $obj = New-Object psobject -Property ([ordered]@{
            Volume = $volume.label
            Freespace = $space
        })
        if([UInt64]$volume.Freespace -gt [UInt64]$max_size_rem){
            Write-Debug "Volume $($volume.label) Has surpased the current highest volume size of $($max_size_rem)"
            $max_size_rem = [unint64]($volume.Freespace)
            $most_free_volume = $volume.Label
        }
        $fullobj += $obj
    }
    Write-Debug "Object Dump $($fullobj)"
    Write-verbose "Volume $($most_free_volume) is the most free at $([uint32]((($max_size_rem / 1024) / 1024) / 1024))GiB"
    $Global:Volumefree = $most_free_volume
    $Global:Volumefree | out-null
    if($autosort -eq $false){
        Write-Debug "No Autosort"
        return $fullobj
    }
    else {
        Write-Debug "Autosort Enabled"
        return ($fullobj | Sort-Object -Property FreeSpace -Descending:$true)
    }

}
