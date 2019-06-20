/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.panel.CollectionFileTransfer");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.panel", "panelstrings");

dojo.declare("widgets.panel.CollectionFileTransfer", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "panel/templates/CollectionFileTransfer.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//
	FileTransferTitleName:'Default File Transfer Title Name',
	
	//
	FileTransferID:'Add New Text:',
	

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("File Transfer Constructor is called: ");
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
		console.debug(" File Transfer postCreate is called..."+this.okButton);	
		
		this.inherited("postCreate",arguments);
	}
	});