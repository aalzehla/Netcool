#!/bin/ksh

function activate_domain
{
    print "Activating domain $1:"
    [ $isTEMS ] && generate_odi_tems_pre
    generate_odi $1
    [ $isTEMS ] && activate_domain_tems $1
    [ $isTEPS ] && activate_domain_teps $1
    [ $isPA ] && activate_domain_pa $1
}

function activate_domain_tems
{
    print " - activating TEMS support"
    . $CHOME/config/*_ms_*.config
    export LIBPATH LD_LIBRARY_PATH SHLIB_PATH KBB_RAS1 SQLLIB
    ksminst -h $CHOME -f  -v 610 -e $DDIR/$1/files >>$LOGFILE 2>&1
    [ $? -eq 0 ] || fail_exit "Problem activating TEMS support (files copying)"
    installVer=$(grep "^ver *=" $CHOME/registry/cienv.ver 2>/dev/null | cut -d"=" -f2)
    echo "ITM installer version = $installVer" >>$LOGFILE
    if [ "$installVer" -lt 621 ]
    then
        #pre 6.2.1 release
        ksminst -h $CHOME -f  -v 610 -s $DDIR/$1/files >>$LOGFILE 2>&1
        [ $? -eq 0 ] || fail_exit "Problem activating TEMS support (support seeding)"
    else
    	DOMAIN_NAME=$1
        #6.2.1 release or later
        CANDLEHOME=$CHOME
        CurRegPath=$CANDLEHOME/registry
        ArchTbl=$CurRegPath/archdsc.tbl
        DynShl=$CANDLEHOME/bin/dynarch.shl
        . $DynShl $ArchTbl

        TEMSNAME=$(grep BINARCH $CHOME/config/.ConfigData/kmsenv 2>/dev/null | grep -v default | cut -f1 -d"|")
        [ -z "$TEMSNAME" ] && fail_exit "Unable to get TEMS name (support seeding)"

        kdstsns kpa_$DOMAIN_NAME.sql $TEMSNAME >>$LOGFILE 2>&1
        [ $? -eq 0 ] || fail_exit "Problem activating TEMS support (support seeding)"
    fi;
}


function activate_domain_teps
{
    print " - activating TEPS support"
    cp -f $DDIR/$1/files/TEPS/CNPS/SQLLIB/kpa_*.sql ${CQ_HOME}/sqllib/. > /dev/null 2>>$LOGFILE
    [ $? -eq 0 ] || fail_exit "Problem copying TEPS support files"
    cp -f $DDIR/$1/files/TEMS/SQLLIB/kpa_*.sql ${CQ_HOME}/sqllib/. > /dev/null 2>>$LOGFILE
    [ $? -eq 0 ] || fail_exit "Problem copying TEPS support files"
}

function activate_domain_pa
{
    print " - activating ITPA tasks"
    $JHOME/bin/java -cp $PA_CLASSPATH com.ibm.tivoli.pa.config.PAConfigMain -execSQL $DDIR/$1/files/PA/tasks.sql >>$LOGFILE 2>&1
    [ $? -eq 0 ] || fail_exit "Problem activating ITPA tasks"
}

function generate_odi
{
    print " - generating odi files"
    $JHOME/bin/java -jar bin/domsupp.jar -deploy $CHOME -grpdir $DDIR/$1/files/PA/odi -workdir $CHOME/tmp >>$LOGFILE 2>&1
    [ $? -eq 0 ] || fail_exit "Problem generating odi files"
}

function generate_odi_tems_pre
{
    case $OSARCH in
        li) PADIR=$CHOME/li6263/pa;;
        aix) PADIR=$CHOME/aix533/pa;;
        sol) PADIR=$CHOME/sol286/pa;;
        hp) PADIR=$CHOME/hpi113/pa;;
        *) fail_exit "Not supported operating system";;
    esac
    if [ ! -f $PADIR/config/dockpa ];
    then
        mkdir -p $PADIR/config > /dev/null 2>>$LOGFILE
        touch $PADIR/config/init.cfg > /dev/null 2>>$LOGFILE
        cp $DDIR/dockpa $PADIR/config > /dev/null 2>>$LOGFILE
        if [ ! -f $PADIR/config/init.cfg ] || [ ! -f $PADIR/config/dockpa ];
        then
			fail_exit "Problem preparing ITPA configuration files for TEMS"        
		fi;	
    fi
}

function cq_install_presentation
{
    print "Executing script InstallPresentation.sh, please wait..."
    $CHOME/bin/itmcmd execute cq InstallPresentation.sh >>$LOGFILE 2>&1
    typeset -i RC=$?
    [ $RC -eq 0 ] || fail_exit "Script InstallPresentation.sh failed - return code = $RC"
}

function fail_exit
{
    print "ERROR: $1"
    print "Domains activation failed."
    exit 1
}

function prepare_tems
{
    MS_CONFIG=`grep "ms|" $CHOME/config/.ConfigData/ConfigInfo 2>>$LOGFILE | cut -d"|" -f2 | head -1`
    if [ $MS_CONFIG ] && [ -f $MS_CONFIG ];
    then
        MS_BIN=`grep "CMS_BINPATH=" ${MS_CONFIG} 2>>$LOGFILE | cut -d"=" -f2 | cut -d"'" -f2 | head -1`        
        PATH=$MS_BIN:$PATH
    fi
    [ $MS_BIN ] || fail_exit "Problem getting TEMS configuration"
}

function prepare_teps
{
    CQ_CONFIG=$CHOME/config/cq.config
    if [ -f $CQ_CONFIG ];
    then
        CQ_HOME=`grep "KFW_HOME=" ${CQ_CONFIG} 2>>$LOGFILE | cut -d"=" -f2 | cut -d"'" -f2 | head -1`
        [ $CQ_HOME ] || fail_exit "Unable to determine TEPS directory"
    fi;    
    [ $CQ_HOME ] || fail_exit "Unable to determine TEPS directory"
}

function prepare_pa
{
    PA_CONFIG=$CHOME/config/pa.config
    if [ -f $PA_CONFIG ];
    then
        PA_HOME=`grep "CTIRA_SIT_PATH=" ${PA_CONFIG} 2>>$LOGFILE | cut -d"=" -f2 | cut -d"'" -f2 | head -1`
        PA_CLASSPATH=`grep "KPA_CLASSPATH=" ${PA_CONFIG} 2>>$LOGFILE | cut -d"=" -f2 | cut -d"'" -f2 | head -1`
        PA_CLASSPATH=$PA_CLASSPATH:$CHOME/classes/kjrall.jar:$PA_HOME/paconf.jar        
    fi
    [ $PA_CLASSPATH ] || fail_exit "Unable to determine ITPA agent CLASSPATH variable"
}

function check_services
{
    print "Checking running services before processing..."
    tems_pid=`grep "|ms|" $CHOME/config/.ConfigData/RunInfo 2>>$LOGFILE | cut -d"|" -f3`

    if [ $tems_pid ];
    then
        ps -ef 2>>$LOGFILE | grep $tems_pid | grep kdsmain > /dev/null
        [ $? -eq 0 ] || fail_exit "TEMS must be running"
    else 
        fail_exit "TEMS must be running"
    fi;
}

######################################################################################

if [ $# -lt 8 ];
then
    print "Invalid arguments"
    exit 1
fi;

isTEMS=
isTEPS=
isPA=

[ $1 = "true" ] && isTEMS="yes"
[ $2 = "true" ] && isTEPS="yes"
[ $3 = "true" ] && isPA="yes"

CHOME=$4
JHOME=$5
DDIR=$6
OSARCH=$7

LOGFILE=$CHOME/logs/itpa_domain.log

shift 7

print "ITPA Domain Activation Tool started - "`date` >> $LOGFILE

[ $isTEMS ] && check_services

print "Preparing environment before activating domains..."

[ $isTEMS ] && prepare_tems
[ $isTEPS ] && prepare_teps
[ $isPA ] && prepare_pa

while [ $# -gt 0 ];
do
    if [ -d $DDIR/$1 ];
    then
        activate_domain $1
    else
    	fail_exit "Invalid domain name"    
    fi;
    shift
done

[ $isTEPS ] && cq_install_presentation

print "Domains activation completed successfully."

[ $isTEMS ] && print "Restart TEMS now"
[ $isTEPS ] && print "Restart TEPS now"
[ $isPA ] && print "Restart ITPA now"
