/*******************************************************************************
* (C) COPYRIGHT International Business Machines Corp., 2011. 
* All Rights Reserved * Licensed Materials - Property of IBM
*******************************************************************************/

/**
 * load the configuration parameters from the ISA ConfigurationService.
 */
dojo.require("dojox.grid.DataGrid");
dojo.require("dojo.data.ItemFileReadStore");
dojo.require("dijit.layout.BorderContainer");
dojo.require("dijit.layout.ContentPane");
dojo.require("dijit.layout.TabContainer");


dojo.addOnLoad(function(){

 	var tc = new dijit.layout.TabContainer({
         style: "width: 98%; height: 95%; margin:1em auto;",
         tabStrip: true
     },
     "mainTabContainer");
 	showLoader();
 	//var createConfig = function() { createConfigurationTab(tc); };
	// applet will be placed in appletDiv
	var appletDiv=dojo.byId("appletDiv");
	// load the applet that will talk to the configuration service
	var appletID=createApplet("com.ibm.isa.web.collector.applets.ConfigurationApplet.class", [], appletDiv);

 	var configApplet = parent.document.getElementById(appletID);
 	var rawData = configApplet.getConfiguration();
    console.log(rawData);
    var data = dojo.fromJson(rawData);
    console.log(data);
    generalParameterGrid(tc, data.generalParameters);
    antPropertyGrid(tc, data.antProperties);
    systemPropertyGrid(tc, data.systemProperties);
 	//setTimeout(createConfig, 2000);
    hideLoader();
    tc.startup();
 	

});

	function createConfigurationTab(tc) {
		

		
	}
 	

	/**
	 * Fill in the general parameters tab
	 * 
	 * @param tc	Main tab container
	 * @param generalParameters general properties from the configuration
	 */
	function generalParameterGrid(tc, generalParameters) {
		
        var gpBorderContainer = new dijit.layout.BorderContainer({
            title: "General Configuration",
            style: "width: 95%; height: 100%;"
        });
        tc.addChild(gpBorderContainer);
        
        var gpContentPane = new dijit.layout.ContentPane({
        	content: "<h1>IBM Support Assistant Web Collector Parameters</h1>",
           	region: "top"
        });
        gpBorderContainer.addChild(gpContentPane);

		
		var generalParameterStore = new dojo.data.ItemFileReadStore({
            data : {items: generalParameters}
        });

		// set the layout structure:
		var generalParameterGridLayout = [{
			field: 'key',
			name: 'Parameter',
			width: 'auto'
		},
		{
			field: 'value',
			name: 'Value',
			width: 'auto'
		}];

		// create a new grid:
		var generalParameterGrid = new dojox.grid.DataGrid({
			store: generalParameterStore,
			sortInfo: 1,
			rowsPerPage: 20,
			region: "center",
			structure: generalParameterGridLayout
		});

		// append the new grid to the div "antPropertyGridContainer":
		gpBorderContainer.addChild(generalParameterGrid);
		generalParameterGrid.startup();
		
	}
 	
	/**
	 * Fill in the Ant Properties tab
	 * 
	 * @param tc	The tab container
	 * @param antProperties	Ant properties from the configuration service
	 */
	function antPropertyGrid(tc, antProperties) {
		
        var antBorderContainer = new dijit.layout.BorderContainer({
            title: "Ant Properties",
            style: "width: 95%; height: 100%;"
        });
        tc.addChild(antBorderContainer);
        
        var antContentPane = new dijit.layout.ContentPane({
        	content: "<h1>IBM Support Assistant JVM System Properties</h1>",
           	region: "top"
        });
        antBorderContainer.addChild(antContentPane);

		
		var antPropertyStore = new dojo.data.ItemFileReadStore({
            data : {items: antProperties}
        });

		// set the layout structure:
		var antPropertyGridLayout = [{
			field: 'key',
			name: 'Property',
			width: 'auto'
		},
		{
			field: 'value',
			name: 'Value',
			width: 'auto'
		}];

		// create a new grid:
		var antPropertyGrid = new dojox.grid.DataGrid({
			store: antPropertyStore,
			sortInfo: 1,
			rowsPerPage: 20,
			region: "center",
			structure: antPropertyGridLayout
		});

		// append the new grid to the div "antPropertyGridContainer":
		antBorderContainer.addChild(antPropertyGrid);
		antPropertyGrid.startup();
		
	}
 
	/**
	 * Fill in the System Properties tab
	 * 
	 * @param tc	The tab container
	 * @param systemProperties	System properties from the configuration service
	 */
	function systemPropertyGrid(tc, systemProperties) {

        var systemBorderContainer = new dijit.layout.BorderContainer({
            title: "System Properties",
            style: "width: 95%; height: 100%;"
        });
        tc.addChild(systemBorderContainer);
        
        var systemContentPane = new dijit.layout.ContentPane({
        	content: "<h1>JVM System Properties</h1>",
           	region: "top"
        });
        systemBorderContainer.addChild(systemContentPane);
		
		var systemPropertyStore = new dojo.data.ItemFileReadStore({
            data : {items: systemProperties}
        });


		// set the layout structure:
		var systemPropertyGridLayout = [{
			field: 'key',
			name: 'Property',
			width: 'auto'
		},
		{
			field: 'value',
			name: 'Value',
			width: 'auto'
		}];

		// create a new grid:
		var systemPropertyGrid = new dojox.grid.DataGrid({
			store: systemPropertyStore,
			sortInfo: 1,
			rowsPerPage: 20,
			region: "center",
			structure: systemPropertyGridLayout
		});

		// append the new grid to the div "systemPropertyGridContainer":
		systemBorderContainer.addChild(systemPropertyGrid);
		systemPropertyGrid.startup();
		
	}

	function showLoader(){

		dojo.style("mainTabContainer", "display", "none");
	    dojo.style("preloader", "display", '');

	}

	function hideLoader(){

		dojo.style("preloader", "display", "none");
		dojo.style("mainTabContainer", "display", '');
		
	}
	
		