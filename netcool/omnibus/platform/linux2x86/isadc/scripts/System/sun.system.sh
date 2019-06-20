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
echo Execute: date                            # Date and time
              date                            
echo "----------------------------------------------------------------------------"
echo Execute: hostname                        # Host name
              hostname                        
echo "----------------------------------------------------------------------------"
echo Execute: uname -a                        # Machine information & OS level
              uname -a                        
echo "----------------------------------------------------------------------------" 
echo Execute: showrev                          # High level summary of the system
              showrev                          
echo "----------------------------------------------------------------------------"
echo Execute: swap -s                         # Swap space summary
              swap -s                         
echo "----------------------------------------------------------------------------" 
echo Execute: swap -l                         # Swap space list
              swap -l                         
echo "----------------------------------------------------------------------------" 
echo Execute: df -k                           # File systems, space
              df -k                           
echo "----------------------------------------------------------------------------" 
echo Execute: ulimit -a                       # Process limits
              ulimit -a                       
echo "----------------------------------------------------------------------------" 
echo Execute: sysdef                         # System definition
              sysdef                         
echo "----------------------------------------------------------------------------" 
echo Execute: vmstat                         # Virtual memory information
              vmstat                         
echo "----------------------------------------------------------------------------"
echo Execute: iostat                         # I/O statistics
              iostat                         
echo "----------------------------------------------------------------------------" 
echo Execute: iostat -En                     # I/O eos
              iostat -En                     
echo "----------------------------------------------------------------------------"
echo Execute: isainfo -v                     # Instruction set architectures
              isainfo -v                     
echo "----------------------------------------------------------------------------" 
echo Execute: isainfo -b                     # Instruction set architectures
              isainfo -b                     
echo "----------------------------------------------------------------------------"
echo Execute: psrinfo -v                      # Processors
              psrinfo -v                      
echo "----------------------------------------------------------------------------"
echo Execute: ps -ef                         # Processes
              ps -ef                         
echo "----------------------------------------------------------------------------" 
echo Execute: prtconf                         # Basic system information
              prtconf                         
echo "----------------------------------------------------------------------------"
echo Execute: type java                      # Java JVM location
              type java                      
echo "----------------------------------------------------------------------------"
echo Execute: java -version                   # Java version
              java -version                   
echo "----------------------------------------------------------------------------"
