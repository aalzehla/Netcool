/*******************************************************************************
 *(C) Copyright IBM Corp. 2010
 * IBM Confidential
 * OCO Source Materials
 *
 * The source code for this program is not published or otherwise
 * divested of its trade secrets, irrespective of what has been
 * deposited with the U.S. Copyright Office.
 *******************************************************************************/
function loadUpdater(button, param) {
	try {
		parent.ContentViewFrame.window.location= "../updater/updater.jsp";	
	} catch(e) {
	}
	if (isIE && button && document.getElementById(button)){
			document.getElementById(button).blur();
	}
}