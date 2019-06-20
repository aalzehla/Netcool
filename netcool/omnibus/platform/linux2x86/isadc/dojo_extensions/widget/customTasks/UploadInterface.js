// dojo.provide allows pages to use all of the types declared in this resource.
dojo.provide("widgets.customTasks.UploadInterface");

// dojo.require the necessary dijit hierarchy
dojo.require("dijit._Widget");
dojo.require("dijit._Templated");
dojo.require("dojo.parser");
dojo.require("dojo.cache");
dojo.require("dojo.fx");
dojo.require("dijit.Tooltip");
dojo.require("dijit.ProgressBar");
dojo.require("dijit.layout.ContentPane");
dojo.require("dijit.layout.BorderContainer");
dojo.require("dijit.form.Form");
dojo.require("dijit.form.CheckBox");
dojo.require("dijit.form.ComboBox");
dojo.require("dijit.form.Textarea");
dojo.require("dijit.form.Button");
dojo.require("widgets.customTasks.InputScrubber");

//Loading of nls variables
dojo.requireLocalization("widgets.customTasks", "UploadInterfaceStrings");

dojo.declare("widgets.customTasks.UploadInterface", [dijit._Widget, dijit._Templated ], {
	
	// Path to the template
	templateString: dojo.cache("widgets", "customTasks/templates/UploadInterfaceTemplate.html"),
	
	//The path to the file to upload
	fileToUpload: "",
	
	//The name of the file to upload
	remoteFileName: "",
	
	//Display the button to transfer to IBM
	displayIBMTransfer:true,

	//Display the button to transfer to another FTP server
	displayOtherTransfer:true,

	//Container for the IBM transfer form
	ibmTransferContainer: null,

	//Container for the FTP transfer form
	ftpTransferContainer: null,
	
	//Active form
	activeTransfer:"",

	//the PMR number from URL
	pmrNumber:"",

	//the email  from URL
	email:"",

	//The current active container
	currentTransferContainer: null,
	
	//the Send action button
	sendUploadButtonNode: null,
	
	//The do not send action button
	doNotUploadButtonNode: null,
	
	//The inputscrubber is used for all validation
	inputScrubber: null,

	//HTTPS method for response
	METHOD_IBM_HTTPS: "https",
	
	//IBMs FTP method for response
	METHOD_IBM_FTP: "ftp_to_ibm",
	
	//FTP method for response
	METHOD_FTP: "ftp_other",

	//Constants against the Active Form variable
	IBM_TRANSFER: "IBM_TRANSFER",
	FTP_TRANSFER: "FTP_TRANSFER",
	
	//Default settings for certain parameters
	DEFAULT_UPLOAD_FOR: "other",
	
	// Override this method to perform custom behavior during dijit construction.
	// Common operations for constructor:
	// 1) Initialize non-primitive types (i.e. objects and arrays)
	// 2) Add additional properties needed by succeeding lifecycle methods
	constructor : function(/* Object */args) {
		console.debug("Constructing the Upload Interface!");
		
		// summary: Constructor for the search widget. It allows specifying of attributes.
		if(args.displayIBMTransfer){
			this.displayIBMTransfer=args.displayIBMTransfer;
         }
		if(args.displayOtherTransfer){
			this.displayOtherTransfer=args.displayOtherTransfer;
         }
		if(args.remoteFileName) {
			this.remoteFileName=args.remoteFileName;
		}
		if(args.pmrNumber) {
			this.pmrNumber=args.pmrNumber;
		}
		
		dojo.mixin(this,args);
	},

	// When this method is called, all variables inherited from superclasses are 'mixed in'.
	// Common operations for postMixInProperties
	// 1) Modify or assign values for widget property variables defined in the template HTML file
	postMixInProperties : function() {
		//do the nls mixin here
		var _nlsResources=dojo.i18n.getLocalization("widgets.customTasks","UploadInterfaceStrings");
		
		dojo.mixin(this,_nlsResources);

		this.inherited(arguments);
	},

	/**
	 * Method to initialize the widget values after it is created.
	 */ 
	postCreate: function() {
		//Create the inputscrubber right away for use throughout
		this.inputScrubber = new widgets.customTasks.InputScrubber();
		
		//Create the header label
		this.transferLabelSpan.innerHTML = this.transferHeaderLabel;
		this.transferInfoDiv.appendChild(dojo.create('div', {"class":"transferInfoMsg",innerHTML: this.transferInfoLabelMain}));		//Add the info on transfering to IBM using other means:
		this.transferInfoDiv.appendChild(dojo.create('div', {"class":"transferInfoMsg left",innerHTML: this.transferInfoLabelDocumentation}));

		var transferButtonEvents = {};
		
		if (this.displayIBMTransfer) {
			var ibmTransferButtonDiv = dojo.create("div", {"class":"transferButton transferButtonLeft"});
			ibmTransferButtonDiv.appendChild(dojo.create("div", {id:this.id + "_ibmTransferImg", "class":"transferImg ibmTransferImg"}));
			ibmTransferButtonDiv.appendChild(dojo.create("div", {"class":"transferButtonlabel", innerHTML:this.ibmTransferLabel,"tabIndex":"0",role:"button"}));
			
			this.transferButtonDiv.appendChild(ibmTransferButtonDiv);
			
			transferButtonEvents.ibmButton = dojo.hitch(this, function(event){
				if (this.activeTransfer!=this.IBM_TRANSFER) {
					if (!event.keyCode || event.keyCode == dojo.keys.ENTER || event.keyCode == dojo.keys.SPACE) {
						this.activeTransfer=this.IBM_TRANSFER;
						
						//Remove selected class from all buttons
						dojo.query(".transferButton", this.transferButtonDiv).forEach(function(item) {
							dojo.removeClass(item, "transferButtonSelected");
						});
						//Add the selected class to the selected button
						dojo.addClass(ibmTransferButtonDiv, "transferButtonSelected");
						
						//If the form has not been initiated yet, do so
						if (!this.ibmTransferContainer) {
							this._buildIBMTransferMenu();
						}
						
						this._validateIBMTransferForm();
						
						if (this.currentTransferContainer) {
							dojo.addClass(this.currentTransferContainer, "hideContainer");
						}
						this.currentTransferContainer=this.ibmTransferContainer;
						
						var transferInputNodeFound = false;
						console.debug("Focusing on first element");

						dojo.removeClass(this.currentTransferContainer, "hideContainer");
						
						dojo.query("input", this.currentTransferContainer).forEach(function(transferInputNode){
							//See if the first node was found and if not see if the element has an id, then we assume we can focus on it
							console.debug("id: " + dojo.attr(transferInputNode, "id"));
							if(!transferInputNodeFound && dojo.attr(transferInputNode, "id")) {
								console.debug("FOUND: " + dojo.attr(transferInputNode, "id"));
								transferInputNode.focus();
								transferInputNodeFound = true;
							}
						});
					}
				}
			});

			dojo.connect(ibmTransferButtonDiv, "onclick", transferButtonEvents, "ibmButton");
			dojo.connect(ibmTransferButtonDiv, "onkeyup", transferButtonEvents, "ibmButton");				
		}
		
		if (this.displayOtherTransfer) {
			var otherTransferButtonDiv = dojo.create("div", {"class":"transferButton transferButtonRight"});
			otherTransferButtonDiv.appendChild(dojo.create("div", {id:this.id + "_otherTransferImg", "class":"transferImg otherTransferImg"}));
			otherTransferButtonDiv.appendChild(dojo.create("div", {"class":"transferButtonlabel", innerHTML:this.otherTransferLabel,"tabIndex":"0",role:"button"}));

			this.transferButtonDiv.appendChild(otherTransferButtonDiv);

			transferButtonEvents.otherButton = dojo.hitch(this, function(event){
				if (this.activeTransfer!=this.FTP_TRANSFER) {
						if (!event.keyCode || event.keyCode == dojo.keys.ENTER || event.keyCode == dojo.keys.SPACE) {
							this.activeTransfer=this.FTP_TRANSFER;
							//Set the opacity
							dojo.query(".transferButton", this.transferButtonDiv).forEach(function(item) {
								dojo.removeClass(item, "transferButtonSelected");
							});
							dojo.addClass(otherTransferButtonDiv, "transferButtonSelected");
							
							this._validateFTPTransferForm();
							
							//If the form has not been initiated yet, do so
							if (!this.ftpTransferContainer) {
								this._buildFTPTransferMenu();
								this.transferDiv.appendChild(this.ftpTransferContainer);
								this.disableSend(true);
							}
							
							if (this.currentTransferContainer) {
								dojo.addClass(this.currentTransferContainer, "hideContainer");
							}
							this.currentTransferContainer=this.ftpTransferContainer;
							
							var transferInputNodeFound = false;
							console.debug("Focusing on first element");

							dojo.removeClass(this.currentTransferContainer, "hideContainer");
							
							dojo.query("input", this.currentTransferContainer).forEach(function(transferInputNode){
								//See if the first node was found and if not see if the element has an id, then we assume we can focus on it
								console.debug("id: " + dojo.attr(transferInputNode, "id"));
								if(!transferInputNodeFound && dojo.attr(transferInputNode, "id")) {
									console.debug("FOUND: " + dojo.attr(transferInputNode, "id"));
									transferInputNode.focus();
									transferInputNodeFound = true;
								}
							});
						}
					}
				});
			
			dojo.connect(otherTransferButtonDiv, "onclick", transferButtonEvents, "otherButton");
			dojo.connect(otherTransferButtonDiv, "onkeyup", transferButtonEvents, "otherButton");
		}

		
		//Need to put a clear:both style here to align the buttons
		if (this.displayIBMTransfer && this.displayOtherTransfer) {
			this.transferButtonDiv.appendChild(dojo.create("div", {"class":"clear"}));
		}
		
		//Create the transfer Buttons
		this._buildTransferSendButtons();
		this.inherited("postCreate",arguments);		
	},
	
	/*
	 * Builds the IBM Transfer form when the IBM transfer button is selected
	 */
	_buildIBMTransferMenu: function() {
		//Create the div containing the IBM transfer form
		this.ibmTransferContainer = dojo.create("div", {"class":"ibmTransferContainer"});
		
		var ibmRadioFieldSet = dojo.create("fieldset", {style:"display:inline-block;margin-left:-3px;"});
		var ibmRadioLegend = dojo.create("legend", {innerHTML:this.ibmTransferFormContainerLabel, style:"display:inline-block;"});
		ibmRadioFieldSet.appendChild(ibmRadioLegend);
		
		var ibmRadioContainer = dojo.create("div", {"class":"ibmHTTPSTextBox", style:"display:inline-block;margin-left:143px;border:0px;padding:0px;"});
		var ibmRadioHTTPSContainer = dojo.create("div", {"class":"ibmHTTPSTextBox ibmRadioDiv"});
		
		//Create the Radio button and Label for HTTPS transfer
		var ibmRadioHTTPS = new dijit.form.RadioButton({
			checked: true,
			value: this.METHOD_IBM_HTTPS,
            name: this.id + "_ibmTransfer",
            id: this.id + "_ibmTransferHTTPS"
		});
		var ibmRadioHTTPSLabel = dojo.create("label", {innerHTML:this.ibmTransferLabelHTTPS, "for":this.id + "_ibmTransferHTTPS"});
		
		//Transfer to IBM via HTTPS
		ibmRadioHTTPSContainer.appendChild(ibmRadioHTTPS.domNode);
		ibmRadioHTTPSContainer.appendChild(ibmRadioHTTPSLabel);
		
		var ibmTransferFormContainer = dojo.create("div", {id:this.id + "ibmTransferFormContainer", "class":"ibmTextBoxDiv"});
		
		ibmRadioContainer.appendChild(ibmRadioHTTPSContainer);
		
		//Transfer to IBM via FTP
		var ibmRadioFTPContainer = dojo.create("div", {"class":"ibmHTTPSTextBox ibmRadioDiv"});
		
		var ibmRadioFTP = new dijit.form.RadioButton({
			checked: false,
			value: this.METHOD_IBM_FTP,
            name: this.id + "_ibmTransfer",
	        id: this.id + "_ibmTransferFTP"
		});
		var ibmRadioFTPLabel = dojo.create("label", {innerHTML:this.ibmTransferLabelFTP, "for":this.id + "_ibmTransferFTP"});
		
		ibmRadioFTPContainer.appendChild(ibmRadioFTP.domNode);
		ibmRadioFTPContainer.appendChild(ibmRadioFTPLabel);

		ibmRadioContainer.appendChild(ibmRadioFTPContainer);
		ibmRadioFieldSet.appendChild(ibmRadioContainer);
		ibmTransferFormContainer.appendChild(ibmRadioFieldSet);
		
		this.ibmTransferContainer.appendChild(ibmTransferFormContainer);

		//Create Hostname label and input
		var ibmPMRContainer = dojo.create("div", {"class":"ibmTextBoxDiv"});
		//Create the textboxs required for the FTP send form
		var ibmPMRTextBox = new dijit.form.ValidationTextBox({
			invalidMessage: this.invalidPMRInputMessage,
			"class": "ibmTextBox",
			required: true,
			label:this.ibmPMRLabel,
			name:"pmr",
			onKeyUp: dojo.hitch(this, this._validateFTPTransferForm),
			id: this.id + "_ibmPMRTextBox"
		});
		
		//Check if PMR was present in url
		if (this.pmrNumber!="") {
			ibmPMRTextBox.set("value", this.pmrNumber);
		}
		
		ibmPMRTextBox.validator = dojo.hitch(this, function() {
			if (ibmPMRTextBox.get("required") == true) {
				if (ibmPMRTextBox.get("value")=="") {
					return false;
				}
			}
			var inputResultPMR = this.inputScrubber.validateInput(this.inputScrubber.TYPE_PMR, ibmPMRTextBox.get("value"));
			var inputResultNoCode = this.inputScrubber.validateInput(this.inputScrubber.TYPE_NO_CODE, ibmPMRTextBox.get("value"));
			if ((inputResultPMR >= 1) && (inputResultNoCode >=1)) {
				return true;
			}
			else {
				return false;
			}
		});

		dojo.attr(ibmPMRTextBox, "class", "ibmTextBox");
		var ibmPMRLabel = dojo.create("label", {innerHTML:this.ibmPMRLabel, "for":this.id + "_ibmPMRTextBox", "class": "ftpTextBoxLabel"});

		//Add the e-mail tooltip image
		var ibmPMRToolTip=dojo.create("span",{id:this.id + "_pmrToolTip"});
		var whiteBkgImage1="'"+getBaseLocation()+'ibm_com/images/v16/t/i_whitebkground.jpg'+"'";
		ibmPMRToolTip.innerHTML="<img src="+whiteBkgImage1+"style='vertical-align:bottom'alt='" +this.ibmPMRToolTipLabel+ "'>";
		
		//ibmPMRToolTip.innerHTML="<img src='ibm_com/images/v16/t/i_whitebkground.jpg' style='vertical-align:bottom' alt='" + this.ibmPMRToolTipLabel + "'>";

		ibmPMRContainer.appendChild(ibmPMRLabel);
		ibmPMRContainer.appendChild(ibmPMRTextBox.domNode);
		ibmPMRContainer.appendChild(ibmPMRToolTip);
		this.ibmTransferContainer.appendChild(ibmPMRContainer);

		var ibmHTTPSTextBoxContainer = dojo.create("div", {"class":"ibmTextBoxDiv"});
		//Create the text-box for e-mail
		var ibmHTTPSTextBox = new dijit.form.ValidationTextBox({
			invalidMessage: this. invalidEmailInputMessage,
			"class": "ibmHTTPSTextBox ibmTextBox",
			id: this.id + "_ibmHTTPSTextBox"
		});
		
		//Check if email was present in url
		if (this.email!="") {
			ibmHTTPSTextBox.set("value", this.email);
		}
		
		ibmHTTPSTextBox.validator = dojo.hitch(this, function() {
			var inputResultEmail = this.inputScrubber.validateInput(this.inputScrubber.TYPE_EMAIL, ibmHTTPSTextBox.get("value"));
			var inputResultNoCode = this.inputScrubber.validateInput(this.inputScrubber.TYPE_NO_CODE, ibmHTTPSTextBox.get("value"));
			if ((inputResultEmail >= 1) && (inputResultNoCode >= 1)) {
				return true;
			}
			else {
				return false;
			}
		});

		//Add the e-mail tooltip image
		var ibmHTTPSToolTip=dojo.create("span",{id:this.id + "_httpsToolTip"});
		var whiteBkgImage1="'"+getBaseLocation()+'ibm_com/images/v16/t/i_whitebkground.jpg'+"'";
		ibmHTTPSToolTip.innerHTML="<img src="+whiteBkgImage1+"style='vertical-align:bottom'alt='" +this.ibmHTTPSToolTipLabel+ "'>";

		//ibmHTTPSToolTip.innerHTML="<img src='ibm_com/images/v16/t/i_whitebkground.jpg' style='vertical-align:bottom'  alt='" + this.ibmHTTPSToolTipLabel + "'>";

		var ibmHTTPSTextBoxLabel = dojo.create("label", {innerHTML:this.ibmHTTPSTextBoxLabel, "for":this.id + "_ibmHTTPSTextBox", "class": "ftpTextBoxLabel"});

		ibmHTTPSTextBoxContainer.appendChild(ibmHTTPSTextBoxLabel);
		ibmHTTPSTextBoxContainer.appendChild(ibmHTTPSTextBox.domNode);
		ibmHTTPSTextBoxContainer.appendChild(ibmHTTPSToolTip);
		
		//Validate the form before connecting to the events
		this._validateIBMTransferForm();
		
		dojo.connect(ibmPMRTextBox, "onClick", dojo.hitch(this, function() {
			this._validateIBMTransferForm();
		}));
		dojo.connect(ibmPMRTextBox, "onKeyUp", dojo.hitch(this, function() {
			this._validateIBMTransferForm();
		}));
		
		//Using a toggler because it prevents conflicting effects from being sent to the element
		//Using wipeout because fade only sets visible to none, leaving the divs present on the screen (including the tooltip)
		var httpsWipeToggler = new dojo.fx.Toggler({
            node: ibmHTTPSTextBoxContainer,
            showFunc: dojo.fx.wipeIn,
            hideFunc: dojo.fx.wipeOut
        });
		
		//Connect to an event to disable the textbox
		dojo.connect(ibmRadioFTP, "onClick", dojo.hitch(this, function(){
			httpsWipeToggler.hide();
			
			this._validateIBMTransferForm();
		}));
		
		//Connect to an event to enable the textbox
		dojo.connect(ibmRadioHTTPS, "onClick", dojo.hitch(this, function(){
			httpsWipeToggler.show();

			this._validateIBMTransferForm();
		}));
		
		//Connect to the onKeyUp event for the textbox
		dojo.connect(ibmHTTPSTextBox, "onKeyUp", dojo.hitch(this, function(){
			this._validateIBMTransferForm();
		}));

		this.ibmTransferContainer.appendChild(ibmHTTPSTextBoxContainer);
		
		//Add the IBM transfer container to the page
		this.transferDiv.appendChild(this.ibmTransferContainer);
		
		//Need to setup the ToolTip after the div is added to the dom!
		var ibmPMRToolTipToolTip = new dijit.Tooltip({
		     connectId: [ibmPMRToolTip.id],
		     label: this.ibmPMRToolTipLabel
		  });
		
		var ibmHTTPSTextBoxToolTip = new dijit.Tooltip({
		     connectId: [ibmHTTPSToolTip.id],
		     label: this.ibmHTTPSToolTipLabel
		  });
	},
	
	/*
	 * Builds the FTP transfer form when the FTP button is clicked
	 */
	_buildFTPTransferMenu: function() {
		//Create the div containing the IBM transfer form
		this.ftpTransferContainer = dojo.create("div", {"class":"ibmTransferContainer"});
		
		//Create Hostname label and input
		var ftpHostnameContainer = dojo.create("div", {"class":"ftpTextBoxDiv"});
		
		//Create the textboxs required for the FTP send form
		var ftpHostnameTextBox = new dijit.form.ValidationTextBox({
			invalidMessage: this.invalidHostnameInputMessage,
			"class": "ftpTextBox",
			required: true,
			label:this.ftpHostnameLabel,
			name:"ftpHostname",
			onKeyUp: dojo.hitch(this, this._validateFTPTransferForm),
			id: this.id + "_ftpHostnameTextBox"
		});
		ftpHostnameTextBox.validator = dojo.hitch(this, function() {
			if (ftpHostnameTextBox.get("required") == true) {
				if (ftpHostnameTextBox.get("value")=="") {
					return false;
				}
			}
			var inputResultURL = this.inputScrubber.validateInput(this.inputScrubber.TYPE_URL, ftpHostnameTextBox.get("value"));
			var inputResultIP = this.inputScrubber.validateInput(this.inputScrubber.TYPE_IP, ftpHostnameTextBox.get("value"));
			var inputResultNoCode = this.inputScrubber.validateInput(this.inputScrubber.TYPE_NO_CODE, ftpHostnameTextBox.get("value"));
			if (((inputResultURL >= 1) || (inputResultIP >=1)) && (inputResultNoCode >=1)) {
				return true;
			}
			else {
				return false;
			}
		});

		dojo.attr(ftpHostnameTextBox, "class", "ftpTextBox");
		var ftpHostnameLabel = dojo.create("label", {innerHTML:this.ftpHostnameLabel, "for":this.id + "_ftpHostnameTextBox", "class": "ftpTextBoxLabel"});

		ftpHostnameContainer.appendChild(ftpHostnameLabel);
		ftpHostnameContainer.appendChild(ftpHostnameTextBox.domNode);
		
		this.ftpTransferContainer.appendChild(ftpHostnameContainer);
		
		//Create UserID label and input
		var ftpUserIDContainer = dojo.create("div", {"class":"ftpTextBoxDiv"});
		
		var ftpUserIDTextBox = new dijit.form.ValidationTextBox({
			invalidMessage: this.invalidUserIDInputMessage,
			"class": "ftpTextBox",
			required: true,
			label:this.ftpUserIDLabel,
			name:"user",
			onKeyUp: dojo.hitch(this, this._validateFTPTransferForm),
			id: this.id + "_ftpUserIDTextBox"
		});
		ftpUserIDTextBox.validator = dojo.hitch(this, function() {
			if (ftpUserIDTextBox.get("required") == true) {
				if (ftpUserIDTextBox.get("value")=="") {
					return false;
				}
			}
			var inputResultNoCode = this.inputScrubber.validateInput(this.inputScrubber.TYPE_NO_CODE, ftpUserIDTextBox.get("value"));
			if (inputResultNoCode >= 1) {
				return true;
			}
			else {
				return false;
			}
		});
		var ftpUserIDLabel = dojo.create("label", {innerHTML:this.ftpUserIDLabel, "for":this.id + "_ftpUserIDTextBox", "class": "ftpTextBoxLabel"});

		ftpUserIDContainer.appendChild(ftpUserIDLabel);
		ftpUserIDContainer.appendChild(ftpUserIDTextBox.domNode);
		
		this.ftpTransferContainer.appendChild(ftpUserIDContainer);
		
		//Create the Password label and input
		var ftpPasswordContainer = dojo.create("div", {"class":"ftpTextBoxDiv"});
		
		var ftpPasswordTextBox = new dijit.form.ValidationTextBox({
			invalidMessage: this.invalidPasswordInputMessage,
			"class": "ftpTextBox",
			required: true,
			type: "password",
			label:this.ftpPasswordLabel,
			name:"password",
			onKeyUp: dojo.hitch(this, this._validateFTPTransferForm),
			id: this.id + "_ftpPasswordTextBox"
		});
		ftpPasswordTextBox.validator = dojo.hitch(this, function() {
			if (ftpPasswordTextBox.get("required") == true) {
				if (ftpPasswordTextBox.get("value")=="") {
					return false;
				}
			}
			var inputResultNoCode = this.inputScrubber.validateInput(this.inputScrubber.TYPE_NO_CODE, ftpPasswordTextBox.get("value"));
			if (inputResultNoCode >= 1) {
				return true;
			}
			else {
				return false;
			}
		});
		var ftpPasswordLabel = dojo.create("label", {innerHTML:this.ftpPasswordLabel, "for":this.id + "_ftpPasswordTextBox", "class": "ftpTextBoxLabel"});

		ftpPasswordContainer.appendChild(ftpPasswordLabel);
		ftpPasswordContainer.appendChild(ftpPasswordTextBox.domNode);
		
		this.ftpTransferContainer.appendChild(ftpPasswordContainer);
		
		//Create the Directory label and input
		var ftpDirectoryContainer = dojo.create("div", {"class":"ftpTextBoxDiv"});
		
		var ftpDirectoryTextBox = new dijit.form.ValidationTextBox({
			invalidMessage: this.invalidDirectoryInputMessage,
			"class": "ftpTextBox",
			label: this.ftpDirectoryLabel,
			name:"remoteDirectory",
			onKeyUp: dojo.hitch(this, this._validateFTPTransferForm),
			id: this.id + "_ftpDirectoryTextBox"
		});
		ftpDirectoryTextBox.validator = dojo.hitch(this, function() {
			if (ftpDirectoryTextBox.get("required") == true) {
				if (ftpDirectoryTextBox.get("value")=="") {
					return false;
				}
			}
			var inputResultNoCode = this.inputScrubber.validateInput(this.inputScrubber.TYPE_NO_CODE, ftpPasswordTextBox.get("value"));
			if (inputResultNoCode >= 1) {
				return true;
			}
			else {
				return false;
			}
		});
		var ftpDirectoryLabel = dojo.create("label", {innerHTML:this.ftpDirectoryLabel, "for":this.id + "_ftpDirectoryTextBox", "class": "ftpTextBoxLabel"});

		ftpDirectoryContainer.appendChild(ftpDirectoryLabel);
		ftpDirectoryContainer.appendChild(ftpDirectoryTextBox.domNode);
		
		this.ftpTransferContainer.appendChild(ftpDirectoryContainer);		
	},
	
	_buildTransferSendButtons: function() {
		this.sendUploadButtonNode= new dijit.form.Button({
			label:this.sendUploadButtonLabel,
			baseClass:"isa-ibm-btn-arrow-pri",
			style:"border:0px none;",
			"class": "transferActionButton",
			disabled: "disabled"
		}, this.sendUploadButton);
		
		this.doNotUploadButtonNode= new dijit.form.Button({
			label:this.doNotUploadButtonLabel,
			baseClass:"isa-ibm-btn-cancel-sec",
			"class": "transferActionButton"
		}, this.doNotUploadButton);
		
		dojo.query(".dijitButtonNode", this.transferActionDiv).forEach(dojo.hitch(this, function(item){
			dojo.style(item,"border", "0px none");
		}));
	},
	
	//Validates the textboxes for the FTP transfer form
	_validateFTPTransferForm: function() {
		//Find all the text boxes in the FTP transfer div
		var textboxValid = true;
		dojo.query(".ftpTextBox", this.ftpTransferContainer).forEach(dojo.hitch(this, function(node) {
			//Convert the dom node to a dijit widget
			var w = dijit.byNode(node);
			
			textboxValid = textboxValid && w.isValid();
		}));
		if (textboxValid) {
			this.disableSend(false);
		}
		else {
			this.disableSend(true);
		}
	},
	
	//Called when changing the transfer forms
	_changeForm: function() {
		if (dijit.byId(this.id + "_ibmTransferHTTPS").get("checked")==true){
			dijit.byId(this.id + "_ibmHTTPSTextBox").set("disabled", false);
			dijit.byId(this.id + "_ibmTransferHTTPS").set("checked", true);
			dijit.byId(this.id + "_ibmTransferHTTPS").focus();
		}
		else if (dijit.byId(this.id + "_ibmTransferFTP").get("checked")==true){
			dijit.byId(this.id + "_ibmTransferFTP").set("checked", true);
			dijit.byId(this.id + "_ibmTransferFTP").focus();
		}
		this._validateIBMTransferForm();
	},
	
	//Validates the IBM transfer form
	_validateIBMTransferForm: function() {
		if (!dijit.byId(this.id + "_ibmPMRTextBox").isValid()) {
			this.disableSend("true");
		}
		else {
			//If the HTTPS radio button is selected, need to verify that textbox is valid
			if (dijit.byId(this.id + "_ibmTransferHTTPS").get("checked")==true){
				//Check if the textbox is false
				if (dijit.byId(this.id + "_ibmHTTPSTextBox").isValid()) {
					this.disableSend(false);
				}
				else {
					this.disableSend(true);
				}
			}//Form is always valid when IBM via FTP is selected
			else if (dijit.byId(this.id + "_ibmTransferFTP").get("checked")==true){
				this.disableSend(false);
			}
		}
	},
	
	//Use this to validate the transfer forms
	validateTransferForm: function() {
		if (this.activeTransfer == this.IBM_TRANSFER) {
			this._validateIBMTransferForm();
		}
		else if (this.activeTransfer == this.FTP_TRANSFER) {
			this._validateFTPTransferForm();
		}
	},
	
	//Disables the send depending on the boolean value of the "disabled" value
	disableSend: function(disabled) {
		if (disabled != (this.sendUploadButtonNode.get("disabled")!=false)) {
			if (disabled) {
				this.sendUploadButtonNode.set("disabled", "disabled");
			}
			else {
				console.debug("Removing disabled!");
				this.sendUploadButtonNode.set("disabled", false);
				dojo.removeAttr(this.sendUploadButtonNode.id, "disabled");
			}
		}
	},
	
	//Returns a JSON object with the required values - will always have a type
	getFormInput: function() {
		var transferInput = {};
		transferInput.parms = {};
		if (this.activeTransfer == this.IBM_TRANSFER) {
			transferInput.parms.pmr = dijit.byId(this.id + "_ibmPMRTextBox").get("value");
			//If the HTTPS radio button is selected, need to verify that textbox is valid
			if (dijit.byId(this.id + "_ibmTransferHTTPS").get("checked")==true){
				transferInput.transferType = this.METHOD_IBM_HTTPS;
				transferInput.parms.emailAddress = dijit.byId(this.id + "_ibmHTTPSTextBox").get("value");
				transferInput.parms.uploadFor = this.DEFAULT_UPLOAD_FOR;
			}
			else if (dijit.byId(this.id + "_ibmTransferFTP").get("checked")==true){
				transferInput.transferType = this.METHOD_IBM_FTP;
				transferInput.parms.uploadFor = this.DEFAULT_UPLOAD_FOR;
				transferInput.parms.remoteFileName = this.remoteFileName;
				//This is a default value that needs to be passed in for FTP
				transferInput.parms.emailAddress = "ibmsa@us.ibm.com";
			}
		}
		else if (this.activeTransfer == this.FTP_TRANSFER) {
			transferInput.transferType = this.METHOD_FTP;
			dojo.query(".ftpTextBox", this.ftpTransferContainer).forEach(dojo.hitch(this, function(node) {
				var w = dijit.byNode(node);
				transferInput.parms[w.name] = w.get("value");
			}));
			
			transferInput.parms.remoteFileName = this.remoteFileName;
		}
		return transferInput;
	},
	
	show: function() {
		dojo.removeClass(this.mainInterface, "hideContainer");
		this.validateTransferForm();		
	},
	
	hide: function() {
		dojo.addClass(this.mainInterface, "hideContainer");
	}
});