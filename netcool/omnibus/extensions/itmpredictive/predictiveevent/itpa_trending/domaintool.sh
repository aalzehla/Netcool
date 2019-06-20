#!/bin/ksh

#detect java
CHOME=
CONSOLE=
ALL=

for arg in $*
do
    case "$arg" in
    -console) CONSOLE=$arg;;
    -all) ALL=$arg;;
    -j) process=j;;   
     *) if [ $process ]
        then
            JHOME=$arg
            process=
        else
            [ -f $arg/registry/cienv.ver ] && CHOME=$arg
        fi;;

    esac
done

if [ $CHOME ];
then
    if [ -d $CHOME ];
    then
        if [ -f $CHOME/config/env.config ];
        then
            javahome=`grep "JAVA_HOME=" ${CHOME}/config/env.config | cut -d"=" -f2 | cut -d"'" -f2 | head -1`
            if [ -d $javahome ];
            then
                JAVAHOME=$javahome
            fi
        fi;
        if [ ! "$JAVAHOME" ];
        then
            javadir=`ls $CHOME/JRE -t | head -1`
            if [ -d "$CHOME/JRE/$javadir" ];
            then
                JAVAHOME="$CHOME/JRE/$javadir"
            fi;  
        fi;
    else
        CHOME=
    fi;
fi;

if [ ! "$JAVAHOME" ];
then
    if [ $JHOME ];
    then
        if [ -f $JHOME/bin/java ];
        then
            JAVAHOME=$JHOME
        fi
    else
        #now check env variables
        if [ $CANDLEHOME ];
        then
            if [ -f $CANDLEHOME/config/env.config ];
            then
                javahome=`grep "JAVA_HOME=" ${CANDLEHOME}/config/env.config | cut -d"=" -f2 | cut -d"'" -f2 | head -1`
                if [ -d $javahome ];
                then
                    JAVAHOME=$javahome
                fi
            fi;
            if [ ! "$JAVAHOME" ];
            then
                javadir=`ls $CANDLEHOME/JRE -t | head -1`
                if [ -d "$CANDLEHOME/JRE/$javadir" ];
                then
                    JAVAHOME="$CANDLEHOME/JRE/$javadir"
                fi;
            fi;
        else
            if [ $JAVA_HOME ];
            then
                JAVAHOME=$JAVA_HOME
            fi
        fi
    fi
fi

if [ $JAVAHOME ];
then
    if [ $CHOME ];
    then
        $JAVAHOME/bin/java -jar bin/domaintool.jar -h $CHOME -j $JAVAHOME $CONSOLE $ALL
    else
        $JAVAHOME/bin/java -jar bin/domaintool.jar -j $JAVAHOME $CONSOLE $ALL
    fi
else
    print "Unable to determine JRE directory. To fix this:"
    print " - Specify IBM Tivoli Monitoring directory by setting CANDLEHOME variable."
    print " - Specify IBM Tivoli Monitoring directory ($0 <IBM Tivoli Monitoring directory>)."
    print " - Specify JRE directory by using parameter -j ($0 -j <JRE directory>)."
fi

