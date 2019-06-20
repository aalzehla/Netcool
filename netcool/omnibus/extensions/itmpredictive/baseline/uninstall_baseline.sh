#!/bin/sh

# This script will delete the 2 event rate situations and restore the original cronjob.

echo "This script will delete the event rate situations and delete the cronjob \
to run the hourly baseline event rate calculation."
echo -n "Do you wish to proceed <y or n> ? "
read WISH
echo

if [ "$WISH" = "n" ] ; then
echo "Aborting script"
exit
fi

if [ ! "$WISH" = "y" ] ; then
echo "Invalid option, exiting"
exit
fi 

# Prompt user for configuration parameters
USERID=sysadmin
PASSWORD=
TEPS_SYSTEM=localhost
SYSTEM=*OMNIBUS_SERVER_AGENT
TACMD="/opt/IBM/ITM/bin/tacmd"
CALENDAR_ENTRY_NAME=EventRateBaseLineCE
LOW_SITUATION=Low_Event_Rate_Baseline
HIGH_SITUATION=High_Event_Rate_Baseline
OMNIHOME="/opt/netcool/omnibus"

echo -n "Enter OMNIbus directory [$OMNIHOME] : "
read CHOICE
OMNIHOME=${CHOICE:-$OMNIHOME}

echo -n "Enter ITM TEPS hostname or ip address [$TEPS_SYSTEM] : "
read CHOICE
TEPS_SYSTEM=${CHOICE:-$TEPS_SYSTEM}

echo -n "Enter path to ITM tacmd command [$TACMD] : "
read CHOICE
TACMD=${CHOICE:-$TACMD}

echo -n "Enter ITM TEPS User Id [$USERID] : "
read CHOICE
USERID=${CHOICE:-$USERID}

# Do not show entered password
echo -n "Enter ITM TEPS Password [$PASSWORD] : "
stty -echo
read CHOICE
PASSWORD=${CHOICE:-$PASSWORD}
stty echo;

echo

BASELINE_DIR="$OMNIHOME/extensions/itmpredictive/baseline"

# Delete the calendar entry if it exists, first deleting the previous override
$TACMD deleteoverride --userid $USERID --password $PASSWORD \
    --situation $LOW_SITUATION --system $SYSTEM --tepshostname $TEPS_SYSTEM -f
$TACMD deleteoverride --userid $USERID --password $PASSWORD \
    --situation $HIGH_SITUATION --system $SYSTEM --tepshostname $TEPS_SYSTEM -f
    
$TACMD login -s $TEPS_SYSTEM -u $USERID -p $PASSWORD
$TACMD deletecalendarentry -n $CALENDAR_ENTRY_NAME -f

# Delete the situations
$TACMD deleteSit -s $LOW_SITUATION -f
$TACMD deleteSit -s $HIGH_SITUATION -f
# Restore the original crontab from file
echo -e "\n\nRestoring original crontab\n"

PRE_ORIG_CRON_FILE=$BASELINE_DIR/cron.pre_install.txt
POST_ORIG_CRON_FILE=$BASELINE_DIR/cron.post_install.txt
NEW_CRON_FILE=$BASELINE_DIR/new_cron.txt

crontab -l > $POST_ORIG_CRON_FILE
crontab -l  | grep -v dynamic_event_rate_baseline > $NEW_CRON_FILE
crontab $NEW_CRON_FILE
if [ $? == 0 ]
then
    echo -e "Original crontab restored, please manually remove original crontab files:\n$PRE_ORIG_CRON_FILE \n$POST_ORIG_CRON_FILE"
else
    echo -e "Failed to restore original crontab, original crontab is in the file $POST_ORIG_CRON_FILE"
fi
rm $NEW_CRON_FILE


