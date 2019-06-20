<%--
 Copyright (c) 2010 IBM Corporation and others.
 All rights reserved. This program and the accompanying materials 
 are made available under the terms of the Eclipse Public License v1.0
 which accompanies this distribution, and is available at
 http://www.eclipse.org/legal/epl-v10.html
 
 Contributors:
     IBM Corporation - initial API and implementation
--%>
<%@ include file="header.jsp"%>
<% 
    String qs = request.getQueryString();
    String location = "";
    if (qs != null) {
	    location = "print.jsp?" + qs + "&pageBreak=true";
    }
    String[] args = new String[] {
			ServletResources.getString("yes", request),
			ServletResources.getString("no", request)};
	String notice = ServletResources.getString("pageBreak", args, request);
%>


<html lang="<%=ServletResources.getString("locale", request)%>">
<head>
<title><%=ServletResources.getString("alert", request)%></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<link rel="stylesheet" href="../<%=pluginVersion%>/advanced/printAlert.css" charset="utf-8" type="text/css">
<script language="JavaScript">

function onloadHandler() {
	sizeButtons();
}

function sizeButtons() {
	var minWidth=60;

	if(document.getElementById("ok").offsetWidth < minWidth){
		document.getElementById("ok").style.width = minWidth+"px";
	}
	if(document.getElementById("cancel").offsetWidth < minWidth){
		document.getElementById("cancel").style.width = minWidth+"px";
	}
}

function getParam(){
	var url = top.location.href;
	var param = url.substring(url.indexOf('?')+1);
	return param;
}
function pageBreak(){
	var form = document.getElementsByName("pageBreakForm")[0];
	form.action = "print.jsp?"+getParam()+"&pageBreak=true&breakConfirmed=true";
	form.submit();
}
function cancelBreak(){
	var form = document.getElementsByName("pageBreakForm")[0];
	form.action = "print.jsp?"+getParam()+"&pageBreak=false&breakConfirmed=true";
	form.submit();
}
</script>

</head>
<body role="main" dir="<%=direction%>" onload="onloadHandler()">
<h1 id="printPreferenceTitle" style="display:none;"><%=ServletResources.getString("alert", request)%></h1>
<p/>
<div align="center" role="region" aria-labelledby="printPreferenceTitle">
<div class="printAlertDiv">
<form name="pageBreakForm" method="post" onsubmit="pageBreak();return false;">
<table role="presentation" align="center" cellpadding="10" cellspacing="0" width="400">
	<tbody>
		<tr>
			<td class="caption"><span style="font-weight:bold;"><%=ServletResources.getString("alert", request)%></span></td>
		</tr>
		<tr>
			<td class="message">
			<p><q><%=notice%></q></p>
			</td>
		</tr>
		<tr>
			<td class="button">
			<div align="center">
				<button id="ok" type="submit"><%=ServletResources.getString("yes", request)%></button>
				<button id="cancel" onClick="cancelBreak()" role="button"><%=ServletResources.getString("no", request)%></button>
            </div>
			</td>
		</tr>
	</tbody>
</table>
</form>
</div>
</div>
</body>
</html>
