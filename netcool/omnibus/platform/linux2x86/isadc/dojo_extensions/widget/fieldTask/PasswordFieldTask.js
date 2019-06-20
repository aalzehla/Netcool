/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */
// dojo.provide allows pages to use all of the types declared in this resource.

dojo.provide("widgets.fieldTask.PasswordFieldTask");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.form.TextBox");

dojo.declare("widgets.fieldTask.PasswordFieldTask", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "fieldTask/templates/PasswordFieldTask.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//the type of Field Task used
	type:'PASSWORD',

	//This is the label for the password box
	passwordLabel: '',

	//This is the default name for this component
	name:'default_name',
	
	//This is the style, if any. Used to specify width and height, if those were passed from the script
    style:'',
	
	//This is the unique ID. Used to return this to the back end
	uniqueid:'',

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the Password Widget
		console.debug("PasswordFieldTask Constructor is called: ");
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
		this.inherited("postCreate",arguments);
		
		//create a div first
		var labelNode=dojo.create('label',{innerHTML:this.passwordLabel, style:"margin-bottom:5px"});		
		var spaceDiv1=dojo.create('div',{style:'margin-bottom:2px'}); //create space to the next element
		var stylePassField=this.style;
		var passwordField = new dijit.form.TextBox({type:'password',name:this.name, style:stylePassField});
		var spaceDiv=dojo.create('div',{style:'margin-bottom:8px'}); //create space to the next element
		

		//Update the main node.
	    this.containerNode.appendChild(labelNode);
	    this.containerNode.appendChild(spaceDiv1);
	    this.containerNode.appendChild(passwordField.domNode);
	    this.containerNode.appendChild(spaceDiv);
	},
	//
	//
	selectedValueAsJSON: function() {
		//
		//Returns the PASSWORD entry in JSON format.
		//
		var valAsJSON = "";
		
		dojo.query("input",this.containerNode).forEach(dojo.hitch(this,function(item){
			var tempVal = new Object();
			tempVal.uniqueid=this.uniqueid;
			tempVal.value=dijit.byId(item.id).value;
			valAsJSON = dojo.toJson(tempVal,true);
			console.debug(" JSON value of Password: "+valAsJSON);
		}));
		return valAsJSON; 
	}
});