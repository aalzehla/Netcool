#!/bin/sh
#Licensed Materials - Property of IBM
#
#(C) Copyright IBM Corp. 1997, 2002 All Rights Reserved
#
#US Government Users Restricted Rights - Use, duplicate or
#disclosure restricted by GSA ADP Schedule Contract with
#IBM Corp.

#set -x
PATHdmesg=$( whence dmesg )
if [ 0 = $? ]
  then
    echo "---------------------------------------------------------"
    echo Execute: $PATHdmesg                                        
                  $PATHdmesg                                        
  else
    echo "---------------------------------------------------------"
    echo dmesg - did not find the command in PATH                   
    if [ -x /sbin/dmesg ]
      then
        echo "---------------------------------------------------------"
        echo Execute: /sbin/dmesg                                       
                      /sbin/dmesg                                       
      else
        if [ -x /usr/sbin/dmesg ]
          then
            echo "---------------------------------------------------------"
            echo Execute: /usr/sbin/dmesg                                    
                          /usr/sbin/dmesg                                    
          else
            if [ -x /bin/dmesg ]
              then
                echo "---------------------------------------------------------"
                echo Execute: /bin/dmesg                                        
                              /bin/dmesg                                        
              else
                echo "---------------------------------------------------------"
                echo dmesg - did not find the command /usr/sbin or /sbin nor /bin
            fi
        fi
    fi
fi
echo "---------------------------------------------------------"
