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

/***********************************************************************
 * OSLC Event Management related elements.
 **********************************************************************/
function OslcEmConsumer() {
	this.subscribers = [];
}

(function() {
	/*
	 * Required XML name space definitions.
	 */
	var XML_NS = {
		DC: "http://purl.org/dc/terms/",
		RDF: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
		OSLC: "http://open-services.net/ns/core#",
		CRTV: "http://open-services.net/ns/crtv#",
		RR: "http://jazz.net/ns/ism/registry#",
		OSLC_EM: "http://jazz.net/ns/ism/event/omnibus#",
		OSLC_EMP: "http://jazz.net/ns/ism/event/omnibus/itnm#",
		OSLC_EMB: "http://jazz.net/ns/ism/event/omnibus/tbsm#",
		OSLC_EMM: "http://jazz.net/ns/ism/event/omnibus/misc#"
	};
	
	var XML_NS_PREFIX = {
			DC: "dcterms",
			RDF: "rdf",
			OSLC: "oslc",
			CRTV: "crtv",
			RR: "rr",
			OSLC_EM: "oslcem",
			OSLC_EMP: "oslcemp",
			OSLC_EMB: "oslcemb",
			OSLC_EMM: "oslcemm"
		};

	var OSLCEM_RESOURCE_TYPE = {
			EVENT: "Event",
			JOURNAL: "Journal",
			DETAIL: "Detail",
			ECIP: "CollectionIdentifierPattern"
		};

	var OSLCEM_RESOURCE_TYPE_URI = {
			EVENT: XML_NS.OSLC_EM + "Event",
			JOURNAL: XML_NS.OSLC_EM + "Journal",
			DETAIL: XML_NS.OSLC_EM + "Detail",
			ECIP: XML_NS.OSLC_EM + "CollectionIdentifierPattern"
		};

	/*
	 * Content types that are returned during the service discovery.
	 */
	var OSLC_CONTENT_TYPES = {
		PROVIDER_CATALOG: "application/x-oslc-disc-service-provider-catalog+xml",
		SERVICE_DESCRIPTION: "application/x-oslc-em-service-description+xml",
		RESOURCE_SHAPE: "application/rdf+xml",
		RDFXML: "application/rdf+xml",
		COMPACTVIEW: "application/x-oslc-compact+xml"
	};
	
	/*
	 * Service type for discovery.
	 */
	var OSLC_SERVICE_TYPE = {
	 	CREATION_FACTORY : 1,
	 	QUERY_CAPABILITY : 2,
	 	CREATION_DIALOG  : 3,
	 	SELECTION_DIALOG : 4
	};

	/**
	 */
	OslcEmConsumer.prototype.getResourceTypeURI = function()
	{
		return (OSLCEM_RESOURCE_TYPE_URI);
	};
	
	/**
	 */
	OslcEmConsumer.prototype.getServiceTypes = function()
	{
		return (OSLC_SERVICE_TYPE);
	};
	
	/**
	 */
	OslcEmConsumer.prototype.getXmlNS = function()
	{
		return (XML_NS);
	};
	
	/**
	 */
	OslcEmConsumer.prototype.getXmlNSPrefix = function(xmlns)
	{
		var	prefix;
		
		/*
		 * Determine the namespace prefix from the URI.
		 */
		if( xmlns == XML_NS.DC )
		{
			prefix = XML_NS_PREFIX.DC;
		}
		else if( xmlns == XML_NS.RDF )
		{
			prefix = XML_NS_PREFIX.RDF;
		}
		else if( xmlns == XML_NS.OSLC )
		{
			prefix = XML_NS_PREFIX.OSLC;
		}
		else if( xmlns == XML_NS.CRTV )
		{
			prefix = XML_NS_PREFIX.CRTV;
		}
		else if( xmlns == XML_NS.OSLC_EM )
		{
			prefix = XML_NS_PREFIX.OSLC_EM;
		}
		else if( xmlns == XML_NS.OSLC_EMP )
		{
			prefix = XML_NS_PREFIX.OSLC_EMP;
		}
		else if( xmlns == XML_NS.OSLC_EMB )
		{
			prefix = XML_NS_PREFIX.OSLC_EMB;
		}
		else if( xmlns == XML_NS.OSLC_EMM )
		{
			prefix = XML_NS_PREFIX.OSLC_EMM;
		}
		else
		{
			prefix = "";
		}
		
		return (prefix);
	};

	/**
	 */
	OslcEmConsumer.prototype.getElementByTagName = function(node, xmlns, name)
	{
		var	elements;

		/*
		 * Use the name space function is one is available, otherwise
		 * use the standard one with an appropriate prefix.
		 */
		if( node.getElementsByTagNameNS )
		{
			elements = node.getElementsByTagNameNS(xmlns, name);
		}
		else
		{
			elements = node.getElementsByTagName(this.getXmlNSPrefix(xmlns) + ":" + name);
		}

		return (elements);
	};

	/**
	 */
	OslcEmConsumer.prototype.getTextContent = function(node)
	{
		var	value;

		if( node.textContent )
		{
			value = node.textContent;
		}
		else
		{
			value = node.text;
		}

		return (value);
	};

	/**
	 */
	OslcEmConsumer.prototype.getAttribute = function(node, xmlns, name)
	{
		var	value;

		/*
		 * Use the name space function is one is available, otherwise
		 * use the standard one with an appropriate prefix.
		 */
		if( node.getAttributeNS )
		{
			value = node.getAttributeNS(xmlns, name);
		}
		else
		{
			value = node.getAttribute(this.getXmlNSPrefix(xmlns) + ":" + name);
		}

		return (value);
	};

	/**
	 */
	OslcEmConsumer.prototype.discoverServices = function(url, cbs)
	{
		var	consumer;
		var	http_request = null;
		
		/*
		 * Send a HTTP request to get the catalog.
		 */
		consumer = this;
		http_request = httpRequestMake( "GET", url + "catalog", null, null,
				 function(http_request)
				 {
				 	// We have a complete HTTP request.
					if( http_request.readyState == 4 )
					{
						// We have a successful GET!!
						if( http_request.status == 200 )
						{
							consumer.parseCatalog(http_request.responseText, cbs);
						}
					}
				 }, OSLC_CONTENT_TYPES.PROVIDER_CATALOG, true);
	};
	
	/**
	 */
	OslcEmConsumer.prototype.discoverServiceProvider = function(url, cbs)
	{
		var	http_request = null;
		var	consumer;
		
		/*
		 * Send a HTTP request to get the catalog.
		 */
		consumer = this;
		http_request = httpRequestMake( "GET", url, null, null,
				 function(http_request)
				 {
				 	// We have a complete HTTP request.
					if( http_request.readyState == 4 )
					{
						// We have a successful GET!!
						if( http_request.status == 200 )
						{
							consumer.parseServiceProvider(http_request.responseText, cbs);
						}
					}
				 }, OSLC_CONTENT_TYPES.SERVICE_DESCRIPTION, true);
	};
	
	/**
	 */
	OslcEmConsumer.prototype.discoverServiceResourceShape = function(url, type, create, cbs)
	{
		var	http_request = null;
		var	consumer;
		
		/*
		 * Send a HTTP request to get the resource shape.
		 */
		consumer = this;
		http_request = httpRequestMake( "GET", (url + "shape/"),
						("?type=" + type + "&create=" + create),
						null,
				 function(http_request)
				 {
				 	// We have a complete HTTP request.
					if( http_request.readyState == 4 )
					{
						// We have a successful GET!!
						if( http_request.status == 200 )
						{
							consumer.parseResourceShape(http_request.responseText, cbs);
						}
					}
				 }, OSLC_CONTENT_TYPES.RESOURCE_SHAPE, true);
	};

	/**
	 */
	OslcEmConsumer.prototype.discoverECIPS = function(url, cbs)
	{
		return (this.queryECIPS((url + "query/ecips"), cbs));
	};

	/**
	 */
	OslcEmConsumer.prototype.queryECIPS = function(url, cbs)
	{
		var	http_request = null;
		var	consumer;
		
		/*
		 * Send a HTTP request to get the resource shape.
		 */
		consumer = this;
		http_request = httpRequestMake( "GET", url, null, null,
				 function(http_request)
				 {
				 	// We have a complete HTTP request.
					if( http_request.readyState == 4 )
					{
						// We have a successful GET!!
						if( http_request.status == 200 )
						{
							consumer.parseECIPCollection(http_request.responseText, cbs);
						}
					}
				 }, OSLC_CONTENT_TYPES.RDFXML, true);
	};

	/**
	 */
	OslcEmConsumer.prototype.getECIP = function(url)
	{
		var	http_request = null;
		var	ecip = null;
		
		/*
		 * Send a HTTP request to get the resource shape.
		 */
		http_request = httpRequestMake( "GET", url, null, null, null,
				 	OSLC_CONTENT_TYPES.RDFXML, false);
		/*
		 * Do we have a complete HTTP request.
		 */
		if( http_request.readyState == 4 )
		{
			/*
			 * Do we have a successful GET!!
			 */
			if( http_request.status == 200 )
			{
				ecip = this.parseECIP(http_request.responseText);
			}
		}

		return (ecip);
	};

	/**
	 */
	OslcEmConsumer.prototype.getCompactView = function(url)
	{
		var	http_request = null;

		/*
		 * Send a HTTP request to get the compact view RDF/XML.
		 */
		http_request = httpRequestMake( "GET", url, null, null, null,
						OSLC_CONTENT_TYPES.COMPACTVIEW,
						false );
		/*
	 	 * Do we have a successful GET!!
		 */
		if( http_request.status != 200 )
		{
			return (null);
		}
	
		/*
		 * Parse the response and return the structure.
		 */
		return (this.parseCompactView(http_request.responseText));
				
	};

	/**
	 */
	OslcEmConsumer.prototype.getEventData = function(url, filter, coldata, orderby)
	{
		var	http_request = null;
		var	uriparams;

		/*
		 * Add the required column selection URI parameter. 
		 */
		if( coldata != null )
		{
			uriparams =	"oslc.properties=" +
					this.addColumnData(coldata);
		}

		/*
		 * Add the order by definition, if there is one.
		 */
		if( orderby != null )
		{
			if( uriparams == null )
			{
				uriparams = "oslc.orderBy=";
			}
			else
			{
				uriparams += "&oslc.orderBy=";
			}
			uriparams += this.addColumnData(orderby);
		}

		/*
		 * Add the filter definition, if there is one.
		 */
		if( filter != null )
		{
			if( uriparams == null )
			{
				uriparams = "oslc.where=";
			}
			else
			{
				uriparams += "&oslc.where=";
			}
			uriparams += encodeURIComponent(filter);
		}

		if( uriparams != null )
		{
			uriparams = "?" + uriparams;
		}

		/*
		 * Send a HTTP request to get the compact view RDF/XML.
		 */
		http_request = httpRequestMake( "GET", url, uriparams,
						null, null,
						OSLC_CONTENT_TYPES.RDFXML,
						false );
		/*
	 	 * Do we have a successful GET!!
		 */
		if( http_request.status != 200 )
		{
			return (null);
		}
	
		/*
		 * Parse the response and return the structure.
		 */
		return (this.parseEventData(http_request.responseText));
				
	};

	/**
	 */
	OslcEmConsumer.prototype.parseCatalog = function(text, cbs)
	{
		var xmldoc;
		var em_sps;
		var url;
		var idx;
		
		/*
		 * Parse the XML document.
		 */
		xmldoc = xmlParse(text);
		
		/*
		 * We now need to locate the service providers that are defined
		 * and look these up.
		 */
		em_sps = this.getElementByTagName(xmldoc, XML_NS.OSLC, "ServiceProvider");
		for( idx = 0; idx < em_sps.length; ++idx )
		{
			url = this.getAttribute(em_sps[idx], XML_NS.RDF, "resource");
			this.discoverServiceProvider(url, cbs);
		}
	};
	
	/**
	 */
	OslcEmConsumer.prototype.parseServiceProvider = function(text, cbs)
	{
		var	xmldoc;
		var	sp;
		var	url;
		var	node;
		
		/*
		 * Parse the XML document.
		 */
		xmldoc = xmlParse(text);
		
		/*
		 * First we need to extract details on the service provider
		 * itself.
		 */
		sp = this.getElementByTagName(xmldoc, XML_NS.OSLC, "ServiceProvider");
		url = this.getAttribute(sp[0], XML_NS.RDF, "about");
		node = this.getElementByTagName(xmldoc, XML_NS.DC, "title");
		
		cbs.serviceprovider_cb( {
						label : this.getTextContent(node[0]),
						url   : url
					 }, cbs.cb_data );
		
		/*
		 * We now need to locate all of the delegated UI dialogs.
		 */
		this.parseService(	xmldoc, cbs, "CreationFactory", "creation", 
		 			OSLC_SERVICE_TYPE.CREATION_FACTORY );
		this.parseService(	xmldoc, cbs, "QueryCapability", "queryBase", 
		 			OSLC_SERVICE_TYPE.QUERY_CAPABILITY ); 
		this.parseService(	xmldoc, cbs, "creationDialog", "dialog", 
		 			OSLC_SERVICE_TYPE.CREATION_DIALOG );
		this.parseService(	xmldoc, cbs, "selectionDialog", "dialog", 
		 			OSLC_SERVICE_TYPE.SELECTION_DIALOG );
	};
	
	/**
	 */
	OslcEmConsumer.prototype.parseService = function(xmldoc, cbs, element, subelement, type)
	{
		var	nodes;
		var	url;
		var	label;
		var	idx;
		var	node;
		var	width = null;
		var	height= null;
		
		/*
		 * We now need to locate all of the defined service elements.
		 */
		nodes = this.getElementByTagName(xmldoc, XML_NS.OSLC, element);
		for( idx = 0; idx < nodes.length; ++idx )
		{
			node = this.getElementByTagName(nodes[idx], XML_NS.OSLC, "label");
			label = this.getTextContent(node[0]);
			
			node = this.getElementByTagName(nodes[idx], XML_NS.OSLC, subelement);
			url = this.getAttribute(node[0], XML_NS.RDF, "resource");
			
			node = this.getElementByTagName(nodes[idx], XML_NS.OSLC, "hintWidth");
			if( node.length > 0 )
			{ 
				width = this.getTextContent(node[0]);
			}
			
			node = this.getElementByTagName(nodes[idx], XML_NS.OSLC, "hintHeight");
			if( node.length > 0 )
			{ 
				height = this.getTextContent(node[0]);
			}
			
			cbs.service_cb( {
						type 	: type,
						label	: label,
						url  	: url,
						width 	: width,
						height 	: height
					 }, cbs.cb_data );
		}
	};
	
	/**
	 */
	OslcEmConsumer.prototype.parseResourceShape = function(text, cbs)
	{
		var	xmldoc;
		var	idx;
		var	node;
		var	name;
		var	type;
		var	readonly;
		var	occurs;
		var	xmlns;
		var	hidx;
		
		/*
		 * Parse the XML document.
		 */
		xmldoc = xmlParse(text);
		
		/*
		 * We now need to locate all of the property elements of the shape.
		 */
		nodes = this.getElementByTagName(xmldoc, XML_NS.OSLC, "Property");
		for( idx = 0; idx < nodes.length; ++idx )
		{
			node = this.getElementByTagName(nodes[idx], XML_NS.OSLC, "name");
			name = this.getTextContent(node[0]);
			
			node = this.getElementByTagName(nodes[idx], XML_NS.OSLC, "readOnly");
			readonly = ((this.getTextContent(node[0]) == "true") ? true : false);
			
			node = this.getElementByTagName(nodes[idx], XML_NS.OSLC, "valueType");
			type = this.getAttribute(node[0], XML_NS.RDF, "resource").split('#',2)[1];
			
			node = this.getElementByTagName(nodes[idx], XML_NS.OSLC, "occurs");
			occurs = this.getAttribute(node[0], XML_NS.RDF, "resource").split('#',2)[1];
			
			node = this.getElementByTagName(nodes[idx], XML_NS.OSLC, "propertyDefinition");
			xmlns = this.getAttribute(node[0], XML_NS.RDF, "resource");
			hidx = xmlns.lastIndexOf("#");
			if( hidx == -1 )
			{
				hidx = xmlns.lastIndexOf("/");
			}
			if( hidx != -1 )
			{
				xmlns = xmlns.substring(0, (hidx + 1));
			}
			
			cbs.shape_cb( {
				name		: name,
				type 		: type,
				readonly	: readonly,
				occurs 		: occurs,
				xmlns		: xmlns,
				xmlnsprefix	: this.getXmlNSPrefix(xmlns)
			 }, cbs.cb_data );
		}
	};

	/**
	 */
	OslcEmConsumer.prototype.parseECIPCollection = function(text, cbs)
	{
		var 	xmldoc;
		var 	idx;
		var 	ecips;
		var	type;
		var	node;
	
		/*
		 * Parse the XML document.
		 */
		xmldoc = xmlParse(text);

		/*
		 * We now need to locate the event collection identifier
		 * patterns that are defined in the response.
		 */
		ecips = this.getElementByTagName(xmldoc, XML_NS.RDF, "Description");
		for( idx = 0; idx < ecips.length; ++idx )
		{
			node = this.getElementByTagName(ecips[idx], XML_NS.RDF, "type");
			type = this.getAttribute(node[0], XML_NS.RDF, "resource");
			if( type == OSLCEM_RESOURCE_TYPE_URI.ECIP )
			{
				/*
				 * Extract the URI to the ECIP.
				 */
        			ecip = this.extractECIP(ecips[idx]);

				/*
				 * Call the callback function.
				 */
				cbs.ecip_cb(ecip, cbs.cb_data);
			}
		}
	};

	/**
	 */
	OslcEmConsumer.prototype.parseECIP = function(text)
	{
		var 	xmldoc;
		var 	ecip;
		var	type;
		var	node;
		var 	ecips;
		var	found;
	
		/*
		 * Parse the XML document.
		 */
		xmldoc = xmlParse(text);

		/*
		 * We now need to locate the event collection identifier
		 * patterns that are defined in the response.
		 */
		ecips = this.getElementByTagName(xmldoc, XML_NS.RDF, "Description");
		idx = 0;
		found = false;
		ecip = null;
		while( idx < ecips.length && found == false )
		{
			node = this.getElementByTagName(ecips[idx], XML_NS.RDF, "type");
			type = this.getAttribute(node[0], XML_NS.RDF, "resource");
			if( type == OSLCEM_RESOURCE_TYPE_URI.ECIP )
			{
				/*
				 * Extract the URI to the ECIP.
				 */
        			ecip = this.extractECIP(ecips[idx]);

				found = true;
			}
		}

		return (ecip);
	};

	/**
         */
        OslcEmConsumer.prototype.extractECIP = function(ecip)
        {
		var 	uri;
		var 	name;
		var 	uritmpl;
		var	type;
		var	node;
		var	uritmplvars;

		/*
		 * Extract the URI to the ECIP.
		 */
		uri = this.getAttribute(ecip, XML_NS.RDF, "about");

		/*
		 * Get the ECIP describes.
		 */
		node = this.getElementByTagName(ecip, XML_NS.OSLC, "resourceType");
		type = this.getAttribute(node[0], XML_NS.RDF, "resource");

		/*
		 * Get the name of the ECIP.
		 */
		node = this.getElementByTagName(ecip, XML_NS.DC, "title");
		name = this.getTextContent(node[0]);

		/*
		 * Get the URI template URI.
		 */
		node = this.getElementByTagName(ecip, XML_NS.RR, "uriPattern");
		uritmpl = this.getTextContent(node[0]);

		/*
		 * Get the URI template variables.
		 */
		uritmplvars = this.parseECIPTmplVars(ecip);

		/*
		 * Build and return the ECIP object.
		 */
		return ( 	{
					name		: name,
					uri 		: uri,
					uritmpl 	: uritmpl,
					restype		: type,
					uritmplvars	: uritmplvars
			 	} );
	};

	/**
	 */
	OslcEmConsumer.prototype.parseECIPTmplVars = function(ecip)
	{
		var	node;
		var	tmplvars;
		var	idx;
		var	uritmplvars;
		var	name;
		var	value;

		/*
		 * Create an array for the URI template variables.
		 */
		uritmplvars = new Array();

		/*
		 * We now need to locate all of the URI template variables in
		 * the ECIP definition.
		 */
		tmplvars = this.getElementByTagName(ecip, XML_NS.RR, "URITemplateVariable");
		for( idx = 0; idx < tmplvars.length; ++idx )
		{
			/*
			 * Get the variable name.
			 */
			node = this.getElementByTagName(tmplvars[idx], XML_NS.OSLC, "name");
			name = this.getTextContent(node[0]);

			/*
			 * Get the variable expansion definition.
			 */
			node = this.getElementByTagName(tmplvars[idx], XML_NS.RDF, "value");
			value = this.getTextContent(node[0]);

			/*
			 * Add a new value to the URI template array.
			 */
			uritmplvars[idx] = 	{
							name  : name,
							value : value
						};
		}

		return (uritmplvars);
	}

	/**
	 */
	OslcEmConsumer.prototype.parseCompactView = function(text)
	{
		var 	xmldoc;
		var	node;
		var 	previews;
		var	cview;
		var	name;

		/*
		 * Parse the XML document.
		 */
		xmldoc = xmlParse(text);

		/*
		 * Create the base compact view structure install.
		 */
		cview = {};

		/*
		 * We now need to get all of the previews.
		 */
		previews = this.getElementByTagName(xmldoc, XML_NS.OSLC, "Preview");
		for( idx = 0; idx < previews.length; ++idx )
		{
			/*
			 * Initialise the preview structure.
			 */
			preview = {};

			/*
			 * Get the document element.
			 */
			node = this.getElementByTagName(previews[idx], XML_NS.OSLC, "document");
			if( node != null )
			{
				preview["uri"] = this.getAttribute(node[0], XML_NS.RDF, "resource");
			}

			/*
			 * Get the width element.
			 */
			node = this.getElementByTagName(previews[idx], XML_NS.OSLC, "hintWidth");
			if( node != null )
			{
				preview["width"] = this.getTextContent(node[0]);
			}

			/*
			 * Get the height element.
			 */
			node = this.getElementByTagName(previews[idx], XML_NS.OSLC, "hintHeight");
			if( node != null )
			{
				preview["height"] = this.getTextContent(node[0]);
			}

			/*
			 * Get the previous node to determine whether it is a
			 * small or large preview.
			 */
			node = previews[idx].parentNode;
			if( node.prefix == "oslc" )
			{
				if( node.localName )
				{
					name = node.localName;
				}
				else
				{
					name = node.baseName;
				}

				if( name == "smallPreview" )
				{
					cview["spreview"] = preview;
				}
				else if( name == "largePreview" )
				{
					cview["lpreview"] = preview;
				}
			}
		}

		return (cview);
	};

	/**
         */
        OslcEmConsumer.prototype.extractEvent = function(node)
        {
		var	event;
		var	nlist;
		var 	cnode;

		/*
		 * Create an empty event object instance.
		 */
		event = {};

		/*
		 * Walk the properties of the event.
		 */
		nlist = node.childNodes;
		for( idx = 0; idx < nlist.length; ++idx )
		{
			cnode = nlist[idx];
			if(	cnode.nodeType == 1 &&
				cnode.nodeName != XML_NS_PREFIX.RDF + ":type" )
			{
				event[(cnode.nodeName.replace(":","_"))] = this.getTextContent(cnode);
			}
		}

		return (event);
	};

	/**
	 */
	OslcEmConsumer.prototype.parseEventData = function(text)
	{
		var 	xmldoc;
		var	node;
		var 	resources;
		var	edata;
		var	type;
		var	idx;

		/*
		 * Parse the XML document.
		 */
		xmldoc = xmlParse(text);

		/*
		 * Create the base event data structure install.
		 */
		edata = new Array();

		/*
		 * We now need to get all of the events in the RDF/XML.
		 */
		resources = this.getElementByTagName(xmldoc, XML_NS.RDF, "Description");
		for( idx = 0; idx < resources.length; ++idx )
		{
			node = this.getElementByTagName(resources[idx], XML_NS.RDF, "type");
			type = this.getAttribute(node[0], XML_NS.RDF, "resource");
			if( type == OSLCEM_RESOURCE_TYPE_URI.EVENT )
			{
				edata.push(this.extractEvent(resources[idx]));
			}
		}

		return (edata);
	};

	/**
	 */
	OslcEmConsumer.prototype.addColumnData = function(coldata)
	{
		var	uriparams = "";
		var	idx;

		/*
		 * Build the URI column data URI params.
		 */
		for( idx = 0; idx < coldata.length; ++idx )
		{
			/*
			 * Check for an order by specific element.
			 */
			if( coldata[idx].hasOwnProperty("desc") )
			{
				if( coldata[idx].desc )
				{
					uriparams += "-";
				}
			}

			/*
			 * Add the column entry to the definition.
			 */
			uriparams += 	coldata[idx].nsprefix + "%3A" +
					coldata[idx].property;
			if( (idx + 1) < coldata.length )
			{
				uriparams += "%2C";
			}
		}

		return (uriparams);
	};
}());
