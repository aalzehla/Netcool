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
echo Execute: id                                # User id executing Collector
              id                                
echo "----------------------------------------------------------------------------" 
echo Execute: env                               # Environment variables
              env                               
echo "----------------------------------------------------------------------------" 
echo Execute: /sbin/runlevel                    # Run level
              /sbin/runlevel                    
