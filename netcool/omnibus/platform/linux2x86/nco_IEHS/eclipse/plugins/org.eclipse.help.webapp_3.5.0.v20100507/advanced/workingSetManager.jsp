<%--
 Copyright (c) 2000, 2010 IBM Corporation and others.
 All rights reserved. This program and the accompanying materials 
 are made available under the terms of the Eclipse Public License v1.0
 which accompanies this distribution, and is available at
 http://www.eclipse.org/legal/epl-v10.html
 
 Contributors:
     IBM Corporation - initial API and implementation
--%>
<%@ include file="header.jsp"%>

<% 
	WorkingSetManagerData data = new WorkingSetManagerData(application, request, response);
	WebappPreferences prefs = data.getPrefs();
	String dataSaveError = data.getSaveError();
	boolean showCriteriaScope = data.isCriteriaScopeEnabled();
%>


<html lang="<%=ServletResources.getString("locale", request)%>">
<head>
<title><%=ServletResources.getString("SelectWorkingSetTitle", request)%></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">


<style type="text/css">
<%@ include file="list.css"%>
</style>

<style type="text/css">
HTML, BODY {
	width:100%;
	height:100%;
	margin:0px;
	padding:0px;
	border:0px;
	overflow:auto;
}

BODY {
    font:<%=prefs.getViewFont()%>;
	background-color: <%=prefs.getToolbarBackground()%>;
	color:WindowText; 	
}

TABLE {
	width:auto;
	margin:0px;
	padding:0px;
}

TD, TR {
	margin:0px;
	padding:0px;
	border:0px;
}
TD.radio {
	white-space: nowrap;
}

BUTTON {
	font:<%=prefs.getViewFont()%>;
	margin:5px;
}

BUTTON {
    font-size:1.0em; 
}

FORM {
    margin: 0px;
    border: 0px;
}

#workingSetContainer {
	color:WindowText; 
	border: 2px inset ThreeDHighlight;
	margin:0px 5px;
	padding:5px;
	overflow:auto;
	height:140px;
	max-height:160px;
	background:Window;
}

#buttonArea {
    height:4em; 
<%
if (data.isMozilla()) {
%>
    padding-bottom:5px;
<%
}
%>
}

</style>

<script language="JavaScript" src="../<%=pluginVersion%>/advanced/resize.js"></script>
<script language="JavaScript" src="../<%=pluginVersion%>/advanced/utils.js"></script>
<script language="JavaScript" src="../<%=pluginVersion%>/advanced/list.js"></script>
<script language="JavaScript">
var isRTL = <%=isRTL%>;
var _active = null;
function highlightHandler(editflag)
{
	document.getElementById('selectws').checked = true;
	if(editflag == "Y"){
		document.getElementById('selectws_hidden').value = "Y";
	}
	else {
		document.getElementById('selectws_hidden').value = "N";
    }
	enableButtons();
}

// register handler
_highlightHandler = highlightHandler;

function onloadHandler() {
<%if(dataSaveError != null){%>
	alert("<%=dataSaveError%>");
	window.location="workingSetManager.jsp"
<%}
if(!data.isMozilla() || "1.3".compareTo(data.getMozillaVersion()) <=0){
// buttons are not resized immediately on mozilla before 1.3
%>
	sizeButtons();
<%}%>
	enableButtons();
	sizeList();
	//document.getElementById("alldocs").focus();
}

function sizeButtons() {
	var minWidth=60;

	if(document.getElementById("ok").offsetWidth < minWidth){
		document.getElementById("ok").style.width = minWidth+"px";
	}
	if(document.getElementById("cancel").offsetWidth < minWidth){
		document.getElementById("cancel").style.width = minWidth+"px";
	}
	if(document.getElementById("edit").offsetWidth < minWidth){
		document.getElementById("edit").style.width = minWidth+"px";
	}
	if(document.getElementById("remove").offsetWidth < minWidth){
		document.getElementById("remove").style.width = minWidth+"px";
	}
	if(document.getElementById("new").offsetWidth < minWidth){
		document.getElementById("new").style.width = minWidth+"px";
	}
}

function enableButtons() {
	if (document.getElementById('selectws').checked){
		document.getElementById("ok").disabled = (_active == null);	
		document.getElementById("edit").disabled = (_active == null);	
		if(document.getElementById('selectws_hidden').value == "N"){
			document.getElementById("remove").disabled = true;
		}
		else if(document.getElementById('selectws_hidden').value == "Y"){
			document.getElementById("edit").disabled = (_active == null);
			document.getElementById("remove").disabled = (_active == null);
		}
		
	} else {
		document.getElementById("ok").disabled = false;
		document.getElementById("edit").disabled = true;
		document.getElementById("remove").disabled = true;
	}
}

function getWorkingSet()
{
	if (_active != null && document.getElementById("selectws").checked)
		return _active.title;
	else
		return "";
}


function selectWorkingSet() {
	var workingSet = getWorkingSet();

	var search = window.opener.location.search;
	if (search && search.length > 0) {
		var i = search.indexOf("contents=");
		if (i >= 0){
			search = search.substring(0, i);
		}

		i = search.indexOf("criteria=");
		if (i >= 0){
			search = search.substring(0, i);
		}

		i = search.indexOf("workingSet=");
		if (i >= 0){
			search = search.substring(0, i);
		}
		else{
			search += "&";
		}

	} else {
		search = "?";
	}

	search += "workingSet=" + encodeURIComponent(workingSet);
	var searchWord = window.opener.document.forms["searchForm"].searchWord.value;
	if (searchWord)
		search += "&searchWord="+encodeURIComponent(searchWord);
    window.opener.location.replace(
		window.opener.location.protocol +
		"//" +
		window.opener.location.host + 
		window.opener.location.pathname +
		search);
 	window.close();
	return false;
}

function removeWorkingSet() {
	window.location.replace("workingSetManager.jsp?operation=remove&workingSet="+encodeURIComponent(getWorkingSet()));
	if (getWorkingSet()==window.opener.document.getElementById("scope").firstChild.nodeValue){
		window.opener.document.getElementById("scope").firstChild.nodeValue=
		    "<%=UrlUtil.JavaScriptEncode(ServletResources.getString("All", request))%>";
		window.opener.document.forms["searchForm"].workingSet.value=
		    "<%=UrlUtil.JavaScriptEncode(ServletResources.getString("All", request))%>";
	}
}

var workingSetDialog;
var w = <%=showCriteriaScope%>? 640:320;
var h = 500;

function newWorkingSet() { 	
	<%
	if (data.isIE()){
	%>
		var l = top.screenLeft + (top.document.body.clientWidth - w) / 2;
		var t = top.screenTop + (top.document.body.clientHeight - h) / 2;
	<%
	} else {
	%>
		var l = top.screenX + (top.innerWidth - w) / 2;
		var t = top.screenY + (top.innerHeight - h) / 2;
	<%
	}
	%>
	// move the dialog just a bit higher than the middle
	if (t-50 > 0) t = t-50;
	window.location="javascript://needModal";
	workingSetDialog = window.open("workingSet.jsp?operation=add&workingSet="+encodeURIComponent(getWorkingSet()), "workingSetDialog", "resizable=yes,height="+h+",width="+w +",left="+l+",top="+t);
	workingSetDialog.focus(); 
}

function editWorkingSet() {
	 	
	<%
	if (data.isIE()){
	%>
		var l = top.screenLeft + (top.document.body.clientWidth - w) / 2;
		var t = top.screenTop + (top.document.body.clientHeight - h) / 2;
	<%
	} else {
	%>
		var l = top.screenX + (top.innerWidth - w) / 2;
		var t = top.screenY + (top.innerHeight - h) / 2;
	<%
	}
	%>
	// move the dialog just a bit higher than the middle
	if (t-50 > 0) t = t-50;
		
	window.location="javascript://needModal";
	workingSetDialog = window.open("workingSet.jsp?operation=edit&workingSet="+encodeURIComponent(getWorkingSet()), "workingSetDialog", "resizable=no,height="+h+",width="+w+",left="+l+",top="+t );
	workingSetDialog.focus(); 
}

function closeWorkingSetDialog()
{
	try {
		if (workingSetDialog)
			workingSetDialog.close();
	}
	catch(e) {}
}

function sizeList() {
    resizeVertical("workingSetContainer", "filterTable", "buttonArea", 100, 30);
}

function escKeydownHandler(e){
	if(!e) e = window.event;
	var key;
	if (e.keyCode) key = e.keyCode;
	else if (e.which) key = e.which;
	if(key == 27){
		window.close();
	}
}

function radioKeydownHandler(e, obj){
	if(!e) e = window.event;
	var key;
	if (e.keyCode) key = e.keyCode;
	else if (e.which) key = e.which;

	var canUp = (obj.id == "selectws")? true: false;
	var canDown = (obj.id == "alldocs")? true: false;
	var selectId = canUp? "alldocs":"selectws";
	if ((key == 38 && canUp) || (key == 40 && canDown)) {
		document.getElementById(selectId).checked = true;
		if(isMozilla){
			document.getElementById(selectId).focus();
		}
		enableButtons();
	}
	
}

</script>

</head>

<body role="main" scroll="yes" dir="<%=direction%>" onload="onloadHandler()" onunload="closeWorkingSetDialog()" onresize = "sizeList()" <%if(data.isMozilla()){%>onkeydown="escKeydownHandler(event);"<%}%>>
<h1 id="workingSetManagerTitle" style="display:none;"><%=ServletResources.getString("SelectWorkingSetTitle", request)%></h1>
<form onsubmit="selectWorkingSet();return false;" role="form" aria-labelledby="workingSetManagerTitle">
	<table role="radiogroup" aria-label="Scope radio group" id="filterTable" cellspacing=0 cellpadding=0 border=0 align=center  style="background:<%=prefs.getToolbarBackground()%>; font:<%=prefs.getToolbarFont()%>;margin-top:5px;width:100%;">
		<tr><td class="radio">
			<input id="alldocs" type="radio" name="workingSet" onclick="enableButtons()" onkeydown="radioKeydownHandler(event, this);"><label for="alldocs" accesskey="<%=ServletResources.getAccessKey("selectAll", request)%>"><%=ServletResources.getLabel("selectAll", request)%></label>
		</td></tr>
		<tr><td class="radio">
			<input type="hidden" id="selectws_hidden" value="Y"/>
			<input id="selectws" type="radio" name="workingSet"  onclick="enableButtons()" onkeydown="radioKeydownHandler(event, this);"><label for="selectws" accesskey="<%=ServletResources.getAccessKey("selectWorkingSet", request)%>"><%=ServletResources.getLabel("selectWorkingSet", request)%></label>	
		</td></tr>
	</table>
<div id="workingSetContainer" >

<table id='list'  cellspacing='0' style="width:100%;">
<% 
String[] wsets = data.getWorkingSets();
String workingSetId = "";
int wsetsCount = wsets.length;
for (int i=0; i<wsets.length; i++)
{
	if (data.isCurrentWorkingSet(i))
		workingSetId = "a" + i;
%>
<tr class='list' id='r<%=i%>' style="width:100%;">
	<td align='<%=isRTL?"right":"left"%>' class='label' nowrap style="width:100%; padding-left:5px;">
		<a id='a<%=i%>' 
		   href='#' 
<%
	 if(!data.isWorkingSetEditable(wsets[i])){
%>
		   onclick="_active=this;highlightHandler('N')"
<%
	 }else {
%>
		   onclick="_active=this;highlightHandler('Y')"
<%} %>
   		   ondblclick="selectWorkingSet()"
		   title="<%=UrlUtil.htmlEncode(wsets[i])%>" >
		   <%=UrlUtil.htmlEncode(wsets[i])%>
		 </a>
	</td>
</tr>

<%
}		
%>

</table>
</div>
			
<div id="buttonArea">
  			<table role="presentation" cellspacing=0 cellpadding=0 border=0 style="background:transparent;">
				<tr>
					<td>
						<button type="button" role="button" onclick="newWorkingSet()" id="new" accesskey="<%=ServletResources.getAccessKey("NewWorkingSetButton", request)%>"><%=ServletResources.getLabel("NewWorkingSetButton", request)%></button>
					</td>
					<td>
					  	<button type="button"  role="button" onclick="editWorkingSet()" id="edit" disabled='<%=data.getWorkingSet() == null ?"true":"false"%>' accesskey="<%=ServletResources.getAccessKey("EditWorkingSetButton", request)%>"><%=ServletResources.getLabel("EditWorkingSetButton", request)%></button>
					</td>
					<td>
					  	<button type="button"  role="button" onclick="removeWorkingSet()" id="remove" disabled='<%=data.getWorkingSet() == null ?"true":"false"%>' accesskey="<%=ServletResources.getAccessKey("RemoveWorkingSetButton", request)%>"><%=ServletResources.getLabel("RemoveWorkingSetButton", request)%></button>
					</td>
				</tr>
  			</table>
	<table align="<%=isRTL?"left":"right"%>" style="background:<%=prefs.getToolbarBackground()%>">
		<tr id="buttonsTable"><td align="<%=isRTL?"left":"right"%>">
  			<table role="presentation" cellspacing=0 cellpadding=0 border=0 style="background:transparent;">
				<tr>
					<td>
						<button type="submit" id="ok"><%=ServletResources.getString("OK", request)%></button>
					</td>
					<td>
					  	<button type="reset" role="button" onclick="window.close()" id="cancel"><%=ServletResources.getString("Cancel", request)%></button>
					</td>
				</tr>
  			</table>
		</td></tr>
	</table>
</div>
</form>
<script language="JavaScript">
	var wsetsCount = <%=wsetsCount%>;
	var selected = selectTopicById('<%=UrlUtil.JavaScriptEncode(workingSetId)%>');
	if (!selected) {
		document.getElementById("alldocs").checked = true;
		document.getElementById("alldocs").focus();
	}
	else {
		document.getElementById("selectws").checked = true;
		document.getElementById("selectws").focus();
	}
		
</script>

</body>
</html>
