#!/bin/sh
#
# Licensed Materials - Property of IBM
#
# 5724O4800
#
# (C) Copyright IBM Corp. 1994, 2014. All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication
# or disclosure restricted by GSA ADP Schedule Contract
# with IBM Corp.
#

UPGRADE_CWD=`pwd`
UPGRADE_BUNDLE="$UPGRADE_CWD/.upgrade_bundle"
RELEASEVER=8.1.0
ECHO=echo

if [ -x /usr/bin/clear ]; then
    CLEAR=/usr/bin/clear
elif [ -x /bin/clear ]; then
    CLEAR=/bin/clear
fi
export OMNIHOME

DEFAULT=0



#######################################
f_STOP_PROCESSES() {
#######################################

# Due to the necessity to move the current install directory all Netcool/OMNIbus process running on the 
# machine need to be stopped. This is an advisable process to ensure no corruption of the existing 
# install takes place.

    # Stop any 'nco' processes
    ps -ef | grep nco | grep -v grep | grep -v nco_upgrade | awk '{print $2}' |
    while read line
    do
        if [ "$line" != "" ]; then
            kill $line
        fi
    done
    # Stop any 'jeld' processes
    ps -ef | grep jeld | grep -v grep | awk '{print $2}' |
    while read line
    do
        if [ "$line" != "" ]; then
            kill $line
        fi
    done
    # Stop any 'omniprop' processes
    ps -ef | grep omniprop | grep -v grep | awk '{print $2}' |
    while read line
    do
        if [ "$line" != "" ]; then
            kill $line
        fi
    done

}


#######################################
f_UPGRADECOMMUNICATIONS() {
#######################################

    # Under the new installer the middleware is in the common area
    if [ -x "$OLD/bin/nco_igen" ]; then
        SRC=$OLD
    else
        SRC=$OLD/..
    fi

    cp -f "$SRC/etc/omni.dat" "$NEW/../etc/"

    # Generate interfaces file
    NCHOME=$NEW/..
    OMNIHOME=$NEW
    export NCHOME OMNIHOME
    $NEW/../bin/nco_igen

    # FIPS and SSL security keystore
    if [ -f "$SRC/etc/security/fips.conf" ]; then
        cp -f "$SRC/etc/security/fips.conf" "$NEW/../etc/security"
    fi

    # The key store may need re-creating using updated key management tools.
    # Since a suitable password needs to be selected this cannot be done
    # automatically, so copy the old key store for manual update.
    keyscopied=
    for keyfile in "$SRC/etc/security/keys"/*; do
        if [ -f "$keyfile" ]; then
            mkdir -p "$NEW/../etc/security/keys/migrated"
            cp -f "$keyfile" "$NEW/../etc/security/keys/migrated"
            keyscopied=1
        fi
    done

    if [ -n "$keyscopied" ]; then
        f_INFO "The key store has been copied into the following directory. See the Installation Guide for how to upgrade the key store. $NEW/../etc/security/keys/migrated"
    fi
}


#######################################
f_COMMONFILES() {
#######################################

    if [ -d $OLD/utils -a -d $NEW/utils ]; then
        if [ ! -d $NEW/install/utils8.1.0 ]; then
            mv -f $NEW/utils $NEW/install/utils8.1.0
            mkdir $NEW/utils
        fi
        cp -Rfp $OLD/utils/* $NEW/utils/
        f_INFO "To ensure new utils provided in 8.1.0 are not overwritten by previous versions a backup of the 8.1.0 utilities has been created in $NEW/install/utils8.1.0"
    else
        cp -fRp $OLD/utils $NEW/
    fi

    if [ -d $OLD/scripts -a -d $NEW/scripts ]; then
        if [ ! -d $NEW/scripts8.1.0 ]; then
            mv -f $NEW/scripts $NEW/scripts8.1.0
            mkdir $NEW/scripts
        fi
        cp -fRp $OLD/scripts $NEW/scripts
        f_INFO "To ensure new scripts provided in 8.1.0 are not overwritten by previous versions a backup of the 8.1.0 scripts has been created in $NEW/scripts8.1.0"
    fi

}

#######################################
f_CONFIGFILE() {
#######################################
    # Check whether the config file is identitical to the original copy in the
    # "default" directory. If there is no default copy in the source directory,
    # or it is not the same as the working copy, copy the working copy.
    directory=`dirname "$file"`
    filename=`basename "$file"`
    default="$directory/default/$filename"

    destination=$2
    if [ ! -d "$destination" ]; then
        mkdir -p "$destination"
    fi

    if [ ! -f "$default" ]; then
        copy=1
    else
        cmp -s "$file" "$default"
        copy=$?
    fi

    if [ "$copy" -eq 1 ]; then
        cp -f "$file" "$destination"
        $ECHO "$filename"
    fi
}

#######################################
f_RESTOSFILES() {
#######################################

    # Copy files in the etc/restos directory.
    # See f_CONFIGFILE() for how each file is handled
    $ECHO "Copying files into omnibus/etc/restos"
    find "$OLD/etc/restos" \( ! -name restos -type d -prune \) -o \
            -type f -print | \
            while read file; do
        f_CONFIGFILE "$file" "$NEW/etc/restos"
    done

    # Migrate $OLD/etc/restos/{docroot,uipreview} to $NEW/etc/restos/{docroot,uipreview}.migrated.n
    for restosdir in docroot uipreview
    do
        if [ -d $NEW/etc/restos/$restosdir -a -d $OLD/etc/restos/$restosdir ]; then
            $ECHO Migrating old etc/restos/$restosdir

            DEST="$NEW/etc/restos/$restosdir.migrated"
            if [ -d $DEST ]
            then
                COUNT=1
                DEST="$NEW/etc/restos/$restosdir.migrated.$COUNT"
                while [ -d $DEST ]
                do
                    COUNT=`expr $COUNT + 1`
                    DEST="$NEW/etc/restos/$restosdir.migrated.$COUNT"
                done
            fi

            f_INFO "Old restos $restosdir will be copied to $DEST."
            mkdir -p "$DEST"
            (cd $OLD/etc/restos/$restosdir; \
             find . -type f -print \
             | cpio -pd "$DEST")
        fi
    done

    $ECHO "Finished files in omnibus/etc/restos"
    $ECHO ""
}

#######################################
f_ETCFILES() {
#######################################

    # Copy files in the etc directory. Exclude interfaces (handled separately)
    # and a couple of well known, read only, files. See f_CONFIGFILE() for
    # how each file is handled
    $ECHO "Coping files into omnibus/etc"
    find "$OLD/etc" \( ! -name etc -type d -prune \) -o \
            -type f \
            ! -name "omni.dat" ! -name "tds.dat" ! -name "interfaces*" \
            ! -name "exclusions.dtd" ! -name "sec_table" -print | \
            while read file; do
        f_CONFIGFILE "$file" "$NEW/etc"
    done
    $ECHO "Finished files in omnibus/etc"
    $ECHO ""
}

#######################################
f_UPGRADEDESK() {
#######################################
    $ECHO "Coping files into omnibus/desktop"
    find "$OLD/desktop" \( ! -name desktop -type d -prune \) -o \
            -type f -print | while read file; do
        f_CONFIGFILE "$file" "$NEW/desktop"
    done
    $ECHO "Finished files in omnibus/desktop"
    $ECHO ""
}

######################################
f_UPGRADEMIBMANAGER() {
######################################

    # If Mibmanager has been installed it can be migrated now
    SRC=""
    case $OLD_VERSION in
        7.1*|7.0*|7.2*|7.3*)
            # Ignore old versions that did not ship with mibmanager
            ;;
        7.4*)
            SRC=$OLD/platform/$OLDARCH/mibmanager/workspace
            ;;
        8.0*|8.1*)
            SRC=$OLD/var/mibmanager
            ;;
        *)
            f_ERROR Do not know how to upgrade version $OLD_VERSION Mibmanager, ignoring.
            ;;
    esac

    if [ -d "$NEW/var/mibmanager" -a ! -z "$SRC" -a -d "$SRC" ]; then
        DEST="$NEW/var/mibmanager.migrated"

        f_INFO "Mibmanager workspace will be copied to $DEST. You can use the contents of this directory to help you configure mibmanager."
        mkdir -p "$DEST"
        (cd $SRC; \
         find . -type f  -print \
         | cpio -pd "$DEST")
    fi
}

######################################
f_UPGRADEPROBES() {
######################################

    # If probes have been installed they can be upgraded now
    # If not, store the configuration for when they are installed
    if [ -d $NEW/$1 -a -d $OLD/$1/$OLDARCH ]; then
        case $1 in
        probes)
            $ECHO Upgrading Probes
            ;;
        tsm)
            $ECHO Upgrading TSMs
            ;;
        *)
            $ECHO Upgrading $1
            ;;
        esac

        DEST="$NEW/$1/migrated"
        if [ -d $DEST ]
        then
            COUNT=1
            DEST="$NEW/$1/migrated.$COUNT"
            while [ -d $DEST ]
            do
                COUNT=`expr $COUNT + 1`
                DEST="$NEW/$1/migrated.$COUNT"
            done
        fi

        f_INFO "Configuration will be copied to $DEST. You can use the contents of this directory to help you configure any $1 you install."
        mkdir -p "$DEST"
        (cd $OLD/$1; \
         find $OLDARCH -type f ! -name 'nco*' ! -name '*.jar' -print \
         | cpio -pd "$DEST")
    fi

}

#######################################
f_UPGRADEOBJECTSERVER() {
#######################################

    case $OLD_VERSION in
    7.1*|7.0*|7.2*|7.3*|7.4*|8.0*|8.1*)
        servers=`ls $OLD/db`
        for server in $servers
        do
            if [ -d "$OLD/db/$server" ]
            then
                f_UPGRADECOPYDIR db/$server
                # Props file was copied with f_ETCFILES
            fi
        done
        if [ -n "$servers" ]
        then
            f_INFO Version 7.x ObjectServers have been copied into the new installation and are ready to run.
        fi
        ;;
    *)
        f_ERROR Do not know how to upgrade version $OLD_VERSION ObjectServers, ignoring.
        ;;
    esac

}


#######################################
f_UPGRADEMONITORS() {
#######################################

    if [ -d $OLD/monitors ]; then
        $ECHO Upgrading Monitors
        cp -frp $OLD/monitors $NEW
    fi

    if [ -d $OLD/profiles ]; then
        if [ -d $NEW/profiles ]; then 
            cp -frp $OLD/profiles/* $NEW/profiles/
        else
            cp -frp $OLD/profiles $NEW/
        fi
    fi
    if [ -d $OLD/datalogs ]; then
        if [ -d $NEW/datalogs ]; then 
            cp -frp $OLD/datalogs/* $NEW/datalogs/
        else
            cp -frp $OLD/datalogs $NEW/
        fi
    fi
    if [ -d $OLD/demo ]; then
        if [ -d $OLD/demo/cgi-bin/ism/ism ]; then
            rm $OLD/demo/cgi-bin/ism/ism
        fi
        if [ -d $NEW/demo ]; then 
            cp -frp $OLD/demo/* $NEW/demo/
        else
            cp -frp $OLD/demo $NEW/
        fi
        ln -s $NEW/demo/cgi-bin/ism $NEW/demo/cgi-bin/ism/ism
        ln -s $OLD/demo/cgi-bin/ism $OLD/demo/cgi-bin/ism/ism
    fi

    # Added changes to copy across the libnmt.so.1 file for ISMs
    # Lois - 1/11/99

    if [ -f $OLD/platform/$OLDARCH/lib/libnmt.so.1 ]; then
        cp -f $OLD/platform/$OLDARCH/lib/libnmt.so.1 $NEW/platform/$ARCH/lib/
    fi

    # Added '-R' to cp for ism directory
    # Wilko - 5th Feb 2000

    if [ -d $OLD/ism ]; then
        cp -fR $OLD/ism $NEW/
    fi

    if [ ! -f $NEW/platform/$ARCH/ismmsg.cat ]; then
        cp -f $OLD/platform/$OLDARCH/ismmsg.cat $NEW/platform/$ARCH/ismmsg.cat
    fi
}

#######################################
f_DUMPPROPSTODIR () {
#######################################
    propsfile=$1
    directory=$2

    # NBS 018133 - Dump each property value to a file with the property
    #          name.
    cat $1 | while read prop value
    do
        case $prop in
        [A-Z]*)
            echo "$value" > $directory/$prop
            ;;
        *)
            ;;
        esac
    done
}

#######################################
f_UPGRADEPROPS() {
#######################################
##Added functionality to add 3.6 new properties to old props
    PROPS=$1
    NEW_PROPS=$2
    TMP_PROPS=/tmp/.$$.tmp_props
    TMP_PROPS_DIR=/tmp/.$$.tmp_prop.d

    rm -rf $TMP_PROPS_DIR
    mkdir -p $TMP_PROPS_DIR || f_FATAL "Could not create $TMP_PROPS_DIR"

##Create header
    cat > $TMP_PROPS <<EOF
#
# Netcool/OMNIbus 8.1.0 Server Properties file
#
EOF

#
    f_DUMPPROPSTODIR $NEW_PROPS $TMP_PROPS_DIR
    f_DUMPPROPSTODIR $PROPS $TMP_PROPS_DIR

# NBS 018133 - Read merged properties from files, and dump them to the new
#          properties file.
    for i in $TMP_PROPS_DIR/*
    do
        printf "%s %s\n" `basename $i` `cat $i`
    done >> $TMP_PROPS

    $ECHO "# End of file" >>  $TMP_PROPS

##write the new file out
    cp -f $TMP_PROPS $NEW_PROPS
    rm -rf $TMP_PROPS_DIR
    rm $TMP_PROPS

}

#######################################
f_UPGRADECOPYDIR() {
#######################################
    if [ -d $OLD/$1 ]; then
        $ECHO Upgrading $1
        if [ ! -d $NEW/$1 ]; then
            mkdir -p $NEW/$1
        fi
        (cd $OLD/$1; tar cf - . ) | (cd $NEW/$1; tar xf -)
    fi
}


###################################################
# New code
###################################################

f_USAGE () {
    echo "Usage: UPGRADE.SH -old <OMNIHOME.OLD> [-new <OMNIHOME.NEW>]" 1>&2
    exit 1
}

f_ARCH () {
#
# What OS are we running ?
# We need OLDARCH where we've changed a platform architecture name, currently
# this only affects Aix
#
    ARCH=""
    if [ `uname -s` = SunOS ]; then
    if [ `uname -r | sed 's/\(..\).*/\1/'` = "4." ]; then
        ARCH=sunos4
    else
        if [ `uname -r | sed -e 's/..\(.\)/\1/'` -lt 7 ]; then
            f_FATAL "Unsupported version of Solaris 2.x"
        fi
        if [ `uname -p` = i386 ]; then
            ARCH=solaris2x86   # Solaris 2.x INTEL (X86)
        elif [ `uname -p` = sparc ]; then
            ARCH=solaris2      # Solaris 2.x SPARC
            OLDARCH=solaris2
        else
            f_FATAL "Unsupported processor for Solaris 2.x"
        fi
    fi
    fi
    if [ `uname -s` = AIX ]; then
    #Just use one version of AIX 
    if [ `uname -v` -lt 5 ]; then
        f_FATAL "Unsupported version of Aix"
    else
        ARCH="aix5"     # AIX 5 PowerPC
        OLDARCH="aix4"
    fi
    fi
    if [ `uname -s` = HP-UX ]; then
    if [ `uname -r | sed 's/..\(..\).*/\1/'` = "11" ]; then
        if [ `uname -m` = "ia64" ]; then
            ARCH=hpux11hpia
            OLDARCH=hpux11hpia
        else
            ARCH=hpux11
            OLDARCH=hpux11
        fi
    else
         f_FATAL "Unsupported version of HP-UX"
    fi
    fi

    if [ `uname -s` = Linux ]; then
        if [ `uname -m  | sed 's/\(s390\)x/\1/'` = "s390" ]; then
            ARCH=linux2s390
            OLDARCH=linux2s390
        else
            ARCH=linux2x86
            OLDARCH=linux2x86
        fi
    fi
    if [ "$ARCH" = "" ]; then
    f_FATAL "Unknown architecture: `uname -s`"
    fi
}

f_VERIFY () {

    if [ ! -d $1 ]; then
        f_FATAL "$1 is not a directory"
    fi
    if [ ! -f $1/RELEASE_ID ]; then
        f_FATAL "$1 is not a valid installation of Netcool/OMNIbus"
    fi

    OLD_VERSION=`head -n 1 $1/RELEASE_ID | awk '{print $2}'`
    case $OLD_VERSION in
    8.1*|8.0*|7.4*|7.3*|7.2*|7.1*|7.0*|3.6*|3.5*|3.4*)
        ;;
    *)
        f_FATAL "Unsupported version of OMNIbus: $OLD_VERSION"
    esac

    if [ -n "$2" ]; then
        if [ ! -d $2 ]; then
            f_FATAL "$2 is not a directory"
        fi
        if [ ! -f $2/RELEASE_ID ]; then
            f_FATAL "$2 is not a valid installation of Netcool/OMNIbus"
        fi

        RELEASEVER=`head -n 1 $2/RELEASE_ID | awk '{print $2}'`
        case $RELEASEVER in
        8.*|7.*|3.6*|3.5*|3.4*)
            ;;
        *)
            f_FATAL "Unsupported version of OMNIbus: $RELEASEVER"
        esac
    fi

    # If the old architecture is aix4, but the old version is 7.x, we need to
    # change the architecture to aix5.
    if [ "$OLDARCH" = "aix4" ]
    then
        case $OLD_VERSION in
        8*|7*) OLDARCH=aix5;;
        esac
    fi
}

f_OUTPUT_PACKAGES () {

    # Check that the given argument is a valid OMNIbus install
    f_VERIFY $1 $2

    if [ -r $1/desktop ]; then
        echo DESKTOP
    fi
    if [ -r $1/probes ]; then
        echo PROBES
    fi
    if [ -r $1/bin/$OLDARCH/nco_objserv -o \
                -r $1/platform/$OLDARCH/bin/nco_objserv ]; then
        echo SERVER
    fi
    if [ -r $1/monitors ]; then
        echo MONITORS
    fi
    if [ -r $1/tsm ]; then
        echo TSM
    fi
    if [ -r $1/fusion ]; then
        echo FUSION
    fi
    if [ -r $1/reporter ]; then
        echo REPORTER
    fi
    if [ -r $1/firewall ]; then
        echo FIREWALL
    fi
    if [ -r $1/platform/$OLDARCH/mibmanager -o $1/var/mibmanager ]; then
        echo MIBMANAGER
    fi
}

f_UPGRADE () {

    # Check that the given argument is a valid OMNIbus install
    f_VERIFY $1 $2

    echo "Upgrading $OLD_VERSION -> $RELEASEVER"

    f_WARN "This upgrade only copies standard configuration Files e.g. files in etc. Any other non-standard files will need to be copied manually."

    for i in COMMON `f_OUTPUT_PACKAGES $1 $2`
    do
        case $i in
        COMMON)
            $ECHO Upgrading Common Components
            f_COMMONFILES
            f_UPGRADECOMMUNICATIONS
            f_ETCFILES
        ;;
        SERVER)
            f_UPGRADEOBJECTSERVER
            f_RESTOSFILES
        ;;
        DESKTOP)
            f_UPGRADEDESK
        ;;
        PROBES)
            f_UPGRADEPROBES probes
        ;;
        MONITORS)
            f_UPGRADEMONITORS
        ;;
        TSM)
            f_UPGRADEPROBES tsm
        ;;
        FUSION)
            f_UPGRADECOPYDIR fusion 
        ;;
        REPORTER)
            f_UPGRADECOPYDIR reporter 
        ;;
        FIREWALL)
            f_UPGRADECOPYDIR firewall 
        ;;
        MIBMANAGER)
            f_UPGRADEMIBMANAGER
        ;;
        esac
    done

}

f_LOG () {
    $ECHO "$*" 1>&2
}

f_INFO () {
    f_LOG "Info: $*"
    f_LOG
}

f_WARN () {
    f_LOG "Warning: $*"
    f_LOG
}

f_ERROR () {
    f_LOG "Error: $*"
    f_LOG
}

f_FATAL () {
    f_LOG "Error (FATAL): $*"
    f_LOG
    exit 2
}

OLD=''
NEW=''
LOG=''
f_ARCH

while [ ${#} -gt 0 ]
do
    case $1 in
    -arch)
        ARCH=$2
        shift 2
        ;;
    -old)
        OLD=$2
        shift 2
        ;;
    -new)
        NEW=$2
        shift 2
        ;;
    -log)
        LOG=$2
        shift 2
        ;;
    *)
        f_USAGE
        ;;

    esac
done

if [ -n "$OLD" -a -d "$OLD/omnibus" ]; then
    OLD=$OLD/omnibus
fi
 
export OLD
export NEW

if [ -n "$OLD" -a -z "$NEW" ]; then
    if [ -n "$LOG" ]; then
        f_OUTPUT_PACKAGES $OLD $NEW > "$LOG" 2>&1
    else
        f_OUTPUT_PACKAGES $OLD $NEW
    fi
elif [ -n "$OLD" -a -n "$NEW" ]; then
    if [ -n "$LOG" ]; then
        f_UPGRADE $OLD $NEW > "$LOG" 2>&1
    else
        f_UPGRADE $OLD $NEW
    fi
else
    f_USAGE
fi

# vi:set et sw=4:
