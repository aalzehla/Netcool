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
 * ObjectServer REST/OSLC System information class.
 **********************************************************************/
function OSSysInfo() {
	this.subscribers = [];
}

(function() {
	/*
	 * System Information type strings.
	 */
	var SYSINFO_ITEM = {
			COMPILE: "compile",
			OSLC: "oslc",
			REST: "rest"
		};

	/**
	 */
	OSSysInfo.prototype.getSysInfo = function(cbs)
	{
		var	http_request = null;
		var	consumer;
		var	url;

		/*
		 * Build the system URI.
		 */
		url = SYSINFO_BASE_URI;
		
		/*
		 * Send a HTTP request to get the system information.
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
							cbs.request_cb(eval('('
 + http_request.responseText + ')'), cbs);
						}
					}
				 }, "application/json", true);
	};

	/**
	 */
	OSSysInfo.prototype.getSysInfoItem = function(item, cbs)
	{
		var	http_request = null;
		var	consumer;
		var	url;

		/*
		 * Build the system URI.
		 */
		url = SYSINFO_BASE_URI + "/" + item;
		
		/*
		 * Send a HTTP request to get the system informatiom item.
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
							cbs.request_cb(eval('('
 + http_request.responseText + ')'), cbs);
						}
					}
				 }, "application/json", true);
	};

	/**
	 */
	OSSysInfo.prototype.getSysInfoCompile = function(cbs)
	{
		this.getSysInfoItem(SYSINFO_ITEM.COMPILE, cbs);
	};

	/**
	 */
	OSSysInfo.prototype.getSysInfoOSLC = function(cbs)
	{
		this.getSysInfoItem(SYSINFO_ITEM.OSLC, cbs);
	};

	/**
	 */
	OSSysInfo.prototype.getSysInfoREST = function(cbs)
	{
		this.getSysInfoItem(SYSINFO_ITEM.REST, cbs);
	};
}());
