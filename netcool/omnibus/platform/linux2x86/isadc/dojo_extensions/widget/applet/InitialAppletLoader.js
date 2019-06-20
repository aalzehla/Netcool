/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.applet.InitialAppletLoader");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("widgets.panel.InvalidPrereqsPanel");
dojo.require("widgets.panel.RuntimeErrorMessage");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.applet", "appletstrings");

dojo.declare("widgets.applet.InitialAppletLoader", [dijit._Widget, dijit._Templated ], {
	// Path to the template
	templateString: dojo.cache("widgets", "applet/templates/InitialAppletLoader.html"),

	//product Taxonomy
	label:'',
	
	//load applet?
	loadApplet:false,
	
	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the prompt widget. 
		console.debug("Initial Applet Loader Constructor ...");
		
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
		console.debug("Post Create for Initial Applet Loader ...");
		this.inherited("postCreate",arguments);
	}
});