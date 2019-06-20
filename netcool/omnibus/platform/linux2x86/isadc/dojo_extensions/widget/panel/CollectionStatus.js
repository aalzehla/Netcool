/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.panel.CollectionStatus");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.ProgressBar");

dojo.require("widgets.customTasks.UploadInterface");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.panel", "panelstrings");

dojo.declare("widgets.panel.CollectionStatus", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "panel/templates/CollectionStatus.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//This is the message displayed in the status area
	statusMessage:'',
	
	//This is the default increment after each action on the status
	statusIncrement:1,
	
	//Depends on our execution protocol: file or http
	execEnvIsFile:true,
	
	//Previous archive location
	_archiveLocation: "",
	
	//Variable to keep track of the current UploadInterface
	uploadInterface: null,
	
	//disable updating of status messages
	processUpdates: true,

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {		
		//do the nls mixin here
		var _nlsResources=dojo.i18n.getLocalization("widgets.panel","panelstrings");
		
		dojo.mixin(this,_nlsResources);

		this.inherited(arguments);
		
	},
	
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		this.inherited("postCreate Collection Status ...", arguments);
		
		 //This widget subscribes to update status events
	     dojo.subscribe("UpdateStatusArea", dojo.hitch(this,function(item){
	    	 console.debug("Collection UpdateStatus Area event subscription... "+item);
	    	 if (this.processUpdates) {
	    		 this.updateStatusNow(item, false);
	    	 }

	     }));
	     
	     //This widget subscribes to collection completion events.
	     dojo.subscribe("CollectionCompleted", dojo.hitch(this,function(item){

	    	 console.debug("Collection Completed event subscription... "+item);
	    	 //dijit.byId("statusCancelButtonID").set("disabled",true);
	    	 this.updateStatusNow(item, true);

	    	 var statusObj = dojo.fromJson(item);
	    	 var status=statusObj.collectionStatus.completionStatus;
	    	 var canceled=statusObj.collectionStatus.canceled;
	    	 if (status==="NORMAL" ) {
	    		 this.publishUploadInterface(item);
	    	 } else {
	    		 this.doNotUpload(true);
	    		 this.enableRestartButton();
	    	 }
	    	 // this._addClass(status, canceled);

	     }));
	     
	     //This widget subscribes to collection completion events.
	     dojo.subscribe("UploadStatusCompleted", dojo.hitch(this,function(item){
			this.updateStatusNow(item, true);
	     }));

	     dojo.subscribe("collectionStarted",dojo.hitch(this,function(item){      
	       this._resetStatus(); //Enable the Spinner Icon
	       document.getElementById("statusMessageID").className = "progress";
	              
	     }));
	     
	     dojo.subscribe("inputDialogResponseProvided", dojo.hitch(this,function(response){
	    	 this.processUpdates = true;
	    	 console.debug("Response submitted ...");
		     document.getElementById("statusMessageID").className = "progress";
	    
	     }));
	     
	      dojo.subscribe("InputRequested", dojo.hitch(this,function(response){
	    	  this.processUpdates = false;
	    	  this.statusMessage=this.inputRequestedMsg;
	       	  this._updateStatus();
	    	 
	 
	    	    console.debug("Input Requested ...");
		       document.getElementById("statusMessageID").className = "question";
	
	     }));
	      
		 //This widget subscribes to Set Archive Location events
	     dojo.subscribe("SetArchiveLocation", dojo.hitch(this,function(item){
	    	 this.setArchiveLocation(dojo.fromJson(item).location);
	     }));
	     
	     
	     dojo.subscribe("ShowUploadInterface", dojo.hitch(this,function(item){
	    	 this.statusMessage = this.transferMessage;
	    	this._updateStatus();
	     }));

	       
		
	},
	
	//Update all the status related variable.
	//Calculate the various end statuses based on the collectinStatus object
	updateStatusNow: function(/*JSONString*/ jsonStatus, completed){	
		//
		//summary: This updates the status 
		//
		var statusObj = dojo.fromJson(jsonStatus);
		
		if(!completed){
			if(statusObj.message) {
				this.statusMessage=statusObj.message;
			}
		  if (statusObj.progress) {
			  this.statusIncrement=statusObj.progress;
		  }
		  
		} else {
			var canceled="";
			var failure="";
			var recovery="";
			var status="";
			var noUpload="";
			var collectionFailed = false;
			
			if (statusObj.collectionStatus.canceled) {
				canceled=statusObj.collectionStatus.canceled;
			}
			if (statusObj.collectionStatus.noUpload) {
				noUpload=statusObj.collectionStatus.noUpload;
			}
			if (statusObj.collectionStatus.collectionArchive){
				this.setArchiveLocation(statusObj.collectionStatus.collectionArchive);
			}
			if (statusObj.collectionStatus.collectionFailure) {
				failure=statusObj.collectionStatus.collectionFailure;
			}
			if (statusObj.collectionStatus.recoveryFailure){
				recovery=statusObj.collectionStatus.recoveryFailure;
			}
			if (statusObj.collectionStatus.completionStatus) {
				status=statusObj.collectionStatus.completionStatus;
			}
			if (statusObj.collectionStatus.collectionFailed) {
				collectionFailed=statusObj.collectionStatus.collectionFailed;
			}

			
			this.statusIncrement=100;
			
			var displayName=this._archiveLocation.replace(/\\\\/gi,'\\');
			if(canceled){ // User has canceled the Collection
				if (statusObj.type=="UPLOAD") {
					
					if (this.execEnvIsFile) {
						var parts = displayName.match(/(.*)[\/\\]([^\/\\]+\.\w+)$/);
						this.statusMessage=this.cancelUploadByUser + displayName+"&nbsp;&nbsp;(<a href='file:///"+ parts[1] +"' target='_blank'>" +this.browseDirectory + " </a>)";
					}
					else {
						this.statusMessage=this.cancelUploadByUser + displayName;
					}
					
					this._addClass("CANCEL", true);
					 this.enableRestartButton();
				} else {
					this.statusMessage=this.collectionCanceledByUser;	
				}  
			}
			
			if (noUpload && collectionFailed==false) {
				if (this.execEnvIsFile) {
					var parts = displayName.match(/(.*)[\/\\]([^\/\\]+\.\w+)$/);
					this.statusMessage=this.doNotUploadByUser + displayName+"&nbsp;&nbsp;(<a href='file:///"+ parts[1] +"' target='_blank'>" +this.browseDirectory + " </a>)";
					
				} else {
					this.statusMessage=this.doNotUploadByUser + displayName;
				}
				
			} else if(status=="NORMAL" && failure==false && canceled==false) {
				var linkToFile=this._archiveLocation.replace(/\\\\/gi,'/');
				
				if (this.execEnvIsFile) {
					var parts = linkToFile.match(/(.*)[\/\\]([^\/\\]+\.\w+)$/);

					if (statusObj.type=="UPLOAD") {
						//Upload is complete, show the restart button now
						this.enableRestartButton();
						this.statusMessage=this.uploadCompletionMessage + displayName+"&nbsp;&nbsp;(<a href='file:///"+ parts[1] +"' target='_blank'>" +this.browseDirectory + " </a>)";
					} else {
						this.statusMessage=this.collectionCompletionMessage;
					}
					
				} else {
					if (statusObj.type=="UPLOAD") {
						
						this.enableRestartButton();
						//Upload is complete, show the restart button now
						this.statusMessage=this.uploadCompletionMessage + displayName;
						
					} else {
						this.statusMessage=this.collectionCompletionMessage;
					}
				}
				
				//clear the uploadinterface
				this._addClass(status, canceled);
				this._publishCompleteSuccess();
				
			} else if(status=="ERROR") {
				console.debug("There was an error : " + statusObj.collectionStatus.collectionErrorMsg);
				if (!statusObj.collectionStatus.collectionErrorMsg) {
					
					var uploadMsg = statusObj.collectionStatus.message;
					uploadMsg = uploadMsg.replace(/\\\\/g,"\\");
					this.statusMessage = uploadMsg;
				
				} else {
					this.statusMessage=statusObj.collectionStatus.collectionErrorMsg;
				}
			
				
				if(!canceled){//Error occured during collection
					this._publishCompletedFailed();
					this.enableRestartButton();
					if (statusObj.type=="UPLOAD") {
						this.enableRestartUploadButton();
					}
				}
				
				this._addClass(status, canceled);
			} else {
				if (statusObj.type=="UPLOAD") {
				//	this.enableRestartUploadButton();
				}
		
			}			
		}
		
		//Update the elements with the new status
		this._updateStatus(completed);		
	},
	// Update the look and feel of the progress bar, depending on the completion status of the execution
	//
	_addClass: function(status, canceled){
		// summary:
		//		This method updates the look and feel of the progress bar, when completion has been reached.
		// 
		//      If there was an error, the look and feel will look a certain way (red?)
		//      If the completion was successful and there was no error and no warning, the look and feel will look (green?)
		//      If there was warnings, the look and feel will look a certain way (yellow?)
		//		
		console.debug("Update this class to reflect the visual of the Progress bar"); 
		var bar = dojo.byId("collectionProgress");
		if (status=="NORMAL") {
			console.debug("adding class success"); 
			dojo.query(".dijitProgressBarTile", bar).addClass("successBar");
			document.getElementById("statusMessageID").className = "success";
		} else if (canceled) {
			console.debug("adding class warning"); 
			dojo.query(".dijitProgressBarTile", bar).addClass("warningBar");
			document.getElementById("statusMessageID").className = "warning";
		} else {
			console.debug("adding class error"); 
			dojo.query(".dijitProgressBarTile", bar).addClass("errorBar");
			document.getElementById("statusMessageID").className = "error";
		}
	},
	_resetStatus: function() {
		this.statusMessage = "";
		this.statusIncrement=1;
		this._updateStatus();
	},
	//Effectively updates the status from the new values set
	//
	_updateStatus: function(completed){
		// summary:
		//		This method updates the status message and the progress bar (TODO: progress bar should be updated in a different way)
		// 
		//      Messages sent from the back end use this method to display on the User Interface. No changes are made to the messages
		//      The messages will be displayed exactly as received.
		//		
		  dojo.byId("statusMessageID").innerHTML = this.statusMessage;
		  dijit.byId("collectionProgress").progress=this.statusIncrement;	
		  dijit.byId("collectionProgress").update();
		 // if (completed) {
		  //var bar = dojo.byId("collectionProgress");
		  //dojo.query(".dijitProgressBarTile", bar).addClass("successBar");
		  //document.getElementById("statusMessageID").className = "success";
	//};
		  console.debug("update status ..."+this.statusMessage);		  
	},
	// This method is called, when the Cancel Collection  button on the data collection is clicked.
	//
	cancelDataCollection: function(){
		// summary:
		//		This method is called, when the Cancel Collection button is clicked during data collection
		// 
		//		
		console.debug("cancel data collection ...");
	},
	//
	//
	_publishCompleteSuccess: function(){
		//
		// summary: publishes event that a build completed successfully
		//
	    dojo.publish("CollectionCompletedWithSuccess", [{'status':'success'}]);
	},
	//
	//
	//
	_publishCompleteCanceled: function(){
		//
		// summary: publishes event that a build was successfully canceled
		//
	    dojo.publish("CollectionCompletedCanceled", [{'status':'canceled'}]);
	},
	//
	//
	//
	_publishCompletedFailed: function(){
		//
		// summary: publishes event that a build failed
		//
	    dojo.publish("CollectionCompletedFailed", [{'status':'failed'}]);
	},


	
	//Builds the Upload Interface
	publishUploadInterface: function(collectionData) {
		
		var statusObj = dojo.fromJson(collectionData);
		this.setArchiveLocation(statusObj.collectionStatus.collectionArchive);
		
		var uploadPMRNumber = "";
		if (executionEnv.pmrNumber != "00000,000,000" && executionEnv.pmrNumber !="") {
			uploadPMRNumber = executionEnv.pmrNumber;
		}
		
		if(this.uploadInterface==null) {
			this.uploadInterface = new widgets.customTasks.UploadInterface({
				displayIBMTransfer:"true",
				displayOtherTransfer:"true",
				remoteFileName:"",
				pmrNumber:uploadPMRNumber,
				email:executionEnv.email
			});
			
			dojo.subscribe("CancelCurrentAction", function(){
				dojo.publish("CancelUpload", []);
				dojo.unsubscribe("CancelCurrentAction");
			});
			

			//Remove the Upload Interface from the GUI
			dojo.subscribe("RemoveUploadInterface", dojo.hitch(this, function() {
				this.uploadInterface.destroyRecursive();
			}));
			
			//Remove the Upload Interface from the GUI
			dojo.subscribe("HideUploadInterface", dojo.hitch(this, function() {
				this.uploadInterface.hide();
			}));
			
			//Remove the Upload Interface from the GUI
			dojo.subscribe("ShowUploadInterface", dojo.hitch(this, function() {
				this.uploadInterface.show();
			}));
			
			dojo.connect(this.uploadInterface.sendUploadButtonNode, "onClick", dojo.hitch(this, function(){
				
			    document.getElementById("statusMessageID").className = "progress";
				var bar = dojo.byId("collectionProgress");
				dojo.query(".dijitProgressBarTile", bar).removeClass("successBar");
				dojo.query(".dijitProgressBarTile", bar).removeClass("errorBar");
				dojo.query(".dijitProgressBarTile", bar).removeClass("warningBar");
				
				var startCollectionUpdate = {};

				startCollectionUpdate.message = this.uploadStartMessage;
				startCollectionUpdate.progress = "0";
				
				this.updateStatusNow(dojo.toJson(startCollectionUpdate), false);
				var uiFormInput =  this.uploadInterface.getFormInput();
				uiFormInput.parms.fileToUpload = this._archiveLocation;
				
				dojo.publish("TransferCollection", [uiFormInput]);
				this.uploadInterface.disableSend("true");
				this.uploadInterface.hide();
				this.enableCancelButton();
			}));
			
			dojo.connect(this.uploadInterface.doNotUploadButtonNode, "onClick", dojo.hitch(this, function(){
				
				this.doNotUpload(false);
				this.enableRestartButton();
				this.enableRestartUploadButton();
				console.debug("RestartUploadButton called: 3");
			}));
			
			dojo.byId("collectionTransferDiv").appendChild(this.uploadInterface.domNode);

			dojo.byId("testthis").focus();
			console.debug("The focus has been placed on the collection status");
		}
		else {
			dojo.publish("ShowUploadInterface", []);
			dojo.byId("testthis").focus();
			console.debug("The focus has been placed on the collection status again");
		}
	},
	
	//Disables the ability to upload
	doNotUpload: function(collectionFailed){
		var statusJSON = {};
		statusJSON.type = "UPLOAD";
		statusJSON.collectionStatus = {};
		statusJSON.collectionStatus.noUpload = true;
		statusJSON.collectionStatus.collectionFailed = collectionFailed;
		statusJSON.collectionStatus.completionStatus = "CANCELED";  
		dojo.publish("UploadCompleted", [dojo.toJson(statusJSON)]);	 
	},
	
	enableRestartButton: function() {
		dojo.publish("EnableRestart", []);	
	},
	
	enableRestartUploadButton: function() {
		dojo.publish("EnableUploadRestart", []);	
	},
	
	enableCancelButton: function() {
		dojo.publish("EnableCancel", []);	
	},
	
	//Set the Archive File location
	setArchiveLocation: function(archiveLocation) {
		this._archiveLocation = archiveLocation;
	}
	
});