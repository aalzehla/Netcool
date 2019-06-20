/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.fieldTask.LabelFieldTask");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.form.Button");

dojo.declare("widgets.fieldTask.LabelFieldTask", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "fieldTask/templates/LabelFieldTask.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//This is the type of field task created
	type:'LABEL',
	
	//This is the label that will be displayed
	labelText: 'Default Label',	
	
	//This is the uniqueID which will be sent back, to the back end (actually, we don't send this information back for Labels)
	uniqueid:'',
	
	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the Label Widget
		console.debug("Label FieldTask Constructor is called: ");
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
		this.inherited("postCreate",arguments);		

		var linkToFile=this.labelText.replace(/href=\"([^\"])?\"/,'href=\'\1\'/g');
		var labelNode=dojo.create('label',{innerHTML:linkToFile, style:"margin-top:5px"});		
		var spaceDiv=dojo.create('div',{style:'margin-bottom:5px'}); //create space to the next element

		//Update the main node.
	    this.containerNode.appendChild(labelNode);
	    this.containerNode.appendChild(spaceDiv);
	}	
});