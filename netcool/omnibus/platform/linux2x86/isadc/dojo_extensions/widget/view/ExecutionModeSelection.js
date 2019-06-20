/*
  (C) COPYRIGHT International Business Machines Corp., 2011. 
   All Rights Reserved * Licensed Materials - Property of IBM 
 */
// dojo.provide allows pages to use all of the types declared in this resource.

dojo.provide("widgets.view.ExecutionModeSelection");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dijit.layout.ContentPane");
dojo.require("dijit.form.Button");
dojo.require("dijit.form.CheckBox");
dojo.require("dojo.data.ItemFileReadStore");
dojo.require("dijit.form.RadioButton");
dojo.require("dijit.tree.ForestStoreModel");
dojo.require("dijit.Tooltip");
dojo.require("dijit.form.FilteringSelect");
dojo.require("dijit.layout.ContentPane");
dojo.require("widgets.panel.AppActionPanel");
//Internationalization
dojo.require("dojo.i18n");
dojo.requireLocalization("widgets.view", "viewstrings");

dojo.declare("widgets.view.ExecutionModeSelection", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "view/templates/ExecutionModeSelection.html"),

	// Set this to true if your widget contains other widgets
	widgetsInTemplate : true,
	
	//product id
	productId:'',
	
	//Component ID
	componentId:'',
	
	//Product version. The version of the product (i.e. for WebSphere 8.5 it will be 8.5)
	productIDVersion:'',
	
	//Component Release
	componentRelease:'',
	
	//product Taxonomy
	productTaxonomy:'',
	
	//CollectorScriptsVersion. The version of the data collector scripts (i.e.: for System Collector 2.0.1 it will be 2.0.1)
	collectorScriptsVersion:'',
	
	//product Script ID (i.e.: Network Collector)
	productScriptID:'',
	
	//Which protocol is being used? Defaults to File protocol
	execEnvIsFile:true,
	
	//Production or Development Environment? Defaults to production
	execEnvISADevEnv:false,
	
	//Location of the master.json file
	masterJSONURL:'',
	
	//PMR Number
	pmrNumber:'',
	
	//Used to determine is applet has loaded successfully
	_isAppletLoaded:true,
	
	//Base Location
	baseLocation:"./",


	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		// summary: Constructor for the search widget. It allows specifying of attributes.
				
		//Unique IDs (could be done better)
		this.localSelectionID="localSelectionID";
		this.remoteSelectionID="remoteSelectionID";
		this.startCollectionID='';
		this.downloadCollectorID='';
		
		//Selected taxonomy		
		this.selectedTaxonomy=this.productTaxonomy;
		
		//Selected version of data collector scripts
		this.selectedVersion='';
		
		//Readable label
		this.selectedName='';
		
		this.baseLocation=getBaseLocation();
		//unique ID created
		this.buttonsCreated=false;
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		//Point to the applet NLS Strings
		var _nlsResources=dojo.i18n.getLocalization("widgets.view","viewstrings");

		dojo.mixin(this,_nlsResources);
		console.debug("Master JSON URL: "+this.masterJSONURL);
		this.inherited(arguments);
	},
	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		this.inherited("postCreate",arguments);
		
		//Parameters
		this._printParameters();

		//Place a label for simple introductory text to let users know what the application is
		var introNode=dojo.create('div',{style:{margin: "-10px 0 0 10px"}
		});
		
		var par=dojo.create('p');
		var header = dojo.create('H2',{innerHTML:this.introText});
		dojo.addClass(header,"introClass");
		par.appendChild(header);		
		introNode.appendChild(par);
		
        this.productSelection.appendChild(introNode);	
        //this.productSelection.appendChild(part2);	
		
        var baseURLForMasterJSON="./";
        //Set the base location based on the protocol(file, http) and the environment (prod, dev)
        if(this.masterJSONURL=='') { //No masterjson.url passed 
            baseURLForMasterJSON="./";
        
          if(!this.execEnvIsFile){ //http protocol 
            baseURLForMasterJSON="../../";	
          }else {
        	
         }
        }
        console.debug("Base Location for  master.json: "+baseURLForMasterJSON);
		//Product Selection is only needed in the http protocol.		
		if(!this.execEnvIsFile){ //http protocol, come here ...
			
			//the master JSON File
	        if(this.masterJSONURL==''){ //if a URL for the master.json file wasn't specified, try to find one
	          this.masterJSONURL=baseURLForMasterJSON+"services/master.json";
	        
	          //location of master.json varies, depending on Production or DevEnvironment
	          if(!this.execEnvISADevEnv){
	        	 this.masterJSONURL=baseURLForMasterJSON+"../../../master.json"; 
	          }
	        }
	    	try {		
	    		var deferred=dojo.xhrGet({
	    			url:this.masterJSONURL,
	    			handleAs:"json",
	    			preventCache:true,
	    			sync:true,
	    			load: dojo.hitch(this,function(response){
	    				//Create the FileReadStore	
	    				console.debug("info read ..."+response);
	    			    this.storeS=new dojo.data.ItemFileReadStore({
	    				    	data:{items:response.items}
	    				});	    				
	    			}), 
	    			error: function(response){
	    				console.debug(" Error message=" +response);
	    			}
	    		});
	    	}catch(e){
	    		console.debug("An exception was thrown while reading the prodinfo.json file from location: ");		
	    	 }
	    		    	
		    //Taxonomy was passed. Check to see if it is also in the Store.
			var productFound=false;					

			
			if(dojo.trim(this.productTaxonomy)!=''){ //taxonomy was passed, give it the highest priority
				console.debug("product Taxonomy was passed on the URL ..."+this.productTaxonomy + ". Find the displayed String...");
			 
				this.storeS.fetch({ query:{taxonomy:this.productTaxonomy}, 
	                     onBegin: function(total){ console.debug("There are ", total, " items in this store."); },
	                     onComplete: dojo.hitch(this,function(items){
	                       if(items.length>1){
	                    	   console.debug(" More than one product was found with the same Taxonomy. "+items);
	                    	   console.debug(" A possible error in the master.json file. "+this.masterJSONURL);
	                       }else
	                         for (var i = 0; i < items.length; i++) {
	                           this.selectedVersion=items[i].version;
	                           this.selectedName=items[i].name;
	                           this.selectedTaxonomy=items[i].taxonomy;
	                           
	                           productFound=true;
	                           
	                           //CollectorScript version is not required. But if passed, it has to match
	                           if(dojo.trim(this.collectorScriptsVersion)!='') { //A collectorscript version was passed.
	                             if(!(this.collectorScriptsVersion==items[i].version)){
	                        	   console.debug("The version passed does not match the supported versions");
	                        	   productFound=false;
	                             }
	                           }
	                           
	                           if(productFound){
		                           this.selectedVersion=items[i].version;
	                           }
	                           
	                           console.debug("items returned Taxonomy:'"+items[i].taxonomy + "'  Data Collector Scripts Version:'" + items[i].version + "'  Name:'" + items[i].name+"'");
	                         }
	                     }),
	                     onError: function(){
	                    	 console.debug("An error occured while searching the store ..."+this.masterJSONURL);
	                     }});						
			} else if(this.productId!=''){ //A product ID was used				
				console.debug("A product ID was used: "+this.productId);
				var searchQuery='*'+this.productId+'*';
				
				console.debug("The search Query is: "+searchQuery);
				
				this.storeS.fetch({ query:{prodIds:searchQuery}, 
                    onBegin: function(total){ 
                    	console.debug("There are ", total, " matching items in this store."); 
                    	},
                    	
                    onComplete: dojo.hitch(this,function(items){
                      console.debug(" Number of matches found in the master.json "+items.length);
                      if(items.length>1){
                    	 console.debug(" The number of matches found is greater than one. master.json");
                      }
                      
                      for (var i = 0; i < items.length; i++) { //See if we can match the URL with the products in the master.json file
                    	 var item=items[i];
                    	 var matchingProducts=item.prodIds;
                    	 
                    	 console.debug("Matching IDs="+matchingProducts);
                    	 
                 		 var numberOfItems=item.PROD_DATA.length;
                 		 console.debug("Matching entries="+item.PROD_DATA.length);
                 		
                 		 //Find the proper match in the product Data and the component Data
                 		 //version used here represents the version that goes with the product ID (similar to release version)
                 		 //This is contrary to the data collector scripts versions
                 		 for(var it=0;it<numberOfItems;it++){
                 			 var product = item.PROD_DATA[it];
                 			 if(product.prodId==this.productId){
                 				var matchesVersion = this._matchesProductVersion(product);
                 				
                 				if(matchesVersion){ //Make sure the product Version matches.
                 					var matchesComponentRelease=this._matchesComponentIdAndRelease(product.COMP_DATA);
                 					if(matchesComponentRelease){
                 						console.debug(" Matched Component and Release");
                 						productFound=true;
                 						break;
                 					}else {
                 						console.debug("Component/Release combination don't match... ");
                 					}
                 				}
                 			 }
                 		 }
                 		 
                 		 if(productFound){ //Product was found.
                            this.selectedVersion=item.version;
                            this.selectedName=item.name;
                            this.selectedTaxonomy=item.taxonomy;
                            this.selectedProdId=this.productId;                            
                            console.debug("items returned "+item.taxonomy + " Data Collector Scripts Version: " + item.version + " Name: " + item.name + " product ID="+this.productId);
                            break;
                 		 }
                       }
                    }),
                    onError: function(){
                   	 console.debug("An error occured while searching the store ...");
                    }});						

			} else {
				console.debug("Neither Taxonomy nor Product ID were entered. Defaulting to FilteringSelect widget. ");
			}

			if(productFound)
			  console.debug("A valid combination of (ProductId,productIDVersion,Component,Release) was found "+productFound);
			
			//The product wasn't found.
			if(!productFound){ //no product Taxonomy, create the FilteringSelect widget
				  console.debug("No valid match for the combination of (ProductId,productVersion,Component,Release) was found. Will display all in combo box");
							
		        
		        //Re-initialize the store. doesn't work when I re-use the previous store
			    this.storeS=new dojo.data.ItemFileReadStore({
			    	url:this.masterJSONURL,
			    	hierarchical:false
			     });	  
			    
			    //Use FilteringSelect	
		        this.productSelectionsNode=new dijit.form.FilteringSelect({
		          store:this.storeS,
		          name:'name',
		          autoComplete: true,		          
		          style: "width: 300px;",
		          required: true,
		          value:' ',			          
		          invalidMessage:this.invalidSelectionMessage,
		          onChange:dojo.hitch(this, this._changeSelected)		    
		          });
		        

				//Place the label, only if there no taxonomy
				var node1=dojo.create('div',{style:{margin:"10px 0 0 0"}});
				var needToCollectForLabel= dojo.create('label',{innerHTML:this.selectProduct,'for':this.productSelectionsNode.id});
				node1.appendChild(needToCollectForLabel);

				//Add the label "Make a selection below ... "
				var part2=dojo.create('p');
				var selectionText = dojo.create('H2',{innerHTML:this.selectionOptionsText});
				dojo.addClass(selectionText,"introClass");
				part2.appendChild(selectionText);		
				this.productSelection.appendChild(part2);	

				//Add the label "i need to collect for:" on the DOM
				this.productSelection.appendChild(node1);	

				//Add the roleNode to the DOM	 (removed)	        		        
		        this.productSelection.appendChild(this.productSelectionsNode.domNode);		        
		        
		        this.createButtonsOnStartup=false;
			}else { //The product was found. Display the label
				//Place the label			
				var node1=dojo.create('div',{style:{margin:'30px 0 0 0'},innerHTML:this.selectedProductLabel+" <b>"+this.selectedName+"</b>"});

				this.productSelection.appendChild(node1);				
		        this.createButtonsOnStartup=true;
			}			
		}			
	},	
	//
	//
	getBaseLocation: function(){
		return this.baseLocation;
	},
	startup: function(){
		//
		//summary: Widget startup and initialization
		//
        //Enable the radio buttons right away ...
        if( this.createButtonsOnStartup)
        	this._createRadioButtons();		
	},
	// This function is triggered, when the focus is lost by the FilteringSelect.
	//
	_changeSelected: function(){
	  // This function is  triggered upon lost of focus by the FilteringSelect
	  // First, the remaining parameters for the selection are picked up.
	  // Then the radio buttons are created.		
	  console.debug("blur Selected ");
	
	  //Only create radio buttons, when valid selection has been made
	  if(this.productSelectionsNode.isValid()) {
	    //Radio button to select local versus Remote
	    console.debug("Taxonomy of Item Selected: "+this.productSelectionsNode.value);
	    this.selectedTaxonomy=this.productSelectionsNode.value;
	  
	    //Get the version and the label of the selected Item
        this.storeS.fetch({ query:{taxonomy:this.selectedTaxonomy}, 
          onBegin: dojo.hitch(this, function(total){ 
        	  console.log("There are ", total, " items in this store that meet the query string."); 
        	  }),
          onComplete: dojo.hitch(this,function(items){
            for (var i = 0; i < items.length; i++) {
              console.debug("version of item returned "+items[i].version);
              this.selectedVersion=items[i].version;
              this.selectedName=items[i].name;
            }
          }) 
       }); 

      //Create the Radio Buttons
      this._createRadioButtons();
	  }
	},
	//
	//
	//
	_createRadioButtons: function(){
		//
		// summary:
		//    This function creates and manages the radio buttons for the selection 
		//    whether to run remote of local
		//
		if(this.buttonsCreated) {
			var wrapperDiv = dojo.byId("wrapperDiv");
			if (wrapperDiv) {
				dojo.destroy(wrapperDiv);
			}
		}
		
		console.debug(" Creating the radio buttons ...");

		var wrapperDiv = dojo.create('div',{id: "wrapperDiv", style:{margin:"30px 0 0 0"}},  this.productSelection);

		var fieldSet1 = dojo.create('fieldset');
		var legend1= dojo.create('legend',{innerHTML:this.radioButtonLabel});

		fieldSet1.appendChild(legend1);
		
		var option1Div = dojo.create('div',{style:{marginTop:"5px"}});
		var remoteRadioButton= new dijit.form.RadioButton(
				{ 	checked:false,
					value: '',
					name: 'group1'
				});
		dojo.connect(remoteRadioButton.domNode,"onclick",this,dojo.hitch(this._remoteSelected));

		option1Div.appendChild(remoteRadioButton.domNode);
		

		//Add the label
		var option1Label=dojo.create('label',{innerHTML:this.remoteSelectionLabel,'for':remoteRadioButton.id});
		option1Div.appendChild(option1Label);

		//Add the info image
		var option1Help=dojo.create('span',{id:'option1Help'});
		var whiteBkgImage1="'"+getBaseLocation()+'ibm_com/images/v16/t/i_whitebkground.jpg'+"'";
		option1Help.innerHTML="<img src="+whiteBkgImage1+"style='vertical-align:bottom'alt='" +this.tooltipLabelRemoteAlt+ "'>";

		option1Div.appendChild(option1Help);
		//wrapperDiv.appendChild(option1Div);
        fieldSet1.appendChild(option1Div);

		var option2Div = dojo.create('div',{style:{marginTop:"5px"}});

		//Second radio button in the same group
		var localRadioButton= new dijit.form.RadioButton(
				{   checked:false,
					value: '',
					name:'group1'} 
		);
		dojo.connect(localRadioButton.domNode,"onclick",this,dojo.hitch(this._localSelected));
		
		option2Div.appendChild(localRadioButton.domNode);

		//Add the label
		var option2Label=dojo.create('label',{innerHTML:this.localSelectionLabel,'for':localRadioButton.id});
		option2Div.appendChild(option2Label);

		//Add the info image
		var option2Help=dojo.create('span',{id: 'option2Help'});
		var whiteBkgImage2="'"+getBaseLocation()+'ibm_com/images/v16/t/i_whitebkground.jpg'+"'";
		option2Help.innerHTML="<img src="+whiteBkgImage2+"style='vertical-align:bottom'alt='" +this.tooltipLabelLocalAlt+ "'>";

		//option2Help.innerHTML="<img src='ibm_com/images/v16/t/i_whitebkground.jpg' style='vertical-align:bottom' alt='" +this.tooltipLabelLocalAlt+ "'>";
		option2Div.appendChild(option2Help);
		fieldSet1.appendChild(option2Div);
		
		wrapperDiv.appendChild(fieldSet1);
		//Create the tooltip (Needs to be attached to a node already in the DOM
		var toolTipRemote= new dijit.Tooltip({connectId:[option1Help.id],label:this.tooltipLabelRemote});

		//Create the tooltip
		var toolTipLocal= new dijit.Tooltip({connectId:[option2Help.id],label:this.tooltipLabelLocal});

		this.buttonsCreated=true;

	},
	//User has selected to run Download Data Collection.
	_localSelected: function(){
		//
		// summary:
		//   User has selected to download Data collector
		//
		console.debug("Download data collector to run locally...");
		
		var localSelection=dojo.byId(this.localSelectionID);
		var remoteSelection=dojo.byId(this.remoteSelectionID);
		
		if(localSelection)			
			dojo.destroy(localSelection);
		
		if(remoteSelection)			
			dojo.destroy(remoteSelection);
		
		//create the parent div
		var parentLicense=dojo.create("div",{id:this.localSelectionID,style:{margin:'30px 0 0 0'}});
							
		//create the checkbox
        var licenseTermCheckBox= new dijit.form.CheckBox({});
        
		//Add the license term label       
        var agreeLicenseTermsLabel=this.agreeLicenseTerms;
        var acceptLicenseTermText=agreeLicenseTermsLabel;
		var licenseTermLabel=dojo.create('label',{innerHTML:acceptLicenseTermText,'for':licenseTermCheckBox.id});

		//assistive technology. Instructions to navigate to next button
		var instructions1Div=dojo.create('div',{id:"instructions1",role:"tooltip","aria-hidden":'true','class':'hiddenInputClass',innerHTML:this.pressTabKeyToNavigateRemote}); 
        //create the label holding the license term url
        var readLicenseTermsLabel=this.readLicenseTerms; 		
        var pReadLicenseTermURL = dojo.create('p',{'class':'ibm-ind-link'});
        var readLicenseTermURL = dojo.create('a',{href:'#',innerHTML:readLicenseTermsLabel,'class':'ibm-forward-link','aria-describedby':instructions1Div.id},pReadLicenseTermURL);
        dojo.connect(readLicenseTermURL,'onclick',this,this._showLicense);
        
        //Add the Windows downloadNow Button
        var downloadWinNowText=this.downloadWinNow;
        var downloadWinNowButton = new dijit.form.Button({label:downloadWinNowText,
        	                                              disabled:true,
        	                                              onClick:dojo.hitch(this,this._downloadWinWebCollector),
        	                                              baseClass:'isa-ibm-btn-download-sec'});        
        this.downloadWinCollectorID=downloadWinNowButton.id;

        //Add the Linux downloadNow Button
        var downloadLinuxNowText=this.downloadLinuxNow;
        var downloadLinuxNowButton = new dijit.form.Button({label:downloadLinuxNowText,
                                                            disabled:true,
                                                            onClick:dojo.hitch(this,this._downloadLinuxWebCollector),
                                                            baseClass:'isa-ibm-btn-download-sec'});        
        this.downloadLinuxCollectorID=downloadLinuxNowButton.id;

        //connect event to checkbox created above
        dojo.connect(licenseTermCheckBox.domNode,"onclick",this,
        		dojo.hitch(function(event){
    	          console.debug("License  local selected ...");			          	    
    	          dijit.byId(this.downloadWinCollectorID).set('disabled',!event.target.checked);
    	          dijit.byId(this.downloadLinuxCollectorID).set('disabled',!event.target.checked);
    	          
        }));

        //Put all the pieces together
        parentLicense.appendChild(pReadLicenseTermURL);
        parentLicense.appendChild(licenseTermCheckBox.domNode);        
        parentLicense.appendChild(licenseTermLabel);           
        parentLicense.appendChild(instructions1Div);
        var buttonDiv = dojo.create('div',{style:{margin:'20px 0 0 0'}});
        buttonDiv.appendChild(downloadWinNowButton.domNode); //disabled at first ...
        buttonDiv.appendChild(downloadLinuxNowButton.domNode); //disabled at first ...
        parentLicense.appendChild(buttonDiv);
        
        var wrapperDiv = dojo.byId("wrapperDiv");
        wrapperDiv.appendChild(parentLicense);   

	},
	//
	//User has selected to run Data Collection Remotely (from the web)
	_remoteSelected: function(){
		// The user has selected to run data collection remotely. (from the web)
		// Generate the buttons and controls needs for it
		//
		console.debug("remote Selected ");
		var localSelection=dojo.byId(this.localSelectionID);
		var remoteSelection=dojo.byId(this.remoteSelectionID);
		
		if(localSelection)
			dojo.destroy(localSelection);
		
		if(remoteSelection)
			dojo.destroy(remoteSelection);

		
		//create the parent div
		var parentLicense=dojo.create("div",{id:this.remoteSelectionID,style:{margin:'20px 0 0 0'}});
		
		//create the checkbox
        var licenseTermCheckBox= new dijit.form.CheckBox({});        
        dojo.connect(licenseTermCheckBox.domNode,"onclick",this,
        		dojo.hitch(function(/** */event){
        		      console.debug("License remote selected ..."+event.target.checked);		      
        	        dijit.byId(this.startCollectionID).set('disabled',!event.target.checked);
        }));
        
		//Add the license term label         
        var agreeLicenseTermsLabel=this.agreeLicenseTerms;        
		var licenseTermLabel=dojo.create('label',{innerHTML:agreeLicenseTermsLabel,'for':licenseTermCheckBox.id});

		//assistive technology. Instructions to navigate to next button
		var instructions2Div=dojo.create('div',{id:"instructions2",role:"tooltip","aria-hidden":'true','class':'hiddenInputClass',innerHTML:this.pressTabKeyToNavigateLocal}); 

        //create the label holding the license term url		
		var readLicenseTermsLabel=this.readLicenseTerms; 		
        var pReadLicenseTermURL = dojo.create('p',{'class':'ibm-ind-link'});
        var readLicenseTermURL = dojo.create('a',{href:'#',innerHTML:readLicenseTermsLabel,'class':'ibm-forward-link','aria-describedby':instructions2Div.id},pReadLicenseTermURL);
        dojo.connect(readLicenseTermURL,'onclick',this,this._showLicense);
        
        //Add the start Collection URL
        var startCollectionText=this.startWebCollector;
        var startCollectionButton = new dijit.form.Button({label:startCollectionText,
        	                                               onClick:dojo.hitch(this, this._startDataCollection),
        	                                               disabled:true,
        	                                               baseClass:'isa-ibm-btn-arrow-pri'});
        this.startCollectionID=startCollectionButton.id;

        //Put all the pieces together
        parentLicense.appendChild(pReadLicenseTermURL);
        parentLicense.appendChild(licenseTermCheckBox.domNode);
        parentLicense.appendChild(licenseTermLabel);
        parentLicense.appendChild(instructions2Div);        
        var buttonDiv = dojo.create('div',{style:{margin:'30px 0 0 0'}});
        buttonDiv.appendChild(startCollectionButton.domNode); //disabled at first ... 
        startCollectionButton.set('disabled',true);
        parentLicense.appendChild(buttonDiv);

        var wrapperDiv = dojo.byId("wrapperDiv");
        wrapperDiv.appendChild(parentLicense);
	},
	//
	// start the download of the standalone collector
	_downloadLinuxWebCollector: function(){
		// This function downloads the selected data collection 
		// Calculates the location of the zip file to be downloaded
		// The file depends on whether we are in Windows or on Linux
		// starts the download of the data collection
		//At the end of the download, display a success/failure window for the download
		console.debug("Downloading the data collection zip file.");
				   
		//Read the product JSON file
		var productJson=readProductJSON({
			"taxonomy":this.getSelectedTaxonomy(),
			"collectorScriptsVersion":this.getSelectedVersion(),
			"baseLocation":getBaseLocation()
			});

		console.debug(" Product Stand Alone: "+productJson.productStandAlone);
		
		var lin=productJson.productStandAlone[1].unix;
		
		var baseURL="";
		if(!this.execEnvISADevEnv) // Development Environment
			baseURL=this.getBaseLocation()+"../../../products/"+this.getSelectedTaxonomy()+"/"+this.getSelectedVersion() + "/";
		else
			baseURL=this.getBaseLocation()+"services/"+this.getSelectedTaxonomy()+"/"+this.getSelectedVersion() + "/";

		//Publish the Collection Downloaded event
		dojo.publish("CollectionFileDownloaded",[{'os':'linux'}]);
		
		window.open(baseURL+lin);
	},
	//
	// start the download of the standalone collector
	_downloadWinWebCollector: function(){
		// This function downloads the selected data collection 
		// Calculates the location of the zip file to be downloaded
		// The file depends on whether we are in Windows or on Linux
		// starts the download of the data collection
		//At the end of the download, display a success/failure window for the download
		console.debug("Downloading the data collection zip file.");
				   
		//Read the product JSON file
		var productJson=readProductJSON({
			"taxonomy":this.getSelectedTaxonomy(),
			"collectorScriptsVersion":this.getSelectedVersion(),
			"baseLocation":getBaseLocation()
			});

		console.debug(" Product Stand Alone: "+productJson.productStandAlone);
		var windows=productJson.productStandAlone[0].win;
		
		var baseURL="";
		if(!this.execEnvISADevEnv) // Development Environment
			baseURL=this.getBaseLocation()+"../../../products/"+this.getSelectedTaxonomy()+"/"+this.getSelectedVersion() + "/";
		else
			baseURL=this.getBaseLocation()+"services/"+this.getSelectedTaxonomy()+"/"+this.getSelectedVersion() + "/";

		//Publish the Collection Downloaded event
		dojo.publish("CollectionFileDownloaded",[{'os':'windows'}]);
		
		window.open(baseURL+windows);
	},
	//
	//Displays the license to the user
	_showLicense: function(){
		// This function shows the license for the selected product in the data collection 
		//First, check if it has a different license than the usual license.
		//This separate license should be in ...
		//if no separate license, then display the default license
		//First, read the product JSON file

		console.debug("Displaying license for product: ");
		
		//Read the product JSON file
		var productJson=readProductJSON({
			"taxonomy":this.getSelectedTaxonomy(),
			"collectorScriptsVersion":this.getSelectedVersion(),
			"baseLocation":this.getBaseLocation()
			});

		var defaultLicenseKey="L-DCHS-8QVQPQ";
		console.debug("License URL=" +productJson.licenseURL);
		var licenseURL="http://www14.software.ibm.com/cgi-bin/weblap/lap.pl?li_formnum=";
		var nameInformation="_blank";
		var specs="menubar=false,scrollbars=yes,width=350,height=400,location=1";
		
		if(productJson.licenseURL==''){			
			licenseURL+=defaultLicenseKey;
			window.open(licenseURL,nameInformation,specs);
		}else {
			licenseURL+=productJson.licenseURL;
			window.open(licenseURL,nameInformation,specs);
		}
	},
	// This function initiates the process of starting the Data Collection.
	// First, the applet is loaded, then the data collection area is brought up.
	// In the data collection area, the user can select which data collection to run
	_startDataCollection: function(){
		// This function starts the data collection 
		// 
		console.debug("Starting the data Collection: ");
				   
		executionEnv.taxonomy=this.getSelectedTaxonomy();
		executionEnv.collectorScriptsVersion=this.getSelectedVersion();
		
		//The product, version have been selected, update the Appletloader
		var appletInfo=dijit.byId("loadingAppletID");
		appletInfo.setProductTaxonomy(this.selectedTaxonomy);
		appletInfo.setCollectorScriptsVersion(this.selectedVersion);
		
		//Determine at this point, if we need to continue in the same language locale.
		//If continuing will create a language mismatch, need to reload the applet in the new locale
		//by invoking the English index.html
		//Read the product JSON file
		var productJson=readProductJSON({
			"taxonomy":this.getSelectedTaxonomy(),
			"collectorScriptsVersion":this.getSelectedVersion(),
			"baseLocation":this.getBaseLocation()
			});
		
		console.debug(" Product Stand Alone: "+productJson.supportedLocales);
		var currentLocaleSupported=false;
		
		
		//Retrieve the product specific supported Locale information
		 if(productJson && productJson!=null) {
			 var allSupportedLocales=productJson.supportedLocales; //These are the locales supported by this product
			 console.debug("Supported Locales for this product: "+allSupportedLocales);

			 var currentLocale=dojo.locale; //Locale according to dojo

			 //English is always supported.
			if(currentLocale=="en-us") {
			  this.supportedLocale=true;
			  currentLocaleSupported=true;
			} else {
			 var itemL=allSupportedLocales.split(",");
			 for(var uu=0; uu<itemL.length;uu++){
				 var langCandidate=dojo.trim(itemL[uu].replace("_","-"));
				  console.debug(" Compare supported locale: "+langCandidate + " to current locale (dojo.locale): "+currentLocale);
				  if(matchesLocale(langCandidate)){
					  this.supportedLocale=langCandidate; // returns one of the locale specified.
					  console.debug("Match found. ");
					  currentLocaleSupported=true;
					  break;
				  }
			  }
			}
			
			console.debug("After Locale Validation: Supported Locale: "+this.supportedLocale);			
		  }

		console.debug("Current Locale is supported by Product? "+currentLocaleSupported);
		if(currentLocaleSupported){
		  navigateNextView(); //Show loading applet
		  this.createCollectionExecution(); //Creates the Execution Area for the Data Collection

		  //this call erases
		  if (this._isAppletLoaded) {
			navigateNextView(); //Show data collection execution environment	
		 }
		}else {
			console.debug("Current Locale is not supported... need to reload the page in English ...");
			//Get the current URL with parameters.
			//Change the location/lang/xx/index.html?params  -- -- -- > location/en/index.html?params & noLandingPage=true
            var anyParams=location.search;
            if(anyParams.length==0){
            	anyParams="?noLandingPage=true";
            } else {
            	anyParams+="&noLandingPage=true";
            }
            
            var newParamsList=anyParams;
            if(!this._contains("taxonomy")){
            	newParamsList+="&taxonomy="+this.getSelectedTaxonomy();
            }
            if(!this._contains("productVersion")){
            	newParamsList+="&productVersion="+this.getSelectedVersion();
            }

            window.location.href="../en/index.html"+newParamsList;
		}
	},
	//
	//
	//
	_contains:function(keyword){
		//
		//Summary: 
		//
		// returns: true  or false
		var params = dojo.queryToObject(window.location.search.slice(1));
		if(params[keyword]){
			return true;
		}
		return false;
	},
	//
	//Returns the version of the collector scripts selected
	getSelectedVersion: function() {
		// This function is used to return the version of the 
		// user's selected collector scripts
		return this.selectedVersion;
	},
	//Returns the value of the taxonomy of product selected
	getSelectedTaxonomy: function(){
		// This function is used to return the taxonomy value of the 
		// user's selected product
		return this.selectedTaxonomy;
	},
	//Returns the value of the readable name of product selected
	getSelectedName: function(){
		// This function is used to return the readable value of the 
		// user's selected product
		return this.selectedName;
	},
	//Returns the selected script ID
	getSelectedScriptID: function() {
		//
		//summary: This function is used to return the script ID
		//
        // The script ID should have been passed in the parameters

		return this.productScriptID;		
	},
	//Returns the PMR Number
	getSelectedPMRNumber: function() {
		//
		//summary: This function is used to return the PMR Number
		//
        // The PMR Number should have been passed. If not, then will return the default PMR Number (0000,000,00)

		return this.pmrNumber;		
	},
	//Creates a Collection Execution Environment
	createCollectionExecution: function(){
		// summary: 
		//		Creates the Collection Execution Area.
		// description:
		//		This method creates the collection execution area.
		// returns:
		
		  var loadedApplet=dijit.byId("loadingAppletID");
		  
		  if(loadedApplet!=null){
		    loadedApplet.uploadApplet();
		  
		    //Applet loading was successful. Create a representation of the Data Collection Selection
		    if(loadedApplet.appletCreated()){
			   collectionExecution = new widgets.view.CollectionExecution({
				     id:"collectionExecutionID",
				     PMRNumber:this.getSelectedPMRNumber(), 
				     productTaxonomy:this.getSelectedTaxonomy(), 
				     productScriptID:this.getSelectedScriptID(),
				     execEnvIsFile:this.execEnvIsFile,		
				     execEnvISADevEnv:this.execEnvISADevEnv,
				     loadedApplet:loadedApplet},"collectionExecutionContentPane");    

			   collectionExecution.startup();
			   collectionExecution.setEnvironmentVariables();

			   //Decide whether to display the Tree or start the collection, if a valid script ID was passed.
			   collectionExecution.displayTreeOrStartCollection();
		   } else {
			   this._isAppletLoaded=false;
			   console.debug("Unable to load Data Collection applet ...");
		   }
		  } else { //Unable to locate the loadedApplet, runtime error here
			  
		  }
	},
	//
	//
	_matchesProductVersion: function(/** **/item){
		//
		//Summary: Check to see if a product matches version
		//
		var versionRegularExpression=item.pRegExpr;
		console.debug("Matching product version: " + this.productIDVersion+" with regular expression: "+ versionRegularExpression+"]");
		
		var regularExpression = new RegExp(versionRegularExpression,"gi");		
		var currentVersion = this.productIDVersion;		
		var matchFound=regularExpression.test(currentVersion);
		
		console.debug("Product match found? "+matchFound);
		return matchFound;
	},
	//
	//
	//
	_matchesComponentIdAndRelease: function(/** **/components){
		//
		//Summary: Iterate through the components and find a matching component and release
		//
		console.debug("Matching Component IDs: "+components.length);
		var matches=false;
		
		for(var i=0; i<components.length;i++){
			var comp_data=components[i];
		  	console.debug("Comparing "+ this.componentId+" against component ID: "+comp_data.compId);
		  	
			if(this.componentId==comp_data.compId){				
				//match for the releaseId found
				console.debug("[Matching component release ="+this.componentRelease + " with regular expression " +comp_data.cRegExpr);
				var regularExpression = new RegExp(comp_data.cRegExpr,"gi");						
				var matchesExpr=regularExpression.test(this.componentRelease);				
				console.debug("Release match found? "+matchesExpr);		
				
			   if(matchesExpr) return true;
			} else {
				console.debug("false");
			}
		} 
		return matches;

	},
	//
	//
	_printParameters: function(){
		console.debug(" product ID: "+this.productId);
		console.debug(" component ID: "+this.componentId);
		console.debug(" productIDVersion: "+this.productIDVersion);
		console.debug(" component Release: "+this.componentRelease);
		console.debug(" Taxonomy: "+this.productTaxonomy);
		console.debug(" Data Collector Script Version: "+this.collectorScriptsVersion);
		console.debug(" PMR Number: "+this.pmrNumber);
		console.debug("Master JSON URL"+this.masterJSONURL);
	}
});