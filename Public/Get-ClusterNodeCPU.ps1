<#
    .SYNOPSIS
    Connects to a cluster to retrive the current cpu load on nodes in 100.00% - 0%.

    .DESCRIPTION
    Connects to a cluster to retrive the current cpu load on nodes.

    .PARAMETER cluster
    This is the name of the cluster to connect to, it is required.

    .PARAMETER autosort
    Optional Switch, when supplied will cpuloads in decending order.

    .INPUTS
    Doesn't except pipeline inputs.

    .OUTPUTS
    system.psobject It will contain all the nodes names and their respective CPU load.
#>
function Get-ClusterNodeCPU{
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [string]$cluster,

        [switch]$autosort
    )
    $cpuloads = @()
    Write-Debug "Parameters Provided`nCluster: $($cluster)`nAutosort: $($autosort)`nUsername is $(((whoami).split("\"))[-1])`nUserdomain is $($env:USERDOMAIN)"
    Write-Verbose "Attempting Contact with Cluster $($cluster)."
    $nodes = get-clusternode -Cluster $cluster -Verbose:$false -ErrorAction silentlycontinue
    if($null -eq $nodes){
        Throw "Failed to connect to Cluster:$($cluster)."
    }
    Write-Debug "All Nodes:`n$($nodes)"
    Write-Verbose "Cluster connection Successfull Contacting Nodes now."
    foreach($node in $nodes){
        $cpu_load = $null
        Write-Verbose "Attempting Connection with Node $($node.name)"
        $cpu_load = Invoke-Command -Verbose:$false -ComputerName $node.Name -ScriptBlock {([Math]::Round(((Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue),2))}
        if($null -eq $cpu_load){
            Write-Error "Failed to contact node $($node.name) Verify Network connectivity."
        }else{
            Write-Verbose "Connected to Node $($node.name), its CPU load is $($cpu_load)"
        }
        $obj = new-object psobject -Property ([ordered]@{
            Node = $node.name
            CPU_load = $cpu_load
        })
        $cpuloads += $obj
    }
    write-debug $cpuloads
    if($autosort -eq $false){
        return $cpuloads
    }
    else{
        return ($cpuloads | Sort-Object -Property CPU_load -Descending:$true)
    }
}