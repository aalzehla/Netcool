/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */
// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.panel.SymptomDescription");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.panel", "panelstrings");

dojo.declare("widgets.panel.SymptomDescription", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "panel/templates/SymptomDescription.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//
	CollectorDescriptionTitleName:'Symptom Description ',

	//
	CollectorDescriptionID:'',

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("Collection Symptom Description is called: ");
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
		console.debug(" Symptom Description postCreate is called...");	

		this.setInvisible();
		
		//When a valid item is clicked, 'startButton' is enabled.
		dojo.subscribe("treeItemSelected",function(item){
  	        console.debug("Valid Item Selection in SymptomDescription? "+item.validSelection);
  	        
  			if(dojo.byId("symptomDescriptionID")){
  				if(item.validSelection)
  					dojo.byId("symptomDescriptionID").innerHTML=item.description;
  				else
  					dojo.byId("symptomDescriptionID").innerHTML="";
  			}
		});
		
		dojo.subscribe("collectionStarted", function(item){
		  console.debug(" collection started event....removing .... dom node");	
			var symptomDescription=dojo.byId("symptomDescription");
			if(symptomDescription) {
				symptomDescription.parentNode.removeChild(symptomDescription)
			}else {
				console.debug("No symptom description ...");
			}
		});
		
		this.inherited("postCreate",arguments);
	},
	//
	setInvisible: function(){
		//dojo.addClass(this.domNode,"");
	}
	});