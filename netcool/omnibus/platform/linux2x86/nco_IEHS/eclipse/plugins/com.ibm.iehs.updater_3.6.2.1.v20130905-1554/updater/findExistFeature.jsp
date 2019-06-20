<%--
 (C) Copyright IBM Corp. 2010
 IBM Confidential
 OCO Source Materials
 
 The source code for this program is not published or otherwise
 divested of its trade secrets, irrespective of what has been
 deposited with the U.S. Copyright Office.
--%> 
<%@ include file="sheader.jsp"%>
<% 
	response.setHeader("Pragma","no-cache"); 
	response.setHeader("Cache-Control","no-store, no-cache");
	response.setDateHeader("Expires", 0); 

	GetInstalledFeaturesData data = new GetInstalledFeaturesData(application,request,response);
%>
<html lang="<%=ServletResources.getString("locale", request)%>" xml:lang="<%=ServletResources.getString("locale", request)%>">
<head>
<script language="JavaScript" type="text/javascript">
var showDe = "<%=WebUpdaterResources.showdescription%>";
var hideDe = "<%=WebUpdaterResources.hidedescription%>";
</script>

<script language="JavaScript" src="js/update.js" type="text/javascript"></script>
<script language="JavaScript" src="js/cancel.js" type="text/javascript"></script>

<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title><%=WebUpdaterResources.updates%></title>
<style type="text/css">
<%@ include file="css/update.css"%>
</style> 

</head>
<body style="margin-top: 0; margin-left: 0; margin-right: 0;" dir="<%=direction%>">
<table width="100%" cellspacing="0" cellpadding="10" border="0">
	<tr>
		<td colspan="10">
				<h3><%=WebUpdaterResources.ShowExistFeature%></h3>
				<div class='panel'>
					<div class='innerPanel'>
						<ul class="itemPanel">
							<%=data.getExistingFeatures()%>
						</ul>
					</div>
				</div>
		</td>
	</tr>
</table>
<div align = "<%=isRTL?"left":"right"%>"
	 style="<%=direction%>">
	<button	onclick="window.location='findFeature.jsp';" >
		<%=WebUpdaterResources.NextButton%>
	</button>
	<button	onclick="cancel('findExist')">
		<%=WebUpdaterResources.CancelButton%>
	</button>
				
</div>
</body>
</html>
