#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Icy Lodestones Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $IcyLodesPath[21][2] = [ _
    [2077, 6020], _
    [2532, 4313], _
    [2814, 2997], _
    [3002, 2252], _
    [2933, 730], _
    [2249, 60], _
    [1332, 743], _
    [634, 2211], _
    [-588, 3467], _
    [-1864, 4460], _
    [-2829, 4839], _
    [-3670, 4207], _
    [-3845, 2624], _
    [-5275, 1280], _
    [-6092, -1124], _
    [-6009, -2251], _
    [-5862, -3607], _
    [-5811, -4583], _
    [-5569, -5221], _
    [-4269, -6000], _
    [-4085, -6607] _
]

Func Farm_IcyLodes()
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        IcyLodesSetup()

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

            IcyLodes()
        WEnd
    WEnd
EndFunc

Func IcyLodesSetup()
    If Map_GetMapID() = 165 Then
        LogInfo("We are in Foible's Fair. Starting the Icy Lodes farm...")
    ElseIf Map_GetMapID() <> 165 And Map_IsMapUnlocked(165) Then
        LogInfo("We are not in Foible's Fair. Teleporting to Foible's Fair...")
        Map_RndTravel(165)
        Sleep(2000)
    ElseIf Not Map_IsMapUnlocked(165) Then
        LogWarn("Foible's Fair is not unlocked on this character, lets try to run there...")
        While Not UnlockFoibles()
            LogError("Failed to unlock Foible's Fair.  Retrying...")
            Sleep(2000)
        WEnd
    EndIf

    LogWarn("We will abandon the Hamnet quest so the bandits don't kill us on the way..")

    Quest_AbandonQuest(0x4A1)

    Sleep(1000)

    MoveTo(-29.32, 8804.68)
    Map_Move(400, 7550) ; Gate trick setup
    Map_WaitMapLoading(161, 1)
    Sleep(2000)
    Map_Move(400, 7800)
    Map_WaitMapLoading(165, 0)
    Sleep(2000)
EndFunc

Func IcyLodes()
    Map_Move(400, 7550)
    Map_WaitMapLoading(161, 1)
    Sleep(1000)

    $RunTime = TimerInit()

    UseSummoningStone()
    LogInfo("I scream. You scream. We all scream for ICE CREAM!!")
    RunToIlodes($IcyLodesPath)
    LogInfo("Brr! It's so cold up here, I'll bring a dolyak lined fleece next time.")
    Other_RndSleep(250)
    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
    Resign()
    Sleep(5000)
    Map_ReturnToOutpost()
    Sleep(1000)
    Map_WaitMapLoading(165, 0)
    Sleep(1000)
EndFunc

Func RunToIlodes($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        AggroMoveSmartFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 1600, 1600, 1412, True, 1600)
        If SurvivorMode() Then
            LogError("Survivor mode activated!")
            Return
        EndIf
        Sleep(100)
    Next
EndFunc