@echo off
reg EXPORT HKEY_LOCAL_MACHINE\software\microsoft\windows\currentversion\uninstall %1
