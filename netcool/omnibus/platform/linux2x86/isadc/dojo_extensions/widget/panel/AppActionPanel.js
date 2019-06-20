/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */
// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.panel.AppActionPanel");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.Menu");
dojo.require("dijit.MenuBar");
dojo.require("dijit.MenuItem");
dojo.require("dijit.PopupMenuBarItem");
dojo.require("dijit.PopupMenuItem");
dojo.require("dijit.MenuBarItem");
dojo.require("dijit.form.DropDownButton");
dojo.require("dijit.Dialog");
dojo.require("dojo.i18n");

//Loading of nls variables
dojo.requireLocalization("widgets.panel", "panelstrings");

dojo.declare("widgets.panel.AppActionPanel", [dijit._Widget, dijit._Templated ], {
	// Path to the template
	templateString: dojo.cache("widgets", "panel/templates/AppActionPanel.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//Which protocol is being used? Defaults to File protocol
	execEnvIsFile:true,
	
	//Production or Development Environment? Defaults to production
	execEnvISADevEnv:false,


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
		
		//do the nls mixin here
		var _nlsResources=dojo.i18n.getLocalization("widgets.panel","panelstrings");
		
		dojo.mixin(this,_nlsResources);

		this.inherited(arguments);
	},
	
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		this.inherited("postCreate",arguments);		
		
		  var pMenuBar;
          
              pMenuBar = new dijit.MenuBar({});

              //Feedback
              pMenuBar.addChild(new dijit.MenuBarItem({
                  label: this.feedbackMenu,
                  onClick:dojo.hitch(this,this.displayFeedback)
                  }));

              //Help
              var pSubMenu2 = new dijit.Menu({});
              pSubMenu2.addChild(new dijit.MenuItem({
                  label: this.helpContent,
                  onClick: dojo.hitch(this,this.displayHelpContent)
              }));
              pSubMenu2.addChild(new dijit.MenuItem({
                  label: this.aboutISADC,
                  onClick: dojo.hitch(this,this.displayAbout)
              }));
              pMenuBar.addChild(new dijit.PopupMenuBarItem({
                  label: this.helpMenu,
                  popup: pSubMenu2
              }));
              pMenuBar.startup();
              this.applicationActionPanel.appendChild(pMenuBar.domNode);
	},
	//
	//Displays the information about the Version Information
	displayAbout: function() {
		//
		//summary: This function displays the About. The information about the about is read from the applet
		//

		var aboutMessage="";
		
		if(!this.execEnvISADevEnv){ //Production, the version file exists
		  var loadedApplet=dijit.byId("loadingAppletID");	
	      var versionInformation = loadedApplet.getISAVersion();
	     
	      console.debug("Version Information: " + versionInformation);
	    
	      var jsonVersionInformation=dojo.fromJson(versionInformation); 
	    	     
	  	  dojo.forEach(jsonVersionInformation.items, function(fields, i){
	  		 aboutMessage +=fields.key + ":  "+fields.value + "<br>";
	   	     console.debug("key:"+fields.key + " value: "+fields.value);
	   	   });
		} else { //Version files don't exist.
			aboutMessage="No Version Information currently available in Development Environment. ";
		}
	     var dialog= new dijit.Dialog({
			title: this.aboutDialogTitle,
			content: aboutMessage,
			draggable:false,
			style: {
				width: "450px"
			}
		});
		dialog.show();
	},
	//
	// Opens the Help window and displays help information
	displayHelpContent: function(){
		//
		//Summary: This will open the Help in its own Window.
		//
		
		var url="";
		var locale=this._calculateLocale();
		
		var relativeFilePath="util/help/html/"+locale+"isadcHelp.html";
		var nameInformation="_blank";
		var specs="menubar=false,scrollbars=yes";
		
		if(this.execEnvISADevEnv) {
			if(this.execEnvIsFile){ //File protocol
				url = getBaseLocation() + "../../ISALite/"+relativeFilePath;
				console.debug("Development Environment and File Protocol. URL="+url);
			} else { //http protocol
				url = getBaseLocation() + ""+relativeFilePath;
				console.debug("Development Environment and HTTP Protocol. URL="+url);
			}			
		} else { //Production Environment
			if(this.execEnvIsFile){ //file protocol
				url =getBaseLocation() +  ""+relativeFilePath;
				console.debug("Production Environment and file Protocol. URL="+url);
			} else { //http protocol
				url =getBaseLocation() +  ""+relativeFilePath;
				console.debug("Production Environment and http Protocol. URL="+url);
			}						
		}
		window.open(url,nameInformation,specs);
	},
	//
	//
	displayFeedback: function() {
		//
		// Summary: Displays the location, where we would like feedback
		//
		console.debug("display feedback clicked ...");
		if (dijit.byId('FeedbackDlgID') == null) {
			var dlgContents = dojo.create('div', {
				style: {textAlign: "left"},
				innerHTML: '<div>'+this.feedbackDialogMessage+'<br /><br /></div>'});
	
			var continueBtn= new dijit.form.Button({label:this.buttonContinueLabel,onClick:dojo.hitch(this,this._continueClicked),baseClass:'isa-ibm-btn-arrow-pri'});
			var cancelBtn= new dijit.form.Button({label:this.buttonCancelLabel,onClick:this._cancelClicked,baseClass:'isa-ibm-btn-cancel-sec'});
			dlgContents.appendChild(continueBtn.domNode);
			dlgContents.appendChild(cancelBtn.domNode);			

			var feedbackDialog = new dijit.Dialog({
				id: 'FeedbackDlgID',
		    	title: this.feedbackDialogTitle,
		    	content: dlgContents,
		    	draggable:false,
		    	style: { 
		    		width: "400px"
		    	}
		    });	
		    feedbackDialog.show();
		} else {
			dijit.byId('FeedbackDlgID').show();
		}

	},
	//
	// sets environment variables.
	setEnvironmentVariables: function(protocol,prodOrDev){	
		//
		//sumary: Makes sure all environment variables have been set up properly to calculate the location of the help acurately
		//
		this.execEnvISADevEnv=prodOrDev;
		this.execEnvIsFile=protocol;
	},
	
	_continueClicked: function(/*event*/ e){		
		console.debug("Continue clicked");	
		dijit.byId('FeedbackDlgID').hide();
		window.open("http://www.ibm.com/developerworks/forums/post!default.jspa?forumID=935&subject="+this.feedbackPostSubject+"&body="+this.feedbackPostMessage);
	},
	
	_cancelClicked: function(/*event*/ e){		
		console.debug("Cancel clicked");	
		dijit.byId('FeedbackDlgID').hide();
	},
	//
	// Returns the locale 
	//
	_calculateLocale: function(){
		//
		//Summary: 
		// For Brazilian Portuguese, Simplified Chinese and Traditional Chinese, use lang_Country.
		// For Others, try to use language only.
		// If we are using "zh", return zh-cn
		//
		var currentLocale=dojo.locale;
		var lowerCaseLocale=currentLocale.toLowerCase();
		console.debug("current Locale: "+currentLocale);
		
		var localeLength=currentLocale.length;
		var returnedLocale="";		
		
		if(localeLength==2){ //Only the language as specified.
			if(this._supportedLocale(lowerCaseLocale)){
				returnedLocale=lowerCaseLocale+"/";
			}else if(lowerCaseLocale=="en"){
				console.debug("Locale: "+lowerCaseLocale);
				returnedLocale="";				
			} else if(lowerCaseLocale=="zh"){
					returnedLocale="zh-cn/";
				}		
		}else if(localeLength==5){ //check for zh-CN, zh-TW and pr-BR and return 5 chars. else, return 2 positions
			if(lowerCaseLocale=="zh-cn" || lowerCaseLocale=="zh-tw" || lowerCaseLocale=="pt-br") 
				returnedLocale=lowerCaseLocale+"/";
			else {
			  var langLocale=lowerCaseLocale.substring(0,2);			  
			  
			  if(this._supportedLocale(langLocale)){
					returnedLocale=langLocale+"/";
				}else if(langLocale=="en"){
					console.debug("Locale: "+langLocale);
					returnedLocale="";				
			}
		  }
		}
		console.debug("Returned location: "+returnedLocale);
		return returnedLocale;
	  
	},
	//
	//List of the languages for which we provide translation
	//
	_supportedLocale: function(entry ) {
		if(entry=="cs"||entry=="de"||entry=="es"||entry=="fr"||entry=="hu"||entry=="it"||entry=="ja"||entry=="ko"||entry=="pl"||entry=="ro"||entry=="ru") return true;
		return false;
	}

});