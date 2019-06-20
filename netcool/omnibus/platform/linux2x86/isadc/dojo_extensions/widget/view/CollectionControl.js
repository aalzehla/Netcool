// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.view.CollectionControl");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.form.Button");
//Internationalization
dojo.require("dojo.i18n");
dojo.requireLocalization("widgets.view", "viewstrings");

dojo.declare("widgets.view.CollectionControl", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "view/templates/CollectionControl.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//
	startButton:true,
	
	//
	startVisible:true,

	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		console.debug("Collection Control Constructor is called: ");
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		
		//Point to the applet NLS Strings
		var _nlsResources=dojo.i18n.getLocalization("widgets.view","viewstrings");

		dojo.mixin(this,_nlsResources);
		this.inherited(arguments);
	},
	
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		console.debug(" Control Buttons postCreate is called..."+this.okButton);	

		var startButtonVisible='';
		
		if(this.startVisible)
		  startButtonVisible='';
		else
		  startButtonVisible='display:none';
		
		var startButtonNode= new dijit.form.Button({
			id:'startCollection',
			label:this.startButtonLabel,
			onClick:this._okClicked, 
			disabled:!this.startButton,
			style:startButtonVisible,
			baseClass:'isa-ibm-btn-arrow-pri'});
		this.domNode.appendChild(startButtonNode.domNode);

		// create but do not display
		var restartButtonNode= new dijit.form.Button({
			id:'restartCollection',
			label:this.restartButtonLabel,
			onClick:this._restartClicked, 
			style:'display:none',
			baseClass:'isa-ibm-btn-refresh-sec'});
		this.domNode.appendChild(restartButtonNode.domNode);

		// create but do not display
		var restartUploadButtonNode= new dijit.form.Button({
			id:'restartUpload',
			label:this.restartUploadButtonLabel,
			onClick:this._restartUploadClicked, 
			style:'display:none',
			baseClass:'isa-ibm-btn-undo-sec'});
		this.domNode.appendChild(restartUploadButtonNode.domNode);
		

		// create but do not display
		var cancelCurrentActionButtonNode= new dijit.form.Button({
			id:'cancelCurrentAction',
			label:this.cancelCurrentActionButtonLabel,
			onClick:this._cancelCurrentActionClicked, 
			style:'display:none',
			baseClass:'isa-ibm-btn-refresh-sec'});
		this.domNode.appendChild(cancelCurrentActionButtonNode.domNode);
		
		//When a valid item is clicked, 'startButton' is enabled.
		dojo.subscribe("treeItemSelected",function(item){

			//sets the start button ...
  	        startButtonNode.set('disabled',!item.validSelection);
  	        
  	        //functions have already been attached...
		});
		
		//When selection completes, or canceled enable the restart button
		dojo.subscribe("EnableRestart",function(item){
			dojo.publish("HideUploadInterface", []);
			console.debug("show restart button");
  	        restartButtonNode.set('style','display:inline-block;');
		});
		
		//When selection completes, or canceled enable the restart button
		dojo.subscribe("EnableUploadRestart",function(item){
			dojo.publish("HideUploadInterface", []);
			restartUploadButtonNode.set('style','display:inline-block;');
		});
		
		//When upload is being performed, enable the cancel button
		dojo.subscribe("EnableCancel",function(item){
			dojo.publish("HideUploadInterface", []);
			cancelCurrentActionButtonNode.set('style','display:inline-block;');
		});
		
		//Allow the cancel button to be hidden besides a mouseclick
		dojo.subscribe("HideCancel",function(item){
			cancelCurrentActionButtonNode.set('style','display:none;');
		});
		
		this.inherited("postCreate",arguments);
	},
	//OK button was clicked.
	//The collection can start
	_okClicked: function(/*event*/ e){
		
		var bar = dojo.byId("collectionProgress");
		dojo.query(".dijitProgressBarTile", bar).removeClass("successBar");
		dojo.query(".dijitProgressBarTile", bar).removeClass("errorBar");
		dojo.query(".dijitProgressBarTile", bar).removeClass("warningBar");
		
		//Disabling the startCollection Button
		//dijit.byId("startCollection").set("disabled",true);
		//HIDE start button once started.
		dijit.byId("startCollection").domNode.style.display = 'none';
		console.debug("collection started ...");	
		//Publish the Start Collection Event
		dojo.publish("collectionStarted",[{'script':true}]);	
		document.getElementById("statusMessageID").className = "progress";
	},
	//Restart button has been clicked.
	//Restarting the Web Collector
	_restartClicked: function(/*event*/ e){

		console.debug("restart...");
		var bar = dojo.byId("collectionProgress");
		dojo.query(".dijitProgressBarTile", bar).removeClass("successBar");
		dojo.query(".dijitProgressBarTile", bar).removeClass("errorBar");
		dojo.query(".dijitProgressBarTile", bar).removeClass("warningBar");
		
		//hide restart button
		dijit.byId("restartCollection").domNode.style.display = 'none';
		if (dijit.byId("restartUpload")) {
			//hide restart button
			dijit.byId("restartUpload").domNode.style.display = 'none';
		}

		//show the start button
		dijit.byId("startCollection").domNode.style.display = 'block';

		//publish restart event
		dojo.publish("collectionRestart", [{'restart':true}]);
	},
	//Restart button has been clicked.
	//Restarting the Web Collector
	_restartUploadClicked: function(/*event*/ e){
		
		//hide the restart upload button
		dijit.byId("restartUpload").domNode.style.display = 'none';
		if (dijit.byId("restartCollection")) {
			//hide restart button
			dijit.byId("restartCollection").domNode.style.display = 'none';
		}
		
		//publish restart event
		dojo.publish("ShowUploadInterface", []);
	},
	
	//Show the cancel button, then cancel whatever action is currently being undertaken
	_cancelCurrentActionClicked: function() {
		//hide the restart upload button
		dijit.byId("cancelCurrentAction").domNode.style.display = 'none';
		
		//publish restart event
		dojo.publish("CancelCurrentAction", []);
	},
	
	//Hide buttons that are present
	_hideRestartButtons: function() {

	}
});