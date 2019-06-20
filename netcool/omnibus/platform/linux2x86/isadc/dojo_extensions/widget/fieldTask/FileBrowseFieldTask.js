/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.fieldTask.FileBrowseFieldTask");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.form.TextBox");
dojo.require("widgets.fieldTask.FileBrowseStore");
dojo.require("dijit.Tree");
dojo.require("dijit.tree.ForestStoreModel");
dojo.require("dijit.Dialog");
dojo.require("dijit.layout.ContentPane");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.fieldTask", "FieldTaskStrings");

dojo.declare("widgets.fieldTask.FileBrowseFieldTask", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "fieldTask/templates/FileBrowseFieldTask.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//The type of Field Task used
	type:'FILEBROWSER',
	
	//The label for this field task
	fileBrowseLabel: '',
	
	//The initial value for this FileBrowse
	initialValue: '',
	
	//If style information was specified, will be respected
	style:'',
	
	//This is the uniqueID used to send information back to the back end
	uniqueid:'',

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("FileBrowseFieldTask Constructor is called: ");
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		//do the nls mixin here
		var _nlsResources=dojo.i18n.getLocalization("widgets.fieldTask","FieldTaskStrings");		
		dojo.mixin(this,_nlsResources);

		var dirNode=null;
		this.inherited(arguments);
	},
	selectedValue: function(){
		//
		//Summary: retrieve the value of the file location selected.
		//
	  
	  var fileName='';
	  dojo.query("input",this.domNode).forEach(function(item){
		  var filesSelected=dojo.byId(item.id);
		  if(filesSelected.files.length>0){
			  fileName=filesSelected.files[0].fileName;
		  }else{
			  console.debug("No file was selected ...");
		  }
	        console.debug("Item: "+item.id + " value: "+fileName);
        });
	  return fileName;
	},
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		console.debug(" postCreate is called...uniqueid=");		
	
		var node2=dojo.create('div');
        node2.innerHTML="<br/>"+this.fileBrowseLabel;
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
		//Returns the FileBrowser entry in JSON format.
		//
		var valAsJSON = "";		
		var tempVal = new Object();
			tempVal.uniqueid=this.uniqueid;
			tempVal.value=dijit.byId(this.uniqueid).value;
			valAsJSON = dojo.toJson(tempVal,true);

			console.debug(" JSON value of FileBrowser: "+valAsJSON);
			return valAsJSON; 
	},
	//This event will create the tree on the Input Dialog
	//Additionally, the buttons for accepting and canceling
	//out of the directory selection are added
	_browseTree: function() {
		var filePath="";//this is not used.
        
		//This is the modified version of the dojox.data.FileStore 
		var fileStore = new widgets.fieldTask.FileBrowseStore({			
			url:filePath, 
			pathAsQueryParam: true,
			options:'files',
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
			style:"valign:top",
			onClick:dojo.hitch(this, function(item,node){
				console.debug("Tree Item was clicked. Retrieve value."+item.path);
				if(item.directory==false){
					var selFile=this.selectedFile + item.path;
					dijit.byId("acceptFileSelectionButton_"+this.uniqueid).set("disabled",false);
				    dojo.byId("fileBrowseSelectionID_"+this.uniqueid).innerHTML=selFile;
				    this.selectedItem=item.path;
				} else {
					var map = new Object();
					map.currentSelection=item.path;
					//Substitute the variables ...
					var selFileIsDir=dojo.string.substitute(this.selectedFileIsDirectory, map);
					
				   dojo.byId("fileBrowseSelectionID_"+this.uniqueid).innerHTML=selFileIsDir;
				   dijit.byId("acceptFileSelectionButton_"+this.uniqueid).set("disabled",true);
				}
			})});		

		dojo.style(directoryTree.domNode,"valign:top;align:left");
		directoryTree.startup();				
		//Should use a replaceChild()
		if(this.dirNode==null){
		    dojo.byId("FileBrowseContentPane0_"+this.uniqueid).appendChild(directoryTree.domNode);
		    this.dirNode=directoryTree.domNode;
		}else {
			dojo.byId("FileBrowseContentPane0_"+this.uniqueid).replaceChild(directoryTree.domNode,this.dirNode);
			this.dirNode=directoryTree.domNode;		  
		}

		//Update values on the filebrowse and make sure to pick them from resource bundles
		dijit.byId("fileBrowseDialog1_"+this.uniqueid).set("title",this.fileBrowseTitle);
		dijit.byId("acceptFileSelectionButton_"+this.uniqueid).set("label",this.fileBrowseButtonAccept);
		
		//Select a File ...
		dojo.byId("fileBrowseSelectAFile_"+this.uniqueid).innerHTML=this.fileBrowseSelection;
		
		//Show the modal dialog
		dijit.byId("fileBrowseDialog1_"+this.uniqueid).show(); 		
	},
	//User has canceled out of the directory selection
	//Back to the initial Value
	_cancelSelectionClicked: function(){
		console.debug("cancel Selected Item: ");
	},
	//User has accepted a specific directory
	//Update the text area with the user selection
	_acceptSelectionClicked: function(){
		console.debug("accept Selected clicked: ");
		dijit.byId(this.uniqueid).set('value',this.selectedItem);
		dijit.byId("fileBrowseDialog1_"+this.uniqueid).hide(); 
	}	
});