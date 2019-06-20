/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.fieldTask.ControlButtons");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.form.Button");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.fieldTask", "FieldTaskStrings");


dojo.declare("widgets.fieldTask.ControlButtons", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "fieldTask/templates/ControlButtons.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//if set to true, an ok Button will be created
	okButton:false,
	
	//if set to true, a cancel Button will be created.
	cancelButton:false,
	
	//if set to true, a skip Button will be created
	skipButton:false,
	

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("ControlButtons Constructor is called: ");
		dojo.mixin(this,args);
		
		
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {		
		//do the nls mixin here
		var _nlsResources=dojo.i18n.getLocalization("widgets.fieldTask","FieldTaskStrings");
		
		dojo.mixin(this,_nlsResources);

		this.inherited(arguments);
	},
	
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		console.debug(" Control Buttons postCreate is called..."+this.okButton);	

		if(this.okButton){
			var okButtonNode= new dijit.form.Button({label:this.okButtonLabel,onClick:this._okButtonClicked,baseClass:'isa-ibm-btn-arrow-pri'});
			console.debug("OK Button Created with ID: "+okButtonNode.id);
			this.domNode.appendChild(okButtonNode.domNode);
		}
		if(this.cancelButton){
			console.debug("cancel Button");
			var cancelButtonNode= new dijit.form.Button({label:this.cancelButtonLabel,onClick:this._cancelButtonClicked,baseClass:'isa-ibm-btn-cancel-sec'});
			console.debug("cancel Button Created with ID: "+cancelButtonNode.id);
			this.domNode.appendChild(cancelButtonNode.domNode);
		}
		if(this.skipButton){
			console.debug("skip Button");
			var skipButtonNode= new dijit.form.Button({label:this.skipButtonLabel,onClick:this._skipButtonClicked,baseClass:'isa-ibm-btn-arrow-sec'});
			console.debug("Skip Button Created with ID: "+skipButtonNode.id);
			this.domNode.appendChild(skipButtonNode.domNode);
		}
		
		this.inherited("postCreate",arguments);
	},

	_okButtonClicked: function(/*event*/ e){		
		console.debug("OK clicked");		
		dojo.publish("inputDialogResponseProvided",[{buttonClicked:'OK'}]);			
	},
	_cancelButtonClicked: function(/*event*/ e){		
		console.debug("Cancel clicked");		
		dojo.publish("inputDialogResponseProvided",[{buttonClicked:'Cancel'}]);			
	},
	_skipButtonClicked: function(/*event*/ e){		
		console.debug("Skip clicked");		
		dojo.publish("inputDialogResponseProvided",[{buttonClicked:'Skip'}]);			
	}

});