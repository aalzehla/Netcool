/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.fieldTask.AutoPDInputButtons");

//dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.form.Button");

dojo.declare("widgets.fieldTask.AutoPDInputButtons", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "fieldTask/templates/AutoPDInputButtons.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
		
  //Used for autopdInput field task
  options:{"option":[]},

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("AutoPD InputButtons Constructor is called: ");
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
	//Creates the individual buttons as they are made available
	postCreate: function() {
		console.debug(" AutoPDInputButtons ... postCreate()");	
		
		var nodes=new Array();
		for(var i=0;i<this.options.length;i++){
			var baseClassStr="";
			if (i==0) {
				baseClassStr="isa-ibm-btn-arrow-pri";				
			} else {
				baseClassStr="isa-ibm-btn-arrow-sec";
			}
			var button=new dijit.form.Button({label:this.options[i],onClick:this._selectionClicked,baseClass:baseClassStr});				
			this.domNode.appendChild(button.domNode);
			console.debug("Constructed button for "+this.options[i]); 
		}
		
		this.inherited("postCreate",arguments);
	},
	//Reacts to the selection made. e.target.innerHTML contains the label of the button clicked.
	_selectionClicked: function(/*event*/ e){ 
		if(e.target.id!=''){ //This line is needed
		  console.debug("Clicked ... : "+e.target.innerHTML); //TODO: Not reliable, needs to change
		  var response=e.target.innerHTML;
		  dojo.publish("inputDialogResponseProvided",[{buttonClicked:response}]);
		} else
			console.debug("Can't recognize this event: "+e);
	}
});