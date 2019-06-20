#!/bin/sh

# This script will create 2 event rate situations and schedule a cronjob to run
# once per hour to calculate a baseline average override value for the situations.
# Calculate the baseline override slightly after the hour so that the situation has a chance
# to be evaluated using the previous override value

echo "This script will create 2 new situations within ITM TEPS and will also install a cronjob \
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
PAST_WEEK_COUNT=5
USERID=sysadmin
PASSWORD=
DB2_USERID=dbusr1
DB2_PASS=
TEPS_SYSTEM=localhost
LOW_STD_DEV_COUNT=2
HIGH_STD_DEV_COUNT=2
OMNIHOME="/opt/netcool/omnibus"
TACMD="/opt/IBM/ITM/bin/tacmd"
DB2_CMD="/opt/IBM/db2/V9.1/bin/db2"

echo -n "Enter OMNIbus directory [$OMNIHOME] : "
read CHOICE
OMNIHOME=${CHOICE:-$OMNIHOME}

echo -n "Enter number of past weeks for average event rate calculation [$PAST_WEEK_COUNT] : "
read CHOICE
PAST_WEEK_COUNT=${CHOICE:-$PAST_WEEK_COUNT}

echo -n "Enter the low threshold as average event rate minus a number of standard deviations [$LOW_STD_DEV_COUNT] : "
read CHOICE
LOW_STD_DEV_COUNT=${CHOICE:-$LOW_STD_DEV_COUNT}

echo -n "Enter the high threshold as average event rate plus a number of standard deviations [$HIGH_STD_DEV_COUNT] : "
read CHOICE
HIGH_STD_DEV_COUNT=${CHOICE:-$HIGH_STD_DEV_COUNT}

echo -n "Enter ITM TEPS hostname or ip address [$TEPS_SYSTEM] : "
read CHOICE
TEPS_SYSTEM=${CHOICE:-$TEPS_SYSTEM}

echo -n "Enter path to db2 command [$DB2_CMD] : "
read CHOICE
DB2_CMD=${CHOICE:-$DB2_CMD}

echo -n "Enter db2 user id [$DB2_USERID] : "
read CHOICE
DB2_USERID=${CHOICE:-$DB2_USERID}

echo -n "Enter db2 password [$DB2_PASS] : "
stty -echo
read CHOICE
DB2_PASS=${CHOICE:-$DB2_PASS}
stty echo;

echo -n -e "\nEnter path to ITM tacmd command [$TACMD] : "
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

BASELINE_DIR="$OMNIHOME/extensions/itmpredictive/baseline"
COMMAND="$BASELINE_DIR/dynamic_event_rate_baseline.sh -b '$BASELINE_DIR' \
-c $PAST_WEEK_COUNT -u $USERID -p $PASSWORD -t $TEPS_SYSTEM -m $TACMD -d '$DB2_CMD' \
-l AVG-$LOW_STD_DEV_COUNT -h AVG+$HIGH_STD_DEV_COUNT -du $DB2_USERID -dp $DB2_PASS"

echo -e "\n\nInstalling cronjob\n"
# Create a cronjob to update the situation override hourly, store original cronjob which can be restored
# Check that cron.orig.txt does not exist
PRE_ORIG_CRON_FILE=$BASELINE_DIR/cron.pre_install.txt
NEW_CRON_FILE=$BASELINE_DIR/new_cron.txt

COUNT=`crontab -l | grep dynamic_event_rate_baseline | wc -l`

if [ $COUNT != 0 ]
then
    echo -e "WARNING :- Event rate baseline cronjob is already installed"
else
    crontab -l > $PRE_ORIG_CRON_FILE
    crontab -l > $NEW_CRON_FILE
    echo "1 * * * * $COMMAND" >> $NEW_CRON_FILE
    crontab $NEW_CRON_FILE
    if [ $? != 0 ]
    then
        echo -e "Failed to install baseline cronjob"
    else
        echo -e "Baseline cronjob installed successfully, original crontab stored in file $PRE_ORIG_CRON_FILE"
    fi
    rm $NEW_CRON_FILE
fi

# Import the situation definitions

$TACMD login -s $TEPS_SYSTEM -u $USERID -p $PASSWORD
$TACMD  createSit --import $BASELINE_DIR/low_event_rate.sit
$TACMD  createSit --import $BASELINE_DIR/high_event_rate.sit

