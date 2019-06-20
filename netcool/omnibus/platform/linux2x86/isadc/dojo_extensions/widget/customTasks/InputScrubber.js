// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.customTasks.InputScrubber");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dojo.parser");

//Internationalization
dojo.require("dojo.i18n");
dojo.requireLocalization("widgets.customTasks", "metricsstrings");

dojo.declare("widgets.customTasks.InputScrubber", [dijit._Widget], {
	
	TYPE_EMAIL: "EMAIL",
	TYPE_URL: "URL",
	TYPE_IP: "IP",
	TYPE_NO_CODE: "NO_CODE",
	TYPE_PMR: "PMR",
	
	//PMR Regex - taken from AE5's TicketInputSelect
	regExpExactMatch: "^[a-zA-Z0-9]{5}[,.]{1}[a-zA-Z0-9]{3}[,.]{1}[a-zA-Z0-9]{3}$",

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
		this.inherited("postCreate",arguments);

	},

	//Validates input based on type - returns -1 if not valid, 0 if type not found, and 1 if valid
	validateInput: function (type, input){
		if (type==this.TYPE_EMAIL) {
			return this._validateEmail(input);
		}
		else if (type==this.TYPE_URL) {
			return this._validateURL(input);
			
		}
		else if (type==this.TYPE_IP){
			return this._validateIP(input);
		}
		else if (type==this.TYPE_NO_CODE) {
			return this._validateNoCode(input);
		}
		else if (type==this.TYPE_PMR){
			return this._validatePMR(input);
		}
		else {
			return 0;
		}
	},
	
	//Scrubs input to remove code
	scrubInput: function(input){
		input = input.replace("&", "&amp;");
		input = input.replace("<", "&lt;");
		input = input.replace(">", "&gt;");
		input = input.replace("\\", "&quot;");
		input = input.replace("'", "&#x27;");
		input = input.replace("/", "&#x2F;");
		return input;
	},
	
	//Validates an input to ensure it matches e-mail parameters
	_validateEmail: function(input) {
		//Need to use email regex to test.
		return 1;
	},
	
	//Validates an input to ensure it matches url parameters
	_validateURL: function(input) {
		//Need to use url regex to test.
		return 1;
	},
	
	//Validates an input to ensure it matches no-code-allowed parameters
	_validateNoCode: function(input) {
		//Need to use nocode regex to test.
		return 1;
	},
	
	//Validates an input to ensure it matches IP parameters
	_validateIP: function(input) {
		//Need to use ip regex to test. (should we test for IP4 and IP6?)
		return 1;
	},
	
	//Validates an input to ensure it matches PMR parameters
	_validatePMR: function(input) {
		if (new RegExp(this.regExpExactMatch).test(input)) {
			return 1;
		}
		else {
			return -1;
		}
	}

});