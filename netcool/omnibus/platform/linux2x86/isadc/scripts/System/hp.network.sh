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
echo Execute: lanscan                                                               
              lanscan                                                               
echo "----------------------------------------------------------------------------" 
echo Execute: netstat -i                                                            
              netstat -i                                                            
echo "----------------------------------------------------------------------------" 
echo Execute: netstat -in                                                           
              netstat -in                                                           
echo "----------------------------------------------------------------------------" 
echo Execute: netstat -rv                                                           
              netstat -rv                                                           
echo "----------------------------------------------------------------------------"
lanscan -i |
  cut -f 1 -d ' ' |
  while read Interface
    do
      echo "-----------------------------"                                          
      echo Execute: ifconfig $Interface                                             
                    ifconfig $Interface                                             
    done
echo "-----------------------------"                                               
echo Execute: ifconfig lo0                                                          
              ifconfig lo0                                                          
echo "----------------------------------------------------------------------------" 
echo Execute: showmount -e                                                          
              showmount -e                                                          
echo "----------------------------------------------------------------------------" 
echo Execute: cat /etc/resolv.conf                                                  
              cat /etc/resolv.conf                                                  
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
