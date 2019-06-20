@echo off

set IS_TEMS=
set IS_TEPS=
set IS_PA=
set PACLASSPATH=
set ERROR=

rem ### MAIN CODE ###

if "%7"=="" echo "Invalid arguments" && goto :END

set IS_TEMS=%1
shift
set IS_TEPS=%1
shift
set IS_PA=%1
shift
set CHOME=%1
for /F "tokens=*" %%f in ('echo %CHOME%') do set CHOME=%%~sf
shift
set JHOME=%1
for /F "tokens=*" %%f in ('echo %JHOME%') do set JHOME=%%~sf
shift
set DDIR=%1
for /F "tokens=*" %%f in ('echo %DDIR%') do set DDIR=%%~sf
shift

set LOGFILE=%CHOME%\logs\itpa_domain.log

echo "ITPA Domain Activation Tool started" >> %LOGFILE%

echo Checking running services before processing...

if not "%IS_TEMS%"=="true" goto :PREPARE_ENV

call %CHOME%\InstallITM\kincinfo.exe -r | findstr MS | findstr \.Running > NUL 2>>%LOGFILE%

if %ERRORLEVEL% NEQ 0 echo "ERROR: TEMS must be running" && goto :END_ERROR

:PREPARE_ENV 

echo Preparing environment before activating domains...

rem prepare tems environment
if not "%IS_TEMS%"=="true" goto :SETUP_PA

call :PREPARE_TEMS
if %ERROR% NEQ 0 echo "ERROR: Problem preparing ITPA configuration files for TEMS" && goto :END_ERROR

:SETUP_PA
if not "%IS_PA%"=="true" goto :PROCESS_DOMAINS

if exist "%CHOME%\tmaitm6\KPAENV" for /f "tokens=2 delims==" %%a in ('findstr "KPA_CLASSPATH=" "%CHOME%\tmaitm6\KPAENV"') do set PACLASSPATH=%%a

if "%PACLASSPATH%"=="" echo "ERROR: Unable to determine ITPA agent CLASSPATH variable" && goto :END_ERROR

:PROCESS_DOMAINS

:LOOP
if "%1"=="" goto :CONTINUE	
if not exist "%DDIR%\%1" echo "ERROR: Invalid domain name" && goto :END_ERROR
call :ACTIVATE_DOMAIN %1
if %ERROR% NEQ 0 goto :END_ERROR
shift
goto :LOOP
:CONTINUE

rem at the end execute installPresentation if teps is available
if "%IS_TEPS%"=="true" call :CQ_INSTALL_PRESENTATION

if %ERROR% NEQ 0 echo ERROR: Script installPresentation.bat failed - return code = %ERROR% && goto :END_ERROR

echo Domains activation completed successfully.

if "%IS_TEMS%"=="true" echo Restart TEMS now
if "%IS_TEPS%"=="true" echo Restart TEPS now
if "%IS_PA%"=="true" echo Restart ITPA now

goto END

rem ### END OF MAIN CODE ###

:ACTIVATE_DOMAIN
	echo Activating domain %1:
	set ERROR=0
	call :GENERATE_ODI %1
	if %ERROR% EQU 1 echo "ERROR: Problem generating odi files" && goto :eof	
	if "%IS_TEMS%"=="true" call :ACTIVATE_DOMAIN_TEMS %1 
	if %ERROR% NEQ 0 echo "ERROR: Problem activating TEMS support" && goto :eof
	if "%IS_TEPS%"=="true" call :ACTIVATE_DOMAIN_TEPS %1 
	if %ERROR% NEQ 0 echo "ERROR: Problem copying TEPS support files" && goto :eof
	if "%IS_PA%"=="true" call :ACTIVATE_DOMAIN_PA %1 
	if %ERROR% NEQ 0 echo "ERROR: Problem activating ITPA tasks"
	goto :eof

:ACTIVATE_DOMAIN_TEMS	
	echo - activating TEMS support
	pushd "%CHOME%/cms"
	call ksminst -f  -v 610 -e "%DDIR%\%1\files" >>%LOGFILE% 2>&1
	if %ERRORLEVEL% NEQ 0 set ERROR=1 && popd && goto :eof
	call ksminst -f  -v 610 -s "%DDIR%\%1\files" >>%LOGFILE% 2>&1
	if %ERRORLEVEL% NEQ 0 set ERROR=1
	popd
	goto :eof

:ACTIVATE_DOMAIN_TEPS
	echo - activating TEPS support	
	for %%f in ("%DDIR%\%1\files\TEPS\CNPS\SQLLIB\*.sql") do if %ERROR% EQU 0 type %%f > "%CHOME%\CNPS\SQLLIB\%%~nxf" 2>>%LOGFILE% && if %ERRORLEVEL% NEQ 0 set ERROR=1
	for %%f in ("%DDIR%\%1\files\TEMS\SQLLIB\*.sql") do if %ERROR% EQU 0 type %%f > "%CHOME%\CNPS\SQLLIB\%%~nxf" 2>>%LOGFILE% && if %ERRORLEVEL% NEQ 0 set ERROR=1
	goto :eof

:ACTIVATE_DOMAIN_PA
	echo - activating ITPA tasks	
	pushd "%CHOME%\TMAITM6"
	%JHOME%\bin\java.exe -classpath "%PACLASSPATH%";paconf.jar;kjrall.jar com.ibm.tivoli.pa.config.PAConfigMain -execSQL %DDIR%\%1\files\PA\tasks.sql >>%LOGFILE% 2>&1
	if %ERRORLEVEL% NEQ 0 set ERROR=1
	popd	
	goto :eof
	
:GENERATE_ODI
	echo - generating odi files
	%JHOME%\bin\java.exe -jar bin/domsupp.jar -deploy %CHOME% -grpdir %DDIR%\%1\files\PA\odi -workdir "%TMP%" >>%LOGFILE% 2>&1
	if %ERRORLEVEL% NEQ 0 set ERROR=1
	goto :eof

:PREPARE_TEMS
	set ERROR=0
	if not exist "%CHOME%\tmaitm6\config\dockpa" xcopy /Q /R /Y "%DDIR%\dockpa" "%CHOME%\tmaitm6\config\" > NUL 2>>%LOGFILE% && echo "#" > "%CHOME%\tmaitm6\config\init.cfg" 2>>%LOGFILE%
	if not exist "%CHOME%\tmaitm6\config\dockpa" set ERROR=1 && goto :eof
	if not exist "%CHOME%\tmaitm6\config\init.cfg" set ERROR=1
	goto :eof
	
:CQ_INSTALL_PRESENTATION
	echo Executing script installPresentation.bat, please wait...
	pushd "%CHOME%\CNPS"
	call cmd /c installPresentation.bat >>%LOGFILE% 2>&1
	set ERROR=%ERRORLEVEL%
	popd
	goto :eof
	
:END_ERROR
	echo Domains activation failed.

:END
