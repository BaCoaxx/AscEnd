#include-once
#include <GUIConstantsEx.au3>
#include <TreeViewConstants.au3>
#include <WindowsConstants.au3>

; =========================
; GLOBAL VARIABLES
; =========================
Global $gLootTypes[3] = ["Purple", "Collector", "Mod"]
Global $gTreeItems = ObjCreate("Scripting.Dictionary")
Global $LootRules = ObjCreate("Scripting.Dictionary")
Global $gLootIniFile = @ScriptDir & "\LootConfig.ini"

Global $hLootGUI = 0
Global $tree = 0
Global $btnApply = 0
Global $btnClose = 0

; =========================
; SHOW LOOT SETTINGS WINDOW
; =========================
Func ShowLootSettings()
    ; If window already exists, just show it
    If $hLootGUI <> 0 And WinExists($hLootGUI) Then
        GUISetState(@SW_SHOW, $hLootGUI)
        Return
    EndIf
    
    ; Create the GUI
    $hLootGUI = GUICreate("Loot Configuration", 320, 430)
    GUISetFont(9, 400, 0, "Segoe UI")
    GUISetBkColor(0xF5F5F5) ; Light modern background
    
    GUICtrlCreateLabel("Select items to pick up and their actions:", 15, 15, 290, 20)
    GUICtrlSetFont(-1, 9, 600, 0, "Segoe UI") ; Bold header
    
    $tree = GUICtrlCreateTreeView(15, 40, 290, 330, _
        BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_LINESATROOT, $TVS_SHOWSELALWAYS))
    
    $btnApply = GUICtrlCreateButton("Save & Apply", 125, 385, 95, 30)
    $btnClose = GUICtrlCreateButton("Close", 230, 385, 75, 30)
    
    ; Build the tree
    BuildLootTree()
    
    ; Load saved settings if they exist
    LoadLootSettings()
    
    GUISetState(@SW_SHOW, $hLootGUI)
EndFunc

; =========================
; BUILD TREE
; =========================
Func BuildLootTree()
    For $i = 0 To UBound($gLootTypes) - 1
        Local $type = $gLootTypes[$i]
        
        ; Parent node = Loot type
        Local $parent = GUICtrlCreateTreeViewItem($type, $tree)
        
        ; Children = Actions (radio style)
        Local $keep    = GUICtrlCreateTreeViewItem("Keep", $parent)
        Local $sell    = GUICtrlCreateTreeViewItem("Sell", $parent)
        
        ; Store control IDs
        $gTreeItems($type & "_Parent")  = $parent
        $gTreeItems($type & "_Keep")    = $keep
        $gTreeItems($type & "_Sell")    = $sell
        
        ; Defaults
        GUICtrlSetState($parent, BitOR($GUI_CHECKED, $GUI_EXPAND))   ; pick up and expand by default
        GUICtrlSetState($keep, $GUI_CHECKED)                         ; keep by default
    Next
EndFunc

; =========================
; LOAD SAVED SETTINGS
; =========================
Func LoadLootSettings()
    For $i = 0 To UBound($gLootTypes) - 1
        Local $type = $gLootTypes[$i]
        
        ; Read from INI file, default to True/Keep
        Local $iniPickup = IniRead($gLootIniFile, "LootSettings", $type & "_Pickup", "True")
        Local $iniAction = IniRead($gLootIniFile, "LootSettings", $type & "_Action", "Keep")
        
        ; Update dictionary
        $LootRules($type & "_Pickup") = ($iniPickup = "True")
        $LootRules($type & "_Action") = $iniAction
        
        ; Apply loaded settings to GUI
        If $LootRules.Exists($type & "_Pickup") Then
            Local $pickup = $LootRules($type & "_Pickup")
            Local $action = $LootRules($type & "_Action")
            
            ; Set pickup state
            If $pickup Then
                GUICtrlSetState($gTreeItems($type & "_Parent"), $GUI_CHECKED)
            Else
                GUICtrlSetState($gTreeItems($type & "_Parent"), $GUI_UNCHECKED)
            EndIf
            
            ; Set action
            GUICtrlSetState($gTreeItems($type & "_Keep"), $GUI_UNCHECKED)
            GUICtrlSetState($gTreeItems($type & "_Sell"), $GUI_UNCHECKED)
            
            Switch $action
                Case "Keep"
                    If $pickup Then GUICtrlSetState($gTreeItems($type & "_Keep"), $GUI_CHECKED)
                Case "Sell"
                    If $pickup Then GUICtrlSetState($gTreeItems($type & "_Sell"), $GUI_CHECKED)
            EndSwitch
        EndIf
    Next
EndFunc

; =========================
; HANDLE LOOT SETTINGS EVENTS
; =========================
Func HandleLootSettingsMsg()
    Local $msg = GUIGetMsg()
    
    Switch $msg
        Case $GUI_EVENT_CLOSE, $btnClose
            GUISetState(@SW_HIDE, $hLootGUI)
            
        Case $tree
            ; Determine which node was clicked
            Local $ctrl = @GUI_CtrlId
            For $i = 0 To UBound($gLootTypes) - 1
                HandleType($gLootTypes[$i], $ctrl)
            Next
            
        Case $btnApply
            UpdateLootRules()
            GUISetState(@SW_HIDE, $hLootGUI)
    EndSwitch
EndFunc

; =========================
; HANDLE TREEVIEW LOGIC
; =========================
Func HandleType($type, $clickedCtrl)
    Local $parent  = $gTreeItems($type & "_Parent")
    Local $keepID  = $gTreeItems($type & "_Keep")
    Local $sellID  = $gTreeItems($type & "_Sell")
    
    Local $enabled = GUICtrlRead($parent) = $GUI_CHECKED
    
    ; If type unchecked → clear children
    If Not $enabled Then
        GUICtrlSetState($keepID, $GUI_UNCHECKED)
        GUICtrlSetState($sellID, $GUI_UNCHECKED)
        Return
    EndIf
    
    ; Radio behaviour: only the clicked action stays checked
    Switch $clickedCtrl
        Case $keepID
            GUICtrlSetState($sellID, $GUI_UNCHECKED)
        Case $sellID
            GUICtrlSetState($keepID, $GUI_UNCHECKED)
    EndSwitch
    
    ; Ensure at least one action is selected (default Keep)
    If Not (GUICtrlRead($keepID) = $GUI_CHECKED _
        Or GUICtrlRead($sellID) = $GUI_CHECKED) Then
        GUICtrlSetState($keepID, $GUI_CHECKED)
    EndIf
EndFunc

; =========================
; UPDATE DICTIONARY BASED ON TREEVIEW
; =========================
Func UpdateLootRules()
    LogWarn(" ***Loot Config Updated*** ")
    
    For $i = 0 To UBound($gLootTypes) - 1
        Local $type = $gLootTypes[$i]
        
        Local $enabled = GUICtrlRead($gTreeItems($type & "_Parent")) = $GUI_CHECKED
        Local $keep    = GUICtrlRead($gTreeItems($type & "_Keep")) = $GUI_CHECKED
        Local $sell    = GUICtrlRead($gTreeItems($type & "_Sell")) = $GUI_CHECKED
        
        ; Save pickup state
        $LootRules($type & "_Pickup") = $enabled
        
        ; Save action
        If $sell Then
            $LootRules($type & "_Action") = "Sell"
        Else
            $LootRules($type & "_Action") = "Keep"
        EndIf
        
        ; Write to INI file
        Local $strPickup = "False"
        If $enabled Then $strPickup = "True"
        IniWrite($gLootIniFile, "LootSettings", $type & "_Pickup", $strPickup)
        IniWrite($gLootIniFile, "LootSettings", $type & "_Action", $LootRules($type & "_Action"))
        
        ; Debug output
        LogError($type & _
            " | Pickup=" & $strPickup & _
            " | Action=" & $LootRules($type & "_Action"))
    Next
EndFunc

; =========================
; HELPER FUNCTIONS
; =========================
Func GetLootPickup($type)
    If $LootRules.Exists($type & "_Pickup") Then
        Return $LootRules($type & "_Pickup")
    EndIf
    Return True ; Default to picking up
EndFunc

Func GetLootAction($type)
    If $LootRules.Exists($type & "_Action") Then
        Return $LootRules($type & "_Action")
    EndIf
    Return "Keep" ; Default action
EndFunc

Func GetItemLootType($aItemPtr)
    Local $lRarity = Item_GetItemInfoByPtr($aItemPtr, "Rarity")
    Local $lModelID = Item_GetItemInfoByPtr($aItemPtr, "ModelID")
    Local $lExtraID = Item_GetItemInfoByPtr($aItemPtr, "ExtraID")
    
    ; Check for dyes first (ModelID 146)
    If $lModelID == 146 Then
        If $lExtraID == 10 Then Return "DyeBlack"    ; Black dye
        If $lExtraID == 12 Then Return "DyeWhite"    ; White dye
        Return "DyeCustom"                           ; All other dyes
    EndIf
    
    ; Check rarity
    If $lRarity == $RARITY_Blue Then Return "Blue"
    If $lRarity == $RARITY_Purple Then Return "Purple"
    If $lRarity == $RARITY_Gold Then Return "Gold"
    
    Return ""
EndFunc

Func CanPickUpEx($aItemPtr)
    Local $lModelID = Item_GetItemInfoByPtr($aItemPtr, "ModelID")
    Local $aExtraID = Item_GetItemInfoByPtr($aItemPtr, "ExtraID")
    Local $lRarity = Item_GetItemInfoByPtr($aItemPtr, "Rarity")
    
    ; Handle special cases first
    If (($lModelID == 2511) And (GetGoldCharacter() < 99000)) Then
        Return True	; gold coins
    EndIf
    
    If $lModelID == $ITEM_ID_Lockpicks Then
        Return True  ; Lockpicks
    EndIf
    
    If $lModelID == 22269 Then	; Cupcakes
        Return True
    EndIf
    
    If $lModelID == $GC_I_MODELID_LUNAR_TOKEN Then ; Lunar Tokens
        Return True
    EndIf
    
    If $lModelID == $ExpertSalvKit Then
        Return True
    EndIf
    
    If IsPcon($aItemPtr) Then
        Return True
    EndIf
    
    If IsRareMaterial($aItemPtr) Then
        Return False
    EndIf
    
    If $lModelID == $CharrSalvKit Then
        Return True
    EndIf
    
    If $lModelID == 16453 Then
        Return True
    EndIf
    
    ; If it's in the tree we handle it here
    ; Use loot system for classified items
    Local $itemType = GetItemLootType($aItemPtr)
    If $itemType <> "" Then
        If $LootRules.Exists($itemType) Then
            Return $LootRules($itemType)
        EndIf
        Return False
    EndIf
    
    Return False
EndFunc

Func CanSellEx($aItemPtr)
    Local $lModelID = Item_GetItemInfoByPtr($aItemPtr, "ModelID")
    
    ; Never sell special items
    If $lModelID == $ITEM_ID_Lockpicks Then
        Return False
    EndIf
    
    If $lModelID == 22269 Then
        Return False  ; Never sell cupcakes
    EndIf
    
    If IsPcon($aItemPtr) Then
        Return False
    EndIf
    
    If IsRareMaterial($aItemPtr) Then
        Return False
    EndIf
    
    ; Use loot system for classified items
    Local $itemType = GetItemLootType($aItemPtr)
    If $itemType <> "" Then
        If $LootRules.Exists($itemType & "_Sell") Then
            Return $LootRules($itemType & "_Sell")
        EndIf
        Return False
    EndIf
    
    Return False
EndFunc
