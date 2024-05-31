<#
    .SYNOPSIS
    Connects to the provided node(s) and tells it to completely restart

    .PARAMETER node
    For a single node you specify this parameter to reboot it will not work if you send an input object.

    .PARAMETER inputobject
    Supporting pipeline input, specifying this opens up 2 more parameters.

    .PARAMETER awaitalive
    Switch Param specifying it will cause the function to keep pinging the host until it comes back online requires ICMP incoming through the firewalls.

    .PARAMETER waittime
    Defaults to 5, this is how many minutes the command will wait for the host to completely stop everything before it begins the awaitalive loops.

    .PARAMETER timebetweenpings
    Defaults to 10, this is how many seconds between pings in the awaitalive loop as to not overload the script/network.

    .PARAMETER serialmode
    When input/pipeline input is provided you can switch between serial which processes each node one by one or in parallel mode, Parallel requires PS7 and is more taxing on compute.

    .INPUTS
    [system.array] or [system.object], these can be piped into the function for parallel mode.
#>
function Restart-ClusterNode {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]$node,

        [parameter(
            ValueFromPipeline=$true
        )]
        [system.array]$inputobject,

        [switch]$awaitalive,

        [Uint32]$waittime=5,

        [uint32]$timebetweenpings=10,

        [bool]$serialmode=$true
    )
    #MARK: Restart-ClusterNode
    Write-Debug "Parameters Provided$($node)`nPipelined:$([bool]$($Null -eq $inputobject))`nAwaitAlive:$($awaitalive)`nWaitTime:$($waittime) Mins`nTime Between Pings:$($timebetweenpings)`nSerialMode:$($serialmode)"
    $awaitvalue = $null
    if($null -eq $inputobject){
        write-debug "Not Pipelined Node is $($node)"
        Write-Verbose "Testing Connection on $($node)"
        $alive = Test-NetConnection -ComputerName $node
        Write-Debug "Connection Status ping:$($alive.pingsucceeded)"
        if($alive.pingsucceeded -eq $true){
            Write-Verbose "Sending Reboot to $($node)"
            Restart-Computer -ComputerName $node
            Write-Verbose "Reboot Sent!"
        }
        else{
            throw "Unable to resolve Node $($node)"
        }
        write-host "Restart Command send to $($node)"
        if($awaitalive -eq $true){
            Write-Verbose "Waitalive was enabled we are waiting $($waittime) Minutes for it to complete its shutdown before testing its connection over and over!"
            $count = 0
            start-sleep -Seconds ($waittime * 60)
            while(($null -eq $awaitvalue) -or ($awaitvalue.pingsucceeded -ne "True")){
                Write-Debug "Run $($count) starting last ones status is $($awaitvalue.pingsucceeded)"
                $awaitvalue = Test-NetConnection -ComputerName $node
                $count++
                Start-Sleep -Seconds $timebetweenpings
            }
            write-output "Node $($node) is back online it took $(($count * $timebetweenpings) /60) Minutes to complete."
        }
    }
    else{
        Write-Debug "In Pipeline Mode, With serial mode:$($serialmode), Powershell editon $($PSEdition) PS major Version $($PSVersionTable.PSVersion.ToString()[0])"
        if($serialmode -eq $true){
            Write-Verbose "Serial processing starting!"
            foreach($node in $inputobject){
                $nodename = $null
                $nodeName = $node.Name
                Write-Verbose "Processing $($nodename), we are checking for a heartbeat"
                $alive = Test-NetConnection -ComputerName $nodename
                if($alive.pingsucceeded -eq $true){
                    write-debug "Node $($nodename) is alive sending reboot."
                    Restart-Computer -ComputerName $nodename
                }
                else{
                    throw "Unable to resolve Node $($nodename)"
                }
                write-host "Restart Command send to $($nodename)"
                if($awaitalive -eq $true){
                    write-verbose "Awaitalive is Active, waiting on node $($nodename)"
                    $count = 0
                    start-sleep -Seconds ($waittime * 60)
                    while(($null -eq $awaitvalue) -or ($awaitvalue -ne "True")){
                        write-debug "Count: $($count) last ping status $($awaitalive.pingsucceeded)"
                        $awaitvalue = Test-NetConnection -ComputerName $node
                        $count++
                        Start-Sleep -Seconds $timebetweenpings
                    } 
                    write-output "Node $($nodename) is back online it took $(($count * $timebetweenpings) /60) Minutes to complete."
                }
            }
            Write-Output "Reboots all sent"
        }else{
            Write-Verbose "Parallel processing starting!`nChecking Functionality support for mode!!!"
            if(($PSEdition -eq "Core") -and ([UInt32]($PSVersionTable.PSVersion.ToString()[0]) -ge 7)){
                Write-Debug "Parallel is supported in current version`n Sending mass reboot."
                restart-computer -ComputerName $inputobject.name
                write-output "Restarts sent to $($inputobject.name)"
                if($awaitalive -eq $true){
                    write-debug "Await alive is enabled, With parallel mode Prepare for CPU & RAM to be consumed."
                    Write-Warning "Parallel mode will spawn several sub-process pwsh's and is taxing on the computer!!!"
                    $inputobject.name | foreach-object -Parallel {
                        Write-Debug "Hyper Parallel Activated!, handling node $($_)"
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
                Write-Debug "Attempted to use parallel in unsupported version"
                throw "Parallel only works in PS7"
            }
        }
    }
}