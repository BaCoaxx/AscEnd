#include-once

#cs ----------------------------------------------------------------------------

	 AutoIt Version: 3.3.18.0
	 Author:         Coffee

	 Script Function:
		Worn Belts Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $BeltFarmPath[3][2] = [ _
    [-9110.60, -6051.47], _ 
    [-6799.50, -2996.72], _
    [-5846.73, -2574.55] _
]

Global $BeltFarmState

Func Farm_WornBelts()
    Cache_SkillBar()
    Sleep(2000)

    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()

        WornBeltsSetup()

	    While CountSlots() > 1
            If Not $BotRunning Then ResetStart() Return

		    WornBeltsFarm()
	    WEnd
    WEnd
EndFunc

Func WornBeltsSetup()
    Quest_ActiveQuest(0x29)
    $BeltFarmState = Quest_GetQuestInfo(0x29, "LogState")

    If $BeltFarmState = 1 Then
        LogInfo("Lets kill some Belt Thieves!")
    ElseIf $BeltFarmState = 0 Then
        LogError("We don't have the Bandit Raid quest!")
        LogInfo("Lets get it!")
        Sleep(1000)
        GetBeltQuest()        
    ElseIf $BeltFarmState = 3 Then
        LogWarn("Bandit Raid quest is completed, lets ditch and retake it!")
        Quest_AbandonQuest(0x29)
        Sleep(1000)
        GetBeltQuest()
    EndIf

    If Map_GetMapID() = 164 Then
        LogInfo("We are in Ashford Abbey. Starting Worn Belts Farm...")
    ElseIf Map_GetMapID() <> 164 And Map_IsMapUnlocked(164) Then
        LogInfo("We are not in Ashford Abbey. Teleporting to Ashford...")
        Map_RndTravel(164)
        Map_WaitMapLoading(164, 0)
        Sleep(2000)
    ElseIf Not Map_IsMapUnlocked(164) Then
        LogWarn("Ashford Abbey is not unlocked on this character, lets try to run there...")
        While Not UnlockAshford()
            LogError("Failed to unlock Ashford Abbey.  Retrying...")
            Sleep(2000)
        WEnd
    EndIf

    ExitAshford() ; Gate trick setup
    Map_Move(-11100, -6200)
    Map_WaitMapLoading(164, 0)
    Sleep(2000)
EndFunc

Func WornBeltsFarm()
    Map_Move(-11089, -6250) ; Leave Ashford Abbey
    Map_WaitMapLoading(146, 1)

    Sleep(1000)

	$RunTime = TimerInit()

    UseSummoningStone()
    RunToWB($BeltFarmPath)
    Other_RndSleep(250)
    LogInfo("Worn Belts Farm complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
    Resign()
    Sleep(5000)
    Map_ReturnToOutpost()
    Sleep(1000)
    Map_WaitMapLoading(164, 0)
    Sleep(1000)
EndFunc

Func RunToWB($g_a_RunPath)
    For $i = 0 To UBound($g_a_RunPath) - 1
        AggroMoveToExFilter($g_a_RunPath[$i][0], $g_a_RunPath[$i][1], 2500, "BanditFilter")
        If SurvivorMode() Then
            LogError("Survivor mode activated!")
            Return
        EndIf
    Next
EndFunc

Func GetBeltQuest()
    Map_RndTravel(148)

    $spawn[0] = Agent_GetAgentInfo(-2, "X")
    $spawn[1] = Agent_GetAgentInfo(-2, "Y")
    Local $sp1 = ComputeDistance(11062, 10709, $spawn[0], $spawn[1])

    If $sp1 < 3500 Then
        LogInfo("Come here you boring ass!")
        MoveTo(11022, 9397)
    ElseIf $sp1 >= 3500 Then
        LogInfo("All these stairs..")
        MoveTo(8232, 6228)
        MoveTo(11126, 9194)
    EndIf

    MoveTo(11062, 10709)

    Other_RndSleep(1000)
    Agent_GoNPC(GetNearestNPCToAgent(-2))
    Other_RndSleep(500)
    Ui_Dialog(0x802903)
    Other_RndSleep(500)
    Ui_Dialog(0x802901)

    Sleep(1000)

    Quest_ActiveQuest(0x29)
    $BeltFarmState = Quest_GetQuestInfo(0x29, "LogState")

    If $BeltFarmState = 1 Then
        LogWarn("Bandit Raid quest is active!")
    Else
        LogError("Cannot take quest!")
        LogStatus("Bot will now pause.")
        $BotRunning = False
        Return
    EndIf
EndFunc