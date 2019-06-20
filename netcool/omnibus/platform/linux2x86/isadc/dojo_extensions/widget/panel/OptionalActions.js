/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.panel.OptionalActions");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("widgets.panel.AddNotes");
dojo.require("widgets.panel.AddFilesAndFolders");
dojo.require("widgets.panel.AddScreenShots");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.panel", "panelstrings");

dojo.declare("widgets.panel.OptionalActions", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "panel/templates/OptionalActions.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//
	OptionalActionsTitleName:'Optional Actions',
	
	//
	AddTextID:'Add Text',
	
	//
	AddFilesID:'Add Files',
	
	//
	AddScreenShotsID:'Add Screenshots',
	

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("OptionalActions Constructor is called: ");
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
		console.debug(" OptionalActions postCreate is called..."+this.okButton);	
		
		this.inherited("postCreate",arguments);
	},
	_addFilesClicked: function(/*event*/ e){
		console.debug("add files clicked ...");
		//If notes already exists, don't create another one TODO: not sure how todo this ...
		//Add Files and Folders: 
		
		alert("This functionality will be implemented in a future iteration.  ");
		/*
		 var wid = new widgets.panel.AddFilesAndFolders({});    
		dojo.byId("collectionCompletedViewDiv").appendChild(wid.domNode);
		
		dojo.publish("addFilesCreated",[{"item":true}]);
       */
	},
	_addTextClicked: function(/*event*/ e){
		console.debug("add text clicked ...");
		alert("This functionality will be implemented in a future iteration.  ");
		   //Add Notes: 
		/*   var wid = new widgets.panel.AddNotes({});    
		   dojo.byId("collectionCompletedViewDiv").appendChild(wid.domNode);		   		
		   dojo.publish("addTextCreated",[{"item":true}]);
		   */
	},
	_addScreenShotsClicked: function(/*event*/ e){
		console.debug("add screenshots clicked ...");
	      //Add ScreenShots:
		alert("This functionality will be implemented in a future iteration.  ");
		/*
		   var wid = new widgets.panel.AddScreenShots({});    
		   dojo.byId("collectionCompletedViewDiv").appendChild(wid.domNode);
		   
		   dojo.publish("addScreenShotsCreated",[{"item":true}]);
		   */
	  }
	});