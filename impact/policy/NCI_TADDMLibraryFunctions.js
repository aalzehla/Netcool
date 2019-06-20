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

/*
Notifies TADDM about a new event that should be correlated with TADDM inventory database.

Parameters:
@dataType - dataType that holds events for the given TADDM data source
@event - EventContainer to report
@eventID - chosen event attribute that is used as the correlation identifier
@severity - event severity.
*/
function TADDM_newEvent(dataType, event, eventID, severity) {
    var taddmEvent = {};
    taddmEvent.eventID = eventID;
    taddmEvent.severity = severity;
    taddmEvent.event = event;
    
    AddDataItem(dataType, taddmEvent);
}

/*
Deletes TADDM event correlation data for the given event.

Parameters: 
@dataType - dataType that holds events for the given TADDM data source 
@eventID - chosen event attribute used as the correlation identifier.

*/
function TADDM_deleteEvent(dataType, eventID) {
    BatchDelete(dataType, eventID, null);
}

/*
Checks whether TADDM event correlation was already performed for the given event.

Parameters:
@dataType - dataType that holds events for the given TADDM data source  
@eventID - chosen event attribute used as the correlation identifier.
 
Returns: true if event was already added to TADDM. Otherwise, it returns the false.
*/
function TADDM_isEventReported(dataType, eventID) {
    if (GetByKey(dataType, eventID, 1)[0]) {
        return true;
    }
    return false;
}

/*
Returns maxNum of best matched TADDM configuration items (CIs) that are correlated to the given event.

Parameters:
@dataType - dataType that holds configuration items for the given TADDM data source.
@eventID - chosen event attribute used as correlation identifier.
@maxNum - maximum number of matches to return.
 
Returns: array of configuration item objects.

Each configuration item has the following properties:
Guid - TADDM unique identifier.
Rank - correlation rank (higher is better).
DisplayName - short name of a configuration item.
HierarchyType - hierarchy type.
LastModifiedTime - last modification time.

The values of all properties are a snapshot of the configuration item's state, which was taken at the moment the event was reported to TADDM.
Any updates (for example DisplayName or LastModifedTime change) or deletion of the configuration item 
that occur after the event was reported, are NOT reflected.

To obtain up to date information about configuration items, connect to TADDM database directly 
using a standard Impact database data source connection.

*/ 
function TADDM_getConfigurationItems(dataType, eventID, maxNum) {
    return GetByKey(dataType, eventID, maxNum);
}

/*
Is the same as TADDM_getConfigurationItems, but returns all matched TADDM configuration items that are correlated to the given event.

Parameters:
@dataType - dataType that holds business applications for the given TADDM data source
@eventID - chosen event attribute used as correlation identifier.

*/
function TADDM_getAllConfigurationItems(dataType, eventID) {
    return GetByFilter(dataType, eventID, false);
}

/*
Returns maxNum of best matched TADDM business applications that are correlated to the given event.

Parameters:
@dataType - dataType that holds business applications for the given TADDM data source
@eventID - chosen event attribute used as correlation identifier
@maxNum - maximum number of matches to return.

Returns: array of business application objects.

Each business application has the following properties:
Guid - TADDM unique identifier
Rank - correlation rank (higher is better)
Name - name of business application
LastModifiedTime - last modification time.

The values of all properties are a snapshot of the business application's state, which was taken at the moment the event was reported to TADDM.
Any updates (for example Name or LastModifedTime change) or deletion of the business application
that occur after the event was reported, are NOT be reflected.

To obtain up to date information about business applications connect to TADDM database directly
using a standard Impact database data source connection.

*/
function TADDM_getBusinessApplications(dataType, eventID, maxNum) {
    return GetByKey(dataType, eventID, maxNum);
}

/*
Is the same as TADDM_getBusinessApplications, but returns all matched TADDM business applications that are correlated to the given event.

Parameters:
@dataType - dataType that holds business applications for given TADDM data source
@eventID - chosen event attribute used as correlation identifier.

*/
function TADDM_getAllBusinessApplications(dataType, eventID) {
    return GetByFilter(dataType, eventID, false);
}
