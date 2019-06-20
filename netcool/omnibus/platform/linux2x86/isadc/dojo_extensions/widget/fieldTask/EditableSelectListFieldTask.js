/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */

// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.fieldTask.EditableSelectListFieldTask");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.form.ComboBox");
dojo.require("dojo.data.ItemFileReadStore");

dojo.declare("widgets.fieldTask.EditableSelectListFieldTask", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "fieldTask/templates/EditableSelectListFieldTask.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//this is the type of field task selected
	type:'EDITABLESELECTLIST',
	
	//Default label text 
	labelText: '',
	
	//Default combo box Items
	comboItems: {identifier:"name", "items":[]},
	
	//The default name of this combo box
	name:'default_name',
	
	//The unique ID used to send data to the back end.
	uniqueid:'',

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("EditableSelectListFieldTask Constructor is called: ");
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		this.inherited(arguments);
	},	
	//
	//
	selectedValueAsJSON: function() {
		//
		//Returns the EDITABLESELECTLIST entry in JSON format.
		//
		var valAsJSON = "";		
		var tempVal = new Object();
		tempVal.uniqueid=this.uniqueid;
		tempVal.value=this.combo.value;
		valAsJSON = dojo.toJson(tempVal,true);
		console.debug(" JSON value of Editable SelectList: "+valAsJSON);
			
		return valAsJSON; 
	},
	//
	//Returns the value of the selected item
	selectedValue: function(){
		return this.combo.value;
	},
	//Returns the 'name' attribute for the item selected
	selectedName: function(){
		return this.combo.name;
	},
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		this.inherited("postCreate",arguments);
		console.debug(" postCreate is called...");	
		
		var itemStore=new dojo.data.ItemFileReadStore({data:this.comboItems});
		var defaultLabel=this.comboItems.items[0].label;
		
		
		this.combo = new dijit.form.ComboBox({
			name:this.name,
		    value:defaultLabel,
			store:itemStore,
			searchAttr:"label"
		});
		
		cbWidth = getCBWidthInPixels(this.comboItems.items);
		this.combo.set("style", "width:"+cbWidth+"px");
		var spaceDiv1=dojo.create('div',{style:'margin-bottom:3px'}); //create space to the next element
		var spaceDiv=dojo.create('div',{style:'margin-bottom:5px'}); //create space to the next element
		
		this.domNode.appendChild(spaceDiv1);		
		this.domNode.appendChild(this.combo.domNode);
		this.domNode.appendChild(spaceDiv);		
	}});