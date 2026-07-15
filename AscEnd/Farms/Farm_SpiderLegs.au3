#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Spider Legs Farm (Also Unnatural Seeds) - Pre Searing

#ce ----------------------------------------------------------------------------

Func Farm_SpiderLegs()
    Local $SpiderLegs[1][2] = [[422, "Spider Legs"]] 

    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        SpiderLegsSetup()

        While CountSlots() > 1
            If Not $BotRunning Then
              If Not $NickRun And Not $TwoFiddy Then
                ResetStart()
              EndIf
              Return
            EndIf

            If $NickRun Or $TwoFiddy Then
              Local $currentCount = GetItemCountByModelID($SpiderLegs[0][0])
              Local $targetCount, $msg

              If $NickRun Then
                $targetCount = 25
                $msg = "Nicholas farm goal reached! "
              ElseIf $TwoFiddy Then
                $targetCount = 250
                $msg = "You got that mad stack brother! "
              EndIf

              If $currentCount >= $targetCount Then
                LogInfo($msg & "Collected " & $currentCount & " " & $SpiderLegs[0][1])
                Return
              EndIf
            EndIf

            SpiderLegs()
        WEnd
    WEnd
EndFunc

Func SpiderLegsSetup()
    If Map_GetMapID() = 166 Then
        LogInfo("We are in Fort Ranik. Starting the Spider Legs farm...")
    ElseIf Map_GetMapID() <> 166 And Map_IsMapUnlocked(166) Then
        LogInfo("We are not in Fort Ranik. Teleporting to Fort Ranik...")
        RndTravel(166)
        Sleep(2000)
    ElseIf Not Map_IsMapUnlocked(166) Then
        LogWarn("Fort Ranik is not unlocked on this character, lets try to run there...")
        While Not UnlockRanik()
            LogError("Failed to unlock Fort Ranik. Retrying...")
            Sleep(2000)
        WEnd
    EndIf
EndFunc

Func SpiderLegs()
    If Map_GetMapID() <> 166 Then
        RndTravel(166)
    EndIf

    ExitRanik()

    Sleep(1000)

    $RunTime = TimerInit()

    UseSummoningStone()
    Cache_SkillBar()
    RunTo($SeedsPath)

    If GetPartyDead() Or SurvivorMode() Then Return
    
    RunToSeeds($SeedsFoePath)

    If GetPartyDead() Or SurvivorMode() Then Return

    Other_RndSleep(250)
    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
EndFunc

Func RunToLegs($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        AggroMoveSmartFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 1200, 1200, $SpiderAloeFilter, True, 1000)
        If SurvivorMode() Or GetPartyDead() Then
            LogError("Run failed. Restarting...")
            Return
        EndIf
        Sleep(500)
    Next
EndFunc