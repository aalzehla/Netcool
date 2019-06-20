<%--
 (C) Copyright IBM Corp. 2010
 IBM Confidential
 OCO Source Materials
 
 The source code for this program is not published or otherwise
 divested of its trade secrets, irrespective of what has been
 deposited with the U.S. Copyright Office.
--%> 
<%@ include file="sheader.jsp"%>
<%@page import="org.eclipse.help.internal.base.HelpBasePlugin"%>
<html lang="<%=ServletResources.getString("locale", request)%>" xml:lang="<%=ServletResources.getString("locale", request)%>">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title><%=WebUpdaterResources.updates%></title>
<style type="text/css">
<%@ include file="css/update.css"%>
</style>  
</head>
<script language="JavaScript" src="js/cancel.js" type="text/javascript"></script>

<% UpdateCommonData data = UpdateCommonData.getInstance(application, request, response); %>
<body>
<%--
<%String infocenterContext = HelpBasePlugin.getDefault().getPluginPreferences().getString("infocenterContext");
if(infocenterContext.equals("/")) {
	infocenterContext = "";
}%>
<script language="JavaScript">
var infocenterContext = "<%=infocenterContext%>";
var noSite = <%=data.getUpdateSites().isEmpty()%>;
if(noSite){
	window.location = infocenterContext + "/updater/noSite.jsp";
}
else{
	window.location = infocenterContext + "/updater/findExistFeature.jsp";
}
</script>
 --%>
<script language="JavaScript">
	var noSite = <%=data.getUpdateSites().isEmpty()%>;
	if(noSite){
		//window.location = "/updater/noSite.jsp";
		window.location.href = "../updater/noSite.jsp";
	}
	else{
		//window.location = "/updater/findExistFeature.jsp";
		window.location.href = "../updater/findExistFeature.jsp";
	}
</script>

<div align = "right" style="padding-top: 250px;padding-right: 25px;"> 
	<button onclick="parent.parent.parent.window.location='../index.jsp';">
		<%=WebUpdaterResources.FinishButton%>
	</button>
</div>
</body>
</html>
