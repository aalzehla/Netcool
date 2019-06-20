/**
 * This js file contains functions to drive ISA automated data collection
 */

dojo.require("dojo.string");
dojo.require("dojo.i18n");
dojo.require("dijit.layout.StackContainer");
dojo.require("dijit.layout.ContentPane");

dojo.require("widgets.view.ExecutionModeSelection");	
dojo.require("widgets.view.CollectionExecution");
dojo.require("widgets.view.ProductSelection");
dojo.require("widgets.applet.AppletLoader");
dojo.require("widgets.metrics.MetricsCapture");

function onLoad(){
	//	summary: 
	//		this function is designed to be called by dojo.addOnLoad to 
	//		initialize JavaScript variables and settings.
	//      	
	console.debug("_isadc:onLoad() function: Loading initial data ... ");
	
	//Determines the initial view. 
	var targetViewID = determineInitialView();		
	
	
	if(targetViewID=="executionModeSelection"){
		//create stack container with a number of panes needed for this navigation.
		//Only create the panes that will be needed for this navigation.
		var stackC= new dijit.layout.StackContainer({
			id:'mainViewStackContainerID'
				},"stackContainerViewDiv");
						
		//fill in the panes. One for the default Display
		var contentDefault=new dijit.layout.ContentPane({
		  id:'defaultContentPaneD'
		});

		stackC.addChild(contentDefault);
		
		console.debug("Creating the execution mode: ");
		//Validate Taxonomy
		var taxonomy='';
		if(executionEnv.taxonomy)
			taxonomy=executionEnv.taxonomy;
		
		//script ID passed?
		var scriptID='';
		if(executionEnv.scriptID)
			scriptID=executionEnv.scriptID;
		
		//PMR Number passed?
		var pmrNumber='';
		if(executionEnv.pmrNumber)
			pmrNumber=executionEnv.pmrNumber;
		
		//compID passed?
		var compId='';
		if(executionEnv.componentID)
			compId=executionEnv.componentID;
		
		//prodId passed?
		var prodId='';
		if(executionEnv.productID)
			prodId=executionEnv.productID;
		
		//version passed?
		var productIDVersion='';
		if(executionEnv.productIDVersion)
			productIDVersion=executionEnv.productIDVersion;
		
		//collectorScriptsVersion passed?
		var collectorScriptsVersion='';
		if(executionEnv.collectorScriptsVersion)
			collectorScriptsVersion=executionEnv.collectorScriptsVersion;
		
		
		//release passed?
		var componentRelease='';
		if(executionEnv.componentRelease)
			componentRelease=executionEnv.componentRelease;

		//Where does the link come from? DCF-Technote? SR? Others?
		var linkSource='';
		if(executionEnv.linkSource)
			linkSource=executionEnv.linkSource;
		
		//Create the execution mode selection and add it to the stack container
		var executionSelection=new widgets.view.ExecutionModeSelection(
				{
				  productTaxonomy:taxonomy,
				  productScriptID:scriptID,
				  pmrNumber:pmrNumber,
				  productId:prodId,
				  componentId:compId,
				  productIDVersion:productIDVersion,
				  componentRelease:componentRelease,
				  execEnvISADevEnv:executionEnv.isaDevEnv,
				  execEnvIsFile:executionEnv.isFile,
				  linkSource:executionEnv.linkSource,
				  collectorScriptsVersion:collectorScriptsVersion
				});		
		dojo.byId("defaultContentPaneD").appendChild(executionSelection.domNode);
		executionSelection.startup(); //this must be called
		
		//Create the applet loader, but don't yet load the applet.
		//The applet will be loaded, once the user select to load the run the data collection
	    var applet = new widgets.applet.AppletLoader({
	    	     id:'loadingAppletID',
			     producTaxonomy:executionSelection.getSelectedTaxonomy(), 
			     collectorScriptsVersion:executionSelection.getSelectedVersion(),
				 execEnvISADevEnv:executionEnv.isaDevEnv,
				 execEnvIsFile:executionEnv.isFile,
			     loadApplet:false});   
	    
		//Add appletPage to stack Container
		stackC.addChild(applet);
		
		//Collection Execution Area.
		var collExecution=new dijit.layout.ContentPane({
			  title:'Collection Execution View',
			  id:'collectionExecutionContentPane'
			});
		stackC.addChild(collExecution);
		
		//Start up the Stack Container
		stackC.startup();		
	}else if(targetViewID=="collectionExecution"){ //File protocol
		console.debug("Collection Execution");

		//create stack container with a number of panes needed for this navigation.
		//Only create the panes that will be needed for this navigation.
		var stackC= new dijit.layout.StackContainer({
			id:'mainViewStackContainerID'
				},"stackContainerViewDiv");
		
		//Create the applet loader, but don't load the applet yet ...
		//Applet loader will check for preReqs as well.
		//The applet will be loaded later time ...
	    var applet = new widgets.applet.AppletLoader({
	    	     id:'loadingAppletID',
			     productTaxonomy:executionEnv.taxonomy, 
				 execEnvISADevEnv:executionEnv.isaDevEnv,
				 execEnvIsFile:executionEnv.isFile,
				 collectorScriptsVersion:executionEnv.collectorScriptsVersion,
			     loadApplet:false});   
	    
		//Add appletPage to stack Container
		stackC.addChild(applet);

		//Create the collection Execution Area
		var collExecution=new dijit.layout.ContentPane({
			  title:'Collection Execution View',
			  id:'collectionExecutionContentPane'
			});
		stackC.addChild(collExecution);
		
		//Create No License Acceptance Area and add to stack.
		var noLicenseContent=new dijit.layout.ContentPane({
			  id:'noLicenseContent',
			  content:'No license was accepted.'
			});
		stackC.addChild(noLicenseContent);
		
		stackC.startup();		

		//Create collection Execution Area
		createCollectionExecution();
		var loadedApplet=dijit.byId("loadingAppletID");
		 if(loadedApplet.appletCreated()){
			 navigateNextView();	 
		 }
					
	}
	
	//Initialize metrics reporting
	var metrisReporting = new widgets.metrics.MetricsCapture({
		 execEnvISADevEnv:executionEnv.isaDevEnv,
		 execEnvIsFile:executionEnv.isFile,
		 pmr:executionEnv.pmrNumber,
		 componentID:executionEnv.componentID,
		 productID:executionEnv.productID,
		 productIDVersion:executionEnv.productIDVersion,
		 collectorScriptsVersion:executionEnv.collectorScriptsVersion,
		 compRelease:executionEnv.componentRelease,
		 taxonomy:executionEnv.taxonomy,
		 linkSource:executionEnv.linkSource
	});
}

//Flow control is pretty straight forward: ...
function navigateNextView() {
	var stack = dijit.byId("mainViewStackContainerID");    
	stack.forward();
}

//Creates a Collection Execution Environment
function createCollectionExecution(){
	// summary: 
	//		Creates the Collection Execution Area.
	// description:
	//		This method creates the collection execution area.
	// returns:
	
	  var loadedApplet=dijit.byId("loadingAppletID");	
	  loadedApplet.uploadApplet();
	  
	  //Applet loading was successful. Create a representation of the Data Collection Selection
	  if(loadedApplet.appletCreated()){
		   collectionExecution = new widgets.view.CollectionExecution({
			     id:"collectionExecutionID",
			     pmr:executionEnv.pmrNumber, 
			     taxonomy:executionEnv.taxonomy, 
			     productName:executionEnv.collectionName,
			     symptom:executionEnv.scriptID,
			     execEnvIsFile:executionEnv.isFile,
			     execEnvISADevEnv:executionEnv.isaDevEnv,
			     loadedApplet:loadedApplet},"collectionExecutionContentPane");    

		   collectionExecution.startup();
		   collectionExecution.setEnvironmentVariables();

		   //Decide whether to display the Tree or start the collection, if a valid script ID was passed.
		   collectionExecution.displayTreeOrStartCollection();

			//IE doesn't like the Execution Area visible at first.
			//Currently set to invisible in CollectionExecution.html
			//dojo.style(dojo.byId("mainView"), "visibility", "visible");
	   } else {
		   console.debug("Unable to load Data Collection applet ...");
	   }
}

//Determines the initial view for the Data Collector
function determineInitialView() {
	// summary: 
	//		This function determines the initial view of the Data Collection
	// description:
	//		returns a view to display based on the URL's parameters.
	// returns:
	//		A string representing the name of the view to display
		
	// determine the appropriate initial view based on parms passed in
	// and local vs. remote execution
	
	//file protocol
	if(executionEnv.isFile){				
		return "collectionExecution"; // return 'collectionExecution'
	} else {
		console.debug("Determining the Initial View: "+executionEnv.noLandingPage);
		if(executionEnv.noLandingPage){
			console.debug("No Landing Page. Bypass Landing Page");
			return "collectionExecution"; //Language mismatch. Don't display Landing page again. Necessary to load a new page
		}
		return "executionModeSelection";
	}	
}


