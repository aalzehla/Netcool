// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.view.SymptomSelection");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");

dojo.declare("widgets.view.SymptomSelection", [dijit._Widget, dijit._Templated ], {
	// Path to the template
	templateString: dojo.cache("widgets", "view/templates/SymptomSelection.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
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
		var helpAreaContainer = dijit.byId("helpArea");
		var helloWorldButton= new dijit.form.Button({label:'hello World'});
		
		helpAreaContainer.addChild(helloWorldButton);
		
		this.inherited("postCreate",arguments);
	}
	
});

