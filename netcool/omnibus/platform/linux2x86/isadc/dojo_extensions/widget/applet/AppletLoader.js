/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.applet.AppletLoader");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dojo.io.script");
dojo.require("widgets.panel.InvalidPrereqsPanel");
dojo.require("widgets.panel.RuntimeErrorMessage");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.applet", "appletstrings");

dojo.declare("widgets.applet.AppletLoader", [dijit._Widget, dijit._Templated ], {
	// Path to the template
	templateString: dojo.cache("widgets", "applet/templates/AppletLoader.html"),

	//product Taxonomy
	productTaxonomy:'',

	//Version of the collector scripts.	
	collectorScriptsVersion:'',

	//Which protocol is being used? Defaults to File protocol
	execEnvIsFile:true,
	
	//Production or Development Environment? Defaults to production
	execEnvISADevEnv:false,

	//loadApplet: If true, load the applet right away. should always be false (for now)
	loadApplet:false,
		
	//Base Location
	baseLocation:'./',
	
	_javaJarLoc: 'lib/getJavaInfo.jar',
	
	_javaReqVersion: '1.6',
	
	autoPDMenuJSON: null,

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("Constructor for Applet Loader");
		this.appletCreationFailed=false;
		this.isaApplet=null;
		
		//This is the locale to pass to the backend.
		//Default to English. 
		this.supportedLocale="en"; //English is always supported.

		//This will be set to true, once the applet has successfully loaded.
		//Use this variable to check for a valid loaded applet.
		appletLoaded=false;
		
		//Set the base location (compare to the index.html location)
		this.baseLocation=getBaseLocation();
		//Load the PluginDetect script
		dojo.io.script.attach("pluginDetector", "../../js/PluginDetect.js");
		
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		//do the nls mixin here
		var _nlsResources=dojo.i18n.getLocalization("widgets.applet","appletstrings");
		
		dojo.mixin(this,_nlsResources);
				
		this.inherited(arguments);
	},
	
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		this.inherited("postCreate",arguments);
		
		dojo.subscribe("SetAutoPDMenuJSON", dojo.hitch(this,function(/*JSON Array*/ jsonArr){
	    	 console.debug("AppletLoader setAutoPDMenuJSON event subscription...");
	    	 this.setAutoPDMenuJSON(jsonArr);
              console.debug("JSON Argument: "+jsonArr);
	     }));
		
		//License was accepted: Report back to back end.
		dojo.subscribe("LicenseAcceptedByCustomer",dojo.hitch(this,function(item){
			//
			console.debug("The license term acceptance flag has been sent to the backend. ");
			this.licenseTermsAccepted();
		}));
		
	},
	//
    // Checks to ensure the pre-reqs are met prior to attempting to download the Applet
	_calculatePreReqs: function() {
		// summary:
		//		This method calculates the pre-reqs for this Applet
		//      If it is detected that this browser/JRE combination is not supported
		//      then a message will be displayed to point to the problem.
		//      An alternative will be given to the user on how to proceed.
		//      i.e.: is this is the standalone collector, the console will be given as alternative
		//      if this is the web collector, then the location to download the proper JRE will be given
		
		var validBrowserType=true; //supported browser type
		var validBrowserVersion=true; //Supported browser version
		var validBrowserPluginCombination=true; //Valid Browser/JRE combination
		var validJRE=true;
		var action="";
		var error="";
			
		if(dojo.isIE<7){ //IE 6 and lower
			var browserName="Internet Explorer ";
			var versionNumber=dojo.isIE;
			console.debug(" Browser " + browserName + " --- " + " Version: " + versionNumber);

			var map = new Object();
			map.browserName=browserName;
			map.versionNumber=versionNumber;
						
			validBrowserType=true;
			validBrowserVersion=false;

			//Substitute the variables ...
			error=dojo.string.substitute(this.unsupportedBrowserVersionDetected, map);
			
			//Various actions to take, if file of http
			if(this.execEnvIsFile){
				action=this.wrongIEBrowserFileVersionAction;							
			}else {
				action=this.wrongIEBrowserHTTPVersionAction;
			}
			
		}else if(dojo.isFF<=3.4){ //Firefox 3.4 and lower
			var browserName=" Firefox ";
			var versionNumber=dojo.isFF;
			console.debug(browserName+"---"+ " version: "+versionNumber);

			var map = new Object();
			map.browserName=browserName;
			map.versionNumber=versionNumber;

			//Validate the browser type and the browser number
			validBrowserType=true;
			validBrowserVersion=false;
			
			//Substitute the variables ...
			error=dojo.string.substitute(this.unsupportedBrowserVersionDetected, map);
			
			//Various actions to take, if file of http
			if(this.execEnvIsFile){
				action=this.wrongFFBrowserFileVersionAction;							
			}else {
				action=this.wrongFFBrowserHTTPVersionAction;
			}
		}else if(dojo.isSafari<5){//Safari 4 and lower		
			var browserName=" Safari ";
			var versionNumber=dojo.isSafari;

			console.debug(browserName+"---"+ " version: "+versionNumber);			
			
			var map = new Object();
			map.browserName=browserName;
			map.versionNumber=versionNumber;

			validBrowserType=true;
			validBrowserVersion=false;

			//Substitute the variables ...
			error=dojo.string.substitute(this.unsupportedBrowserVersionDetected, map);
			
			//Various actions to take, if file of http
			if(this.execEnvIsFile){
				action=this.wrongSafariBrowserFileVersionAction;							
			}else {
				action=this.wrongSafariBrowserHTTPVersionAction;
			}
		}else if(dojo.isChrome<10){//Chrome 9 and lower
			var browserName=" Chrome ";
			var versionNumber=dojo.isChrome;

			console.debug(browserName+"---"+ " version: "+versionNumber);			
			
			var map = new Object();
			map.browserName=browserName;
			map.versionNumber=versionNumber;

			validBrowserType=true;
			validBrowserVersion=false;

			//Substitute the variables ...
			error=dojo.string.substitute(this.unsupportedBrowserVersionDetected, map);
			
			//Various actions to take, if file of http
			if(this.execEnvIsFile){
				action=this.wrongChromeBrowserFileVersionAction;							
			}else {
				action=this.wrongChromeBrowserHTTPVersionAction;
			}
		}else if(dojo.isOpera<11){ //11+ is Tier 2 > not tested extensively
			validBrowserType=false;
			console.debug("Opera Browser version: "+dojo.isOpera);
			error= this.unsupportedBrowserVersionDetected;
			if(this.execEnvIsFile){
				action=this.wrongFFBrowserFileVersionAction;							
			}else {
				action=this.wrongFFBrowserHTTPVersionAction;
			}
		}else {
			//Good versions of Firefox, IE or Safari
			if(dojo.isFF || dojo.isIE || dojo.isSafari || dojo.isChrome || dojo.isOpera){ //Valid versions of Chrome, Firefox, IE and Safari
				validBrowserType=true;
				validBrowser=true;

				//setup the appletDiv
				dojo.style(dojo.byId("appletDiv"), {width:"300px", margin:"100px auto 0px"});
				//show the loading screen
				dojo.byId("appletDiv").innerHTML = "<div style='text-align:center; margin-top:225px;'>"+this.loadingAppletLabel+"<div>";
				
				//Check for valid JRE here
				PluginDetect.getVersion(".");
				var JavaVersion = PluginDetect.getVersion('Java', this._javaJarLoc);
				var JavaStatus = PluginDetect.isMinVersion('Java', this._javaReqVersion, this._javaJarLoc);
				console.debug('Java version is ' + JavaVersion + ' (min is ' + this._javaReqVersion + ')\n' + 'Java status is ' + JavaStatus);

				if (JavaVersion==null || JavaStatus==null) {//if Java is not available
					validJRE=false;
					//Substitute the variables ...
					error=this.appletRequiresJava; //No JRE Present
					action=this.appletRequiresJavaVersionOrBetterAction;
					action = action + "<br />" + this.appletRequiresJavaVersionOrBetterAdditional;
					
				}
				else if (JavaStatus==-1) {//If Java is less then minimum requirement
					validJRE=false;
					
					var map = new Object();
					map.JavaVersion=JavaVersion;

					//Substitute the variables ...
					error=dojo.string.substitute(this.appletRequiresJavaVersionOrBetter, map);//Invalid JRE version
					action=this.appletRequiresJavaVersionOrBetterAction;
					action = action + "<br />" + this.appletRequiresJavaVersionOrBetterAdditional;
				}
				else if (JavaStatus==-0.2) {//If Java appears disabled (ex. in FF), manually check the version
					var javaVersionManual = JavaVersion.split("."); //User's Java version
					var javaVersionMain = this._javaReqVersion.split("."); //Minimum requirement
					
					var javaVersionIsGreater = true;
					
					for (var i in javaVersionMain) {
						if (javaVersionManual[i] < javaVersionMain[i]) {
							javaVersionIsGreater = false;
							break; //User's version is less then required
						}
						else if (javaVersionManual[i] > javaVersionMain[i]) {
							break; //User's version is better
						}
					}
					
					if (!javaVersionIsGreater) {
						validJRE=false;
						var map = new Object();
						map.JavaVersion=JavaVersion;

						//Substitute the variables ...
						error=dojo.string.substitute(this.appletRequiresJavaVersionOrBetter, map);//Invalid JRE version
						action=this.appletRequiresJavaVersionOrBetterAction;
						action = action + "<br />" + this.appletRequiresJavaVersionOrBetterAdditional;
					}
				}
				
			}else { //No match found, unknown browser
			  console.debug("Unknown browser type -- not supported: ..." + dojo.isChrome);
			  validBrowserType=false;			
			  error= this.unsupportedBrowserDetected;
			
			  if(this.execEnvIsFile){
				action=this.unsupportedBrowserFileAction;							
			  }else {
				action=this.unsupportedBrowserHTTPAction;
			  }
			}
		}
		
		//Set validBrowser boolean variable if either the type is wrong or the version is wrong .
		if(!validBrowserType || !validBrowserVersion){
			validBrowser=false;
		}else
			validBrowser=true;
		
		//Check for BrowserPlugin combination here:
		
		return {"validBrowser":validBrowser,
			    "validJRE":validJRE,
			    "validBrowserPluginCombination":validBrowserPluginCombination,
			    "actionMessage":action,
			    "errorMessage":error};
	},
	//
	setProductTaxonomy: function(/** */productID){
		//
		//Sets the product Taxonomy
		//
		this.productTaxonomy=productID;
	},
	//
	setCollectorScriptsVersion: function(/** */collectorScriptsVersion){
		//
		//Sets the product Version
		//
		this.collectorScriptsVersion=collectorScriptsVersion;
	},
	//
	//
	getBaseLocation: function(){
		return this.baseLocation;
	},
	// 
	// It also ensures that the right panels is being shown on the UI, while the applet is loading
	uploadApplet: function() {
		// summary:
		//		This method initiates the loading of the Applet
		//      It also ensure that the proper panels and messages are being shown, while the applet is loading. 
		//      The name of the Web Collector being loaded will also be shown.
		//      The progress bar is also shown, however its status is not progressing, since there is no way to know
		//      when it will end.

		//First, calculate the pre-reqs
	     var preReqs = this._calculatePreReqs();
	     
	     //If something is wrong with the pre-reqs, display a message
	     if((!preReqs.validBrowser) || (!preReqs.validJRE) | (!preReqs.validBrowserPluginCombination)){
		     var errorMessage = new widgets.panel.InvalidPrereqsPanel({
		    	 validBrowser:preReqs.validBrowser,
		    	 validJRE:preReqs.validJRE,
		    	 validCombination:preReqs.validBrowserPluginCombination,
		    	 error: preReqs.errorMessage,
		    	 action:preReqs.actionMessage
		     },dojo.byId("invalidPrereqsDiv"));
		     dojo.byId("appletDiv").innerHTML="";
		     
		     this.appletLoaded=false;
			//Remove the applet Loaded View, if one is present.
//			if(dojo.byId("loadingTextAndProgressBarDiv"))
//					dojo.byId("loadingTextAndProgressBarDiv").parentNode.removeChild(dojo.byId("loadingTextAndProgressBarDiv"));	
		    errorMessage.showInvalidPanel();
		    return;
	     }
	     
	      //All the pre-reqs are met. Now, try to load the applet.
//	      var appletLoadingMessage=this.appletLoadingMessage;		 
	      this.loadApplet=true;
//	      var loadingText=appletLoadingMessage;
//	      dojo.byId("appletLoadingText").innerHTML="<h1>"+ loadingText + "</h1>";
	      
//	      //Display the progress bar
//	      var pg = new dijit.ProgressBar({
//	    	   maximum:50,
//	    	   annotate:true,
//	    	   indeterminate:true},dojo.byId("appletProgressBar"));
//	 
	       
	      //Calculate the URL for the jars on the applet			
	      var appletJarsURL= this._getJarsURL();
			
	      //Create the Applet Object and load the applet into the application
	      this.createProductionApplet(appletJarsURL);
	      
	      //Something went wrong during the creation of the applet.
	      if(this.appletCreationFailed){ //Something went wrong during the creation of the applet.
	    	   //Create an error here ...
				//Remove the applet Loaded View, if one is present.
				if(dojo.byId("appletLoadingView"))
					dojo.byId("appletLoadingView").parentNode.removeChild(dojo.byId("appletLoadingView"));				

		    	var failAppletCreationMessage=this.failAppletCreationMessage;
		    	var failAppletCreationAction=this.failAppletCreationAction;

				var errorMessage = new widgets.panel.RuntimeErrorMessage({
					actionMessage:failAppletCreationMessage,
					errorMessage:failAppletCreationAction,
					reloadButton:true
			      },dojo.byId("runtimeDialogDiv"));
				    	  
	    	  return ;
	       }
	      
	      //ISAApplet is null?
	      if(this.isaApplet==null){
				//Remove the applet Loaded View, if one is present.
	    	   var nullAppletMessage=this.nullAppletMessage;
	    	   var nullAppletAction=this.nullAppletAction;

				if(dojo.byId("appletLoadingView"))
					dojo.byId("appletLoadingView").parentNode.removeChild(dojo.byId("appletLoadingView"));				
							
				var errorMessage = new widgets.panel.RuntimeErrorMessage({
					actionMessage:nullAppletAction,
					errorMessage:nullAppletMessage,			 
					reloadButton:true
			      },dojo.byId("runtimeDialogDiv"));
				    	  
	    	  return;
	      }
	      
 	      // Applet was created, and might have loaded, but not completely
	       if(!this._isValidApplet()){ 
	    	   var invalidAppletMessage=this.invalidAppletMessage;
	    	   
	    	   //Action to take differs, depending on protocol.
	    	   var invalidAppletAction=this.invalidAppletActionFile;
	    	   
	    	   if(!this.execEnvIsFile) {
	    	     invalidAppletAction=this.invalidAppletActionHTTP; //using HTTP Protocol
	    	   }
	    	   
	    	   console.debug("This is not a valid applet, continue ...");
				//Remove the applet Loaded View, if one is present.
//				if(dojo.byId("loadingTextAndProgressBarDiv"))
//					dojo.byId("loadingTextAndProgressBarDiv").parentNode.removeChild(dojo.byId("loadingTextAndProgressBarDiv"));				
							
				var errorMessage = new widgets.panel.RuntimeErrorMessage({
					actionMessage:invalidAppletAction, 
					errorMessage:invalidAppletMessage,			 
					reloadButton:true
			      },dojo.byId("runtimeDialogDiv"));
			
	              return ;
	       }
	       this.appletLoaded=true;
	       
	       //Hide the appletDiv from the screen
	       dojo.style("appletDiv", {height:"1px", width:"1px", visibility:"hidden", marginTop:"0px"});
	       
	       //Need to reset the height of the appletloadingview to keep screen size the same
	       dojo.style("appletLoadingView", {height:"490px"});
	       
	},
	//Calculates the JARS URL for a given product. This function might need to be moved
	//to another class that encapsulates a Product. Each product has to calculate the JARs it needs to run with
	_getJarsURL: function(){
		// summary:
		//		This method calculates the Jars files needed to successfully load the Applet for a given product and a given protocol
		// 
		//      It will a well formatted (comma separated) list of jars, that will be passed to the Applet creation routine
		//		Depending on the protocol selected (http, file) and depending on the execution environment ( Production or Development)
		//      the jar file will be calculated in a different way.
		//
		//      The return value is a JSON formatted object with the following variable:
		//      libJars: List of all Jars
		//      coreRelPath: Additional core file that needs to be passed 
		//      deltaRelPath: Addtional Product specific file that needs to be passed

		console.debug("Calculating the JARs URL for the Applet.");
		
		var libJars='';				 
		var productDeltaRelPath='';
		var coreRelPath='';
		
		//First, read the product JSON file
		var productJson=readProductJSON({
			"taxonomy":this.productTaxonomy,
			"collectorScriptsVersion":this.collectorScriptsVersion,
			"baseLocation":this.getBaseLocation()
			});
		
		//Retrieve the product specific supported Locale information
		 if(productJson && productJson!=null) {
			 var allSupportedLocales=productJson.supportedLocales; //These are the locales supported by this product
			 //console.debug("Default specified locale: "+this.supportedLocale);
			 console.debug("Supported Locales for this product: "+allSupportedLocales);
			 var currentLocale=dojo.locale; //Locale according to dojo
			 
			  var itemL=allSupportedLocales.split(",");
				for(var uu=0; uu<itemL.length;uu++){
				 var langCandidate=dojo.trim(itemL[uu].replace("_","-"));
				  console.debug(" Compare supported locale: "+langCandidate + " to current locale (dojo.locale): "+currentLocale);
				  if(matchesLocale(langCandidate)){
					  this.supportedLocale=langCandidate; // returns one of the locale specified.
					  console.debug("Match found. ");
					  break;
				  }
				}
				
			console.debug("After Locale Validation: Supported Locale: "+this.supportedLocale);
		 }
		 
		 //Retrieve the list of JARS to be on the path 
		//If Development Environment is being used
		if(this.execEnvISADevEnv){
			console.debug("Using the development Environment ");
						
			if(this.execEnvIsFile){ //Using the file protocol
				console.debug("Using the File protocol in the dev. environment");
			    if(productJson && productJson!=null) {
			         //Then find the appropriate core JSON file and read it
			         var coreJson = readCoreJSON(productJson,this.getBaseLocation());
			 
			         //Locate the core libraries and remember their path
			         var coreLibJars = coreJson.libjars;
						
					 var normalizedCoreLibJars=this._normalizeJarPaths(coreLibJars,this.getBaseLocation());
					 console.debug("Normalized CoreLibJars: "+normalizedCoreLibJars);

			         //Any product specific libraries?
			         var productLibJars=productJson.libJarsURL;
			 
			         //Append the path of the product libs
			         // lib1,lib2,lib3 ==> prepend/lib1,prepend/lib2,prepend/lib3
			         if(productLibJars && productLibJars!=''){
				    	 var normalizedProductLibRelPath=this._normalizeJarPaths(productLibJars, this.getBaseLocation());
						libJars=normalizedCoreLibJars+","+normalizedProductLibRelPath;   //add to the core.
			         }
			    }
			} else { //Using the http protocol
				console.debug("Using the http protocol in the dev environment");
				var coreJson = readCoreJSON(productJson,this.getBaseLocation());
					 
				//Locate the core libraries and remember their path
				var coreLibJars = coreJson.libjars;
				console.debug("CoreLibJars: "+coreLibJars);
				
				var normalizedCoreLibJars=this._normalizeJarPaths(coreLibJars,this.getBaseLocation());
				console.debug("Normalized CoreLibJars: "+normalizedCoreLibJars);
				
				 //Any product specific libraries?
				var productLibJars=productJson.libJarsURL;
				 
		         //Append the path of the product libs
		         // lib1,lib2,lib3 ==> prepend/lib1,prepend/lib2,prepend/lib3
			     if(productLibJars && productLibJars!=''){
			    	 var normalizedProductLibRelPath=this._normalizeJarPaths(productLibJars, this.getBaseLocation());
					libJars=normalizedCoreLibJars+","+normalizedProductLibRelPath;   //add to the core.
				}
				var mainCoreJar="lib/isaCore_"+productJson.isaCoreBuildId+".zip";
				coreRelPath=this._normalizeJarPaths(mainCoreJar, this.getBaseLocation());
					
				//Calculate the relative path for the product Jar file
				productDeltaRelPath=this._normalizeJarPaths(productJson.productDeltas, this.getBaseLocation());	
			  }
			}  else { //Using the Production Environment
		     if(this.execEnvIsFile){ 		//File protocol
			   console.debug("Using the File protocol in production");
			   this.collectorScriptsVersion = productJson.version;
			   console.debug("product version is " + this.collectorScriptsVersion);
		       if(productJson && productJson!=null) {
		         //Then find the appropriate core JSON file and read it
		         var coreJson = readCoreJSON(productJson, this.getBaseLocation());
		 
		         //Locate the core libraries and remember their path
		         var coreLibJars = coreJson.libjars;
				
				 var normalizedCoreLibJars=this._normalizeJarPaths(coreLibJars,this.getBaseLocation());
				 console.debug("Normalized CoreLibJars: "+normalizedCoreLibJars);

		         //Any product specific libraries?
		         var productLibJars=productJson.libJarsURL;
		 
		         //Append the path of the product libs
		         if(productLibJars && productLibJars!=''){
			    	 var normalizedProductLibRelPath=this._normalizeJarPaths(productLibJars, this.getBaseLocation());
						libJars=normalizedCoreLibJars+","+normalizedProductLibRelPath;   //add to the core.
		         }
		       }
		   }else {//http protocol
			  console.debug("Using http protocol in production");
			   //Then find the appropriate core JSON file and read it
			   var coreJson = readCoreJSON(productJson, this.getBaseLocation());
			 
			   //Locate the core libraries and remember their path
			   var coreLibJars = coreJson.libjars;

			   var normalizedCoreLibJars=this._normalizeJarPaths(coreLibJars,this.getBaseLocation());
			   console.debug("Normalized CoreLibJars: "+normalizedCoreLibJars);

			   //
			   var productLibJars=productJson.libJarsURL;
			 
			   //Append the path of the product libs
			   //Calculate the productLibJars location
			   if(productLibJars && productLibJars!=''){
				   var baseLibPath=this.getBaseLocation()+"../../../products/"+this.productTaxonomy+"/"+this.collectorScriptsVersion+"/"; // will be prepended to each part			
				   var normalizedProductLibRelPath=this._normalizeJarPaths(productLibJars, baseLibPath);
				   
				   libJars=normalizedCoreLibJars+","+normalizedProductLibRelPath;			 
			   }

			   var coreVersion=productJson.isaCoreBuildId;

		       //Calculate relative Path for the Core Jar file
			   var corePathPrepend=this.getBaseLocation()+"../../../isacommon/"+coreVersion+"/";
			   coreRelPath=this._normalizeJarPaths("isaCore_"+productJson.isaCoreBuildId+".zip",corePathPrepend);
			
			   //Calculate the relative path for the product Jar file
			   var deltaPathPrepend=this.getBaseLocation()+"../../../products/"+this.productTaxonomy+"/"+this.collectorScriptsVersion+"/";
			   productDeltaRelPath=this._normalizeJarPaths(productJson.productDeltas,deltaPathPrepend);			    
		  }
		}

		console.debug("libjars: "+libJars);
	    console.debug("coreRelPath: "+coreRelPath);
	    console.debug("productDeltaRelPath: "+productDeltaRelPath);

		return {"libJars":libJars,"coreRelPath":coreRelPath,"productDeltaPath":productDeltaRelPath};
	},
	//
	// Update the path based to carry the relative location (relative to the location of index.html)
	//
	_normalizeJarPaths: function(listOfJars, prepend) {
		console.debug("Normalizing "+listOfJars + " with "+prepend);
		//remove trailing ',' if present
		var lastIndex = listOfJars.lastIndexOf(',');
		if((lastIndex!=-1) && (lastIndex + 1 == listOfJars.length)){
			listOfJars=listOfJars.substring(0,listOfJars.length-1);
		}
		
		var listOfNormalizedJars="";
		var libraryParts = listOfJars.split(",");
		
		for(var i=0; i<libraryParts.length;i++){
		    var fullPathWithBase=prepend+libraryParts[i]; //prepend the base to each part.
			   listOfNormalizedJars+=fullPathWithBase;
			       if(i<(libraryParts.length-1)) //add a ',' to seperate individual instances
			    	   listOfNormalizedJars+=",";
		   } //end of splitting ...
		console.debug("Result of normalization: "+listOfNormalizedJars);
		return listOfNormalizedJars;
	},
	//Checks to see if the applet was successfully created
	//
	appletCreated: function() {
		// summary:
		//		This method should be called to know if the Applet has been successfully created and loaded
		// 
		//      It will return false, if the Applet has not been successfully created and loaded
		//		It will return true, if the Applet has been successfully created and loaded

      return this.appletLoaded;
	},    
	//
	//
	createProductionApplet: function(/*JSON object */urls) {
		// summary:
		//		This method puts together all the parameters passed for the successfull creation of an Applet
		//     urls represents the parameters needed for the creation of the applet.
		//     urls.libJars: represents all the JARS that go on the classpath for the applet creation
		//     urls.coreRelPath:
		//     urls.productDeltaPath:
		//
		//       If an applet was successfully created, then isaApplet is not null.
		var jarsURL=urls.libJars;
		var isaCoreRelPath=urls.coreRelPath; 
		var productDeltaRelPath=urls.productDeltaPath; 
		var ui_locale=this._calculateLocale();
		
		var appletDiv=parent.document.getElementById("appletDiv");

		var appletID=null;
		
		if (this.execEnvIsFile) {			
			console.debug("Creating Applet in the file protocol ... using JarsURL:" + jarsURL);
			appletID=this.createApplet("com.ibm.isa.web.collector.applets.ISAApplet.class",
					                        [ ["ui_locale", ui_locale ]], 
					                        appletDiv,
					                        jarsURL);
		}	else { //http protocol
			console.debug("Creating Applet using the http protocol ...");
		    var locationOfFile=location.pathname;
		    var hostName=location.hostname;
		    var portNumber=location.port;
		    
		    if(portNumber=='')
		    	portNumber='';
		    else
		    	portNumber=":"+portNumber;
		    
		    var index1=locationOfFile.lastIndexOf("/");
		    var calculatedLocation="http://"+hostName+portNumber+locationOfFile.substring(0, index1)+"/";
		    
	 	    var isaCoreLocation=calculatedLocation+isaCoreRelPath;
	 	    var productLocation=calculatedLocation+productDeltaRelPath;	 	    

	 	    console.debug("Libraries to load Core Jars: "+jarsURL);
		    console.debug("Libraries to load Core: "+isaCoreLocation);
		    console.debug("Libraries to load Product: "+productLocation);
		    
		    
		    appletID=this.createApplet("com.ibm.isa.web.collector.applets.ISAApplet.class", 
				[ ["isaCoreURL", isaCoreLocation ], ["productDeltaURL", productLocation ],["ui_locale", ui_locale ] ], appletDiv,jarsURL);			
				
		}
		if(appletID==null || (typeof appletID=='undefined')){
			this.appletCreationFailed=true;
			console.debug(" appletID is null or appletID is undefined. Something went wrong during creation of the applet. ");
		}else
		  this.isaApplet=parent.document.getElementById(appletID);
	},
	// 
	// Method for the creation of the applet
	createApplet: function(code,params,container,url){
		// summary:
		//	   This method is used to start the Applet.
		//       Cross Browser Applet creation method
		//       param code
		//       param params
		//       param container
		//       param url
		//
		//      returns The ID of the created Applet
		//
		try {
			console.debug("Starting Applet: "+code);
			dojo.style(container, {width:"300px", margin:"100px auto 0px"});
			var codebase = "http://java.sun.com/update/1.6.0/jinstall-6u26-windows-i586.cab";
			var classID="clsid:CAFEEFAC-0016-0000-0000-ABCDEFFEDCBA";
			var type = "application/x-java-applet;version=1.6";
			var style = "width:300px;height:300px;";
			var id = Math.random();
			console.debug("Style="+style);
			if (dojo.isIE){
				var applet = '<object CODEBASE="'+codebase+'" CLASSID="'+classID+'" style="'+style+'" id="'+id+'">';
				applet +='<param name="code" value="'+code+'"/>';
				applet +='<param name="archive" value="'+url+'"/>';
				applet +='<param name="MAYSCRIPT" value="true" />';
				applet +='<param name="scriptable" value="true" />';
				applet +='<param name="java_arguments" value="-Djnlp.packEnabled=true"/>';
				applet +='<param name="applet_stop_timeout" value="5000/">';
				applet +='<param name="productTaxonomy" value="'+this.productTaxonomy+'">';
				applet +='<param name="productVersion" value="'+this.collectorScriptsVersion+'">';
				dojo.forEach(params, function (param){
					var key = param[0];
					var value = param [1];
					applet +='<param name="'+key+'" value="'+value+'"/>';
				});
				applet +='<comment>';
				applet +=this.appletRequiresJavaVersionOrBetter;
				applet +='</comment>';
				applet +='</object>';
				container.innerHTML=applet;
				//dojo.style(container, {visibility:"hidden", height:"1px", width:"1px"});
				return id;		
			}
			else {
				var applet ='<embed id="'+id+'" style="'+style+'" MAYSCRIPT=true code="'+code
				           +'" java_arguments=\"-Djnlp.packEnabled=true\" applet_stop_timeout=\"5000\" productTaxonomy="'+this.productTaxonomy+'" productVersion="'+this.collectorScriptsVersion+'"  archive="'+url
				           +'" pluginpage="https://www.ibm.com/developerworks/java/jdk/" type="'+type+'" '+'alt='+this.altText;
				dojo.forEach(params, function (param){
					var key = param[0];
					var value = param [1];
					applet +=' '+key+'="'+value+'" ';
				});
				applet +='>';
				applet +='<noembed>';
				applet +=this.appletRequiresJavaVersionOrBetter;
				applet +='</noembed>';
				applet +='</embed>';			
				container.innerHTML=applet;
				//dojo.style(container, {visibility:"hidden", height:"1px", width:"1px"});
				return id;
			}
		} catch (e) {
			this.appletCreationFailed=true;
			console.error("AppletLoader.createApplet: "+e.message);
		}
	},
	//
	//Method to retrieve autopdMenuJSON
	getAutoPDMenuJSON: function(){
		// summary:
		//		This method retrieves the autopdJSON file from the Applet.
		// 
		return this.autoPDMenuJSON;
	},
	
	//
	//Method to set the autopdMenuJSON from the applet
	setAutoPDMenuJSON: function(/*JSON*/ autoPDMenuJSON){
		// summary:
		//		This method retrieves the autopdJSON file from the Applet.
		//
		this.autoPDMenuJSON = autoPDMenuJSON;
	},
	//
	//
	//Starts the Data Collection on the Applet
	startCollection: function(/*JSON */collectionParams){  	          
		// summary:
		//		This method starts the Data Collection by calling the Applet StartCollection function
		// 
		//     collectionParams: These are the parameters needed to start the Data Collection
		//		
		try {		        
				 this.isaApplet.startCollection(
						collectionParams.link,
						null, 
						collectionParams.problemKeyValue, 
						collectionParams.scriptLabel,
						this._getURLAsJSON());
		}catch(e){
          console.debug("There was a problem starting the Data Collection: "+e);			
		}
	},
	//
	//Submits the response to the backend.
	submitResponse: function(/* */response){
		// summary:
		//		This method submits the response of data entered in the inputdialog to the backend
		// 
		this.isaApplet.submitResponse(response);
	},
	//
	//indicate that license was accepted
	licenseTermsAccepted: function(){
		// summary:
		//		This method indicates that the user accpeted the license terms
		// 
		this.isaApplet.licenseTermsAccepted();
	},
	//
	//Returns the isaApplet object, if one has been created. 
	getISAApplet: function(){
		return this.isaApplet;
	},
	//
	// Calculates, if the current Data collection supports the appropriate locale
	// 
	//
	_calculateLocale: function(){
		//
		//Summary: Checks if the current locale is supported by the given Data Collection.
		//
		return this.supportedLocale; //Defaults to English Locale
	},
	//
	//
	_isValidApplet: function() {
		//
		// summary: checks to see if the current applet is valid.
		//    This will be run prior to calling anything on the applet. 
		//    If it is not valid, then a runtimeError will be displayed and the application will end.
		//		
		if(dojo.isIE){ //IE handles it differently
			var validApplet=true;			
			try {
				console.debug("typeof this.isaApplet.isAlive() =" + (typeof this.isaApplet.isAlive())); //isAlive() is a method on the applet.
			}catch(e){
				console.debug("Error occured checking if applet is alive: typeof this.isaApplet.isAlive() ===>  "+e);
				validApplet=false;
			}
			
			return validApplet;
		}else {
	   		console.debug("typeof this.isaApplet.isAlive =" + (typeof this.isaApplet.isAlive)); //isAlive() is a method on the applet.
			if(typeof this.isaApplet.isAlive=='function') {
				console.debug(" Method this.isaApplet.isAlive does exist on the applet ...");				
				return true;
			} else {
			  console.debug(" Method this.isaApplet.isAlive doesn't exist on the applet, can't continue ...");
			  this.appletLoaded=false;
			  return false;
		  }
		}
	},
	//
	//
	appletIsAlive: function(){
		//
		//summary: this method is used to check if the applet is still alive
		//
		
		return this.isaApplet.isAlive();
	},
	//
	//
	_getURLAsJSON: function(){
		//
		//summary: converts the URL information to JSON object
		//

		//The following shows the conversion for the parameters
		//?developmentEnv=true&pmr=999,99,99&product=SSEQTP --> param=developmentEnv,value1=true&
		//                                                      param=pmr,value2=99900,99,999 &
		//                                                      param=product,value3=SSEQTP
		var hostname=location.hostname;
		var pathname=location.pathname;
		var queryParams=location.search;
		
		var protocol="http";
		
		if(this.execEnvIsFile)
			protocol="file";
		
		console.debug(" Hostname:"+hostname +
				      "\n QueryParams:"+queryParams + "\n Pathname:"+pathname );
		
		//gather information about file protocol and host name and path name
		var temp0="protocol="+protocol + "&hostname="+hostname+"&pathname="+pathname;
		var queryObjectTemp0=dojo.queryToObject(temp0);
		var l=dojo.toJson(queryObjectTemp0);
		var finalJSON=l.substring(0,l.length-1) + ',"queryParams":[';
		
		var paramsTokens=queryParams.replace("?","").split("&"); //removes the '?' in front of the queryparams

		//Convert the parameters into tokens
		for(var i=0;i<paramsTokens.length;i++){
			var token=paramsTokens[i];
			
			var corrected=token.replace("=","&value="); //replace = with &value
			var expanded="param="+corrected; //prepend param to the first one
			
			var partialJSON=dojo.toJson(dojo.queryToObject(expanded));
			
			finalJSON+=partialJSON;
			if(i!=(paramsTokens.length-1)) finalJSON+=",";
		}
		finalJSON+="]}";
		//console.debug("Final JSON: "+finalJSON);
						
		return finalJSON;
	},
	//
	// The ISA Version String
	//
	getISAVersion: function() {
		//
		//summary: this will return the ISA Version in JSON format
		//
		return this.isaApplet.getISAVersion();
		
	},
	//
	//
	_getSupportedLocales: function(){
		//
		// Returns the list of supported Locales
		//
		return this.supportedLocale;
	},
	//Uploads the data collection
	uploadRequest: function(/*JSON */ formJSON){  	          
		// summary:
		//		This method starts transfering the data collection archive base on user selected variables
		// 
		//     formJSON: These are the parameters needed to transfer the collection archive
		//

		try {
			console.debug("formJSON: " + formJSON);
			return this.isaApplet.uploadRequest(formJSON);
		}catch(e){
			var statusJSON = {};
			statusJSON.progress = "100";
			statusJSON.collectionStatus = {};
			statusJSON.collectionStatus.completionStatus = "ERROR";
			statusJSON.collectionStatus.collectionFailure = true;
			statusJSON.collectionStatus.canceled = false;
			statusJSON.collectionStatus.collectionErrorMsg = this.failAppletUpload;
			
		    dojo.publish("UploadCompleted", [dojo.toJson(statusJSON)]);
		    console.debug("There was a problem transfering the collection archive: "+e);
		}
	},
	//Cancels current upload based on identifier
	cancelUploadRequest: function(/* String */ identifier) {
		console.debug("Canceling the upload: " + identifier);
		this.isaApplet.cancelUploadRequest(identifier);
	}
});