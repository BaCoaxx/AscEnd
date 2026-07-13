#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Baked Husk Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $WurmPath[7][2] = [ _
    [-10198, -5374], _
    [-9795, -5050], _
    [-9739, -3919], _
    [-9749, -2915], _
    [-9694, -2073], _
    [-9695, -969], _
    [-9699, -168] _
]

Func Farm_BakedHusk()
    Local $BakedHusk[1][2] = [[433, "Baked Husks"]] 
    
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        BakedHuskSetup()

        While CountSlotS() > 1
            If Not $BotRunning Then
              If Not $NickRun And Not $TwoFiddy Then
                ResetStart()
              EndIf
              Return
            EndIf

            If $NickRun Or $TwoFiddy Then
              Local $currentCount = GetItemCountByModelID($BakedHusk[0][0])
              Local $targetCount, $msg

              If $NickRun Then
                $targetCount = 25
                $msg = "Nicholas farm goal reached! "
              ElseIf $TwoFiddy Then
                $targetCount = 250
                $msg = "You got that mad stack brother! "
              EndIf

              If $currentCount >= $targetCount Then
                LogInfo($msg & "Collected " & $currentCount & " " & $BakedHusk[0][1])
                Return
              EndIf
            EndIf

            BakedHusk()
        WEnd
    WEnd
EndFunc

Func BakedHuskSetup()
    If Map_GetMapID() = 164 Then
        LogInfo("We are in Ashford Abbey. Starting the Baked Husks farm...")
    ElseIf Map_GetMapID() <> 164 And Map_IsMapUnlocked(164) Then
        LogInfo("We are not in Ashford Abbey. Teleporting to Ashford...")
        RndTravel(164)
        Sleep(2000)
    ElseIf Not Map_IsMapUnlocked(164) Then
        LogWarn("Ashford Abbey is not unlocked on this character, lets try to run there...")
        While Not UnlockAshford()
            LogError("Failed to unlock Ashford Abbey. Retrying...")
            Sleep(2000)
        WEnd
    EndIf
EndFunc

Func BakedHusk()
    If Map_GetMapID() <> 164 Then
        RndTravel(164)
    EndIf

    Sleep(1000)

    ExitAshford()

    Sleep(1000)

    $RunTime = TimerInit()

    LogInfo("Ooo get your wurms out. Ohh baby, baby!!")
    UseSummoningStone()
    RunToWurms($WurmPath)
    
    If GetPartyDead() Or SurvivorMode() Then
        LogError("Run failed. Restarting...")
        Return
    EndIf
    
    LogInfo("Just call me the Wurminat0r 3000..")
    Other_RndSleep(250)
    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
EndFunc

Func RunToWurms($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        AggroMoveSmartFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 1800, 1800, $WurmFilter, True, 1800)
        If SurvivorMode() Or GetPartyDead() Then
            LogError("Run failed. Restarting...")
            Return
        EndIf
        Sleep(100)
    Next
EndFunc