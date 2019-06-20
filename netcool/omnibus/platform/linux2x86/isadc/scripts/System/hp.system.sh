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
echo Execute: date                       # /Date and time
              date                       
echo "----------------------------------------------------------------------------" 
echo Execute: hostname                   # /Host name
              hostname                   
echo "----------------------------------------------------------------------------" 
echo Execute: uname -a                   # /Machine infomation & OS level
              uname -a                   
echo "----------------------------------------------------------------------------" 
echo Execute: model                      # /Machine model
              model                      
echo "----------------------------------------------------------------------------" 
echo Execute: swapinfo -ta               # /Paging space information
              swapinfo -ta               
echo "----------------------------------------------------------------------------" 
echo Execute: bdf                        # /File systems, space
              bdf                        
echo "----------------------------------------------------------------------------" 
echo Execute: ulimit -f                  # /Process limits
              ulimit -f                  
echo "----------------------------------------------------------------------------" 
echo Execute: sysdef                     # /System definition
              sysdef                     
echo "----------------------------------------------------------------------------" 
echo Execute: vmstat                     # /Virtual memory information
              vmstat                     
echo "----------------------------------------------------------------------------" 
echo Execute: iostat                     # /I/O statistics
              iostat                     
echo "----------------------------------------------------------------------------"
echo Execute: ioscan -fCprocessor          # /Processors
              ioscan -fCprocessor          
echo "----------------------------------------------------------------------------"
echo Execute: ps -ef                     # /Processes
              ps -ef                     
echo "----------------------------------------------------------------------------" 
echo Execute: ioscan                     # /I/O scan
              ioscan                     
echo "----------------------------------------------------------------------------" 
echo Execute: type java                  # /Java JVM location
              type java                  
echo Execute: java -version               # /Java version
              java -version                                                         
echo "----------------------------------------------------------------------------" 
