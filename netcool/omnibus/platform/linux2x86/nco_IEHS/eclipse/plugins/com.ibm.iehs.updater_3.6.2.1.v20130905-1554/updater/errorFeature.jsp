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
%> 
<%
	ErrorFeatureData data = new ErrorFeatureData(application, request, response);
%>
<html lang="<%=ServletResources.getString("locale", request)%>" xml:lang="<%=ServletResources.getString("locale", request)%>">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<style type="text/css">
<%@ include file="css/update.css"%>
</style>  
</head>
<script language="JavaScript" src="js/cancel.js"></script>

<body onload="" 
dir="<%=direction%>"
	 style="margin-top: 0; 
	 margin-left: 0; 
	 margin-right: 0;">
<br>
<table width="100%" cellspacing="0" cellpadding="10" border="0">
<tr>
	<td>
		<h4><%=WebUpdaterResources.ErrorFeature%></h4>
	</td>
</tr>
<tr>	
	<td>
			
		<div class='panel' >
			<div class='innerPanel'>
						
				<p> 
				<ul class="itemPanel">
					<%=data.generateScript()%>
				</ul>
				<br >
			</div>
		</div>	
	</td>
</tr>
<tr>
	<td>
		<div align = "right" style="padding-top: 150px;padding-right: 25px" >
			<button onclick="window.location='selectFeature.jsp';" >
				<%=WebUpdaterResources.NextButton%>
			</button>
			<button onclick=cancel("errorFeature")>
				<%=WebUpdaterResources.CancelButton%>
			</button>
		</div>
	</td>
</tr>
</table>
</body>
</html>
