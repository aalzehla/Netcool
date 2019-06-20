#!/bin/ksh
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
echo Execute: netstat -rv                                                           
              netstat -rv                                                           
echo "----------------------------------------------------------------------------"
echo Execute: ifconfig -a                                                          
              ifconfig -a                                                          
echo "----------------------------------------------------------------------------"
echo Execute: ndd -get /dev/tcp tcp_close_wait_interval                             
              ndd -get /dev/tcp tcp_close_wait_interval                             
echo "----------------------------------------------------------------------------"
echo Execute: ndd -get /dev/tcp tcp_fin_wait_2_flush_interval                       
              ndd -get /dev/tcp tcp_fin_wait_2_flush_interval                       
echo "----------------------------------------------------------------------------"
echo Execute: ndd -get /dev/tcp tcp_keepalive_interval                              
              ndd -get /dev/tcp tcp_keepalive_interval                              
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