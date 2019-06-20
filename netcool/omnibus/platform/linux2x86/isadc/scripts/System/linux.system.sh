#!/bin/sh
#Licensed Materials - Property of IBM
#
#(C) Copyright IBM Corp. 1997, 2002 All Rights Reserved
#
#US Government Users Restricted Rights - Use, duplicate or
#disclosure restricted by GSA ADP Schedule Contract with
#IBM Corp.

#set -x
echo "----------------------------------------------------------------------------" 
echo Execute: date                                 # Date and time
              date                                 
echo "----------------------------------------------------------------------------" 
echo Execute: hostname                             # Host name
              hostname                             
echo "----------------------------------------------------------------------------" 
echo Execute: uname -a                             # Machine information & OS level
              uname -a                             
echo "----------------------------------------------------------------------------"
echo Execute: cat /proc/meminfo                     # Memory and paging space info
              cat /proc/meminfo                     
echo "----------------------------------------------------------------------------"
echo Execute: free                                  # Memory and paging space info
              free                                  
echo "----------------------------------------------------------------------------"
echo Execute: df -k                                # File systems, space
              df -k                                
echo "----------------------------------------------------------------------------"
echo Execute: ulimit -a                            # Process limits
              ulimit -a                            
echo "----------------------------------------------------------------------------" 
echo Execute: vmstat                               # Virtual memory information
              vmstat                               
echo "----------------------------------------------------------------------------" 
echo Execute: iostat                               # I/O statistics
              iostat                               
echo "----------------------------------------------------------------------------"
echo Execute: cat /proc/cpuinfo                     # Processors
              cat /proc/cpuinfo                     
echo "----------------------------------------------------------------------------" 
echo Execute: ps -ef                               # Processes
              ps -ef                               
echo "----------------------------------------------------------------------------"
echo Execute: lspci                                #PCI Devices
              lspci
echo "----------------------------------------------------------------------------"
echo Execute: lsscsi                               #SCSI Devices
              lsscsi                        
echo "----------------------------------------------------------------------------"
echo Execute: type java                            # Java JVM location
              type java                            
echo "----------------------------------------------------------------------------" 
echo Execute: java -version                        # Java version
              java -version                         
echo "----------------------------------------------------------------------------"
