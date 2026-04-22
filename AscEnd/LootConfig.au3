#include-once
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

; ============================================================================
; Global Variables & INI Loading
; ============================================================================
Global $sIniFile = @ScriptDir & "\lootconfig.ini"

; Load variables from INI (Defaulting to "0" / False)
Global $isPurplePickup = (IniRead($sIniFile, "Pickup", "Purple", "0") == "1")
Global $isPurpleSell   = (IniRead($sIniFile, "Sell", "Purple", "0") == "1")
Global $isGoldPickup   = (IniRead($sIniFile, "Pickup", "Gold", "0") == "1")
Global $isGoldSell     = (IniRead($sIniFile, "Sell", "Gold", "0") == "1")
Global $isBluePickup   = (IniRead($sIniFile, "Pickup", "Blue", "0") == "1")
Global $isBlueSell     = (IniRead($sIniFile, "Sell", "Blue", "0") == "1")
Global $isBlackPickup  = (IniRead($sIniFile, "Pickup", "Black", "0") == "1")
Global $isBlackSell    = (IniRead($sIniFile, "Sell", "Black", "0") == "1")
Global $isWhitePickup  = (IniRead($sIniFile, "Pickup", "White", "0") == "1")
Global $isWhiteSell    = (IniRead($sIniFile, "Sell", "White", "0") == "1")
Global $isOtherPickup  = (IniRead($sIniFile, "Pickup", "Other", "0") == "1")
Global $isOtherSell    = (IniRead($sIniFile, "Sell", "Other", "0") == "1")
Global $isPconsPickup  = (IniRead($sIniFile, "Pickup", "Pcons", "0") == "1")
Global $isPconsSell    = (IniRead($sIniFile, "Sell", "Pcons", "0") == "1")
Global $isCBagPickup   = (IniRead($sIniFile, "Pickup", "CBag", "0") == "1")
Global $isCBagSell     = (IniRead($sIniFile, "Sell", "CBag", "0") == "1")
Global $isCSalvPickup  = (IniRead($sIniFile, "Pickup", "CSalv", "0") == "1")
Global $isCSalvSell    = (IniRead($sIniFile, "Sell", "CSalv", "0") == "1")
Global $isCollPickup   = (IniRead($sIniFile, "Pickup", "Coll", "0") == "1")
Global $isCollSell     = (IniRead($sIniFile, "Sell", "Coll", "0") == "1")

; Declare GUI Control Variables globally so Event Functions can read them
Global $LootGui, $PurplePickup, $Radio3, $Radio4, $GoldPickup, $Radio1, $Radio2
Global $BluePickup, $Radio5, $Radio6, $BlackPickup, $Radio7, $Radio8
Global $WhitePickup, $Radio11, $Radio12, $OtherDyePickup, $Radio9, $Radio10
Global $PconPickup, $Radio13, $Radio14, $CBagPickup, $Radio15, $Radio16
Global $CSalvPickup, $Radio17, $Radio18, $CollectorPickup, $Radio19, $Radio20
Global $ApplyBtn, $CloseBtn

; ============================================================================
; GUI Initialization
; ============================================================================
Func InitLootSettingsGUI()
    $LootGui = GUICreate("AscEnd - Loot Config", 258, 309, -1, -1, -1, BitOR($WS_EX_TOPMOST,$WS_EX_WINDOWEDGE))
    GUISetOnEvent($GUI_EVENT_CLOSE, "LootSettings_Close", $LootGui)

    GUICtrlCreateGroup("Loot", 8, 7, 242, 295, -1, $WS_EX_TRANSPARENT)
    GUICtrlSetFont(-1, 12, 800, 0, "Arial")

    GUICtrlCreateGroup("Purple", 95, 29, 64, 65)
    GUICtrlSetFont(-1, 10, 400, 0, "Arial Rounded MT Bold")
    GUICtrlSetColor(-1, 0x800080)
    $Radio3 = GUICtrlCreateRadio("Keep", 106, 44, 49, 25)
    $Radio4 = GUICtrlCreateRadio("Sell", 106, 64, 49, 25)
    $PurplePickup = GUICtrlCreateCheckbox("", 152, 29, 17, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_CENTER,$BS_VCENTER))
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    GUICtrlCreateGroup("Gold", 20, 29, 64, 65)
    GUICtrlSetFont(-1, 10, 400, 0, "Arial Rounded MT Bold")
    GUICtrlSetColor(-1, 0xFFFF00)
    $Radio1 = GUICtrlCreateRadio("Keep", 31, 44, 49, 25)
    $Radio2 = GUICtrlCreateRadio("Sell", 31, 64, 49, 25)
    $GoldPickup = GUICtrlCreateCheckbox("", 77, 29, 17, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_CENTER,$BS_VCENTER))
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    GUICtrlCreateGroup("Blue", 171, 29, 64, 65)
    GUICtrlSetFont(-1, 10, 400, 0, "Arial Rounded MT Bold")
    GUICtrlSetColor(-1, 0x00FFFF)
    $Radio5 = GUICtrlCreateRadio("Keep", 182, 44, 49, 25)
    $Radio6 = GUICtrlCreateRadio("Sell", 182, 64, 49, 25)
    $BluePickup = GUICtrlCreateCheckbox("", 228, 29, 17, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_CENTER,$BS_VCENTER))
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    GUICtrlCreateGroup("Black Dye", 19, 96, 104, 48)
    GUICtrlSetFont(-1, 10, 400, 0, "Arial Rounded MT Bold")
    $Radio7 = GUICtrlCreateRadio("Keep", 30, 111, 49, 25)
    $Radio8 = GUICtrlCreateRadio("Sell", 79, 111, 37, 25)
    $BlackPickup = GUICtrlCreateCheckbox("", 116, 96, 17, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_CENTER,$BS_VCENTER))
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    GUICtrlCreateGroup("Other Dye", 19, 145, 104, 48)
    GUICtrlSetFont(-1, 10, 400, 0, "Arial Rounded MT Bold")
    $Radio9 = GUICtrlCreateRadio("Keep", 30, 160, 49, 25)
    $Radio10 = GUICtrlCreateRadio("Sell", 79, 160, 37, 25)
    $OtherDyePickup = GUICtrlCreateCheckbox("", 116, 145, 17, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_CENTER,$BS_VCENTER))
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    GUICtrlCreateGroup("White Dye", 131, 96, 104, 48)
    GUICtrlSetFont(-1, 10, 400, 0, "Arial Rounded MT Bold")
    $Radio11 = GUICtrlCreateRadio("Keep", 142, 111, 49, 25)
    $Radio12 = GUICtrlCreateRadio("Sell", 191, 111, 37, 25)
    $WhitePickup = GUICtrlCreateCheckbox("", 228, 96, 17, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_CENTER,$BS_VCENTER))
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    GUICtrlCreateGroup("PCons", 131, 145, 104, 48)
    GUICtrlSetFont(-1, 10, 400, 0, "Arial Rounded MT Bold")
    GUICtrlSetColor(-1, 0x008080)
    $Radio13 = GUICtrlCreateRadio("Keep", 142, 160, 49, 25)
    $Radio14 = GUICtrlCreateRadio("Sell", 191, 160, 37, 25)
    $PconPickup = GUICtrlCreateCheckbox("", 228, 145, 17, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_CENTER,$BS_VCENTER))
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    GUICtrlCreateGroup("Charr Bag", 19, 195, 104, 48)
    GUICtrlSetFont(-1, 10, 400, 0, "Arial Rounded MT Bold")
    GUICtrlSetColor(-1, 0xFF0000)
    $Radio15 = GUICtrlCreateRadio("Keep", 30, 210, 49, 25)
    $Radio16 = GUICtrlCreateRadio("Sell", 79, 210, 37, 25)
    GUICtrlSetState($Radio16, $GUI_DISABLE)
    $CBagPickup = GUICtrlCreateCheckbox("", 116, 195, 17, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_CENTER,$BS_VCENTER))
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    GUICtrlCreateGroup("Charr Salv", 131, 195, 104, 48)
    GUICtrlSetFont(-1, 10, 400, 0, "Arial Rounded MT Bold")
    GUICtrlSetColor(-1, 0xFF0000)
    $Radio17 = GUICtrlCreateRadio("Keep", 142, 210, 49, 25)
    $Radio18 = GUICtrlCreateRadio("Sell", 191, 210, 37, 25)
    $CSalvPickup = GUICtrlCreateCheckbox("", 228, 195, 17, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_CENTER,$BS_VCENTER))
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    GUICtrlCreateGroup("Collectors", 131, 244, 104, 48)
    GUICtrlSetFont(-1, 10, 400, 0, "Arial Rounded MT Bold")
    GUICtrlSetColor(-1, 0x008000)
    $Radio19 = GUICtrlCreateRadio("Keep", 142, 259, 49, 25)
    $Radio20 = GUICtrlCreateRadio("Sell", 191, 259, 37, 25)
    $CollectorPickup = GUICtrlCreateCheckbox("", 228, 244, 17, 17, BitOR($GUI_SS_DEFAULT_CHECKBOX,$BS_CENTER,$BS_VCENTER))
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    $ApplyBtn = GUICtrlCreateButton("Apply", 19, 250, 51, 33)
    GUICtrlSetOnEvent(-1, "LootSettings_Apply")

    $CloseBtn = GUICtrlCreateButton("Close", 72, 250, 51, 33)
    GUICtrlSetOnEvent(-1, "LootSettings_Close")
    GUICtrlCreateGroup("", -99, -99, 1, 1)

    ; Apply loaded settings visually
    If $isPurplePickup Then GUICtrlSetState($PurplePickup, $GUI_CHECKED)
    If $isGoldPickup Then GUICtrlSetState($GoldPickup, $GUI_CHECKED)
    If $isBluePickup Then GUICtrlSetState($BluePickup, $GUI_CHECKED)
    If $isBlackPickup Then GUICtrlSetState($BlackPickup, $GUI_CHECKED)
    If $isWhitePickup Then GUICtrlSetState($WhitePickup, $GUI_CHECKED)
    If $isOtherPickup Then GUICtrlSetState($OtherDyePickup, $GUI_CHECKED)
    If $isPconsPickup Then GUICtrlSetState($PconPickup, $GUI_CHECKED)
    If $isCBagPickup Then GUICtrlSetState($CBagPickup, $GUI_CHECKED)
    If $isCSalvPickup Then GUICtrlSetState($CSalvPickup, $GUI_CHECKED)
    If $isCollPickup Then GUICtrlSetState($CollectorPickup, $GUI_CHECKED)

    If $isPurpleSell Then
        GUICtrlSetState($Radio4, $GUI_CHECKED)
    Else
        GUICtrlSetState($Radio3, $GUI_CHECKED)
    EndIf
    If $isGoldSell Then
        GUICtrlSetState($Radio2, $GUI_CHECKED)
    Else
        GUICtrlSetState($Radio1, $GUI_CHECKED)
    EndIf
    If $isBlueSell Then
        GUICtrlSetState($Radio6, $GUI_CHECKED)
    Else
        GUICtrlSetState($Radio5, $GUI_CHECKED)
    EndIf
    If $isBlackSell Then
        GUICtrlSetState($Radio8, $GUI_CHECKED)
    Else
        GUICtrlSetState($Radio7, $GUI_CHECKED)
    EndIf
    If $isWhiteSell Then
        GUICtrlSetState($Radio12, $GUI_CHECKED)
    Else
        GUICtrlSetState($Radio11, $GUI_CHECKED)
    EndIf
    If $isOtherSell Then
        GUICtrlSetState($Radio10, $GUI_CHECKED)
    Else
        GUICtrlSetState($Radio9, $GUI_CHECKED)
    EndIf
    If $isPconsSell Then
        GUICtrlSetState($Radio14, $GUI_CHECKED)
    Else
        GUICtrlSetState($Radio13, $GUI_CHECKED)
    EndIf
    If $isCBagSell Then
        GUICtrlSetState($Radio16, $GUI_CHECKED)
    Else
        GUICtrlSetState($Radio15, $GUI_CHECKED)
    EndIf
    If $isCSalvSell Then
        GUICtrlSetState($Radio18, $GUI_CHECKED)
    Else
        GUICtrlSetState($Radio17, $GUI_CHECKED)
    EndIf
    If $isCollSell Then
        GUICtrlSetState($Radio20, $GUI_CHECKED)
    Else
        GUICtrlSetState($Radio19, $GUI_CHECKED)
    EndIf
EndFunc

; ============================================================================
; GUI Event Handlers
; ============================================================================
Func ShowLootSettings()
    GUISetState(@SW_SHOW, $LootGui)
    WinActivate($LootGui)
EndFunc

Func LootSettings_Close()
    GUISetState(@SW_HIDE, $LootGui)
EndFunc

Func LootSettings_Apply()
    ; 1. Read Pickups
    $isPurplePickup = (BitAND(GUICtrlRead($PurplePickup), $GUI_CHECKED) == $GUI_CHECKED)
    $isGoldPickup   = (BitAND(GUICtrlRead($GoldPickup), $GUI_CHECKED) == $GUI_CHECKED)
    $isBluePickup   = (BitAND(GUICtrlRead($BluePickup), $GUI_CHECKED) == $GUI_CHECKED)
    $isBlackPickup  = (BitAND(GUICtrlRead($BlackPickup), $GUI_CHECKED) == $GUI_CHECKED)
    $isWhitePickup  = (BitAND(GUICtrlRead($WhitePickup), $GUI_CHECKED) == $GUI_CHECKED)
    $isOtherPickup  = (BitAND(GUICtrlRead($OtherDyePickup), $GUI_CHECKED) == $GUI_CHECKED)
    $isPconsPickup  = (BitAND(GUICtrlRead($PconPickup), $GUI_CHECKED) == $GUI_CHECKED)
    $isCBagPickup   = (BitAND(GUICtrlRead($CBagPickup), $GUI_CHECKED) == $GUI_CHECKED)
    $isCSalvPickup  = (BitAND(GUICtrlRead($CSalvPickup), $GUI_CHECKED) == $GUI_CHECKED)
    $isCollPickup   = (BitAND(GUICtrlRead($CollectorPickup), $GUI_CHECKED) == $GUI_CHECKED)
    
    ; 2. Read Sells
    $isPurpleSell   = (BitAND(GUICtrlRead($Radio4), $GUI_CHECKED) == $GUI_CHECKED)
    $isGoldSell     = (BitAND(GUICtrlRead($Radio2), $GUI_CHECKED) == $GUI_CHECKED)
    $isBlueSell     = (BitAND(GUICtrlRead($Radio6), $GUI_CHECKED) == $GUI_CHECKED)
    $isBlackSell    = (BitAND(GUICtrlRead($Radio8), $GUI_CHECKED) == $GUI_CHECKED)
    $isWhiteSell    = (BitAND(GUICtrlRead($Radio12), $GUI_CHECKED) == $GUI_CHECKED)
    $isOtherSell    = (BitAND(GUICtrlRead($Radio10), $GUI_CHECKED) == $GUI_CHECKED)
    $isPconsSell    = (BitAND(GUICtrlRead($Radio14), $GUI_CHECKED) == $GUI_CHECKED)
    $isCBagSell     = (BitAND(GUICtrlRead($Radio16), $GUI_CHECKED) == $GUI_CHECKED)
    $isCSalvSell    = (BitAND(GUICtrlRead($Radio18), $GUI_CHECKED) == $GUI_CHECKED)
    $isCollSell     = (BitAND(GUICtrlRead($Radio20), $GUI_CHECKED) == $GUI_CHECKED)

    ; 3. Save to INI
    IniWrite($sIniFile, "Pickup", "Purple", $isPurplePickup ? "1" : "0")
    IniWrite($sIniFile, "Sell",   "Purple", $isPurpleSell ? "1" : "0")
    IniWrite($sIniFile, "Pickup", "Gold", $isGoldPickup ? "1" : "0")
    IniWrite($sIniFile, "Sell",   "Gold", $isGoldSell ? "1" : "0")
    IniWrite($sIniFile, "Pickup", "Blue", $isBluePickup ? "1" : "0")
    IniWrite($sIniFile, "Sell",   "Blue", $isBlueSell ? "1" : "0")
    IniWrite($sIniFile, "Pickup", "Black", $isBlackPickup ? "1" : "0")
    IniWrite($sIniFile, "Sell",   "Black", $isBlackSell ? "1" : "0")
    IniWrite($sIniFile, "Pickup", "White", $isWhitePickup ? "1" : "0")
    IniWrite($sIniFile, "Sell",   "White", $isWhiteSell ? "1" : "0")
    IniWrite($sIniFile, "Pickup", "Other", $isOtherPickup ? "1" : "0")
    IniWrite($sIniFile, "Sell",   "Other", $isOtherSell ? "1" : "0")
    IniWrite($sIniFile, "Pickup", "Pcons", $isPconsPickup ? "1" : "0")
    IniWrite($sIniFile, "Sell",   "Pcons", $isPconsSell ? "1" : "0")
    IniWrite($sIniFile, "Pickup", "CBag", $isCBagPickup ? "1" : "0")
    IniWrite($sIniFile, "Sell",   "CBag", $isCBagSell ? "1" : "0")
    IniWrite($sIniFile, "Pickup", "CSalv", $isCSalvPickup ? "1" : "0")
    IniWrite($sIniFile, "Sell",   "CSalv", $isCSalvSell ? "1" : "0")
    IniWrite($sIniFile, "Pickup", "Coll", $isCollPickup ? "1" : "0")
    IniWrite($sIniFile, "Sell",   "Coll", $isCollSell ? "1" : "0")

    If IsDeclared("LogStatus") Then LogStatus("Loot configuration applied and saved.")

    GUISetState(@SW_HIDE, $LootGui)
EndFunc
