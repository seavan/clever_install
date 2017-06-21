!define APPNAME "CleverRus Toolset"
!define COMPANYNAME "Clever Distribution, LLC"
!define VERSIONMAJOR 0
!define VERSIONMINOR 2
!define VERSIONBUILD 1

!include "MUI2.nsh"
!include "StrRep.nsh"
!include "ReplaceInFile.nsh"
!include "nsDialogs.nsh"
!include "LogicLib.nsh"
!define ARP "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
!include "FileFunc.nsh"
!include x64.nsh

Name "Clever Toolset 0.2"
OutFile "clever_install.exe"
RequestExecutionLevel admin

XPStyle on
; SilentInstall silent
Var Dialog
Var Text
Var Label
; Var /Global Hostname

; Page custom nsDialogsHostName nsDialogsHostNameLeave
Page instfiles


!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Russian"

LangString Label_Host ${LANG_ENGLISH} "Please enter correct hostname for zabbix:"
LangString Label_Host ${LANG_RUSSIAN} "Введите корректное имя хоста для zabbix:"
LangString Label_Uninstall ${LANG_ENGLISH} "${APPNAME} is already installed. Reinstalling"
LangString Label_Uninstall ${LANG_RUSSIAN} "${APPNAME} уже установлен. Переустанавливаю"
LangString Label_Uninstall_Complete ${LANG_ENGLISH} "${APPNAME} is removed"
LangString Label_Uninstall_Complete ${LANG_RUSSIAN} "${APPNAME} удален"

Function .onInit
	UserInfo::GetAccountType
	pop $0
	${If} $0 != "admin" ;Require admin rights on NT4+
		MessageBox mb_iconstop "Administrator rights required!"
		SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
		Quit
	${EndIf}
 
	ReadRegStr $R0 HKLM \
	"Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" \
	"QuietUninstallString"
	StrCmp $R0 "" done
 
	MessageBox MB_OK $(Label_Uninstall) IDOK uninst
	Abort
 
;Run the uninstaller
uninst:
	ClearErrors
	ExecWait "$R0";
	MessageBox MB_OK $(Label_Uninstall_Complete)
done:
 
FunctionEnd

; Function getHostName 
;	ReadRegStr $0 HKLM "System\CurrentControlSet\Control\ComputerName\ActiveComputerName" "ComputerName"
;	return
; FunctionEnd

;Function nsDialogsHostName
;	nsDialogs::Create 1018
;	Pop $Dialog
;	Call getHostName
;	Pop $0	
;	${NSD_CreateLabel} 0 0 100% 12u $(Label_Host)
;	Pop $Label	
;	${NSD_CreateText} 0 13u 100% 12u "$0"
;	Pop $Text
;	nsDialogs::Show
;FunctionEnd

; Function nsDialogsHostNameLeave
; 	${NSD_GetText} $Text $Hostname
; FunctionEnd


Section GetHostNameScript
	StrCpy $INSTDIR "C:\cltools"
	SetOutPath "$INSTDIR\gethostname"
	File /r gethostname\*.*
	ExecWait "$INSTDIR\gethostname\gethostname.bat"
SectionEnd

Section ZabbixAgent
	RMDir /r "$INSTDIR\zabbix"	
	SetOutPath "$INSTDIR\zabbix"
	CreateDirectory "$INSTDIR\zabbix\conf\zabbix_agentd.conf.d"		
	File /r zabbix\*.*
	Rename  conf\zabbix_agentd.win.conf  conf\zabbix_agentd.conf
	!insertmacro _ReplaceInFile conf\zabbix_agentd.conf "LogFile=c:\zabbix_agentd.log" "LogFile=$INSTDIR\zabbix\log\zabbix_agentd.log"	
	!insertmacro _ReplaceInFile conf\zabbix_agentd.conf "Server=127.0.0.1" "Server=srv-zabbix-01.erevan.biz"	
	
;	!insertmacro _ReplaceInFile conf\zabbix_agentd.conf "Hostname=Windows host" "Hostname=$Hostname"
	!insertmacro _ReplaceInFile conf\zabbix_agentd.conf "ServerActive=127.0.0.1" "ServerActive=srv-zabbix-01.erevan.biz"
SectionEnd


Section ProcessExplorer
	SetOutPath "$INSTDIR\procexp"
	File /r procexp\*.*
SectionEnd

Section Install
	WriteRegStr HKLM "${ARP}" \
                 "DisplayName" "${APPNAME}"
	WriteRegStr HKLM "${ARP}" \
                 "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "${ARP}" \
                 "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
	IntFmt $0 "0x%08X" $0
	WriteRegDWORD HKLM "${ARP}" "EstimatedSize" "$0"
	
	${If} ${RunningX64}
		ExecWait "$INSTDIR\zabbix\bin\win64\zabbix_agentd.exe --install --config $INSTDIR\zabbix\conf\zabbix_agentd.conf"
		ExecWait "$INSTDIR\zabbix\bin\win64\zabbix_agentd.exe --start"
	${Else}
		ExecWait "$INSTDIR\zabbix\bin\win32\zabbix_agentd.exe --install --config $INSTDIR\zabbix\conf\zabbix_agentd.conf"
		ExecWait "$INSTDIR\zabbix\bin\win32\zabbix_agentd.exe --start"
	${EndIf}  	
SectionEnd

Section "Uninstall"
	${If} ${RunningX64}
		ExecWait "$INSTDIR\zabbix\bin\win64\zabbix_agentd.exe --stop";
		ExecWait "$INSTDIR\zabbix\bin\win64\zabbix_agentd.exe --uninstall";
	${Else}
		ExecWait "$INSTDIR\zabbix\bin\win32\zabbix_agentd.exe --stop";
		ExecWait "$INSTDIR\zabbix\bin\win32\zabbix_agentd.exe --uninstall";
	${EndIf}  	
	RMDir /r "$INSTDIR"
	DeleteRegKey HKLM "${ARP}"	
SectionEnd

Section
	WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd
