#include-once
#include <GUIConstantsEx.au3>
#include <TreeViewConstants.au3>
#include <WindowsConstants.au3>

; =========================
; GLOBAL VARIABLES
; =========================
Global $gLootTypes[24] = [ _
    "Gold", "Purple", "Blue", _
    "Collectors", "Baked Husks", "Charr Carvings", "Dull Carapaces", "Enchanted Lodestones", "Gargoyle Skulls", "Grawl Necklaces", "Icy Lodestones", "Red Iris", "Skale Fins", "Skeletal Limbs", "Spider Legs", "Unnatural Seeds", "Worn Belts", _
    "Dye", "Black Dye", "White Dye", _
    "Pcons", "Charr Bags", "Charr Salvage Kit" _
]
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
    $hLootGUI = GUICreate("AscEnd", 313, 288, 253, 250, -1, BitOR($WS_EX_TRANSPARENT,$WS_EX_WINDOWEDGE))
    GUISetFont(9, 400, 0, "Tahoma")
    GUISetBkColor(0xF0F0F0) ; Standard grey background
    
    $Group3 = GUICtrlCreateGroup("Loot Configuration", 8, 7, 296, 273, -1, $WS_EX_TRANSPARENT)
    $btnApply = GUICtrlCreateButton("Apply", 64, 239, 89, 28)
    $btnClose = GUICtrlCreateButton("Close", 160, 239, 89, 28)
    
    $tree = GUICtrlCreateTreeView(32, 32, 249, 193, _
        BitOR($GUI_SS_DEFAULT_TREEVIEW, $TVS_CHECKBOXES, $TVS_SINGLEEXPAND, $TVS_FULLROWSELECT, $WS_HSCROLL, $TVS_DISABLEDRAGDROP, $TVS_NOTOOLTIPS), _
        $WS_EX_CLIENTEDGE)
    
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    
    ; Register OnEvent mode handlers if the main GUI uses OnEvent mode
    GUISetOnEvent($GUI_EVENT_CLOSE, "HandleLootSettingsMsg", $hLootGUI)
    GUICtrlSetOnEvent($btnApply, "HandleLootSettingsMsg")
    GUICtrlSetOnEvent($btnClose, "HandleLootSettingsMsg")
    GUICtrlSetOnEvent($tree, "HandleLootSettingsMsg")
    
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
    Local $parent = 0
    Local $collectorsNode = 0
    Local $dyeNode = 0
    
    For $i = 0 To UBound($gLootTypes) - 1
        Local $type = $gLootTypes[$i]
        
        ; Determine the correct parent node
        Switch $type
            Case "Collectors", "Dye", "Gold", "Purple", "Blue", "Pcons", "Charr Bags", "Charr Salvage Kit"
                $parent = GUICtrlCreateTreeViewItem($type, $tree)
                
                ; Save references to specific category parents
                If $type = "Collectors" Then $collectorsNode = $parent
                If $type = "Dye" Then $dyeNode = $parent
                
            Case "Black Dye", "White Dye"
                $parent = GUICtrlCreateTreeViewItem($type, $dyeNode)
                
            Case Else ; E.g. "Baked Husks", "Red Iris", etc.
                $parent = GUICtrlCreateTreeViewItem($type, $collectorsNode)
        EndSwitch
        
        ; Keep/Sell options for items that support actions
        If $type <> "Pcons" And $type <> "Charr Bags" And $type <> "Charr Salvage Kit" Then
            Local $keep = GUICtrlCreateTreeViewItem("Keep", $parent)
            Local $sell = GUICtrlCreateTreeViewItem("Sell", $parent)
            
            $gTreeItems($type & "_Keep") = $keep
            $gTreeItems($type & "_Sell") = $sell
            GUICtrlSetState($keep, $GUI_CHECKED) ; keep by default
        EndIf
        
        ; Store control IDs
        $gTreeItems($type & "_Parent") = $parent
        
        ; Defaults
        GUICtrlSetState($parent, BitOR($GUI_CHECKED, $GUI_EXPAND)) ; pick up and expand by default
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
            If $type <> "Pcons" And $type <> "Charr Bags" And $type <> "Charr Salvage Kit" Then
                GUICtrlSetState($gTreeItems($type & "_Keep"), $GUI_UNCHECKED)
                GUICtrlSetState($gTreeItems($type & "_Sell"), $GUI_UNCHECKED)
                
                Switch $action
                    Case "Keep"
                        If $pickup Then GUICtrlSetState($gTreeItems($type & "_Keep"), $GUI_CHECKED)
                    Case "Sell"
                        If $pickup Then GUICtrlSetState($gTreeItems($type & "_Sell"), $GUI_CHECKED)
                EndSwitch
            EndIf
        EndIf
    Next
EndFunc

; =========================
; HANDLE LOOT SETTINGS EVENTS
; =========================
Func HandleLootSettingsMsg()
    Local $ctrl = @GUI_CtrlId
    
    Switch $ctrl
        Case $GUI_EVENT_CLOSE, $btnClose
            GUISetState(@SW_HIDE, $hLootGUI)
            
        Case $tree
            ; Determine which node was clicked
            For $i = 0 To UBound($gLootTypes) - 1
                HandleType($gLootTypes[$i], GUICtrlRead($tree))
            Next
            
            ; Clear highlighting in treeview
            GUICtrlSetState($tree, $GUI_FOCUS)
            
        Case $btnApply
            UpdateLootRules()
            GUISetState(@SW_HIDE, $hLootGUI)
    EndSwitch
EndFunc

; =========================
; HANDLE TREEVIEW LOGIC
; =========================
Func HandleType($type, $clickedID)
    Local $parent  = $gTreeItems($type & "_Parent")
    Local $state = GUICtrlRead($parent)
    Local $enabled = (BitAND($state, $GUI_CHECKED) = $GUI_CHECKED)
    
    If $type = "Pcons" Or $type = "Charr Bags" Or $type = "Charr Salvage Kit" Then Return
    
    Local $keepID  = $gTreeItems($type & "_Keep")
    Local $sellID  = $gTreeItems($type & "_Sell")
    
    ; If type unchecked → clear children
    If Not $enabled Then
        GUICtrlSetState($keepID, $GUI_UNCHECKED)
        GUICtrlSetState($sellID, $GUI_UNCHECKED)
        Return
    EndIf
    
    ; Radio behaviour: only the clicked action stays checked
    Switch $clickedID
        Case $keepID
            GUICtrlSetState($sellID, $GUI_UNCHECKED)
        Case $sellID
            GUICtrlSetState($keepID, $GUI_UNCHECKED)
    EndSwitch
    
    ; Ensure at least one action is selected (default Keep)
    Local $keepState = GUICtrlRead($keepID)
    Local $sellState = GUICtrlRead($sellID)
    
    If Not ((BitAND($keepState, $GUI_CHECKED) = $GUI_CHECKED) _
        Or (BitAND($sellState, $GUI_CHECKED) = $GUI_CHECKED)) Then
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
        
        ; For TreeView Checkboxes, we must use BitAND with $GUI_CHECKED to properly read the state
        Local $state = GUICtrlRead($gTreeItems($type & "_Parent"))
        Local $enabled = (BitAND($state, $GUI_CHECKED) = $GUI_CHECKED)
        
        ; Save pickup state
        $LootRules($type & "_Pickup") = $enabled
        
        ; Save action
        If $type <> "Pcons" And $type <> "Charr Bags" And $type <> "Charr Salvage Kit" Then
            Local $sellState = GUICtrlRead($gTreeItems($type & "_Sell"))
            Local $sell = (BitAND($sellState, $GUI_CHECKED) = $GUI_CHECKED)
            If $sell Then
                $LootRules($type & "_Action") = "Sell"
            Else
                $LootRules($type & "_Action") = "Keep"
            EndIf
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
