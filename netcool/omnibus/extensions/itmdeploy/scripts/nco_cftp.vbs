'
' Script to check relevant environment variables and run nco_cftp
'
MSG_OMNIHOME_MISSING="ERROR: OMNIHOME is not defined."
MSG_NCHOME_MISSING="ERROR: NCHOME is not defined."
MSG_CHOME_MISSING="ERROR: CANDEL_HOME is not defined."


'
' Main function
'

Function Main
	On Error GoTo 0
	Set WshShell = WScript.CreateObject("WScript.Shell")


	NCHOME = WshShell.Environment("PROCESS")("NCHOME")
	If Len(NCHOME) < 1 Then
		WScript.Echo MSG_NCHOME_MISSING
		Exit Function
	End If

	OMNIHOME = WshShell.Environment("PROCESS")("OMNIHOME")
	If Len(OMNIHOME) < 1 Then
		WScript.Echo MSG_OMNIHOME_MISSING
		Exit Function
	End If


	CNDLHOME = WshShell.Environment("PROCESS")("CANDLE_HOME")
	If Len(CNDLHOME) < 1 Then
		WScript.Echo MSG_CHOME_MISSING
		Exit Function
	End If


	'
	'Attempt to load common scripting code
	'

	Set objFileSystem = CreateObject("Scripting.FileSystemObject")
	CommonFile = OMNIHOME & "\bin\nco_common.vbs"

	if Not objFileSystem.FileExists(CommonFile) Then
		WScript.Echo "Unable to locate nco_common.vbs"
		Exit Function
	End If

	Set objTextStream = objFileSystem.OpenTextFile(CommonFile, 1)
	strCode = objTextStream.ReadAll
	objTextStream.Close
	Execute strCode

	JRE = GetJRE(NCHOME)
	If Len(JRE) < 1 Then
		JVer = GetJavaVersion
		JRE = GetJavaPath(JVer)
	End If

	If Len(JRE) < 1 Then
		WScript.Echo MSG_NO_JRE_FOUND
		Exit Function
	End If
	'
	'Check for java.exe
	'
	if Not objFileSystem.FileExists(JRE & "\bin\java.exe") Then
		WScript.Echo MSG_JAVA_EXE_NOT_FOUND  &vbCrLf&vbCrLf & "Current value for NCO_JRE: " & JRE
		Exit Function
	End If
	


	'
	'set environment variable for future use
	'

	WshShell.Environment("PROCESS")("NCO_JRE") = JRE
	WshShell.Environment("PROCESS")("OMNIHOME") = OMNIHOME
	

	'
	'Set local version of classpath
	'


	'
	LOCALCLASSPATH = Chr(34) & CNDLHOME & "\CNP\cnp_vbjorball.jar" & Chr(34) & ";" & _
			 Chr(34) & CNDLHOME & "\CNP\ae.jar" & Chr(34) & ";" & _
			 Chr(34) & CNDLHOME & "\CNP\cnp.jar" & Chr(34) & ";" & _
			 Chr(34) & CNDLHOME & "\CNP\icu4jm32.jar" & Chr(34) & ";" & _
			 Chr(34) & CNDLHOME & "\CNP\kjrall.jar" & Chr(34) & ";" & _
			 Chr(34) & CNDLHOME & "\CNP\terminal.jar" & Chr(34) & ";" & _
			 Chr(34) & CNDLHOME & "\CNP\util.jar" & Chr(34) & ";" & _
			 Chr(34) & OMNIHOME & "\java\jars\cftp.jar" & Chr(34)

	'
	'Process the argument list
	'
	For i = 0 To WScript.Arguments.Count -1
		if (WScript.Arguments(i) = "") then
			ArgList = ArgList & " " & Chr(34) & Chr(34)
		Else
       		ArgList = ArgList & " """ & WScript.Arguments(i) & """"
		End If 
	Next



	'
	' Set up CANDLE_HOME
	'
	P_CNDLHOME = ""
	if Len(CNDLHOME) > 0 Then
		P_CNDLHOME = "-DCANDLE_HOME==" & Chr(34) & CNDLHOME & Chr(34)
	
	End If


	P_MEMORY = "-Xms64m -Xmx512m"

	'
	' Assemble complete commandline string
	'

	COMMANDLINE = Chr(34) & _
		      Chr(34) & JRE & "\bin\java.exe" & Chr(34) & _
		      " -classpath" & _
		      " " & LOCALCLASSPATH & _
		      " " & P_CNDLHOME& _
		      " " & P_MEMORY & _
		      " com.ibm.cdb.integration.itm.ConduitFileTransferHelper " & _
		      ArgList & _
		      Chr(34)
		      		      
	'
	'Run the command
	'
	If InStr(COMMANDLINE, "-version") Or InStr(COMMANDLINE, "-help") Then
		WshShell.Run "cmd /s /k " & COMMANDLINE, 1, False

	Else
		WshShell.Run "cmd /s /c " & COMMANDLINE, 1, False

	End If
End Function

Main
