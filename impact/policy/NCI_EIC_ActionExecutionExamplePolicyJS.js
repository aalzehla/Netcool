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
Load("EIC_UtilsJS");
Log("Test EIC Action Execution Example JS");
Log(CurrentContext());
RuleName = MatchingRuleName;
if (typeof RuleName == undefined || typeof RuleName == null ) {
  RuleName = EICMATCHINGRULENAME;
}
impactObjects=getRuleResourcesAsImpactObjects(RuleName,PrimaryEventSerial );
Log("Impact Objects " + impactObjects);
