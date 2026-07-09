#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Enchanted Lodestones Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $EnchLodesPath1[5][2] = [ _ ; Barradin to Elode path
    [-7916, 1431], _
    [-10492, 1445], _
    [-11775, 2709], _
    [-12306, 3467], _
    [-11963, 4448] _
]

Global $ELodePath2[11][2] = [ _ ; Stone Elementals path
    [-10999, 5376], _
    [-11810, 6735], _
    [-11321, 8714], _
    [-11816, 9902], _
    [-13260, 11043], _
    [-14233, 12006], _
    [-16411, 13829], _
    [-17769, 14268], _
    [-19963, 12555], _
    [-19770, 11666], _
    [-18961, 10906] _
]

Func Farm_EnchLodes()
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        EnchLodesSetup()

        While CountSlotS() > 1
            If Not $BotRunning Then
              If Not $NickRun And Not $TwoFiddy Then
                ResetStart()
              EndIf
              Return
            EndIf

            If $NickRun Or $TwoFiddy Then
              Local $currentCount = GetItemCountByModelID($NickItem[0])
              Local $targetCount, $msg

              If $NickRun Then
                $targetCount = 25
                $msg = "Nicholas farm goal reached! "
              ElseIf $TwoFiddy Then
                $targetCount = 250
                $msg = "You got that mad stack brother! "
              EndIf

              If $currentCount >= $targetCount Then
                LogInfo($msg & "Collected " & $currentCount & " " & $NickItem[1])
                Return
              EndIf
            EndIf

            EnchLodes()
        WEnd
    WEnd
EndFunc

Func EnchLodesSetup()
    If Map_GetMapID() = 163 Then
        LogInfo("We are in Barradin Estate. Starting the Enchanted Lodes farm...")
    ElseIf Map_GetMapID() <> 163 And Map_IsMapUnlocked(163) Then
        LogInfo("We are not in Barradin Estate. Teleporting to Barradin Estate...")
        RndTravel(163)
        Sleep(2000)
    ElseIf Not Map_IsMapUnlocked(163) Then
        LogWarn("Barradin Estate is not unlocked on this character, lets try to run there...")
        While Not UnlockBarradin()
            LogError("Failed to unlock Barradin Estate. Retrying...")
            Sleep(2000)
        WEnd
    EndIf

    LogInfo("We need loads of lodes, so let's go!")
EndFunc

Func EnchLodes()
    If Map_GetMapID() <> 163 Then
        RndTravel(163)
    EndIf

    ExitBarradin()

    Sleep(1000)
    
    $RunTime = TimerInit()

    LogInfo("I smell trouble, so let there be rubble! Come here Stone Elementals!")
    RunTo($EnchLodesPath1)

    If SurvivorMode() Or GetPartyDead() Then Return
    
    LogInfo("I'm going to turn you into hardcore!")
    UseSummoningStone()
    RunToElodes($ELodePath2)
    
    If SurvivorMode() Or GetPartyDead() Then Return

    Other_RndSleep(250)
    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
EndFunc

Func RunToElodes($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        AggroMoveSmartFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 1600, 1600, $EnchLodesFilter, True, 1600)
        If SurvivorMode() Or GetPartyDead() Then
            LogError("Run failed. Restarting...")
            Return
        EndIf
        Sleep(100)
    Next
EndFunc