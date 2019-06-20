'
' Licensed Materials - Property of IBM
'
' 5724O4800
'
' (C) Copyright IBM Corp. 2012. All Rights Reserved
'
' US Government Users Restricted Rights - Use, duplication
' or disclosure restricted by GSA ADP Schedule Contract
' with IBM Corp.
'
'
' This script will collect log files related to the installation of
' Netcool/OMNIbus. Files are collected from the _uninst directory of
' Netcool/OMNIbus, the user's home directory (IA log files only), and the log
' directory of the IBM Deployment Engine.
'
' Usage: cscript nc_install_logs.vbs [/pmr:nnnnn,nnn,nnn] product_dir ...
'
' If you plan to send the log files to IBM for diagnosis please specify
' your PMR number so that the output file is named approriately.
'
' One or more product directory paths (NCHOME for Core, tip_home_dir and
' webgui_home_dir for WebGUI) must be provided so that the log files stored
' below these directories can be included.
'

function Fixed(number, places)
	' Return the given number, left padded to the numbe of places
	Fixed = string(places - len(number), "0") & number
end function

'
' Storage functions
'
function CreateFolder(folder)
	' Create given folder, and parents, if it does not exist
	if not fso.FolderExists(folder) then
		parent = fso.GetParentFolderName(folder)
		if not fso.FolderExists(parent) then
			CreateFolder(parent)
		end if
		fso.CreateFolder(folder)
	end if
end function

function ListDirectory(folder)
	' List directory into a file within the stage directory
	destfile = STAGEDIR & "\" & Replace(folder, ":", "-") & ".dir"
	destfolder = fso.GetParentFolderName(destfile)

	CreateFolder(destfolder)
	set stream = fso.OpenTextFile(destfile, 2, True)

	if fso.FolderExists(folder) then
		for each file in fso.GetFolder(folder).Files
			stream.WriteLine(file.Name & " " & file.Size & " " & file.DateLastModified & " " & file.Attributes)
		next

		for each subfolder in fso.GetFolder(folder).SubFolders
			stream.WriteLine(subfolder.Name & " " & subfolder.Size & " " & subfolder.DateLastModified & " " & subfolder.Attributes)
		next
	end if

	stream.Close
end function

function CreateLongFileIndex()
	if (len(longFileMap) > 0) then
		destfile = STAGEDIR & "\toolong\0-index.txt"

		set stream = fso.OpenTextFile(destfile, 2, True)
		stream.Write(longFileMap)
		stream.Close
	end if
end function

function StoreFile(file)
	if fso.FileExists(file) then
		' Store file in stage directory, path (with ?: mapped to ?-) is included
		destfile = STAGEDIR & "\" & Replace(file, ":", "-")

		' Avoid path length overflow
		if (len(destfile) > 250) then
			longFileCount = longFileCount + 1
			longFileMap = longFileMap & destfile & ":" & longFileCount & "-" & file.Name & Chr(13) & Chr(10)
			destfile = STAGEDIR & "\toolong\" & longFileCount & "-" & file.Name
		end if

		destfolder = fso.GetParentFolderName(destfile)

		CreateFolder(destfolder)
		fso.GetFile(file).Copy(destfile)
	end if
end function

function StoreDirectoryTreeRe(path, re)
	' Store all the files matching re in the given directory and its subdirectories
	if fso.FolderExists(path) then
		set folder = fso.GetFolder(path)
		for each file in folder.Files
			if re.Test(file) then
				StoreFile(file)
			end if
		next
		for each subfolder in folder.SubFolders
			call StoreDirectoryTreeRe(subfolder, re)
		next
	end if
end function

function StoreDirectoryTree(path, pattern)
	' Store all the files matching pattern in the given directory and its subdirectories
	set re = new RegExp
	re.pattern = pattern
	call StoreDirectoryTreeRe(path, re)
end function

function StoreOneDirectory(path, pattern)
	' Store all the files matching pattern in the given directory but not its subdirectories
	set re = new RegExp
	re.pattern = pattern
	if fso.FolderExists(path) then
		set folder = fso.GetFolder(path)
		for each file in folder.Files
			if re.Test(file) then
				StoreFile(file)
			end if
		next
	end if
end function

'
' DE log collection
'
function CollectDELogs(top)
	' Collect logs from a single DE instance
	if (fso.FolderExists(top)) then
		wscript.echo("Collecting DE logs from " & top)

		ListDirectory(top & "\jre")
		ListDirectory(top & "\bin")

		call StoreDirectoryTree(top & "\logs", "")
		call StoreOneDirectory(top, "")
		call StoreFile(top & "\repos\derby.log")
	end if
end function

function CollectUserDELogs(home)
	' Collect logs from acsi_* folders in the user's home directory
	set subfolders = fso.GetFolder(home).SubFolders
	for each folder in subfolders
		if StrComp("acsi_", left(folder.name, 5)) = 0 then
			CollectDELogs(folder)
		end if
	next
end function

function CollectRootDELogs
	' Collect logs from root DE
	CollectDELogs(WshSysEnv("ProgramFiles") & "\IBM\common\acsi")
	CollectDELogs(WshSysEnv("ProgramFiles(x86)") & "\IBM\common\acsi")
end function

'
' COI log collection
'
function CollectCOIExtLogs(home)
	' Collect COI-EXT logs from the user's home directory
	if fso.FolderExists(home) then
		for each file in fso.GetFolder(home).Files
			if InStr(file, "OMNIbus") > 0 and StrComp(Right(file, 4), ".log") = 0 then
				StoreFile(file)
			end if
		next
	end if
end function

'
' Product log collection
'
function CollectProductLogs(product)
	' Collection installer logs from a product install
	Wscript.echo("Collecting product logs from " & product)
	call StoreOneDirectory(product, "\.log$")
	call StoreDirectoryTree(product & "\_uninst", "\.log$")

	CollectCoreOMNIbusLogs(product)
	CollectOMNIbusWebGUILogs(product)
end function

function CollectCoreOMNIbusLogs(product)
	StoreFile(product & "\omnibus\log\migrate.log")
	StoreFile(product & "\omnibus\platform\win32\install\omnibus.log")
end function

function CollectOMNIbusWebGUILogs(product)
	StoreFile(product & "\derby\derby.log")
	call StoreDirectoryTree(product & "\logs\manageprofiles", "\.log$")
	call StoreDirectoryTree(product & "\profiles\TIPProfile", "\.log$")
end function

'
' Package staging directory
'
function CreateZip(zipfile)
	' Create an empty zip file
	set stream = fso.CreateTextFile(zipfile, True)
	stream.write("PK" & chr(5) & chr(6) & string(18, chr(0)))
	stream.close()
end function

function AddFolderToZip(folder, zipfile)
	' Copy a folder to an empty zip file
	' Both paths MUST be absolute
	set zipfolder = Application.NameSpace(zipfile)
	zipfolder.CopyHere(folder)

	' Need to wait until done or it will fail
	finished = 0
	while finished = 0
		WScript.sleep(1000)
		if fso.fileExists(zipfile) then
			if fso.getFile(zipfile).size > 22 then
				finished = 1
			end if
		end if
	wend
end function

function TryToZipUp(folder, zipfile)
	' Create a zip file and add a folder and its contents
	' Does not contain any error handing
	absfolder = fso.GetAbsolutePathName(folder)
	abszipfile = fso.GetAbsolutePathName(zipfile)
	call CreateZip(abszipfile)
	call AddFolderToZip(absfolder, abszipfile)
	fso.DeleteFolder(absfolder)
end function

function ZipUp(folder, zipfile)
	' Create a zip file and add a folder and its contents
	' Handles errors. Returns name of zip file if it worked
	' or fold if it did not.
	result = zipfile
	on error resume next
	Err.Clear
	call TryToZipUp(folder, zipfile)
	if Err.Number then result = folder
	ZipUp = result
end function

'
' Services
'
set fso = CreateObject("Scripting.FileSystemObject")
set WshShell = WScript.CreateObject("WScript.Shell")
set WshSysEnv = WshShell.Environment("PROCESS")
set Application = CreateObject("shell.application")

'
' Parameters
'
dim PMR, STAGEDIR, PACKDATE, PRODUCTS, PACKAGE
PACKDATE = Now
DATESTRING = Fixed(Year(PACKDATE), 4) & Fixed(Month(PACKDATE), 2) & Fixed(Day(PACKDATE), 2) & "T" & Fixed(Hour(PACKDATE), 2) & Fixed(Minute(PACKDATE), 2) & Fixed(Second(PACKDATE), 2)

'
' State
'
dim longFileCount, longFileMap
longFileCount = 0
longFileMap = ""

' PMR is a named argument, and affected the stage directory name
PMR = Wscript.Arguments.Named.Item("pmr")
if PMR = "" then
	STAGEDIR = "nc_install_logs." + DATESTRING
else
	STAGEDIR = PMR & ".nc_install_logs." & DATESTRING
end if

' The unamed arguments list product install directories
set PRODUCTS = WScript.Arguments.Unnamed

if PRODUCTS.Count = 0 then
	Wscript.echo(Chr(13) & Chr(10) & _
		"The path to the Netcool/OMNIbus installation must be given." & _
		Chr(13) & Chr(10) & _
		Chr(13) & Chr(10) & _
		"    cscript nc_install_logs.vbs [/pmr:nnnnn,nnn,nnn] <path> ..." & _
		Chr(13) & Chr(10) & _
		Chr(13) & Chr(10) & _
		"The PMR argument should be used when you intend to submit files to IBM." & _
		Chr(13) & Chr(10) & _
		"<path> is the installation directory. More than one <path> can be given." & _
		Chr(13) & Chr(10) & _
		"For Core Netcool/OMNIbus give the value of NCHOME." & _
		Chr(13) & Chr(10) & _
		"For Netcool/OMNIbus WebGUI give both tip_home_dir and webgui_home_dir." & _
		Chr(13) & Chr(10))
	Wscript.Quit(1)
end if


'
' Main function
'
fso.CreateFolder(STAGEDIR)
STAGEDIR = fso.GetFolder(STAGEDIR).Path

CollectUserDELogs(WshSysEnv("HOMEDRIVE") & WshSysEnv("HOMEPATH"))
CollectRootDELogs

CollectCOIExtLogs(WshSysEnv("HOMEDRIVE") & WshSysEnv("HOMEPATH"))

for I = 0 to PRODUCTS.Count - 1
	CollectProductLogs(PRODUCTS(I))
next

CreateLongFileIndex()

PACKAGE = ZipUp(STAGEDIR, STAGEDIR & ".zip")
Wscript.echo("The package of log files is " & PACKAGE)
