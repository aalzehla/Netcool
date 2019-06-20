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

function convertJsonToIPL(jsonStr,isStrStartsWithArray,keySet) {
   Log("Converting JSON to IPL");
   var jsonArrayClass = "com.ibm.json.java.JSONArray";
   var jsonObjectClass = "com.ibm.json.java.JSONObject";
   var setClass = "java.util.Set";
   var iteratorClass = "java.util.Iterator";
   var parseMethod = "parse";
   var getMethod = "get";
   var outputObj = [];
   if ( isStrStartsWithArray ) {

      Log(3,"Starting to process Array");
     var outputObj = [];
      var eturnArray = JavaCall(jsonArrayClass ,null,parseMethod,[jsonStr]);
      var exceptionRaised = GetGlobalVar('EXCEPTION_RAISED');
      if( exceptionRaised == false ) { 
        var lenOfArray  = JavaCall(jsonArrayClass,returnArray,"size",null);
        var count = 0 ;
         Log(3,"Number of Entries : " + lenOfArray);
         while( count < (lenOfArray) ) {
         var    objInArray = JavaCall(jsonArrayClass,returnArray,getMethod,[count]);
            Log(3,"Obtained the Array");
            var iplObj = NewObject();
            var lenOfKeySet=Length(keySet);
            var keyCount = 0;
            while(keyCount < Int(lenOfKeySet) ) {
                Log(3,"obtaining the value for : " + keySet[keyCount]);
                var value = JavaCall(jsonObjectClass,objInArray,getMethod,[keySet[keyCount]]);
                iplObj[keySet[keyCount]] = value;
                keyCount = keyCount + 1;
            } // keyCount <  lenOfKeySet
            outputObj[count] = iplObj;
            count = count + 1;
         } // count < lenOfArray
      } // if exceptionRaised.
   } else {
      //make the object 
      jsonObject = JavaCall(jsonObjectClass ,null,parseMethod,[jsonStr]); 
      returnArray = JavaCall(null,jsonObject ,"get",["items"]);
        lenOfArray  = JavaCall(null,returnArray,"size",null);
         count = 0 ;
         Log(3,"Number of Entries : " + lenOfArray);
         while( count < Int(lenOfArray) ) {
            //objInArray = JavaCall(null,returnArray,getMethod,[0]);
            objInArray =  returnArray.get(count);
            Log(3,"Obtained the Array");
            Log("objInArray " + objInArray); 
            iplObj = NewObject();
            lenOfKeySet=Length(keySet);
            keyCount = 0;
            while(keyCount < lenOfKeySet ) {
                Log(3,"obtaining the value for : " + keySet[keyCount]);
                value = JavaCall(jsonObjectClass,objInArray,getMethod,[keySet[keyCount]]);
                iplObj[keySet[keyCount]] = value;
                keyCount = keyCount + 1;
            } // keyCount <  lenOfKeySet
            outputObj[count] = iplObj;
            count = count + 1;
         } // count < lenOfArray 
   }
  return outputObj ; 
}


/**
*Gets the resources from the database and returns an array of objects
*this is helpful when user executes policies for actions.
*User can call this function to get all the resources information
* and do an action based on this information.
*/
function getRuleResourcesAsImpactObjects(RuleName, serialNum) {
 var outputObj=[]; 
 Log("Getting Resources for RuleName : " + RuleName);
 if (typeof RuleName == undefined || RuleName == null || RuleName == "") {
   Log("You must provide a Rule Name to get objects");
 
 } else {
   Log("Getting Resources..."); 
   Resources = GetByFilter('EIC_RuleResources',"RULENAME='"+RuleName+"' AND Serial="+serialNum,null);
    ResourcesJSON = Resources[0].RESOURCES;
   // Log(" ResourcesJSON " + ResourcesJSON );
    
 keySet=["UITreeNodeType" ,"EICMATCHINGRULENAME" ,"UITreeNodeId" 
,"UITreeParentNodeId" ,"UITreeNodeStatus" ,"UITreeNodeParent" 
,"UITreeNodeLabel" ,"Node" ,"AlertGroup" ,"AlertKey" ,"leveldown" 
,"Summary" ,"Identifier" ,"reltype" ,"label" ,"Serial" 
,"resourceIdentifier" ,"type" ,"Type" ,"id" ,"Severity" ]; 
     outputObj = convertJsonToIPL(""+ResourcesJSON ,false,keySet);
    // Log("Resource Of Impact is " + outputObj); 
   } 
  return  outputObj;
}  

 
/**
*creates a Impact Objects for the resources of
*the current rule.
*/
 function createImpactObjectsFromResources() {
  Log("Activating createImpactObjectsFromResources...");
  dependentResourcesArray = outDependentResourcesArray  ;
  RuleName = MatchingRuleName ;
   
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
    
}

/*
*The following call is a must to create the resources
*this call should be the only call in this library function
*/
//createImpactObjectsFromResources(); 
