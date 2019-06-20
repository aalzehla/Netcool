DELETE FROM $KPASCHEMA$.KPATASKS WHERE ID = 'MLGEN-1277759453080';
DELETE FROM $KPASCHEMA$.KPAPROPS WHERE TASKID = 'MLGEN-1277759453080';
DELETE FROM $KPASCHEMA$.KPAATTR WHERE TASKID = 'MLGEN-1277759453080';
DELETE FROM $KPASCHEMA$.KPANODES WHERE TASKID = 'MLGEN-1277759453080';
DELETE FROM $KPASCHEMA$.KPAOUTPUTS WHERE TASKID = 'MLGEN-1277759453080';
DELETE FROM $KPASCHEMA$.KPACONSTRAINTS WHERE TASKID = 'MLGEN-1277759453080';
DELETE FROM $KPASCHEMA$.KPAIDENTDESTS WHERE TASKID = 'MLGEN-1277759453080';
DELETE FROM $KPASCHEMA$.KPAIDENTSRCS WHERE TASKID = 'MLGEN-1277759453080';
DELETE FROM $KPASCHEMA$.KPAJOINS WHERE TASKID = 'MLGEN-1277759453080';
DELETE FROM $KPASCHEMA$.KPAOUTPUTSETS WHERE TASKID = 'MLGEN-1277759453080';

INSERT INTO $KPASCHEMA$.KPATASKS
(
  TASKNAME,
  ISACTIVE,
  STARTUPRUN,
  TASKDESC,
  UPDATETIME,
  TASKINT,
  PREID,
  ID,
  MODTYPE,
  EXPRESSION
)
VALUES
(
  'Event Rate Forecast',
  1,
  1,
  '',
  '2010-06-28 23:13:34.646',
  1800,
  '',
  'MLGEN-1277759453080',
  'LinearTrending',
  'lsr(x, t)'
);

INSERT INTO $KPASCHEMA$.KPAPROPS
(
  TASKID,
  PROPVALUE,
  PROPNAME,
  OUTPUTUID
)
VALUES
(
  'MLGEN-1277759453080',
  '10000',
  'threshold',
  '2fa0152c:115add8e9fe:-73af'
);

INSERT INTO $KPASCHEMA$.KPAPROPS
(
  TASKID,
  PROPVALUE,
  PROPNAME,
  OUTPUTUID
)
VALUES
(
  'MLGEN-1277759453080',
  '8000',
  'threshold',
  '2fa0152c:115add8e9fe:-73ae'
);

INSERT INTO $KPASCHEMA$.KPAPROPS
(
  TASKID,
  PROPVALUE,
  PROPNAME,
  OUTPUTUID
)
VALUES
(
  'MLGEN-1277759453080',
  '90',
  'fp',
  '2fa0152c:115add8e9fe:-73ab'
);

INSERT INTO $KPASCHEMA$.KPAPROPS
(
  TASKID,
  PROPVALUE,
  PROPNAME,
  OUTPUTUID
)
VALUES
(
  'MLGEN-1277759453080',
  '7',
  'fp',
  '2fa0152c:115add8e9fe:-73a9'
);

INSERT INTO $KPASCHEMA$.KPAPROPS
(
  TASKID,
  PROPVALUE,
  PROPNAME,
  OUTPUTUID
)
VALUES
(
  'MLGEN-1277759453080',
  '30',
  'fp',
  '2fa0152c:115add8e9fe:-73a8'
);

INSERT INTO $KPASCHEMA$.KPAPROPS
(
  TASKID,
  PROPVALUE,
  PROPNAME,
  OUTPUTUID
)
VALUES
(
  'MLGEN-1277759453080',
  'WRITETIME',
  'AGTIME',
  'x'
);

INSERT INTO $KPASCHEMA$.KPAPROPS
(
  TASKID,
  PROPVALUE,
  PROPNAME,
  OUTPUTUID
)
VALUES
(
  'MLGEN-1277759453080',
  'HourSum',
  'Granularity',
  NULL
);

INSERT INTO $KPASCHEMA$.KPAPROPS
(
  TASKID,
  PROPVALUE,
  PROPNAME,
  OUTPUTUID
)
VALUES
(
  'MLGEN-1277759453080',
  '2010-06-30 13:59:21',
  'LASTRAN',
  NULL
);

INSERT INTO $KPASCHEMA$.KPAATTR
(
  TASKID,
  ORIGINNODECOL,
  ATTRID,
  AFFINITY,
  SCHNAME,
  COLNAME,
  ID,
  ATTRTYPE,
  ISINPUT,
  ATTRNAME,
  ATTRGROUPID,
  TABLENAME,
  DBNAME
)
VALUES
(
  'MLGEN-1277759453080',
  '"Node"',
  'KNONCOERND.EVTCNT',
  '0000000000000000000000000040000000000000000',
  'ITMUSER',
  '"MAX_EventCount"',
  'x',
  'Number',
  1,
  'EventCount',
  'KNONCOERND',
  '"KNO_EVENT_RATE_BY_NODE"',
  'WAREHOUS'
);

INSERT INTO $KPASCHEMA$.KPANODES
(
  TASKID,
  ISGROUP,
  NODEVAL
)
VALUES
(
  'MLGEN-1277759453080',
  1,
  '*OMNIBUS_SERVER_AGENT'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTS
(
  ID,
  TASKID,
  ATTRID,
  UNIQUEID,
  ATTRGROUPID,
  ATTRNAME,
  APPL,
  OUTPUTSETID,
  ATTRTYPE,
  AFFINITY
)
VALUES
(
  'confidence',
  'MLGEN-1277759453080',
  'KPACNO8099.CONFIDENCE',
  '2fa0152c:115add8e9fe:-73ad',
  'KPACNO8099',
  'Confidence',
  'kpa',
  '-2b3b3330:129806f7933:-7f7e',
  'Number',
  '0000000000000000000000000000G00000000000000'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTS
(
  ID,
  TASKID,
  ATTRID,
  UNIQUEID,
  ATTRGROUPID,
  ATTRNAME,
  APPL,
  OUTPUTSETID,
  ATTRTYPE,
  AFFINITY
)
VALUES
(
  'direct',
  'MLGEN-1277759453080',
  'KPACNO8099.DIRECTION',
  '2fa0152c:115add8e9fe:-73ac',
  'KPACNO8099',
  'Direction',
  'kpa',
  '-2b3b3330:129806f7933:-7f7e',
  'Number',
  '0000000000000000000000000000G00000000000000'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTS
(
  ID,
  TASKID,
  ATTRID,
  UNIQUEID,
  ATTRGROUPID,
  ATTRNAME,
  APPL,
  OUTPUTSETID,
  ATTRTYPE,
  AFFINITY
)
VALUES
(
  'nsamp',
  'MLGEN-1277759453080',
  'KPACNO8099.NSAMPLES',
  '2fa0152c:115add8e9fe:-73b1',
  'KPACNO8099',
  'Number_Of_Samples',
  'kpa',
  '-2b3b3330:129806f7933:-7f7e',
  'Number',
  '0000000000000000000000000000G00000000000000'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTS
(
  ID,
  TASKID,
  ATTRID,
  UNIQUEID,
  ATTRGROUPID,
  ATTRNAME,
  APPL,
  OUTPUTSETID,
  ATTRTYPE,
  AFFINITY
)
VALUES
(
  'str',
  'MLGEN-1277759453080',
  'KPACNO8099.STRENGTH',
  '2fa0152c:115add8e9fe:-73b0',
  'KPACNO8099',
  'Strength',
  'kpa',
  '-2b3b3330:129806f7933:-7f7e',
  'Number',
  '0000000000000000000000000000G00000000000000'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTS
(
  ID,
  TASKID,
  ATTRID,
  UNIQUEID,
  ATTRGROUPID,
  ATTRNAME,
  APPL,
  OUTPUTSETID,
  ATTRTYPE,
  AFFINITY
)
VALUES
(
  'ttct',
  'MLGEN-1277759453080',
  'KPACNO8099.TTCRITHRES',
  '2fa0152c:115add8e9fe:-73af',
  'KPACNO8099',
  'Time_To_Critical_Threshold',
  'kpa',
  '-2b3b3330:129806f7933:-7f7e',
  'Number',
  '0000000000000000000000000000G00000000000000'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTS
(
  ID,
  TASKID,
  ATTRID,
  UNIQUEID,
  ATTRGROUPID,
  ATTRNAME,
  APPL,
  OUTPUTSETID,
  ATTRTYPE,
  AFFINITY
)
VALUES
(
  'ttwt',
  'MLGEN-1277759453080',
  'KPACNO8099.TTWRNTHRES',
  '2fa0152c:115add8e9fe:-73ae',
  'KPACNO8099',
  'Time_To_Warning_Threshold',
  'kpa',
  '-2b3b3330:129806f7933:-7f7e',
  'Number',
  '0000000000000000000000000000G00000000000000'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTS
(
  ID,
  TASKID,
  ATTRID,
  UNIQUEID,
  ATTRGROUPID,
  ATTRNAME,
  APPL,
  OUTPUTSETID,
  ATTRTYPE,
  AFFINITY
)
VALUES
(
  'y',
  'MLGEN-1277759453080',
  'KPAFNO8099.DATA',
  '2fa0152c:115add8e9fe:-73ab',
  'KPAFNO8099',
  'Data',
  'kpa',
  '-2b3b3330:129806f7933:-7f78',
  'Number',
  '0000000000000000000000000000G00000000000000'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTS
(
  ID,
  TASKID,
  ATTRID,
  UNIQUEID,
  ATTRGROUPID,
  ATTRNAME,
  APPL,
  OUTPUTSETID,
  ATTRTYPE,
  AFFINITY
)
VALUES
(
  'ts',
  'MLGEN-1277759453080',
  'KPAFNO8099.FCSTTIME',
  '2fa0152c:115add8e9fe:-73aa',
  'KPAFNO8099',
  'Forecast_Timestamp',
  'kpa',
  '-2b3b3330:129806f7933:-7f78',
  'Date',
  '0000000000000000000000000000G00000000000000'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTS
(
  ID,
  TASKID,
  ATTRID,
  UNIQUEID,
  ATTRGROUPID,
  ATTRNAME,
  APPL,
  OUTPUTSETID,
  ATTRTYPE,
  AFFINITY
)
VALUES
(
  'y',
  'MLGEN-1277759453080',
  'KPAFNO8099.DATA',
  '2fa0152c:115add8e9fe:-73a9',
  'KPAFNO8099',
  'Data',
  'kpa',
  '-2b3b3330:129806f7933:-7f78',
  'Number',
  '0000000000000000000000000000G00000000000000'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTS
(
  ID,
  TASKID,
  ATTRID,
  UNIQUEID,
  ATTRGROUPID,
  ATTRNAME,
  APPL,
  OUTPUTSETID,
  ATTRTYPE,
  AFFINITY
)
VALUES
(
  'y',
  'MLGEN-1277759453080',
  'KPAFNO8099.DATA',
  '2fa0152c:115add8e9fe:-73a8',
  'KPAFNO8099',
  'Data',
  'kpa',
  '-2b3b3330:129806f7933:-7f78',
  'Number',
  '0000000000000000000000000000G00000000000000'
);

INSERT INTO $KPASCHEMA$.KPAIDENTDESTS
(
  ATTRGROUPID,
  IDENTTYPE,
  ATTRID,
  ATTRTYPE,
  AFFINITY,
  OUTPUTSETID,
  ATTRKEY,
  APPL,
  UNIQUEID,
  ATTRNAME,
  TASKID
)
VALUES
(
  'KPACNO8099',
  0,
  'KPACNO8099.AGENTNODE',
  'Object',
  '0000000000000000000000000000G00000000000000',
  '-2b3b3330:129806f7933:-7f7e',
  'Node',
  'kpa',
  '-2b3b3330:129806f7933:-7f7d',
  'AgentNode',
  'MLGEN-1277759453080'
);

INSERT INTO $KPASCHEMA$.KPAIDENTDESTS
(
  ATTRGROUPID,
  IDENTTYPE,
  ATTRID,
  ATTRTYPE,
  AFFINITY,
  OUTPUTSETID,
  ATTRKEY,
  APPL,
  UNIQUEID,
  ATTRNAME,
  TASKID
)
VALUES
(
  'KPACNO8099',
  0,
  'KPACNO8099.NCONODE',
  'Object',
  '0000000000000000000000000000G00000000000000',
  '-2b3b3330:129806f7933:-7f7e',
  'NcoNode',
  'kpa',
  '-2b3b3330:129806f7933:-7f7b',
  'NcoNode',
  'MLGEN-1277759453080'
);

INSERT INTO $KPASCHEMA$.KPAIDENTDESTS
(
  ATTRGROUPID,
  IDENTTYPE,
  ATTRID,
  ATTRTYPE,
  AFFINITY,
  OUTPUTSETID,
  ATTRKEY,
  APPL,
  UNIQUEID,
  ATTRNAME,
  TASKID
)
VALUES
(
  'KPACNO8099',
  2,
  'KPACNO8099.TIMESTAMP',
  'Date',
  '0000000000000000000000000000G00000000000000',
  '-2b3b3330:129806f7933:-7f7e',
  'AnalyticTimeC',
  'kpa',
  '-2b3b3330:129806f7933:-7f79',
  'Timestamp',
  'MLGEN-1277759453080'
);

INSERT INTO $KPASCHEMA$.KPAIDENTDESTS
(
  ATTRGROUPID,
  IDENTTYPE,
  ATTRID,
  ATTRTYPE,
  AFFINITY,
  OUTPUTSETID,
  ATTRKEY,
  APPL,
  UNIQUEID,
  ATTRNAME,
  TASKID
)
VALUES
(
  'KPAFNO8099',
  2,
  'KPAFNO8099.TIMESTAMP',
  'Date',
  '0000000000000000000000000000G00000000000000',
  '-2b3b3330:129806f7933:-7f78',
  'AnalyticTimeF',
  'kpa',
  '-2b3b3330:129806f7933:-7f77',
  'Timestamp',
  'MLGEN-1277759453080'
);

INSERT INTO $KPASCHEMA$.KPAIDENTDESTS
(
  ATTRGROUPID,
  IDENTTYPE,
  ATTRID,
  ATTRTYPE,
  AFFINITY,
  OUTPUTSETID,
  ATTRKEY,
  APPL,
  UNIQUEID,
  ATTRNAME,
  TASKID
)
VALUES
(
  'KPAFNO8099',
  3,
  'KPAFNO8099.DURATION',
  'Number',
  '0000000000000000000000000000G00000000000000',
  '-2b3b3330:129806f7933:-7f78',
  'fp',
  'kpa',
  '-2b3b3330:129806f7933:-7f76',
  'Duration',
  'MLGEN-1277759453080'
);

INSERT INTO $KPASCHEMA$.KPAIDENTDESTS
(
  ATTRGROUPID,
  IDENTTYPE,
  ATTRID,
  ATTRTYPE,
  AFFINITY,
  OUTPUTSETID,
  ATTRKEY,
  APPL,
  UNIQUEID,
  ATTRNAME,
  TASKID
)
VALUES
(
  'KPAFNO8099',
  0,
  'KPAFNO8099.AGENTNODE',
  'Object',
  '0000000000000000000000000000G00000000000000',
  '-2b3b3330:129806f7933:-7f78',
  'Node',
  'kpa',
  '-2b3b3330:129806f7933:-7f75',
  'AgentNode',
  'MLGEN-1277759453080'
);

INSERT INTO $KPASCHEMA$.KPAIDENTDESTS
(
  ATTRGROUPID,
  IDENTTYPE,
  ATTRID,
  ATTRTYPE,
  AFFINITY,
  OUTPUTSETID,
  ATTRKEY,
  APPL,
  UNIQUEID,
  ATTRNAME,
  TASKID
)
VALUES
(
  'KPAFNO8099',
  0,
  'KPAFNO8099.NCONODE',
  'Object',
  '0000000000000000000000000000G00000000000000',
  '-2b3b3330:129806f7933:-7f78',
  'NcoNode',
  'kpa',
  '-2b3b3330:129806f7933:-7f73',
  'NcoNode',
  'MLGEN-1277759453080'
);

INSERT INTO $KPASCHEMA$.KPAIDENTSRCS
(
  SCHNAME,
  AFFINITY,
  ATTRID,
  COLNAME,
  TABLENAME,
  ORIGINNODECOL,
  ATTRGROUPID,
  TASKID,
  DBNAME,
  DESTUID,
  UNIQUEID
)
VALUES
(
  'ITMUSER',
  '0000000000000000000000000040000000000000000',
  'KNONCOERND.ORIGINNODE',
  '"Node"',
  '"KNO_EVENT_RATE_BY_NODE"',
  '"Node"',
  'KNONCOERND',
  'MLGEN-1277759453080',
  'WAREHOUS',
  '-2b3b3330:129806f7933:-7f7d',
  '-2b3b3330:129806f7933:-7f7c'
);

INSERT INTO $KPASCHEMA$.KPAIDENTSRCS
(
  SCHNAME,
  AFFINITY,
  ATTRID,
  COLNAME,
  TABLENAME,
  ORIGINNODECOL,
  ATTRGROUPID,
  TASKID,
  DBNAME,
  DESTUID,
  UNIQUEID
)
VALUES
(
  'ITMUSER',
  '0000000000000000000000000040000000000000000',
  'KNONCOERND.NCONODE',
  '"NcoNode"',
  '"KNO_EVENT_RATE_BY_NODE"',
  '"Node"',
  'KNONCOERND',
  'MLGEN-1277759453080',
  'WAREHOUS',
  '-2b3b3330:129806f7933:-7f7b',
  '-2b3b3330:129806f7933:-7f7a'
);

INSERT INTO $KPASCHEMA$.KPAIDENTSRCS
(
  SCHNAME,
  AFFINITY,
  ATTRID,
  COLNAME,
  TABLENAME,
  ORIGINNODECOL,
  ATTRGROUPID,
  TASKID,
  DBNAME,
  DESTUID,
  UNIQUEID
)
VALUES
(
  'ITMUSER',
  '0000000000000000000000000040000000000000000',
  'KNONCOERND.ORIGINNODE',
  '"Node"',
  '"KNO_EVENT_RATE_BY_NODE"',
  '"Node"',
  'KNONCOERND',
  'MLGEN-1277759453080',
  'WAREHOUS',
  '-2b3b3330:129806f7933:-7f75',
  '-2b3b3330:129806f7933:-7f74'
);

INSERT INTO $KPASCHEMA$.KPAIDENTSRCS
(
  SCHNAME,
  AFFINITY,
  ATTRID,
  COLNAME,
  TABLENAME,
  ORIGINNODECOL,
  ATTRGROUPID,
  TASKID,
  DBNAME,
  DESTUID,
  UNIQUEID
)
VALUES
(
  'ITMUSER',
  '0000000000000000000000000040000000000000000',
  'KNONCOERND.NCONODE',
  '"NcoNode"',
  '"KNO_EVENT_RATE_BY_NODE"',
  '"Node"',
  'KNONCOERND',
  'MLGEN-1277759453080',
  'WAREHOUS',
  '-2b3b3330:129806f7933:-7f73',
  '-2b3b3330:129806f7933:-7f72'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTSETS
(
  UNIQUEID,
  NAME,
  TASKID
)
VALUES
(
  '-2b3b3330:129806f7933:-7f7e',
  'Status',
  'MLGEN-1277759453080'
);

INSERT INTO $KPASCHEMA$.KPAOUTPUTSETS
(
  UNIQUEID,
  NAME,
  TASKID
)
VALUES
(
  '-2b3b3330:129806f7933:-7f78',
  'Forecast',
  'MLGEN-1277759453080'
);