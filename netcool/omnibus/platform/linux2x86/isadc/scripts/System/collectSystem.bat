@echo off
rem ******************************************************************
rem the first argument passed to this batch file is the intended 
rem output file.  If it is not available, then this file will not run.
rem ******************************************************************

echo **************************** date /t ****************************
date /t 
echo . 

echo **************************** time /t **************************** 
time /t 
echo . 

echo ****************************** mode ***************************** 
mode 
echo . 

echo ************************* net accounts ************************** 
net accounts 
echo . 

echo ************************** net config *************************** 
net config 
echo . 

echo *************************** net start *************************** 
net start 
echo . 

echo ************************** java -version ************************ 
java -version 
echo . 

echo *************************** systeminfo *************************** 
systeminfo 
echo . 

