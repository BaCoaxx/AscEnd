#include-once

#cs ----------------------------------------------------------------------------

	 AutoIt Version: 3.3.18.0
	 Author:         Coaxx

	 Script Function:
		Charr at the Gate - Pre Searing

#ce ----------------------------------------------------------------------------

Global $CharrPath[7][2] = [ _
    [6076, 4777], _
    [3435, 6366], _
    [679, 6551], _
    [-221, 7057], _
    [-2353, 8856], _
    [-2869, 9117], _
    [-3468, 10648] _
]

Global $CharrState
Global $desiredDistance = 1000
Global $hasRun = False

Func Farm_CharrAtTheGate()
    Cache_SkillBar()
    Sleep(2000)
    
    If CountSlots() < 4 Then InventoryPre()
    If Not $hasBonus Then GetBonus()

    While 1
		CheckQuest()

        If Not $BotRunning Then ResetStart() Return
            
		ExitAscalon()
		CharrAtGate()
		Sleep(250)
    WEnd
EndFunc

Func CheckQuest()
    If Map_GetMapID() = 148 Then
        If Not $hasRun Then
            LogInfo("We are in Ascalon baby!!")
            $hasRun = True
        EndIf
    ElseIf Map_GetMapID() <> 148 Then
        If Not $hasRun Then
            LogInfo("We are not in the greatest city of all. Teleporting to Ascalon...")
            $hasRun = True
        EndIf
        Map_RndTravel(148)
    EndIf

    Sleep(2000)

    Quest_ActiveQuest(0x2E)
    $CharrState = Quest_GetQuestInfo(0x2E, "LogState")

    If $CharrState = 1 Then
        LogInfo("Is that a roast furry!")
        Return
    ElseIf ($CharrState = 0) Or ($CharrState = 3) Then
        Quest_AbandonQuest(0x2E)
        Sleep(500)
        
        $spawn[0] = Agent_GetAgentInfo(-2, "X")
        $spawn[1] = Agent_GetAgentInfo(-2, "Y")
        Local $sp1 = ComputeDistance(5677, 10660, $spawn[0], $spawn[1])
        
        Select
            Case $sp1 <= 5000
                LogInfo("Ohh no step-prince!")
                MoveTo(8351, 10420)
                MoveTo(5677, 10660)
            Case $sp1 > 5000 And $sp1 <= 5800
                LogInfo("Come here Rurik.")
                MoveTo(7921, 6497)
                MoveTo(7416, 10497)
                MoveTo(5677, 10660)
             Case $sp1 > 5800 And $sp1 <= 7200
                LogInfo("I won't tell Althea, if you don't.")
                MoveTo(8328, 5684)
                MoveTo(7921, 6497)
                MoveTo(7416, 10497)
                MoveTo(5677, 10660)
        EndSelect
        
        Other_RndSleep(1000)
        Agent_GoNPC(GetNearestNPCToAgent(-2))
        Other_RndSleep(500)
        Ui_Dialog(0x802E01)
        
        Sleep(1000)

        Quest_ActiveQuest(0x2E)
        $CharrState = Quest_GetQuestInfo(0x2E, "LogState")

        If $CharrState = 1 Then
            LogInfo("Quest acquired!")
        ElseIf ($CharrState = 0) Or ($CharrState = 3) Then
            LogInfo("Cannot take quest!")
            LogStatus("Bot will now pause.")
            $BotRunning = False
            Return
        EndIf
        
        MoveTo(7416, 10497)
        MoveTo(7921, 6497)
        LogInfo("Heading out to say furr-well to the charr!")
    EndIf
EndFunc

Func ExitAscalon()
    MoveTo(7630, 5544)
    Map_Move(6985, 4939)
    Map_WaitMapLoading(146, 1)
    Sleep(1000)
EndFunc

Func CharrAtGate()
    $RunTime = TimerInit()

    Sleep(3200)
    LogInfo("Lead the way my Prince!")
    UseSummoningStone()
    RunTo($CharrPath)
    LogInfo("Come here you furry bastards!")
    
    Local $targetAgent, $currentDistance, $targetX, $targetY
    Local $myX, $myY, $angle, $newX, $newY

    Local $tolerance = 120
    Local $adjustFactor = 0.6
    Local $maxruntime = TimerInit()

    While TimerDiff($maxruntime) <= 200000
        If GetPartyDead() Then
            LogInfo("Way to go fool, you died!")
            UpdateStats()
            ExitLoop
        ElseIf SurvivorMode() Then
            LogInfo("Fur-ck this for game of cat and mouse, I'm out!")
            UpdateStats()
            ExitLoop
        ElseIf Agent_GetAgentInfo(-2, "HPPercent") * 100 <= 25 Then
            LogInfo("I regret everything that led to this fur-related emergency!")
            UpdateStats()
            ExitLoop
        ElseIf GetNumberOfCharrInRangeOfAgent(-2, 3500) <= 1 Then
            LogInfo("Run complete. Restarting...")
            UpdateStats()
            ExitLoop
        EndIf

        $targetAgent = Agent_TargetNearestEnemy(2800)
        $currentDistance = GetDistance($targetAgent, -2)
        
        If Abs($currentDistance - $desiredDistance) > $tolerance Then
            
            $targetX = Agent_GetAgentInfo($targetAgent, "X")
            $targetY = Agent_GetAgentInfo($targetAgent, "Y")
            
            $myX = Agent_GetAgentInfo(-2, "X")
            $myY = Agent_GetAgentInfo(-2, "Y")

            $angle = ATan2($targetY - $myY, $targetX - $myX)


            $newX = $targetX - ($desiredDistance * Cos($angle))
            $newY = $targetY - ($desiredDistance * Sin($angle))


            $newX = $myX + ($newX - $myX) * $adjustFactor
            $newY = $myY + ($newY - $myY) * $adjustFactor
            
            Map_Move($newX, $newY)
        EndIf
        Other_RndSleep(250)
    WEnd
    Resign()
EndFunc