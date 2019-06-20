<%--
 (C) Copyright IBM Corp. 2010
 IBM Confidential
 OCO Source Materials
 
 The source code for this program is not published or otherwise
 divested of its trade secrets, irrespective of what has been
 deposited with the U.S. Copyright Office.
--%> 
<%@
page import="com.ibm.iehs.updater.data.*"  contentType="text/html; charset=UTF-8"
%>
<%@ page import="com.ibm.iehs.updater.WebUpdaterResources"%>
<%@ page import="org.eclipse.help.internal.webapp.data.RequestData"%>
<%@ page import="org.eclipse.help.internal.webapp.data.UrlUtil"%>
<%@ page import="org.eclipse.help.internal.webapp.data.ServletResources"%>
<% 
request.setCharacterEncoding("UTF-8");
boolean isRTL = UrlUtil.isRTL(request, response);
String  direction = isRTL?"rtl":"ltr";
if (new RequestData(application,request, response).isMozilla()) {
%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<% 
} else {
%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<%
}
%><!------------------------------------------------------------------------------
 ! Copyright (c) 2000, 2004 IBM Corporation and others.
 ! All rights reserved. This program and the accompanying materials 
 ! are made available under the terms of the Eclipse Public License v1.0
 ! which accompanies this distribution, and is available at
 ! http://www.eclipse.org/legal/epl-v10.html
 ! 
 ! Contributors:
 !     IBM Corporation - initial API and implementation
 ------------------------------------------------------------------------------->