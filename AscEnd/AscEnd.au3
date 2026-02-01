#RequireAdmin
#include "../../API/_GwAu3.au3"
#include "../../API/SmartCast/_UtilityAI.au3"
#include "GwAu3_AddOns.au3"

#Region Declarations

; =======================
; Globals
; =======================

Global Const $doLoadLoggedChars = True
Opt("GUIOnEventMode", 1)
Opt("GUICloseOnESC", False)
Opt("ExpandVarStrings", 1)

Global $ProcessID = ""
Global $timer = TimerInit()
Global $TotalTime = 0
Global $RunTime = 0
Global $g_b_DebugMode = False
Global Const $BotTitle = "AscEnd"
Global $BotRunning = False
Global $Bot_Core_Initialized = False
Global $Survivor = False
Global $_19Stop = False
Global $Collector = False
Global $Purple = False
Global $spawn[2] = [0, 0]
Global $hasBoners = False

$g_bAutoStart = False  ; Flag for auto-start
$g_s_MainCharName  = ""

; =======================
; Logging
; =======================

Global Const $g_s_LogFile = @ScriptDir & "\console_log.txt"
FileDelete($g_s_LogFile)
OnAutoItExitRegister("_OnExitLog")

#EndRegion Declaration

#include "Farms/Farms_All.au3"

; =======================
; Command line arguments
; =======================

For $i = 1 To $CmdLine[0]
    If $CmdLine[$i] = "-character" And $i < $CmdLine[0] Then
        $g_s_MainCharName = $CmdLine[$i + 1]
        $g_bAutoStart = True
        ExitLoop
    EndIf
Next

#include "GUI.au3"

; =======================
; Startup info
; =======================

LogInfo("Based on GWA2")
LogInfo("GWA2 - Created by: " & $GC_S_GWA2_CREATOR)
LogInfo("GWA2 - Build date: " & $GC_S_GWA2_BUILD_DATE & @CRLF)
LogInfo("GwAu3 - Created by: " & $GC_S_UPDATOR)
LogInfo("GwAu3 - Build date: " & $GC_S_BUILD_DATE)
LogInfo("GwAu3 - Version: " & $GC_S_VERSION)
LogInfo("GwAu3 - Last Update: " & $GC_S_LAST_UPDATE & @CRLF)
Core_AutoStart()

While Not $BotRunning
    Sleep(100)
WEnd

While True
    If $BotRunning = True Then
        RunSelectedFarm()
    Else
        Sleep(1000)
    EndIf
WEnd

; =======================
; Functions
; =======================

Func RunSelectedFarm()
    Local $FarmToRun = GUICtrlRead($FarmCombo)

    If $FarmToRun = "" Then
        LogError("Error: No farm selected.")
        LogError("Bot will close in 5 seconds...")
        Sleep(5000)
        Exit
    EndIf

    For $i = 0 To UBound($g_a_Farms) - 1
        If $g_a_Farms[$i][0] = $FarmToRun Then
            If $g_a_Farms[$i][1] = "" Then Return False

            AdlibRegister("UpdateTotalTime", 1000)
            $TotalTime = TimerInit()
            UpdateStats()
            LogInfo("Starting farm: " & $FarmToRun)
            Return Call($g_a_Farms[$i][1])
        EndIf
    Next

    LogError("Error: No valid farm selected.")
    LogError("Bot will close in 5 seconds...")
    Exit
EndFunc

Func GetBoners()
    Map_RndTravel(148)
    Sleep(250)

    If FindSummoningStone() Then
        LogInfo("Summoning stone found!")
        Return
    EndIf

    LogError("No stone found, grabbing boners!")
    Chat_SendChat("bonus", "/")
    Other_RndSleep(4500)

    DeleteBonusItems()

    If FindSummoningStone() Then
        LogInfo("Boners collected successfully.")
    Else
        LogError("No boners available..")
    EndIf
    
    Other_RndSleep(1500)
    $hasBoners = True
EndFunc

; =======================
; Logging helpers
; =======================

Func LogInfo($sText)
    _LogWrite("INFO", $sText)
EndFunc

Func LogWarn($sText)
    _LogWrite("WARN", $sText)
EndFunc

Func LogStatus($sText)
	_LogWrite("STATUS", $sText)
EndFunc

Func LogError($sText)
    _LogWrite("ERROR", $sText)
EndFunc

Func _LogWrite($sLevel, $sText)
    Local $sLine = _
        @CRLF & "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & $sLevel & "] " & _
        $sText

    ; GUI console
    If IsDeclared("g_h_EditText") Then
        Local $l_x_Color
        Switch $sLevel
            Case "ERROR"
                $l_x_Color = 0x322CCA ; Red
            Case "WARN"
                $l_x_Color = 0x790984 ; Purple
            Case "STATUS"
                $l_x_Color = 0xC76D09 ; Blue
            Case "INFO"
                $l_x_Color = 0x000000 ; Black
        EndSwitch

        ; Append text with color
        _GUICtrlRichEdit_SetSel($g_h_EditText, -1, -1)
        _GUICtrlRichEdit_SetCharColor($g_h_EditText, $l_x_Color)
        _GUICtrlRichEdit_AppendText($g_h_EditText, $sLine)
        _GUICtrlEdit_Scroll($g_h_EditText, 1)
    EndIf

    ; File log (crash safe)
    Local $hFile = FileOpen($g_s_LogFile, $FO_APPEND)
    If $hFile <> -1 Then
        FileWrite($hFile, $sLine)
        FileClose($hFile)
    EndIf
EndFunc

Func _OnExitLog()
    Local $code = @exitCode
    Local $msg = "Script terminated. ExitCode=" & $code
    Local $hFile = FileOpen($g_s_LogFile, $FO_APPEND)
    If $hFile <> -1 Then
        FileWrite($hFile, _
            @CRLF & "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] [EXIT] " & _
            $msg)
        FileClose($hFile)
    EndIf
EndFunc