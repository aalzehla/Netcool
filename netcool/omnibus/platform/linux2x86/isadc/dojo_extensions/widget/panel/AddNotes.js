/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.panel.AddNotes");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.form.Textarea");
dojo.require("dijit.form.Button");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.panel", "panelstrings");

dojo.declare("widgets.panel.AddNotes", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "panel/templates/AddNotes.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//
	AddNotesTitleID:'Add Notes',
	AddNotesIntroduction:' Add any notes or commment about the data collection in the text area below. ',
	notesContent:'',
	

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("AddNotes Constructor is called: ");
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
		console.debug(" Add Notes postCreate is called...");
		var okButtonNode= new dijit.form.Button({label:'OK',onClick:this._okClicked,baseClass:'isa-ibm-btn-arrow-pri'});
		this.addNotesButton.appendChild(okButtonNode.domNode);
		
		dojo.subscribe("addFilesCreated",function(item){
			dijit.byId("addTextButtonID").set('disabled',true);
			dijit.byId("addFilesButtonID").set('disabled',true);
			dijit.byId("addScreenShotsButtonID").set('disabled',true);
		});

		dojo.subscribe("addTextCreated",function(item){
			dijit.byId("addTextButtonID").set('disabled',true);
			dijit.byId("addFilesButtonID").set('disabled',true);
			dijit.byId("addScreenShotsButtonID").set('disabled',true);
		});

		dojo.subscribe("addScreenShotsCreated",function(item){
			dijit.byId("addTextButtonID").set('disabled',true);
			dijit.byId("addFilesButtonID").set('disabled',true);
			dijit.byId("addScreenShotsButtonID").set('disabled',true);
		});

		dojo.subscribe("addFilesClosed",function(item){
			dijit.byId("addTextButtonID").set('disabled',false);
			dijit.byId("addFilesButtonID").set('disabled',false);
			dijit.byId("addScreenShotsButtonID").set('disabled',false);
		});

		dojo.subscribe("addTextClosed",function(item){
			dijit.byId("addTextButtonID").set('disabled',false);
			dijit.byId("addFilesButtonID").set('disabled',false);
			dijit.byId("addScreenShotsButtonID").set('disabled',false);
		});

		dojo.subscribe("addScreenShotsClosed",function(item){
			dijit.byId("addTextButtonID").set('disabled',false);
			dijit.byId("addFilesButtonID").set('disabled',false);
			dijit.byId("addScreenShotsButtonID").set('disabled',false);
		});
		
		console.debug("self ID "+this.id);
		this.inherited("postCreate",arguments);
	},
	_okClicked: function(e){
		console.debug(" clicked ..."+this.id);
		var notesID=this.id;
		dojo.byId(notesID).parentNode.parentNode.parentNode.removeChild(dojo.byId(notesID).parentNode.parentNode);
		dijit.byId("addTextButtonID").set('disabled',false);
		dijit.byId("addFilesButtonID").set('disabled',false);
		dijit.byId("addScreenShotsButtonID").set('disabled',false);

		dojo.publish("addTextClosed",[{"item":"true"}]);
	}
	});