#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Nicholas Sandford Farm & Exchange

#ce ----------------------------------------------------------------------------

Func Farm_NickFarm()
    Local $NickID = $NickItem[0]
    Local $NickName = $NickItem[1]
    
    LogInfo("Starting Nicholas farm for: " & $NickName)
    
    For $i = 0 To UBound($g_aNicholasFarmMap) - 1 ; We get the current nick item, take the id, check our the other array and run the corresponding farm function :)
        If $g_aNicholasFarmMap[$i][0] = $NickID Then
            Local $sFarmFunc = $g_aNicholasFarmMap[$i][1]

            $NickRun = True
            Call($sFarmFunc)
            
            ; After farming is complete, exchange with Nicholas
            LogInfo("Farm complete, proceeding to Nicholas exchange...")
            Call("Farm_NickExchange")
        EndIf
    Next
    
    LogError("No farm available for " & $NickName)
    LogStatus("Bot will now pause...")
    $BotRunning = False
    Return
EndFunc
