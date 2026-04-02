#include <TreeView.au3> 

; LootSettings.au3

; Create a TreeView control for loot settings

Global $hTreeView = _GUICreate("Loot Settings", 400, 300) 

; Add types: Purple, Collector, Mod
Global $aTypes[3] = [{"name":"Purple","options":["Keep","Sell","Salvage"]},{"name":"Collector","options":["Keep","Sell","Salvage"]},{"name":"Mod","options":["Keep","Sell","Salvage"]}] 

For $i = 0 To UBound($aTypes) - 1 
    Local $hType = _TreeView_Add($hTreeView, $aTypes[$i].name) 
    For $j = 0 To UBound($aTypes[$i].options) - 1 
        _TreeView_Add($hTreeView, $aTypes[$i].options[$j], $hType) 
    Next 
Next 

GUISetState(@SW_SHOW, $hTreeView) 
While 1 
    Switch GUIGetMsg() 
        Case $GUI_EVENT_CLOSE 
            Exit 
    EndSwitch 
WEnd