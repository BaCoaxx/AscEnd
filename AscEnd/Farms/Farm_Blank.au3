#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Blank Base For Farms

#ce ----------------------------------------------------------------------------

Func Farm_Blank()
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        BlankSetup()

        While CountSlotS() > 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf

            Blank()
        WEnd
    WEnd
EndFunc

Func BlankSetup() ; Setup the farm here, this wont be looped but will be called again if we come back from InventoryPre().

EndFunc

Func Blank() ; Main Farm that will loop.
   
EndFunc