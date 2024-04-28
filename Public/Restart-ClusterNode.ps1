<#
    .SYNOPSIS
    Connects to the provided node(s) and tells it to completely restart


#>
function Restart-ClusterNode {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]$node,

        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.array]$inputobject,

        [bool]$awaitalive=$true,

        [Uint32]$waittime=5,

        [uint32]$timebetweenpings=10,

        [bool]$serialmode=$true
    )
    $awaitvalue = $null
    if($null -eq $inputobject){
        $alive = Test-NetConnection -ComputerName $node
        if($alive.pingsucceeded -eq $true){
            Restart-Computer -ComputerName $node
        }
        else{
            throw "Unable to resolve Node $($node)"
        }
        write-host "Restart Command send to $($node)"
        if($awaitalive -eq $true){
            $count = 0
            start-sleep -Seconds ($waittime * 60)
            while(($null -eq $awaitvalue) -or ($awaitvalue.pingsucceeded -ne "True")){
                $awaitvalue = Test-NetConnection -ComputerName $node
                $count++
                Start-Sleep -Seconds $timebetweenpings
            }
            write-output "Node $($node) is back online it took $(($count * $timebetweenpings) /60) Minutes to complete."
        }
    }
    else{
        if($serialmode -eq $true){
            foreach($node in $inputobject){
                $nodename = $null
                $nodeName = $node.Name
                $alive = Test-NetConnection -ComputerName $nodename
                if($alive.pingsucceeded -eq $true){
                    Restart-Computer -ComputerName $nodename
                }
                else{
                    throw "Unable to resolve Node $($nodename)"
                }
                write-host "Restart Command send to $($nodename)"
                if($awaitalive -eq $true){
                    $count = 0
                    start-sleep -Seconds ($waittime * 60)
                    while(($null -eq $awaitvalue) -or ($awaitvalue -ne "True")){
                        $awaitvalue = Test-NetConnection -ComputerName $node
                        $count++
                        Start-Sleep -Seconds $timebetweenpings
                    } 
                    write-output "Node $($nodename) is back online it took $(($count * $timebetweenpings) /60) Minutes to complete."
                }
            }
            Write-Output "Reboots all sent"
        }else{
            if(($PSEdition -eq "Core") -and ([UInt32]($PSVersionTable.PSVersion.ToString()[0]) -ge 7)){
                restart-computer -ComputerName $inputobject.name
                write-output "Restarts sent to $($inputobject.name)"
                if($awaitalive -eq $true){
                    $inputobject.name | % -Parallel {
                        $count = 0
                        start-sleep -Seconds ($using:waittime * 60)
                        while(($null -eq $using:awaitvalue) -or ($awaitvalue -ne "True")){
                            $awaitvalue = Test-NetConnection -ComputerName $_
                            $count++
                            Start-Sleep -Seconds $using:timebetweenpings
                        } 
                        write-output "Node $($_) is back online it took $(($count * $using:timebetweenpings) /60) Minutes to complete."
                    }
                }
            }else{
                throw "Parallel only works in PS7"
            }
        }
    }
}