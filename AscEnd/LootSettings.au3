#include-once
#include <GUIConstantsEx.au3>
#include <TreeViewConstants.au3>
#include <WindowsConstants.au3>

; =========================
; GLOBAL VARIABLES
; =========================
Global $gLootTypes[23] = [ _
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
; Creates and displays the Loot Configuration GUI.
; Initializes the TreeView, buttons, and loads saved settings.
; =========================
Func ShowLootSettings()
    ; If window already exists, just show it
    If $hLootGUI <> 0 And WinExists($hLootGUI) Then
        GUISetState(@SW_SHOW, $hLootGUI)
        Return
    EndIf
    
    ; Create the GUI window with a standard style and ensure it stays on top
    $hLootGUI = GUICreate("AscEnd", 313, 288, 253, 250, -1, BitOR($WS_EX_TRANSPARENT, $WS_EX_WINDOWEDGE, $WS_EX_TOPMOST))
    GUISetFont(9, 400, 0, "Tahoma")
    GUISetBkColor(0xF0F0F0)
    
    ; Layout group and action buttons
    $Group3 = GUICtrlCreateGroup("Loot Configuration", 8, 7, 296, 273, -1, $WS_EX_TRANSPARENT)
    $btnApply = GUICtrlCreateButton("Apply", 64, 239, 89, 28)
    $btnClose = GUICtrlCreateButton("Close", 160, 239, 89, 28)
    
    ; Create the TreeView with checkboxes and prevent drag-drop or tooltips
    $tree = GUICtrlCreateTreeView(32, 32, 249, 193, _
        BitOR($GUI_SS_DEFAULT_TREEVIEW, $TVS_CHECKBOXES, $TVS_SINGLEEXPAND, $TVS_FULLROWSELECT, $WS_HSCROLL, $TVS_DISABLEDRAGDROP, $TVS_NOTOOLTIPS), _
        $WS_EX_CLIENTEDGE)
    
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    
    ; Register OnEvent mode handlers to trigger GUI interactions
    GUISetOnEvent($GUI_EVENT_CLOSE, "HandleLootSettingsMsg", $hLootGUI)
    GUICtrlSetOnEvent($btnApply, "HandleLootSettingsMsg")
    GUICtrlSetOnEvent($btnClose, "HandleLootSettingsMsg")
    GUICtrlSetOnEvent($tree, "HandleLootSettingsMsg")
    
    ; Build the hierarchical item tree
    BuildLootTree()
    
    ; Load user's previously saved settings from the INI file
    LoadLootSettings()
    
    ; Display the GUI
    GUISetState(@SW_SHOW, $hLootGUI)
EndFunc

; =========================
; BUILD TREE
; Constructs the nested items and categories inside the TreeView.
; Assigns Keep/Sell actions to appropriate item types.
; =========================
Func BuildLootTree()
    Local $parent = 0
    Local $collectorsNode = 0
    Local $dyeNode = 0
    
    For $i = 0 To UBound($gLootTypes) - 1
        Local $type = $gLootTypes[$i]
        
        ; Determine the correct parent node for nesting
        Switch $type
            Case "Collectors", "Dye", "Gold", "Purple", "Blue", "Pcons", "Charr Bags", "Charr Salvage Kit"
                $parent = GUICtrlCreateTreeViewItem($type, $tree)
                
                ; Save references to specific category parents for later nesting
                If $type = "Collectors" Then $collectorsNode = $parent
                If $type = "Dye" Then $dyeNode = $parent
                
            Case "Black Dye", "White Dye"
                $parent = GUICtrlCreateTreeViewItem($type, $dyeNode)
                
            Case Else ; e.g., "Baked Husks", "Red Iris" (which fall under "Collectors")
                $parent = GUICtrlCreateTreeViewItem($type, $collectorsNode)
        EndSwitch
        
        ; Create Keep/Sell radio-like options for items that support actions
        ; (Pcons, Bags, and Kits are pick-up only, they do not have Keep/Sell states)
        If $type <> "Pcons" And $type <> "Charr Bags" And $type <> "Charr Salvage Kit" Then
            Local $keep = GUICtrlCreateTreeViewItem("Keep", $parent)
            Local $sell = GUICtrlCreateTreeViewItem("Sell", $parent)
            
            $gTreeItems($type & "_Keep") = $keep
            $gTreeItems($type & "_Sell") = $sell
            GUICtrlSetState($keep, $GUI_CHECKED) ; Set 'Keep' as default action
        EndIf
        
        ; Store the parent control ID in the dictionary for quick lookups
        $gTreeItems($type & "_Parent") = $parent
        
        ; Set the node to be checked (pickup) by default, and ensure it's collapsed
        GUICtrlSetState($parent, $GUI_CHECKED)
    Next
EndFunc

; =========================
; LOAD SAVED SETTINGS
; Reads the LootConfig.ini file to restore the user's previously saved options.
; Applies the values directly to the GUI controls and the internal dictionary.
; =========================
Func LoadLootSettings()
    For $i = 0 To UBound($gLootTypes) - 1
        Local $type = $gLootTypes[$i]
        
        ; Read values from INI file, default to True (pickup) and Keep (action) if missing
        Local $iniPickup = IniRead($gLootIniFile, "LootSettings", $type & "_Pickup", "True")
        Local $iniAction = IniRead($gLootIniFile, "LootSettings", $type & "_Action", "Keep")
        
        ; Update the internal settings dictionary
        $LootRules($type & "_Pickup") = ($iniPickup = "True")
        $LootRules($type & "_Action") = $iniAction
        
        ; Verify the setting exists before applying to GUI
        If $LootRules.Exists($type & "_Pickup") Then
            Local $pickup = $LootRules($type & "_Pickup")
            Local $action = $LootRules($type & "_Action")
            
            ; Check or uncheck the parent node based on the pickup setting
            If $pickup Then
                GUICtrlSetState($gTreeItems($type & "_Parent"), $GUI_CHECKED)
            Else
                GUICtrlSetState($gTreeItems($type & "_Parent"), $GUI_UNCHECKED)
            EndIf
            
            ; Only apply Keep/Sell to items that support actions
            If $type <> "Pcons" And $type <> "Charr Bags" And $type <> "Charr Salvage Kit" Then
                ; Uncheck both before re-applying the saved one
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
; Listens for interactions in the Loot Settings GUI and reacts accordingly.
; E.g., Window closing, clicking Apply, or toggling items in the TreeView.
; =========================
Func HandleLootSettingsMsg()
    Local $ctrl = @GUI_CtrlId
    
    Switch $ctrl
        Case $GUI_EVENT_CLOSE, $btnClose
            GUISetState(@SW_HIDE, $hLootGUI)
            
        Case $tree
            ; Determine which node was clicked and handle radio toggle behavior
            For $i = 0 To UBound($gLootTypes) - 1
                HandleType($gLootTypes[$i], GUICtrlRead($tree))
            Next
            
            ; Clear focus highlighting so the treeview item doesn't stay blue
            GUICtrlSetState($tree, $GUI_FOCUS)
            
        Case $btnApply
            UpdateLootRules()
            GUISetState(@SW_HIDE, $hLootGUI)
    EndSwitch
EndFunc

; =========================
; HANDLE TREEVIEW LOGIC
; Enforces radio-button-like mutual exclusivity for "Keep" and "Sell" sub-items.
; Also unchecks child items if the parent (pickup) gets unchecked.
; =========================
Func HandleType($type, $clickedID)
    Local $parent  = $gTreeItems($type & "_Parent")
    Local $state = GUICtrlRead($parent)
    Local $enabled = (BitAND($state, $GUI_CHECKED) = $GUI_CHECKED)
    
    ; Skip logic for categories without Keep/Sell options
    If $type = "Pcons" Or $type = "Charr Bags" Or $type = "Charr Salvage Kit" Then Return
    
    Local $keepID  = $gTreeItems($type & "_Keep")
    Local $sellID  = $gTreeItems($type & "_Sell")
    
    ; If the parent type is unchecked, visually uncheck its children
    If Not $enabled Then
        GUICtrlSetState($keepID, $GUI_UNCHECKED)
        GUICtrlSetState($sellID, $GUI_UNCHECKED)
        Return
    EndIf
    
    ; Radio behavior: If 'Keep' is clicked, uncheck 'Sell' (and vice versa)
    Switch $clickedID
        Case $keepID
            GUICtrlSetState($sellID, $GUI_UNCHECKED)
        Case $sellID
            GUICtrlSetState($keepID, $GUI_UNCHECKED)
    EndSwitch
    
    ; Ensure at least one action is selected if the parent is checked.
    ; Defaults to 'Keep' if nothing is currently selected.
    Local $keepState = GUICtrlRead($keepID)
    Local $sellState = GUICtrlRead($sellID)
    
    If Not ((BitAND($keepState, $GUI_CHECKED) = $GUI_CHECKED) _
        Or (BitAND($sellState, $GUI_CHECKED) = $GUI_CHECKED)) Then
        GUICtrlSetState($keepID, $GUI_CHECKED)
    EndIf
EndFunc

; =========================
; UPDATE DICTIONARY BASED ON TREEVIEW
; Reads the active selections in the TreeView and translates them into the script's
; internal Dictionary ($LootRules). Also writes these updated rules to LootConfig.ini.
; =========================
Func UpdateLootRules()
    LogWarn(" ***Loot Config Updated*** ")
    
    For $i = 0 To UBound($gLootTypes) - 1
        Local $type = $gLootTypes[$i]
        
        ; For TreeView Checkboxes, BitAND with $GUI_CHECKED must be used to properly extract the state
        Local $state = GUICtrlRead($gTreeItems($type & "_Parent"))
        Local $enabled = (BitAND($state, $GUI_CHECKED) = $GUI_CHECKED)
        
        ; Save pickup preference directly to dictionary
        $LootRules($type & "_Pickup") = $enabled
        
        ; Determine the action (Keep or Sell)
        If $type <> "Pcons" And $type <> "Charr Bags" And $type <> "Charr Salvage Kit" Then
            Local $sellState = GUICtrlRead($gTreeItems($type & "_Sell"))
            Local $sell = (BitAND($sellState, $GUI_CHECKED) = $GUI_CHECKED)
            
            If $sell Then
                $LootRules($type & "_Action") = "Sell"
            Else
                $LootRules($type & "_Action") = "Keep"
            EndIf
        Else
            $LootRules($type & "_Action") = "Keep" ; Default action for non-actionable items
        EndIf
        
        ; Prepare string versions for INI file writing
        Local $strPickup = "False"
        If $enabled Then $strPickup = "True"
        
        ; Persist to configuration file
        IniWrite($gLootIniFile, "LootSettings", $type & "_Pickup", $strPickup)
        IniWrite($gLootIniFile, "LootSettings", $type & "_Action", $LootRules($type & "_Action"))
        
        ; Output changes to bot console for verification
        LogStatus($type & " - Pickup = " & $strPickup & " - Action = " & $LootRules($type & "_Action"))
    Next
EndFunc

; =========================
; HELPER FUNCTIONS
; These functions bridge the gap between the LootSettings GUI logic and the
; bot's core item evaluation scripts. They query the $LootRules dictionary.
; =========================

; Retrieves whether a specific loot type should be picked up (True) or ignored (False).
Func GetLootPickup($type)
    If $LootRules.Exists($type & "_Pickup") Then
        Return $LootRules($type & "_Pickup")
    EndIf
    Return True ; Default to picking up if not defined
EndFunc

; Retrieves whether a specific loot type should be "Keep" or "Sell".
Func GetLootAction($type)
    If $LootRules.Exists($type & "_Action") Then
        Return $LootRules($type & "_Action")
    EndIf
    Return "Keep" ; Default action if not defined
EndFunc

; Evaluates a given item pointer and categorizes it into one of the known $gLootTypes.
Func GetItemLootType($aItemPtr)
    Local $lRarity = Item_GetItemInfoByPtr($aItemPtr, "Rarity")
    Local $lModelID = Item_GetItemInfoByPtr($aItemPtr, "ModelID")
    Local $lExtraID = Item_GetItemInfoByPtr($aItemPtr, "ExtraID")
    
    ; Check for dyes first (ModelID 146)
    If $lModelID == 146 Then
        If $lExtraID == 10 Then Return "Black Dye"    ; Black dye
        If $lExtraID == 12 Then Return "White Dye"    ; White dye
        Return "Dye"                                  ; All other dyes
    EndIf
    
    ; Check item rarity (Blue, Purple, Gold)
    If $lRarity == $RARITY_Blue Then Return "Blue"
    If $lRarity == $RARITY_Purple Then Return "Purple"
    If $lRarity == $RARITY_Gold Then Return "Gold"
    
    ; Check if the item is a Pcon (Party consumable like Cupcakes, Apples, etc.)
    If IsPcon($aItemPtr) Then Return "Pcons"

    ; Check specific Pre-Searing Collector items based on their Model IDs
    If IsPreCollectable($aItemPtr) Then
        If $lModelID == 422 Then Return "Spider Legs"
        If $lModelID == 423 Then Return "Charr Carvings"
        If $lModelID == 424 Then Return "Icy Lodestones"
        If $lModelID == 425 Then Return "Dull Carapaces"
        If $lModelID == 426 Then Return "Gargoyle Skulls"
        If $lModelID == 427 Then Return "Worn Belts"
        If $lModelID == 428 Then Return "Unnatural Seeds"
        If $lModelID == 429 Then Return "Skale Fins"
        If $lModelID == 430 Then Return "Skeletal Limbs"
        If $lModelID == 431 Then Return "Enchanted Lodestones"
        If $lModelID == 432 Then Return "Grawl Necklaces"
        If $lModelID == 433 Then Return "Baked Husks"
        If $lModelID == 2994 Then Return "Red Iris"
        Return "Collectors"
    EndIf

    ; Check specific Charr-related items
    If $lModelID == 16453 Then Return "Charr Bags"
    If $lModelID == 18721 Then Return "Charr Salvage Kit"
        
    Return "" ; Item doesn't fall into any configurable loot category
EndFunc

; The primary interface for the bot's Looting loop. Returns True if the item
; meets the criteria to be picked up off the ground.
Func CanPickUpEx($aItemPtr)
    Local $lModelID = Item_GetItemInfoByPtr($aItemPtr, "ModelID")
    
    ; Handle special cases that bypass user configuration (Always pickup)
    If (($lModelID == 2511) And (GetGoldCharacter() < 99000)) Then Return True ; Gold coins (up to 99k)
    If $lModelID == $ITEM_ID_Lockpicks Then Return True
    If $lModelID == 22269 Then Return True ; Cupcakes
    If $lModelID == $GC_I_MODELID_LUNAR_TOKEN Then Return True
    If $lModelID == $ExpertSalvKit Then Return True
    If IsRareMaterial($aItemPtr) Then Return False ; Never pickup rare mats by default
    If $lModelID == $CharrSalvKit Then Return True
    If $lModelID == 16453 Then Return True ; Charr Bag
    
    ; If not a special case, determine its Loot Type and query the user's config
    Local $itemType = GetItemLootType($aItemPtr)
    If $itemType <> "" Then
        Return GetLootPickup($itemType)
    EndIf
    
    Return False ; Default to ignoring unknown/unconfigured items
EndFunc

; The primary interface for the bot's Merchant loop. Returns True if the item
; meets the criteria to be sold to a merchant.
Func CanSellEx($aItemPtr)
    ; Determine the item's Loot Type and check if the user set it to "Sell"
    Local $itemType = GetItemLootType($aItemPtr)
    If $itemType <> "" Then
        Return (GetLootAction($itemType) == "Sell")
    EndIf
    
    Return False ; Default to keeping unknown/unconfigured items
EndFunc
