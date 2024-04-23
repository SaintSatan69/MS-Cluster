<#
    .DESCRIPTION
    This Module is for a couple handy commands for Microsoft Failover clusters that the default powershell module doesn't provide.
    Microsoft Makes some values gathered be in different units, storage is returned in Bytes and Memory is returned in KibiBytes. -verbose is recommend to be used,
    This provides information as it is running and will tell you the best of the values in GibiBytes sizes which are more readable. Debug is available as well both spit,
    Lots of information that doesn't get sent to variables.
#>


#MARK: Initialization of module
if($IsWindows -eq "True"){
}
else{
    throw "Not windows, Only supports windows"
}
if($PSEdition -ne "Desktop"){
    Write-Warning "You are using Powershell Core, The Microsoft Cluster module only works in Windows Powershell. This module will Run still but the Failoverclusters module will run in compatibily mode increasing latency!"
}
try{
    if($PSEdition -ne "Desktop"){
        import-module failoverclusters -UseWindowsPowerShell -WarningAction SilentlyContinue
    }
    else{
        import-module failoverclusters
    }
}
catch{
    Throw "Missing Failoverclusters Module from the RSAT optional feature please install that first."
}
Write-Warning "Make sure your account: $(whoami) has the permissions to connect to your cluster through winRM."

Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" | ForEach-Object {

    . $_.FullName

}
$onremovescript = {
    remove-module FailoverClusters -ErrorAction SilentlyContinue
    Write-Output "Module Cleanup Complete."
}
$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript
$registerEngineEventSplat = @{
    SourceIdentifier = ([System.Management.Automation.PsEngineEvent]::Exiting)
    Action = $OnRemoveScript
}
Register-EngineEvent @registerEngineEventSplat
#for a funny and accurate picture https://imgflip.com/i/8m1gc3