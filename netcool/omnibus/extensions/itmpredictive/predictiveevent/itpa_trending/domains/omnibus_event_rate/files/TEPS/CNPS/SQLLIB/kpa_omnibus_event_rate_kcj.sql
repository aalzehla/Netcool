DELETE FROM KFWQUERY WHERE ID = "KPA.KPACNO8099";
DELETE FROM KFWQUERY WHERE ID = "KPA.KPAFNO8099";
DELETE FROM KFWQUERY WHERE ID = "MLGEN-1277759453075";
DELETE FROM KFWQUERY WHERE ID = "MLGEN-1277759453076";
DELETE FROM KFWQUERY WHERE ID = "MLGEN-1277759453077";
DELETE FROM KFWQUERY WHERE ID = "MLGEN-1277759453078";
DELETE FROM KFWQUERY WHERE ID = "MLGEN-1277759453079";
DELETE FROM KFWQUERY WHERE ID = "UDQ-110.06.30-11.00.26-00005";
DELETE FROM KFWQUERY WHERE ID = "XMLGEN-OMNIbus_Event_Rate";
DELETE FROM KFWTMPLSTA WHERE TEMPLATE = "XMLGEN-OMNIbus_Event_Rate";
DELETE FROM KFWTMPLSIT WHERE TEMPLATE = "XMLGEN-OMNIbus_Event_Rate";
DELETE FROM KFWTMPL WHERE NAME = "XMLGEN-OMNIbus_Event_Rate";

INSERT INTO KFWQUERY
  (ID,
   APPL,
   AFFINITIES,
   PROD_PROV,
   NAME,
   TEXT,
   LASTUSER,
   MODIFIED,
   QUERY  )
VALUES
  ("KPA.KPACNO8099",
   "KPA",
   "0000000000000000000000000000G00000000000000",
   "P",
   "KPA T NO8099 LTS",
   "KPACNO8099 Default Query",
   "SYSADMIN",
   "1100628221059000",
   "at=$THRUNODE$@table1.name=KPACNO8099@table1.column1.name=ORIGINNODE@table1.column2.name=TIMESTAMP@table1.column3.name=CONFIDENCE@table1.column4.name=DIRECTION@table1.column5.name=STRENGTH@table1.column6.name=NSAMPLES@table1.column7.name=TTWRNTHRES@table1.column8.name=TTCRITHRES@table1.column9.name=AGENTNODE@table1.column10.name=NCONODE@table1.columnCount=10@tableCount=1@filter1.connector=AND@filter1.column=ORIGINNODE@filter1.operator=EQ@filter1.value=$NODE$@filter2.connector=AND@filter2.column=TIMESTAMP@filter2.operator=EQ@filter2.value=$TIMESTAMP$@filterCount=2@readonly=T@multinodeineligible=T@property1.name=-1021A@property1.value=kfw.TableRow@propertyCount=1@history=F@"
  );

INSERT INTO KFWQUERY
  (ID,
   APPL,
   AFFINITIES,
   PROD_PROV,
   NAME,
   TEXT,
   LASTUSER,
   MODIFIED,
   QUERY  )
VALUES
  ("KPA.KPAFNO8099",
   "KPA",
   "0000000000000000000000000000G00000000000000",
   "P",
   "KPA T NO8099 LTF",
   "KPAFNO8099 Default Query",
   "SYSADMIN",
   "1100628221059000",
   "at=$THRUNODE$@table1.name=KPAFNO8099@table1.column1.name=ORIGINNODE@table1.column2.name=TIMESTAMP@table1.column3.name=FCSTTIME@table1.column4.name=DATA@table1.column5.name=AGENTNODE@table1.column6.name=NCONODE@table1.column7.name=DURATION@table1.columnCount=7@tableCount=1@filter1.connector=AND@filter1.column=ORIGINNODE@filter1.operator=EQ@filter1.value=$NODE$@filter2.connector=AND@filter2.column=TIMESTAMP@filter2.operator=EQ@filter2.value=$TIMESTAMP$@filterCount=2@readonly=T@multinodeineligible=T@property1.name=-1021A@property1.value=kfw.TableRow@propertyCount=1@history=F@"
  );

INSERT INTO KFWQUERY
  (ID,
   APPL,
   AFFINITIES,
   PROD_PROV,
   NAME,
   TEXT,
   LASTUSER,
   MODIFIED,
   QUERY  )
VALUES
  ("MLGEN-1277759453075",
   "KPA",
   "0000000000000000000000000000G00000000000000",
   "P",
   "Event_Rate Status",
   "",
   "SYSADMIN",
   "1070319145449000",
   'tableCount=1@table1.name=KPACNO8099@table1.column1.name=KPACNO8099.ORIGINNODE@table1.column2.name=KPACNO8099.TIMESTAMP@table1.column3.name=KPACNO8099.AGENTNODE@table1.column4.name=KPACNO8099.NCONODE@table1.column5.name=KPACNO8099.CONFIDENCE@table1.column6.name=KPACNO8099.DIRECTION@table1.column7.name=KPACNO8099.STRENGTH@table1.column8.name=KPACNO8099.NSAMPLES@table1.column9.name=KPACNO8099.TTWRNTHRES@table1.column10.name=KPACNO8099.TTCRITHRES@table1.columnCount=10@at=$THRUNODE$@filter1.connector=AND@filter1.column=KPACNO8099.ORIGINNODE@filter1.operator=EQ@filter1.value=$NODE$@filterCount=1@property1.name=-1021A@property1.value=kfw.TableRow@propertyCount=1@order1.column=KPACNO8099.TTCRITHRES@order1.sequence=ASCENDING@orderCount=1@multinodeineligible=T@ccsid=55050241@parma1.value="TIMEOUT","600",3@parmaCount=1@@readonly=N@'
  );

INSERT INTO KFWQUERY
  (ID,
   APPL,
   AFFINITIES,
   PROD_PROV,
   NAME,
   TEXT,
   LASTUSER,
   MODIFIED,
   QUERY  )
VALUES
  ("MLGEN-1277759453076",
   "KPA",
   "0000000000000000000000000000G00000000000000",
   "P",
   "Event_Rate",
   "",
   "SYSADMIN",
   "1070319145449000",
   'tableCount=1@table1.name=KPAFNO8099@table1.column1.name=KPAFNO8099.ORIGINNODE@table1.column2.name=KPAFNO8099.TIMESTAMP@table1.column3.name=KPAFNO8099.AGENTNODE@table1.column4.name=KPAFNO8099.NCONODE@table1.column5.name=KPAFNO8099.FCSTTIME@table1.column6.name=KPAFNO8099.DURATION@table1.column7.name=KPAFNO8099.DATA@table1.columnCount=7@at=$THRUNODE$@filter1.connector=AND@filter1.column=KPAFNO8099.ORIGINNODE@filter1.operator=EQ@filter1.value=$NODE$@filterCount=1@property1.name=-1021A@property1.value=kfw.TableRow@propertyCount=1@order1.column=KPAFNO8099.AGENTNODE@order1.sequence=ASCENDING@orderCount=1@multinodeineligible=T@ccsid=55050241@parma1.value="TIMEOUT","600",3@parmaCount=1@@readonly=N@'
  );

INSERT INTO KFWQUERY
  (ID,
   APPL,
   AFFINITIES,
   PROD_PROV,
   NAME,
   TEXT,
   LASTUSER,
   MODIFIED,
   QUERY  )
VALUES
  ("MLGEN-1277759453077",
   "KPA",
   "0000000000000000000000000000G00000000000000",
   "P",
   "Event_Rate Status Drilldown",
   "",
   "SYSADMIN",
   "1070319145449000",
   'tableCount=1@table1.name=KPACNO8099@table1.column1.name=KPACNO8099.ORIGINNODE@table1.column2.name=KPACNO8099.TIMESTAMP@table1.column3.name=KPACNO8099.AGENTNODE@table1.column4.name=KPACNO8099.NCONODE@table1.column5.name=KPACNO8099.CONFIDENCE@table1.column6.name=KPACNO8099.DIRECTION@table1.column7.name=KPACNO8099.STRENGTH@table1.column8.name=KPACNO8099.NSAMPLES@table1.column9.name=KPACNO8099.TTWRNTHRES@table1.column10.name=KPACNO8099.TTCRITHRES@table1.columnCount=10@at=$THRUNODE$@filter1.connector=AND@filter1.column=KPACNO8099.ORIGINNODE@filter1.operator=EQ@filter1.value=$NODE$@filter2.connector=AND@filter2.column=KPACNO8099.AGENTNODE@filter2.operator=EQ@filter2.value=$KPACNO8099.AGENTNODE$@filter3.connector=AND@filter3.column=KPACNO8099.NCONODE@filter3.operator=EQ@filter3.value=$KPACNO8099.NCONODE$@filterCount=3@property1.name=-1021A@property1.value=kfw.TableRow@propertyCount=1@order1.column=KPACNO8099.TTCRITHRES@order1.sequence=ASCENDING@orderCount=1@multinodeineligible=T@ccsid=55050241@parma1.value="TIMEOUT","600",3@parmaCount=1@@readonly=N@'
  );

INSERT INTO KFWQUERY
  (ID,
   APPL,
   AFFINITIES,
   PROD_PROV,
   NAME,
   TEXT,
   LASTUSER,
   MODIFIED,
   QUERY  )
VALUES
  ("MLGEN-1277759453078",
   "KPA",
   "0000000000000000000000000000G00000000000000",
   "P",
   "Event_Rate Drilldown",
   "",
   "SYSADMIN",
   "1070319145449000",
   'tableCount=1@table1.name=KPAFNO8099@table1.column1.name=KPAFNO8099.ORIGINNODE@table1.column2.name=KPAFNO8099.TIMESTAMP@table1.column3.name=KPAFNO8099.AGENTNODE@table1.column4.name=KPAFNO8099.NCONODE@table1.column5.name=KPAFNO8099.FCSTTIME@table1.column6.name=KPAFNO8099.DURATION@table1.column7.name=KPAFNO8099.DATA@table1.columnCount=7@at=$THRUNODE$@filter1.connector=AND@filter1.column=KPAFNO8099.ORIGINNODE@filter1.operator=EQ@filter1.value=$NODE$@filter2.connector=AND@filter2.column=KPAFNO8099.AGENTNODE@filter2.operator=EQ@filter2.value=$KPACNO8099.AGENTNODE$@filter3.connector=AND@filter3.column=KPAFNO8099.NCONODE@filter3.operator=EQ@filter3.value=$KPACNO8099.NCONODE$@filterCount=3@property1.name=-1021A@property1.value=kfw.TableRow@propertyCount=1@order1.column=KPAFNO8099.AGENTNODE@order1.sequence=ASCENDING@orderCount=1@multinodeineligible=T@ccsid=55050241@parma1.value="TIMEOUT","600",3@parmaCount=1@@readonly=N@'
  );

INSERT INTO KFWQUERY
  (ID,
   APPL,
   AFFINITIES,
   PROD_PROV,
   NAME,
   TEXT,
   LASTUSER,
   MODIFIED,
   QUERY  )
VALUES
  ("MLGEN-1277759453079",
   "KPA",
   "0000000000000000000000000000G00000000000000",
   "P",
   "Event_Rate Overlay",
   "",
   "SYSADMIN",
   "1071003230324000",
   'tableCount=1@table1.name="KNO_EVENT_RATE_BY_NODE_H"@table1.columnCount=0@property1.name=-1021A@property1.value=kfw.TableRow@propertyCount=1@ccsid=55050241@sqlType=KFW_WH@dsn=KFW_WH@sql=SELECT "WRITETIME" as "tstamp", "MAX_EventCount" as "Event_Rate", -21474836 as "Forecast" FROM $KFW_USR$."KNO_EVENT_RATE_BY_NODE_H" WHERE SHIFTPERIOD = -1
AND "Node" = $KPACNO8099.AGENTNODE$
AND "NcoNode" = $KPACNO8099.NCONODE$
UNION ALL SELECT DISTINCT "Forecast_Timestamp" as "tstamp", -21474836 as "Event_Rate", "Data" as "Forecast" FROM $KFW_USR$."KPA_T_NO8099_LTF" WHERE "Duration" <= 0
and "AgentNode" = $KPACNO8099.AGENTNODE$
and "NcoNode" = $KPACNO8099.NCONODE$
and "Timestamp" = (SELECT MAX("Timestamp") FROM $KFW_USR$."KPA_T_NO8099_LTF" WHERE 1 = 1
AND "AgentNode" = $KPACNO8099.AGENTNODE$
AND "NcoNode" = $KPACNO8099.NCONODE$
) ORDER BY "tstamp","Event_Rate"@parma1.value="TIMEOUT","600",3@parmaCount=1@ctTimeCount=1@ctTime1=tstamp@@readonly=N@'
  );

INSERT INTO KFWQUERY
  (ID,
   APPL,
   AFFINITIES,
   PROD_PROV,
   NAME,
   TEXT,
   LASTUSER,
   MODIFIED,
   QUERY  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "KPA",
   "0000000000000000000000000000G00000000000000",
   "*",
   "OMNIbus_Event_Rate",
   "",
   "SYSADMIN",
   "1071001092706000",
   'at=$THRUNODE$@table1.name=KPACNO8099@table1.columnCount=0@table2.name=KPAFNO8099@table2.columnCount=0@tableCount=2@parma1.value="TIMEOUT","600",3@parmaCount=1@'
  );

INSERT INTO KFWTMPL
  (AFFINITIES,
   AREA,
   ATTRIBS,
   LSTDATE,
   LSTUSRPRF,
   NAME,
   TEXT  )
VALUES
  ("0000000000000000000000000000G00000000000000",
   32,
   259,
   "1071001092706000",
   "_ KCJ",
   "XMLGEN-OMNIbus_Event_Rate",
   "OMNIbus_Event_Rate"
  );

INSERT INTO KFWTMPLSTA
  (TEMPLATE,
   NAME,
   SEVERITY,
   ATTRIBS,
   TEXT  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "Fatal",
   100,
   259,
   "Fatal State"
  );

INSERT INTO KFWTMPLSTA
  (TEMPLATE,
   NAME,
   SEVERITY,
   ATTRIBS,
   TEXT  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "Critical",
   90,
   259,
   "Critical State"
  );

INSERT INTO KFWTMPLSTA
  (TEMPLATE,
   NAME,
   SEVERITY,
   ATTRIBS,
   TEXT  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "Minor",
   40,
   259,
   "Minor State"
  );

INSERT INTO KFWTMPLSTA
  (TEMPLATE,
   NAME,
   SEVERITY,
   ATTRIBS,
   TEXT  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "Warning",
   30,
   259,
   "Warning State"
  );

INSERT INTO KFWTMPLSTA
  (TEMPLATE,
   NAME,
   SEVERITY,
   ATTRIBS,
   TEXT  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "Harmless",
   27,
   259,
   "Harmless State"
  );

INSERT INTO KFWTMPLSTA
  (TEMPLATE,
   NAME,
   SEVERITY,
   ATTRIBS,
   TEXT  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "Informational",
   25,
   259,
   "Informational State"
  );

INSERT INTO KFWTMPLSTA
  (TEMPLATE,
   NAME,
   SEVERITY,
   ATTRIBS,
   TEXT  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "Unknown",
   15,
   259,
   "Unknown State"
  );

INSERT INTO KFWTMPLSTA
  (TEMPLATE,
   NAME,
   SEVERITY,
   ATTRIBS,
   TEXT  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "Unavailable",
   1,
   259,
   "Unavailable State"
  );

INSERT INTO KFWTMPLSTA
  (TEMPLATE,
   NAME,
   SEVERITY,
   ATTRIBS,
   TEXT  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "OK",
   -1,
   65795,
   "Normal and Available State"
  );

INSERT INTO KFWTMPLSIT
  (TEMPLATE,
   STATE,
   TYPE,
   NAME  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "Critical",
   0,
   "Event_Rate_TTCT_1W"
  );

INSERT INTO KFWTMPLSIT
  (TEMPLATE,
   STATE,
   TYPE,
   NAME  )
VALUES
  ("XMLGEN-OMNIbus_Event_Rate",
   "Warning",
   0,
   "Event_Rate_TTWT_1W"
  );
