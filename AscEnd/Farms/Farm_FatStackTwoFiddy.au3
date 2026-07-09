#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Fat Stack TwoFiddy

#ce ----------------------------------------------------------------------------

Func Farm_FatStackTwoFiddy()

    LogInfo("Starting the Fat Stack TwoFiddy!!!")
    $TwoFiddy = True
    
    For $i = 0 To UBound($g_aNicholasFarmMap) - 1
      Local $sFarmFunc = $g_aNicholasFarmMap[$i][1]

      Call($sFarmFunc)

      If Not $BotRunning Then
        ResetStart()
        Return
      EndIf
      
      ; After farming is complete, slap a ho ho ho.
      If $i >= UBound($g_aNicholasFarmMap) - 1 Then
        LogInfo("Farm complete!")
        LogStatus("Bot will now pause...")
        $BotRunning = False
      Else
        LogInfo("Onto the next one...")
      EndIf
    Next
    
    If $BotRunning Then
      LogError("No farm available for " & $NickName)
      LogStatus("Bot will now pause...")
      $BotRunning = False
    EndIf

    ResetStart()
    Return
EndFunc
