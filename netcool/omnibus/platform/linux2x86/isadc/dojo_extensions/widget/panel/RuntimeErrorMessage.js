/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.panel.RuntimeErrorMessage");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.Dialog");
dojo.require("dijit.form.Button");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.panel", "panelstrings");

dojo.declare("widgets.panel.RuntimeErrorMessage", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "panel/templates/RuntimeErrorMessage.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,

	//Error Message that will be displayed
	errorMessage:'',
	
	//Action to take, if any action is known
	actionMessage:'',
	
	//Display the reload button, if true
	reloadButton:false,

	//Display the wait button, if true
	waitButton:false,
	
	//Display the wait button, if true
	showButtonLabels:true,
	
	//fatal error? (can't recover)
	fatalError:false,
	
	//title
	titleRuntimeError:'',

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("RuntimeErrorMessage constructor is called: ");
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
		console.debug(" Runtime Error  postCreate is called...");			
		this.inherited("postCreate",arguments);		

		var wrapperLabel = dojo.create('div');

		var errorMessageLabel = dojo.create('div',{innerHTML:this.errorMessage,style:"margin-top:10px"});
		var actionMessageLabel = dojo.create('div',{innerHTML:this.actionMessage,style:"margin-top:10px"});
		wrapperLabel.appendChild(errorMessageLabel);
		wrapperLabel.appendChild(actionMessageLabel);
		
		var buttonWrapper = dojo.create('div');
		//Make the buttons look a little neater
		if (!this.showButtonLabels) {
			dojo.attr(buttonWrapper, "style", "margin-top:10px");
		}
		
		if(this.waitButton){
			console.debug("add the wait button ...");
			if(this.showButtonLabels){
				var waitMessageLabel = dojo.create('div',{innerHTML:this.waitMessage,style:"margin-top:10px"});
				buttonWrapper.appendChild(waitMessageLabel);
			}
			var waitButtonNode= new dijit.form.Button({
				label:this.waitButtonLabel,
				//onClick:this._clearDialogAndWait,
				baseClass:'isa-ibm-btn-arrow-pri'});
			//Need to add this connector as their are scope issues in the onClick option above
			dojo.connect(waitButtonNode,"onClick",dojo.hitch(this,function(item){
				//Hide and destroy the dialog
				dialog.hide();
				dojo.destroy(dialog);
				//Call the waitForPage subscription - should be defined by page calling the dialog
				dojo.publish("waitForPage", []);
			}));
			buttonWrapper.appendChild(waitButtonNode.domNode);
		}

		//
		if(this.reloadButton){
			console.debug("add the reload button ...");
			var reloadButtonClass = "isa-ibm-btn-arrow-pri";
			if (this.waitButton) {
				reloadButtonClass = "isa-ibm-btn-arrow-sec";
			}
			
			if(this.showButtonLabels){
				var reloadMessageLabel = dojo.create('div',{innerHTML:this.reloadMessage,style:"margin-top:10px"});
				buttonWrapper.appendChild(reloadMessageLabel);
			}
			var okButtonNode= new dijit.form.Button({
				label:this.okButtonLabel,
				onClick:this._applicationReload,
				baseClass:reloadButtonClass});
			buttonWrapper.appendChild(okButtonNode.domNode);
		}
		
		var dialog = new dijit.Dialog({
			title:this.titleRuntimeError
		});
		
		wrapperLabel.appendChild(buttonWrapper);
		dojo.attr(dialog,"content",wrapperLabel);
		
		dialog.show();
		//this.containerNode.appendChild(dialog.domNode);
	},
	//
	//
	_applicationReload: function(){
		//
		// summary: reloading the application
		//
		
		//dijit.byId("runtimeDialogID").hide();
// Do we actually need to remove the child before reloading?
//		var runtimeNode=dijit.byId("runtimeDialogID").domNode;
//		runtimeNode.parentNode.removeChild(runtimeNode);
		console.debug("Reloading ...");
		window.location.reload();
	}
});