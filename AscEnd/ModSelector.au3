#include-once
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <TabConstants.au3>

; ============================================================================
; Rare-mod configuration
; Columns: Section | INI key | ModStruct hex | Display name | Enabled | CtrlID
; Hex values stay in source. INI stores 1/0 only.
; ============================================================================
Global $g_sRareModsIni = @ScriptDir & "\modconfig.ini"
Global $g_hModSelectorGui = 0
Global $g_idModSelectorApply = 0
Global $g_idModSelectorClose = 0

Global $g_aRareMods[109][6] = [ _
    ["IsRareMod", "Stance10", "0A00A822", "10%", 1, 0], _
    ["IsRareMod", "Stance11", "0B00A822", "11%", 1, 0], _
    ["IsRareMod", "Stance12", "0C00A822", "12%", 1, 0], _
    ["IsRareMod", "Stance13", "0D00A822", "13%", 1, 0], _
    ["IsRareMod", "Stance14", "0E00A822", "14%", 1, 0], _
    ["IsRareMod", "Stance15", "0F00A822", "15%", 1, 0], _
    ["IsRareMod", "HP5010", "0A327822", "10%", 1, 0], _
    ["IsRareMod", "HP5011", "0B327822", "11%", 1, 0], _
    ["IsRareMod", "HP5012", "0C327822", "12%", 1, 0], _
    ["IsRareMod", "HP5013", "0D327822", "13%", 1, 0], _
    ["IsRareMod", "HP5014", "0E327822", "14%", 1, 0], _
    ["IsRareMod", "HP5015", "0F327822", "15%", 1, 0], _
    ["IsRareMod", "Fire15", "0F0A1824", "15", 1, 0], _
    ["IsRareMod", "Fire16", "100A1824", "16", 1, 0], _
    ["IsRareMod", "Fire17", "110A1824", "17", 1, 0], _
    ["IsRareMod", "Fire18", "120A1824", "18", 1, 0], _
    ["IsRareMod", "Fire19", "130A1824", "19", 1, 0], _
    ["IsRareMod", "Fire20", "140A1824", "20", 1, 0], _
    ["IsRareMod", "Death15", "0F051824", "15", 1, 0], _
    ["IsRareMod", "Death16", "10051824", "16", 1, 0], _
    ["IsRareMod", "Death17", "11051824", "17", 1, 0], _
    ["IsRareMod", "Death18", "12051824", "18", 1, 0], _
    ["IsRareMod", "Death19", "13051824", "19", 1, 0], _
    ["IsRareMod", "Death20", "14051824", "20", 1, 0], _
    ["IsRareMod", "Dom15", "0F021824", "15", 1, 0], _
    ["IsRareMod", "Dom16", "10021824", "16", 1, 0], _
    ["IsRareMod", "Dom17", "11021824", "17", 1, 0], _
    ["IsRareMod", "Dom18", "12021824", "18", 1, 0], _
    ["IsRareMod", "Dom19", "13021824", "19", 1, 0], _
    ["IsRareMod", "Dom20", "14021824", "20", 1, 0], _
    ["IsRareMod", "SCharr", "00018080", "vs Charr", 1, 0], _
    ["IsRareRunePre", "MinorVigor", "C202E827", "Minor Vigor", 1, 0], _
    ["IsRareRunePre", "MajorVigor", "C202E927", "Major Vigor", 1, 0], _
    ["IsRareRunePre", "SupVigor", "C202EA27", "Superior Vigor", 1, 0], _
    ["IsRareRunePre", "MinorStrength", "0111E821", "Minor Strength", 1, 0], _
    ["IsRareRunePre", "MinorTactics", "0115E821", "Minor Tactics", 1, 0], _
    ["IsRareRunePre", "MinorAxeMastery", "0112E821", "Minor Axe Mastery", 1, 0], _
    ["IsRareRunePre", "MinorHammerMastery", "0113E821", "Minor Hammer Mastery", 1, 0], _
    ["IsRareRunePre", "MinorSwordmanship", "0114E821", "Minor Swordmanship", 1, 0], _
    ["IsRareRunePre", "MinorAbsorption", "FC000824", "Minor Absorption", 1, 0], _
    ["IsRareRunePre", "MinorExpertise", "0117E821", "Minor Expertise", 1, 0], _
    ["IsRareRunePre", "MinorMarksmanship", "0119E821", "Minor Marksmanship", 1, 0], _
    ["IsRareRunePre", "MinorBeastMastery", "0116E821", "Minor Beast Mastery", 1, 0], _
    ["IsRareRunePre", "MinorWildernessSurvival", "0118E821", "Minor Wilderness Survival", 1, 0], _
    ["IsRareRunePre", "MinorDivineFavour", "0110E821", "Minor Divine Favour", 1, 0], _
    ["IsRareRunePre", "MinorHealing", "010DE821", "Minor Healing", 1, 0], _
    ["IsRareRunePre", "MinorProtection", "010FE821", "Minor Protection", 1, 0], _
    ["IsRareRunePre", "MinorSmitingPrayers", "010EE821", "Minor Smiting Prayers", 1, 0], _
    ["IsRareRunePre", "MinorSoulReaping", "0106E821", "Minor Soul Reaping", 1, 0], _
    ["IsRareRunePre", "MinorBloodMagic", "0104E821", "Minor Blood Magic", 1, 0], _
    ["IsRareRunePre", "MinorDeathMagic", "0105E821", "Minor Death Magic", 1, 0], _
    ["IsRareRunePre", "MinorCurses", "0107E821", "Minor Curses", 1, 0], _
    ["IsRareRunePre", "MinorFastcast", "0100E821", "Minor Fastcast", 1, 0], _
    ["IsRareRunePre", "MinorInspirationMagic", "0103E821", "Minor Inspiration Magic", 1, 0], _
    ["IsRareRunePre", "MinorIllusionMagic", "0101E821", "Minor Illusion Magic", 1, 0], _
    ["IsRareRunePre", "MinorDominationMagic", "0102E821", "Minor Domination Magic", 1, 0], _
    ["IsRareRunePre", "MinorEnergyStorage", "010CE821", "Minor Energy Storage", 1, 0], _
    ["IsRareRunePre", "MinorAirMagic", "0108E821", "Minor Air Magic", 1, 0], _
    ["IsRareRunePre", "MinorEarthMagic", "0109E821", "Minor Earth Magic", 1, 0], _
    ["IsRareRunePre", "MinorFireMagic", "010AE821", "Minor Fire Magic", 1, 0], _
    ["IsRareRunePre", "MinorWaterMagic", "010BE821", "Minor Water Magic", 1, 0], _
    ["IsRareRunePre", "Vitae", "12020824", "Vitae", 1, 0], _
    ["IsRareRunePre", "Attunement", "11020824", "Attunement", 1, 0], _
    ["IsRareRunePre", "Recovery", "13020824", "Recovery", 1, 0], _
    ["IsRareRunePre", "Restoration", "14020824", "Restoration", 1, 0], _
    ["IsRareRunePre", "Clarity", "15020824", "Clarity", 1, 0], _
    ["IsRareRunePre", "Purity", "16020824", "Purity", 1, 0], _
    ["IsRareInsigniaPre", "Sentinel", "FB010824", "Sentinel", 1, 0], _
    ["IsRareInsigniaPre", "Tormentor", "EC010824", "Tormentor", 1, 0], _
    ["IsRareInsigniaPre", "Prodigy", "E3010824", "Prodigy", 1, 0], _
    ["IsRareInsigniaPre", "Blessed", "E9010824", "Blessed", 1, 0], _
    ["IsRareInsigniaPre", "Radiant", "E5010824", "Radiant", 1, 0], _
    ["IsRareInsigniaPre", "Survivor", "E6010824", "Survivor", 1, 0], _
    ["IsRareInsigniaPre", "Stalwart", "E7010824", "Stalwart", 1, 0], _
    ["IsRareInsigniaPre", "Brawler", "E8010824", "Brawler", 1, 0], _
    ["IsRareInsigniaPre", "Herald", "EA010824", "Herald", 1, 0], _
    ["IsRareInsigniaPre", "Sentry", "EB010824", "Sentry", 1, 0], _
    ["IsRareInsigniaPre", "Frostbound", "FC010824", "Frostbound", 1, 0], _
    ["IsRareInsigniaPre", "Earthbound", "FD010824", "Earthbound", 1, 0], _
    ["IsRareInsigniaPre", "Pyrebound", "FE010824", "Pyrebound", 1, 0], _
    ["IsRareInsigniaPre", "Stormbound", "FF010824", "Stormbound", 1, 0], _
    ["IsRareInsigniaPre", "Beastmaster", "00020824", "Beastmaster", 1, 0], _
    ["IsRareInsigniaPre", "Scout", "01020824", "Scout", 1, 0], _
    ["IsRareInsigniaPre", "Knight", "F9010824", "Knight", 1, 0], _
    ["IsRareInsigniaPre", "Dreadnought", "FA010824", "Dreadnought", 1, 0], _
    ["IsRareInsigniaPre", "Lieutenant", "08020824", "Lieutenant", 1, 0], _
    ["IsRareInsigniaPre", "Stonefist", "09020824", "Stonefist", 1, 0], _
    ["IsRareInsigniaPre", "Wanderer", "F6010824", "Wanderer", 1, 0], _
    ["IsRareInsigniaPre", "Disciple", "F7010824", "Disciple", 1, 0], _
    ["IsRareInsigniaPre", "Anchorite", "F8010824", "Anchorite", 1, 0], _
    ["IsRareInsigniaPre", "Prismatic", "F1010824", "Prismatic", 1, 0], _
    ["IsRareInsigniaPre", "Hydromancer", "F2010824", "Hydromancer", 1, 0], _
    ["IsRareInsigniaPre", "Geomancer", "F3010824", "Geomancer", 1, 0], _
    ["IsRareInsigniaPre", "Pyromancer", "F4010824", "Pyromancer", 1, 0], _
    ["IsRareInsigniaPre", "Aeromancer", "F5010824", "Aeromancer", 1, 0], _
    ["IsRareInsigniaPre", "Undertaker", "ED010824", "Undertaker", 1, 0], _
    ["IsRareInsigniaPre", "Bonelace", "EE010824", "Bonelace", 1, 0], _
    ["IsRareInsigniaPre", "MinionMaster", "EF010824", "Minion Master", 1, 0], _
    ["IsRareInsigniaPre", "Blighter", "F0010824", "Blighter", 1, 0], _
    ["IsRareInsigniaPre", "Bloodstained", "0A020824", "Bloodstained", 1, 0], _
    ["IsRareInsigniaPre", "Artificer", "E2010824", "Artificer", 1, 0], _
    ["IsRareInsigniaPre", "Virtuoso", "E4010824", "Virtuoso", 1, 0] _
]

; ============================================================================
; INI load / save
; ============================================================================
Func RareMods_LoadFromIni()
    Local $i
    For $i = 0 To UBound($g_aRareMods) - 1
        If IniRead($g_sRareModsIni, $g_aRareMods[$i][0], $g_aRareMods[$i][1], "1") = "1" Then
            $g_aRareMods[$i][4] = 1
        Else
            $g_aRareMods[$i][4] = 0
        EndIf
    Next
EndFunc

Func RareMods_SaveToIni()
    Local $i
    For $i = 0 To UBound($g_aRareMods) - 1
        IniWrite($g_sRareModsIni, $g_aRareMods[$i][0], $g_aRareMods[$i][1], $g_aRareMods[$i][4] ? "1" : "0")
    Next
EndFunc

Func IsConfiguredRare($sSection, $sName, $sModStruct, $sModCode)
    Local $i
    For $i = 0 To UBound($g_aRareMods) - 1
        If $g_aRareMods[$i][0] = $sSection And $g_aRareMods[$i][1] = $sName Then
            If $g_aRareMods[$i][4] <> 1 Then Return False
            Return StringInStr($sModStruct, $sModCode, 0, 1) > 0
        EndIf
    Next
    If IniRead($g_sRareModsIni, $sSection, $sName, "1") <> "1" Then Return False
    Return StringInStr($sModStruct, $sModCode, 0, 1) > 0
EndFunc

Func RareMods_AnyEnabledInSection($sSection, $sModStruct)
    Local $i
    For $i = 0 To UBound($g_aRareMods) - 1
        If $g_aRareMods[$i][0] = $sSection Then
            If IsConfiguredRare($sSection, $g_aRareMods[$i][1], $sModStruct, $g_aRareMods[$i][2]) Then Return True
        EndIf
    Next
    Return False
EndFunc

; ============================================================================
; Mod Selector GUI helpers
; ============================================================================
Func _ModSelector_FindIndex($sSection, $sKey)
    Local $i
    For $i = 0 To UBound($g_aRareMods) - 1
        If $g_aRareMods[$i][0] = $sSection And $g_aRareMods[$i][1] = $sKey Then Return $i
    Next
    Return -1
EndFunc

Func _ModSelector_CreateCheckbox($iIndex, $iX, $iY, $iW = 150)
    If $iIndex < 0 Then Return
    $g_aRareMods[$iIndex][5] = GUICtrlCreateCheckbox($g_aRareMods[$iIndex][3], $iX, $iY, $iW, 18)
EndFunc

Func _ModSelector_CreateGroupCheckboxes($sSection, $sGroupTitle, $iX, $iY, $iW, $aKeys)
    Local $iCount = UBound($aKeys)
    Local $iH = 24 + ($iCount * 20)
    GUICtrlCreateGroup($sGroupTitle, $iX, $iY, $iW, $iH)
    Local $i
    For $i = 0 To $iCount - 1
        Local $idx = _ModSelector_FindIndex($sSection, $aKeys[$i])
        _ModSelector_CreateCheckbox($idx, $iX + 8, $iY + 18 + ($i * 20), $iW - 16)
    Next
    GUICtrlCreateGroup("", -99, -99, 1, 1)
EndFunc

Func _ModSelector_CreateModTab()
    Local $aStance[6] = ["Stance10", "Stance11", "Stance12", "Stance13", "Stance14", "Stance15"]
    Local $aHP[6] = ["HP5010", "HP5011", "HP5012", "HP5013", "HP5014", "HP5015"]
    Local $aFire[6] = ["Fire15", "Fire16", "Fire17", "Fire18", "Fire19", "Fire20"]
    Local $aDeath[6] = ["Death15", "Death16", "Death17", "Death18", "Death19", "Death20"]
    Local $aDom[6] = ["Dom15", "Dom16", "Dom17", "Dom18", "Dom19", "Dom20"]
    Local $aOther[1] = ["SCharr"]

    _ModSelector_CreateGroupCheckboxes("IsRareMod", "Stance %", 16, 36, 168, $aStance)
    _ModSelector_CreateGroupCheckboxes("IsRareMod", "HP > 50%", 192, 36, 168, $aHP)
    _ModSelector_CreateGroupCheckboxes("IsRareMod", "Fire +1", 368, 36, 168, $aFire)
    _ModSelector_CreateGroupCheckboxes("IsRareMod", "Death +1", 16, 188, 168, $aDeath)
    _ModSelector_CreateGroupCheckboxes("IsRareMod", "Domination +1", 192, 188, 168, $aDom)
    _ModSelector_CreateGroupCheckboxes("IsRareMod", "Other", 368, 188, 168, $aOther)
EndFunc

Func _ModSelector_CreateRuneTab()
    Local $iCol = 0
    Local $iRow = 0
    Local $iMaxRows = 13
    Local $i
    For $i = 0 To UBound($g_aRareMods) - 1
        If $g_aRareMods[$i][0] <> "IsRareRunePre" Then ContinueLoop
        Local $iX = 16 + ($iCol * 174)
        Local $iY = 36 + ($iRow * 22)
        $g_aRareMods[$i][5] = GUICtrlCreateCheckbox($g_aRareMods[$i][3], $iX, $iY, 168, 18)
        $iRow += 1
        If $iRow >= $iMaxRows Then
            $iRow = 0
            $iCol += 1
        EndIf
    Next
EndFunc

Func _ModSelector_CreateInsigniaTab()
    Local $iCol = 0
    Local $iRow = 0
    Local $iMaxRows = 13
    Local $i
    For $i = 0 To UBound($g_aRareMods) - 1
        If $g_aRareMods[$i][0] <> "IsRareInsigniaPre" Then ContinueLoop
        Local $iX = 16 + ($iCol * 174)
        Local $iY = 36 + ($iRow * 22)
        $g_aRareMods[$i][5] = GUICtrlCreateCheckbox($g_aRareMods[$i][3], $iX, $iY, 168, 18)
        $iRow += 1
        If $iRow >= $iMaxRows Then
            $iRow = 0
            $iCol += 1
        EndIf
    Next
EndFunc

Func _ModSelector_ApplyCheckboxStates()
    Local $i
    For $i = 0 To UBound($g_aRareMods) - 1
        If $g_aRareMods[$i][5] = 0 Then ContinueLoop
        If $g_aRareMods[$i][4] = 1 Then
            GUICtrlSetState($g_aRareMods[$i][5], $GUI_CHECKED)
        Else
            GUICtrlSetState($g_aRareMods[$i][5], $GUI_UNCHECKED)
        EndIf
    Next
EndFunc

; ============================================================================
; Mod Selector GUI
; ============================================================================
Func InitModSelectorGUI()
    $g_hModSelectorGui = GUICreate("AscEnd - Mods", 560, 400, -1, -1, -1, BitOR($WS_EX_TOPMOST, $WS_EX_WINDOWEDGE))
    GUISetOnEvent($GUI_EVENT_CLOSE, "ModSelector_Close", $g_hModSelectorGui)

    GUICtrlCreateTab(8, 8, 544, 384)
    GUICtrlCreateTabItem("Mod")
    _ModSelector_CreateModTab()
    GUICtrlCreateTabItem("Rune")
    _ModSelector_CreateRuneTab()
    GUICtrlCreateTabItem("Insignia")
    _ModSelector_CreateInsigniaTab()
    GUICtrlCreateTabItem("")

    $g_idModSelectorApply = GUICtrlCreateButton("Apply", 16, 351, 73, 33)
    GUICtrlSetOnEvent($g_idModSelectorApply, "ModSelector_Apply")
    $g_idModSelectorClose = GUICtrlCreateButton("Close", 96, 351, 73, 33)
    GUICtrlSetOnEvent($g_idModSelectorClose, "ModSelector_Close")

    _ModSelector_ApplyCheckboxStates()
EndFunc

Func ShowModSelector()
    RareMods_LoadFromIni()
    _ModSelector_ApplyCheckboxStates()
    GUISetState(@SW_SHOW, $g_hModSelectorGui)
    WinActivate($g_hModSelectorGui)
EndFunc

Func ModSelector_Close()
    GUISetState(@SW_HIDE, $g_hModSelectorGui)
EndFunc

Func ModSelector_Apply()
    Local $i
    For $i = 0 To UBound($g_aRareMods) - 1
        If $g_aRareMods[$i][5] = 0 Then ContinueLoop
        If BitAND(GUICtrlRead($g_aRareMods[$i][5]), $GUI_CHECKED) = $GUI_CHECKED Then
            $g_aRareMods[$i][4] = 1
        Else
            $g_aRareMods[$i][4] = 0
        EndIf
    Next
    RareMods_SaveToIni()
    LogStatus("Mods configuration applied and saved.")
    GUISetState(@SW_HIDE, $g_hModSelectorGui)
EndFunc

RareMods_LoadFromIni()
