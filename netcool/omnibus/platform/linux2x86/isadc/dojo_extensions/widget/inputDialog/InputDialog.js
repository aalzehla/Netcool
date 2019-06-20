/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */
// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.inputDialog.InputDialog");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dojo.cache");
dojo.require("dijit.ProgressBar");
dojo.require("dijit.form.Form");
dojo.require("dijit.form.CheckBox");
dojo.require("dijit.form.ComboBox");
dojo.require("dijit.form.Textarea");
dojo.require("widgets.fieldTask.PlainTextFieldTask");
dojo.require("widgets.fieldTask.PromptFieldTask");
dojo.require("widgets.fieldTask.LabelFieldTask");
dojo.require("widgets.fieldTask.ControlButtons");
dojo.require("widgets.fieldTask.TextAreaFieldTask");
dojo.require("widgets.fieldTask.SelectListFieldTask");
dojo.require("widgets.fieldTask.EditableSelectListFieldTask");
dojo.require("widgets.fieldTask.FileBrowseFieldTask");
dojo.require("widgets.fieldTask.DirectoryFieldTask");
dojo.require("widgets.fieldTask.PasswordFieldTask");
dojo.require("widgets.fieldTask.AutoPDInputButtons");

dojo.require("dojo.fx");

dojo.declare("widgets.inputDialog.InputDialog", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "inputDialog/templates/InputDialogTemplate.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,

	//Title of the input Dialog, no longer used
	inputDialogTitle: '',
	
	
	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
		if(!args.title ||(args.title=null)){
			this.inputDialogTitle=' ';
         }
		console.debug("Input Dialog Constructor ...");
		
		this.inputType=args.inputType;
		  //These are the widgets
		var components = new Array();

		if(args.inputType=="dialog"){
		
		  this.okButton=args.okButton;
		  this.cancelButton=args.cancelButton;
		  this.skipButton=args.skipButton;		  
		  this.uniqueid=args.uniqueid;
		  
		  this.handle="default";
		
		  this.requiresUserInput=false;
		
		  //This is the prompt
		  this.promptVar=new widgets.fieldTask.PromptFieldTask({promptText:args.prompt, uniqueid:args.uniqueid});
	    
	    
	      //Create the Control Buttons	    
	      this.controlB= new widgets.fieldTask.ControlButtons({okButton:this.okButton, cancelButton:this.cancelButton, skipButton:this.skipButton});	
	     
	   
	      // build each component
	      dojo.forEach(args.fields, function (field, i) {
	        console.debug("Processing field: " + field.name + ", type: " + field.type);
	        var fieldType=field.type.toUpperCase();
	        switch (fieldType) {
	          case ("LABEL"):
	            console.debug("build a Label");
	            var outLabel = field.label;
	            if (field.name.match("errorLabel")) {
	            	outLabel = '<span class="ibm-error">' + field.label + '&nbsp;</span>';
	            }
	            components[i]=new widgets.fieldTask.LabelFieldTask({labelText:outLabel, uniqueid:field.uniqueid});
	            
	            break;
	            
	          case ("PLAINTEXT"):
	        	console.debug("build a Plaintext");
	            var initialValue='';
	            var width='';
	            
	            if(field.initialValue)
	            	initialValue=field.initialValue;

	            if(field.width)
	            	width=field.width;
	            
	            var initialStyle="width: "+width+"em";
	            
	            components[i]=new widgets.fieldTask.PlainTextFieldTask({plainTextLabel:field.label, initialValue:initialValue, style:initialStyle, name:field.name, uniqueid:field.uniqueid});
	            this.requiresUserInput=true;
	            break;
	            
	          case ("PASSWORD"):
	        	console.debug("build a Password");
	            var width='';//This is the default
	            
	            if(field.initialValue)
	            	initialValue=field.initialValue;

	            if(field.width)
	            	width=field.width;

	            var initialStyle="width: "+width+"em;";

		        components[i]=new widgets.fieldTask.PasswordFieldTask({passwordLabel:field.label, style:initialStyle, name:field.name, uniqueid:field.uniqueid});
		        this.requiresUserInput=true;
		        break;
		        
	          case ("SELECTLIST"):
		        console.debug("build a non editable Select List: ");		        

	            components[i]=new widgets.fieldTask.SelectListFieldTask({labelText:field.label, comboItems:field.selectStore, name:field.name, uniqueid:field.uniqueid, initValue:field.initialValue});
	            this.requiresUserInput=true;
	            	        
		        break;
		        
	          case ("TEXTAREA"):
		        console.debug("build a TextArea");
	            var width='';//This is the default
	            var height='';//This is the default
	            var initialValue='';
	            
	            if(field.initialValue)
	            	initialValue=field.initialValue;

	            if(field.width)
	            	width=field.width;

	            if(field.height)
	            	height=field.height;

	            var initialStyle="width: "+width+"em; height: "+height+" em";

	            components[i]=new widgets.fieldTask.TextAreaFieldTask({textAreaLabel:field.label,textAreaContent:initialValue, name:field.name, style:initialStyle, uniqueid:field.uniqueid});
	            this.requiresUserInput=true;
		        break;
		        
	          case ("FILEBROWSER"): 
		        console.debug("build a File Browser");
	            var initialValue='';
	            var width='';
	            
	            if(field.initialValue)
	            	initialValue=field.initialValue;

	            if(field.width && (field.width!=0) ||(field.width!='0'))
	            	width=field.width;
	            
	            var initialStyle="width: "+width+"em;";

	            components[i]=new widgets.fieldTask.FileBrowseFieldTask({fileBrowseLabel:field.label, initialValue:initialValue, style:initialStyle, uniqueid:field.uniqueid});
	            this.requiresUserInput=true;
		        break;
		        
	          case ("DIRECTORYBROWSER"): 
			        console.debug("build a Directory Browse");
		            this.requiresUserInput=true;

		            var initialValue='';
		            var width='';

		            if(field.initialValue)
		            	initialValue=field.initialValue;

		            if(field.width && (field.width!=0) ||(field.width!='0'))
		            	width=field.width;
		            
		            var initialStyle="width: "+width+"em;";
		            
	                components[i]= new widgets.fieldTask.DirectoryFieldTask({directoryBrowseLabel:field.label, initialValue:initialValue, style:initialStyle, uniqueid:field.uniqueid});
	                this.requiresUserInput=true;
	                break;

	          case ("EDITABLESELECTLIST"):
		       	console.debug("build an Editable Select List");
	            var width='';//This is the default
	            var height='';//This is the default

	            if(field.width)
	            	width=field.width;

	            if(field.height)
	            	height=field.height;

	            var initialStyle="width: "+width+"em; height: "+height+" em";

	            components[i]=new widgets.fieldTask.EditableSelectListFieldTask({labelText:field.label, comboItems:field.selectStore, style:initialStyle, name:field.name, uniqueid:field.uniqueid});
	            this.requiresUserInput=true;
	            
		        break;
		        		            
	          default:
	            console.debug("Oops! don't know how to handle a " + field.type + " yet");
	        };
	    });			    	    
		} else if(args.inputType=="autopdInput"){
			this.inputDialogTitle="";
			  //This is the prompt
			  this.promptVar=new widgets.fieldTask.PromptFieldTask({promptText:args.prompt, uniqueid:args.uniqueid, title:''});
		    			    
		      //Create the Control Buttons	    
		      this.controlB= new widgets.fieldTask.AutoPDInputButtons({options:args.options});	
		      
		}
		this.myComps = components;
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		this.inherited(arguments);
	},
	
	//When this method is called, it activates the input Dialog (meaning: it is now set to active)
	//
	setActive: function(){		
		dojo.addClass(this.domNode,"InputDialogActive");
	},
	
	//When this method is called, it desactivates the input Dialog and moves it down below.
	//
	setInactive: function() {
		dojo.removeClass(this.domNode,"InputDialogActive"); //TODO: Should be an image
		dojo.addClass(this.domNode,"InputDialogInactive");
	},
	//
	//
	getValuesAsJSON: function(action){		
		if(this.inputType=="autopdInput"){
			var response='{"action":"'+action+'", '+
                          '"uniqueid":"'+this.uniqueid +'"}';
			
			return response;
		}
		
		else if (this.inputType=="dialog"){
		
		  var header='{"action":"'+action+'", '+
		             '"uniqueid":"'+this.uniqueid+'", ';
		
		   console.debug("calculate JSON Values");
		   var responseList='"responseList":[';
		   var hasResponse=false;
		   var atLeastOneResponse=false;
		   
		   dojo.forEach(this.myComps, function (field, i) {
			 console.debug("Value of i: "+i + " type: "+field.type);			 
			 switch (field.type) {
	          case ("PLAINTEXT"):
	        	  console.debug("PLAINTEXT Fieldtask: value of i: "+i+ " type: "+field.type);
	              if(hasResponse || atLeastOneResponse) responseList+=",";
	              hasResponse=true;
	              atLeastOneResponse=true;
	              responseList+=field.selectedValueAsJSON();
	              //console.debug("JSON response from PlainText :"+field.selectedValueAsJSON());	              
	        	  break;
	          case ("PASSWORD"):	        	  
        	      console.debug("PASSWORD  Fieldtask: value of i: "+i+ " type: "+field.type);
                  if(hasResponse || atLeastOneResponse) responseList+=",";
	              hasResponse=true;
	              atLeastOneResponse=true;
                  responseList+=field.selectedValueAsJSON();
                  //console.debug("JSON response from Password fieldTask :"+field.selectedValueAsJSON());            
	        	  break;
	          
	          case ("TEXTAREA"):	        	  
    	          console.debug("TEXTAREA Fieldtask: value of i: "+i+ " type: "+field.type);
      		      if(hasResponse || atLeastOneResponse) responseList+=",";
    		      hasResponse=true;
    		      atLeastOneResponse=true;
                  responseList+=field.selectedValueAsJSON();
                  //console.debug("JSON response from TextArea fieldTask :"+field.selectedValueAsJSON());      	          
	        	  break;
	          
	          case ("SELECTLIST"):
	        	  console.debug("SELECTLIST Fieldtask: value of i: "+i+ " type: "+field.type);
        		  if(hasResponse || atLeastOneResponse) responseList+=",";
    		      hasResponse=true;
    		      atLeastOneResponse=true;
    		      responseList+=field.selectedValueAsJSON();	        	  
	        	  break;

	          case ("FILEBROWSER"):	       
	        	  console.debug("FILEBROWSER Fieldtask: value of i: "+i+ " type: "+field.type);
	        	  console.debug("Value of i: "+i + " type: "+field.type);
    		      if(hasResponse || atLeastOneResponse) responseList+=",";
    		      hasResponse=true;
    		      atLeastOneResponse=true;
    		      responseList+=field.selectedValueAsJSON();	        	  
	        	  break;

	          case ("DIRECTORYBROWSER"):
	        	  console.debug("DIRECTORYBROWSER Fieldtask: value of i: "+i+ " type: "+field.type);	        	  
    		      if(hasResponse || atLeastOneResponse) responseList+=",";
    		      hasResponse=true;
    		      atLeastOneResponse=true;
    		      responseList+=field.selectedValueAsJSON();
	        	  field.deregisterDirectory();
	        	  break;

	          case ("EDITABLESELECTLIST"):
	        	  console.debug("EDITABLESELECTLIST Fieldtask: value of i: "+i+ " type: "+field.type);
        		  if(hasResponse || atLeastOneResponse) responseList+=",";
    		      hasResponse=true;
    		      atLeastOneResponse=true;
    		      responseList+=field.selectedValueAsJSON();
	        	  break;
	        	  
	          case ("LABEL"):
	        	   console.debug("LABEL Fieldtask: value of i: "+i+ " type: "+field.type);
    		       hasResponse=false;

	        	  break;
			 }
		 });
		 
		console.debug("Response List: "+responseList);
		console.debug("Handle: "+this.handle);
		return header+responseList+"]}";
		} else console.debug("Unknow input type: "+this.inputType);
	},
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		console.debug("InputDialog:postCreate()--> "+ this.myComps.length);				
	   
	   if(this.promptVar) 
		 this.inputDialogElements.appendChild(this.promptVar.domNode);
	  
       for(i=0; i<this.myComps.length;i++){	
 	     this.inputDialogElements.appendChild(this.myComps[i].domNode);
       }

       if(this.controlB)
		  this.controlsButton.appendChild(this.controlB.domNode);
	  

       this.setActive();
     
       
       
       //OK was clicked on the Input Dialog
       //Record information about this input dialog
       //convert from Form to JSON to send to back end       
       this.handle=dojo.subscribe("inputDialogResponseProvided", function(response){
    	   console.debug("====================Input Dialog Response Provided");
    	       	   
    	   var widgetID=collectionExecution.getCurrentInputDialog();
    	   console.debug("current Input Dialog: "+widgetID);
    	       	   
    	   //TODO: I have to do this, since dojo.byId() and dijit.byId() return different things.
    	   //Check with experts, if there is a better way to do this
    	   var inputDialogDojoWg=dojo.byId(widgetID);
		   var inputDialogDijitWg=dijit.byId(widgetID); 
		   
			if(inputDialogDojoWg) {				
				dojo.fx.wipeOut({
					node:inputDialogDojoWg
				}).play();
				
			}else {
				console.debug("No input dialog ...");
			}
			
					
			var responseJSON='';
			if(inputDialogDijitWg.inputType=="dialog"){
				responseJSON=inputDialogDijitWg.getValuesAsJSON(response.buttonClicked);
				
				console.debug("JSON Return Values ... for "+ response.buttonClicked+" "+responseJSON);				
			}else if(inputDialogDijitWg.inputType=="autopdInput"){
				responseJSON=inputDialogDijitWg.getValuesAsJSON(response.buttonClicked);
				console.debug("JSON Return Values ... for "+response.buttonClicked+" "+responseJSON);
			}
			console.debug("unsubscribing "+inputDialogDijitWg.handle);				
			dojo.unsubscribe(inputDialogDijitWg.handle);
			//Completed responding to input dialog
			
			collectionExecution.submitResponse(responseJSON);
			dojo.publish("inputDialogCompleted",[{recentAction:'okClicked'}]);
       });
 
       //Cancel was clicked.
       dojo.subscribe("inputDialogCancelClicked",function(item){
    	   console.debug("input Dialog cancel Clicked");
    	   
    	   //TODO: Figure out a way to get the right ID
    	   var widgetID="widget_inputDialog_InputDialog_0";
    	   
    	   //TODO: I have to do this, since dojo.byId() and dijit.byId() return different things.
    	   //Check with experts, if there is a better way to do this
    	   var inputDialogDojoWg=dojo.byId(widgetID);
		   var inputDialogDijitWg=dijit.byId(widgetID); 
		   
			if(inputDialogDojoWg) {
				dojo.fx.slideTo({
					node:inputDialogDojoWg,
					top:300
				}).play();
			}else {
				console.debug("No input dialog ...");
			}
			
			
			//Remove the controlButtons from this table.
			dojo.query("table#controlsTable", inputDialogDojoWg).forEach(function(node,index,arr){
				console.debug("remove child ...");
				node.parentNode.removeChild(node);
			});
		
			//Change the image to another image
			//Change the stylesheet as well.
			if(inputDialogDijitWg){
				inputDialogDijitWg.setInactive();
			}else {
				console.debug("not found");
			}
       
			//Completed responding to input dialog
			//dojo.publish("inputDialogCompleted",[{recentAction:'okClicked'}]);

    	   
			//Completed responding to input dialog
			//dojo.publish("inputDialogCompleted",[{recentAction:'cancelClicked'}]);

       });
       
       dojo.subscribe("inputDialogSkipClicked",function(item){
    	   console.debug("input Dialog skip Clicked");
    	   
    	   
    	   //TODO: I have to do this, since dojo.byId() and dijit.byId() return different things.
    	   //Check with experts, if there is a better way to do this
    	   var inputDialogDojoWg=dojo.byId(widgetID);
		   var inputDialogDijitWg=dijit.byId(widgetID); 
		   
			if(inputDialogDojoWg) {
				dojo.fx.slideTo({
					node:inputDialogDojoWg,
					top:300
				}).play();
			}else {
				console.debug("No input dialog ...");
			}
			
			
			//Remove the controlButtons from this table.
			dojo.query("table#controlsTable", inputDialogDojoWg).forEach(function(node,index,arr){
				node.parentNode.removeChild(node);
			});
		
			//Change the image to another image
			//Change the stylesheet as well.
			if(inputDialogDijitWg){
				inputDialogDijitWg.setInactive();
			}else {
				console.debug("not found");
			}
       
			//Completed responding to input dialog
			//dojo.publish("inputDialogCompleted",[{recentAction:'okClicked'}]);

    	   
			//Completed responding to input dialog
			//dojo.publish("inputDialogCompleted",[{recentAction:'skipClicked'}]);

       });
       
      this.inherited("postCreate",arguments);
	}
});


