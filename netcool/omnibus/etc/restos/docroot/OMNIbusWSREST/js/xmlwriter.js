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
 * ObjectServer REST API class definitions.
 **********************************************************************/
function XMLWriter() {
	this.subscribers = [];
}

(function() {
	/*
	 * Local variables of the XMLWriter class.
	 */
	XMLWriter.prototype.encoding = 'ISO-8859-1';
	XMLWriter.prototype.version  = 	'1.0';
	
	XMLWriter.prototype.stack = null;
	XMLWriter.prototype.active = null;
	XMLWriter.prototype.root = null;
	
	XMLWriter.prototype.documentStart = function()
	{
		this.close();
		this.stack = new Array();
	};
	
	XMLWriter.prototype.documentEnd = function()
	{
		this.active = this.root;
		this.stack = new Array();
	};
	
	XMLWriter.prototype.elementStart = function( ns, name )
	{
		var	node;
		
		/*
		 * Start a new node with this name, and an
		 * optional name space.
		 */
		if( ns )
		{
			name = ns + ':' + name;
		}
		
		/*
		 * Create a new node.
		 */
		node = {
				name:		name,
				children: 	[],
				attrs:		{}
			};
		
		/*
		 * Add the new node to the XML document as required.
		 */
		if( this.active )
		{
			this.active.children.push(node);
			this.stack.push(this.active);
		}
		else
		{
			this.root = node;
		}
		this.active = node;
	};
	
	XMLWriter.prototype.elementEnd = function()
	{
		this.active = this.stack.pop() || this.root;
	};
	
	XMLWriter.prototype.elementAddAttribute = function( name, value )
	{
		if( this.active )
		{
			this.active.attrs[name] = value;
		}
	};
	
	XMLWriter.prototype.elementAddTextValue = function( text )
	{
		if( this.active )
		{
			this.active.children.push(text);
		}
	};
	
	XMLWriter.prototype.elementAdd = function( ns, name, text )
	{
		this.elementStart(ns, name);
		this.elementAddTextValue(text);
		this.elementEnd();
	},
	
	XMLWriter.prototype.flush = function()
	{
		var	buffer;
		var	xmldoc;
		
		/*
		 * Convert the structure to a string representation.
		 */
		if( this.stack && this.stack[0] )
		{
			this.documentEnd();
		}
		
		buffer = '<?xml version="' + this.version + '" encoding="' + this.encoding + '" ?>';
		buffer = [ buffer ];
		
		if( this.root )
		{
			this.format(this.root, buffer);
		}
		
		xmldoc = "";
		while( buffer.length > 0 )
		{
			xmldoc = buffer.pop() + xmldoc;
		}
			
		return (xmldoc);
	};
	
	XMLWriter.prototype.close = function()
	{
		if( this.root )
		{
			clean( this.root );
		}
		this.active = null;
		this.root = null;
		this.stack = null;
	};
	
	XMLWriter.prototype.getDocument = function()
	{
		if( window.ActiveXObject )
		{ //MSIE
			var doc = new ActiveXObject('Microsoft.XMLDOM');
			doc.async = false;
			doc.loadXML(this.flush());
			return doc;
		}
		else
		{	// Mozilla, Firefox, Opera, etc.
			return (new DOMParser()).parseFromString(this.flush(),'text/xml');
		}
	};
	
	XMLWriter.prototype.format = function( node, buffer )
	{
		var	attr = 0;
		var	child;
		var	xml = null;
		var	idx;
		var	nc;
		
		/*
		 * Format the current node.
		 */
		xml = "<" + node.name;
		nc = node.children.length;
		for( attr in node.attrs )
		{
			xml += ' ' + attr + '="' + node.attrs[attr] + '"';
		}
		xml += nc ? '>' : ' />';
		buffer.push(xml);
			
		/*
		 * Add the children nodes.
		 */
		idx = 0;
		if( nc )
		{
			do
			{
				child = node.children[idx++];
				if( typeof child == 'string' )
				{
					if( nc == 1 )
					{
						//single text node
						return buffer.push((buffer.pop() + child + '</' + node.name + '>'));
					}
					else
					{
						//regular text node
						buffer.push(child);
					}
				}
				else if( typeof child == 'object' )
				{	
					//element node
					this.format(child, buffer);
				}
			} while( idx < nc );
			buffer.push('</' + node.name + '>' );
		}
	};
	
	XMLWriter.prototype.clean = function( node )
	{
		var	clen;
		
		clen = node.children.length;
		while( clen-- )
		{
			if( typeof node.children[clen] == 'object' )
			{
				this.clean(node.children[clen]);
			}
		}
		node.name = null;
		node.attrs= null;
		node.children = null;	
	};
}());
