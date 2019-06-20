// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.view.CollectionExecution");

//dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dojo.data.ItemFileReadStore");
dojo.require("widgets.view.CollectionControl");
dojo.require("widgets.panel.CollectionSummary");
dojo.require("widgets.panel.CollectionCompleteSummary");
dojo.require("widgets.inputDialog.InputDialog");
dojo.require("widgets.panel.CollectionStatus");
dojo.require("widgets.panel.OptionalActions");
dojo.require("widgets.panel.SymptomDescription");
dojo.require("widgets.view.ScriptSelection");
dojo.require("widgets.panel.LicensePanel"); 
dojo.require("dojo.date.locale");

dojo.declare("widgets.view.CollectionExecution", [dijit._Widget, dijit._Templated ], {
	// Path to the template
	templateString: dojo.cache("widgets", "view/templates/CollectionExecution.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//product Taxonomy
	productTaxonomy:'',
	
	//product Script ID
	productScriptID:'',
	
	//Which protocol is being used? Defaults to File protocol
	execEnvIsFile:false,
	
	//Production or Development Environment? Defaults to production
	execEnvISADevEnv:false,
	
	//The loadedApplet
	loadedApplet:null,
	
	//The current upload request identifier, needed to cancel current upload
	currentUploadIndentifier: "",
	
	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("Constructor for CollectionExecution ");

		//Keeps track of the input Dialogs for this collection Execution
		this.inputDialogs = new Array();
		
		//
		this.counter=0;
		
		//Knows, which is the current inputDialog being shown
		this.current='';
		
		this.inRestart=false;
		this.statusArea=null;	
		
		this.treeWidget=null;
		
		this.licenseObj="";
		
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		var _nlsResources=dojo.i18n.getLocalization("widgets.view","viewstrings");		
		dojo.mixin(this,_nlsResources);

		this.inherited(arguments);
	},
	// Registers this new Input Dialog
	_addInputDialog: function(dialog){
		// summary:
		//     This method keeps track of the current InputDialog.
		//
		this.inputDialogs[counter++]= dialog;
	},
		//
	_getInputDialog: function(dialog){
		// summary:
		//     This method keeps track of the current InputDialog.
		//
		for(var i=0; i<this.inputDialogs.length;i++){
			if(this.inputDialogs[i]==dialog) return this.inputDalogs[i];
		}
	},
	//
	setCurrentInputDialog: function(currentDialog ){
		// summary:
		//     This method sets the current inputDialog.
		//
		this.current=currentDialog;
	},
	//
	getCurrentInputDialog: function(){
		// summary:
		//     This method retrieved the current inputDialog
		//

		return this.current;
	},
	
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		this.inherited("postCreate",arguments);
			     
	     //Subscribe to the treeselected event. Helps keep the value of the script path
	     dojo.subscribe("treeItemSelected",dojo.hitch(this, function(item){
	    	 if (item.validSelection == true) {
			     dojo.byId("msgAreaViewDiv").innerHTML = this.clickStart;	    		 
	    	 }
	     }));
	     
	     dojo.subscribe("UploadCompleted", dojo.hitch(this,function(item){
			//Hide the Cancel button if it is being displayed
			dojo.publish("HideCancel", []);
			dojo.publish("UploadStatusCompleted", [item]);
	     }));
	     
	     //Wait for input from the User ...	     
	     dojo.subscribe("inputDialogCompleted", function(item){
	     });
	     
	     //This widget subscribes to collection completion events.
	     dojo.subscribe("CollectionCompleted", dojo.hitch(this,function(item){
	    	 console.debug("Collection Completed event subscription... "+item);	    	 
	    	 console.debug("Deregistering event confirmation to navigate away.");
	    	 window.onbeforeunload = null;	    	 
	     }));
	     
	     //Collection completed even has been published
	     dojo.subscribe("CollectionCompletedWithSuccess",function(item){
	    	 console.debug("Collection Completed with success event occured ..., create optional options");
	     });
	     
	     //Collection has been canceled
	     dojo.subscribe("collectionCanceled", function(item){
	    	 
	     });
	     
	     //Input Dialog Panel has been skipped
	     dojo.subscribe("collectionSkiped",  function(item){
	    	 
	     });

	     //Input Dialog Panel has been skipped
	     dojo.subscribe("SetLicenseInformation",  dojo.hitch(this,function(licenseItem){
	    	 console.debug("License Information: "+licenseItem);
	    	 this.licenseObj = dojo.fromJson(licenseItem);
	    	 
	    	 console.debug("License Accepted:"+this.licenseObj.licenseAccepted);	    	
	     }));

	     dojo.subscribe("collectionRestart", dojo.hitch(this,function(item) {
	    	 console.debug("set inRestart to true");
	    	 this.inRestart = true;
	    	 
	    	 //set and show the msgAreaViewDiv
	    	 dojo.byId("msgAreaViewDiv").innerHTML = this.selectAnotherScript;
	    	 dojo.byId("msgAreaViewDiv").style.display = "block";
	    	 
	    	 //hide the statusArea widget
	    	 this.statusArea.domNode.style.display = 'none';
	     }));
	     
	     //This widget subscribes to collection transfer requests
	     dojo.subscribe("TransferCollection", dojo.hitch(this,function(formJSON){
	    	 this.currentUploadIndentifier = this.loadedApplet.uploadRequest(dojo.toJson(formJSON));
	     }));
	     
	     //This widget subscribes to collection transfer requests
	     dojo.subscribe("CancelUpload", dojo.hitch(this,function(formJSON){
	    	 this.loadedApplet.cancelUploadRequest(this.currentUploadIndentifier);
	     }));
	     
	     //Wait for event, where a new input dialog is requested
	     dojo.subscribe("InputRequested",function(item){
	    	 
	    	 console.debug("Input Data: Type: "+item);
	    	 var inputDialog= new widgets.inputDialog.InputDialog(item);
	    	 
		      //Remember the current Input Dialog ID
		      console.debug("InputDialog created with ID: "+collectionExecution.getCurrentInputDialog());
		      collectionExecution.setCurrentInputDialog(inputDialog.id);

		      //Add current input dialog to the dom
		      dojo.byId("inputDialogViewDiv").appendChild(inputDialog.domNode);
		      					
	     });
	     

	     //Collection started event has been  published.
	     //The tree will be removed
	     //optional Actions will be displayed
	     //
	     dojo.subscribe("collectionStarted",dojo.hitch(this,function(item){
	    	 
				var scriptObject=this.treeWidget.readScriptFile();
				
				var tree=dojo.byId("symptomsTreeID");
				//var treeDijit=dijit.byId("symptomsTreeID"); 
					
				//Attach the status
				console.debug('inRestart:'+this.inRestart);
				if (!this.inRestart) {
					//create and add the CollectionStatus widget then hide the msgAreaViewDiv
					this.statusArea=new widgets.panel.CollectionStatus({execEnvIsFile:this.execEnvIsFile});					
					dojo.byId("statusAreaViewDiv").appendChild(this.statusArea.domNode);
					dojo.byId("msgAreaViewDiv").style.display = "none";
				} else {
					//hide the msgAreaViewDiv and display the statusAreaViewDiv
					dojo.byId("msgAreaViewDiv").style.display = "none";
					this.statusArea.domNode.style.display = 'block';
				}
				  
				//Calculate the Start Parameters for the Data Collection
				var startParameters=this.calculateStartParameters(scriptObject);
				
				dojo.publish("collectionStartedWithScript",[{"scriptId":startParameters.scriptId}]);
				
			       //Register event to navigate away.
			       console.debug("Registering event confirmation to navigate away.");
			       window.onbeforeunload =dojo.hitch(this, this._exitWithWarning);
			       
				//Start the collection  
				this.loadedApplet.startCollection(startParameters);
				
			 	//Remove the tree from the DOM
				if(tree) 
					  tree.parentNode.removeChild(tree);
				  
	     }));
	},
	//
	//Decides whether to display the Data Collection right away or display the complete set of selections.
	//
	displayTreeOrStartCollection: function() {
	  //
	  // summary: This function is used to display the tree, if needed. In the case that the scriptID was passed in the URL, 
	  // the data collection will start right away.
	  // In this case, there is no need to display the tree at first.
	  //
	    
	    //Wait for the menu to complete the loading before proceeding
	    dojo.subscribe("autoPDMenuLoadedAndScriptFound",dojo.hitch(this,function(item){
	    	//A valid script was found, start the collection right away.
	    	console.debug("Starting the collection for the following script: " + this.productScriptID);
			  //IE doesn't like the Execution Area visible at first.
			  //Currently set to invisible in CollectionExecution.html
			  dojo.style(dojo.byId("mainView"), "visibility", "visible");

		      //Start Collection, Stop Collection, Continue Collection  buttons
		      var collectionControl = new widgets.view.CollectionControl({startButton:false, startVisible:false});    
		      dojo.byId("collectionControlViewDiv").appendChild(collectionControl.domNode);
		      
			  console.debug("Publish start collection event...");
			//Publish the Start Collection Event
			dojo.publish("collectionStarted",[{'script':true}]);				    	
	    }));


	    //Wait for the menu to complete the loading before proceeding
	    dojo.subscribe("autoPDMenuLoadedAndNoScriptFound",dojo.hitch(this,function(item){
	    	//No valid script was found, build the tree widget
	      console.debug("create Tree Widget " + this.productScriptID+ " scriptFound? "+item.scriptFound);

	      //Create div to hold paragraph to be read by JAWS
          var selectScriptDiv=dojo.create('div',{style:{margin:"20px 0 0 0"}});
          var messageTextPar=dojo.create('p',{tabIndex:'-1'});

          messageTextPar.appendChild(document.createTextNode(this.selectScript));
          
		  selectScriptDiv.appendChild(messageTextPar);
	      dojo.byId("msgAreaViewDiv").appendChild(messageTextPar);	

	      //Start Collection, Stop Collection, Continue Collection  buttons
	      var collectionControl = new widgets.view.CollectionControl({startButton:false});    
	      dojo.byId("collectionControlViewDiv").appendChild(collectionControl.domNode);
	      
		  //IE doesn't like the Execution Area visible at first.
		  //Currently set to invisible in CollectionExecution.html
		  dojo.style(dojo.byId("mainView"), "visibility", "visible");
		  
		  //Don't do this for IE
		  
		  if(dojo.isFF){
		    messageTextPar.focus();
		  }
	
		  console.debug("License Information accepted?: "+ this.licenseObj.licenseAccepted);
		  
		  var t="";
		  if( (this.licenseObj.licenseAccepted=="true") || (this.licenseObj.licenseAccepted==true)){
			console.debug("The license has already been accepted.");
						
		  }else { //If I have to build the LicensePanel, it means the license wasn't yet accepted.
		     if(this.execEnvIsFile) 
		    	t = new widgets.panel.LicensePanel({execEnvIsFile:this.execEnvIsFile,execEnvISADevEnv:this.execEnvISADevEnv});
		  }
	    }));
	    
	  //Create the tree from the AutoPDMenu scripts files
	    
		this.treeWidget = new widgets.view.ScriptSelection({collectionTaxonomy:this.productTaxonomy, scriptID:this.productScriptID});		
	},
	//
	// Display a warning prior to navigating to another page/closing the browser
	//
	_exitWithWarning: function(){
		//
		//summary: This function is used to check if the data collection is in progress, when the user
		// is about to navigate away.
		//
		console.debug(" Exiting? "+this.completeDataCollectionOnExit);
		
		return this.completeDataCollectionOnExit;
	},
	//
	//Calculates the start parameters for the Applet.
	//These parameters depend on the environment, the protocol
	calculateStartParameters: function(/* */scriptObject){
		// summary:
		//		This method calculates the start parameters for the Applet.
		// 
		//    returns: collectionParams: These are the parameters needed to start the Data Collection
		//		
		
		//Print all the values before executing
		console.debug(" Link: "+ scriptObject.link);
		console.debug(" ID: "+  scriptObject.id);
		console.debug(" Label: "+scriptObject.label);
		console.debug(" Problem Key: "+scriptObject.problemKeyValue);
				 
		//The return JSON
		return {"link":scriptObject.link,
			    "scriptId":scriptObject.id,
			    "scriptLabel":scriptObject.label,
			    "problemKeyValue":scriptObject.problemKeyValue};
	},
	//Submits the response to an inputDialog to the back end.
	//
	submitResponse: function(/** JSON response**/response){
		// summary:
		//		This method calculates the start parameters for the Applet.
		// 
		//    returns: collectionParams: These are the parameters needed to start the Data Collection
		//		
		 this.loadedApplet.submitResponse(response);	    		
	},
	//
	//
	setEnvironmentVariables: function() {
		//
		//summary: set some environment variables on elements on the CollectionExecutionEnvironment
		//
		
		console.debug(" setting the development Environment variables: isDevEnv? "+this.execEnvISADevEnv);
		var appAction = dijit.byId("appActionPanel");
		appAction.setEnvironmentVariables(this.execEnvIsFile,this.execEnvISADevEnv);
	}
});