#!/bin/sh -x

# This script is designed to be run hourly by a cronjob and 
# will set a situation override value based on an average baseline of event rates 
# for the same hour in previous weeks.
CALENDAR_ENTRY_NAME=EventRateBaseLineCE
CLASSPATH=$CLASSPATH:./baseline.jar
TACMD="/opt/IBM/ITM/bin/tacmd"
DB2_CMD="/opt/IBM/db2/V9.1/bin/db2"
OMNIHOME=/opt/netcool/omnibus
BASELINE_DIR=$OMNIHOME/extensions/itmpredictive/baseline/
PAST_WEEK_COUNT=5
USERID=sysadmin
PASSWORD=
TEPS_SYSTEM=localhost
LOW_SITUATION=Low_Event_Rate_Baseline
HIGH_SITUATION=High_Event_Rate_Baseline
SYSTEM=*OMNIBUS_SERVER_AGENT
LOW_PREDICATE="KNO_EVENT_RATE_BY_NODE.EventCount LT 0"
HIGH_PREDICATE="KNO_EVENT_RATE_BY_NODE.EventCount GT 0"

# Situation override for high/low threshold is average event rate +/- 1 standard deviation
LOW_FUNCTION=AVG-2
HIGH_FUNCTION=AVG+2

for ARG in $*
do
    if [ "$LAST_ARG" = "-b" ]
    then
        BASELINE_DIR=$ARG
    fi
    
    if [ "$LAST_ARG" = "-c" ]
    then
        PAST_WEEK_COUNT=$ARG
    fi
    
    if [ "$LAST_ARG" = "-u" ]
    then
        USERID=$ARG
    fi
    
    if [ "$LAST_ARG" = "-p" ]
    then
        PASSWORD=$ARG
    fi
    
    if [ "$LAST_ARG" = "-du" ]
    then
        DB2_USERID=$ARG
    fi
    
    if [ "$LAST_ARG" = "-dp" ]
    then
        DB2_PASSWORD=$ARG
    fi
    
    if [ "$LAST_ARG" = "-t" ]
    then
        TEPS_SYSTEM=$ARG
    fi
    
    if [ "$LAST_ARG" = "-m" ]
    then
        TACMD=$ARG
    fi
    
    if [ "$LAST_ARG" = "-l" ]
    then
        LOW_FUNCTION=$ARG
    fi
    
    if [ "$LAST_ARG" = "-h" ]
    then
        HIGH_FUNCTION=$ARG
    fi
    
    if [ "$LAST_ARG" = "-d" ]
    then
        DB2_CMD=$ARG
    fi
    
    LAST_ARG=$ARG
done

cd $BASELINE_DIR
#Calculate the timestamp for x weeks ago and for now
START_TIME=`java -classpath $CLASSPATH CalcStartTime $PAST_WEEK_COUNT | awk -F: '{print $1}'`
END_TIME=`date +1%y%m%d%H0000000`
HOUR=`date +%k`
DAY_OF_WEEK=`date +%u`


# Delete the calendar entry if it exists, first deleting the previous override
$TACMD deleteoverride --userid $USERID --password $PASSWORD \
    --situation $LOW_SITUATION --system $SYSTEM --tepshostname $TEPS_SYSTEM -f
$TACMD deleteoverride --userid $USERID --password $PASSWORD \
    --situation $HIGH_SITUATION --system $SYSTEM --tepshostname $TEPS_SYSTEM -f
    
$TACMD login -s $TEPS_SYSTEM -u $USERID -p $PASSWORD
$TACMD deletecalendarentry -n $CALENDAR_ENTRY_NAME -f

# Create calendar entry for the current hour
$TACMD addcalendarentry -n $CALENDAR_ENTRY_NAME -d "Event Rate Baseline Current Hour" -c "* $HOUR * * $DAY_OF_WEEK"

# Run the command to generate a baseline average value based on event rates for the past weeks for the current
# hour and use this average value to override the event rate situations .
# First generate a list of the distinct nodes we have event data for.

DISTINCT_NODES=distinct_nodes.out
if [ -f $DISTINCT_NODES ]
then
   rm $DISTINCT_NODES
fi

echo "connect to WAREHOUS user $DB2_USERID using $DB2_PASSWORD" | $DB2_CMD
echo "select distinct \"NcoNode\" from ITMUSER.KNO_EVENT_RATE_BY_NODE where \"NcoNode\" !=  ''" | $DB2_CMD -x -r $DISTINCT_NODES

# Loop through the nodes and generate a high and low baseline override for each node

NODES=`cat $DISTINCT_NODES`
for NODE in $NODES
do
    $TACMD acceptbaseline --key "KNONCOERND.NCONODE EQ $NODE" -c $CALENDAR_ENTRY_NAME --userid $USERID --password $PASSWORD \
     --situation $LOW_SITUATION --system $SYSTEM --predicate "$LOW_PREDICATE" \
     --function $LOW_FUNCTION --startdata $START_TIME --enddata $END_TIME \
     --tepshostname $TEPS_SYSTEM

    $TACMD acceptbaseline --key "KNONCOERND.NCONODE EQ $NODE" -c $CALENDAR_ENTRY_NAME --userid $USERID --password $PASSWORD \
     --situation $HIGH_SITUATION --system $SYSTEM --predicate "$HIGH_PREDICATE" \
     --function $HIGH_FUNCTION --startdata $START_TIME --enddata $END_TIME \
     --tepshostname $TEPS_SYSTEM
done