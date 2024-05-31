# MicahZoft-MS-cluster
# This is a side project Powershell module for Microsoft Failover clusters to provid System administrators some commands to gather data of clusters.
Supported versions of powershell: 5.1, 7.4.2.  
Testing Support: Currently None Still getting hardware.  
***
Current Commands:  
Get-ClusterDiskSpace | This retrives the free space of cluster volumes.  
Get-ClusterNodeRAM   | This retrives the free memory of all cluster nodes.  
get-clusterNodeCPU   | This retrived the current CPU load on each cluster.  
Restart-Clusternode  | This tells specified cluster nodes to restart, potentially pinging the device until it comes online.  

***
Global Variables:  
Volumefree - the volume lable with the most free space, doesn't include how much it has.  
Memoryfreenode - the name of the node with the most free memory, doesn't include how much it has.  

***
## For New Ideas Please Create an Issue With a New Feature Tag.