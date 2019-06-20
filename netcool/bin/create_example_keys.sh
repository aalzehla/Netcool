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
# This shell script creates a set of example keystores that contain a
# Certification Authority (CA) certificate with private key and a server
# certificate with private key. The script can be used for proofs of concept
# and for guidance on using the command-line key management tool, nc_gskmd.
#
#
# For demonstration purposes, this script runs within a single installation of
# Netcool/OMNIbus. Three different keystores are created and used. In a
# real system, each keystore would be located on a different computer.
# The certificate and certificate request files identified as $CERT_FILE and
# $REQ_FILE would be sent between the computers using a mechanism such
# as secure email or ftp. Note that, in real systems, Netcool/OMNIbus
# components only access one keystore, which must be named omni.kdb.
#
# Three keystores (.kdb) are created:
# - ca.kdb contains the CA's certificate and private key.
#   This is extremely sensitive information that is used to sign server
#   certificates. You must keep this keystore secure, in line with your
#   organisation's security policies. This keystore is not accessed by
#   Netcool/OMNIbus.
# - omni.kdb contains the CA's certificate and the server's certificate
#   and private key.
#   You must keep this keystore only on the server computer. This keystore is
#   named omni.kdb so that it can be used by both client and server programs in
#   this Netcool/OMNIbus installation.
# - client/omni.kdb contains the CA's certificate.
#   You must distribute this keystore, or its contents, to each installation of
#   Netcool/OMNIbus from which client programs will connect to the server. In
#   order for Netcool/OMNIbus client programs to be able to use this keystore,
#   all the files that make up the keystore must be put in
#   $NCHOME/etc/security/keys in the client installation.
#
# Each keystore is composed of a main file named <basename>.kdb and a number of
# other files with the same <basename> but with different extensions. All files
# are required and must be transferred or backed up together.
#
# If several different servers are going to be run within the same installation
# of Netcool/OMNIbus, their certificate requests must all be created from the
# same keystore. For each server, repeat the "-certreq -create", "-cert -sign"
# and "-cert -receive" commands demonstrated below.
#
# If client programs are going to connect to multiple servers, with
# certificates that were signed by different CAs, the certificate for each CA
# must be imported into the client installation's keystore. For each CA, repeat
# the "-cert -extract" and "-cert -add" commands demonstrated below.
#


# To use this script with different parameters, make a copy of the script and
# then edit and run the copy.

# Security parameters
CA_KEYPW=3xtrEmely-5ecrEt
CA_DN=CN=CA,O=example.com
CA_LABEL=CA

OMNI_KEYPW=0bviously-5ecrEt
SERVER_DN=CN=NCOMS,O=example.com
SERVER_LABEL=NCOMS

CLIENT_KEYPW=0ptionaLly-5ecret

# Temporary file names
REQ_FILE=cert_req
CERT_FILE=cert

# This script is in $NCHOME/bin, find nc_gskcmd and location of the keystores
SCRIPTDIR=`dirname $0`
SCRIPTDIR=`cd "$SCRIPTDIR" ; pwd`

GSKCMD="$SCRIPTDIR/nc_gskcmd"
CA_KDB="$SCRIPTDIR/../etc/security/keys/ca.kdb"
OMNI_KDB="$SCRIPTDIR/../etc/security/keys/omni.kdb"
CLIENT_KDB="$SCRIPTDIR/../etc/security/keys/client/omni.kdb"

# Prevent accidental destruction of existing keystores
BROKEN=
for KDB in "$CA_KDB" "$OMNI_KDB" "$CLIENT_KDB"
do
    if [ -f "$KDB" ]
    then
        echo "Failure. Key store already exists: $KDB"
        BROKEN=1
    fi
done

if [ -n "$BROKEN" ]
then
    exit 1
fi

# Create keystores
echo "Creating keystores"
while read KEYPW KDB
do
    mkdir -p `dirname "$KDB"`
    "$GSKCMD" -keydb -create \
        -db "$KDB" -type cms -pw "$KEYPW" \
        -stash \
        || exit
done << EOF
$CA_KEYPW $CA_KDB
$OMNI_KEYPW $OMNI_KDB
$CLIENT_KEYPW $CLIENT_KDB
EOF

# Create CA certificate
echo "Creating CA certificate"
"$GSKCMD" -cert -create \
    -db "$CA_KDB" -type cms -pw "$CA_KEYPW" \
    -ca true -label "$CA_LABEL" -dn "$CA_DN" \
    || exit

# Transfer CA certificate to the other two keystores
rm -f "$CERT_FILE"
"$GSKCMD" -cert -extract \
    -db "$CA_KDB" -type cms -pw "$CA_KEYPW" \
    -label "$CA_LABEL" -target "$CERT_FILE" \
    || exit
"$GSKCMD" -cert -add \
    -db "$OMNI_KDB" -type cms -pw "$OMNI_KEYPW" \
    -label "$CA_LABEL" -file "$CERT_FILE" \
    || exit
"$GSKCMD" -cert -add \
    -db "$CLIENT_KDB" -type cms -pw "$CLIENT_KEYPW" \
    -label "$CA_LABEL" -file "$CERT_FILE" \
    || exit
rm -f "$CERT_FILE"

# Create certificate request for server
echo "Creating server certificate"
rm -f "$REQ_FILE" "$CERT_FILE"
"$GSKCMD" -certreq -create \
    -db "$OMNI_KDB" -type cms -pw "$OMNI_KEYPW" \
    -label "$SERVER_LABEL" -dn "$SERVER_DN" -file "$REQ_FILE" \
    || exit

# Sign certificate request
"$GSKCMD" -cert -sign \
    -db "$CA_KDB" -type cms -pw "$CA_KEYPW" \
    -label "$CA_LABEL" -file "$REQ_FILE" -target "$CERT_FILE" \
    || exit

# Receive signed certificate
"$GSKCMD" -cert -receive \
    -db "$OMNI_KDB" -type cms -pw "$OMNI_KEYPW" \
    -file "$CERT_FILE" \
    || exit
rm -f "$REQ_FILE" "$CERT_FILE"


# Show the results
while read KEYPW KDB DESC
do
    echo ""
    echo "$DESC keystore"
    echo "$DESC keystore" | sed 's/./=/g'
    "$GSKCMD" -cert -list \
        -db "$KDB" -type cms -pw "$KEYPW"
done << EOF
$CA_KEYPW $CA_KDB CA
$OMNI_KEYPW $OMNI_KDB Server
$CLIENT_KEYPW $CLIENT_KDB Client
EOF
# vim:et:sw=4:
