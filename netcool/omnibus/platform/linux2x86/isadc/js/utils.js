/**
 * 
 */


var executionEnv = (function(){
	// summary:
	//		executionEnv provides functions and variables which contain 
	//		information	about the browser runtime
	// returns:
	//		an Object containing execution environment information
	
	// isFile: 
	//		Boolean indicator of file vs http protocol for the browser
	// 
	// pmr: This is the PMR Number that was passed to the URL. If no PMR was passed, a default PMR value is used
	// taxonomy: This is the taxonomy code of the product, for which data collection will be run.
	// scriptID: This is the script ID for the data collection to be run.
	// collectionName: This is the readable label for the name of the taxonomy Code
	//
	var isFile = location.protocol === "file:";
	var params = dojo.queryToObject(window.location.search.slice(1));
	 noLandingPage=params["noLandingPage"];
	 console.debug("Parameters: "+location.search);
	 
	//Set to true, if we are running within the development Environment.
	//Used to help navigate through 
	var isDevelopmentEnv=checkDevelopmentEnvironment();
	
	console.debug ("Running In Development Environment? "+isDevelopmentEnv);

	//Set defaults
    var pmrNumber= ""; //This is the PMR Number passed as a URl Parameter
    var collectionTaxonomy = ""; //This is the Taxonomy Code, if passed as a URL Parameter
    var scriptID="";     // This is the Script ID. Could be passed, if the user wants to run the Script directly
    var componentID= ""; //This is the Component ID. Optional
    var productID= ""; // This is the product ID . Optional
    var productIDVersion=""; //This is the version of the product ID . Optional
    var componentRelease=""; //This is the version of the Component. Optional
    var login=""; //This is the login that was passed
    var email=""; //This is the email address that was passed. Optional
    var linkSource=""; //This is the source of the request to run this collector. Products can set this to track marketing information
    var collectorScriptsVersion=""; //This is the version of the Data Collection scripts. i.e.: taxonomy=System, collectorScriptsVersion=2.0.1

	
	if(isFile){ //file protocol, assume user should simply double click. All information should be picked up from the file.
		var baseLocation="../../";
		if(isDevelopmentEnv){ //File protocol in the Dev. Environment			
			prodInfoFile=baseLocation + "services/devEnvProdInfoFile.json"; //In the development Environment, we read this file
		} else {			
			prodInfoFile=baseLocation + "properties/prodinfo.json";
		}
		
		try {		
			var deferred=dojo.xhrGet({
				url:prodInfoFile,
				handleAs:"json",
				preventCache:true,
				sync:true,
				load: function(response){
					console.debug("The product JSON file loaded successfully. from "+prodInfoFile);
					productJson=response;
				}, 
				error: function(response){
					console.debug(" There was an error loading the product JSON file from location: "+prodInfoFile + ". Error message=" +response);
				}
			});
		}catch(e){
			console.debug("An exception was thrown while reading the prodinfo.json file from location: "+prodInfoFile);		
		}

		  //Product information parameters
	     collectionTaxonomy = productJson.taxonomy;
	     collectorScriptsVersion = productJson.version;
	
	 }else { //http protocol
    
	  //Get all the parameters passed on the URL
      collectionTaxonomy = params["taxonomy"];
      scriptID = params["scriptID"];
      pmrNumber = params["pmr"];
      componentID = params["compId"];
      productID = params["prodId"];
      productIDVersion=params["version"]; //Version of the productID from the SR URL
      componentRelease=params["release"];
      login=params["login"];
      email=params["email"];
      linkSource=params["linkSource"];
      collectorScriptsVersion=params["productVersion"]; //Version of the Data Collecto Scripts
      
              		
	  if (!collectionTaxonomy) {
		  console.debug("No Collection Taxonomy was passed as query parameter. ");		
		}
	  if (!collectorScriptsVersion) {
		  console.debug("No Collection Scripts version was passed as query parameter. ");		
		}

		
	  if(!pmrNumber){
		  console.debug("No PMR Number was passed as query parameter. ");	
		  pmrNumber="00000,000,000";
		}

	  if(!scriptID){
		  console.debug("No script ID was passed as query parameter. ");			  
		}
	  if(!noLandingPage){
		  console.debug("skipLanding page was not specified");
	  }else {
		  console.debug("skipLanding page was specified");
	  }
	}
	
	console.debug("The following URL Parameters were passed:");
    console.debug("ScriptID : "+scriptID);
    console.debug("PMR Number: "+pmrNumber);
    console.debug("Taxonomy name: "+collectionTaxonomy);
    console.debug("componentID : "+componentID);
    console.debug("productID: "+productID);
    console.debug("productIDVersion: "+productIDVersion);
    console.debug("componentRelease: "+componentRelease);
    console.debug("login: "+login);
    console.debug("email:"+email);
    console.debug("linkSource:"+linkSource);
    console.debug("collectorScriptsVersion:"+collectorScriptsVersion);
    
    console.debug("The following values were calculated: ");
    console.debug("Current locale: "+dojo.locale);
    console.debug("isFile protocol?: "+isFile);
    console.debug("developmentEnvironment?: "+isDevelopmentEnv);

	return { // return Object
		isFile: isFile,
		pmrNumber:pmrNumber,		
		taxonomy:collectionTaxonomy,
		scriptID:scriptID,
		isaDevEnv:isDevelopmentEnv,
		componentID:componentID,
		componentRelease:componentRelease,
		productID:productID,
		productIDVersion:productIDVersion,
		login:login,
		email:email,
		linkSource:linkSource,
		noLandingPage:noLandingPage,
		collectorScriptsVersion:collectorScriptsVersion
	};
})();

	
//This javascript function will be called, when the data collection completes.	
function collectionCompleted(text){
	// summary:
	//    Collection has completed. Publish this event for others (CollectionStatus) to consume.
	//
	console.debug('Collection Completed: '+text);    
	var arrayOfInputs=new Array();
	arrayOfInputs[0]=text;
	
    dojo.publish("CollectionCompleted", arrayOfInputs);	    
}

function uploadComplete(status){
	// summary:
	//    Upload of collection has completed. Publish this event for others (CollectionStatus) to consume.
	//
	console.debug("Running uploadComplete: " + status);
	var statusReturned = dojo.fromJson(status);
	console.debug("some status" + statusReturned);

	
	var statusJSON = {};
	statusJSON.type = "UPLOAD";
	statusJSON.collectionStatus = {};

	
	if (statusReturned.uploadStatus.returnCode=="success") {
		statusJSON.collectionStatus.canceled = false;
		statusJSON.collectionStatus.collectionFailure = false;
		statusJSON.collectionStatus.completionStatus = "NORMAL";
		statusJSON.collectionStatus.message = statusReturned.uploadStatus.message;
		console.debug("Upload successful");
	}
	else if (statusReturned.uploadStatus.returnCode=="canceled") {
		statusJSON.collectionStatus.canceled = true;
		statusJSON.collectionStatus.completionStatus = "CANCELED";
		statusJSON.collectionStatus.message = statusReturned.uploadStatus.message;
		console.debug("Upload cancelled");
	}
	else if (statusReturned.uploadStatus.returnCode=="error") {
		statusJSON.collectionStatus.completionStatus = "ERROR";
		statusJSON.collectionStatus.collectionFailure = true;
		statusJSON.collectionStatus.canceled = false;
		statusJSON.collectionStatus.message = statusReturned.uploadStatus.message;
		console.debug("Upload failed due to error!");
	}
    dojo.publish("UploadCompleted", [dojo.toJson(statusJSON)]);	    
}

function uploadStatusMsg(msg){
	// summary:
	//    Collection has completed. Publish this event for others (CollectionStatus) to consume.
	//
	console.debug("In uploadStatusMsg");

	var msgJSON = {};
	msgJSON.message = msg;

	dojo.publish("UpdateStatusArea", [dojo.toJson(msgJSON)]);
	   
}

function uploadProgress(percent){
	// summary:
	//    Collection has completed. Publish this event for others (CollectionStatus) to consume.
	//
	console.debug("In uploadProgress");
	
	var statusJSON = {};
	statusJSON.progress = percent;

	dojo.publish("UpdateStatusArea", [dojo.toJson(statusJSON)]);
}

function updateProgressBar(percent) {
	
	var statusJSON = {};
	statusJSON.progress = percent;

	dojo.publish("UpdateStatusArea", [dojo.toJson(statusJSON)]);
}

//
function requestInput(text){
	// summary:
	//		Input has been requested from the Back end.
	//
	console.debug("Request Input String: "+text);
	var textJson=dojo.fromJson(text); 
	var arrayOfInputs=new Array();
	arrayOfInputs[0]=textJson;
		
	dojo.publish("InputRequested", arrayOfInputs);		 
}

//This will publish an updateStatusArea event.
function updateStatusArea(text) {
	// summary:
	//		This function updates the status Area, based on information read from the Applet 
	//
	
    var tempString = {'message':text,status:'info',action:'none'};
    var jsonString = dojo.toJson(tempString, true);
    
    console.debug('converted status area message: '+jsonString);
    
    dojo.publish("UpdateStatusArea", [jsonString]);	    
}


function checkDevelopmentEnvironment() {
	// summary:
	//		Checks to see if we are running in a development Environment or in Production 
	//	    To run in a development Environment, one needs to use the following query param: developmentEnvironment=true on the URL
	// returns:
	//		true: if this is the dev. Environment
	//      false: if this is Production
	//
	
	//var devEnv=false;
	var params = dojo.queryToObject(window.location.search.slice(1));
	var devEnv= params["developmentEnvironment"];
	if(devEnv=='true'){
		devEnv=true;
	}		
	return devEnv;
}

function getCBWidthInPixels(items) {
	//go through list of options and "measure" width of longest string in pixels
	maxWidth=150;
	for (var i=0; i < items.length; i++) {
		ruler = document.getElementById("CBRuler");
		if (ruler){
			ruler.innerHTML = items[i].label;
			maxWidth = (maxWidth >= ruler.offsetWidth) ? maxWidth : ruler.offsetWidth;
			console.debug("label: "+items[i].label);
			console.debug("maxWidth: "+maxWidth);
		}
	}
	
	//small buffer for arrow button ~20px
	maxWidth+=20;
	
	return(maxWidth);
}


function getUserAgent() {
	// summary:
	//		Get the string that describes the browser
	// returns:
	//		A string that describes the browser
	//
  return navigator.userAgent;
}

//Single place to get the base location
function getBaseLocation(){
	if(executionEnv.isFile){ //File Protocol
		if(executionEnv.isaDevEnv){ //Deve Environment
			return "../../"; //File + Dev Env
		} else {
			return "../../"; //File + Production
		}
	}else { //HTTP
		if(executionEnv.isaDevEnv){  
			return "../../"; //http + dev Ent
		} else { //Production
			return "../../"; //http + production
		}
	}
}

function setAutoPDMenu(jsonAPD, licenseAccepted){	
	console.debug("setAutoPDMenu invoked from applet. "+jsonAPD);
	console.debug("license accepted parm is "+licenseAccepted);
	
    dojo.publish("SetLicenseInformation", [licenseAccepted]);	
	
    dojo.publish("SetAutoPDMenuJSON", [jsonAPD]);	
}

//Function to update the archive location for after collection
function setArchiveLocation(archiveLoc) {
	console.debug("Setting the archiveLocation from the applet.");
	
	var archiveJSON = {};
	archiveJSON.location = archiveLoc;
	dojo.publish("SetArchiveLocation", [dojo.toJson(archiveJSON)]);
}

function matchesLocale(candidate){
	//
	// Summary: Check if candidate locale is supported by given list
	//
	// Returns:
	//  true: if a match is found
	//  false: if no match is found.
	//
	//
	//Checks to see if the current locale on this browser 
	//is supported by this product.
	//If the current locale is not supported, will return false (English locale will be used)
	//fr or fr_FR will match to fr
	//User can only specify one of the followings:
	//
		var currentLocale=dojo.locale; //Could have length of 2 or a length of 5 (fr, fr_FR)
		var lowerCaseLocale=currentLocale.toLowerCase(); //Convert to lower case to ease comparison
		
		//candidate can only be one of the supported locales: 2 characters, except zh-cn, zh-tw and pt-BR
		var candidateLowerCase=dojo.trim(candidate.toLowerCase()); //Make sure to trim possible spaces
		
		//Print to validate
		console.debug("Current Locale: "+lowerCaseLocale + " candidate in lower case: " + candidateLowerCase);
		
		//Length of the selected locale.
		var localeLength=lowerCaseLocale.length;
				
		//Only language was specified (fr, de, it, ...)
		if(localeLength==2){ //Only the language was specified.
			return (lowerCaseLocale==candidateLowerCase);
		}else if(localeLength==5){ //5 characters
			if(lowerCaseLocale=="zh-cn" || lowerCaseLocale=="zh-tw" || lowerCaseLocale=="pt-br" ){ // In this case, the match has to be perfect
				if(lowerCaseLocale==candidateLowerCase) {
					return true;
				} else
					return false;
			}else { // Only select the first two characters and compare them to the supported ones
				var langLocale=lowerCaseLocale.substring(0,2);
				return (langLocale==candidateLowerCase);
			}
		}
		//Any other case
		return false	
}