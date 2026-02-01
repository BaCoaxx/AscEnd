#include-once
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <Date.au3>

Global $aVanguardQuests[9][2] = [ _
    [0, "V Bounty - Blazefiend Griefblade"], _; ANCHOR
    [1, "V Rescue - Farmer Hamnet"], _
    [2, "V Annihilation - Charr"], _
    [3, "V Bounty - Countess Nadya"], _
    [4, "V Rescue - Footman Tate"], _
    [5, "V Annihilation - Bandits"], _
    [6, "V Bounty - Utini Wupwup"], _
    [7, "V Rescue - Save the Ascalonian Noble"], _
    [8, "V Annihilation - Undead"] _
]

Global Const $VANGUARD_EPOCH = "2026/01/14 16:01:00"

Func _GetVanguardQuestByOffset($iDayOffset)
    Local $iQuestCount = UBound($aVanguardQuests)

    ; Current UTC timestamp
    Local $tNowUTC = _DateDiff("s", "1970/01/01 00:00:00", _NowUTC())

    ; HARD REFERENCE POINT (Blazefiend @ 16:01 UTC)
    Local $tRefUTC = _DateDiff("s", "1970/01/01 00:00:00", $VANGUARD_EPOCH)

    ; Days since reference
    Local $iDaysPassed = Int(($tNowUTC - $tRefUTC) / 86400)

    ; Apply offset (0=today, 1=tomorrow, etc)
    Local $iIndex = Mod($iDaysPassed + $iDayOffset, $iQuestCount)
    If $iIndex < 0 Then $iIndex += $iQuestCount

    Return $aVanguardQuests[$iIndex][1]
EndFunc

Func _NowUTC()
    Local $iTZ = _Date_Time_GetTimeZoneInformation()
    Local $iBias = $iTZ[1] ; minutes offset from UTC
    Return _DateAdd("n", -$iBias, _NowCalc())
EndFunc

; Main Form
$MainGui = GUICreate($BotTitle, 496, 361, 273, 216, -1, BitOR($WS_EX_TOPMOST,$WS_EX_WINDOWEDGE))
GUISetBkColor(0xEAEAEA, $MainGui)

; Combo Boxes For Character Selection & Farms
$Group3 = GUICtrlCreateGroup("", 8, 7, 480, 345)
$Group1 = GUICtrlCreateGroup("Select Your Character", 16, 24, 193, 49)

Global $GUINameCombo
If $doLoadLoggedChars Then
    $GUINameCombo = GUICtrlCreateCombo($g_s_MainCharName, 24, 40, 177, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
    GUICtrlSetData(-1, Scanner_GetLoggedCharNames())
Else
    $GUINameCombo = GUICtrlCreateInput($g_s_MainCharName, 24, 40, 177, 25)
EndIf

Global $FarmCombo
$Group2 = GUICtrlCreateGroup("Select Farm", 16, 76, 193, 49)
$FarmCombo = GUICtrlCreateCombo("", 24, 92, 177, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))

For $i = 0 To UBound($g_a_Farms) - 1
    GUICtrlSetData($FarmCombo, $g_a_Farms[$i][0])
Next

; CheckBox Options
; Survivor Mode, 19 Stop, Purple & Collectors
Global Const $OPT_SURVIVOR  = 1
Global Const $OPT_PURPLE    = 2
Global Const $OPT_COLLECTOR = 4
Global Const $OPT_19STOP    = 8


$Loot = GUICtrlCreateGroup("Loot", 16, 129, 85, 57)
$GUI_CBPurple = GUICtrlCreateCheckbox("Purple?", 24, 145, 73, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_LEFT))
$GUI_CBCollector = GUICtrlCreateCheckbox("Collectors?", 24, 162, 73, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_LEFT))
GUICtrlCreateGroup("", -99, -99, 1, 1)

$Config = GUICtrlCreateGroup("Config", 108, 129, 101, 57)
$GUI_CBSurvivor = GUICtrlCreateCheckbox("Survivor?", 116, 145, 73, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_LEFT))
$GUI_CB19Stop = GUICtrlCreateCheckbox("Stop at 19?", 116, 162, 73, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_LEFT))
GUICtrlCreateGroup("", -99, -99, 1, 1)

Func GetSelectedOptions()
    Local $options = 0

    If GUICtrlRead($GUI_CBSurvivor) = $GUI_CHECKED Then
        $options = BitOR($options, $OPT_SURVIVOR)
    EndIf

    If GUICtrlRead($GUI_CBPurple) = $GUI_CHECKED Then
        $options = BitOR($options, $OPT_PURPLE)
    EndIf

    If GUICtrlRead($GUI_CBCollector) = $GUI_CHECKED Then
        $options = BitOR($options, $OPT_COLLECTOR)
    EndIf

    If GUICtrlRead($GUI_CB19Stop) = $GUI_CHECKED Then
        $options = BitOR($options, $OPT_19STOP)
    EndIf

    Return $options
EndFunc

; Buttons
$GUIStartButton = GUICtrlCreateButton("Start", 221, 32, 65, 33)
GUICtrlSetOnEvent($GUIStartButton, "GuiButtonHandler")
$GUIRefreshButton = GUICtrlCreateButton("Refresh", 292, 32, 65, 33)
GUICtrlSetOnEvent($GUIRefreshButton, "GuiButtonHandler")

; RichEdit Output Box
$g_h_EditText = _GUICtrlRichEdit_Create($MainGui, "", 16, 197, 341, 114, BitOR($ES_AUTOVSCROLL, $ES_MULTILINE, $WS_VSCROLL, $ES_READONLY), $WS_EX_STATICEDGE)
_GUICtrlRichEdit_SetBkColor($g_h_EditText, $COLOR_WHITE)

; Images and Labels
$Pic1 = GUICtrlCreatePic("nudes\AscEnd4.jpg", 371, 31, 108, 279)
$Label3 = GUICtrlCreateLabel("Run Time:", 242, 70, 53, 17)
$Label4 = GUICtrlCreateLabel("Total Time:", 238, 87, 57, 17)
$Label5 = GUICtrlCreateLabel("Red Iris:", 289, 171, 43, 17)
$Label6 = GUICtrlCreateLabel("Unnatural Seeds:", 246, 108, 86, 17)
$Label7 = GUICtrlCreateLabel("Icy Lodestones:", 253, 139, 79, 17)
$Label8 = GUICtrlCreateLabel("Spider Legs:", 269, 124, 63, 17)
$Label9 = GUICtrlCreateLabel("Gargoyle Skulls:", 252, 155, 80, 17)
Global $RunTimeLbl = GUICtrlCreateLabel("00:00:00", 293, 70, 46, 17)
Global $TotalTimeLbl = GUICtrlCreateLabel("00:00:00", 293, 87, 46, 17)
Global $rediriscount = GUICtrlCreateLabel("0", 330, 171, 10, 17)
Global $seeds = GUICtrlCreateLabel("0", 330, 108, 10, 17)
Global $icylodestones = GUICtrlCreateLabel("0", 330, 139, 10, 17)
Global $spiderlegs = GUICtrlCreateLabel("0", 330, 124, 10, 17)
Global $gargskulls = GUICtrlCreateLabel("0", 330, 155, 10, 17)


; Seperator and Current Quest
Global $CurrentVanguardQuest = "Current: " & _GetVanguardQuestByOffset(0) & "  |  Next: " & _GetVanguardQuestByOffset(1)
$Label1 = GUICtrlCreateLabel("Seperator", 13, 327, 473, 2, $SS_ETCHEDHORZ, BitOR($WS_EX_CLIENTEDGE,$WS_EX_STATICEDGE))
$Label2 = GUICtrlCreateLabel($CurrentVanguardQuest, 15, 332, 465, 17, $SS_CENTER)

GUICtrlCreateGroup("", -99, -99, 1, 1)
GUISetOnEvent($GUI_EVENT_CLOSE, "GuiButtonHandler")
GUISetState(@SW_SHOW)

Func GuiButtonHandler()
    Switch @GUI_CtrlId
        Case $GUIStartButton
            If Not $BotRunning Then
                If Not $Bot_Core_Initialized Then
                    InitializeBot()
                    WinSetTitle($MainGui, "", player_GetCharname())
                    GUICtrlSetState($GUINameCombo, $GUI_DISABLE)
                    GUICtrlSetState($GUIRefreshButton, $GUI_DISABLE)
                    $Bot_Core_Initialized = True
                EndIf

                $options = GetSelectedOptions()
                GUICtrlSetState($GUIStartButton, $GUI_DISABLE)
                GUICtrlSetState($FarmCombo, $GUI_DISABLE)
                GUICtrlSetState($GUI_CBSurvivor, $GUI_DISABLE)
                GUICtrlSetState($GUI_CBPurple, $GUI_DISABLE)
                GUICtrlSetState($GUI_CBCollector, $GUI_DISABLE)
                GUICtrlSetState($GUI_CB19Stop, $GUI_DISABLE)

                $Survivor = BitAND($options, $OPT_SURVIVOR)
                LogStatus($Survivor ? "Survivor mode enabled." : "Survivor mode disabled.")
                $Purple = BitAND($options, $OPT_PURPLE)
                LogStatus($Purple ? "Keeping Purples." : "Discarding Purples.")
                $Collector = BitAND($options, $OPT_COLLECTOR)
                LogStatus($Collector ? "Keeping Collectors materials." : "Discarding Collectors materials.")
                $_19Stop = BitAND($options, $OPT_19STOP)
                LogStatus($_19Stop ? "Stopping at level 19, only applicable to hamnet." : "Sending to level 20.")

                GUICtrlSetData($GUIStartButton, "Stop")
                GUICtrlSetState($GUIStartButton, $GUI_ENABLE)
                $BotRunning = True

            ElseIf $BotRunning Then
                GUICtrlSetState($FarmCombo, $GUI_ENABLE)
                GUICtrlSetState($GUI_CBSurvivor, $GUI_ENABLE)
                GUICtrlSetState($GUI_CBPurple, $GUI_ENABLE)
                GUICtrlSetState($GUI_CBCollector, $GUI_ENABLE)
                GUICtrlSetState($GUI_CB19Stop, $GUI_ENABLE)
                
                GUICTrlSetState($GUIStartButton, $GUI_DISABLE)
                GUICtrlSetData($GUIStartButton, "Pausing...")
                LogStatus("Bot will pause, please wait..")
                $BotRunning = False
            EndIf

        Case $GUIRefreshButton
            GUICtrlSetData($GUINameCombo, "")
            GUICtrlSetData($GUINameCombo, Scanner_GetLoggedCharNames())

        Case $GUI_EVENT_CLOSE
            Exit
    EndSwitch
EndFunc

Func InitializeBot()
    GUICtrlSetState($GUIStartButton, $GUI_DISABLE)
    Local $g_s_MainCharName = GUICtrlRead($GUINameCombo)
    If $g_s_MainCharName=="" Then
        If Core_Initialize(ProcessExists("gw.exe"), True) = 0 Then
            MsgBox(0, "Error", "Guild Wars is not running.")
            Exit
        EndIf
    ElseIf $ProcessID Then
        $proc_id_int = Number($ProcessID, 2)
        If Core_Initialize($proc_id_int, True) = 0 Then
            MsgBox(0, "Error", "Could not Find a ProcessID or somewhat '"&$proc_id_int&"'  "&VarGetType($proc_id_int)&"'")
            Exit
            If ProcessExists($proc_id_int) Then
                ProcessClose($proc_id_int)
            EndIf
            Exit
        EndIf
    Else
        If Core_Initialize($g_s_MainCharName, True) = 0 Then
            MsgBox(0, "Error", "Could not Find a Guild Wars client with a Character named '"&$g_s_MainCharName&"'")
            Exit
        EndIf
    EndIf

    $Bot_Core_Initialized = True
EndFunc

Func UpdateStats()
    GUICtrlSetData($RunTimeLbl, FormatElapsedTime($RunTime))
    GUICtrlSetData($rediriscount, GetItemCountByModelID($GC_I_MODELID_RED_IRIS_FLOWER))
    GUICtrlSetData($seeds, GetItemCountByModelID($GC_I_MODELID_UNNATURAL_SEED))
    GUICtrlSetData($icylodestones, GetItemCountByModelID($GC_I_MODELID_ICY_LODESTONE))
    GUICtrlSetData($spiderlegs, GetItemCountByModelID($GC_I_MODELID_SPIDER_LEG))
    GUICtrlSetData($gargskulls, GetItemCountByModelID($GC_I_MODELID_GARGOYLE_SKULL))
EndFunc

Func UpdateTotalTime()
    GUICtrlSetData($TotalTimeLbl, FormatElapsedTime($TotalTime))
EndFunc

Func ResetStart()
    GUICtrlSetState($GUIStartButton, $GUI_ENABLE)
    GUICtrlSetData($GUIStartButton, "Start")
    LogStatus("Bot paused.")
    Sleep(500)
EndFunc