/*******************************************************************************
 *(C) Copyright IBM Corp. 2010
 * IBM Confidential
 * OCO Source Materials
 *
 * The source code for this program is not published or otherwise
 * divested of its trade secrets, irrespective of what has been
 * deposited with the U.S. Copyright Office.
 *******************************************************************************/
function cancel(srcPage) {
	switch (srcPage){
	
		case 'findExist':
			cancelFindExist();
			break;
		case 'findFeature':
			cancelFindFeature();
			break;
		case 'selectFeature':
			cancelSelectFeature();
			break;
		case 'installFeature':
			cancelInstallFeature();
			break;
		case 'errorFeature':
			backToCancelPage();
			break;

	}
	
	
}
//cancel action in the findexist page
function cancelFindExist() {
	backToCancelPage();
}
//cancel action in the findfeature page
function cancelFindFeature() {
	cancelFindOnServer();
	backToCancelPage();
}
//cancel action in the selectfeature page
function cancelSelectFeature() {
	cancelSelectOnServer();
	backToCancelPage();
}
//cancel action in the installfeature page
function cancelInstallFeature() {
	//such a complicated process that push the function into the installfeature page
	cancelInstall();
}

function backToCancelPage() {
	window.location="cancelUpdate.jsp";
}

var isIE = false;
var req;
function cancelSelectOnServer() {
	var url = "CancelServlet?srcPage=selectFeature";
    initRequest(url);
    req.send(null);
}

function cancelFindOnServer() {
    var url = "CancelServlet?srcPage=findFeature";
    initRequest(url);

    req.send(null);
}

function cancelInstallOnServer() {
	var url = "CancelServlet?srcPage=installFeature";
    initRequest(url);
    req.send(null);
    
    
}

function resetInstallOnServer() {
	var url = "CancelServlet?srcPage=resetUpdateStatus";
    initRequest(url);
    req.send(null);
    
    
}



function initRequest(url) {
    if (window.XMLHttpRequest) {
        req = new XMLHttpRequest();
    } else if (window.ActiveXObject) {
        isIE = true;
        req = new ActiveXObject("Microsoft.XMLHTTP");
    }
    req.open("GET", url, true);
}


