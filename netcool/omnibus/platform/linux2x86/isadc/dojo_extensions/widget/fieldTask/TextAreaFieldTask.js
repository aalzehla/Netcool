/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */
// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.fieldTask.TextAreaFieldTask");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.form.Textarea");

dojo.declare("widgets.fieldTask.TextAreaFieldTask", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "fieldTask/templates/TextAreaFieldTask.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//type This is used to know the type of the fieldTask
	type:'TEXTAREA',
	
	//This is the text area label
	textAreaLabel: '',
	
	//This is the content of the Text Area
	textAreaContent: '',
	
	//This is the style, if any. Used to specify width and height, if those were passed from the script
    style:'',
    
    //Passed to the html template.
    name:'default',
    
    //The uniqueID. used when returning data to the backend
    uniqueid:'',

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the TextArea Widget
		console.debug("TextAreaFieldTask Constructor is called: ");
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
	postCreate: function() {
		console.debug(" postCreate is called...");		
		this.inherited("postCreate",arguments);
	},
	//  
	//
	selectedValue: function(){
		//  
		//Summary: This function returns the selected value
		//
		 //dojo.query("textarea",this.domNode).forEach(function(item){
	     //   	responseList+="{'value':'"+dijit.byId(item.id).value+"', 'uniqueid':'"+field.uniqueid+"'},";
		 //       console.debug("Item: "+item.id + " value: "+dijit.byId(item.id).value + " uniqueid: "+field.uniqueid);
	     //     });
		//return ;
		//Currently not implemented. Code Quality improvement task
	},
	//
	//
	selectedValueAsJSON: function() {
		//
		//Returns the TEXTAREA entry in JSON format.
		//
		var valAsJSON = "";
		
		dojo.query("textarea",this.domNode).forEach(dojo.hitch(this,function(item){
			var tempVal = new Object();
			tempVal.uniqueid=this.uniqueid;
			tempVal.value=dijit.byId(item.id).value;
			valAsJSON = dojo.toJson(tempVal,true);
			console.debug(" JSON value of TextArea: "+valAsJSON);
		}));
		return valAsJSON; 
	}
	
	
});