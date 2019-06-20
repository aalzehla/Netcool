/******************************************************* {COPYRIGHT-TOP-RM} ***
* Licensed Materials - Property of IBM
* "Restricted Materials of IBM"
* 5724-S43
*
* (C) Copyright IBM Corporation 2013, 2014. All Rights Reserved.
*
* US Government Users Restricted Rights - Use, duplication, or
* disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
******************************************************** {COPYRIGHT-END-RM} **/
Load("ITMLibraryFunctionsJS");
var returnEnv = "";
returnEnv=CT_Get ("ITMHostName", 1920, "sysadmin", "ITMPassword","ManagedSystem","ManagedSystemName",null,null,null,returnEnv);
//returnEnv=CT_Acknowledge("ITMHostName",1920,"sysadmin","ITMPassword","situation","ManagedSystemName",null,null,null,returnEnv );
//returnEnv=CT_Activate("ITMHostName",1920,"sysadmin","ITMPassword","situation","ManagedSystemName","situation",returnEnv );
//returnEnv=CT_Alert("ITMHostName",1920,"sysadmin","ITMPassword","situation","ManagedSystemName","Alert description","itemname",returnEnv );
//returnEnv=CT_WTO("ITMHostName",1920,"sysadmin","ITMPassword","This is a message test from Impact","t","Normal",returnEnv);

//returnEnv=CT_Deactivate("ITMHostName",1920,"sysadmin","ITMPassword","situations","ManagedSystemName","itemname",returnEnv);
//returnEnv=CT_Reset("ITMHostName",1920,"sysadmin","ITMPassword","situations","ManagedSystemName","itemname",returnEnv);
//returnEnv=CT_Resurface("ITMHostName",1920,"sysadmin","ITMPassword","situations","ManagedSystemName","itemname",returnEnv);

nsMapping= NewObject();
nsMapping["SOAP-ENV"]= "http://schemas.xmlsoap.org/soap/envelope/";
nsMapping["SOAP_CHK"] = "http://soaptest1/soaptest/";
nsMapping["tns"] = "urn:candle-soap:attributes";

xPathExpr = "//tns:Name/text()";
Result1=GetByXPath(""+returnEnv, nsMapping, xPathExpr);
Log("Result1 is " + Result1);

Log("returnEnv from the main function is : " + returnEnv);
//Log("Name " + Result1.Result.Name[0]);
