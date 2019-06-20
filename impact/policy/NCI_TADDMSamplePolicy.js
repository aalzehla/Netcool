/******************************************************* {COPYRIGHT-TOP-RM} ***
 * Licensed Materials - Property of IBM
 * "Restricted Materials of IBM"
 * 5724-S43
 *
 * (C) Copyright IBM Corporation 2014, 2015. All Rights Reserved.
 *
 * US Government Users Restricted Rights - Use, duplication, or
 * disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 ******************************************************** {COPYRIGHT-END-RM} **/
Load("TADDMLibraryFunctions");

/* For this sample policy to work, please define a working TADDM datasource with following data types:
 * TADDM_events  (dataset=TADDM_Events)
 * TADDM_items   (dataset=Configuration_Items)
 * TADDM_bizapps (dataset=TADDM_BusinessApplications)
 * 
 * or substitute data type names with your own.
 */

function TADDM_onNewEvent(event) {
    TADDM_newEvent("TADDM_events", event, event.Serial, event.Severity);
}

function TADDM_onDeleteEvent(event) {
    TADDM_deleteEvent("TADDM_events", event.Serial);
}

function TADDM_hasEvent(event) {
    return TADDM_isEventReported("TADDM_events", event.Serial);
}

function TADDM_getCIs(event) {
    return TADDM_getAllConfigurationItems("TADDM_items", event.Serial);
}

function TADDM_getBizapps(event) {
    return TADDM_getAllBusinessApplications("TADDM_bizapps", event.Serial);
}

function reportEvent(event) {
    Log("Reporting to TADDM event: " + event);
    TADDM_onNewEvent(event);

    Log("Getting correlated CIs");
    var items = TADDM_getCIs(event);
 
    for (var i = 0; i < items.length; i++) {
        var item = items[i];
        Log("Found CI: " + item.displayName + ", guid: " + item.guid);
    }

    Log("Getting correlated BizApps");
    var bizapps = TADDM_getBizapps(event);

    for (var i = 0; i < bizapps.length; i++) {
        var bizapp = bizapps[i];
        Log("Found BizApp: " + bizapp.name + ", guid: " + bizapp.guid);
    }
}

function reportCurrentEvent() {
    reportEvent(EventContainer);
}

function removeEvent(event) {
    Log("Removing event correlation for event: " + event);
    if (TADDM_hasEvent(event)) {
        Log("Event: " + event.Serial + " found in TADDM, deleting");
        TADDM_onDeleteEvent(event);
    } else {
        Log("Event: " + event.Serial + " not found in TADDM, skipping");
    }
}

function removeCurrentEvent() {
    removeEvent(EventContainer);
}

// by default report current event and log correlated items
reportCurrentEvent();
