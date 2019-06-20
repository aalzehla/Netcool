<%--
 (C) Copyright IBM Corp. 2010
 IBM Confidential
 OCO Source Materials
 
 The source code for this program is not published or otherwise
 divested of its trade secrets, irrespective of what has been
 deposited with the U.S. Copyright Office.
--%> 
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
	"http://www.w3.org/TR/html4/strict.dtd">
<%@ include file="sheader.jsp"%>
<html lang="<%=ServletResources.getString("locale", request)%>" xml:lang="<%=ServletResources.getString("locale", request)%>">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<%response.setHeader("Pragma", "no-cache");
			response.setHeader("Cache-Control", "no-store, no-cache");
			response.setDateHeader("Expires", 0);
%>
<title><%=WebUpdaterResources.updates%></title>
<style type="text/css">
<%@ include file="css/update.css"%>
</style>
<script language="JavaScript" src="js/update.js" type="text/javascript"></script>
<script language="JavaScript" src="js/cancel.js" type="text/javascript"></script>
</head>

<%boolean isSafari = UrlUtil.isSafari(request);
			InstallUpdatesData data = new InstallUpdatesData(application,
					request, response);
  Object[] infoPageForUpdateFailure = {data.getInfoPageForUpdateFailure()};
%>

<body dir="<%=direction%>"
	"
	style="margin-top: 0; margin-left: 0; margin-right: 0;">

<table width="100%" cellspacing="0" cellpadding="8" border="0">
	<tr>
		<td>
		<div id="caption">
		<h3><%=WebUpdaterResources.BeingInstalled%></h3>
		</div>
		</td>
	</tr>
	<tr>
		<td>
		<div id="loadingWarningButton"></div>
		</td>
	</tr>
	<tr>
		<td>
		<div class='panel' id='itemsPanel'>
		<div class='innerPanel'>
		<ul id="itemPanel" class="itemPanel">
			<%=data.getScriptForExistingFeatures()%>
			<%=data.getScriptForNewfeatures()%>
		</ul>
		<br>
		</div>
		</div>
		</td>
	</tr>
	<tr>
		<td>
		<div id="FinishButtonDiv"></div>
		</td>
	</tr>
</table>
<div id="progressdiv">

<div id="statusContainer" align="center"></div>


<div align="right" style="padding-top: 50px;padding-right: 25px;">
<button onclick="cancel('installFeature')"><%=WebUpdaterResources.StopButton%>
</button>
</div>

<textarea id="kickoffwarning" style="display:none"><%=WebUpdaterResources.loading_kickoff_warning%></textarea>
</div>

<script language="JavaScript" type="text/javascript">
<!-- ajax progressbar -->
var isIE = <%=data.isIE()%>;
var req;
var percentOfProcess = -1
var errorHappens = false;
var oneOrMoreOfSuccessUpdate = false;
var installCanceled = false;
var installComplete = false;

function getUpdateStatus() {
    var url = "UpdateServlet?action=getUpdatingStatus";
    initRequest(url);
    // set callback function
    req.onreadystatechange = processXMLResponse;
    req.send(null);
}

function initRequest(url) {
    if (window.XMLHttpRequest) {
        req = new XMLHttpRequest();
    } else if (window.ActiveXObject) {
        req = new ActiveXObject("Microsoft.XMLHTTP");
    }
    req.open("GET", url, true);
}

function processXMLResponse() {
    if (req.readyState == 4) {
        if (req.status == 200) {
            var items = req.responseXML.getElementsByTagName("updatingPercent");
            if(items){
            	percentOfProcess = items[0].firstChild.nodeValue;
			}
			
			var statuses = req.responseXML.getElementsByTagName("updatingStatus");
			try{
				var statusMessage = statuses[0].firstChild.nodeValue;
				showStatus(statusMessage)
             } catch(e){
       			//some strange character lead to this exception
             }
			
	        if (percentOfProcess < 100) {
	            setTimeout("getUpdateStatus()", 2000);
	        } else {
	        	installComplete = true;
	        }
	     }
    }
}


function showStatus(statusMessage) {
	var statusContainer = document.getElementById("statusContainer");
	clearAllChildren(statusContainer);
	
	var newStatusContainer = document.getElementById("statusContainer");
	newStatusContainer.appendChild(document.createTextNode(statusMessage));
}

function syncIndicator() {
	//make the indicator sync to the most recent status
	submitIndicatorQuery();
	
}


function wanringForLoading() {
	var caption = document.getElementById("caption");
	clearAllChildren(caption);
	
	var caption = document.getElementById("itemsPanel");
	caption.style.visibility="hidden";
	
	
	var newCaption = document.getElementById("caption");
	var head = document.createElement("h3");
	newCaption.appendChild(head);
	
	head.innerHTML = document.getElementById("kickoffwarning").value;
	
	//remove the status
	var progressdiv = document.getElementById("progressdiv");
		clearAllChildren(progressdiv);
	
	var finishButtonDiv = document.getElementById("loadingWarningButton");
	var divContainer = document.createElement("div");
	
		finishButtonDiv.appendChild(divContainer);
		
		divContainer.setAttribute("align", "right");

	var finishButton = document.createElement("button");
	
	if(isIE) {
	    finishButton.attachEvent("onclick", complete);
	}else {
		finishButton.setAttribute("onclick","complete()");
	}

		divContainer.appendChild(finishButton);
	
		finishButton.appendChild(document.createTextNode("<%=WebUpdaterResources.OK%>"))
	
}

function complete() {
	var finishButtonDiv = document.getElementById("loadingWarningButton");
	 clearAllChildren(finishButtonDiv);
	var caption = document.getElementById("caption");
	clearAllChildren(caption);
	
	var newCaption = document.getElementById("caption");
	var head = document.createElement("h3");
	newCaption.appendChild(head);
		
	if (!errorHappens) {
		head.innerHTML = "<%=WebUpdaterResources.FollowingFeautreInstalled%>";
	} else {		
		head.innerHTML = "<%=java.text.MessageFormat.format(WebUpdaterResources.FollowingFeatureInstalledWithError,infoPageForUpdateFailure)%>";
	}
	var caption = document.getElementById("itemsPanel");
	caption.style.visibility= "visible";
	renderFinishUI();
	
}

// ajax cancel function 

function cancelInstall() {


	//stop polling the status 
	installCanceled = true;
	
	
		var caption = document.getElementById("caption");
		clearAllChildren(caption);
		var newCaption = document.getElementById("caption");
	    var head = document.createElement("h3");
		newCaption.appendChild(head);
		
		if (!errorHappens) {
			head.appendChild(document.createTextNode("<%=WebUpdaterResources.FollowingFeatureInstalledWithStop%>")); 
		} else {
			head.innerHTML = "<%=java.text.MessageFormat.format(WebUpdaterResources.FollowingFeatureInstalledWithErrorAndStop,infoPageForUpdateFailure)%>";
		}
		
		removeFeaturesNotProcessed();
		
		renderFinishUI();
	
}

var removalRequest;

function removeFeaturesNotProcessed() {
 	var url = "UpdateServlet?action=getRemovalFeatures";
    initRemovalRequest(url);
    // set callback function
    removalRequest.onreadystatechange = processFeatureRemovalResponse;
    removalRequest.send(null);    
}

function initRemovalRequest(url) {
    if (window.XMLHttpRequest) {
        removalRequest = new XMLHttpRequest();
    } else if (window.ActiveXObject) {
        removalRequest = new ActiveXObject("Microsoft.XMLHTTP");
    }
    removalRequest.open("GET", url, true);
}


function processFeatureRemovalResponse() {

     var proccesedFeatures = new Array();
     var index=0;
     
	if (removalRequest.readyState == 4) {
        if (removalRequest.status == 200) {
        
                          
          for (var i = 0; i < removalRequest.responseXML.getElementsByTagName("img").length; i ++) {
	            var img = removalRequest.responseXML.getElementsByTagName("img")[i];
	            var img_Index = img.firstChild.nodeValue;
	            var img_src = getImageSrc(img_Index);
	            			
				var id = removalRequest.responseXML.getElementsByTagName("id")[i];
				var img_id = id.firstChild.nodeValue;
				if(!installCancelled)
				showIndicator(img_src, img_id);
        	}
        	
        	
   		}
    }
   
  		 //each feature is wrapped in a <li> element   
         var features = document.getElementsByTagName("li");
	     //remove the feature not successfully updated from the UI     
         for (var i = 0; i < features.length; i++) {
		
       	     removeNode(features[i]);	
      		}
   
}

function removeNode(node){

	var list = node.childNodes;
	if (list == null) return;
	if (list.item(0) == null) return; 
	if (list.item(0).tagName == "img"||list.item(0).tagName == "IMG"){
	
	if (list.item(0).src.indexOf("images/package.gif")>0||list.item(0).src.indexOf("images/next.gif")>0){
	
	clearAllChildren(node);
	}
	}
}

/**
 * Returns the child node with specified tag
 */
function getChildNode(parent, childTag)
{
	var list = parent.childNodes;
	if (list == null) return null;
	for (var i=0; i<list.length; i++)
		if (list.item(i).tagName == childTag)
			return list.item(i);
	return null;
}

function finish() {

	resetInstallOnServer();
	parent.parent.parent.window.location='../index.jsp';
	
}

getUpdateStatus();

<!-- ajax status indicator -->

var indicatorRequest;
function submitIndicatorQuery() {
    var url = "UpdateServlet?action=getStatusIndicator";
    initIndicatorRequest(url);
    // set callback function
    indicatorRequest.onreadystatechange = processIndicatorResponse;
    indicatorRequest.send(null);
}


function initIndicatorRequest(url) {
    if (window.XMLHttpRequest) {
        indicatorRequest = new XMLHttpRequest();
    } else if (window.ActiveXObject) {
        indicatorRequest = new ActiveXObject("Microsoft.XMLHTTP");
    }
    indicatorRequest.open("GET", url, true);
}



function processIndicatorResponse() {

    if (indicatorRequest.readyState == 4) {
    
        if (indicatorRequest.status == 200) {
        	
        	for (var i = 0; i < indicatorRequest.responseXML.getElementsByTagName("img").length; i ++) {
	            
	            var img = indicatorRequest.responseXML.getElementsByTagName("img")[i];
	            var img_Index = img.firstChild.nodeValue;
	            var img_src = getImageSrc(img_Index);
				
				var id = indicatorRequest.responseXML.getElementsByTagName("id")[i];
				var img_id = id.firstChild.nodeValue;
				showIndicator(img_src, img_id);
        	
        	}
			
        if (!installComplete && !installCanceled) {
        //if the install is not completed or canceled, refresh the install status.
            setTimeout("submitIndicatorQuery()", 2000);
            
        } else if(installComplete) {
        
        	wanringForLoading();
        	
        } else {
        // install cancelled, do nothing.
        }
        
       }
    }
}

function getImageSrc(index) {

	switch (index){
		case '0':
			return "images/next.gif";
		case '1':
			oneOrMoreOfSuccessUpdate = true;
			return "images/success.gif";
		case '2':
			errorHappens = true;
			return "images/error.gif";
	}
}

function showIndicator(img_src, img_id) {

    var feature = document.getElementById(img_id);
        
	var indicatorImg = document.getElementById("img_" + img_id);
	
	if (!indicatorImg) {
			
		var li = document.getElementById(img_id);		
		var img = document.createElement("img");
		img.src = img_src;
		img.height = 13;
		img.width = 13;
		img.id = "img_" + img_id;
		
		li.insertBefore(img, li.firstChild);
		
	} else {
		indicatorImg.src = img_src;
	}
	
}

function renderFinishUI(){
	//remove the status
	var progressdiv = document.getElementById("progressdiv");
		clearAllChildren(progressdiv);
	
	var finishButtonDiv = document.getElementById("FinishButtonDiv");
	var divContainer = document.createElement("div");
	
		finishButtonDiv.appendChild(divContainer);
		
		divContainer.setAttribute("align", "right");

	var finishButton = document.createElement("button");
	
	if(isIE) {
	    finishButton.attachEvent("onclick", finish);
	}else {
		finishButton.setAttribute("onclick","finish()");
	}
		divContainer.appendChild(finishButton);
	
		finishButton.appendChild(document.createTextNode("<%=WebUpdaterResources.FinishButton%>"))
}

//begin to poll the indicator status
submitIndicatorQuery();

</script>
<%
data.finishUpdate(request, response, session);
%>
</body>
</html>
