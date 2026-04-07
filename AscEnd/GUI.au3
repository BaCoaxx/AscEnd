#include-once
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <Date.au3>
#include <TabConstants.au3>
#include <ProgressConstants.au3>
#include <GuiTab.au3>

; Total exp for each level
Global $g_aLevelXP[20] = [ _
    0, 2000, 4600, 7800, 11600, 16000, 21000, _
    26600, 32800, 39600, 47000, 55000, 63600, _
    72800, 82600, 93000, 104000, 115600, _
    127800, 140600 _
]

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

; Based off wiki data, if it's wrong blame them lol =]
Global $aNicholasItems[52][2] = [ _
    [432, "Grawl Necklaces"], _      ; Day 0 
    [433, "Baked Husks"], _          ; Day 1
    [430, "Skeletal Limbs"], _       ; Day 2
    [428, "Unnatural Seeds"], _      ; Day 3
    [431, "Enchanted Lodestones"], _ ; Day 4
    [429, "Skale Fins"], _           ; Day 5
    [424, "Icy Lodestones"], _       ; Day 6 ANCHOR
    [426, "Gargoyle Skulls"], _      ; Day 7 
    [425, "Dull Carapaces"], _       ; Day 8
    [433, "Baked Husks"], _          ; Day 9
    [2994, "Red Iris Flowers"], _    ; Day 10
    [422, "Spider Legs"], _          ; Day 11
    [430, "Skeletal Limbs"], _       ; Day 12
    [423, "Charr Carvings"], _       ; Day 13
    [431, "Enchanted Lodestones"], _ ; Day 14
    [432, "Grawl Necklaces"], _      ; Day 15
    [424, "Icy Lodestones"], _       ; Day 16
    [427, "Worn Belts"], _           ; Day 17
    [426, "Gargoyle Skulls"], _      ; Day 18
    [428, "Unnatural Seeds"], _      ; Day 19
    [429, "Skale Fins"], _           ; Day 20
    [2994, "Red Iris Flowers"], _    ; Day 21
    [431, "Enchanted Lodestones"], _ ; Day 22
    [430, "Skeletal Limbs"], _       ; Day 23
    [423, "Charr Carvings"], _       ; Day 24
    [422, "Spider Legs"], _          ; Day 25
    [433, "Baked Husks"], _          ; Day 26
    [426, "Gargoyle Skulls"], _      ; Day 27
    [428, "Unnatural Seeds"], _      ; Day 28
    [424, "Icy Lodestones"], _       ; Day 29
    [432, "Grawl Necklaces"], _      ; Day 30
    [431, "Enchanted Lodestones"], _ ; Day 31
    [427, "Worn Belts"], _           ; Day 32
    [425, "Dull Carapaces"], _       ; Day 33
    [422, "Spider Legs"], _          ; Day 34
    [426, "Gargoyle Skulls"], _      ; Day 35
    [424, "Icy Lodestones"], _       ; Day 36
    [428, "Unnatural Seeds"], _      ; Day 37
    [427, "Worn Belts"], _           ; Day 38
    [432, "Grawl Necklaces"], _      ; Day 39
    [433, "Baked Husks"], _          ; Day 40
    [430, "Skeletal Limbs"], _       ; Day 41
    [2994, "Red Iris Flowers"], _    ; Day 42
    [423, "Charr Carvings"], _       ; Day 43
    [429, "Skale Fins"], _           ; Day 44
    [425, "Dull Carapaces"], _       ; Day 45
    [431, "Enchanted Lodestones"], _ ; Day 46
    [423, "Charr Carvings"], _       ; Day 47
    [422, "Spider Legs"], _          ; Day 48
    [2994, "Red Iris Flowers"], _    ; Day 49
    [427, "Worn Belts"], _           ; Day 50
    [425, "Dull Carapaces"] _        ; Day 51
]

Global $g_aNicholasFarmMap[13][2] = [ _
    [432, "Farm_GrawlNecklace"], _
    [433, "Farm_BakedHusk"], _
    [430, "Farm_SkeletonLimbs"], _
    [428, "Farm_UnnaturalSeeds"], _
    [431, "Farm_EnchLodes"], _
    [429, "Farm_Skale"], _
    [424, "Farm_IcyLodes"], _
    [426, "Farm_GargoyleSkull"], _
    [425, "Farm_Carapace"], _
    [2994, "Farm_RedIris"], _
    [422, "Farm_UnnaturalSeeds"], _
    [423, "Farm_CharrBossFarm"], _
    [427, "Farm_WornBelts"] _
]

Global Const $NICHOLAS_EPOCH = "2026/03/25 07:00:00"
Global Const $NICHOLAS_EPOCH_INDEX = 6
Global Const $VANGUARD_EPOCH = "2026/01/14 16:01:00"

Func _GetNicholasItemByOffset($iDayOffset)
    Local $iItemCount = UBound($aNicholasItems)
    
    ; Current UTC timestamp
    Local $tNowUTC = _DateDiff("s", "1970/01/01 00:00:00", _NowUTC())
    
    ; Reference point (Icy Lodestone @ March 25, 2026 07:00:00 UTC)
    Local $tRefUTC = _DateDiff("s", "1970/01/01 00:00:00", $NICHOLAS_EPOCH)
    
    ; Days since reference (changes daily at 07:00 UTC)
    Local $iDaysPassed = Int(($tNowUTC - $tRefUTC) / 86400)
    
    ; Apply offset (0=today, 1=tomorrow, -1=yesterday, etc)
    Local $iIndex = Mod($NICHOLAS_EPOCH_INDEX + $iDaysPassed + $iDayOffset, $iItemCount)
    If $iIndex < 0 Then $iIndex += $iItemCount
    
    ; Return array with [ModelID, ItemName]
    Local $aResult[2]
    $aResult[0] = $aNicholasItems[$iIndex][0]
    $aResult[1] = $aNicholasItems[$iIndex][1]
    
    Return $aResult
EndFunc

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
$MainGui = GUICreate($BotTitle, 496, 411, 449, 181, -1, BitOR($WS_EX_TOPMOST,$WS_EX_WINDOWEDGE))

; Combo Boxes For Character Selection & Farms
$Group3 = GUICtrlCreateGroup("", 8, 7, 480, 395, -1,  $WS_EX_TRANSPARENT)
$Group1 = GUICtrlCreateGroup("Select Your Character", 16, 24, 193, 49)

Global $GUINameCombo
If $doLoadLoggedChars Then
    $GUINameCombo = GUICtrlCreateCombo($g_s_MainCharName, 24, 40, 177, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
    GUICtrlSetData(-1, Scanner_GetLoggedCharNames())
Else
    $GUINameCombo = GUICtrlCreateInput($g_s_MainCharName, 24, 40, 177, 25)
EndIf
GUICtrlCreateGroup("", -99, -99, 1, 1)

Global $FarmCombo
$Group2 = GUICtrlCreateGroup("Select Farm", 16, 76, 193, 49)
$FarmCombo = GUICtrlCreateCombo("", 24, 92, 177, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))

For $i = 0 To UBound($g_a_Farms) - 1
    GUICtrlSetData($FarmCombo, $g_a_Farms[$i][0])
Next
GUICtrlCreateGroup("", -99, -99, 1, 1)

; CheckBox Options
; Survivor Mode, 19 Stop
Global Const $OPT_SURVIVOR  = 1
Global Const $OPT_19STOP    = 8

$Group4 = GUICtrlCreateGroup("Loot Config", 16, 129, 86, 57)
$GUISettingsButton = GUICtrlCreateButton("Settings", 31, 146, 57, 33)
GUICtrlSetOnEvent($GUISettingsButton, "GuiButtonHandler")
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

; Images, Tabs and Labels
$Pic1 = GUICtrlCreatePic("nudes\AscEnd.jpg", 371, 31, 108, 279)
$Label3 = GUICtrlCreateLabel("Run Time:", 242, 70, 53, 17)
$Label4 = GUICtrlCreateLabel("Total Time:", 238, 87, 57, 17)
$RunTimeLbl = GUICtrlCreateLabel("00:00:00", 293, 70, 46, 17)
$TotalTimeLbl = GUICtrlCreateLabel("00:00:00", 293, 87, 46, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)

$Tab1 = GUICtrlCreateTab(224, 104, 134, 83)
GUICtrlSetFont(-1, 6, 400, 0, "Arial")
$TabSheet1 = GUICtrlCreateTabItem("1")
GUICtrlSetState(-1,$GUI_SHOW)
$Label7 = GUICtrlCreateLabel("Red Iris:", 280, 125, 43, 17, $SS_RIGHT)
$Label8 = GUICtrlCreateLabel("Baked Husk:", 257, 140, 66, 17, $SS_RIGHT)
$Label9 = GUICtrlCreateLabel("Charr Carving:", 252, 155, 71, 17, $SS_RIGHT)
$Label10 = GUICtrlCreateLabel("Enchanted Lodes:", 232, 170, 91, 17, $SS_RIGHT)
$red_iris = GUICtrlCreateLabel("0", 323, 126, 30, 17, $SS_CENTER)
$baked_husk = GUICtrlCreateLabel("0", 323, 141, 30, 17, $SS_CENTER)
$charr_carv = GUICtrlCreateLabel("0", 323, 156, 30, 17, $SS_CENTER)
$ench_lodes = GUICtrlCreateLabel("0", 323, 171, 30, 17, $SS_CENTER)
$TabSheet2 = GUICtrlCreateTabItem("2")
$Label11 = GUICtrlCreateLabel("Skale Fin:", 272, 125, 51, 17, $SS_RIGHT)
$Label12 = GUICtrlCreateLabel("Grawl Necklace:", 240, 140, 83, 17, $SS_RIGHT)
$Label13 = GUICtrlCreateLabel("Unnatural Seeds:", 237, 155, 86, 17, $SS_RIGHT)
$Label14 = GUICtrlCreateLabel("Icy Lodes:", 270, 170, 53, 17, $SS_RIGHT)
$skale_fin = GUICtrlCreateLabel("0", 323, 126, 30, 17, $SS_CENTER)
$grawl_neck = GUICtrlCreateLabel("0", 323, 141, 30, 17, $SS_CENTER)
$unnatural_seeds = GUICtrlCreateLabel("0", 323, 156, 30, 17, $SS_CENTER)
$icy_lodes = GUICtrlCreateLabel("0", 323, 171, 30, 17, $SS_CENTER)
$TabSheet3 = GUICtrlCreateTabItem("3")
$Label15 = GUICtrlCreateLabel("Dull Carapace:", 249, 125, 74, 17, $SS_RIGHT)
$Label16 = GUICtrlCreateLabel("Spider Leg:", 249, 140, 74, 17, $SS_RIGHT)
$Label17 = GUICtrlCreateLabel("Skeletal Limb:", 249, 155, 74, 17, $SS_RIGHT)
$Label18 = GUICtrlCreateLabel("Gargoyle Skull:", 249, 170, 74, 17, $SS_RIGHT)
$dull_carap = GUICtrlCreateLabel("0", 323, 126, 30, 17, $SS_CENTER)
$spider_leg = GUICtrlCreateLabel("0", 323, 141, 30, 17, $SS_CENTER)
$skeletal_limb = GUICtrlCreateLabel("0", 323, 156, 30, 17, $SS_CENTER)
$gargoyle_skull = GUICtrlCreateLabel("0", 323, 171, 30, 17, $SS_CENTER)
GUICtrlCreateTabItem("")

; Seperators and Current Quest
Global $CurrentVanguardQuest = "Current: " & _GetVanguardQuestByOffset(0) & "  |  Next: " & _GetVanguardQuestByOffset(1)
GUICtrlCreateLabel("", 13, 327, 473, 2, $SS_ETCHEDHORZ, BitOR($WS_EX_CLIENTEDGE,$WS_EX_STATICEDGE))
$CVQ_Label = GUICtrlCreateLabel($CurrentVanguardQuest, 15, 333, 473, 17, $SS_CENTER)
GUICtrlCreateLabel("", 13, 351, 473, 2, $SS_ETCHEDHORZ, BitOR($WS_EX_CLIENTEDGE,$WS_EX_STATICEDGE))

; Progress bar and level indicator
$Progress = GUICtrlCreateProgress(15, 362, 465, 17, $PBS_SMOOTH)
GUICtrlSetColor(-1, 0x00FF00)

Func UpdateProgressBar()
    Static $iLastXP = -1

    Local $iMyXP = World_GetWorldInfo("Experience")

    If $iMyXP = $iLastXP Then Return
    $iLastXP = $iMyXP

    Local $iMyLevel = 0

    For $i = UBound($g_aLevelXP) - 1 To 0 Step -1
        If $iMyXP >= $g_aLevelXP[$i] Then
            $iMyLevel = $i
            ExitLoop
        EndIf
    Next

    ; At max level, fill the bar to 100%
    If $iMyLevel >= UBound($g_aLevelXP) - 1 Then
        GUICtrlSetData($Progress, 100)
        GUICtrlSetData($explbl, "LDoA!")
        Return
    EndIf

    Local $iLevelStart = $g_aLevelXP[$iMyLevel]
    Local $iLevelEnd   = $g_aLevelXP[$iMyLevel + 1]

    Local $fPercent = (($iMyXP - $iLevelStart) / ($iLevelEnd - $iLevelStart)) * 100

    GUICtrlSetData($explbl, ($iLevelEnd - $iMyXP) & " XP Needed")
    GUICtrlSetData($Progress, Round($fPercent))
EndFunc

Global $Level = "--"
$levellbl = GUICtrlCreateLabel("Level: " & $Level, 15, 383, 48, 17)
GUICtrlSetFont(-1, 9, 400, 0, "MS Sans Serif")
GUICtrlSetColor(-1, 0x008000)
$explbl = GUICtrlCreateLabel($Level & " XP Needed", 216, 383, 264, 17, $SS_RIGHT)
GUICtrlSetColor(-1, 0x008000)

; Nicholas Sandford Exchange
Global $NickItem = _GetNicholasItemByOffset(0)
Global $NickItemDisplay = "Current: " & $NickItem[1] & "  |  Next: " & _GetNicholasItemByOffset(1)[1]
$Nick_Label = GUICtrlCreateLabel($NickItemDisplay, 82, 383, 330, 17, $SS_CENTER)
GUICtrlSetBkColor($Nick_Label, $GUI_BKCOLOR_TRANSPARENT)

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
                GUICtrlSetState($GUI_CB19Stop, $GUI_DISABLE)
                GUICtrlSetState($GUISettingsButton, $GUI_DISABLE)

                $Survivor = BitAND($options, $OPT_SURVIVOR)
                LogStatus($Survivor ? "Survivor mode enabled." : "Survivor mode disabled.")
                $_19Stop = BitAND($options, $OPT_19STOP)
                LogStatus($_19Stop ? "Stopping at level 19, only applicable to hamnet." : "Sending to level 20.")

                GUICtrlSetData($GUIStartButton, "Stop")
                GUICtrlSetState($GUIStartButton, $GUI_ENABLE)
                $BotRunning = True

            ElseIf $BotRunning Then
                GUICtrlSetState($FarmCombo, $GUI_ENABLE)
                GUICtrlSetState($GUI_CBSurvivor, $GUI_ENABLE)
                GUICtrlSetState($GUI_CB19Stop, $GUI_ENABLE)
                GUICtrlSetState($GUISettingsButton, $GUI_ENABLE)
                
                GUICTrlSetState($GUIStartButton, $GUI_DISABLE)
                GUICtrlSetData($GUIStartButton, "Pausing...")
                LogStatus("Bot will pause, please wait..")
                $BotRunning = False
            EndIf

        Case $GUIRefreshButton
            GUICtrlSetData($GUINameCombo, "")
            GUICtrlSetData($GUINameCombo, Scanner_GetLoggedCharNames())

        Case $GUISettingsButton
            ShowLootSettings()

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
    GUICtrlSetData($red_iris, GetItemCountByModelID($GC_I_MODELID_RED_IRIS_FLOWER))
    GUICtrlSetData($baked_husk, GetItemCountByModelID($GC_I_MODELID_BAKED_HUSK))
    GUICtrlSetData($charr_carv, GetItemCountByModelID($GC_I_MODELID_CHARR_CARVING))
    GUICtrlSetData($ench_lodes, GetItemCountByModelID($GC_I_MODELID_ENCHANTED_LODESTONE))
    GUICtrlSetData($skale_fin, GetItemCountByModelID($GC_I_MODELID_SKALE_FIN_PRE))
    GUICtrlSetData($grawl_neck, GetItemCountByModelID($GC_I_MODELID_GRAWL_NECKLACE))
    GUICtrlSetData($unnatural_seeds, GetItemCountByModelID($GC_I_MODELID_UNNATURAL_SEED))
    GUICtrlSetData($icy_lodes, GetItemCountByModelID($GC_I_MODELID_ICY_LODESTONE))
    GUICtrlSetData($dull_carap, GetItemCountByModelID($GC_I_MODELID_DULL_CARAPACE))
    GUICtrlSetData($spider_leg, GetItemCountByModelID($GC_I_MODELID_SPIDER_LEG))
    GUICtrlSetData($skeletal_limb, GetItemCountByModelID($GC_I_MODELID_SKELETAL_LIMB))
    GUICtrlSetData($gargoyle_skull, GetItemCountByModelID($GC_I_MODELID_GARGOYLE_SKULL))
EndFunc

Func UpdateTotalTime()
    GUICtrlSetData($TotalTimeLbl, FormatElapsedTime($TotalTime))
EndFunc

Func UpdateProgress()
    If Map_GetInstanceInfo("Type") <> $GC_I_MAP_TYPE_LOADING Then
        UpdateProgressBar()
        Local $lvl = Agent_GetAgentInfo(-2, "Level")
        If $lvl <> $Level Then
            $Level = $lvl
            GUICtrlSetData($levellbl, "Level: " & $Level)
        EndIf
    EndIf
EndFunc

Func ResetStart()
    GUICtrlSetState($GUIStartButton, $GUI_ENABLE)
    GUICtrlSetState($FarmCombo, $GUI_ENABLE)
    GUICtrlSetState($GUI_CBSurvivor, $GUI_ENABLE)
    GUICtrlSetState($GUI_CB19Stop, $GUI_ENABLE)
    GUICtrlSetState($GUISettingsButton, $GUI_ENABLE)
    GUICtrlSetData($GUIStartButton, "Start")
    $CharrBossPickup = True
    $hasBonus = False
    $NickRun = False
    LogStatus("Bot paused.")
    Sleep(500)
EndFunc