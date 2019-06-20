<%-- ***************************************************** {COPYRIGHT-TOP} ***
* Licensed Materials - Property of IBM
* 5724-S44
*
* (C) Copyright IBM Corp. 2009
*
* US Government Users Restricted Rights - Use, duplication, or
* disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
********************************************************** {COPYRIGHT-END} --%>
<?xml version="1.0" encoding="UTF-8" ?>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@ include file="/common/taglibs.jsp" %>
<fmt:setBundle basename="ncw.nl.predictiveevent" var="langset" scope="request"/>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title><fmt:message key="ext_attrs.page.title" bundle="${langset}"/></title>
<link rel="stylesheet" type="text/css" href="styles/tablestyles.css" />

<script type="text/javascript">
//<![CDATA[
window.resizeTo(700, 500);

function alternateRowColour() {
	var body = document.getElementById("contentBody");
	var bodyRows = body.getElementsByTagName("tr");

	for (var i = 0; i < bodyRows.length; i++) {
		bodyRows[i].className = (i % 2) == 0 ? "isc-table-row" : "isc-table-row-alternate";
	}
}
//]]>
</script>
</head>

<%
Map attrsMap = new TreeMap(com.ibm.icu.text.Collator.getInstance(request.getLocale()));

String extAttr = request.getParameter("extAttr");
// Example extAttr value: Confidence="75";Number_Of_Samples="5";Strength="3"

if (extAttr != null && !"".equals(extAttr)) {
	// Remove final "
	extAttr = extAttr.substring(0, extAttr.length() - 1);

	// Splitting this way will remove both ; and the trailing " between attributes
	String[] attrs = extAttr.split("\";");

	for (int i = 0; i < attrs.length; i++) {
		// This split removes = and the leading " between attribute name and value
		String[] attr = attrs[i].split("=\"");
		attrsMap.put(attr[0], attr[1]);
	}

	pageContext.setAttribute("extAttrEntrySet", attrsMap.entrySet());
}
%>

<body onload="alternateRowColour()">

<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
	<tbody>
		<tr class="isc-table-toolbar">
		<td class="isc-table-toolbar-cap-l" valign="top"><img src="images/table_toolbar_lcap.gif" alt="<fmt:message key="ext_attrs.table.toolbar.img.leftcorner" bundle="${langset}"/>" /> </td>
		<td class="isc-table-toolbar-buttonbar" valign="middle"><fmt:message key="ext_attrs.table.toolbar.title" bundle="${langset}"><fmt:param value="${param.Serial}"/></fmt:message></td>
		<td class="isc-table-toolbar-cap-r" valign="top" align="right"><img src="images/table_toolbar_rcap.gif" alt="<fmt:message key="ext_attrs.table.toolbar.img.rightcorner" bundle="${langset}"/>" /> </td>
		</tr>
	</tbody>
</table>

<table summary="<fmt:message key="ext_attrs.table.summary" bundle="${langset}"/>" class="isc-table-scroll-container" width="100%" cellspacing="0" cellpadding="0" border="0">
	<thead>
		<tr class="isc-table-header">
			<th class="isc-table-header-data" valign="middle" scope="col" align="left"><fmt:message key="ext_attrs.table.header.attrname" bundle="${langset}"/></th>
			<th class="isc-table-header-data" valign="middle" scope="col" align="left"><fmt:message key="ext_attrs.table.header.attrvalue" bundle="${langset}"/></th>
		</tr>
	</thead>
	<tbody id="contentBody" class="isc-table-body-border">
		<c:choose>
			<c:when test="${pageScope.extAttrEntrySet == null}">
				<tr>
					<td class="isc-table-data" colspan="2"><fmt:message key="ext_attrs.table.data.empty" bundle="${langset}"/></td>
				</tr>
			</c:when>
			<c:otherwise>
				<c:forEach var="entry" items="${pageScope.extAttrEntrySet}">
					<tr>
						<td class="isc-table-data"><c:out value="${entry.key}" /></td>
						<td class="isc-table-data"><c:out value="${entry.value}" /></td>
					</tr>
				</c:forEach>
			</c:otherwise>
		</c:choose>
	</tbody>
</table>

<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
	<tbody>
		<tr class="isc-table-footer">
			<td class="isc-table-footer-cap-l" valign="bottom" align="left"><img src="images/table_footer_lcap.gif" width="2" height="26" alt="<fmt:message key="ext_attrs.table.footer.img.leftcorner" bundle="${langset}"/>" /></td>
			<td style="width:100%" valign="middle"></td>
			<td class="isc-table-footer-cap-r" valign="bottom" align="right"><img src="images/table_footer_rcap.gif" alt="<fmt:message key="ext_attrs.table.footer.img.rightcorner" bundle="${langset}"/>" /></td>
		</tr>
	</tbody>
</table>
</body>
</html>
