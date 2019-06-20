/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */
// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.fieldTask.PromptFieldTask");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");

dojo.declare("widgets.fieldTask.PromptFieldTask", [dijit._Widget , dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "fieldTask/templates/PromptFieldTask.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,

	//This is used to know the type of the fieldTask
	type:'PROMPT',
	
	// This is the visible text label
	promptText: '',
	
	//This is the uniqueid. Should be unique and used to return the data back to the back end (not really used)
	uniqueid:'',
	
	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the prompt widget. 
		console.debug("Prompt FieldTask Constructor ...");
		
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		this.inherited(arguments);
	},
	
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		console.debug("Post Create ...");
		this.inherited("postCreate",arguments);
	}
});