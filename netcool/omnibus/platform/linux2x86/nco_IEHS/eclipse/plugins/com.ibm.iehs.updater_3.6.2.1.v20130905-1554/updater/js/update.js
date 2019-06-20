/*******************************************************************************
 *(C) Copyright IBM Corp. 2010
 * IBM Confidential
 * OCO Source Materials
 *
 * The source code for this program is not published or otherwise
 * divested of its trade secrets, irrespective of what has been
 * deposited with the U.S. Copyright Office.
 *******************************************************************************/
var isMozilla = navigator.userAgent.indexOf('Mozilla') != -1 && parseInt(navigator.appVersion.substring(0,1)) >= 5;
var isIEBrowser = navigator.userAgent.indexOf('MSIE') != -1;
if (isMozilla) {
  document.addEventListener('click', mouseClickHandler, true);
}
else{
  document.onclick = mouseClickHandler;
}

minus = new Image();
minus.src = "images/minus.gif";
plus = new Image();
plus.src = "images/plus.gif";

/**
 * Returns true when this is an expanded tree node
 */
function isExpanded(node) {
  return node.className == "expanded";
}

/**
 * Returns true when this is a collapsed tree node
 */
function isCollapsed(node) {
  return  node.className == "collapsed";
}

/**
 * Returns the target node of an event
 */
function getTarget(e) {
	var target;
  	if (isMozilla){
  		target = e.target;
  	}	else if (isIEBrowser){
   		target = window.event.srcElement;
  	}
	return target;
}

/**
 * Returns true when the node is the plus or minus icon
 */
function isPlusMinus(node) {	
	
	var flag;
	try {
		flag = (node.nodeType != 3 && node.tagName == "IMG" && (node.className == "expanded" || node.className == "collapsed"));
	}catch(e){
	}
	return flag;
}

/**
 * handler for expanding / collapsing topic tree
 */
function mouseClickHandler(e) {
  	var clickedNode = getTarget(e);
  	if (isPlusMinus(clickedNode) )	{	
    	if (isCollapsed(clickedNode)) {
   			expand(clickedNode);
    	} else if (isExpanded(clickedNode)) {
  	  		collapse(clickedNode);
    	}
  	}
 }
 
 
 /**
 * Collapses a tree rooted at the specified element
 */
function collapse(node) {
  node.className = "collapsed";
  node.src = plus.src;
  node.alt = showDe;
  node.title = showDe;
  // set the UL as well
  var ul = getChildNode(node.parentNode, "UL");
  if (ul != null) {
  ul.className = "collapsed";
  }
}

/**
 * Expands a tree rooted at the specified element
 */
function expand(node) {
  	node.className = "expanded";
  	node.src = minus.src;
    node.alt = hideDe;
    node.title = hideDe;
  	// set the UL as well
  	var ul = getChildNode(node.parentNode, "UL");
  	if (ul != null){
  		ul.className = "expanded";
  	}
}

/**
 * Returns the child node with specified tag
 */
function isValid()
{
    var unChecked = true;
    
    var elements=document.selectForm.elements; 
    var counter=elements.length; 
    
    for(var i=0; i<counter; i++){ 
            var element=elements[i]; 
            if(element.checked == true&&element.type=='checkbox'){ 
             unChecked=false; 
            } 
        } 
		
        document.getElementById('installbutton').disabled=unChecked;

    } 

/**
 * Returns the child node with specified tag
 */
function getChildNode(parent, childTag) {
	var list = parent.childNodes;
	if (list == null) {
		return null;
	}
	for (var i=0; i<list.length; i++) {
		if (list.item(i).tagName == childTag) {
			return list.item(i);
		}
	}
	return null;
}

function clickhandler(arg){
	var imageNode = arg.parentNode.firstChild;
    if (isCollapsed(imageNode)) {
   		expand(imageNode);
    } else if (isExpanded(imageNode)) {
  	  	collapse(imageNode);
    }
}

/**
 * Handler for key down (arrows)
 */
function keyDownHandler(key, target)
{
	if(key == 79) {
		key = 39;
	} else if(key == 66){
    	key = 37;
	} else if (key != 37 && key != 39) {
		return true;
	}
 	if (key == 39) { // Right arrow, expand
		if (isCollapsed(target)){
			expand(target);
		}
  	} else if (key == 37) { // Left arrow,collapse
		if (isExpanded(target)) {
			collapse(target);
		}
  	} 
  			
  	return false;
}

//clear all children of a DOM node
function clearAllChildren(node) {
	node.parentNode.replaceChild(node.cloneNode(false), node);
}

