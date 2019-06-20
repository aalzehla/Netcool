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

Log("Visualize EIC in topology view");

if (typeof Serial == "undefined" || Serial == null ) {
 Log("Serial field is not defined"); 
} else {
  Log("Serial field is defined and will be assinged to serialNum : " + Serial);
  serialNum = Serial;
}
if( typeof serialNum == "undefined" || serialNum == null ) {
   Log("serialNum is not defined");
   //serialNum =  "0";
   // serialNum = "896096";
} else { 
   EventContainer.serialNumber = Int(serialNum);
   EventContainer.isResourceRel = true; 

   Activate(null,'EIC_IsolateAndCorrelate');

 Log("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ COMPLETED CORRELATION $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"); 
   Log("Topology MatchingRuleName = " + GetGlobalVar("MATCHINGRULENAME"));
 //hack to get the rule name
   Rule=GetByFilter('EVENTRULES',"ID="+eRuleInfo,null);
   MatchingRuleName = Rule[0].RULENAME;
  Log("Topology MatchingRuleName GetByFilter result = " + MatchingRuleName );
 
   Log("Rule Name " + eRuleInfo); 
   Log("Primary Event : " + primaryEventInfo);
   Log("Alert Array : " + alertArray);
   Log("dependentResourcesArray : " + dependentResourcesArray);
   if( typeof eRuleInfo != "undefined" && eRuleInfo != null ) { 
     Log("Rule Processed : " + eRuleInfo);
   }
   
   Log("Length of dependent Resources Array : " + Length(dependentResourcesArray)); 
    if ( dependentResourcesArray == null || Length (dependentResourcesArray) == 0 ) {
     Log("No dependent resources found.");
     Exit();
    }  
   /*
   for( var i = 0; i < dependentResourcesArray.length;i++) {
       Log("Dependent Resources Array : " +  dependentResourcesArray[i] );
       res =  dependentResourcesArray[i];
       Log("Dependent Resources Array (Node): " + res.get("Node") ); 
       printObject(dependentResourcesArray[i]); 
   }
   */
    
   keys = Keys(dependentResourcesArray[0]);
   lenKeys = Length(keys); 
   arrayOfObjects = [];
   namedArrayToCreateParentChild = [];
   var indexNodeId = 1; 
   for( var i = 0; i < dependentResourcesArray.length;i++,indexNodeId++) {
      obj = NewObject(); 
      obj.UITreeNodeType='GRAPH'; 
      obj.EICMATCHINGRULENAME=  ""+ MatchingRuleName;
      Log("obj.EICMATCHINGRULENAME " + obj.EICMATCHINGRULENAME);
      obj.UITreeNodeId = indexNodeId; 
      obj.UITreeParentNodeId  = 0;
      obj.UITreeNodeStatus=0;
      obj.UITreeNodeParent =0;
      obj.PrimaryEventSerial =  serialNum ;
      id = "" + dependentResourcesArray[i].get('id');
      namedArrayToCreateParentChild[id] = i;
      type = "" + dependentResourcesArray[i].get('type'); 
      if( type == 'EVENT' ) {
        obj.UITreeNodeLabel = 'Event Serial : ' + dependentResourcesArray[i].get('Serial'); 
        sev = "" + dependentResourcesArray[i].get('Severity');
        obj.UITreeNodeStatus=Int(sev);
      } else {
        obj.UITreeNodeLabel = 'Resource : ' + dependentResourcesArray[i].get('label'); 
      }
      for(m=0;m <lenKeys;m++) {
        key = keys[m];
        if( key != 'children' ) { 
           val =  dependentResourcesArray[i].get(key);
           if( val != null )  {
              obj[key] = ""+dependentResourcesArray[i].get(key);
              delete val; 
           }else {
              obj[key] = "" ; 
           }
        }
        
      }
      arrayOfObjects[i] = obj;  
   }
   for( var i = 0; i < dependentResourcesArray.length;i++) {
      id =  id = "" + dependentResourcesArray[i].get('id');
      var children = dependentResourcesArray[i].get('children');
      var paro = namedArrayToCreateParentChild[id];
      var ParObj =  arrayOfObjects[paro];
      parentId = ParObj['UITreeNodeId']; 
      Log( " Parent ID : " + parentId); 
      chLen = Length(children);
      Log("ChLen : " + chLen); 
      if( chLen > 0 ) {
         for(var m = 0; m < chLen ; m++) {
              chId = "" + children[m];
              Log("Child Identification : " + chId); 
              caid = namedArrayToCreateParentChild[chId];
              Log("CaID : " + caid); 
              ob1 = arrayOfObjects[caid];
              ob1.UITreeNodeParent = parentId; 
         }
      }
      delete children; 
   }
   // Log("CurrentContext : " + CurrentContext()); 
   
   /* Create Array of Impact Object */

   Log("Array of Impact Objects : " + arrayOfObjects );
   
   l= Length(arrayOfObjects);
   for(var i = 0; i < l; i ++ ) {
   
      Log(" ID : " + arrayOfObjects[i].UITreeNodeId + " Parent Node : " + arrayOfObjects[i].UITreeNodeParent); 
   }
   
   delete namedArrayToCreateParentChild;
   delete dependentResourcesArray;
   delete eRuleInfo;
   delete alertArray;
   // delete printObject; 
   delete outString;
   delete keys; 
}
