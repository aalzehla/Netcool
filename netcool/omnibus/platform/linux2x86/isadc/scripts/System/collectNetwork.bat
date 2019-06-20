@echo off

echo ************************* ipconfig ****************************** 
ipconfig -all 
echo .

echo ************************ netstat -an **************************** 
netstat -an 
echo . 

echo *********************** net localgroup ************************** 
net localgroup 
echo . 

echo ************************* net session *************************** 
net session 
echo . 

echo ************************** net share **************************** 
net share 
echo . 

echo *********************** net statistics ************************** 
net statistics 
echo . 

echo ********************* net statistics Server ********************* 
net statistics Server 
echo . 

echo ******************* net statistics Workstation ****************** 
net statistics Workstation 
echo . 

echo **************************** net use **************************** 
net use 
echo . 

echo *************************** net user **************************** 
net user 
echo . 

echo ************************** nbtstat -n ************************** 
nbtstat -n 
echo . 

echo ************************** nbtstat -r ************************** 
nbtstat -r 
echo . 

echo ************************** nbtstat -s ************************** 
nbtstat -s 
echo . 

echo ************************** nbtstat -S ************************** 
nbtstat -S 
echo . 
