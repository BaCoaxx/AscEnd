#include-once

#cs ----------------------------------------------------------------------------

	 AutoIt Version: 3.3.18.0
	 Author:         Coaxx

	 Script Function:
		Unnatural Seed Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $SeedsPath[5][2] = [ _
    [22434, 4456], _
    [21710, 3365], _
    [20471, 2644], _
    [19902, 1954], _
    [18979, 342] _
]

Global $SeedsFoePath[11][2] = [ _
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
    [20373, -12225] _
]

Func Farm_UnnaturalSeeds()
    Cache_SkillBar()
    Sleep(2000)

    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        UnnaturalSeedSetup()

        While CountSlots() > 1
            If Not $BotRunning Then ResetStart() Return

            UnnaturalSeed()
        WEnd
    WEnd
EndFunc

Func UnnaturalSeedSetup()
    If Map_GetMapID() = 166 Then
        LogInfo("We are in Fort Ranik. Starting the Unnatural Seeds farm...")
    ElseIf Map_GetMapID() <> 166 And Map_IsMapUnlocked(166) Then
        LogInfo("We are not in Fort Ranik. Teleporting to Fort Ranik...")
        Map_RndTravel(166)
        Sleep(2000)
    ElseIf Not Map_IsMapUnlocked(166) Then
        LogWarn("Fort Ranik is not unlocked on this character, lets try to run there...")
        While Not UnlockRanik()
            LogError("Failed to unlock Fort Ranik.  Retrying...")
            Sleep(2000)
        WEnd
    EndIf

    $spawn[0] = Agent_GetAgentInfo(-2, "X")
    $spawn[1] = Agent_GetAgentInfo(-2, "Y")
    Local $sp1 = ComputeDistance(23020, 10125, $spawn[0], $spawn[1])
        
    Select
        Case $sp1 <= 2400
            LogInfo("Little high, little low.")
            MoveTo(22865, 11380)
            MoveTo(22958, 11149)
        Case $sp1 > 2400 And $sp1 <= 4200
            LogInfo("Anywhere the wind blows.")
            MoveTo(23038, 11847)
        Case $sp1 > 4200
            LogInfo("King Adelbern, doesn't even matter.")
            MoveTo(23186, 13527)
            MoveTo(23038, 11847)
        EndSelect

        MoveTo(22552, 7515) ; Gate trick setup
        Map_Move(22530, 7300)
        Map_WaitMapLoading(162, 1)
        Sleep(2000)
        Map_Move(22538, 7280)
        Map_WaitMapLoading(166, 0)
        Sleep(2000)
EndFunc

Func UnnaturalSeed()
    Other_RndSleep(250)
    MoveTo(22552, 7515)
    Map_Move(22530, 7300)
    Map_WaitMapLoading(162, 1)
    Sleep(1000)

    $RunTime = TimerInit()

    UseSummoningStone()
    RunTo($SeedsPath)
    RunToSeeds($SeedsFoePath)
    Other_RndSleep(250)
    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
    Resign()
    Sleep(5000)
    Map_ReturnToOutpost()
    Sleep(1000)
    Map_WaitMapLoading(166, 0)
    Sleep(1000)
EndFunc

Func RunToSeeds($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        PickupLoot()
        Sleep(1000)
        AggroMoveToExFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 1700, "UnnaturalSeeds")
        If SurvivorMode() Then
            LogError("Survivor mode activated!")
            Return
        EndIf
    Next
EndFunc

Func UnnaturalSeeds($aAgentPtr)

	If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False

    Local $ModelID = Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber')
    Local $SpiderAloeIDs[6] = [1401, 1403, 1426, 1428, 1429]
    Local $IsSpiderAloe = False
    For $i = 0 To UBound($SpiderAloeIDs) - 1
        If $ModelID == $SpiderAloeIDs[$i] Then
            $IsSpiderAloe = True
            ExitLoop
        EndIf
    Next
    If Not $IsSpiderAloe Then Return False

    Return True
EndFunc