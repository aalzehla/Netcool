/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.fieldTask.DirectoryFieldTask");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("widgets.fieldTask.FileBrowseStore");
dojo.require("dijit.tree.ForestStoreModel");
dojo.require("dijit.Tree");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.Dialog");
dojo.require("dijit.layout.ContentPane");
dojo.require("dijit.layout.BorderContainer");
dojo.require("dojox.form.BusyButton");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.fieldTask", "FieldTaskStrings");

dojo.declare("widgets.fieldTask.DirectoryFieldTask", [dijit._Widget , dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "fieldTask/templates/DirectoryFieldTask.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//the type of Field Task used
	type:'DIRECTORYBROWSER',
	
	//The default label
	directoryBrowseLabel: '',
	
	//The initial value for the directory location
	initialValue: '',
	
	//If style information was passed, will be respected (width, ...)
	style:'',
	
	//The unique ID is used to send data back to the back end
	uniqueid:'',
	
	//The busy button will display when the directory browser is loading
	busyButton:'',
	
	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the prompt widget. 
		console.debug("Directory FieldTask Constructor ... ");		
		this.selectedItem='';
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
		console.debug("PostCreate Directory Browser: Initial value="+ this.initialValue);
		
		var node2=dojo.create('div');
        node2.innerHTML="<br/>"+this.directoryBrowseLabel;
        this.domNode.appendChild(node2);

		//Textbox to hold initial value
		this.textBox = new dijit.form.TextBox({
			id:this.uniqueid,
		    value:this.initialValue,		    
		    style:this.style
		});
		this.domNode.appendChild(this.textBox.domNode);

		//Browse button to initiate the browse
		this.browseButton= new dijit.form.Button({
		 label:this.browseLabel,
		 style:this.style,
		 onClick:dojo.hitch(this, "_browseTree")
		});
		this.domNode.appendChild(this.browseButton.domNode);
				
		this.inherited("postCreate",arguments);
		
	},
	//
	//Returns the value of the selected item
	selectedValue: function(){
		var value=dijit.byId(this.uniqueid).value;
		console.debug("value: "+value);
		correctedValue=value.replace(/\\/gi,'/');	
		console.debug("Corrected value: "+correctedValue);
		return correctedValue;
	},	
	//
	//
	selectedValueAsJSON: function() {
		//
		//Returns the Directory Browse entry in JSON format.
		//
		var valAsJSON = "";		
		var tempVal = new Object();
			tempVal.uniqueid=this.uniqueid;
			tempVal.value=dijit.byId(this.uniqueid).value;
			valAsJSON = dojo.toJson(tempVal,true);

			console.debug(" JSON value of Directory Browser: "+valAsJSON);
			return valAsJSON; 
	},
	//This event will create the tree on the Input Dialog
	//Additionally, the buttons for accepting and canceling
	//out of the directory selection are added
	_browseTree: function() {
		var filePath="";//this is not used.

		//Show the modal dialog
		dijit.byId("ContentPane0_"+this.uniqueid).destroyDescendants(true);
		
		//Display a loading icon so the user knows to wait
		dirBrowseBusy = new dojox.form.BusyButton({
			busyLabel: " "});
		dirBrowseBusy.makeBusy();
		dijit.byId("ContentPane0_"+this.uniqueid).set('content',dirBrowseBusy);
		
		//Update values on the directorybrowse and make sure to pick them from resource bundle
		dijit.byId("dialog1_"+this.uniqueid).set("title",this.directoryBrowseTitle);
		dijit.byId("acceptDirectorySelectionButton_"+this.uniqueid).set("label",this.directoryBrowseButtonAccept);
		
		//Navigate to directory
		dojo.byId("navigateToDirectory_"+this.uniqueid).innerHTML=this.directoryBrowseSelection;
		
		//Directory Selected
		dojo.byId("selectionID_"+this.uniqueid).innerHTML=this.directorySelected;

		//Show the dialog and let the directories load, versus waiting for them to load in the backend
		dijit.byId("dialog1_"+this.uniqueid).show();

		//This is the modified version of the dojox.data.FileStore
		var fileStore = new widgets.fieldTask.FileBrowseStore({
			url:filePath, 
			pathAsQueryParam: true,
			options:'dirsOnly',
			labelAttribute:"root"
		});

		//Create the model to hold the data
		myModel = new dijit.tree.ForestStoreModel({
		  store:fileStore,
		  deferItemLoadingUntilExpand:false,
		  query:'{}',
		  childrenAttrs:["children"]

		});

		//Create the Tree
		directoryTree = new dijit.Tree({
			showRoot:false,
			model:myModel,
			label:'root',
			persist: false,
			style:"valign:top;align:left",
			onClick:dojo.hitch(this, function(item,node){
				console.debug("Tree Item was clicked. Retrieve value."+item.path);
				dojo.byId("selectionID_"+this.uniqueid).innerHTML=this.selectedDirectory+item.path;
				this.selectedItem=item.path;
			})});

		dojo.style(directoryTree.domNode,"valign:top;align:left");
		directoryTree.startup();
		dijit.byId("ContentPane0_"+this.uniqueid).destroyDescendants(true);
		dojo.byId("ContentPane0_"+this.uniqueid).appendChild(directoryTree.domNode);

	},
	//User has canceled out of the directory selection
	//Back to the initial Value
	_cancelSelectionClicked: function(){
		//var open=dijit.byId("dialog1").open;
		console.debug("cancel Selected Item: ");
		//dijit.byId(this.uniqueid).set('value',this.initialValue);
	},
	//User has accepted a specific directory
	//Update the text area with the user selection
	_acceptSelectionClicked: function(){
		console.debug("accept Selected clicked: Delete the tree from the inputDialog. ");
		dijit.byId(this.uniqueid).set('value',this.selectedItem);
		dijit.byId("dialog1_"+this.uniqueid).hide(); 
	},
	//
	deregisterDirectory: function(){
		console.debug("Deregistering node");
		dojo.byId("dialog1_"+this.uniqueid).parentNode.removeChild(dojo.byId("dialog1_"+this.uniqueid));
	}
});