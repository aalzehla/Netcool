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
echo Execute: hostname                                                             
              hostname                                                             
echo "----------------------------------------------------------------------------" 
echo Execute: netstat -i                                                            
              netstat -i                                                            
echo "----------------------------------------------------------------------------" 
echo Execute: netstat -in                                                           
              netstat -in                                                           
echo "----------------------------------------------------------------------------" 
echo Execute: netstat -v                                                           
              netstat -v                                                           
echo "----------------------------------------------------------------------------" 
echo Execute: ifconfig -a                                                           
              ifconfig -a                                                           
echo "----------------------------------------------------------------------------" 
echo Execute: showmount -e                                                          
              showmount -e                                                          
echo "----------------------------------------------------------------------------"
echo Execute: no -a                                                                 
              no -a                                                                 
echo "----------------------------------------------------------------------------" 
echo Execute: cat /etc/resolve.conf                                                  
              cat /etc/resolve.conf                                                  
echo "----------------------------------------------------------------------------" 
echo Execute: nslookup -querytype=ANY $( hostname )                                 
              nslookup -querytype=ANY $( hostname )                                 
echo "----------------------------------------------------------------------------" 
echo Execute: arp -a                                                                
              arp -a                                                                
echo "----------------------------------------------------------------------------" 
echo Execute: nfsstat                                                               
              nfsstat                                                               
echo "----------------------------------------------------------------------------" 
