@echo off

set JHOME=
set CHOME=

:Loop
IF [%1]==[] GOTO Continue	
	IF [%1]==[-j] set JHOME=%2&& goto :NEXT
	IF [%1]==[-console] set CONSOLE=%1&& goto :NEXT
    IF [%1]==[-all] set ALL=%1&& goto :NEXT
    if exist "%1\InstallITM\kinconfg.exe" set CHOME="%1"
:NEXT
	SHIFT
	GOTO Loop	
	
:Continue

IF [%JHOME%]==[] GOTO CHECK_JAVA1
	%JHOME%\bin\java.exe -version > NUL 2>NUL	
	IF %ERRORLEVEL% EQU 0 GOTO RUN_TOOL

:CHECK_JAVA1

IF "%CHOME%"=="" GOTO CHECK_JAVA2
	call %CHOME%\InstallITM\candlegetjavahome.bat > NUL 2>NUL	
		
	IF %ERRORLEVEL% NEQ 0 GOTO CHECK_JAVA3
	
	For /F "Tokens=*" %%j in ('%CHOME%\InstallITM\candlegetjavahome.bat') Do Set JHOME="%%j"

	%JHOME%\bin\java.exe -version > NUL 2>NUL
	IF %ERRORLEVEL% EQU 0 GOTO RUN_TOOL

:CHECK_JAVA2

call candlegetjavahome.bat > NUL 2>NUL

if %ERRORLEVEL% NEQ 0 goto CHECK_JAVA3
		
For /F "Tokens=*" %%J in ('candlegetjavahome.bat') Do Set JHOME="%%J"

%JHOME%\bin\java.exe -version > NUL 2>NUL
IF %ERRORLEVEL% EQU 0 GOTO RUN_TOOL

:CHECK_JAVA3

%JAVA_HOME%\bin\java.exe -version > NUL 2>NUL
IF %ERRORLEVEL% NEQ 0 GOTO NO_JAVA 
set JHOME=%JAVA_HOME%

:RUN_TOOL

IF "%CHOME%"=="" %JHOME%\bin\java.exe -jar ./bin/domaintool.jar -j %JHOME% %ALL% %CONSOLE%  
IF not "%CHOME%"=="" %JHOME%\bin\java.exe -jar ./bin/domaintool.jar -h "%CHOME%" -j %JHOME% %ALL% %CONSOLE%

GOTO END

:NO_JAVA
        echo Unable to determine JRE directory.
        echo To fix this:
        echo * Specify IBM Tivoli Monitoring directory, for example:
        echo         domaintool.bat c:\IBM\ITM
        echo * Specify JRE directory by using parameter -j, for example:
        echo         domaintool.bat -j c:\progra~1\ibm\java50
GOTO END

:END
