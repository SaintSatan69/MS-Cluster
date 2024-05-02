#attempts to retrive all available memory on the cluster name provided 
#MARK: Get-clusterNodeRAM

    <#
        .SYNOPSIS
        This cmdlet is to retrive all cluster nodes free amount of memory.

        .DESCRIPTION
        This cmdlet is to retrive all cluster nodes free amount of memory.
        Has 2 parameters, Cluster and Autosort.

        .PARAMETER Cluster
        A required parameter to point the cmdlets to the clusters virtual network name account in AD.

        .PARAMETER autosort
        Optional Switch, when supplied will sort the return object in order of free memory.

        .PARAMETER GibiByteMode
        Optional Switch, when supplied will covert the memory from KiBibytes to GiBiBytes.

        .INPUTS
        Doesn't Support pipeline inputs.

        .OUTPUTS
        system.psobject. returns a PSobject that will hold all the cluster nodes and their respective Free memory in KibiBytes.

        .EXAMPLE
        PS> get-clusterNodeRAM -cluster Production-fc -verbose
        VERBOSE: Node Node2 Has the most free memory at 25.32GiBi
        Node        FreePhysicalMemory
        ------      ------------------
        Node1       11881676
        Node2       25884698
        Node3       15887654

        .EXAMPLE
        PS> get-clusterNodeRAM -cluster Production-fc -autosort:$true -debug
        DEBUG:<debugging messages>
        Node        FreePhysicalMemory
        ------      ------------------
        Node2       25884698
        Node3       15887654
        Node1       11881676
    #>
    function Get-ClusterNodeRAM {
        [CmdletBinding()]
        param(
            [parameter(Mandatory)]
            [string]$cluster,
    
            [switch]$autosort,
    
            [switch]$GibiByteMode
        )
        Write-Debug "Parameters Provided:`nClusterName:$($cluster)`nAutosort:$($autosort)`nUsername is $(((whoami).split("\"))[-1])`nUserdomain is $($env:USERDOMAIN)"
        Write-Verbose "Attempting connection to cluster $($cluster)"
        $nodes = get-clusternode -cluster $cluster -ErrorAction silentlycontinue -Verbose:$false
        write-debug "Nodes gathered from cluster are $($nodes.name)"
        if($null -eq $nodes){
            Throw "Failed to contact cluster $($cluster)"
        }
        Write-Verbose "Connection successfull"
        #initialize some vars
        $elected_node = ""
        $finalobj = @()
        #interates on each node and runs a command on them
        foreach($node in $nodes){
            write-debug "Processing $($node)"
            #just initalize mem for each loop to null in the event it can't contact just one node in the cluster
            $mem = $null
            try{
                Write-Verbose "Attempting a connection on node $($node.name)"
                #attmps to connect to each node and using WMI gather how much free memory is available, if it fails it will only write and error and keep going
                $mem = Invoke-Command -verbose:$false -ComputerName $node.Name -ScriptBlock{Get-CimInstance win32_operatingsystem | Select-Object -Property Freephysicalmemory} -Verbose:$false
                Write-Debug "Memory gathered from $($node) is $($mem)"
            }
            catch{
                Write-Error "Failed to connect to node $($node.Name)"
            }
            if($null -ne $mem){
                if($GibiByteMode -eq $false){
                    $memory = $mem
                }
                else{
                    $memory = ([unint]($mem) / 1024 / 1024)
                }
                $obj = New-Object psobject -Property ([ordered]@{
                    Node = $node.Name
                    Memory = $memory
                })
            }
            else{
                Write-Warning "At least 1 node unable to retrive memory information, there will be a NULL in output object for which ever node failed"
                $obj = new-object -Property ([ordered]@{
                    Node = $node.name
                    Memory = $null
                })
            }
            $finalobj += $obj
            #this determins which node has the most free memory so that in the future if your making roles on a cluster you know which one can support it the most.
            Write-Verbose "Gathering Node with the most free memory"
            if($mem.Freephysicalmemory -gt $free_mem){
                write-debug "Node $($node.name) has more free then current max $($free_mem)"
                $elected_node = $node.Name
                $free_mem = ([uint32](($mem.Freephysicalmemory) / 1024) / 1024)
            }
        }
        write-debug "Object dump $($finalobj)"
        Write-Verbose "Node $($elected_node) Has the most free memory at $($Free_mem)GiBi"\
        $global:MemoryFreeNode = $elected_node
        $global:MemoryFreeNode | out-null
        if($autosort -eq $false){
            return $finalobj
        }
        else{
            return ($finalobj | Sort-Object -Property Memory -Descending:$true)
        }
    
    }