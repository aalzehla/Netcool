// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.view.ScriptSelection");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.layout.ContentPane");
dojo.require("widgets.panel.CollectionStatus");
dojo.require("dijit.form.Button");
dojo.require("dojo.data.ItemFileReadStore");
dojo.require("widgets.panel.CollectionStatus");
dojo.require("widgets.panel.RuntimeErrorMessage");
dojo.require("dijit.Tree");
dojo.requireLocalization("widgets.view", "viewstrings");

dojo.declare("widgets.view.ScriptSelection", [dijit._Widget, dijit._Templated ], {
	// Path to the template
	templateString: dojo.cache("widgets", "view/templates/ScriptSelection.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	//Default taxonomy of the Data Collection selected
	collectionTaxonomy:'System',
	
	//Script ID:  If a script ID was passed, use it.
	scriptID:'',
	
	//Check if there is a need to load the applet or not
	loadedApplet: null,
	
	//This is the maximum wait time
	MAX_WAIT_TIME:10000, //10 seconds max
	
	//Unit used (milliseconds) 
	unit:200, //200ms
	
	//Start of the count
	count:0, // count initialization
	
	//Placeholder for the waitForPage subscription
	waitForPage:'',


	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("Constructor for ScriptSelection widget");
		//The url to the script data
		this.scriptLink='';
		
		this.problemKeyValue='';
		
		//The label used in this script. This could be translated.
		this.scriptLabel='';	    
		
		//This is only used for simulation of multiple input dialogs ....
		//Should be turned off for the real thing ...
		this.counter=0;
		
		//
		this.testData = new Array();
		
		//This is the JSON String representation of the autopdMenu
		this.apdJsonJS=null;
		
		//SymptomsTree is null to start with
		this.symptomsTree=null;

		//No script was found yet
		this.scriptFound=false;
		
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		//Point to the applet NLS Strings
		var _nlsResources=dojo.i18n.getLocalization("widgets.view","viewstrings");

		dojo.mixin(this,_nlsResources);
		this.inherited(arguments);
	},
	//
	//
	//
	_doNothing: function() {
		console.debug("do nothing for a few milliseconds...");
	},
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		this.inherited("postCreate",arguments);

		//Read the AutoPDMenuJSON file
		this.loadedApplet=dijit.byId("loadingAppletID");

		waitForPage = dojo.subscribe("waitForPage", this, "createApdMenu");
		
		//Attempt to create the collector menu
		this.createApdMenu();
	},
	/*
	 * Attempts to create the AutoPDMenu
	 */
	createApdMenu: function(){
		console.debug("Starting createApdMenu at: " + this.count);
		dojo.byId("collectionCompletedViewDiv").innerHTML = "<div style='text-align:center; margin-top:140px;'>"+this.loadingMenuDescription+"<div>";
		var apdJson = this.loadedApplet.getAutoPDMenuJSON();
		if (this.count>this.MAX_WAIT_TIME) {
			console.debug("Exceeded the maximum amount of time to wait for autopdMenu to build. " + this.count);
			var errorMessage = new widgets.panel.RuntimeErrorMessage({
				actionMessage:this.waitActionMessage,
				errorMessage:this.waitErrorMessage,
				reloadButton:true,
				showButtonLabels:false,
				waitButton:true
		      });
			this.count=0;
		}
		else {
			//If the collector menu isn't ready in the applet, then try again
			if(!apdJson){
				this.count+=this.unit;
				var t = setTimeout(dojo.hitch(this,function() {
					this.createApdMenu();
					}),this.unit);
			}
			else { //The collector menu was found!
				console.debug("Tree loaded. ");
				this.apdJsonJS = dojo.fromJson(apdJson);	
				this._checkForScript();
				this._buildTree();
			}
		}
	},
	//
	//This function checks to see if a script passed on the URL can be found in the autopdmenu.xml file
	//
	_checkForScript: function(){
		
		// create the autoPDMenu data store
	    this.apdMenuStore = new dojo.data.ItemFileReadStore({
	    	data: this.apdJsonJS
	    });

		console.debug("Check existence of passed scriptID in the datastore."); 
		//The AutoPD Menu file was successfully loaded. Check if a script ID was passed.
		if(this.scriptID!='' && !this.scriptFound){ // a script ID was passed, now check to see if it is valid.	
			    	this.apdMenuStore.fetch({ query:{problemKey:this.scriptID}, 
	                     onBegin: function(total){ console.debug("Total number of items in the store: ", total); },
	                     
	                     onComplete: dojo.hitch(this,function(items){
	                       console.debug("Number of matching items in the store. "+items.length);
	                       if(items.length>1){	                    	   
	                    	   console.debug("The same problemType was used more than once in the AutoPDMenu.xml file. ");
	                    	   console.debug("Correct this problem. The complete tree will be displayed.");
	                       }else {
	                         for (var i = 0; i < items.length; i++) {
	                        
	                        	//Remember the label, the link and the scriptID 
	                           this.scriptLabel=items[i].label;
	                           this.scriptLink=items[i].link;
	                           this.scriptFound=true;
	                          
	                           console.debug("item returned " + items[i].id + " Label: "+items[i].label );
	                         }
	                       }
	                     }),
	                     onError: function(){
	                    	 console.debug("An error occured while searching for matching scriptID in the autopd menu store ...");
	                     }});		
			}
	},
	//
	// This function builds the tree, after all the data has been successfully loaded.
	//
	_buildTree: function(){
		//
		//Summary: Build the tree, after the data has been successfully loaded.
		//
		console.debug("Now build the tree. script found?"+this.scriptFound);

		var apdMenuModel = new dijit.tree.TreeStoreModel({
	    	store: this.apdMenuStore,
	    	query: {
	    		"id": "root"
	    	},
	    	childrenAttrs: ["children"]
	    });

	    var symptomsTree=new dijit.Tree({
	    	id:"symptomsTreeID",
	        model: apdMenuModel,
	        showRoot: false
	    });
	    
	    //Clear out the loading message
	    dojo.byId("collectionCompletedViewDiv").innerHTML = "";

	    //If the script wasn't found, simply build the tree
	    //If the script was found, there is no need to add the tree at this point. It will be added upon restart
	     if(!this.scriptFound)
	    	 dojo.byId("collectionCompletedViewDiv").appendChild(symptomsTree.domNode);
	        

	    //On a restart, we want to redisplay the tree and set the status message
        dojo.subscribe("collectionRestart",dojo.hitch(this,function(item) {
        	dojo.byId("collectionCompletedViewDiv").appendChild(symptomsTree.domNode);
        }));

        //Retrieve the product name, symptom name changes with selection
	    dojo.connect(symptomsTree,"onClick",dojo.hitch(this,function(item){
	    	console.debug("dojo.connect "+item.label);
	    	
	    	if(item.type=='problem'){ //a valid leave was clicked	    		
	    		this.setScriptToUse(item);
	    		dojo.publish("treeItemSelected",[{'validSelection':true,'label':item.label,'id':item.problemKey, 'script':item.link}]);
	    	}
	    	else {
	    		console.debug("valid Selection? false");
	    		dojo.publish("treeItemSelected",[{'validSelection':false}]);	    		
	    	}
	      }
	    ));
	    //Can clear the waitForPage subscription since the menu is loaded
	    dojo.unsubscribe(this.waitForPage);
	    
	    //Publish the appropriate event
	    if(this.scriptFound)
	    	dojo.publish("autoPDMenuLoadedAndScriptFound", [{'scriptFound':this.scriptFound,'symptomsTree':symptomsTree}]);
	    else 
	    	dojo.publish("autoPDMenuLoadedAndNoScriptFound",[{'scriptFound':this.scriptFound,'symptomsTree':symptomsTree}]);
	},
	getServiceBase: function(){
		return "";
	},
	//
	//
	collectionSelected: function(item){
		console.debug("Item selected: "+item);
	}, 
	//
	//
	hasMoreInputDialog: function(){
		if(this.counter==this.testData.length)
			return false;
		else
			return true;
	}, 
	//
	//
	nextInputDialog: function(){
		return this.testData[this.counter++];
	}, 
	//
	//
	readScriptFile: function(){
		console.debug("Script file path="+this.scriptLink);
		
		
		return {"id":this.scriptID,"label":this.scriptLabel, "link":this.scriptLink, "problemKeyValue":this.problemKeyValue};
		
	},
	//Remember the script that has been selected for use
	setScriptToUse: function(item){		
		  this.scriptLink=item.link;
		  this.scriptID=item.id;
		  this.scriptLabel=item.label;	  
		  this.problemKeyValue = item.problemKey;
	},
	//
	//
	//
	validScriptFound: function(){
		//
		//summary: This function returns true, if a valid scriptID was found
		console.debug("Valid script found?"+this.scriptFound);
		return this.scriptFound;
    }
});