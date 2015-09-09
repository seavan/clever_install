!include StrRep.nsh
!include ReplaceInFile.nsh

Name "Clever Install Test"
OutFile clever_install.exe
; SilentInstall silent


Function CheckFolder1
	IfFileExists C:\cltest 0 +2
	MessageBox MB_OK "Folder Exists"
FunctionEnd

Function getHostName 
	ReadRegStr $0 HKLM "System\CurrentControlSet\Control\ComputerName\ActiveComputerName" "ComputerName"
FunctionEnd


Section ZabbixAgent

	call getHostName
	call CheckFolder1
	Var /GLOBAL ZPath
	StrCpy $ZPath "C:\cltools\zabbix"
	SetOutPath $ZPath
	File /r zabbix\*.*
	Rename  conf\zabbix_agentd.win.conf  conf\zabbix_agentd.conf
	!insertmacro _ReplaceInFile conf\zabbix_agentd.conf "LogFile=c:\zabbix_agentd.log" "LogFile=c:\cltools\zabbix\log\zabbix_agentd.log"	
	
SectionEnd

