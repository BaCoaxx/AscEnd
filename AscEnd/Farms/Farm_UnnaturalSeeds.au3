#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Unnatural Seed Farm (Also Spider Legs) - Pre Searing

#ce ----------------------------------------------------------------------------

Global $SeedsPath[5][2] = [ _
    [22434, 4456], _
    [21710, 3365], _
    [20471, 2644], _
    [19902, 1954], _
    [18979, 342] _
]

Global $SeedsFoePath[12][2] = [ _
    [18459, -1404], _
    [18117, -2672], _
    [17253, -3751], _
    [16118, -4523], _
    [15693, -5676], _
    [15688, -7657], _
    [15817, -8699], _
    [16992, -10330], _
    [17488, -11398], _
    [18616, -12186], _
    [20373, -12225], _
    [21225, -11664] _
]

Func Farm_UnnaturalSeeds()
    Local $UnnaturalSeeds[1][2] = [[428, "Unnatural Seeds"]] 

    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        UnnaturalSeedSetup()

        While CountSlots() > 1
            If Not $BotRunning Then
              If Not $NickRun And Not $TwoFiddy Then
                ResetStart()
              EndIf
              Return
            EndIf

            If $NickRun Or $TwoFiddy Then
              Local $currentCount = GetItemCountByModelID($UnnaturalSeeds[0][0])
              Local $targetCount, $msg

              If $NickRun Then
                $targetCount = 25
                $msg = "Nicholas farm goal reached! "
              ElseIf $TwoFiddy Then
                $targetCount = 250
                $msg = "You got that mad stack brother! "
              EndIf

              If $currentCount >= $targetCount Then
                LogInfo($msg & "Collected " & $currentCount & " " & $UnnaturalSeeds[0][1])
                Return
              EndIf
            EndIf

            UnnaturalSeed()
        WEnd
    WEnd
EndFunc

Func UnnaturalSeedSetup()
    If Map_GetMapID() = 166 Then
        LogInfo("We are in Fort Ranik. Starting the Unnatural Seeds farm...")
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

Func UnnaturalSeed()
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

Func RunToSeeds($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        AggroMoveSmartFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 1200, 1200, $SpiderAloeFilter, True, 1000)
        If SurvivorMode() Or GetPartyDead() Then
            LogError("Run failed. Restarting...")
            Return
        EndIf
        Sleep(500)
    Next
EndFunc