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

        [uint]$waittime=5,

        [uint]$timebetweenpings=10,

        [bool]$serialmode=$true
    )
    $awaitvalue = $null
    if($null -eq $inputobject){
        Restart-Computer -ComputerName $node
        write-host "Restart Command send to $($node)"
        if($awaitalive -eq $true){
            $count = 0
            start-sleep -Seconds ($waittime * 60)
            while(($null -eq $awaitvalue) -or ($awaitvalue.pingsucceeded -ne "True")){
                $awaitvalue = Test-NetConnection -ComputerName $node
                $count++
                Start-Sleep -Seconds $timebetweenpings
            }
            write-output "Node $($node) is back online it took $($count * ($waittime * 60)) Minutes to complete."
        }
    }
    else{
        if($serialmode -eq $true){
            foreach($node in $inputobject){
                $nodename = $null
                $nodeName = $node.Name
                Restart-Computer -ComputerName $nodename
                write-host "Restart Command send to $($nodename)"
                if($awaitalive -eq $true){
                    $count = 0
                    start-sleep -Seconds ($waittime * 60)
                    while(($null -eq $awaitvalue) -or ($awaitvalue -ne "True")){
                        $awaitvalue = Test-NetConnection -ComputerName $node
                        $count++
                        Start-Sleep -Seconds $timebetweenpings
                    } 
                    write-output "Node $($nodename) is back online it took $($count * ($waittime * 60)) Minutes to complete."
                }
            }
            Write-Output "Reboots all sent"
        }else{
            restart-computer -ComputerName $inputobject.name
            write-output "Restarts sent to $($inputobject.name)"
            if($awaitalive -eq $true){
                $inputobject.name | % -Parallel {
                    $count = 0
                    start-sleep -Seconds ($using:waittime * 60)
                    while(($null -eq $using:awaitvalue) -or ($awaitvalue -ne "True")){
                        $awaitvalue = Test-NetConnection -ComputerName $_
                        $count++
                        Start-Sleep -Seconds $timebetweenpings
                    } 
                    write-output "Node $($_) is back online it took $($count * ($waittime * 60)) Minutes to complete."
                }
            }
        }
    }
}