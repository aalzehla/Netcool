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
echo Execute: date         				# Date and time
              date                                                          
echo "----------------------------------------------------------------------------" 
echo Execute: hostname                  # Host name
              hostname                                                              
echo "----------------------------------------------------------------------------" 
echo Execute: uname -a                  # Machine information & OS level
              uname -a                                                              
echo "----------------------------------------------------------------------------" 
echo Execute: oslevel                   # AIX version
              oslevel                                                               
echo "----------------------------------------------------------------------------"
echo Execute: instfix -i | grep AIX_ML  # AIX maintenance level
              instfix -i | grep AIX_ML   
echo "----------------------------------------------------------------------------" 
echo Execute: bootinfo -K               # 32-bit vs 64-bit
              bootinfo -K                                                           
echo "----------------------------------------------------------------------------" 
echo Execute: bootinfo -m               # Machine model
              bootinfo -m                                                           
echo "----------------------------------------------------------------------------" 
echo Execute: bootinfo -T               # Machine type
              bootinfo -T                                                           
echo "----------------------------------------------------------------------------" 
echo Execute: bootinfo -r               # Memory
              bootinfo -r                                                           
echo "----------------------------------------------------------------------------" 
echo Execute: lsattr -El sys0           # Memory
              lsattr -El sys0                                                       
echo "----------------------------------------------------------------------------" 
echo Execute: lsps -s                   # Paging space summary
              lsps -s                                                               
echo "----------------------------------------------------------------------------" 
echo Execute: lsps -a                   # Paging space details
              lsps -a                                                               
echo "----------------------------------------------------------------------------" 
echo Execute: df -k                     # File systems, space
              df -k                                                                 
echo "----------------------------------------------------------------------------" 
echo Execute: ulimit -a                 # Process limits
              ulimit -a                                                             
echo "----------------------------------------------------------------------------" 
echo Execute: /usr/samples/kernel/vmtune  # Kernel parameters
              /usr/samples/kernel/vmtune                                            
echo "----------------------------------------------------------------------------" 
echo Execute: vmstat                    # Vitual memory information
              vmstat                                                                
echo "----------------------------------------------------------------------------"
echo Execute: iostat                    # I/O statistics
              iostat                                                               
echo "----------------------------------------------------------------------------" 
echo Execute: lscfg                     # System hardware
              lscfg                                                                 
echo "----------------------------------------------------------------------------" 
echo Execute: lsdev -C -S a             # System hardware
              lsdev -C -S a                                                         
echo "----------------------------------------------------------------------------" 
echo Execute: bindprocessor -q          # Processors
              bindprocessor -q                                                     
echo "----------------------------------------------------------------------------" 
echo Execute: lsdev -Cc disk            # Physical disk infomation
              lsdev -Cc disk                                                        
echo "----------------------------------------------------------------------------" 
echo Execute: lspv                      # Physical disk infomation
              lspv                                                                  
echo "----------------------------------------------------------------------------" 
echo Execute: lsvg                      # Volume groups
              lsvg                                                                  
echo "----------------------------------------------------------------------------" 
echo Execute: lsfs                      # File systems
              lsfs                                                                  
echo "----------------------------------------------------------------------------" 
echo Execute: lsattr -El sys0           # System limits, settings
              lsattr -El sys0            
echo "----------------------------------------------------------------------------" 
echo Execute: ps -ef                    # Processes
              ps -ef                   
echo "----------------------------------------------------------------------------" 
echo Execute: lssrc -a                  # Subsystem status
              lssrc -a                  
echo "----------------------------------------------------------------------------" 
echo Execute: errpt                     # Error report
              errpt                      
echo "----------------------------------------------------------------------------" 
echo Execute: lsuser ALL                # User accounts
              lsuser ALL                
echo "----------------------------------------------------------------------------" 
echo Execute: lsgroup ALL               # Groups
              lsgroup ALL               
echo "----------------------------------------------------------------------------"
echo Execute: lslicense                 # Licenced users
              lslicense                
echo "----------------------------------------------------------------------------"
echo Execute: type java                 # Java JVM location
              type java                
echo "----------------------------------------------------------------------------"
echo Execute: java -version             # Java version
              java -version                                            
echo "----------------------------------------------------------------------------" 