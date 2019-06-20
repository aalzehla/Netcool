/**
 * This file contains information to read productJSON file and coreJSON files from disk to determine
 * product information (if not already passed) and/or paths if necessary
 * @param productInfo
 * @returns {String}
 */

// dojo.require the necessary dijit hierarchy
dojo.require("dojo.parser");
dojo.require("widgets.view.ExecutionModeSelection");	
dojo.require("widgets.view.CollectionExecution");


function readProductJSON(/*JSON object */ productInfo){
	//	summary: 
	//		this function is designed to be called by dojo.addOnLoad to 
	//		initialize JavaScript on a page

	var productFile='';
	var prodInfoFile='';
	var baseLocation=productInfo.baseLocation;
	
	if(executionEnv.isaDevEnv){//Development Environment
		if(executionEnv.isFile){ //File protocol in the Dev. Environment
			prodInfoFile=baseLocation+"services/devEnvProdInfoFile.json"; //In the development Environment, we read this file
		} else {
		    prodInfoFile=baseLocation+"services/"+productInfo.taxonomy+"/"+productInfo.collectorScriptsVersion+"/devEnvProdInfoHttp.json"; //In the development Environment, we read this file
		}
	} else { //Production Environment
	  if(!executionEnv.isFile){ //http protocol
	    console.debug("Taxonomy: "+productInfo.taxonomy + " Product Version: " +productInfo.collectorScriptsVersion);
	    prodInfoFile=baseLocation+"../../../products/"+productInfo.taxonomy+"/"+productInfo.collectorScriptsVersion+"/prodinfo.json";		
	 } else { //file protocol	    
	    prodInfoFile=baseLocation+"properties/prodinfo.json";
	  } 
	}
	
	console.debug("Reading file: "+prodInfoFile);
	
	try {		
		var deferred=dojo.xhrGet({
			url:prodInfoFile,
			handleAs:"json",
			preventCache:true,
			sync:true,
			load: function(response){
				console.debug("The product JSON file loaded successfully. from "+prodInfoFile);
				productFile=response;
			}, 
			error: function(response){
				console.debug(" There was an error loading the product JSON file from location: "+prodInfoFile + ". Error message=" +response);
			}
		});
	}catch(e){
		console.debug("An exception was thrown while reading the prodinfo.json file from location: "+prodInfoFile);		
	  }
	
	return productFile;
	}
	
	
		
	function readCoreJSON(/* */productFile, baseLocation){
		//
		//
		var coreFile='';
		var coreFileResponse='';
		console.debug("Reading core json file: "+executionEnv.isFile);
		
		//This is needed to allow Development Environment work
		if(executionEnv.isaDevEnv){
			if(executionEnv.isFile){ //File protocol in the Dev. Environment
				coreFile=baseLocation+"services/devEnvISACoreFile.json"; //In the development Environment, we read this file
			} else {
			    coreFile=baseLocation+"services/"+productFile.taxonomy+"/"+productFile.version+"/devEnvISACoreHttp.json"; //In the development Environment, we read this file
			}
		} else {//In production
		
		  if(executionEnv.isFile){ //file protocol
			console.debug("productFile: "+productFile.isaCoreBuildId);
			var coreVersion=productFile.isaCoreBuildId;
			coreFile=baseLocation+"properties/isacore_"+coreVersion+".json";
		  }else { //http protocol
			console.debug("Core Build ID="+productFile.isaCoreBuildId);
			var coreVersion=productFile.isaCoreBuildId;

			coreFile=baseLocation+"../../../isacommon/"+coreVersion+"/isacore_"+coreVersion+".json";
			console.debug("CoreFile "+coreFile);
		  }
		}
		
		try {		
			var deferred=dojo.xhrGet({
				url:coreFile,
				handleAs:"json",
				preventCache:true,
				sync:true,
				load: function(response){
					console.debug("loading core.json worked "+response);
					coreFileResponse=response;
				}, 
				error: function(response){
					console.debug(" Error reading core json file");
				}
			});
		}catch(e){
			console.debug("An error happened while reading the coreinfo.json file"+coreFile);
			
		}
		return coreFileResponse;
		}