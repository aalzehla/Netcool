/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */
// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.fieldTask.SelectListFieldTask");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dojo.data.ItemFileReadStore");
dojo.require("dijit.form.Select");

dojo.declare("widgets.fieldTask.SelectListFieldTask", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "fieldTask/templates/SelectListFieldTask.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//  This is used to know the type of the fieldTask
	type:'SELECTLIST',
	
	// This is the readable text label
	labelText: '',
	
	//This is the combo Items
	comboItems:{identifier:"label", "items":[]},
	
	//This is the default name
	name:'',
	
	//This is the uniqueid. Should be unique and used to return the data back to the back end
	uniqueid:'',
	
	initValue:'',
	
	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("SelectListFieldTask Constructor is called: ");
		
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from super classes are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		this.inherited(arguments);
	},
	
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		console.debug(" postCreate is called...");	
				
		this.combo = new dijit.form.Select({name:this.name,maxHeight:100});
		
		console.debug("combo items: "+dojo.toJson(this.comboItems.items,true));
		for (var i=0; i < this.comboItems.items.length; i++) {
			this.combo.addOption({"label":this.comboItems.items[i].label,"value":this.comboItems.items[i].name});
		}

		dijit.byId( this.combo.domNode.id).attr( 'value',this.initValue );

		var spaceDiv=dojo.create('div',{style:'margin-bottom:5px'}); //create space to the next element
		
		this.domNode.appendChild(this.combo.domNode);
		this.domNode.appendChild(spaceDiv);
		
		this.inherited("postCreate",arguments);
	},
	//
	//Returns the value of the selected item
	selectedValue: function(){
		//
		// summary: this function returns the selected value.
		//
		console.debug("name: "+this.combo.value);
		console.debug("value: "+this.combo.name);
		return this.combo.value;
	},
	//
	//
	selectedValueAsJSON: function() {
		//
		//Returns the SELECTLIST entry in JSON format.
		//
		var valAsJSON = "";		
		var tempVal = new Object();
		tempVal.uniqueid=this.uniqueid;
		tempVal.value=this.combo.value;
		valAsJSON = dojo.toJson(tempVal,true);
		console.debug(" JSON value of SelectList: "+valAsJSON);
			
		return valAsJSON; 
	},
	//Returns the 'name' attribute for the item selected
	selectedName: function(){
		//
		// summary: this function returns the selected name
		//
		return this.combo.name;
	}
});