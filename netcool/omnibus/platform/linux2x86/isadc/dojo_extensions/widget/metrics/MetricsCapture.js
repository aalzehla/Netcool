/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.metrics.MetricsCapture");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");

//Internationalization
dojo.require("dojo.i18n");
dojo.requireLocalization("widgets.metrics", "metricsstrings");

dojo.declare("widgets.metrics.MetricsCapture", [dijit._Widget], {

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : false,
	
	//The PMR Number for this collection
	pmr:'',
		
	//The componentID for this collection
	componentID:'',
	
	//The Product ID for this collection
	productID:'',
	
	//productID Version. This is the version associated with the product ID (i.e.  WebSphere 8.5, this will be 8.5) 
	productIDVersion:'',
	
	//The version of the scripts used. (i.e.: SystemCollector version 2.0.1)
	collectorScriptsVersion:'',
	
	//The Component Release
	compRelease:'',
	
	//Which protocol is being used? Defaults to File protocol
	execEnvIsFile:true,
	
	//Production or Development Environment? Defaults to production
	execEnvISADevEnv:false,
	
	//Product Taxonomy
	taxonomy:'',
	
	
	//Collection started
	collectionStarted:false,
	
	//Collection abandoned
	collectionAbandoned:false,
	
	//Collection run status
	completionSuccess: false,

	//Collection was canceled by the user
	completionCanceled: false,

	//Collection r
	completionFailure:false,
		
	//File Downloaded
	fileDownloaded:false,
	
	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("Constructor for MetricsCapture ");
		
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		
		//Point to the applet NLS Strings
		var _nlsResources=dojo.i18n.getLocalization("widgets.metrics","metricsstrings");

		dojo.mixin(this,_nlsResources);
		this.inherited(arguments);
	},
	
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		this.inherited("postCreate",arguments);

		//This will only be enabled, when we are in production.
		if(!(this.execEnvISADevEnv || this.execEnvIsFile)){	    	 
		//if(true){ //TODO: Remove me
		//This widget subscribes to events needed to capture and report metrics information
		
		//Capture metrics on collection start-up
	     dojo.subscribe("collectionStartedWithScript", dojo.hitch(this,function(item){
	    	 console.debug("Collection Started event subscription... ");
	    	 
	    	 this._resetAllVariables();
	    	 //sets collectionStarted flag
	    	 this.collectionStarted=true;
	    	 var scriptId=item.scriptId;
	    	 console.debug("scriptID: "+scriptId);
	    	 
	    	 var ev="collectionStarted="+this.collectionStarted + " scriptId="+scriptId;
	    	 console.debug("ibmStats String="+ev);
	    	 
	 		 ibmStats.event({
					"ibmEV":"pop-up",
					"ibmEvAction":"Open",
					"ibmEvGroup":this.ibmEventGroup,
					"ibmEvName": "Collection Started ",
					"ibmEvModule" : this._metricsModule(),
				    "ibmEvSection" : ev,
				    "ibmEvLinkTitle" : ""
			});
	     }));
	     
	     //Capture metrics on collection Successful end
	     dojo.subscribe("CollectionCompletedWithSuccess", dojo.hitch(this,function(item){
	    	 console.debug("Collection Success event subscription... ");
	    	 //sets collectionCompleted flag
	    	 this.completionSuccess=true;
	    	 
	 		 ibmStats.event({
					"ibmEV":"pop-up",
					"ibmEvAction":"Open",
					"ibmEvGroup":this.ibmEventGroup,
					"ibmEvName": "Collection Completion Success",
					"ibmEvModule" : this._metricsModule(),
				    "ibmEvSection" : "completionSuccess="+this.completionSuccess,
				    "ibmEvLinkTitle" : ""
			});
	     }));
	     
	     
	     //Capture metrics on collection failure
	     dojo.subscribe("CollectionCompletedFailed", dojo.hitch(this,function(item){
	    	 console.debug("Collection Failed event subscription... ");

	    	 //sets collection Failure flag
	    	 this.completionFailure=true;
	    	 
	 		 ibmStats.event({
					"ibmEV":"pop-up",
					"ibmEvAction":"Open",
					"ibmEvGroup":this.ibmEventGroup,
					"ibmEvName": "Collection Completion Failure",
					"ibmEvModule" : this._metricsModule(),
				    "ibmEvSection" : "completionFailure="+this.completionFailure,
				    "ibmEvLinkTitle" : ""
			});
	     }));

	     //Capture metrics on collection failure
	     dojo.subscribe("CollectionCompletedCanceled", dojo.hitch(this,function(item){
	    	 console.debug("Collection canceled event subscription... ");

	    	 //sets collection canceled flag
	    	 this.completionCanceled=true;
	    	 
	 		 ibmStats.event({
					"ibmEV":"pop-up",
					"ibmEvAction":"Open",
					"ibmEvGroup":this.ibmEventGroup,
					"ibmEvName": "Collection Completion Canceled",
					"ibmEvModule" : this._metricsModule(),
				    "ibmEvSection" : "completionCanceled="+this.completionCanceled,
				    "ibmEvLinkTitle" : ""
			});
	     }));

	     
	     //Capture metrics on file download
	     dojo.subscribe("CollectionFileDownloaded", dojo.hitch(this,function(item){
	    	 console.debug("Collection Downloaded event subscription... ");

	    	 //sets collection Downloaded flag
	    	 this.fileDownloaded=true;
	    	 	    	 
	    	 console.debug("Metrics Module: "+this._metricsModule());
	    	 
	 		 ibmStats.event({
					"ibmEV":"pop-up",
					"ibmEvAction":"Open",
					"ibmEvGroup":this.ibmEventGroup,
					"ibmEvName": "Collection File Downloaded",
					"ibmEvModule" : this._metricsModule(),
				    "ibmEvSection" : "fileDownloaded="+this.fileDownloaded,
				    "ibmEvLinkTitle" : ""
			});
	     }));

	     
	     //Capture metrics on browser close
	     dojo.subscribe("CollectionBrowserClosed", dojo.hitch(this,function(item){	    	 
	    	 
	    	 console.debug("Collection Browser Closed event subscription... ");
	    	 
	    	// Calculate the correlations based on the various events that happened prior:
	    	 //collectionRunning: true or false
	    	 //collectionStarted: true or false
	    	 var validCompletion=this.completionSuccess || this.completionCanceled || this.completionFailure;
	    	 
	    	 if(this.collectionStarted && !validCompletion)
	    		 this.collectionAbandoned=true;
	    	 
	    	 var eventSection="collection Started="+this.collectionStarted + " collection Abandoned="+this.collectionAbandoned +
	    	                  " file Downloaded="+this.fileDownloaded;
	    	 	    	 
	    	 console.debug("Metrics Module: "+this._metricsModule());
	    	 console.debug("Event Section: "+eventSection);
	    	 
	    	 //the metricsModule(): pmr, prodID, compID, ...
	 		 ibmStats.event({
				"ibmEV":"pop-up",
				"ibmEvAction":"Close",
				"ibmEvGroup":this.ibmEventGroup,
				"ibmEvName": "Collection Browser Closed",
				"ibmEvModule" : this._metricsModule(), 
				"ibmEvSection" : eventSection,
				"ibmEvLinkTitle" : ""
			});	    	 	    	 
	     }));
		}
	},
	//
	//
	_metricsModule: function(){
		//
		//Summary: Converts the value of current metrics information to a JSON format
		//
		
   	       var eventModule="pmr="+this.pmr+" productID="+this.productID+" productIDVersion="+this.productIDVersion+
                           " componentID="+this.componentID+" componentRelease="+this.compRelease + " taxonomy="+this.taxonomy + " data collector scripts version="+this.collectorScriptsVersion;

  	    
		return eventModule;
	},
	//
	//
	_resetAllVariables: function(){
		//
		//Summary: resets all the variables for another collection run
		//
		this.collectionStarted=false;
		this.completionSuccess=false;
		this.completionCanceled=false;
		this.completionFailure=false;
		this.collectionAbandoned=false;
	}
});