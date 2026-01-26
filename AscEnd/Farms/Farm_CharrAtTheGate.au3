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
Global $desiredDistance = 900
Global $hasRun = False

Func Farm_CharrAtTheGate()
    If CountSlots() < 4 Then InventoryPre()
    If Not $hasBoners Then GetBoners()

    While 1
		CheckQuest()
		ExitAscalon()
		CharrAtGate()
		Sleep(250)
    WEnd
EndFunc

Func CheckQuest()
    If Map_GetMapID() = 148 Then
        If Not $hasRun Then
            Out("We are in Ascalon baby!!")
            $hasRun = True
        EndIf
    ElseIf Map_GetMapID() <> 148 Then
        If Not $hasRun Then
            Out("We are not in the greatest city of all. Teleporting to Ascalon...")
            $hasRun = True
        EndIf
        Map_RndTravel(148)
    EndIf

    Sleep(2000)

    Quest_ActiveQuest(0x2E)
    $CharrState = Quest_GetQuestInfo(0x2E, "LogState")

    If $CharrState = 1 Then
        Out("Is that a roast furry!")
        Return
    ElseIf ($CharrState = 0) Or ($CharrState = 3) Then
        Quest_AbandonQuest(0x2E)
        Sleep(500)
        
        $spawn[0] = Agent_GetAgentInfo(-2, "X")
        $spawn[1] = Agent_GetAgentInfo(-2, "Y")
        Local $sp1 = ComputeDistance(5677, 10660, $spawn[0], $spawn[1])
        
        Select
            Case $sp1 <= 5000
                Out("Ohh no step-prince!")
                MoveTo(8351, 10420)
                MoveTo(5677, 10660)
            Case $sp1 > 5000 And $sp1 <= 5800
                Out("Come here Rurik.")
                MoveTo(7921, 6497)
                MoveTo(7416, 10497)
                MoveTo(5677, 10660)
             Case $sp1 > 5800 And $sp1 <= 7200
                Out("I won't tell Althea, if you don't.")
                MoveTo(8328, 5684)
                MoveTo(7921, 6497)
                MoveTo(7416, 10497)
                MoveTo(5677, 10660)
        EndSelect
        
        Other_RndSleep(1000)
        Agent_GoNPC(GetNearestNPCToAgent(-2))
        Other_RndSleep(500)
        Ui_Dialog(0x802E01)
        Other_RndSleep(500)

        $CharrState = Quest_GetQuestInfo(0x2E, "LogState")

        If $CharrState = 1 Then
            Out("Quest acquired!")
        ElseIf ($CharrState = 0) Or ($CharrState = 3) Then
            Out("Cannot take quest!")
            Out("Bot will now close...")
            Sleep(5000)
            Exit
        EndIf
        
        MoveTo(7416, 10497)
        MoveTo(7921, 6497)
        Out("Heading out to say furr-well to the charr!")
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
    Out("Lead the way my Prince!")
    UseSummoningStone()
    RunToCharr($CharrPath)
    Out("Come here you furry bastards!")
    
    Local $tolerance = 140
    Local $adjustFactor = 0.4

    While 1
        If GetPartyDead() Then
            Out("Way to go fool, you died!")
            UpdateStats()
            ExitLoop
        ElseIf SurvivorMode() Then
            Out("Fur-ck this for game of cat and mouse, I'm out!")
            UpdateStats()
            ExitLoop
        ElseIf Agent_GetAgentInfo(-2, "HPPercent") * 100 <= 25 Then
            Out("I regret everything that led to this fur-related emergency!")
            UpdateStats()
            ExitLoop
        ElseIf GetNumberOfCharrInRangeOfAgent(-2, 3500) <= 1 Then
            Out("Run complete. Restarting...")
            UpdateStats()
            ExitLoop
        EndIf

        Local $charrArray = GetFilteredAgentsInRange(3500, "CharrFilter")

        If IsArray($charrArray) And UBound($charrArray) >= 2 Then
            ; We have at least 2 Charr in range
            Local $targetAgent1 = $charrArray[0] ; Closest
            Local $targetAgent2 = $charrArray[1] ; Second closest
            
            Local $distance1 = GetDistance($targetAgent1, -2)
            Local $distance2 = GetDistance($targetAgent2, -2)
            
            ; Determine which enemy is closest
            Local $closestAgent = ($distance1 < $distance2) ? $targetAgent1 : $targetAgent2
            Local $closestDistance = ($distance1 < $distance2) ? $distance1 : $distance2
            
            ; Only move if we're outside tolerance range of the closest enemy
            If Abs($closestDistance - $desiredDistance) > $tolerance Then
                ; Get positions
                Local $target1X = Agent_GetAgentInfo($targetAgent1, "X")
                Local $target1Y = Agent_GetAgentInfo($targetAgent1, "Y")
                Local $target2X = Agent_GetAgentInfo($targetAgent2, "X")
                Local $target2Y = Agent_GetAgentInfo($targetAgent2, "Y")
                Local $myX = Agent_GetAgentInfo(-2, "X")
                Local $myY = Agent_GetAgentInfo(-2, "Y")
                
                ; Calculate midpoint between the two enemies
                Local $midX = ($target1X + $target2X) / 2
                Local $midY = ($target1Y + $target2Y) / 2
                
                ; Calculate angle from closest enemy to your position
                Local $closestX = Agent_GetAgentInfo($closestAgent, "X")
                Local $closestY = Agent_GetAgentInfo($closestAgent, "Y")
                Local $angle = ATan2($myY - $closestY, $myX - $closestX)
                
                ; Position yourself at desired distance from the closest enemy
                Local $idealX = $closestX + ($desiredDistance * Cos($angle))
                Local $idealY = $closestY + ($desiredDistance * Sin($angle))
                
                ; But bias toward the midpoint to keep both in range
                ; 60% toward ideal position from closest, 40% toward midpoint
                Local $newX = ($idealX * 0.8) + ($midX * 0.2)
                Local $newY = ($idealY * 0.8) + ($midY * 0.2)
                
                ; Apply smooth adjustment
                $newX = $myX + ($newX - $myX) * $adjustFactor
                $newY = $myY + ($newY - $myY) * $adjustFactor
                
                Map_Move($newX, $newY)
            EndIf
        ElseIf IsArray($charrArray) And UBound($charrArray) >= 1 Then
            ; Only one Charr in range, use original single-target logic
            Local $targetAgent1 = $charrArray[0]
            Local $currentDistance = GetDistance($targetAgent1, -2)
            
            If Abs($currentDistance - $desiredDistance) > $tolerance Then
                Local $targetX = Agent_GetAgentInfo($targetAgent1, "X")
                Local $targetY = Agent_GetAgentInfo($targetAgent1, "Y")
                
                Local $myX = Agent_GetAgentInfo(-2, "X")
                Local $myY = Agent_GetAgentInfo(-2, "Y")
                
                Local $angle = ATan2($targetY - $myY, $targetX - $myX)
                
                Local $newX = $targetX - ($desiredDistance * Cos($angle))
                Local $newY = $targetY - ($desiredDistance * Sin($angle))
                
                $newX = $myX + ($newX - $myX) * $adjustFactor
                $newY = $myY + ($newY - $myY) * $adjustFactor
                
                Map_Move($newX, $newY)
            EndIf
        EndIf
        Other_RndSleep(250)
    WEnd
    Resign()
EndFunc

Func RunToCharr($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        MoveTo($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1])
    Next
EndFunc