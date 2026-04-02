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
    $hLootGUI = GUICreate("Loot Config", 320, 420)
    
    $tree = GUICtrlCreateTreeView(10, 10, 280, 320, _
        BitOR($TVS_CHECKBOXES, $TVS_HASBUTTONS, $TVS_LINESATROOT))
    
    $btnApply = GUICtrlCreateButton("Apply", 10, 350, 80, 30)
    $btnClose = GUICtrlCreateButton("Close", 100, 350, 80, 30)
    
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
        Local $salvage = GUICtrlCreateTreeViewItem("Salvage", $parent)
        
        ; Store control IDs
        $gTreeItems($type & "_Parent")  = $parent
        $gTreeItems($type & "_Keep")    = $keep
        $gTreeItems($type & "_Sell")    = $sell
        $gTreeItems($type & "_Salvage") = $salvage
        
        ; Defaults
        GUICtrlSetState($parent, $GUI_CHECKED)   ; pick up by default
        GUICtrlSetState($keep, $GUI_CHECKED)     ; keep by default
    Next
EndFunc

; =========================
; LOAD SAVED SETTINGS
; =========================
Func LoadLootSettings()
    For $i = 0 To UBound($gLootTypes) - 1
        Local $type = $gLootTypes[$i]
        
        ; Check if we have saved settings
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
            GUICtrlSetState($gTreeItems($type & "_Salvage"), $GUI_UNCHECKED)
            
            Switch $action
                Case "Keep"
                    If $pickup Then GUICtrlSetState($gTreeItems($type & "_Keep"), $GUI_CHECKED)
                Case "Sell"
                    If $pickup Then GUICtrlSetState($gTreeItems($type & "_Sell"), $GUI_CHECKED)
                Case "Salvage"
                    If $pickup Then GUICtrlSetState($gTreeItems($type & "_Salvage"), $GUI_CHECKED)
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
    Local $salvID  = $gTreeItems($type & "_Salvage")
    
    Local $enabled = GUICtrlRead($parent) = $GUI_CHECKED
    
    ; If type unchecked → clear children
    If Not $enabled Then
        GUICtrlSetState($keepID, $GUI_UNCHECKED)
        GUICtrlSetState($sellID, $GUI_UNCHECKED)
        GUICtrlSetState($salvID, $GUI_UNCHECKED)
        Return
    EndIf
    
    ; Radio behaviour: only the clicked action stays checked
    Switch $clickedCtrl
        Case $keepID
            GUICtrlSetState($sellID, $GUI_UNCHECKED)
            GUICtrlSetState($salvID, $GUI_UNCHECKED)
        Case $sellID
            GUICtrlSetState($keepID, $GUI_UNCHECKED)
            GUICtrlSetState($salvID, $GUI_UNCHECKED)
        Case $salvID
            GUICtrlSetState($keepID, $GUI_UNCHECKED)
            GUICtrlSetState($sellID, $GUI_UNCHECKED)
    EndSwitch
    
    ; Ensure at least one action is selected (default Keep)
    If Not (GUICtrlRead($keepID) = $GUI_CHECKED _
        Or GUICtrlRead($sellID) = $GUI_CHECKED _
        Or GUICtrlRead($salvID) = $GUI_CHECKED) Then
        GUICtrlSetState($keepID, $GUI_CHECKED)
    EndIf
EndFunc

; =========================
; UPDATE DICTIONARY BASED ON TREEVIEW
; =========================
Func UpdateLootRules()
    ConsoleWrite("=== Loot Rules Updated ===" & @CRLF)
    
    For $i = 0 To UBound($gLootTypes) - 1
        Local $type = $gLootTypes[$i]
        
        Local $enabled = GUICtrlRead($gTreeItems($type & "_Parent")) = $GUI_CHECKED
        Local $keep    = GUICtrlRead($gTreeItems($type & "_Keep")) = $GUI_CHECKED
        Local $sell    = GUICtrlRead($gTreeItems($type & "_Sell")) = $GUI_CHECKED
        Local $salvage = GUICtrlRead($gTreeItems($type & "_Salvage")) = $GUI_CHECKED
        
        ; Save pickup state
        $LootRules($type & "_Pickup") = $enabled
        
        ; Save action
        If $sell Then
            $LootRules($type & "_Action") = "Sell"
        ElseIf $salvage Then
            $LootRules($type & "_Action") = "Salvage"
        Else
            $LootRules($type & "_Action") = "Keep"
        EndIf
        
        ; Debug output
        ConsoleWrite($type & _
            " | Pickup=" & $LootRules($type & "_Pickup") & _
            " | Action=" & $LootRules($type & "_Action") & @CRLF)
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
