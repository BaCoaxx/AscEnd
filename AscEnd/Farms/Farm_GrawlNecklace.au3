#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Grawl Necklace Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $GrawlNecklacePath[9][2] = [ _
    [-7915, 1434], _
    [-7823, 271], _
    [-7607, -148], _
    [-5330, -63], _
    [-2333, 296], _
    [-1902, 295], _
    [-118, 301], _
    [1411, 1123], _
    [3160, 2538] _
]

Global $GrawlNecklaceFarm[17][2] = [ _
    [3649, 4199], _
    [3161, 6039], _
    [3388, 6823], _
    [4897, 6321], _
    [6731, 5619], _
    [7552, 7086], _
    [6162, 7713], _
    [4569, 8568], _
    [4452, 9793], _
    [5886, 9843], _
    [7809, 9460], _
    [9681, 9265], _
    [10740, 9602], _
    [9543, 10930], _
    [8830, 11890], _
    [7450, 11645], _
    [5659, 12696] _
]

Func Farm_GrawlNecklace()
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        GrawlNecklaceSetup()

        While CountSlotS() > 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf

            If $NickRun Then
                Local $currentCount = GetItemCountByModelID($NickItem[0])
                If $currentCount >= 25 Then
                    LogInfo("Nicholas farm goal reached! Collected " & $currentCount & " " & $NickItem[1])
                    Return
                EndIf
            EndIf

            GrawlNecklace()
        WEnd
    WEnd
EndFunc

Func GrawlNecklaceSetup()
    If Map_GetMapID() = 163 Then
        LogInfo("We are in Barradin Estate. Starting the Grawl Necklace farm...")
    ElseIf Map_GetMapID() <> 163 And Map_IsMapUnlocked(163) Then
        LogInfo("We are not in Barradin Estate. Teleporting to Barradin Estate...")
        Map_RndTravel(163)
        Sleep(2000)
    ElseIf Not Map_IsMapUnlocked(163) Then
        LogWarn("Barradin Estate is not unlocked on this character, lets try to run there...")
        While Not UnlockBarradin()
            LogError("Failed to unlock Barradin Estate.  Retrying...")
            Sleep(2000)
        WEnd
    EndIf

    LogInfo("The stench of stupid grawl is rife out here today, let's go!")

    ExitBarradin()
    Sleep(2000)
    Map_Move(-7029, 1435)
    Map_WaitMapLoading(163, 0)
    Sleep(2000)
EndFunc

Func GrawlNecklace()
    ExitBarradin()
    Sleep(1000)
    
    $RunTime = TimerInit()

    LogInfo("The Grawl aren't the only monsters in Ascalon. I see mine in the mirror.")
    RunTo($GrawlNecklacePath)
    LogInfo("I'm running on rage and caffeine. Mostly rage.")
    UseSummoningStone()
    RunToGrawlNecklaces($GrawlNecklaceFarm)
    LogInfo("That's for the last patrol you ambushed, you filthy beasts.")
    Other_RndSleep(250)
    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
    Resign()
    Sleep(5000)
    Map_ReturnToOutpost()
    Sleep(1000)
    Map_WaitMapLoading(163, 0)
    Sleep(1000)
EndFunc

Func RunToGrawlNecklaces($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        AggroMoveSmartFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 1300, 1300, $GrawlNecklaceFilter, True, 1300)
        If SurvivorMode() Then
            LogError("Survivor mode activated!")
            Return
        EndIf
        Sleep(100)
    Next
EndFunc