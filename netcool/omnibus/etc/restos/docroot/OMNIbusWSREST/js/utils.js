/***********************************************************************
 *
 *      IBM Confidential
 *
 *      OCO Source Materials
 *
 *      5724O4800
 *
 *      (C) Copyright IBM Corp. 2013
 *
 *      The source code for this program is not published or
 *      otherwise divested of its trade secrets, irrespective of
 *      what has been deposited with the U.S. Copyright Office.
 *
 **********************************************************************/
 
var BASE_URI = "/OMNIbusWSREST";
var SRVS_BASE_URI = "/objectserver";
var OSLC_BASE_URI = SRVS_BASE_URI + "/oslc/";
var REST_BASE_URI = SRVS_BASE_URI + "/restapi/";
var SYSINFO_BASE_URI = SRVS_BASE_URI + "/sysinfo";
 
var OSLC_WABASE_URI = BASE_URI + "/oslc_wa/";
var REST_WABASE_URI = BASE_URI + "/rest_wa/";

var OSLC_RESOURCE_EVENT_URI = OSLC_BASE_URI + "event";
var OSLC_RESOURCE_JOURNAL_URI = OSLC_BASE_URI + "journal";
var OSLC_RESOURCE_DETAIL_URI = OSLC_BASE_URI + "detail";
 
/***********************************************************************
 * HTTP request related functions.
 **********************************************************************/
function httpRequestCreate()
{
	var	req_hdl = null;

	/*
	 * Determine the type of browser we are in and handle
	 * accordingly.
	 */
	if( window.XMLHttpRequest )
	{
		/*
		 * Mozilla, Safari, IE7, etc browser handler.
		 */
		req_hdl = new XMLHttpRequest();
		
		if( req_hdl.overrideMimeType )
		{
			req_hdl.overrideMimeType('text/html');
		}
	}
	else if( window.ActiveXObject )
	{
		/*
		 * IE6 - Why are you different!
		 */
		try
		{
			req_hdl = new ActiveXObject("MSXML2.XMLHTTP.3.0");
		}
		catch( exp_hdl )
		{
			try
			{
				req_hdl = new ActiveXObject("Microsoft.XMLHTTP");
			}
			catch( exp_hdl ) {}
		}
	}

	return (req_hdl);
}

function httpRequestMake(action, url, parameters, payload, handler, mtype, async)
{
	var	http_request;
	
	/*
	 * Create a HTTP request.
	 */
	http_request = httpRequestCreate();
	if( !http_request )
	{
		alert('Cannot create XMLHTTP instance');
		return (null);
	}
	
	/*
	 * Setup the HTTP request object.
	 */
	if( async == true )
	{
		http_request.onreadystatechange = function() { handler(http_request); };
	}
	if( parameters == null )
	{
		parameters = "";
	}
	http_request.open(action, url + parameters, async);
	if( "withCredentials" in http_request && async == true )
	{
		http_request.withCredentials = true;
	}
	http_request.setRequestHeader('Content-Type', mtype);
	http_request.setRequestHeader('Accept', mtype);
	http_request.send(payload);
	
	return (http_request);
}

/***********************************************************************
 * XML Loading/Parsing related functions.
 **********************************************************************/
function xmlLoadDataFromURL( url, mtype )
{
	var	xhttp;
	
	/*
	 * Lets make a very basic HTTP request for the XML document.
	 */
	try
	{
		if( window.XMLHttpRequest )
		{
			xhttp = new XMLHttpRequest();
		}
		else if( window.ActiveXObject )
		{
			xhttp = new ActiveXObject("Microsoft.XMLHTTP");
		}
		else
		{
			return (null);
		}

		xhttp.open("GET", url, false);
		try
		{
			xhttp.responseType = "msxml-document";
		}
		catch(a) {}
		xhttp.setRequestHeader("Accept", mtype);
		xhttp.send(null);
	
	}
	catch( exp_hdl )
	{
		alert("HTTP Request Exception: [" + exp_hdl.toString() + "]");
	}
	
	return (xhttp.responseXML);
}

function xmlParse(text)
{
	var	xmldoc;

	/*
	 * Parse the XML text that has been provided.
	 */
	if( window.DOMParser )
	{
		parser = new DOMParser();
		xmldoc = parser.parseFromString(text, "text/xml");
	}
	else
	{
		xmldoc = new ActiveXObject("Microsoft.XMLDOM");
		xmldoc.async = "false";
		xmldoc.loadXML(text);
	}

	return (xmldoc);
}

/***********************************************************************
 * XSL Transformations.
 **********************************************************************/
function xslTransformXML( xsl, xml )
{
	var	result;
	
	/*
	 * Load the XSL file and RDF data.
	 */
	try
	{
		/*
		 * Code for IE.
		 */
		if( window.ActiveXObject )
		{
			/*
			 * Transform the XML document.
			 */
			result = xml.transformNode(xsl);
		}
		else if( document.implementation &&
			 document.implementation.createDocument )
		{
			var	xsltproc;

			/*
			 * Create an XSLT processor and import the style.
			 */
			xsltproc = new XSLTProcessor();
			xsltproc.importStylesheet(xsl);

			/*
			 * Transform the XML document.
			 */
			result = xsltproc.transformToFragment(xml, document);
		}

	}
	catch( exp_hdl )
	{
		alert(exp_hdl.toString());
		result = null;
	}
	
	return (result);
}

/***********************************************************************
 * Dialog Display Utility functions.
 **********************************************************************/
function showPageInModalDialog(base_url, width, height, protocol, norval)
{
	var 	rval;
	var	url;
	var	args;
	
	/*
	 * Build the full URL. We are going to be tagging on some dimensions for
	 * the window itself.
	 */
	url = BASE_URI + "/dialogui.html#" + width + "@" + height + "@" + protocol + "@" + base_url; 
	
	/*
	 * Build the arguments for the dialog.
	 */
	args = "dialogWidth:" + width + "; dialogHeight:" + height + "; center:yes, resizable: no, status: no, help: no";
	
	/*
	 * Create a model dialog which a re-direction HTML page for IFRAME embedding.
	 */
	rval = window.showModalDialog(url, "showModalDialog", args);
	if( norval == false )
	{
		return (rval);
	}
}

function showSubWindow(url, width, height)
{
	var 	rval;
	var	args;
	
	/*
	 * Create the dialogs arguments.
	 */
	args = "dialogWidth:" + width + "px; dialogHeight:" + height + "px; center:yes, resizable: no, status: no, help: no";
	
	/*
	 * Create a model dialog for the defined URL.
	 */
	rval = window.showModalDialog(url, "showModalDialog", args);
	if( rval != null )
	{
		if( console && console.log )
		{
			console.log("Response From Modal Dialog = [" + rval + "]");
		}
	}
}

/***********************************************************************
 * Dialog UI IFRame embedding support functions.
 **********************************************************************/
function showDialogUI( url, width, height, protocol, return_url, msg_handler )
{
	var	ie;
	var	frame;
	
	/*
	 * Step #1: Create an iframe with a fragment to indicate protocol.
	 * Step #2: set the iframe's window.name to indicate the Return URL.
	 */
	ie = window.navigator.userAgent.indexOf("MSIE");
	if( ie > 0 )
	{
		frame = document.createElement('<iframe name=\'' + url + '\'>');
	}
	else
	{
		frame = document.createElement('iframe');
		frame.name = url;
	}
	if( protocol != null )
	{
		frame.src = url + '#' + protocol;
	}
	else
	{
		frame.src = url;
	}
	frame.width = width;
	frame.height = height;
	frame.msg_handler = msg_handler;
	frame.name = return_url;
	frame.return_url = return_url;
	
	/*
	 * Step #3: We need to listen for "onload" events on the iframe.
	 */
	if( ie > 0 )
	{
		frame.attachEvent("onload", onDialogUIFrameLoaded);
	}
	else
	{
		frame.onload = onDialogUIFrameLoaded;
	}
	
	return (frame);
}

function onDialogUIFrameLoaded()
{
	var	location;
	
	/*
	 * The UI frame has been loaded.
	 */
	try
	{
		/*
		 * Step #4: When the frame's location is equal to the Return
		 * URL, then read response and return.
		 *
		 * NOTE: May throw an exception if the frame's location is
		 * still a different origin.
		 */
		location = this.contentWindow.location.toString();
		if( location == this.return_url )
		{
			var message = this.contentWindow.name;
			this.msg_handler(message);
		}
	}
	catch( exp_hdl )
	{
		// Ignore: access exception when trying to access window name.
	}
}

/***********************************************************************
 * HTML Table support functions.
 **********************************************************************/
function addRowToTable( table, cells )
{
	var	row;
	var	cell;
	var	idx;

	/*
	 * Create a new row in the table and add the cell columns values.
	 */
	row = table.insertRow(table.rows.length);

	for( idx = 0; idx < cells.length; ++idx )
	{
		cell = row.insertCell(idx);
		cell.innerHTML = cells[idx].value
		cell.style.textAlign = cells[idx].align;
		if( cells[idx].width )
		{
			cell.style.width = cells[idx].width;
		}
	}
}

/***********************************************************************
 * System information table populations.
 **********************************************************************/
function getsysinfoCB( sysinfo, cbs )
{
	var	cells;
	var	html;

	/*
	 * Add the REST API elements to the table.
	 */
	cells = new Array();
	cells.push( { value : "Version : ", align : "right" } );
	cells.push( { value : sysinfo.rest.version, align : "left" } );
	addRowToTable(cbs.restapi_tbody, cells);

	cells = new Array();
	cells.push( { value : "Minor : ", align : "right" } );
	cells.push( { value : sysinfo.rest.minor, align : "left" } );
	addRowToTable(cbs.restapi_tbody, cells);

	cells = new Array();
	cells.push( { value : "Major : ", align : "right" } );
	cells.push( { value : sysinfo.rest.major, align : "left" } );
	addRowToTable(cbs.restapi_tbody, cells);

	/*
	 * Add the OSLC API elements to the table.
	 */
	cells = new Array();
	cells.push( { value : "Version : ", align : "right" } );
	cells.push( { value : sysinfo.oslc.version, align : "left" } );
	addRowToTable(cbs.oslcapi_tbody, cells);

	cells = new Array();
	cells.push( { value : "Minor : ", align : "right" } );
	cells.push( { value : sysinfo.oslc.minor, align : "left" } );
	addRowToTable(cbs.oslcapi_tbody, cells);

	cells = new Array();
	cells.push( { value : "Major : ", align : "right" } );
	cells.push( { value : sysinfo.oslc.major, align : "left" } );
	addRowToTable(cbs.oslcapi_tbody, cells);

	/*
	 * Add the compile elements to the table.
	 */
	cells = new Array();
	cells.push( { value : "Full Details : ", align : "right", width : "25%" } );
	cells.push( { value : sysinfo.compile.full_details, align : "left" } );
	addRowToTable(cbs.compile_tbody, cells);

	cells = new Array();
	cells.push( { value : "Date : ", align : "right", width : "25%" } );
	cells.push( { value : sysinfo.compile.date, align : "left" } );
	addRowToTable(cbs.compile_tbody, cells);

	cells = new Array();
	cells.push( { value : "Machine : ", align : "right", width : "25%" } );
	cells.push( { value : sysinfo.compile.machine, align : "left" } );
	addRowToTable(cbs.compile_tbody, cells);

	cells = new Array();
	cells.push( { value : "System : ", align : "right", width : "25%" } );
	cells.push( { value : sysinfo.compile.system, align : "left" } );
	addRowToTable(cbs.compile_tbody, cells);

	cells = new Array();
	cells.push( { value : "Build Version : ", align : "right", width : "25%" } );
	cells.push( { value : sysinfo.compile.build_version, align : "left" } );
	addRowToTable(cbs.compile_tbody, cells);
}

function getsysinfo( document, id_restapi, id_oslcapi, id_compile )
{
	var	sysinfo;
	var	cbs;

	/*
	 * Build the callback data structure for the system information
	 * call.
	 */
	cbs =	{
			request_cb : getsysinfoCB,
			restapi_tbody : document.getElementById(id_restapi),
			oslcapi_tbody : document.getElementById(id_oslcapi),
			compile_tbody : document.getElementById(id_compile)
		};

	/*
	 * Create a system information instance and get the actual system
	 * information.
	 */
	sysinfo = new OSSysInfo();

	sysinfo.getSysInfo(cbs);
}

/***********************************************************************
 * UI Preview support methods.
 **********************************************************************/
function uipGetSeverityName(evals, value)
{
	var	idx;
	var	name = null;

	idx = 0;
	while( idx < evals.severities.length && name == null )
	{
		if( evals.severities[idx].value == value )
		{
			name = evals.severities[idx].name;
		}
		idx++;
	}

	if( name == null )
	{
		name = "<unknown>";
	}

	return (name);
}

/***********************************************************************
 * Misc.
 **********************************************************************/
function zeropad( val )
{
	return (("0" + val).slice(-2));
}

function replaceCharAt( sval, idx, cval )
{
	return (sval.substring(0, idx) + cval + sval.substring((idx + 1)));
}

function encodeHTMLMapper(cval)
{
	var encoding_map =	{
					"&" : "&amp;",
					"'" : "&#39;",
					"<" : "&lt;",
					">" : "&gt;",
					"\"" : "&quot;"
				};
	return (encoding_map[cval]);
}

function encodeHTML(sval)
{
	return (sval.replace(/[&"'<>]/g, encodeHTMLMapper));
}
