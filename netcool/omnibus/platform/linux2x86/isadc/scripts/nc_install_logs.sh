#!/bin/sh
#
# Licensed Materials - Property of IBM
#
# 5724O4800
#
# (C) Copyright IBM Corp. 2012. All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication
# or disclosure restricted by GSA ADP Schedule Contract
# with IBM Corp.
#
#
# This script will collect log files related to the installation of
# Netcool/OMNIbus. Files are collected from the _uninst directory of
# Netcool/OMNIbus, the user's home directory (IA log files only), and the log
# directory of the IBM Deployment Engine.
#
# Usage: nc_install_logs [--pmr nnnnn,nnn,nnn] product_dir ...
#
# If you plan to send the log files to IBM for diagnosis please specify
# your PMR number so that the output file is named approriately.
#
# One or more product directory paths (NCHOME for Core, tip_home_dir and
# webgui_home_dir for WebGUI) must be provided so that the log files stored
# below these directories can be included.
#

#
# Storage functions
#
store_file() {
    if [ -f "$1" ]
    then
        stage_file="$STAGEDIR/$1"
        stage_dir=`dirname "$STAGEDIR/$1"`
        mkdir -p "$stage_dir"
        cp "$1" "$stage_file"
    fi
}

store_hierachy() {
    # $1 - root of hieracy, $2 - file name pattern
    if [ -d "$1" ]
    then
        find "$1" -type f -name "$2" -print | while read file
        do
            store_file "$file"
        done
    fi
}

canonical_path() {
    if [ -d "$1" ]
    then
        stage_dir="$STAGEDIR/$1"
        mkdir -p "$stage_dir"
        directory=`cd "$1"; pwd`
        echo "$directory" > "$STAGEDIR/$1/pwd"
    fi
}

directory_contents() {
    if [ -d "$1" ]
    then
        stage_dir="$STAGEDIR/$1"
        mkdir -p "$stage_dir"
        ls -la "$1" > "$STAGEDIR/$1/ls-la"
    fi
}

#
# DE log collection
#
collect_de_logs() {
    echo "Collecting DE logs from $1"

    canonical_path "$1"
    directory_contents "$1/jre"
    directory_contents "$1/bin"

    store_hierachy "$1/logs" "*"

    for file in "$1"/*.properties
    do
        store_file "$file"
    done

    store_file "$1/repos/derby.log"
}

collect_user_de_logs() {
    for dehome in "$1"/.acsi_*
    do
        if [ -d "$dehome" ]
        then
            collect_de_logs "$dehome"
        fi
    done
}

collect_root_de_logs() {
    if [ -d "/var/ibm/common/acsi" ]
    then
        collect_de_logs "/var/ibm/common/acsi"
    fi
    if [ -d "/usr/ibm/common/acsi" ]
    then
        collect_de_logs "/usr/ibm/common/acsi"
    fi
}

#
# COI-EXT log collection
#
collect_coi_ext_logs() {
    for file in "$HOME"/*OMNIbus*log
    do
        store_file "$file"
    done
}

#
# Product installation log collection
#
collect_product_logs() {
    echo "Collecting product logs from $1"

    canonical_path "$1"

    for file in "$1"/*.log
    do
        store_file "$file"
    done

    store_hierachy "$1/_uninst" "*.log"

    core_omnibus_logs "$1"
    omnibus_webgui_logs "$1"
}

core_omnibus_logs() {
    store_file "$1/omnibus/log/migrate.log"
}

omnibus_webgui_logs() {
    store_file "$1/derby/derby.log"
    store_hierachy "$1/logs/manageprofiles" "*.log"
    store_hierachy "$1/profiles/TIPProfile" "*.log"
}

#
# Package staging directory
#
tar_up() {
    if [ -d "$1" ]
    then
        tar cf "${1}.tar" "${1}" 2> /dev/null

        if [ -f "${1}.tar" ]
        then
            rm -rf "$1"
            echo "${1}.tar"
            return
        fi
    fi
    echo "$1"
}

do_gzip() {
    if [ -f "$1" ]
    then
        gzip "$1" 2> /dev/null

        if [ -f "$1.gz" ]
        then
            echo "$1.gz"
        fi
    fi
}

do_compress() {
    if [ -f "$1" ]
    then
        compress "$1" 2> /dev/null

        if [ -f "$1.Z" ]
        then
            echo "$1.Z"
        fi
    fi
}

do_compression() {
    if [ -f "$1" ]
    then
        gzipped=`do_gzip "$1"`
        if [ -n "$gzipped" ]
        then
            echo "$gzipped"
            return
        else
            compressed=`do_compress "$1"`
            if [ -n "$compressed" ]
            then
                echo "$compressed"
                return
            fi
        fi
    fi
    echo "$1"
}

packageup() {
    # Tar up
    package=`tar_up "$STAGEDIR"`

    # Compress
    package=`do_compression "$package"`

    # Let the user know where the package is
    echo "The package of log files is $package"
}

#
# Parameters
#
usage() {
    echo "Usage: $0 [--pmr nnnnn,nnn,nnn] <path> ..." >&2
    echo "" >&2
    echo "The PMR argument should be used when you intend to submit files to IBM." >&2
    echo "<path> is the installation directory. More than one <path> can be given." >&2
    echo "For Core Netcool/OMNIbus give the value of NCHOME." >&2
    echo "For Netcool/OMNIbus WebGUI give both tip_home_dir and webgui_home_dir." >&2
    exit 1
}

if [ "$1" = "--pmr" ]
then
    PMR="$2"
    shift 2
else
    PMR=
fi
export PMR

if [ "$#" -lt 1 ]
then
    usage
fi

if [ -z "$PMR" ]
then
    STAGEDIR=`date +"nc_install_logs.%Y%m%dT%H%M%S"`
else
    STAGEDIR=`date +"${PMR}.nc_install_logs.%Y%m%dT%H%M%S"`
fi
export STAGEDIR

#
# Main function
#
mkdir -p "$STAGEDIR"

collect_user_de_logs "$HOME"
collect_root_de_logs

collect_coi_ext_logs

for productdir in "$@"
do
    collect_product_logs "$productdir"
done

packageup
# vim:et:sw=4:
