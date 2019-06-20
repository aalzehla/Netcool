#!/bin/sh
#Licensed Materials - Property of IBM
#
#(C) Copyright IBM Corp. 2008 All Rights Reserved
#
#US Government Users Restricted Rights - Use, duplicate or
#disclosure restricted by GSA ADP Schedule Contract with
#IBM Corp.

#set -x
echo "----------------------------------------------------------------------------" 
echo Execute: rpm -qa                          # listing of the installed software 
              rpm -qa                          
echo "----------------------------------------------------------------------------"
echo Execute: rpm -qai                         # listing of the installed software 
              rpm -qai                         
echo "----------------------------------------------------------------------------" 
echo Execute: cat /proc/version                # unmodified kernel version and gcc compiler version used to build kernel
              cat /proc/version                
echo "----------------------------------------------------------------------------" 
echo Execute: cat /etc/issue                   # version of Linux and patch level
              cat /etc/issue                   
echo "----------------------------------------------------------------------------"
echo Execute: /sbin/chkconfig --list           # services installed and running at what run level
              /sbin/chkconfig --list           