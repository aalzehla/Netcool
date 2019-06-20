/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.panel.AddFilesAndFolders");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.form.Button");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.panel", "panelstrings");

dojo.declare("widgets.panel.AddFilesAndFolders", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "panel/templates/AddFilesAndFolders.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//
	AddFilesAndFoldersIntroduction:'Select a File or Folder to add to the collection archive. When you are finished, select the Done button.',
	
	//
	AddFilesAndFolderTitleID:'Add Files and Folders',
	

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("AddFilesAndFolders Constructor is called: ");
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
		console.debug(" Add Files and Folders postCreate is called...");
		
		var addFilesButton= new dijit.form.Button({label:'Add',onClick:this._addClicked,baseClass:'isa-ibm-btn-add-sec'});		

		this.addFilesAndFolderButton.appendChild(addFilesButton.domNode);
		
		//this.selectedFilesArea.innerHTML="Contains files that have already been selected";
		
		var doneButton= new dijit.form.Button({label:'Done',onClick:this._doneClicked,baseClass:'isa-ibm-btn-arrow-pri'});
		this.okButtonArea.appendChild(doneButton.domNode);		

		this.inherited("postCreate",arguments);
		console.debug(" Add Files and Folders postCreate is exiting");

	},
	_addClicked: function(e){
		
		console.debug("add clicked");
	},
	_doneClicked: function(e){
		console.debug("done clicked");
	}
	});