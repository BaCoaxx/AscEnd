#include-once

#Region Calculations
;~ Description: Returns the distance between two coordinate pairs.
Func ComputeDistance($aX1, $aY1, $aX2, $aY2)
	Return Sqrt(($aX1 - $aX2) ^ 2 + ($aY1 - $aY2) ^ 2)
EndFunc   ;==>ComputeDistance

Func ATan2($y, $x)
    Return ATan($y / $x) + (($x < 0) ? (($y < 0) ? -3.14159265358979 : 3.14159265358979) : 0)
EndFunc   ;==>ATan2

;~ Description: Returns the distance between two agents.
Func GetDistance($aAgent1 = -1, $aAgent2 = -2)
	If IsDllStruct($aAgent1) = 0 Then $aAgent1 = Agent_GetAgentPtr($aAgent1)
	If IsDllStruct($aAgent2) = 0 Then $aAgent2 = Agent_GetAgentPtr($aAgent2)
	Return Sqrt((Agent_GetAgentInfo($aAgent1, "X") - Agent_GetAgentInfo($aAgent2, "X")) ^ 2 + (Agent_GetAgentInfo($aAgent1, "Y") - Agent_GetAgentInfo($aAgent2, "Y")) ^ 2)
EndFunc   ;==>GetDistance

Func CheckAreaRange($aX, $aY, $range)
	$ret = False
	$pX = Agent_GetAgentInfo(-2, "X")
	$pY = Agent_GetAgentInfo(-2, "Y")

	If ($pX < $aX + $range) And ($pX > $aX - $range) And ($pY < $aY + $range) And ($pY > $aY - $range) Then
		$ret = True
	EndIf
	Return $ret
EndFunc   ;==>CheckAreaRange

Func CalculateAverageTime()
	Local $averagetime
	Local $timesum = 0

	for $i = 1 To UBound($AvgTime)
		$timesum += $AvgTime[$i-1]
	Next

	$averagetime = $timesum/UBound($AvgTime)
	$averagetime = Round($averagetime)
	$AvgRunTimeMinutes = Int($averagetime / 60)
	$AvgRunTimeSeconds = Mod($averagetime , 60)
EndFunc ;==> CalculateAverageTime

Func CalculateFastestTime()
	Local $fastesttime
	Local $currtime

	for $i = 1 To UBound($AvgTime)
		$currtime = $AvgTime[$i-1]
		If $i = 1 Then
			$fastesttime = $currtime
		Else
			If $currtime < $fastesttime Then
				$fastesttime = $currtime
			EndIf
		EndIf
	Next

	$RunTimeMinutes = Int($fastesttime / 60)
    $RunTimeSeconds = Mod($fastesttime , 60)
EndFunc ;==> CalculateFastestTime
#EndRegion Calculations

#Region Travel
Func RndTravel($aMapID)
	Local $UseDistricts = 7 ; 7=eu, 8=eu+int, 11=all(incl. asia)
	; Region/Language order: eu-en, eu-fr, eu-ge, eu-it, eu-sp, eu-po, eu-ru, int, asia-ko, asia-ch, asia-ja
	Local $Region[11]   = [2, 2, 2, 2, 2, 2, 2, -2, 1, 3, 4]
	Local $Language[11] = [0, 2, 3, 4, 5, 9, 10, 0, 0, 0, 0]
	Local $Random = Random(0, $UseDistricts - 1, 1)
;~ 	MoveMap($aMapID, $Region[$Random], 0, $Language[$Random])
	Map_MoveMap($aMapID, $Region[$Random], 0, $Language[5])
	Map_WaitMapLoading($aMapID, 0)
	Sleep(1000)
EndFunc   ;==>RndTravel
#EndRegion Travel

#Region Other
;~ Description: Resign.
Func Resign()
	Chat_SendChat('resign', '/')
EndFunc   ;==>Resign

Func GetIsDead($aAgent = -2)
	Return Agent_GetAgentInfo($aAgent, "IsDead")
EndFunc	;==>GetisDead

Func GetEnergy($aAgent = -2)
	Return Agent_GetAgentInfo($aAgent, "CurrentEnergy")
EndFunc	;==>GetEnergy
#EndRegion

#Region Movement
Func MoveTo($aX, $aY, $aRandom = 50)
	Local $lBlocked = 0
	Local $lMe
	Local $lMapLoading = Map_GetInstanceInfo("Type"), $lMapLoadingOld
	Local $lDestX = $aX + Random(-$aRandom, $aRandom)
	Local $lDestY = $aY + Random(-$aRandom, $aRandom)

	If GetPartyDead() Then Return
	If SurvivorMode(40) Then Return

	Map_Move($lDestX, $lDestY, 0)

	Do
		Sleep(100)

		If GetPartyDead() Then ExitLoop
		If SurvivorMode(40) Then Return

		$lMapLoadingOld = $lMapLoading
		$lMapLoading = Map_GetInstanceInfo("Type")
		If $lMapLoading <> $lMapLoadingOld Then ExitLoop

		If Agent_GetAgentInfo(-2, "MoveX") == 0 And Agent_GetAgentInfo(-2, "MoveY") == 0 Then
			$lBlocked += 1
			$lDestX = $aX + Random(-$aRandom, $aRandom)
			$lDestY = $aY + Random(-$aRandom, $aRandom)
			If $lBlocked == 14 Then
				Chat_SendChat("Stuck", "/")
				If SurvivorMode(40) Then Return
			EndIf
			Map_Move($lDestX, $lDestY, 0)
			If SurvivorMode(40) Then Return
		EndIf
	Until ComputeDistance(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), $lDestX, $lDestY) < 25 Or $lBlocked > 20 Or GetPartyDead()
EndFunc   ;==>MoveTo

Func MoveUpkeepEx($aX, $aY, $aUpkeepSkills = 0, $aOrderedSkills = 0, $bCastInOrder = False, $Range = 85, $aRandom = 50)
Local $lDestX = $aX + Random(-$aRandom, $aRandom)
Local $lDestY = $aY + Random(-$aRandom, $aRandom)
    While ComputeDistance(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), $lDestX, $lDestY) > $Range And Not GetPartyDead()
        If $bCastInOrder And IsArray($aOrderedSkills) Then
            Local $allReady = True
            For $i = 0 To UBound($aOrderedSkills) - 1
                If Not IsRecharged($aOrderedSkills[$i]) Then
                    $allReady = False
                    ExitLoop
                EndIf
            Next

            If $allReady Then
                For $i = 0 To UBound($aOrderedSkills) - 1
                    UseSkillEx($aOrderedSkills[$i], -2)
                    Sleep(150)
                Next
            EndIf
        Else
            If IsArray($aUpkeepSkills) Then
                For $i = 0 To UBound($aUpkeepSkills) - 1
                    Local $aSkill = Skill_GetSkillBarInfo($aUpkeepSkills[$i], "SkillID")
                    Local $hasEffect = Agent_GetAgentEffectInfo(-2, $aSkill, "HasEffect")
                    Local $skillDuration = Agent_GetAgentEffectInfo(-2, $aSkill, "Duration")
                    Local $timeRemaining = Agent_GetAgentEffectInfo(-2, $aSkill, "TimeRemaining")
                    Local $recastTime = ($skillDuration * 1000) / 8

                    If Not $hasEffect Or $timeRemaining <= $recastTime Then
                        UseSkillEx($aUpkeepSkills[$i], -2)
                    EndIf            
                Next
            EndIf
        EndIf

        Map_Move($lDestX, $lDestY, 0)
        Sleep(100)
    WEnd
EndFunc   ;==>MoveUpkeepEx
#EndRegion

#Region Fighting
Func AggroMoveToExFilter($aX, $aY, $range = 1700, $filterFunc = "EnemyFilter")

	If GetPartyDead() Then Return
	$TimerToKill = TimerInit()
	Local $random = 50
	Local $iBlocked = 0
	Local $enemy
	Local $distance

	Map_Move($aX, $aY, $random)
	$coords[0] = Agent_GetAgentInfo(-2, 'X')
	$coords[1] = Agent_GetAgentInfo(-2, 'Y')
	Do
		If GetPartyDead() Then ExitLoop
		Other_RndSleep(250)
		$oldCoords = $coords
		If GetNumberOfFoesInRangeOfAgent(-2, 1700, $GC_I_AGENT_TYPE_LIVING, 1, $filterFunc) > 0 Then
			If GetPartyDead() Then ExitLoop
			$enemy = GetNearestEnemyToAgent(-2, 1700, $GC_I_AGENT_TYPE_LIVING, 1, $filterFunc)
			If GetPartyDead() Then ExitLoop
			$distance = ComputeDistance(Agent_GetAgentInfo($enemy, 'X'), Agent_GetAgentInfo($enemy, 'Y'), Agent_GetAgentInfo(-2, 'X'), Agent_GetAgentInfo(-2, 'Y'))
			If $distance < $range And $enemy <> 0 And Not GetPartyDead() Then
				FightExFilter($range, $filterFunc)
				If SurvivorMode() Then Return
			EndIf
		EndIf

		Other_RndSleep(250)

		If GetPartyDead() Then ExitLoop
		$coords[0] = Agent_GetAgentInfo(-2, 'X')
		$coords[1] = Agent_GetAgentInfo(-2, 'Y')
		If $oldCoords[0] = $coords[0] And $oldCoords[1] = $coords[1] And Not GetPartyDead() Then
			$iBlocked += 1
			MoveTo($coords[0], $coords[1], 300)
			Other_RndSleep(350)
			If GetPartyDead() Then ExitLoop
			Map_Move($aX, $aY)
		EndIf

	Until ComputeDistance($coords[0], $coords[1], $aX, $aY) < 250 Or $iBlocked > 20 Or GetPartyDead() Or TimerDiff($TimerToKill) > 180000
EndFunc   ;==>AggroMoveToExFilter

Func FightExFilter($range, $filterFunc = "EnemyFilter")
	If GetPartyDead() Then Return
	If SurvivorMode() Then Return
	Local $target
	Local $distance
	Local $useSkill
	Local $energy
	Local $lastId = 99999, $coordinate[2], $timer
	Out("Engaging in combat...")
		Do
			If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
			If TimerDiff($TimerToKill) > 180000 Then Exitloop
			If GetPartyDead() Then Exitloop
			If SurvivorMode() Then Return
			$target = GetNearestEnemyToAgent(-2, 1700, $GC_I_AGENT_TYPE_LIVING, 1, $filterFunc)
			If GetPartyDead() Then Exitloop
			If SurvivorMode() Then Return
			$distance = ComputeDistance(Agent_GetAgentInfo($target, 'X'), Agent_GetAgentInfo($target, 'Y'), Agent_GetAgentInfo(-2, 'X'), Agent_GetAgentInfo(-2, 'Y'))
			If $target <> 0 AND $distance < $range And Not GetPartyDead() Then
				If TimerDiff($TimerToKill) > 180000 Then Exitloop
				If Agent_GetAgentInfo($target, 'ID') <> $lastId Then
					If GetPartyDead() Then Exitloop
					If SurvivorMode() Then Return
					Agent_ChangeTarget($target)
					Other_RndSleep(150)
					Agent_CallTarget($target)
					Other_RndSleep(150)
					If GetPartyDead() Then Exitloop
					If SurvivorMode() Then Return
					Agent_Attack($target)
					$lastId = Agent_GetAgentInfo($target, 'ID')
					$coordinate[0] = Agent_GetAgentInfo($target, 'X')
					$coordinate[1] = Agent_GetAgentInfo($target, 'Y')
					$timer = TimerInit()
					$distance = ComputeDistance($coordinate[0], $coordinate[1], Agent_GetAgentInfo(-2, 'X'), Agent_GetAgentInfo(-2, 'Y'))
					If GetPartyDead() Then Exitloop
					If SurvivorMode() Then Return
					If $distance > 1100 Then
						Do
							If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
							If TimerDiff($TimerToKill) > 180000 Then Exitloop
							If GetPartyDead() Then Exitloop
							If SurvivorMode() Then Return
							Map_Move($coordinate[0], $coordinate[1])
							Other_RndSleep(50)
							If GetPartyDead() Then Exitloop
							If SurvivorMode() Then Return
							$distance = ComputeDistance($coordinate[0], $coordinate[1], Agent_GetAgentInfo(-2, 'X'), Agent_GetAgentInfo(-2, 'Y'))
						Until $distance < 1100 Or TimerDiff($timer) > 10000 Or GetPartyDead() Or TimerDiff($TimerToKill) > 180000
					EndIf
				EndIf
				If TimerDiff($TimerToKill) > 180000 Then Exitloop
				Other_RndSleep(150)
				$timer = TimerInit()
				If GetPartyDead() Then Exitloop
				If SurvivorMode() Then Return
					Do
						If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
						If TimerDiff($TimerToKill) > 180000 Then Exitloop
						If GetPartyDead() Then Exitloop
						If SurvivorMode() Then Return
						$target = GetNearestEnemyToAgent(-2, 1700, $GC_I_AGENT_TYPE_LIVING, 1, $filterFunc)
						If GetPartyDead() Then Exitloop
						If SurvivorMode() Then Return
						$distance = GetDistance($target, -2)
						If $distance < 1250 And Not GetPartyDead() Then
							If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
							If TimerDiff($TimerToKill) > 180000 Then Exitloop
							For $i = 0 To 7
								If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
								If TimerDiff($TimerToKill) > 180000 Then Exitloop
								If GetPartyDead() Then Exitloop
								If SurvivorMode() Then Return
								If Agent_GetAgentInfo($target, 'IsDead') Then ExitLoop

								$distance = GetDistance($target, -2)
								If $distance > $range Then ExitLoop

								$energy = GetEnergy(-2)

								If IsRecharged($i+1) And $energy >= Skill_GetSkillInfo(Skill_GetSkillbarInfo($i, "SkillID"), "EnergyCost") And Not GetPartyDead() Then
									If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
									If TimerDiff($TimerToKill) > 180000 Then Exitloop
									$useSkill = $i + 1
									UseSkillEx($useSkill, $target)
									Other_RndSleep(150)
									If GetPartyDead() Then Exitloop
									If SurvivorMode() Then Return
									Agent_Attack($target)
									Other_RndSleep(150)
								EndIf
								If TimerDiff($TimerToKill) > 180000 Then Exitloop
								If $i = 7 Then $i = -1 ; change -1
								If GetPartyDead() Then Exitloop
								If SurvivorMode() Then Return
							Next
						EndIf
						If TimerDiff($TimerToKill) > 180000 Then Exitloop
						If GetPartyDead() Then Exitloop
						If SurvivorMode() Then Return
						Agent_Attack($target)
						$distance = GetDistance($target, -2)
					Until Agent_GetAgentInfo($target, 'HP') < 0.005 Or $distance > $range Or TimerDiff($timer) > 20000 Or GetPartyDead() Or TimerDiff($TimerToKill) > 180000
			EndIf
			If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
			If TimerDiff($TimerToKill) > 180000 Then Exitloop
			If GetPartyDead() Then Exitloop
			If SurvivorMode() Then Return
			$target = GetNearestEnemyToAgent(-2, 1700, $GC_I_AGENT_TYPE_LIVING, 1, $filterFunc)
			If GetPartyDead() Then Exitloop
			If SurvivorMode() Then Return
			$distance = GetDistance($target, -2)
		Until Agent_GetAgentInfo($target, 'ID') = 0 Or $distance > $range Or GetPartyDead() Or TimerDiff($TimerToKill) > 180000

		If CountSlots() <> 0 And Not GetPartyDead() Then
			If TimerDiff($TimerToKill) > 180000 Then Return
			PickupLoot()
		EndIf
EndFunc   ;==>FightExFilter

Func GetPartyDead()
	; Party is dead, if player is dead and no more heroes have a rez skill or all heroes with rez skills are also dead
	Local $heroID

	; Check, if all of those heroes are dead - if at least 1 is still alive not, return false
	For $ii = 1 To UBound($heroNumberWithRez)
		$heroID = Party_GetMyPartyHeroInfo($heroNumberWithRez[$ii-1], "AgentID")
		If Not Agent_GetAgentInfo($heroID, "IsDead") Then Return False
	Next

	; If those heroes are all dead, check if you as player are also dead
	If Not GetIsDead(-2) Then Return False

	; Only for follower bot - Check if leader is dead
	If Not GetIsDead(GetMemberAgentID(1)) Then Return False

	; If all area dead, return True
	Return True
EndFunc ;==> GetPartyDead

Func SurvivorMode($Threshold = 65)
	If $Survivor = True Then
		If Agent_GetAgentInfo(-2, 'CurrentHP') <= Agent_GetAgentInfo(-2, 'MaxHP') * ($Threshold / 100) Then
			Return True
		EndIf
	EndIf
	Return False
EndFunc ;==> SurvivorMode

Func CacheHeroesWithRez()
	; Go over all heroes and find all Heroes with rez skills
	For $i = 1 To Party_GetMyPartyInfo("ArrayHeroPartyMemberSize")
		If HasRezSkill($i) Then
			Redim $heroNumberWithRez[UBound($heroNumberWithRez)+1]
			$heroNumberWithRez[UBound($heroNumberWithRez)-1] = $i
		EndIf
	Next
EndFunc ;==> CacheHeroesWithRez

Func GetPartyDefeated()
	; Party is defeated, when you die, while Malus is at 60%
	Return Party_GetPartyContextInfo("IsDefeated")
EndFunc ;==> GetPartyDefeated

Func GetPartySize()
    Local $aParty = Party_GetMyPartyInfo("ArrayPlayerPartyMemberSize")
    Local $aHero = Party_GetMyPartyInfo("ArrayHeroPartyMemberSize")
    Local $aHench = Party_GetMyPartyInfo("ArrayHenchmanPartyMemberSize")
    
    Return $aParty + $aHero + $aHench
EndFunc   ;==> GetPartySize

Func GetEffectTimeRemainingEx($aAgent = -2, $aSkillID = 0, $aInfo = "TimeRemaining")
    Return Agent_GetAgentEffectInfo($aAgent, $aSkillID, $aInfo)
EndFunc   ;==>GetEffectTimeRemainingEx
#EndRegion

#Region AgentFilters
Func EnemyFilter($aAgentPtr)

	If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
	If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False

    Return True
EndFunc	;==>EnemyFilter

Func CharrFilter($aAgentPtr)

	If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False

    Local $ModelID = Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber')
    Local $CharrModelIDs[6] = [1640, 1643, 1648, 1652, 1658, 1662] ; Array of Charr model IDs
    Local $IsCharr = False
    For $i = 0 To UBound($CharrModelIDs) - 1
        If $ModelID == $CharrModelIDs[$i] Then
            $IsCharr = True
            ExitLoop
        EndIf
    Next
    If Not $IsCharr Then Return False

    Return True
EndFunc   ;==>CharrFilter

Func MantisMenderFilter($aAgentPtr)

	If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
	If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False
	If Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber') <> $MantisMender Then Return False

    Return True
EndFunc	;==>MantisMenderFilter

Func WardenSummerFilter($aAgentPtr)

	If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
	If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False
	If Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber') <> $WardenSummer Then Return False

    Return True
EndFunc	;==>WardenSummerFilter

Func WardenSeasonFilter($aAgentPtr)

	If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
	If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False
	If Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber') <> $WardenSeason Then Return False

    Return True
EndFunc	;==>WardenSeasonFilter

Func NPCFilter($aAgentPtr)

	If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 6 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
	If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False

    Return True
EndFunc	;==>NPCFilter
#EndRegion

#Region Agents
Func GetNearestEnemyToAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 1, $aCustomFilter = "EnemyFilter")
	Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc	;==>GetNearestEnemyToAgent

Func GetNearestMantisMenderToAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 1, $aCustomFilter = "MantisMenderFilter")
	Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc	;==>GetNearestMantisMenderToAgent

Func GetNearestWardenSummerToAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 1, $aCustomFilter = "WardenSummerFilter")
	Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc	;==>GetNearestWardenSummerToAgent

Func GetNearestWardenSeasonToAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 1, $aCustomFilter = "WardenSeasonFilter")
	Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc	;==>GetNearestWardenSeasonToAgent

Func GetNumberOfFoesInRangeOfAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 0, $aCustomFilter = "EnemyFilter")
	Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc	;==>GetNumberOfFoesInRangeOfAgent

Func GetNumberOfCharrInRangeOfAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 0, $aCustomFilter = "CharrFilter")
	Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc	;==>GetNumberOfCharrInRangeOfAgent

Func GetNumberOfMantisMendersInRangeOfAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 0, $aCustomFilter = "MantisMenderFilter")
	Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc	;==>GetNumberOfMantisMendersInRangeOfAgent

Func GetNumberOfWardenSummersInRangeOfAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 0, $aCustomFilter = "WardenSummerFilter")
	Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc	;==>GetNumberOfWardenSummersInRangeOfAgent

Func GetNumberOfWardenSeasonsInRangeOfAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 0, $aCustomFilter = "WardenSeasonFilter")
	Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc	;==>GetNumberOfWardenSeasonsInRangeOfAgent

Func GetNearestNPCToAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 1, $aCustomFilter = "NPCFilter")
	Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc	;==>GetNearestNPCToAgent

Func GetFilteredAgentsInRange($aRadius, $aFilterFunc = "")
    Local $lAgentArray = Agent_GetAgentArray($GC_I_AGENT_TYPE_LIVING)
    If Not IsArray($lAgentArray) Or $lAgentArray[0] = 0 Then Return 0

    Local $myX = Agent_GetAgentInfo(-2, "X")
    Local $myY = Agent_GetAgentInfo(-2, "Y")

    Local $result[0]
    For $i = 1 To $lAgentArray[0]
        Local $lAgentPtr = $lAgentArray[$i]

        ; Filters the agents
        If $aFilterFunc <> "" Then
            If Not Call($aFilterFunc, $lAgentPtr) Then ContinueLoop
        EndIf

        ; Range check to see whether agents are outside of the radius
        Local $tempax = Agent_GetAgentInfo($lAgentPtr, "X")
        Local $tempay = Agent_GetAgentInfo($lAgentPtr, "Y")
        Local $dist = Sqrt(($tempax - $myX) ^ 2 + ($tempay - $myY) ^ 2)
        If $dist > $aRadius Then ContinueLoop

        ; Append to an array
        ReDim $result[UBound($result) + 1]
        $result[UBound($result) - 1] = $lAgentPtr
    Next

    Return $result
EndFunc   ;==>GetFilteredAgentsInRange

Func GetMemberAgentID($aPartyMember)
    If $aPartyMember < 1 Then Return 0

    Local $myLogin = Agent_GetAgentInfo(-2, "LoginNumber")
    Local $playerCount = Party_GetMyPartyInfo("ArrayPlayerPartyMemberSize")
    If $playerCount < 1 Then Return 0

    Local $pos = 0

    For $i = 1 To $playerCount
        $pos += 1
        If $pos <> $aPartyMember Then ContinueLoop

        Local $login = Party_GetMyPartyPlayerMemberInfo($i, "LoginNumber")
        If $login = 0 Then Return 0

        If $login = $myLogin Then Return Agent_GetMyID()

        Local $agents = Agent_GetAgentArray(0xDB)
        If Not IsArray($agents) Or $agents[0] = 0 Then Return 0

        For $j = 1 To $agents[0]
            If Agent_GetAgentInfo($agents[$j], "LoginNumber") = $login Then
                Return Agent_GetAgentInfo($agents[$j], "ID")
            EndIf
        Next

        Return 0
    Next

    Return 0
EndFunc   ;==>GetMemberAgentID
#EndRegion

#Region Skills
Func IsRecharged($aSkill)
	Return Skill_GetSkillbarInfo($aSkill, "IsRecharged")
EndFunc   ;==>IsRecharged

Func UseSkillEx($aSkill, $aTgt = -2, $aTimeout = 3000)
	If GetIsDead(-2) Then Return
	If Not IsRecharged($aSkill) Then Return
	Local $aSkillID = Skill_GetSkillbarInfo($aSkill, "SkillID")
	Local $aEnergyCost = Skill_GetSkillInfo($aSkillID, "EnergyCost")
	If GetEnergy(-2) < $aEnergyCost Then Return
	Local $lDeadlock = TimerInit()
	Skill_UseSkill($aSkill, $aTgt)

	Do
		Sleep(32)
		If GetIsDead(-2) Then Return
	Until (Not Agent_GetAgentInfo(-2, "IsCasting") And Not Agent_GetAgentInfo(-2, "Skill") And Not Skill_GetSkillbarInfo($aSkill, "Casting")) Or (TimerDiff($lDeadlock) > $aTimeout)
EndFunc   ;==>UseSkillEx

Func HasRezSkill($a_i_HeroNumber)
	For $i = 1 To 8
		For $ii = 1 To UBound($RezSkillIDs)
			If Skill_GetSkillbarInfo($i, "SkillID", $a_i_HeroNumber) = $RezSkillIDs[$ii-1] Then
				Return True
			EndIf
		Next
	Next
	Return False
EndFunc ;==> HasRezSkill
#EndRegion

#Region Inventory
Func CountSlots()
	Local $bag
	Local $temp = 0
	For $i = 1 To 4
		$bag = Item_GetBagPtr($i)
		$temp += Item_GetBagInfo($bag,"EmptySlots")
	Next
	Return $temp
EndFunc ; Counts open slots in your Inventory

; Returns the total quantity of items with the given ModelID in bags 1-4
Func GetItemCountByModelID($targetModelID)
    Local $totalCount = 0
    Local $itemModelID
    Local $itemQuantity
    Local $itemPtr

    For $bag = 1 To 4
        Local $bagPtr = Item_GetBagPtr($bag)
        If $bagPtr = 0 Then ContinueLoop  ; Skip if bag doesn't exist

        Local $slots = Item_GetBagInfo($bagPtr, 'Slots')
        For $slot = 1 To $slots
            $itemPtr = Item_GetItemBySlot($bag, $slot)
            If $itemPtr = 0 Then ContinueLoop

            ; Skip empty/invalid items
            If Item_GetItemInfoByPtr($itemPtr, "ItemID") = 0 Then ContinueLoop

            $itemModelID = Item_GetItemInfoByPtr($itemPtr, "ModelID")
            If $itemModelID = $targetModelID Then
                $itemQuantity = Item_GetItemInfoByPtr($itemPtr, "Quantity")
                $totalCount += $itemQuantity
            EndIf
        Next
    Next

    Return $totalCount
EndFunc   ;==>GetItemCountByModelID

Func PickUpLoot()
    ;Local $lAgentArray = Item_GetItemArray()
    ;Local $maxitems = $lAgentArray[0]

	Local $lAgentArray = Item_GetItemArray()
	Local $maxitems = IsArray($lAgentArray) ? $lAgentArray[0] : 0


	If GetPartyDead() Then Return
    For $i = 1 To $maxitems
		If GetPartyDead() Then ExitLoop
        Local $aItemPtr = $lAgentArray[$i]
        Local $aItemAgentID = Item_GetItemInfoByPtr($aItemPtr, "AgentID")

        If GetPartyDead() Then ExitLoop
        If $aItemAgentID = 0 Then ContinueLoop ; If Item is not on the ground

        If CanPickUp($aItemPtr) Then
            Item_PickUpItem($aItemAgentID)
            Local $lDeadlock = TimerInit()
            While GetItemAgentExists($aItemAgentID)
                Sleep(100)
                If GetPartyDead() Then ExitLoop
                If TimerDiff($lDeadlock) > 10000 Then ExitLoop
            WEnd
        EndIf
    Next
EndFunc   ;==>PickUpLoot

;~ Description: Test if an Item agent exists.
Func GetItemAgentExists($aItemAgentID)
	Return (Agent_GetAgentPtr($aItemAgentID) > 0 And $aItemAgentID < Item_GetMaxItems())
EndFunc   ;==>GetItemAgentExists

Func CanPickUp($aItemPtr)
	Local $lModelID = Item_GetItemInfoByPtr($aItemPtr, "ModelID")
	Local $aExtraID = Item_GetItemInfoByPtr($aItemPtr, "ExtraID")
	Local $lRarity = Item_GetItemInfoByPtr($aItemPtr, "Rarity")
	If (($lModelID == 2511) And (GetGoldCharacter() < 99000)) Then
		Return True	; gold coins (only pick if character has less than 99k in inventory)
	ElseIf ($lModelID == $ITEM_ID_Dyes) Then	; if dye
		If (($aExtraID == $ITEM_ExtraID_BlackDye) Or ($aExtraID == $ITEM_ExtraID_WhiteDye)) Then ; only pick white and black ones
			Return True
		EndIf
		Return True ; pick all dyes
	ElseIf $lRarity == $RARITY_Gold Then ; gold items
		Return True
	ElseIf $lRarity == $RARITY_Purple Then ; purple items
		Return True
	ElseIf $lRarity == $RARITY_Blue Then ; blue items
		Return True
	ElseIf $lModelID == $ITEM_ID_Lockpicks Then
		Return True
	ElseIf $lModelID == 22269 Then	; Cupcakes
		Return False
	ElseIf IsPreCollectable($aItemPtr) Then
		Return True
	ElseIf IsPcon($aItemPtr) Then ; ==== Pcons ==== or all event items
		Return False
	ElseIf IsRareMaterial($aItemPtr) Then	; rare Mats
		Return False
	Else
		Return False
	EndIf
EndFunc   ;==>CanPickUp

;~ Description: Returns a weapon or shield's minimum required attribute.
Func GetItemReq($aItemPtr)
	Local $lMod = GetModByIdentifier($aItemPtr, "9827")
	Return $lMod[0]
EndFunc   ;==>GetItemReq

;~ Description: Returns a weapon or shield's required attribute.
Func GetItemAttribute($aItem)
	Local $lMod = GetModByIdentifier($aItem, "9827")
	Return $lMod[1]
EndFunc   ;==>GetItemAttribute

;~ Description: Returns an array of a the requested mod.
Func GetModByIdentifier($aItemPtr, $aIdentifier)
	If Not IsPtr($aItemPtr) Then $aItemPtr = Item_GetItemPtr($aItemPtr)
	Local $lReturn[2]
	Local $lString = StringTrimLeft(Item_GetModStruct($aItemPtr), 2)
	For $i = 0 To StringLen($lString) / 8 - 2
		If StringMid($lString, 8 * $i + 5, 4) == $aIdentifier Then
			$lReturn[0] = Int("0x" & StringMid($lString, 8 * $i + 1, 2))
			$lReturn[1] = Int("0x" & StringMid($lString, 8 * $i + 3, 2))
			ExitLoop
		EndIf
	Next
	Return $lReturn
EndFunc   ;==>GetModByIdentifier


Func GetItemMaxDmg($aItem)
	If Not IsPtr($aItem) Then $aItem = Item_GetItemPtr($aItem)
	Local $lModString = Item_GetModStruct($aItem)
	Local $lPos = StringInStr($lModString, "A8A7") ; Weapon Damage
	If $lPos = 0 Then $lPos = StringInStr($lModString, "C867") ; Energy (focus)
	If $lPos = 0 Then $lPos = StringInStr($lModString, "B8A7") ; Armor (shield)
	If $lPos = 0 Then Return 0
	Return Int("0x" & StringMid($lModString, $lPos - 2, 2))
 EndFunc	;==> GetItemMaxDmg

Func GetGoldCharacter()
	Return Item_GetInventoryInfo("GoldCharacter")
EndFunc   ;==>GetGoldCharacter

Func GetGoldStorage()
	Return Item_GetInventoryInfo("GoldStorage")
EndFunc   ;==>GetGoldStorage

Func CheckArrayPscon($lModelID)
	For $p = 0 To (UBound($Array_pscon) -1)
		If ($lModelID == $Array_pscon[$p]) Then Return True
	Next
EndFunc   ;==>CheckArrayPscon

Func InventoryPre()
    Out("Travelling to Ascalon City (Pre-Searing)")
    RndTravel($GC_I_MAP_ID_ASCALON_CITY_OUTPOST)
    
    Sleep(3000)
    
    Out("Moving to Merchant..")
    MerchantAscalonPre()
    Sleep(2000)
    
    If GetGoldCharacter() < 100 Then
        Out("Selling common items to get 100 gold minimum, and free inventory space.")
        For $i = 1 To 4
            PreSell($i)
            If GetGoldCharacter() >= 100 Then ExitLoop
        Next
    EndIf
    
    If GetGoldCharacter() >= 100 Then
        Out("Identifying")
        For $i = 1 To 4
            Ident($i)
        Next
        
        Out("Selling")
        For $i = 1 To 4
            Sell($i)
        Next
    Else
        Out("Not enough gold to buy ID kit, returning...")
        Return
    EndIf
    
    Out("Inventory management complete!")
EndFunc ;==> InventoryPre

Func Inventory()

	Out("Travelling to Eye of the North")
	RndTravel($Town_ID_EyeOfTheNorth)

	$inventorytrigger = 1

	Sleep(1000)

	Out("Move to Merchant")
	MerchantEotN()
	Sleep(2000)

	Out("Identifying")
	For $i = 1 To 4
		Ident($i)
	Next

	Out("Selling")
	For $i = 1 To 4
		Sell($i)
	Next

	If GetGoldCharacter() > 90000 Then
		Out("Depositing Gold")
		Item_DepositGold()
	EndIf

	If FindRareRuneOrInsignia() <> 0 Then
		Out("Salvage all Runes")
		For $i = 1 To 4
			Salvage($i)
		Next
		Out("Second Round of Salvage")
		For $i = 1 To 4
			Salvage($i)
		Next

		Out("Sell leftover items")
		For $i = 1 To 4
			Sell($i)
		Next
	EndIf

	While FindRareRuneOrInsignia() <> 0
		Out("Move to Rune Trader")
		RuneTraderEotN()
		Sleep(2000)

		Out("Sell Runes")
		For $i = 1 To 4
			SellRunes($i)
		Next
		Sleep(2000)

		If GetGoldCharacter() > 20000 Then
			Out("Buying Rare Materials")
			RareMaterialTraderEotN()
		EndIf
	WEnd

	If GetGoldCharacter() > 20000 And GetGoldStorage() > 900000 Then
		Out("Buying Rare Materials")
		RareMaterialTraderEotN()
	EndIf

	Sleep(3000)
EndFunc ;==> Inventory

Func Merchant()
	;~ Array with Coordinates for Merchants (you better check those for your own Guildhall)
	Dim $Waypoints_by_Merchant[29][3] = [ _
			[$BurningIsle, -4439, -2088], _
			[$BurningIsle, -4772, -362], _
			[$BurningIsle, -3637, 1088], _
			[$BurningIsle, -2506, 988], _
			[$DruidsIsle, -2037, 2964], _
			[$FrozenIsle, 99, 2660], _
			[$FrozenIsle, 71, 834], _
			[$FrozenIsle, -299, 79], _
			[$HuntersIsle, 5156, 7789], _
			[$HuntersIsle, 4416, 5656], _
			[$IsleOfTheDead, -4066, -1203], _
			[$NomadsIsle, 5129, 4748], _
			[$WarriorsIsle, 4159, 8540], _
			[$WarriorsIsle, 5575, 9054], _
			[$WizardsIsle, 4288, 8263], _
			[$WizardsIsle, 3583, 9040], _
			[$ImperialIsle, 1415, 12448], _
			[$ImperialIsle, 1746, 11516], _
			[$IsleOfJade, 8825, 3384], _
			[$IsleOfJade, 10142, 3116], _
			[$IsleOfMeditation, -331, 8084], _
			[$IsleOfMeditation, -1745, 8681], _
			[$IsleOfMeditation, -2197, 8076], _
			[$IsleOfWeepingStone, -3095, 8535], _
			[$IsleOfWeepingStone, -3988, 7588], _
			[$CorruptedIsle, -4670, 5630], _
			[$IsleOfSolitude, 2970, 1532], _
			[$IsleOfWurms, 8284, 3578], _
			[$UnchartedIsle, 1503, -2830]]
	For $i = 0 To (UBound($Waypoints_by_Merchant) - 1)
		If ($Waypoints_by_Merchant[$i][0] == True) Then
			MoveTo($Waypoints_by_Merchant[$i][1], $Waypoints_by_Merchant[$i][2])
		EndIf
	Next

	Out("Talk to Merchant")
	Local $guy = GetNearestNPCToAgent(-2, 1320, $GC_I_AGENT_TYPE_LIVING, 1, "NPCFilter")
	MoveTo(Agent_GetAgentInfo($guy, "X")-20,Agent_GetAgentInfo($guy, "Y")-20)
    Agent_GoNPC($guy)
    Sleep(1000)
EndFunc ;==> Merchant

Func MerchantAscalonPre()
	Local $spX = Agent_GetAgentInfo(-2, "X")
    Local $spY = Agent_GetAgentInfo(-2, "Y")
	Local $sp1 = ComputeDistance(8436, 4819, $spX, $spY)

	If $sp1 > 3000 Then MoveTo(8339.99, 6202.35)
	
    MoveTo(8450.46, 4900.70)
    
    Out("Talking to Merchant..")
    Local $guy = GetNearestNPCToAgent(-2, 1320, $GC_I_AGENT_TYPE_LIVING, 1, "NPCFilter")
    MoveTo(Agent_GetAgentInfo($guy, "X") - 20, Agent_GetAgentInfo($guy, "Y") - 20)
    Agent_GoNPC($guy)
    Sleep(1000)
EndFunc ;==> MerchantAscalonPre

Func MerchantEotN()
	; Run to Merchant in EotN
	Out("Run to Merchant in EotN")
	MoveTo(-2660.77, 1162.44)

	Out("Talk to Merchant")
	Local $guy = GetNearestNPCToAgent(-2, 1320, $GC_I_AGENT_TYPE_LIVING, 1, "NPCFilter")
	MoveTo(Agent_GetAgentInfo($guy, "X")-20,Agent_GetAgentInfo($guy, "Y")-20)
    Agent_GoNPC($guy)
    Sleep(1000)
EndFunc ;==> MerchantEotN

Func RareMaterialTrader()
	;~ Array with Coordinates for Merchants (you better check those for your own Guildhall)
	Dim $Waypoints_by_RareMatTrader[36][3] = [ _
			[$BurningIsle, -3793, 1069], _
			[$BurningIsle, -2798, -74], _
			[$DruidsIsle, -989, 4493], _
			[$FrozenIsle, 71, 834], _
			[$FrozenIsle, 99, 2660], _
			[$FrozenIsle, -385, 3254], _
			[$FrozenIsle, -983, 3195], _
			[$HuntersIsle, 3267, 6557], _
			[$IsleOfTheDead, -3415, -1658], _
			[$NomadsIsle, 1930, 4129], _
			[$NomadsIsle, 462, 4094], _
			[$WarriorsIsle, 4108, 8404], _
			[$WarriorsIsle, 3403, 6583], _
			[$WarriorsIsle, 3415, 5617], _
			[$WizardsIsle, 3610, 9619], _
			[$ImperialIsle, 244, 11719], _
			[$IsleOfJade, 8919, 3459], _
			[$IsleOfJade, 6789, 2781], _
			[$IsleOfJade, 6566, 2248], _
			[$IsleOfMeditation, -2197, 8076], _
			[$IsleOfMeditation, -1745, 8681], _
			[$IsleOfMeditation, -331, 8084], _
			[$IsleOfMeditation, 422, 8769], _
			[$IsleOfMeditation, 549, 9531], _
			[$IsleOfWeepingStone, -3988, 7588], _
			[$IsleOfWeepingStone, -3095, 8535], _
			[$IsleOfWeepingStone, -2431, 7946], _
			[$IsleOfWeepingStone, -1618, 8797], _
			[$CorruptedIsle, -4424, 5645], _
			[$CorruptedIsle, -4443, 4679], _
			[$IsleOfSolitude, 3172, 3728], _
			[$IsleOfSolitude, 3221, 4789], _
			[$IsleOfSolitude, 3745, 4542], _
			[$IsleOfWurms, 8353, 2995], _
			[$IsleOfWurms, 6708, 3093], _
			[$UnchartedIsle, 2530, -2403]]
	For $i = 0 To (UBound($Waypoints_by_RareMatTrader) - 1)
		If ($Waypoints_by_RareMatTrader[$i][0] == True) Then
			MoveTo($Waypoints_by_RareMatTrader[$i][1], $Waypoints_by_RareMatTrader[$i][2])
		EndIf
	Next
	Out("Talk to Rare Material Trader")
	Local $guy = GetNearestNPCToAgent(-2, 1320, $GC_I_AGENT_TYPE_LIVING, 1, "NPCFilter")
	MoveTo(Agent_GetAgentInfo($guy, "X")-20,Agent_GetAgentInfo($guy, "Y")-20)
    Agent_GoNPC($guy)
    Sleep(1000)
	;~This section does the buying
	While GetGoldStorage() > 900*1000 Or GetGoldCharacter() > 10*1000
		If GetGoldCharacter() > 10*1000 Then
			Merchant_RequestQuote(930)
			Sleep(500)
			Merchant_TraderBuy()
			Sleep(500)
		Elseif GetGoldStorage() > 900*1000 Then
			Item_WithdrawGold()
			Sleep(1000)
		EndIf
	WEnd
EndFunc	;==>Rare Material trader

Func RareMaterialTraderEotN()
	Out("Run to Rare Material Trader in EotN")
	MoveTo(-2216.90, 1083.70)

	Out("Talk to Rare Material Trader")
	Local $guy = GetNearestNPCToAgent(-2, 1320, $GC_I_AGENT_TYPE_LIVING, 1, "NPCFilter")
	MoveTo(Agent_GetAgentInfo($guy, "X")-20,Agent_GetAgentInfo($guy, "Y")-20)
    Agent_GoNPC($guy)
    Sleep(1000)
	
	;~This section does the buying
	While GetGoldStorage() > 900*1000 Or GetGoldCharacter() > 10*1000
		If GetGoldCharacter() > 10*1000 Then
			Merchant_BuyItem($Ectoplasm_ID, 1, True)
			;Merchant_RequestQuote(930)
			;Sleep(500)
			;Merchant_TraderBuy()
			;Sleep(500)
		Elseif GetGoldStorage() > 900*1000 Then
			Item_WithdrawGold()
			Sleep(1000)
		EndIf
	WEnd
EndFunc	;==> RareMaterialTraderEotN

Func RuneTrader()
	MoveTo(1297.07,11389.97)
	MoveTo(905.74,11655.34)
	Out("Talk to Rune Trader")
	Local $guy = GetNearestNPCToAgent(-2, 1320, $GC_I_AGENT_TYPE_LIVING, 1, "NPCFilter")
	MoveTo(Agent_GetAgentInfo($guy, "X")-20,Agent_GetAgentInfo($guy, "Y")-20)
    Agent_GoNPC($guy)
    Sleep(1000)
EndFunc	;==> Rune Trader

Func RuneTraderEotN()
	Out("Run to Rune Trader in EotN")
	MoveTo(-3250.18, 2011.88)

	Out("Talk to Rune Trader")
	Local $guy = GetNearestNPCToAgent(-2, 1320, $GC_I_AGENT_TYPE_LIVING, 1, "NPCFilter")
	MoveTo(Agent_GetAgentInfo($guy, "X")-20,Agent_GetAgentInfo($guy, "Y")-20)
    Agent_GoNPC($guy)
    Sleep(1000)
EndFunc	;==> RuneTraderEotN

Func Ident($BagIndex)
	Local $BagPtr
	Local $aItemPtr
	Local $guy = GetNearestNPCToAgent(-2, 1320, $GC_I_AGENT_TYPE_LIVING, 1, "NPCFilter")
	Local $merchantID = Agent_GetAgentInfo($guy, "ID")
	$BagPtr = Item_GetBagPtr($BagIndex)
	For $ii = 1 To Item_GetBagInfo($BagPtr, "Slots")
		If FindIdentificationKit() = 0 Then
			If GetGoldCharacter() < 500 And GetGoldStorage() > 499 Then
				Item_WithdrawGold(500)
				Sleep(1000)
			EndIf
			Local $j = 0
			Do
				Merchant_BuyItem($SupIDKit, 1)
				Sleep(1000)
				$j = $j + 1
			Until FindIdentificationKit() <> 0 Or $j = 3
			If $j = 3 Then ExitLoop
			Sleep(1000)
		EndIf
		$aItemPtr = Item_GetItemBySlot($BagIndex, $ii)
		If Item_GetItemInfoByPtr($aItemPtr, "ItemID") = 0 Then ContinueLoop
		If Item_GetItemInfoByPtr($aItemPtr, "IsIdentified") Then ContinueLoop
		Item_IdentifyItem($aItemPtr, "Superior")
		;IdentifyItem2($aItemPtr, FindIdentificationKit())
		Sleep(250)
	Next
EndFunc ;==>Ident

Func Salvage($BagIndex)
	Local $BagPtr
	Local $aItemPtr
	Local $aItemID
	Local $aSalvageKitID
	$BagPtr = Item_GetBagPtr($BagIndex)
	For $ii = 1 To Item_GetBagInfo($BagPtr, "Slots")
		If FindExpertSalvageKit() = 0 Then
			If GetGoldCharacter() < 400 And GetGoldStorage() > 399 Then
				Item_WithdrawGold(400)
				Sleep(1000)
			EndIf
			Local $j = 0
			Do
				Merchant_BuyItem($ExpertSalvKit, 1)
				Sleep(1000)
				$j = $j + 1
			Until FindExpertSalvageKit() <> 0 Or $j = 3
			If $j = 3 Then ExitLoop
			Sleep(1000)
		EndIf
		$aItemPtr = Item_GetItemBySlot($BagIndex, $ii)
		If Item_GetItemInfoByPtr($aItemPtr, "ItemID") = 0 Then ContinueLoop
		If IsRareRune($aItemPtr) = 0 And IsRareInsignia($aItemPtr) = 0 Then
			Continueloop
		Else
			If IsAlreadySalvaged($aItemPtr) Then ContinueLoop
			If IsRareRune($aItemPtr) Then
				;StartSalvage2($aItemPtr, FindExpertSalvageKit())
				;Sleep(500)
				;Item_SalvageMod(1)
				;Sleep(500)
				Item_SalvageItem($aItemPtr, "Expert", "Suffix")
			ElseIf IsRareInsignia($aItemPtr) Then
				;StartSalvage2($aItemPtr, FindExpertSalvageKit())
				;Sleep(500)
				;Item_SalvageMod(0)
				;Sleep(500)
				Item_SalvageItem($aItemPtr, "Expert", "Prefix")
			Else
				Continueloop
			EndIf
		EndIf
	Next
EndFunc ;==>Salvage

Func IsAlreadySalvaged($aItemPtr)
	Local $modelID
	If Not IsPtr($aItemPtr) Then $aItemPtr = Item_GetItemPtr($aItemPtr)
	
	$modelID = Item_GetItemInfoByPtr($aItemPtr, "ModelID")
	Switch $modelID
		Case 5551	;~ Sup Vigor
			Return True
		Case 903	;~ minor Strength, minor Tactics
			Return True
		Case 904	;~ minor Expertise, minor Marksman
			Return True
		Case 902	;~ minor Healing, minor Prot, minor Divine
			Return True
		Case 900	;~ minor Soul
			Return True
		Case 899	;~ minor Fastcast, minor Insp
			Return True
		Case 901	;~ minor Energy
			Return True
		Case 6327	;~ minor Spawn
			Return True
		Case 15545	;~ minor Scythe, minor Mystic
			Return True
		Case 898	;~ minor Vigor, minor Vitae
			Return True
		Case 3612	;~ major Fastcast
			Return True
		Case 5550	;~ major Vigor
			Return True
		Case 5557	;~ superior Smite
			Return True
		Case 5553	;~ superior Death
			Return True
		Case 5549	;~ superior Dom
			Return True
		Case 5555	;~ superior Air
			Return True
		Case 6329	;~ superior Channel, superior Commu
			Return True
		Case 5551	;~ superior Vigor
			Return True
		Case 19156	;~ Sentinel insignia
			Return True
		Case 19139	;~ Tormentor insignia
			Return True
		Case 19163	;~ Winwalker insignia
			Return True
		Case 19129	;~ Prodigy insignia
			Return True
		Case 19165	;~ Shamans insignia
			Return True
		Case 19127	;~ Nightstalker insignia
			Return True
		Case 19168	;~ Centurions insignia
			Return True
		Case 19135	;~ Blessed insignia
			Return True
	EndSwitch

	Return False
EndFunc	;==> IsAlreadySalvaged

;~ Description: Starts a salvaging session of an item.
Func StartSalvage2($aItem, $aSalvageKit = 0)
    Local $lOffset[4] = [0, 0x18, 0x2C, 0x690]
    Local $lSalvageSessionID = Memory_ReadPtr($g_p_BasePointer, $lOffset)
    Local $lSalvageKit = 0

    If Not IsPtr($aSalvageKit) Then
        $lSalvageKit = Item_GetItemPtr($aSalvageKit)
    Else
        $lSalvageKit = $aSalvageKit
    EndIf
    Sleep(250)
    If $lSalvageKit = 0 Then Return 0

    DllStructSetData($g_d_Salvage, 2, Item_ItemID($aItem))
    DllStructSetData($g_d_Salvage, 3, Item_ItemID($lSalvageKit))
    DllStructSetData($g_d_Salvage, 4, $lSalvageSessionID[1])
    Core_Enqueue($g_p_Salvage, 16)
    Return 1
EndFunc

;~ Description: Identifies an item.
Func IdentifyItem2($aItem, $aIdentKit = 0)
	Local $lItemID = Item_ItemID($aItem)
	Local $lIdentKit = 0

	If Not IsPtr($aIdentKit) Then
		$lIdentKit = Item_GetItemPtr($aIdentKit)
	Else
		$lIdentKit = $aIdentKit
	EndIf
	Sleep(250)

    If Item_GetItemInfoByPtr($aItem, "IsIdentified") Then Return True
    If $lIdentKit = 0 Then Return False

    Core_SendPacket(0xC, $GC_I_HEADER_ITEM_IDENTIFY, Item_ItemID($lIdentKit), $lItemID)

    Local $lDeadlock = TimerInit()
    Do
        Sleep(100)
    Until Item_GetItemInfoByPtr($aItem, "IsIdentified") Or TimerDiff($lDeadlock) > 2500

	If TimerDiff($lDeadlock) > 2500 Then Return False

    Return True
EndFunc   ;==>IdentifyItem

Func FindIdentificationKit()
	Local $lItemPtr
	Local $lKit = 0
	Local $lKitPtr = 0
	Local $lUses = 101
	For $i = 1 To 4
		For $j = 1 To Item_GetBagInfo(Item_GetBagPtr($i), 'Slots')
			$lItemPtr = Item_GetItemBySlot($i, $j)
			Switch Item_GetItemInfoByPtr($lItemPtr, 'ModelID')
				Case 2989
					If Item_GetItemInfoByPtr($lItemPtr, 'Value') / 2 < $lUses Then
						$lKit = Item_GetItemInfoByPtr($lItemPtr, 'ItemID')
						$lUses = Item_GetItemInfoByPtr($lItemPtr, 'Value') / 2
						$lKitPtr = $lItemPtr
					EndIf
				Case 5899
					If Item_GetItemInfoByPtr($lItemPtr, 'Value') / 2.5 < $lUses Then
						$lKit = Item_GetItemInfoByPtr($lItemPtr, 'ItemID')
						$lUses = Item_GetItemInfoByPtr($lItemPtr, 'Value') / 2.5
						$lKitPtr = $lItemPtr
					EndIf
				Case Else
					ContinueLoop
			EndSwitch
		Next
	Next
	Return $lKitPtr
EndFunc   ;==>FindIdentificationKit

Func FindExpertSalvageKit()
	Local $lItemPtr
	Local $lKitPtr = 0
	For $i = 1 To 4
		For $j = 1 To Item_GetBagInfo(Item_GetBagPtr($i), 'Slots')
			$lItemPtr = Item_GetItemBySlot($i, $j)
			Switch Item_GetItemInfoByPtr($lItemPtr, 'ModelID')
				Case 2991
					$lKitPtr = $lItemPtr
				Case Else
					ContinueLoop
			EndSwitch
		Next
	Next
	Return $lKitPtr
EndFunc   ;==>FindExpertSalvageKit

Func FindRareRuneOrInsignia()
	Local $lItemPtr
	For $i = 1 To 4
		For $j = 1 To Item_GetBagInfo(Item_GetBagPtr($i), 'Slots')
			$lItemPtr = Item_GetItemBySlot($i, $j)
			If IsRareRune($lItemPtr) Or IsRareInsignia($lItemPtr) Then Return True
		Next
	Next
	Return False
EndFunc	   ;==>FindSellableRune

Func FindConset()
	Local $lItemPtr
	Local $litemID
	Local $consetItemCounter = 0
	For $i = 1 To 4
		For $j = 1 To Item_GetBagInfo(Item_GetBagPtr($i), 'Slots')
			$lItemPtr = Item_GetItemBySlot($i, $j)
			$lItemID = Item_GetItemInfoByPtr($lItemPtr, 'ModelID')
			For $ii = 0 to UBound($Conset) - 1
				If $litemID = $Conset[$ii] Then
					$consetItemCounter += 1
				EndIf
			Next
		Next
	Next

	If $consetItemCounter = 3 Then Return True
	Return False
EndFunc   ;==>FindConset

Func UseConset()
	Local $lItemPtr
	Local $lItemID

	For $i = 1 To 4
		For $j = 1 To Item_GetBagInfo(Item_GetBagPtr($i), 'Slots')
			$lItemPtr = Item_GetItemBySlot($i, $j)
			$lItemID = Item_GetItemInfoByPtr($lItemPtr, 'ModelID')
			For $ii = 0 to UBound($Conset) - 1
				If $lItemID = $Conset[$ii] Then
					If $ii = 0 And GetEffectTimeRemainingEx(-2, $EffectEssence) = 0 Then
						Item_UseItem($lItemPtr)
						Sleep(250)
					ElseIf $ii = 1 And GetEffectTimeRemainingEx(-2, $EffectArmor) = 0 Then
						Item_UseItem($lItemPtr)
						Sleep(250)
					ElseIf $ii = 2 And GetEffectTimeRemainingEx(-2, $EffectGrail) = 0 Then
						Item_UseItem($lItemPtr)
						Sleep(250)
					Else
						ContinueLoop
					EndIf
				EndIf
			Next
		Next
	Next
	Return
EndFunc	   ;==>UseConset

Func FindSummoningStone()
	Local $lItemPtr
	Local $lItemID
	For $i = 1 To 4
		For $j = 1 To Item_GetBagInfo(Item_GetBagPtr($i), 'Slots')
			$lItemPtr = Item_GetItemBySlot($i, $j)
			$lItemID = Item_GetItemInfoByPtr($lItemPtr, 'ModelID')
			For $ii = 0 to UBound($SummoningStone) - 1
				If $lItemID = $SummoningStone[$ii] Then Return True
			Next
		Next
	Next
	Return False
EndFunc   ;==>FindSummoningStone

Func UseSummoningStone()
	Local $lItemPtr
	Local $litemID
	If GetEffectTimeRemainingEx(-2, 2886) <> 0 Then Return False	; Summoning Sickness
	For $i = 1 To 4
		For $j = 1 To Item_GetBagInfo(Item_GetBagPtr($i), 'Slots')
			$lItemPtr = Item_GetItemBySlot($i, $j)
			$lItemID = Item_GetItemInfoByPtr($lItemPtr, 'ModelID')
			For $ii = 0 to UBound($SummoningStone) - 1
				If $litemID = $SummoningStone[$ii] Then
					Item_UseItem($lItemPtr)
					Sleep(250)
					Return True
				EndIf
			Next
		Next
	Next
	Return False
EndFunc	   ;==>UseSummoningStone

Func DeleteBonusItems()
	Local $lItemPtr
	Local $lItemID
	For $i = 1 To 4
		For $j = 1 To Item_GetBagInfo(Item_GetBagPtr($i), 'Slots')
			$lItemPtr = Item_GetItemBySlot($i, $j)
			If IsBonusJunk($lItemPtr) Then
				Item_DestroyItem($lItemPtr)
			EndIf
		Next
	Next
	Return False
EndFunc   ;==>DeleteBonusItems

Func PreSell($BagIndex)
    Local $aItemPtr
    Local $BagPtr = Item_GetBagPtr($BagIndex)
    For $ii = 1 To Item_GetBagInfo($BagPtr, "Slots")
        $aItemPtr = Item_GetItemBySlot($BagIndex, $ii)
        If Item_GetItemInfoByPtr($aItemPtr, "ItemID") = 0 Then ContinueLoop
        Local $sellable = CanPreSell($aItemPtr)
        Sleep(500)
        If $sellable Then
            Merchant_SellItem($aItemPtr)
        EndIf
        Sleep(250)
		If GetGoldCharacter() >= 100 Then Return
    Next
EndFunc ;==> PreSell

Func Sell($BagIndex)
	Local $aItemPtr
	Local $BagPtr = Item_GetBagPtr($BagIndex)
	For $ii = 1 To Item_GetBagInfo($BagPtr, "Slots")
		$aItemPtr = Item_GetItemBySlot($BagIndex, $ii)
		If Item_GetItemInfoByPtr($aItemPtr, "ItemID") = 0 Then ContinueLoop
		Local $sellable = CanSell($aItemPtr)
		Sleep(500)
		If $sellable Then
			Merchant_SellItem($aItemPtr)
		EndIf
		Sleep(250)
	Next
EndFunc ;==> Sell

Func ScanDyes($dyeID)
	Local $aItemPtr
	Local $BagIndex
	Local $BagPtr
	Local $dyeNumber = 0
	Local $ModelID 
	Local $ExtraID

	For $BagIndex = 1 To 4
		$BagPtr = Item_GetBagPtr($BagIndex)
		For $ii = 1 To Item_GetBagInfo($BagPtr, "Slots")
			$aItemPtr = Item_GetItemBySlot($BagIndex, $ii)
			If Item_GetItemInfoByPtr($aItemPtr, "ItemID") = 0 Then ContinueLoop
			$ModelID = Item_GetItemInfoByPtr($aItemPtr, "ModelID")
			$ExtraID = Item_GetItemInfoByPtr($aItemPtr, "ExtraID")
			If $ModelID == 146 And $ExtraID == $dyeID Then
				$dyeNumber += Item_GetItemInfoByPtr($aItemPtr, "Quantity")
			Else
				ContinueLoop
			EndIf
		Next
	Next
	Return $dyeNumber
EndFunc ;==> ScanDyes


Func SellRunes($BagIndex)
	Local $aItemPtr
	Local $BagPtr = Item_GetBagPtr($BagIndex)
	For $ii = 1 To Item_GetBagInfo($BagPtr, "Slots")
		$aItemPtr = Item_GetItemBySlot($BagIndex, $ii)
		If Item_GetItemInfoByPtr($aItemPtr, "ItemID") = 0 Then ContinueLoop
		Local $sellable = IsSellableInsignia($aItemPtr) + IsSellableRune($aItemPtr)
		Sleep(250)
		If $sellable > 0 Then
			If GetGoldCharacter() > 65000 And GetGoldStorage() <= 935000 Then
				Item_DepositGold(65000)
				Sleep(500)
			ElseIf GetGoldCharacter() > 65000 And GetGoldStorage() > 935000 Then
				ExitLoop
			EndIf

			If IsSupVigor($aItemPtr) Then
				If GetGoldCharacter() > 20000 Then Item_DepositGold()
				Sleep(500)
				If GetGoldCharacter() > 20000 Then ContinueLoop
			EndIf
			Merchant_SellItem($aItemPtr, 1, True)
		EndIf
		Sleep(500)
	Next
EndFunc ;==> SellRunes

Func CanPreSell($aItemPtr)
    Local $lRarity = Item_GetItemInfoByPtr($aItemPtr, "Rarity")
    Local $lIsIdentified = Item_GetItemInfoByPtr($aItemPtr, "IsIdentified")
    
    ; Only sell white (common) items
    If $lRarity <> $RARITY_White Then Return False
    
    ; Don't sell unidentified items (wait for normal Sell)
    If Not $lIsIdentified Then Return False

    Return True
EndFunc ;==> CanPreSell

Func CanSell($aItem)
	Local $IsPurple = IsPurple($aItem)
	Local $IsPreCollectable = IsPreCollectable($aItem)
	Local $RareSkin = IsRareSkin($aItem)
	Local $Pcon = IsPcon($aItem)
	Local $Material = IsRareMaterial($aItem)
	Local $IsSpecial = IsSpecialItem($aItem)
	Local $IsCaster = IsPerfectCaster($aItem)
	Local $IsStaff = IsPerfectStaff($aItem)
	Local $IsShield = IsPerfectShield($aItem)
	Local $IsRune = IsRareRune($aItem)
	Local $IsInsignia = IsRareInsignia($aItem)
	Local $IsReq8 = IsReq8Max($aItem)
	Local $IsReq7 = IsReq7Max($aItem)
	Local $IsTome = IsRegularTome($aItem)
	Local $IsEliteTome = IsEliteTome($aItem)
	Local $IsTyriaAnniSkin = IsTyriaAnniSkin($aItem)
	Local $IsCanthaAnniSkin = IsCanthaAnniSkin($aItem)
	Local $IsElonaAnniSkin = IsElonaAnniSkin($aItem)
	Local $IsEotnAnniSkin = IsEotnAnniSkin($aItem)
	Local $IsAnyCampAnniSkin = IsAnyCampAnniSkin($aItem)
  
	Switch $IsPurple
	Case True
	   Return False ; Is purple
	EndSwitch

	Switch $IsPreCollectable
	Case True
	   Return False ; Is pre-collectable
	EndSwitch
 
	Switch $IsSpecial
	Case True
	   Return False ; Is special item (Ecto, TOT, etc)
	EndSwitch
 
	Switch $Pcon
	Case True
	   Return False ; Is a Pcon
	EndSwitch
 
	Switch $Material
	Case True
	   Return False ; Is rare material
	EndSwitch
 
	Switch $IsShield
	Case True
	   Return False ; Is perfect shield
	EndSwitch
 
	Switch $IsReq8
	Case True
	   Return False ; Is req8 max
	EndSwitch
 
	Switch $IsReq7
	Case True
	   Return False ; Is req7 max (15armor)
	EndSwitch
 
	Switch $IsRune
	Case True
	   Return False
	EndSwitch

	Switch $IsInsignia
	Case True
	   Return False
	EndSwitch

	Switch $IsTome
	Case True
	   Return False
	EndSwitch
 
	Switch $IsEliteTome
	Case True
	   Return False
	EndSwitch
 
	Switch $RareSkin
	Case True
	   Return True
	EndSwitch

	Switch $IsTyriaAnniSkin
	Case True
	   Return True
	EndSwitch

	Switch $IsCanthaAnniSkin
	Case True
	   Return True
	EndSwitch

	Switch $IsElonaAnniSkin
	Case True
	   Return True
	EndSwitch

	Switch $IsEotnAnniSkin
	Case True
	   Return True
	EndSwitch

	Switch $IsAnyCampAnniSkin
	Case True
	   Return True
	EndSwitch
 
	Return True
  EndFunc ;==> CanSell
#EndRegion

#Region Items
Func IsPurple($aItem)
	Local $lRarity = Item_GetItemInfoByPtr($aItem, "Rarity")
	
	If $lRarity = $RARITY_Purple Then
		Return $Purple
	EndIf
	Return False
EndFunc ;==> IsPurple

Func IsPreCollectable($aItem)
	Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

	Switch $ModelID
	Case 2994
	   Return True ; Red iris,
	Case 422, 424, 426, 428 ; Collector mats
        Return $Collector
	EndSwitch
	Return False
EndFunc ;==> IsPreCollectable

Func IsBonusJunk($aItem)
    Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

    For $i = 0 To UBound($GC_BonusWeapons) - 1
        If $ModelID = $GC_BonusWeapons[$i] Then Return True
    Next

    Return False
EndFunc

Func IsRareSkin($aItem)
	Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

	Switch $ModelID
    Case 399
	   Return True ; Crystallines
    Case 344
	   Return True ; Magmas Shield
    Case 603
	   Return True ; Orrian Earth Staff
    Case 391
	   Return True ; Raven Staff
    Case 926
       Return True ; Cele Scepter All Attribs
    Case 942, 943
	   Return True ; Cele Shields (Str + Tact)
    Case 858, 776, 789
	   Return True ; Paper Fans (Divine, Soul, Energy)
    Case 905
	   Return True ; Divine Scroll (Canthan)
    Case 785
	   Return True ; Celestial Staff all attribs.
    Case 1022, 874, 875
	   Return True ; Jug - DF, SF, ES
    Case 952, 953
	   Return True ; Kappa Shields (Str + Tact)
    Case 736, 735, 778, 777, 871, 872, 741, 870, 873, 871, 872, 869, 744, 1101
	   Return True ; All rare skins from Cantha Mainland
    Case 945, 944, 940, 941, 950, 951, 1320, 1321, 789, 896, 875, 954, 955, 956, 958
	   Return True ; All rare skins from Dragon Moss
    Case 959, 960
	   Return True ; Plagueborn Shields
;~     Case 1026, 1027
;~ 	   Return True ; Plagueborn Focus (ES, DF)
    Case 341
	   Return True ; Stone Summit Shield
    Case 342
	   Return True ; Summit Warlord Shield
    Case 1985
	   Return True ; Eaglecrest Axe
    Case 2048
	   Return True ; Wingcrest Maul
    Case 2071
	   Return True ; Voltaic Spear
    Case 1953, 1954, 1955, 1956, 1957, 1958, 1959, 1960, 1961, 1962, 1963, 1964, 1965, 1966, 1967, 1968, 1969, 1970, 1971, 1972, 1973
	   Return True ; Froggy Scepters
;~     Case 1197, 1556, 1569, 1439, 1563, 1557
	Case 1197, 1556, 1569, 1439, 1563
	   Return True ; Elonian Swords (Colossal, Ornate, Tattooed, Dead, etc)
	Case 1589
		Return True ; Sea Purse Shield
	Case 1469, 1488, 1266
		Return True ; Diamong Aegis mot,com,tac
	Case 1497, 1498, 1268
		Return True ; Iridescent Aegis mot,com,tac
    Case 21439
	   Return True ; Polar Bear
    Case 1896
	   Return True ; Draconic Aegis - Str
    Case 36674
	   Return True ; Envoy Staff (Divine?)
    Case 1976
	   Return True ; Emerald Blade
    Case 1978
	   Return True ; Draconic Scythe
    Case 32823
	   Return True ; Dhuums Soul Reaper
    Case 208
	   Return True ; Ascalon War Hammer
    Case 1315
	   Return True ; Gloom Shield (Str)
    Case 1039
	   Return True ; Zodiac Shield (Str)
    Case 1037
	   Return True ; Exalted Aegis (Str)
    Case 1320
	   Return True ; Guardian Of The Hunt (Str)
    Case 956, 958
	   Return True ; Outcast Shield (Str) / (Tac)
    Case 336
	   Return True ; Shadow Shield (OS - Str)
    Case 120
	   Return True ; Sephis Axe (OS)
    Case 114
	   Return True ; Dwarven Axe (OS)
    Case 118
	   Return True ; Serpent Axe (OS)
    Case 1052
	   Return True ; Darkwing Defender (Str)
    Case 2236
	   Return True ; Enamaled Shield (Tact)
	Case 985
	   Return True ; Dragon Kamas
	Case 396
		Return True ; Brute Sword
	Case 397
		Return True ; Butterfly Sword
	Case 405
		Return True ; Falchion
	Case 400
		Return True ; Fellblade
	Case 402
		Return True ; Fiery Dragon Sword
	Case 406
		Return True ; Flamberge
	Case 407
		Return True ; Forked Sword
	Case 408
		Return True ; Gladius
	Case 412
		Return True ; Long Sword
	Case 416
		Return True ; Scimitar
	Case 417
		Return True ; Shadow Blade
	Case 418
		Return True ; Short Sword
	Case 419
		Return True ; Spatha
	Case 421
		Return True ; Wingblade
	Case 737
		Return True ; Broadsword
	Case 790
		Return True ; Celestial Sword
	Case 791
		Return True ; Crenellated Sword
	Case 739
		Return True ; Dadao Sword
	Case 740
		Return True ; Dusk Blade
	Case 795
		Return True ; Golden Phoenix Blade
	Case 793
		Return True ; Gothic Sword
	Case 1322
		Return True ; Jade Sword
	Case 741
		Return True ; Jitte
	Case 742
		Return True ; Katana
	Case 794
		Return True ; Oni Blade
	Case 796
		Return True ; Plagueborn Sword
	Case 743
		Return True ; Platinum Blade
	Case 744
		Return True ; Shinobi Blade
	Case 797
		Return True ; Sunqua Blade
	Case 792
		Return True ; Wicked Blade
	Case 1042
		Return True ; Vertebreaker
	Case 1043
		Return True ; Zodiac Sword
	EndSwitch
	Return False
EndFunc ;==> IsRareSkin 

Func IsTyriaAnniSkin($aItem)
	Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

	Switch $ModelID
	Case 2017, 2018, 2019, 2020
	   Return True ; Bone Idols
	Case 2444
		Return True ; Canthan Targe
	Case 2100, 2101
		Return True ; Censor Icon
	Case 2012, 2013, 2014, 2015, 2016
		Return True ; Chirmeric Prism
	Case 2011
		Return True ; Ithas Bow
	EndSwitch
	Return False
EndFunc ;==> IsTyriaAnniSkin

Func IsCanthaAnniSkin($aItem)
	Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

	Switch $ModelID
	Case 2460
	   Return True ; Dragon Fangs
	Case 2464, 2465, 2466, 2467
		Return True ; Spirit Binder
	Case 2469, 2470
		Return True ; Japan 1st Anniversary Shield
	EndSwitch
	Return False
EndFunc ;==> IsCanthaAnniSkin

Func IsElonaAnniSkin($aItem)
	Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

	Switch $ModelID
	Case 2471
	   Return True ; Sunspear
	EndSwitch
	Return False
EndFunc ;==> IsElonaAnniSkin

Func IsEotnAnniSkin($aItem)
	Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

	Switch $ModelID
	Case 2472
	   Return True ; Darksteel Longbow
	Case 2473
		Return True ; Glacial Blade
	Case 2474
		Return True ; Glacial Blades
	Case 2475, 2476, 2477, 2478, 2479, 2480, 2481, 2482, 2483, 2484, 2485, 2486, 2487, 2488, 2489, 2490, 2491, 2492, 2493, 2494, 2495
		Return True ; Hourglass Staff
	Case 2102, 2134, 2103
		Return True ; Etched Sword
	Case 2105, 2106
		Return True ; Arced Blade
	Case 2116, 2117
		Return True ; Granite Edge
	Case 1955, 2125, 1956
		Return True ; Stoneblade
	EndSwitch
	Return False
EndFunc ;==> IsEotnAnniSkin

Func IsAnyCampAnniSkin($aItem)
	Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

	Switch $ModelID
	Case 2239
	   Return True ; Bears Sloth
	Case 2070, 2081, 2082, 2084
		Return True ; Foxs Greed
	Case 2440, 2439, 2438
		Return True ; Hogs Gluttony
	Case 2020, 2026, 2027, 2028, 2029, 2030, 2492
		Return True ; Lions Pride
	Case 2009, 2008
		Return True ; Scorpions Lust, Scorpions Bow
	Case 2451, 2452, 2453, 2454
		Return True ; Snakes Envy
	Case 2246, 2424, 2427, 2428, 2429, 2430
		Return True ; Unicorns Wrath
	Case 2010
		Return True ; Black Hawks Lust
	Case 2456, 2457, 2458, 2459
		Return True ; Dragons Envy
	Case 2431, 2432, 2433, 2434
		Return True ; Peacocks Wrath
	Case 2240
		Return True ; Rhinos Sloth
	Case 2442, 2443, 2441
		Return True ; Spiders Gluttony
	Case 2031, 2045, 2047, 2054, 2055
		Return True ; Tigers Pride
	Case 2087, 2088, 2090, 2091, 2092, 2094, 2095
		Return True ; Wolfs Greed
	Case 2133
		Return True ; Furious Bonecrusher
	Case 2435, 2436, 2437
		Return True ; Bronze Guardian
	Case 2447, 2450, 2448
		Return True ; Deaths Head
	Case 2056, 2057, 2066, 2067
		Return True ; Heavens Arch
	Case 2242, 2243, 2244, 2445
		Return True ; Quicksilver
	Case 2021, 2022, 2023, 2024, 2025
		Return True ; Storm Ember
	Case 2461
		Return True ; Omnious Aegis
	EndSwitch
	Return False
EndFunc ;==> IsAnyCampAnniSkin

Func IsPcon($aItem)
	Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

	Switch $ModelID
    Case 910, 2513, 5585, 6049, 6366, 6367, 6375, 15477, 19171, 19172, 19173, 22190, 24593, 28435, 30855, 31145, 31146, 35124, 36682
	   Return True ; Alcohol
    Case 6376, 21809, 21810, 21813, 36683
	   Return True ; Party
    Case 21492, 21812, 22269, 22644, 22752, 28436
	   Return True ; Sweets
    Case 6370, 21488, 21489, 22191, 26784, 28433
	   Return True ; DP Removal
    Case 15837, 21490, 30648, 31020
	   Return True ; Tonic
    EndSwitch
	Return False
EndFunc ;==> IsPcon

Func IsRareMaterial($aItem)
	Local $M = Item_GetItemInfoByPtr($aItem, "ModelID")
	Local $Type = Item_GetItemInfoByPtr($aItem, "ItemType")
 
	If $Type <> 11 Then Return False	; Some items have the same model ID, so the type of rare mats is 11
	Switch $M
	Case 922, 923, 926, 927, 928, 930, 931, 932, 935, 936, 937, 938, 939, 941, 942, 943, 944, 945, 949, 950, 951, 952, 956, 6532, 6533
	   Return True ; Rare Mats
	EndSwitch
	Return False
EndFunc ;==> IsRareMaterial

Func IsSpecialItem($aItem)
	Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")
	Local $ExtraID = Item_GetItemInfoByPtr($aItem, "ExtraID")

	Switch $ModelID
    Case 5656, 18345, 21491, 37765, 21833, 28433, 28434
	   Return True ; Special - ToT etc
    Case 22751
	   Return True ; Lockpicks
    Case 146
	   If $ExtraID = 10 Or $ExtraID = 12 Then
		  Return True ; Black & White Dye
	   Else
		  Return False
	   EndIf
    Case 24353, 24354
	   Return True ; Chalice & Rin Relics
    Case 522
	   Return True ; Dark Remains
    Case 3746, 22280
	   Return True ; Underworld & FOW Scroll
    Case 35121
	   Return True ; War supplies
    Case 36985
	   Return True ; Commendations
	Case 19186, 19187, 19188, 19189
		Return True ; Djinn Essences
    EndSwitch
	Return False
EndFunc	;==> IsSpecialItem

Func IsPerfectCaster($aItem)
	Local $ModStruct = Item_GetModStruct($aItem)
	Local $A = GetItemAttribute($aItem)
    ; Universal mods
    Local $PlusFive = StringInStr($ModStruct, "5320823", 0, 1) ; Mod struct for +5^50
	Local $PlusFiveEnch = StringInStr($ModStruct, "500F822", 0, 1) ; Mod struct for +5wench
	Local $is10Cast = StringInStr($ModStruct, "A0822", 0, 1) ; Mod struct for 10% cast
	Local $is10Recharge = StringInStr($ModStruct, "AA823", 0, 1) ; Mod struct for 10% recharge
	; Ele mods
	Local $Fire20Casting = StringInStr($ModStruct, "0A141822", 0, 1) ; Mod struct for 20% fire
	Local $Fire20Recharge = StringInStr($ModStruct, "0A149823", 0, 1)
	Local $Water20Casting = StringInStr($ModStruct, "0B141822", 0, 1) ; Mod struct for 20% water
	Local $Water20Recharge = StringInStr($ModStruct, "0B149823", 0, 1)
	Local $Air20Casting = StringInStr($ModStruct, "08141822", 0, 1) ; Mod struct for 20% air
	Local $Air20Recharge = StringInStr($ModStruct, "08149823", 0, 1)
	Local $Earth20Casting = StringInStr($ModStruct, "09141822", 0, 1)
	Local $Earth20Recharge = StringInStr($ModStruct, "09149823", 0, 1)
	Local $Energy20Casting = StringInStr($ModStruct, "0C141822", 0, 1)
	Local $Energy20Recharge = StringInStr($ModStruct, "0C149823", 0, 1)
	; Monk mods
	Local $Smiting20Casting = StringInStr($ModStruct, "0E141822", 0, 1) ; Mod struct for 20% smite
	Local $Smiting20Recharge = StringInStr($ModStruct, "0E149823", 0, 1)
	Local $Divine20Casting = StringInStr($ModStruct, "10141822", 0, 1) ; Mod struct for 20% divine
	Local $Divine20Recharge = StringInStr($ModStruct, "10149823", 0, 1)
	Local $Healing20Casting = StringInStr($ModStruct, "0D141822", 0, 1) ; Mod struct for 20% healing
	Local $Healing20Recharge = StringInStr($ModStruct, "0D149823", 0, 1)
	Local $Protection20Casting = StringInStr($ModStruct, "0F141822", 0, 1) ; Mod struct for 20% protection
	Local $Protection20Recharge = StringInStr($ModStruct, "0F149823", 0, 1)
	; Rit mods
	Local $Channeling20Casting = StringInStr($ModStruct, "22141822", 0, 1) ; Mod struct for 20% channeling
	Local $Channeling20Recharge = StringInStr($ModStruct, "22149823", 0, 1)
	Local $Restoration20Casting = StringInStr($ModStruct, "21141822", 0, 1)
	Local $Restoration20Recharge = StringInStr($ModStruct, "21149823", 0, 1)
    Local $Communing20Casting = StringInStr($ModStruct, "20141822", 0, 1)
	Local $Communing20Recharge = StringInStr($ModStruct, "20149823", 0, 1)
    Local $Spawning20Casting = StringInStr($ModStruct, "24141822", 0, 1) ; Spawning - Unconfirmed
	Local $Spawning20Recharge = StringInStr($ModStruct, "24149823", 0, 1) ; Spawning - Unconfirmed
	; Mes mods
    Local $Illusion20Recharge = StringInStr($ModStruct, "01149823", 0, 1)
	Local $Illusion20Casting = StringInStr($ModStruct, "01141822", 0, 1)
	Local $Domination20Casting = StringInStr($ModStruct, "02141822", 0, 1) ; Mod struct for 20% domination
    Local $Domination20Recharge = StringInStr($ModStruct, "02149823", 0, 1) ; Mod struct for 20% domination recharge
    Local $Inspiration20Recharge = StringInStr($ModStruct, "03149823", 0, 1)
	Local $Inspiration20Casting = StringInStr($ModStruct, "03141822", 0, 1)
	; Necro mods
    Local $Death20Casting = StringInStr($ModStruct, "05141822", 0, 1) ; Mod struct for 20% death
	Local $Death20Recharge = StringInStr($ModStruct, "05149823", 0, 1)
    Local $Blood20Recharge = StringInStr($ModStruct, "04149823", 0, 1)
	Local $Blood20Casting = StringInStr($ModStruct, "04141822", 0, 1)
    Local $SoulReap20Recharge = StringInStr($ModStruct, "06149823", 0, 1)
	Local $SoulReap20Casting = StringInStr($ModStruct, "06141822", 0, 1)
    Local $Curses20Recharge = StringInStr($ModStruct, "07149823", 0, 1)
	Local $Curses20Casting = StringInStr($ModStruct, "07141822", 0, 1)

	Switch $A
    Case 1 ; Illusion
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Illusion20Casting > 0 Or $Illusion20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Illusion20Recharge > 0 Or $Illusion20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Illusion20Recharge > 0 Then
		  If $Illusion20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 2 ; Domination
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Domination20Casting > 0 Or $Domination20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Domination20Recharge > 0 Or $Domination20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Domination20Recharge > 0 Then
		  If $Domination20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 3 ; Inspiration
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Inspiration20Casting > 0 Or $Inspiration20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Inspiration20Recharge > 0 Or $Inspiration20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Inspiration20Recharge > 0 Then
		  If $Inspiration20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 4 ; Blood
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Blood20Casting > 0 Or $Blood20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Blood20Recharge > 0 Or $Blood20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Blood20Recharge > 0 Then
		  If $Blood20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 5 ; Death
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Death20Casting > 0 Or $Death20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Death20Recharge > 0 Or $Death20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Death20Recharge > 0 Then
		  If $Death20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 6 ; SoulReap - Doesnt drop?
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $SoulReap20Casting > 0 Or $SoulReap20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $SoulReap20Recharge > 0 Or $SoulReap20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $SoulReap20Recharge > 0 Then
		  If $SoulReap20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 7 ; Curses
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Curses20Casting > 0 Or $Curses20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Curses20Recharge > 0 Or $Curses20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Curses20Recharge > 0 Then
		  If $Curses20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 8 ; Air
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Air20Casting > 0 Or $Air20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Air20Recharge > 0 Or $Air20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Air20Recharge > 0 Then
		  If $Air20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 9 ; Earth
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Earth20Casting > 0 Or $Earth20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Earth20Recharge > 0 Or $Earth20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Earth20Recharge > 0 Then
		  If $Earth20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
       Return False
    Case 10 ; Fire
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Fire20Casting > 0 Or $Fire20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Fire20Recharge > 0 Or $Fire20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Fire20Recharge > 0 Then
		  If $Fire20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
       Return False
    Case 11 ; Water
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Water20Casting > 0 Or $Water20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Water20Recharge > 0 Or $Water20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Water20Recharge > 0 Then
		  If $Water20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 12 ; Energy Storage
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Energy20Casting > 0 Or $Energy20Recharge > 0 Or $Water20Casting > 0 Or $Water20Recharge > 0 Or $Fire20Casting > 0 Or $Fire20Recharge > 0 Or $Earth20Casting > 0 Or $Earth20Recharge > 0 Or $Air20Casting > 0 Or $Air20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Energy20Recharge > 0 Or $Energy20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Or $Water20Casting > 0 Or $Water20Recharge > 0 Or $Fire20Casting > 0 Or $Fire20Recharge > 0 Or $Earth20Casting > 0 Or $Earth20Recharge > 0 Or $Air20Casting > 0 Or $Air20Recharge > 0 Then
		     Return True
		  EndIf
       EndIf
	   If $Energy20Recharge > 0 Then
		  If $Energy20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $is10Cast > 0 Or $is10Recharge > 0 Then
		  If $Water20Casting > 0 Or $Water20Recharge > 0 Or $Fire20Casting > 0 Or $Fire20Recharge > 0 Or $Earth20Casting > 0 Or $Earth20Recharge > 0 Or $Air20Casting > 0 Or $Air20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 13 ; Healing
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Healing20Casting > 0 Or $Healing20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Healing20Recharge > 0 Or $Healing20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Healing20Recharge > 0 Then
		  If $Healing20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 14 ; Smiting
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Smiting20Recharge > 0 Or $Smiting20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Smiting20Recharge > 0 Then
		  If $Smiting20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 15 ; Protection
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Protection20Recharge > 0 Or $Protection20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Protection20Recharge > 0 Then
		  If $Protection20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 16 ; Divine
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Divine20Casting > 0 Or $Divine20Recharge > 0 Or $Healing20Casting > 0 Or $Healing20Recharge > 0 Or $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Or $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Divine20Recharge > 0 Or $Divine20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Or $Healing20Casting > 0 Or $Healing20Recharge > 0 Or $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Or $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Divine20Recharge > 0 Then
		  If $Divine20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $is10Cast > 0 Or $is10Recharge > 0 Then
		  If $Healing20Casting > 0 Or $Healing20Recharge > 0 Or $Smiting20Casting > 0 Or $Smiting20Recharge > 0 Or $Protection20Casting > 0 Or $Protection20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 32 ; Communing
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Communing20Casting > 0 Or $Communing20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Communing20Recharge > 0 Or $Communing20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Communing20Recharge > 0 Then
		  If $Communing20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
	Case 33 ; Restoration
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Restoration20Casting > 0 Or $Restoration20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Restoration20Recharge > 0 Or $Restoration20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Restoration20Recharge > 0 Then
		  If $Restoration20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 34 ; Channeling
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Channeling20Casting > 0 Or $Channeling20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Channeling20Recharge > 0 Or $Channeling20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Channeling20Recharge > 0 Then
		  If $Channeling20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    Case 36 ; Spawning - Unconfirmed
	   If $PlusFive > 0 Or $PlusFiveEnch > 0 Then
		  If $Spawning20Casting > 0 Or $Spawning20Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Spawning20Recharge > 0 Or $Spawning20Casting > 0 Then
		  If $is10Cast > 0 Or $is10Recharge > 0 Then
		     Return True
		  EndIf
	   EndIf
	   If $Spawning20Recharge > 0 Then
		  If $Spawning20Casting > 0 Then
		     Return True
		  EndIf
	   EndIf
	   Return False
    EndSwitch
    Return False
EndFunc ;==> IsPerfectCaster

Func IsPerfectStaff($aItem)
	Local $ModStruct = Item_GetModStruct($aItem)
	Local $A = GetItemAttribute($aItem)
	; Ele mods
	Local $Fire20Casting = StringInStr($ModStruct, "0A141822", 0, 1) ; Mod struct for 20% fire
	Local $Water20Casting = StringInStr($ModStruct, "0B141822", 0, 1) ; Mod struct for 20% water
	Local $Air20Casting = StringInStr($ModStruct, "08141822", 0, 1) ; Mod struct for 20% air
	Local $Earth20Casting = StringInStr($ModStruct, "09141822", 0, 1) ; Mod Struct for 20% Earth
	Local $Energy20Casting = StringInStr($ModStruct, "0C141822", 0, 1) ; Mod Struct for 20% Energy Storage (Doesnt drop)
	; Monk mods
	Local $Smite20Casting = StringInStr($ModStruct, "0E141822", 0, 1) ; Mod struct for 20% smite
	Local $Divine20Casting = StringInStr($ModStruct, "10141822", 0, 1) ; Mod struct for 20% divine
	Local $Healing20Casting = StringInStr($ModStruct, "0D141822", 0, 1) ; Mod struct for 20% healing
	Local $Protection20Casting = StringInStr($ModStruct, "0F141822", 0, 1) ; Mod struct for 20% protection
	; Rit mods
	Local $Channeling20Casting = StringInStr($ModStruct, "22141822", 0, 1) ; Mod struct for 20% channeling
	Local $Restoration20Casting = StringInStr($ModStruct, "21141822", 0, 1) ; Mod Struct for 20% Restoration
	Local $Communing20Casting = StringInStr($ModStruct, "20141822", 0, 1) ; Mod Struct for 20% Communing
	Local $Spawning20Casting = StringInStr($ModStruct, "24141822", 0, 1) ; Mod Struct for 20% Spawning (Unconfirmed)
	; Mes mods
	Local $Illusion20Casting = StringInStr($ModStruct, "01141822", 0, 1) ; Mod struct for 20% Illusion
	Local $Domination20Casting = StringInStr($ModStruct, "02141822", 0, 1) ; Mod struct for 20% domination
	Local $Inspiration20Casting = StringInStr($ModStruct, "03141822", 0, 1) ; Mod struct for 20% Inspiration
	; Necro mods
	Local $Death20Casting = StringInStr($ModStruct, "05141822", 0, 1) ; Mod struct for 20% death
	Local $Blood20Casting = StringInStr($ModStruct, "04141822", 0, 1) ; Mod Struct for 20% Blood
    Local $SoulReap20Casting = StringInStr($ModStruct, "06141822", 0, 1) ; Mod Struct for 20% Soul Reap (Doesnt drop)
	Local $Curses20Casting = StringInStr($ModStruct, "07141822", 0, 1) ; Mod Struct for 20% Curses

	Switch $A
    Case 1 ; Illusion
	   If $Illusion20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 2 ; Domination
	   If $Domination20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 3 ; Inspiration - Doesnt Drop
	   If $Inspiration20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 4 ; Blood
	   If $Blood20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 5 ; Death
	   If $Death20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 6 ; SoulReap - Doesnt Drop
	   If $SoulReap20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 7 ; Curses
	   If $Curses20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 8 ; Air
	   If $Air20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 9 ; Earth
	   If $Earth20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 10 ; Fire
	   If $Fire20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 11 ; Water
	   If $Water20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 12 ; Energy Storage
	   If $Air20Casting > 0 Or $Earth20Casting > 0 Or $Fire20Casting > 0 Or $Water20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 13 ; Healing
	   If $Healing20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 14 ; Smiting
	   If $Smite20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 15 ; Protection
	   If $Protection20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 16 ; Divine
	   If $Healing20Casting > 0 Or $Protection20Casting > 0 Or $Divine20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 32 ; Communing
	   If $Communing20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 33 ; Restoration
	   If $Restoration20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 34 ; Channeling
	   If $Channeling20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 36 ; Spawning - Unconfirmed
	   If $Spawning20Casting > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
	EndSwitch
	Return False
EndFunc ;==> IsPerfectStaff

Func IsPerfectShield($aItem)
    Local $ModStruct = Item_GetModStruct($aItem)
	; Universal mods
    Local $Plus30 = StringInStr($ModStruct, "1E4823", 0, 1) ; Mod struct for +30 (shield only?)
	Local $Minus3Hex = StringInStr($ModStruct, "3009820", 0, 1) ; Mod struct for -3wHex (shield only?)
	Local $Minus2Stance = StringInStr($ModStruct, "200A820", 0, 1) ; Mod Struct for -2Stance
	Local $Minus2Ench = StringInStr($ModStruct, "2008820", 0, 1) ; Mod struct for -2Ench
	Local $Plus45Stance = StringInStr($ModStruct, "02D8823", 0, 1) ; For +45Stance
	Local $Plus45Ench = StringInStr($ModStruct, "02D6823", 0, 1) ; Mod struct for +45ench
	Local $Plus44Ench = StringInStr($ModStruct, "02C6823", 0, 1) ; For +44/+10Demons
	Local $Minus520 = StringInStr($ModStruct, "5147820", 0, 1) ; For -5(20%)
	; +1 20% Mods ~ Updated 08/10/2018 - FINISHED
	Local $PlusIllusion = StringInStr($ModStruct, "0118240", 0, 1) ; +1 Illu 20%
	Local $PlusDomination = StringInStr($ModStruct, "0218240", 0, 1) ; +1 Dom 20%
	Local $PlusInspiration = StringInStr($ModStruct, "0318240", 0, 1) ; +1 Insp 20%
	Local $PlusBlood = StringInStr($ModStruct, "0418240", 0, 1) ; +1 Blood 20%
	Local $PlusDeath = StringInStr($ModStruct, "0518240", 0, 1) ; +1 Death 20%
	Local $PlusSoulReap = StringInStr($ModStruct, "0618240", 0, 1) ; +1 SoulR 20%
	Local $PlusCurses = StringInStr($ModStruct, "0718240", 0, 1) ; +1 Curses 20%
	Local $PlusAir = StringInStr($ModStruct, "0818240", 0, 1) ; +1 Air 20%
	Local $PlusEarth = StringInStr($ModStruct, "0918240", 0, 1) ; +1 Earth 20%
    Local $PlusFire = StringInStr($ModStruct, "0A18240", 0, 1) ; +1 Fire 20%
	Local $PlusWater = StringInStr($ModStruct, "0B18240", 0, 1) ; +1 Water 20%
	Local $PlusHealing = StringInStr($ModStruct, "0D18240", 0, 1) ; +1 Heal 20%
	Local $PlusSmite = StringInStr($ModStruct, "0E18240", 0, 1) ; +1 Smite 20%
	Local $PlusProt = StringInStr($ModStruct, "0F18240", 0, 1) ; +1 Prot 20%
	Local $PlusDivine = StringInStr($ModStruct, "1018240", 0, 1) ; +1 Divine 20%
	; +10vsMonster Mods
	Local $PlusDemons = StringInStr($ModStruct, "A0848210", 0, 1) ; +10vs Demons
	Local $PlusDragons = StringInStr($ModStruct, "A0948210", 0, 1) ; +10vs Dragons
	Local $PlusPlants = StringInStr($ModStruct, "A0348210", 0, 1) ; +10vs Plants
	Local $PlusUndead = StringInStr($ModStruct, "A0048210", 0, 1) ; +10vs Undead
	Local $PlusTengu = StringInStr($ModStruct, "A0748210", 0, 1) ; +10vs Tengu
    ; New +10vsMonster Mods 07/10/2018 - Thanks to Savsuds
    Local $PlusCharr = StringInStr($ModStruct, "0A014821", 0 ,1) ; +10vs Charr
    Local $PlusTrolls = StringInStr($ModStruct, "0A024821", 0 ,1) ; +10vs Trolls
    Local $PlusSkeletons = StringInStr($ModStruct, "0A044821", 0 ,1) ; +10vs Skeletons
    Local $PlusGiants = StringInStr($ModStruct, "0A054821", 0 ,1) ; +10vs Giants
    Local $PlusDwarves = StringInStr($ModStruct, "0A064821", 0 ,1) ; +10vs Dwarves
    Local $PlusDragons = StringInStr($ModStruct, "0A094821", 0 ,1) ; +10vs Dragons
    Local $PlusOgres = StringInStr($ModStruct, "0A0A4821", 0 ,1) ; +10vs Ogres
	; +10vs Dmg
	Local $PlusPiercing = StringInStr($ModStruct, "A0118210", 0, 1) ; +10vs Piercing
	Local $PlusLightning = StringInStr($ModStruct, "A0418210", 0, 1) ; +10vs Lightning
	Local $PlusVsEarth = StringInStr($ModStruct, "A0B18210", 0, 1) ; +10vs Earth
	Local $PlusCold = StringInStr($ModStruct, "A0318210", 0, 1) ; +10 vs Cold
	Local $PlusSlashing = StringInStr($ModStruct, "A0218210", 0, 1) ; +10vs Slashing
	Local $PlusVsFire = StringInStr($ModStruct, "A0518210", 0, 1) ; +10vs Fire
	; New +10vs Dmg 08/10/2018
	Local $PlusBlunt = StringInStr($ModStruct, "A0018210", 0, 1) ; +10vs Blunt

    If $Plus30 > 0 Then
	   If $PlusDemons > 0 Or $PlusPiercing > 0 Or $PlusDragons > 0 Or $PlusLightning > 0 Or $PlusVsEarth > 0 Or $PlusPlants > 0 Or $PlusCold > 0 Or $PlusUndead > 0 Or $PlusSlashing > 0 Or $PlusTengu > 0 Or $PlusVsFire > 0 Then
	      Return True
	   ElseIf $PlusCharr > 0 Or $PlusTrolls > 0 Or $PlusSkeletons > 0 Or $PlusGiants > 0 Or $PlusDwarves > 0 Or $PlusDragons > 0 Or $PlusOgres > 0 Or $PlusBlunt > 0 Then
		  Return True
	   ElseIf $PlusDomination > 0 Or $PlusDivine > 0 Or $PlusSmite > 0 Or $PlusHealing > 0 Or $PlusProt > 0 Or $PlusFire > 0 Or $PlusWater > 0 Or $PlusAir > 0 Or $PlusEarth > 0 Or $PlusDeath > 0 Or $PlusBlood > 0 Or $PlusIllusion > 0 Or $PlusInspiration > 0 Or $PlusSoulReap > 0 Or $PlusCurses > 0 Then
		  Return True
	   ElseIf $Minus2Stance > 0 Or $Minus2Ench > 0 Or $Minus520 > 0 Or $Minus3Hex > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
	EndIf
    If $Plus45Ench > 0 Then
	   If $PlusDemons > 0 Or $PlusPiercing > 0 Or $PlusDragons > 0 Or $PlusLightning > 0 Or $PlusVsEarth > 0 Or $PlusPlants > 0 Or $PlusCold > 0 Or $PlusUndead > 0 Or $PlusSlashing > 0 Or $PlusTengu > 0 Or $PlusVsFire > 0 Then
	      Return True
	   ElseIf $PlusCharr > 0 Or $PlusTrolls > 0 Or $PlusSkeletons > 0 Or $PlusGiants > 0 Or $PlusDwarves > 0 Or $PlusDragons > 0 Or $PlusOgres > 0 Or $PlusBlunt > 0 Then
		  Return True
	   ElseIf $Minus2Ench > 0 Then
		  Return True
	   ElseIf $PlusDomination > 0 Or $PlusDivine > 0 Or $PlusSmite > 0 Or $PlusHealing > 0 Or $PlusProt > 0 Or $PlusFire > 0 Or $PlusWater > 0 Or $PlusAir > 0 Or $PlusEarth > 0 Or $PlusDeath > 0 Or $PlusBlood > 0 Or $PlusIllusion > 0 Or $PlusInspiration > 0 Or $PlusSoulReap > 0 Or $PlusCurses > 0 Then
		  Return True
	   Else
		  Return False
	   EndIf
	EndIf
	If $Minus2Ench > 0 Then
	   If $PlusDemons > 0 Or $PlusPiercing > 0 Or $PlusDragons > 0 Or $PlusLightning > 0 Or $PlusVsEarth > 0 Or $PlusPlants > 0 Or $PlusCold > 0 Or $PlusUndead > 0 Or $PlusSlashing > 0 Or $PlusTengu > 0 Or $PlusVsFire > 0 Then
		  Return True
	   ElseIf $PlusCharr > 0 Or $PlusTrolls > 0 Or $PlusSkeletons > 0 Or $PlusGiants > 0 Or $PlusDwarves > 0 Or $PlusDragons > 0 Or $PlusOgres > 0 Or $PlusBlunt > 0 Then
		  Return True
	   EndIf
	EndIf
    If $Plus44Ench > 0 Then
	   If $PlusDemons > 0 Then
	      Return True
	   EndIf
	EndIf
    If $Plus45Stance > 0 Then
	   If $Minus2Stance > 0 Then
	      Return True
	   EndIf
	EndIf
	Return False
EndFunc ;==> IsPerfectShield

Func IsRareRune($aItem)
    Local $ModStruct = Item_GetModStruct($aItem)
	Local $SupVigor = StringInStr($ModStruct, "C202EA27", 0, 1) ; Mod struct for Sup vigor rune
	Local $minorStrength = StringInStr($ModStruct, "0111E821", 0, 1) ; minor Strength
	Local $minorTactics = StringInStr($ModStruct, "0115E821", 0, 1) ; minor Tactics
	Local $minorExpertise = StringInStr($ModStruct, "0117E821", 0, 1) ; minor Expertise
	Local $minorMarksman = StringInStr($ModStruct, "0119E821", 0, 1) ; minor Marksman
	Local $minorHealing = StringInStr($ModStruct, "010DE821", 0, 1) ; minor Healing
	Local $minorProt = StringInStr($ModStruct, "010FE821", 0, 1) ; minor Prot
	Local $minorDivine = StringInStr($ModStruct, "0110E821", 0, 1) ; minor Divine
	Local $minorSoul = StringInStr($ModStruct, "0106E821", 0, 1) ; minor Soul
	Local $minorFastcast = StringInStr($ModStruct, "0100E821", 0, 1) ; minor Fastcast
	Local $minorInsp = StringInStr($ModStruct, "0103E821", 0, 1) ; minor Insp
	Local $minorEnergy = StringInStr($ModStruct, "010CE821", 0, 1) ; minor Energy
	Local $minorSpawn = StringInStr($ModStruct, "0124E821", 0, 1) ; minor Spawn
	Local $minorScythe = StringInStr($ModStruct, "0129E821", 0, 1) ; minor Scythe
	Local $minorMystic = StringInStr($ModStruct, "012CE821", 0, 1) ; minor Mystic
	Local $minorVigor = StringInStr($ModStruct, "C202E827", 0, 1) ; minor Vigor
	Local $minorVitae = StringInStr($ModStruct, "12020824", 0, 1) ; minor Vitae

	Local $majorFast = StringInStr($ModStruct, "0200E821", 0, 1) ; major Fastcast
	Local $majorVigor = StringInStr($ModStruct, "C202E927", 0, 1) ; major Vigor

	Local $supSmite = StringInStr($ModStruct, "030EE821", 0, 1) ; superior Smite
	Local $supDeath = StringInStr($ModStruct, "0305E821", 0, 1) ; superior Death
	Local $supDom = StringInStr($ModStruct, "0302E821", 0, 1) ; superior Dom
	Local $supAir = StringInStr($ModStruct, "0308E821", 0, 1) ; superior Air
	Local $supChannel = StringInStr($ModStruct, "0322E821", 0, 1) ; superior Channel
	Local $supCommu = StringInStr($ModStruct, "0320E821", 0, 1) ; superior Commu

	If $minorStrength > 0 Or $minorTactics > 0 Or $minorExpertise > 0 Or $minorMarksman > 0 Or $minorHealing > 0 Or $minorProt > 0 Or $minorDivine > 0 Then 
	   	Return True
	ElseIf $minorSoul > 0 Or $minorFastcast > 0 Or $minorInsp > 0 Or $minorEnergy > 0 Or $minorSpawn > 0 Or $minorScythe > 0 Or $minorMystic > 0 Then
		Return True
	ElseIf $minorVigor > 0 Or $minorVitae > 0 Or $majorFast > 0 Or $majorVigor > 0 Or $supSmite > 0 Or $supDeath > 0 Or $supDom > 0 Then
		Return True
	ElseIf $supAir > 0 Or $supChannel > 0 Or $supCommu > 0 Or $SupVigor > 0 Then
		Return True
	Else
	   Return False
	EndIf
EndFunc ;==> IsRareRune

Func IsSellableRune($aItem)
    Local $ModStruct = Item_GetModStruct($aItem)
	Local $SupVigor = StringInStr($ModStruct, "C202EA27", 0, 1) ; Mod struct for Sup vigor rune
	Local $minorStrength = StringInStr($ModStruct, "0111E821", 0, 1) ; minor Strength
	Local $minorTactics = StringInStr($ModStruct, "0115E821", 0, 1) ; minor Tactics
	Local $minorExpertise = StringInStr($ModStruct, "0117E821", 0, 1) ; minor Expertise
	Local $minorMarksman = StringInStr($ModStruct, "0119E821", 0, 1) ; minor Marksman
	Local $minorHealing = StringInStr($ModStruct, "010DE821", 0, 1) ; minor Healing
	Local $minorProt = StringInStr($ModStruct, "010FE821", 0, 1) ; minor Prot
	Local $minorDivine = StringInStr($ModStruct, "0110E821", 0, 1) ; minor Divine
	Local $minorSoul = StringInStr($ModStruct, "0106E821", 0, 1) ; minor Soul
	Local $minorFastcast = StringInStr($ModStruct, "0100E821", 0, 1) ; minor Fastcast
	Local $minorInsp = StringInStr($ModStruct, "0103E821", 0, 1) ; minor Insp
	Local $minorEnergy = StringInStr($ModStruct, "010CE821", 0, 1) ; minor Energy
	Local $minorSpawn = StringInStr($ModStruct, "0124E821", 0, 1) ; minor Spawn
	Local $minorScythe = StringInStr($ModStruct, "0129E821", 0, 1) ; minor Scythe
	Local $minorMystic = StringInStr($ModStruct, "012CE821", 0, 1) ; minor Mystic
	Local $minorVigor = StringInStr($ModStruct, "C202E827", 0, 1) ; minor Vigor
	Local $minorVitae = StringInStr($ModStruct, "12020824", 0, 1) ; minor Vitae

	Local $majorFast = StringInStr($ModStruct, "0200E821", 0, 1) ; major Fastcast
	Local $majorVigor = StringInStr($ModStruct, "C202E927", 0, 1) ; major Vigor

	Local $supSmite = StringInStr($ModStruct, "030EE821", 0, 1) ; superior Smite
	Local $supDeath = StringInStr($ModStruct, "0305E821", 0, 1) ; superior Death
	Local $supDom = StringInStr($ModStruct, "0302E821", 0, 1) ; superior Dom
	Local $supAir = StringInStr($ModStruct, "0308E821", 0, 1) ; superior Air
	Local $supChannel = StringInStr($ModStruct, "0322E821", 0, 1) ; superior Channel
	Local $supCommu = StringInStr($ModStruct, "0320E821", 0, 1) ; superior Commu

	If $minorStrength > 0 Or $minorTactics > 0 Or $minorExpertise > 0 Or $minorMarksman > 0 Or $minorHealing > 0 Or $minorProt > 0 Or $minorDivine > 0 Then 
		Return True
 	ElseIf $minorSoul > 0 Or $minorFastcast > 0 Or $minorInsp > 0 Or $minorEnergy > 0 Or $minorSpawn > 0 Or $minorScythe > 0 Or $minorMystic > 0 Then
	 	Return True
 	ElseIf $minorVigor > 0 Or $minorVitae > 0 Or $majorFast > 0 Or $majorVigor > 0 Or $supSmite > 0 Or $supDeath > 0 Or $supDom > 0 Then
	 	Return True
	ElseIf $supAir > 0 Or $supChannel > 0 Or $supCommu > 0 Or $SupVigor > 0 Then
		Return True
	Else
	   Return False
	EndIf
EndFunc ;==> IsSellableRune

Func IsSupVigor($aItem)
	Local $ModStruct = Item_GetModStruct($aItem)
	Local $SupVigor = StringInStr($ModStruct, "C202EA27", 0, 1) ; Mod struct for Sup vigor rune

	If $SupVigor > 0 Then
	   Return True
	Else
	   Return False
	EndIf
EndFunc ;==> IsSupVigor


Func IsRareInsignia($aItem)
    Local $ModStruct = Item_GetModStruct($aItem)
	Local $Sentinel = StringInStr($ModStruct, "FB010824", 0, 1) ; Sentinel insig
	Local $Tormentor = StringInStr($ModStruct, "EC010824", 0, 1) ; Tormentor insig
	Local $WindWalker = StringInStr($ModStruct, "02020824", 0, 1) ; Windwalker insig
	Local $Prodigy = StringInStr($ModStruct, "E3010824", 0, 1) ; Prodigy insig
	Local $Shamans = StringInStr($ModStruct, "04020824", 0, 1) ; Shamans insig
	Local $Nightstalker = StringInStr($ModStruct, "E1010824", 0, 1) ; Nightstalker insig
	Local $Centurions = StringInStr($ModStruct, "07020824", 0, 1) ; Centurions insig
	Local $Blessed = StringInStr($ModStruct, "E9010824", 0, 1) ; Blessed insig

	If $Sentinel > 0 Or $Tormentor > 0 Or $WindWalker > 0 Or $Prodigy > 0 Or $Shamans > 0 Or $Nightstalker > 0 Or $Centurions > 0 Or $Blessed > 0 Then
	   Return True
	Else
	   Return False
	EndIf
EndFunc ;==> IsRareInsignia

Func IsSellableInsignia($aItem)
    Local $ModStruct = Item_GetModStruct($aItem)
	Local $Sentinel = StringInStr($ModStruct, "FB010824", 0, 1) ; Sentinel insig
	Local $Tormentor = StringInStr($ModStruct, "EC010824", 0, 1) ; Tormentor insig
	Local $WindWalker = StringInStr($ModStruct, "02020824", 0, 1) ; Windwalker insig
	Local $Prodigy = StringInStr($ModStruct, "E3010824", 0, 1) ; Prodigy insig
	Local $Shamans = StringInStr($ModStruct, "04020824", 0, 1) ; Shamans insig
	Local $Nightstalker = StringInStr($ModStruct, "E1010824", 0, 1) ; Nightstalker insig
	Local $Centurions = StringInStr($ModStruct, "07020824", 0, 1) ; Centurions insig
	Local $Blessed = StringInStr($ModStruct, "E9010824", 0, 1) ; Blessed insig

	If $Sentinel > 0 Or $Tormentor > 0 Or $WindWalker > 0 Or $Prodigy > 0 Or $Shamans > 0 Or $Nightstalker > 0 Or $Centurions > 0 Or $Blessed > 0 Then
	   Return True
	Else
	   Return False
	EndIf
EndFunc ;==> IsSellableInsignia

Func IsReq8Max($aItem)
	Local $Type = Item_GetItemInfoByPtr($aItem, "ItemType")
	Local $Rarity = Item_GetItemInfoByPtr($aItem, "Rarity")
	Local $MaxDmgOffHand = GetItemMaxReq8($aItem)
	Local $MaxDmgShield = GetItemMaxReq8($aItem)
	Local $MaxDmgSword = GetItemMaxReq8($aItem)

	Switch $Rarity
    Case 2624 ;~ Gold
       Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
    Case 2623 ;~ Purple?
	   Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
    Case 2626 ;~ Blue?
	   Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
	EndSwitch
	Return False
EndFunc ;==> IsReq8Max

Func IsReq7Max($aItem)
	Local $Type = Item_GetItemInfoByPtr($aItem, "ItemType")
	Local $Rarity = Item_GetItemInfoByPtr($aItem, "Rarity")
	Local $MaxDmgOffHand = GetItemMaxReq7($aItem)
	Local $MaxDmgShield = GetItemMaxReq7($aItem)
	Local $MaxDmgSword = GetItemMaxReq7($aItem)

	Switch $Rarity
    Case 2624 ;~ Gold
       Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
    Case 2623 ;~ Purple?
	   Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
    Case 2626 ;~ Blue?
	   Switch $Type
	   Case 12 ;~ Offhand
		  If $MaxDmgOffHand = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 24 ;~ Shield
		  If $MaxDmgShield = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   Case 27 ;~ Sword
		  If $MaxDmgSword = True Then
			 Return True
		  Else
			 Return False
		  EndIf
	   EndSwitch
	EndSwitch
	Return False
EndFunc ;==> IsReq7Max

Func GetItemMaxReq8($aItem)
	Local $Type = Item_GetItemInfoByPtr($aItem, "ItemType")
	Local $Dmg = GetItemMaxDmg($aItem)
	Local $Req = GetItemReq($aItem)

	Switch $Type
    Case 12 ;~ Offhand
	   If $Dmg == 12 And $Req == 8 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 24 ;~ Shield
	   If $Dmg == 16 And $Req == 8 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 27 ;~ Sword
	   If $Dmg == 22 And $Req == 8 Then
		  Return True
	   Else
		  Return False
	   EndIf
	EndSwitch
EndFunc ;==> GetItemMaxReq8

Func GetItemMaxReq7($aItem)
	Local $Type = Item_GetItemInfoByPtr($aItem, "ItemType")
	Local $Dmg = GetItemMaxDmg($aItem)
	Local $Req = GetItemReq($aItem)

	Switch $Type
    Case 12 ;~ Offhand
	   If $Dmg == 11 And $Req == 7 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 24 ;~ Shield
	   If $Dmg == 15 And $Req == 7 Then
		  Return True
	   Else
		  Return False
	   EndIf
    Case 27 ;~ Sword
	   If $Dmg == 21 And $Req == 7 Then
		  Return True
	   Else
		  Return False
	   EndIf
	EndSwitch
EndFunc ;==> GetItemMaxReq7

Func IsRegularTome($aItem)
	Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

	Switch $ModelID
    Case 21796, 21797, 21798, 21799, 21800, 21801, 21802, 21803, 21804, 21805
	   Return True
	EndSwitch
	Return False
EndFunc ;==> IsRegularTome

Func IsEliteTome($aItem)
	Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

	Switch $ModelID
    Case 21786, 21787, 21788, 21789, 21790, 21791, 21792, 21793, 21794, 21795
	   Return True ; All Elite Tomes
	EndSwitch
	Return False
EndFunc ;==> IsEliteTome

Func IsFiveE($aItem)
	Local $ModStruct = Item_GetModStruct($aItem)
	Local $t = Item_GetItemInfoByPtr($aItem, "ItemType")
	If (IsIHaveThePower($ModStruct) And $t = 2) Then Return True	; (Nur für Äxte)
EndFunc	;==> IsFiveE

Func IsIHaveThePower($ModStruct)
	Local $EnergyAlways5 = StringInStr($ModStruct, "0500D822", 0 ,1) ; Energy +5
	If $EnergyAlways5 > 0 Then Return True
EndFunc ;==> IsIHaveThePower

Func IsMaxAxe($aItem)
	Local $Type = Item_GetItemInfoByPtr($aItem, "ItemType")
	Local $Dmg = GetItemMaxDmg($aItem)
	Local $Req = GetItemReq($aItem)

	If $Type == 2 And $Dmg == 28 And $Req == 9 Then
		Return True
	Else
		Return False
	EndIf
EndFunc ;==> IsMaxAxe

Func IsMaxDagger($aItem)
	Local $Type = Item_GetItemInfoByPtr($aItem, "ItemType")
	Local $Dmg = GetItemMaxDmg($aItem)
	Local $Req = GetItemReq($aItem)

	If $Type == 32 And $Dmg == 17 And $Req == 9 Then
		Return True
	Else
		Return False
	EndIf
EndFunc ;==> IsMaxDagger

#EndRegion

#Region Checking Guild Hall
;~ Checks to see which Guild Hall you are in and the spawn point
Func CheckGuildHall()
	If Map_GetMapID() == $GH_ID_Warriors_Isle Then
		$WarriorsIsle = True
		Out("Warrior's Isle")
	EndIf
	If Map_GetMapID() == $GH_ID_Hunters_Isle Then
		$HuntersIsle = True
		Out("Hunter's Isle")
	EndIf
	If Map_GetMapID() == $GH_ID_Wizards_Isle Then
		$WizardsIsle = True
		Out("Wizard's Isle")
	EndIf
	If Map_GetMapID() == $GH_ID_Burning_Isle Then
		$BurningIsle = True
		Out("Burning Isle")
	EndIf
	If Map_GetMapID() == $GH_ID_Frozen_Isle Then
		$FrozenIsle = True
		Out("Frozen Isle")
	EndIf
	If Map_GetMapID() == $GH_ID_Nomads_Isle Then
		$NomadsIsle = True
		Out("Nomad's Isle")
	EndIf
	If Map_GetMapID() == $GH_ID_Druids_Isle Then
		$DruidsIsle = True
		Out("Druid's Isle")
	EndIf
	If Map_GetMapID() == $GH_ID_Isle_Of_The_Dead Then
		$IsleOfTheDead = True
		Out("Isle of the Dead")
	EndIf
	If Map_GetMapID() == $GH_ID_Isle_Of_Weeping_Stone Then
		$IsleOfWeepingStone = True
		Out("Isle of Weeping Stone")
	EndIf
	If Map_GetMapID() == $GH_ID_Isle_Of_Jade Then
		$IsleOfJade = True
		Out("Isle of Jade")
	EndIf
	If Map_GetMapID() == $GH_ID_Imperial_Isle Then
		$ImperialIsle = True
		Out("Imperial Isle")
	EndIf
	If Map_GetMapID() == $GH_ID_Isle_Of_Meditation Then
		$IsleOfMeditation = True
		Out("Isle of Meditation")
	EndIf
	If Map_GetMapID() == $GH_ID_Uncharted_Isle Then
		$UnchartedIsle = True
		Out("Uncharted Isle")
	EndIf
	If Map_GetMapID() == $GH_ID_Isle_Of_Wurms Then
		$IsleOfWurms = True
		Out("Isle of Wurms")
		If $IsleOfWurms = True Then
			CheckIsleOfWurms()
		EndIf
	EndIf
	If Map_GetMapID() == $GH_ID_Corrupted_Isle Then
		$CorruptedIsle = True
		Out("Corrupted Isle")
		If $CorruptedIsle = True Then
			CheckCorruptedIsle()
		EndIf
	EndIf
	If Map_GetMapID() == $GH_ID_Isle_Of_Solitude Then
		$IsleOfSolitude = True
		Out("Isle of Solitude")
	EndIf
EndFunc ;~ Check Guild halls


#Region Luxon and Kurzick Points
Func GetKurzickFaction()
	Local $currentKurzFaction = World_GetWorldInfo("CurrentKurzick")
	Return $currentKurzFaction
EndFunc ;==> GetKurzickPoints

Func GetMaxKurzickFaction()
	Local $maxKurzFaction = World_GetWorldInfo("MaxKurzickPoints")
	Return $maxKurzFaction
EndFunc ;==> GetMaxKurzickPoints

Func GetKurzickTitlePoints()
	Local $currentKurzPoints = Title_GetTitleInfo($GC_E_TITLEID_KURZICK, "CurrentPoints")
	Return $currentKurzPoints
EndFunc ;==> GetKurzickTitlePoints

Func GetKurzickTitle()
	Local $currentKurzPoints = Title_GetTitleInfo($GC_E_TITLEID_KURZICK, "CurrentPoints")

	If $currentKurzPoints < 100000 Then
		Return 0
	ElseIf $currentKurzPoints < 250000 Then
		Return 1
	ElseIf $currentKurzPoints < 400000 Then
		Return 2
	ElseIf $currentKurzPoints < 550000 Then
		Return 3
	ElseIf $currentKurzPoints < 875000 Then
		Return 4
	ElseIf $currentKurzPoints < 1200000 Then
		Return 5
	ElseIf $currentKurzPoints < 1850000 Then
		Return 6
	ElseIf $currentKurzPoints < 2500000 Then
		Return 7
	ElseIf $currentKurzPoints < 3750000 Then
		Return 8
	ElseIf $currentKurzPoints < 5000000 Then
		Return 9
	ElseIf $currentKurzPoints < 7500000 Then
		Return 10
	ElseIf $currentKurzPoints < 10000000 Then
		Return 11
	Else
		Return 12
	EndIf
EndFunc ;==> GetKurzickTitle

Func GetLuxonFaction()
	Local $currentLuxFaction = World_GetWorldInfo("CurrentLuxon")
	Return $currentLuxFaction
EndFunc ;==> GetLuxonPoints

Func GetMaxLuxonFaction()
	Local $maxLuxFaction = World_GetWorldInfo("MaxLuxonPoints")
	Return $maxLuxFaction
EndFunc ;==> GetMaxLuxonPoints

Func GetLuxonTitlePoints()
	Local $currentLuxonPoints = Title_GetTitleInfo($GC_E_TITLEID_LUXON, "CurrentPoints")
	Return $currentLuxonPoints
EndFunc ;==> GetLuxonTitlePoints

Func GetLuxonTitle()
	Local $currentLuxonPoints = Title_GetTitleInfo($GC_E_TITLEID_LUXON, "CurrentPoints")

	If $currentLuxonPoints < 100000 Then
		Return 0
	ElseIf $currentLuxonPoints < 250000 Then
		Return 1
	ElseIf $currentLuxonPoints < 400000 Then
		Return 2
	ElseIf $currentLuxonPoints < 550000 Then
		Return 3
	ElseIf $currentLuxonPoints < 875000 Then
		Return 4
	ElseIf $currentLuxonPoints < 1200000 Then
		Return 5
	ElseIf $currentLuxonPoints < 1850000 Then
		Return 6
	ElseIf $currentLuxonPoints < 2500000 Then
		Return 7
	ElseIf $currentLuxonPoints < 3750000 Then
		Return 8
	ElseIf $currentLuxonPoints < 5000000 Then
		Return 9
	ElseIf $currentLuxonPoints < 7500000 Then
		Return 10
	ElseIf $currentLuxonPoints < 10000000 Then
		Return 11
	Else
		Return 12
	EndIf
EndFunc ;==> GetLuxonTitle
#EndRegion


#Region Constants
; ==== Constants ====
Global Enum $DIFFICULTY_NORMAL, $DIFFICULTY_HARD
Global Enum $INSTANCETYPE_OUTPOST, $INSTANCETYPE_EXPLORABLE, $INSTANCETYPE_LOADING
Global Enum $RANGE_ADJACENT=156, $RANGE_NEARBY=240, $RANGE_AREA=312, $RANGE_EARSHOT=1000, $RANGE_SPELLCAST = 1085, $RANGE_SPIRIT = 2500, $RANGE_COMPASS = 5000
Global Enum $RANGE_ADJACENT_2=156^2, $RANGE_NEARBY_2=240^2, $RANGE_AREA_2=312^2, $RANGE_EARSHOT_2=1000^2, $RANGE_SPELLCAST_2=1085^2, $RANGE_SPIRIT_2=2500^2, $RANGE_COMPASS_2=5000^2
Global Enum $PROF_NONE, $PROF_WARRIOR, $PROF_RANGER, $PROF_MONK, $PROF_NECROMANCER, $PROF_MESMER, $PROF_ELEMENTALIST, $PROF_ASSASSIN, $PROF_RITUALIST, $PROF_PARAGON, $PROF_DERVISH

;~ Rez Skills
Global $RezSkillIDs[15]
$RezSkillIDs[0] = 2 ; Resurrection Signet
$RezSkillIDs[1] = 268 ; Unyielding Aura
$RezSkillIDs[2] = 304 ; Light of Dwayna
$RezSkillIDs[3] = 305 ; Resurrect
$RezSkillIDs[4] = 306 ; Rebirth
$RezSkillIDs[5] = 314 ; Restore Life
$RezSkillIDs[6] = 315 ; Vengeance
$RezSkillIDs[7] = 791 ; Flesh of my Flesh
$RezSkillIDs[8] = 963 ; Restoration
$RezSkillIDs[9] = 1128 ; Resurrection Chant
$RezSkillIDs[10] = 1222 ; Lively Was Naomei
$RezSkillIDs[11] = 1263 ; Renew Life
$RezSkillIDs[12] = 1481 ; Death Pact Signet
$RezSkillIDs[13] = 1592 ; "We Shall Return"
$RezSkillIDs[14] = 1778 ; Signet of Return

Global $heroNumberWithRez[0]

;~ Summoning Stones
Global $SummoningStone[20]
$SummoningStone[0] = 37810	; Legionnaire 
$SummoningStone[1] = 30209	; Tengu
$SummoningStone[2] = 30210	; Imperial Guard
$SummoningStone[3] = 35126	; Shining Blade
$SummoningStone[4] = 31156	; Zaishen 
$SummoningStone[5] = 32557	; Ghastly
$SummoningStone[6] = 31155	; Mysterious
$SummoningStone[7] = 30960	; Mystical
$SummoningStone[8] = 30963	; Demonic
$SummoningStone[9] = 34176	; Celestial
$SummoningStone[10] = 30961	; Amber
$SummoningStone[11] = 30966	; Jadeite
$SummoningStone[12] = 30846	; Automaton
$SummoningStone[13] = 30965	; Fossilized
$SummoningStone[14] = 30959	; Chitinous
$SummoningStone[15] = 30964	; Gelatinous
$SummoningStone[16] = 30962	; Arctic
$SummoningStone[17] = 31022	; Mischievous
$SummoningStone[18] = 31023	; Frosty
$SummoningStone[19] = 30847	; Igneous

;~ Conset
Global $Conset[3]
$Conset[0] = 24859	; Essence of Celerity
$Conset[1] = 24860	; Armor of Salvation
$Conset[2] = 24861	; Grail fo Might

Global Const $EffectEssence = 2522
Global Const $EffectArmor = 2520
Global Const $EffectGrail = 2521

;~ Pcons
Global $Pcon[19]
$Pcon[0] = 17060	; Drake Kabob
$Pcon[1] = 17061	; Skalefin Soup
$Pcon[2] = 17062	; Pahnai Salad
$Pcon[3] = 22269	; Birthday Cupcake
$Pcon[4] = 22752	; Golden Egg
$Pcon[5] = 28431	; Candy Apple
$Pcon[6] = 28432	; Candy Corn
$Pcon[7] = 28436	; Slice of Pumpkin Pie
$Pcon[8] = 29425	; Lunar Fortune 2008
$Pcon[9] = 29426	; Lunar Fortune 2009
$Pcon[10] = 29427	; Lunar Fortune 2010
$Pcon[11] = 29428	; Lunar Fortune 2011
$Pcon[12] = 29429	; Lunar Fortune 2012
$Pcon[13] = 29430	; Lunar Fortune 2013
$Pcon[14] = 29431	; Lunar Fortune 2014
$Pcon[15] = 31151	; Blue Rock Candy
$Pcon[16] = 31152	; Green Rock Candy
$Pcon[17] = 31153	; Red Rock Candy
$Pcon[18] = 35121	; War Supplies

Global Const $RARITY_Gold = 2624
Global Const $RARITY_Purple = 2626
Global Const $RARITY_Blue = 2623
Global Const $RARITY_White = 2621

;~ All Weapon mods
Global $Weapon_Mod_Array[25] = [893, 894, 895, 896, 897, 905, 906, 907, 908, 909, 6323, 6331, 15540, 15541, 15542, 15543, 15544, 15551, 15552, 15553, 15554, 15555, 17059, 19122, 19123]

;~ Bonus Weapons
Global Const $GC_I_MODELID_DRAGON_FANGS = 6377
Global Const $GC_I_MODELID_SPIRIT_BINDER = 6507
Global Const $GC_I_MODELID_NEVERMOR = 5831
Global Const $GC_I_MODELID_TIGER_ROAR = 6036
Global Const $GC_I_MODELID_WOLF_FAVOR = 6058
Global Const $GC_I_MODELID_RHINOS_CHARGE = 6060
Global Const $GC_I_MODELID_LUMINESCENT_SCEPTER = 6508
Global Const $GC_I_MODELID_SERRATED_SHIELD = 6514
Global Const $GC_I_MODELID_SOUL_SHRIEKER = 6515
Global Const $GC_I_MODELID_SUNDERING_DARKSTEEL_LONGBOW = 25406
Global Const $GC_I_MODELID_HOURGLASS_STAFF = 25407
Global Const $GC_I_MODELID_GLACIAL_BLADE = 25408

Global Const $GC_BonusWeapons[12] = [ _
    $GC_I_MODELID_DRAGON_FANGS, _
    $GC_I_MODELID_SPIRIT_BINDER, _
    $GC_I_MODELID_NEVERMOR, _
    $GC_I_MODELID_TIGER_ROAR, _
    $GC_I_MODELID_WOLF_FAVOR, _
    $GC_I_MODELID_RHINOS_CHARGE, _
    $GC_I_MODELID_LUMINESCENT_SCEPTER, _
    $GC_I_MODELID_SERRATED_SHIELD, _
    $GC_I_MODELID_SOUL_SHRIEKER, _
    $GC_I_MODELID_SUNDERING_DARKSTEEL_LONGBOW, _
    $GC_I_MODELID_HOURGLASS_STAFF, _
    $GC_I_MODELID_GLACIAL_BLADE _
]

;~ General Items
Global $General_Items_Array[6] = [2989, 2991, 2992, 5899, 5900, 22751]
Global Const $ITEM_ID_Lockpicks = 22751

;~ Dyes
Global Const $ITEM_ID_Dyes = 146
Global Const $ITEM_ExtraID_BlackDye = 10
Global Const $ITEM_ExtraID_WhiteDye = 12

;~ Alcohol
Global $Alcohol_Array[19] = [910, 2513, 5585, 6049, 6366, 6367, 6375, 15477, 19171, 19172, 19173, 22190, 24593, 28435, 30855, 31145, 31146, 35124, 36682]
Global $OnePoint_Alcohol_Array[11] = [910, 5585, 6049, 6367, 6375, 15477, 19171, 19172, 19173, 22190, 28435]
Global $ThreePoint_Alcohol_Array[7] = [2513, 6366, 24593, 30855, 31145, 31146, 35124]
Global $FiftyPoint_Alcohol_Array[1] = [36682]

;~ Party
Global $Spam_Party_Array[5] = [6376, 21809, 21810, 21813, 36683]

;~ Sweets
Global $Spam_Sweet_Array[6] = [21492, 21812, 22269, 22644, 22752, 28436]

;~ Tonics
Global $Tonic_Party_Array[4] = [15837, 21490, 30648, 31020]

;~ DR Removal
Global $DPRemoval_Sweets[6] = [6370, 21488, 21489, 22191, 26784, 28433]

;~ Special Drops
Global $Special_Drops[7] = [5656, 18345, 21491, 37765, 21833, 28433, 28434]

;~ Stupid Drops that I am not using, but in here in case you want these to add these to the CanPickUp and collect in your chest
Global $Map_Piece_Array[4] = [24629, 24630, 24631, 24632]

;~ Stackable Trophies
Global $Stackable_Trophies_Array[1] = [27047]
Global Const $ITEM_ID_Glacial_Stones = 27047

;~ Materials
Global $All_Materials_Array[36] = [921, 922, 923, 925, 926, 927, 928, 929, 930, 931, 932, 933, 934, 935, 936, 937, 938, 939, 940, 941, 942, 943, 944, 945, 946, 948, 949, 950, 951, 952, 953, 954, 955, 956, 6532, 6533]
Global $Common_Materials_Array[11] = [921, 925, 929, 933, 934, 940, 946, 948, 953, 954, 955]
Global $Rare_Materials_Array[25] = [922, 923, 926, 927, 928, 930, 931, 932, 935, 936, 937, 938, 939, 941, 942, 943, 944, 945, 949, 950, 951, 952, 956, 6532, 6533]

;~ Tomes
Global $All_Tomes_Array[20] = [21796, 21797, 21798, 21799, 21800, 21801, 21802, 21803, 21804, 21805, 21786, 21787, 21788, 21789, 21790, 21791, 21792, 21793, 21794, 21795]

;~ Arrays for the title spamming (Not inside this version of the bot, but at least the arrays are made for you)
Global $ModelsAlcohol[100] = [910, 2513, 5585, 6049, 6366, 6367, 6375, 15477, 19171, 22190, 24593, 28435, 30855, 31145, 31146, 35124, 36682]
Global $ModelSweetOutpost[100] = [15528, 15479, 19170, 21492, 21812, 22644, 31150, 35125, 36681]
Global $ModelsSweetPve[100] = [22269, 22644, 28431, 28432, 28436]
Global $ModelsParty[100] = [6368, 6369, 6376, 21809, 21810, 21813]

Global $Array_pscon[39]=[910, 5585, 6366, 6375, 22190, 24593, 28435, 30855, 31145, 35124, 36682, 6376, 21809, 21810, 21813, 36683, 21492, 21812, 22269, 22644, 22752, 28436,15837, 21490, 30648, 31020, 6370, 21488, 21489, 22191, 26784, 28433, 5656, 18345, 21491, 37765, 21833, 28433, 28434]

Global $PIC_MATS[26][2] = [["Fur Square", 941],["Bolt of Linen", 926],["Bolt of Damask", 927],["Bolt of Silk", 928],["Glob of Ectoplasm", 930],["Steel of Ignot", 949],["Deldrimor Steel Ingot", 950],["Monstrous Claws", 923],["Monstrous Eye", 931],["Monstrous Fangs", 932],["Rubies", 937],["Sapphires", 938],["Diamonds", 935],["Onyx Gemstones", 936],["Lumps of Charcoal", 922],["Obsidian Shard", 945],["Tempered Glass Vial", 939],["Leather Squares", 942],["Elonian Leather Square", 943],["Vial of Ink", 944],["Rolls of Parchment", 951],["Rolls of Vellum", 952],["Spiritwood Planks", 956],["Amber Chunk", 6532],["Jadeite Shard", 6533]]

Global $Array_Store_ModelIDs460[147] = [474, 476, 486, 522, 525, 811, 819, 822, 835, 610, 2994, 19185, 22751, 4629, 24630, 4631, 24632, 27033, 27035, 27044, 27046, 27047, 7052, 5123 _
		, 1796, 21797, 21798, 21799, 21800, 21801, 21802, 21803, 21804, 1805, 910, 2513, 5585, 6049, 6366, 6367, 6375, 15477, 19171, 22190, 24593, 28435, 30855, 31145, 31146, 35124, 36682 _
		, 6376 , 6368 , 6369 , 21809 , 21810, 21813, 29436, 29543, 36683, 4730, 15837, 21490, 22192, 30626, 30630, 30638, 30642, 30646, 30648, 31020, 31141, 31142, 31144, 1172, 15528 _
		, 15479, 19170, 21492, 21812, 22269, 22644, 22752, 28431, 28432, 28436, 1150, 35125, 36681, 3256, 3746, 5594, 5595, 5611, 5853, 5975, 5976, 21233, 22279, 22280, 6370, 21488 _
		, 21489, 22191, 35127, 26784, 28433, 18345, 21491, 28434, 35121, 921, 922, 923, 925, 926, 927, 928, 929, 930, 931, 932, 933, 934, 935, 936, 937, 938, 939, 940, 941, 942, 943 _
		, 944, 945, 946, 948, 949, 950, 951, 952, 953, 954, 955, 956, 6532, 6533]

;~ Prophecies
Global $GH_ID_Warriors_Isle = 4
Global $GH_ID_Hunters_Isle = 5
Global $GH_ID_Wizards_Isle = 6
Global $GH_ID_Burning_Isle = 52
Global $GH_ID_Frozen_Isle = 176
Global $GH_ID_Nomads_Isle = 177
Global $GH_ID_Druids_Isle = 178
Global $GH_ID_Isle_Of_The_Dead = 179

;~ Factions
Global $GH_ID_Isle_Of_Weeping_Stone = 275
Global $GH_ID_Isle_Of_Jade = 276
Global $GH_ID_Imperial_Isle = 359
Global $GH_ID_Isle_Of_Meditation = 360

;~ Nightfall
Global $GH_ID_Uncharted_Isle = 529
Global $GH_ID_Isle_Of_Wurms = 530
Global $GH_ID_Corrupted_Isle = 537
Global $GH_ID_Isle_Of_Solitude = 538

Global $WarriorsIsle = False
Global $HuntersIsle = False
Global $WizardsIsle = False
Global $BurningIsle = False
Global $FrozenIsle = False
Global $NomadsIsle = False
Global $DruidsIsle = False
Global $IsleOfTheDead = False
Global $IsleOfWeepingStone = False
Global $IsleOfJade = False
Global $ImperialIsle = False
Global $IsleOfMeditation = False
Global $UnchartedIsle = False
Global $IsleOfWurms = False
Global $CorruptedIsle = False
Global $IsleOfSolitude = False

;~ Identification and Salvaging Stuff
Global Const $SupIDKit = 5899
Global Const $ExpertSalvKit = 2991
Global Const $Ectoplasm_ID = 930

;~ Outpost - Map
Global Const $Town_ID_EyeOfTheNorth = 642

;~ Inventory
Global $inventorytrigger = 0

;~ Coordinates
Global $coords[2]
Global $X
Global $Y

;~ Enemy Model IDs
Global Const $MantisMender = 3714
Global Const $WardenSummer = 3737
Global Const $WardenSeason = 3738

;~ Timer -> For when killing takes too long or enemies are stuck
Global $TimerToKill = 0
#EndRegion

#Region Gui
;Description: Print to console with timestamp
Func Out($TEXT)
    Local $TEXTLEN = StringLen($TEXT)
    Local $CONSOLELEN = _GUICtrlEdit_GetTextLen($g_h_EditText)
    If $TEXTLEN + $CONSOLELEN > 30000 Then GUICtrlSetData($g_h_EditText, StringRight(_GUICtrlEdit_GetText($g_h_EditText), 30000 - $TEXTLEN - 1000))
	_GUICtrlRichEdit_SetCharColor($g_h_EditText, $COLOR_BLACK)
    _GUICtrlEdit_AppendText($g_h_EditText, @CRLF & "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $TEXT)
    _GUICtrlEdit_Scroll($g_h_EditText, 1)
EndFunc

Func FormatElapsedTime($timerHandle)
	If Not IsNumber($timerHandle) Or $timerHandle <= 0 Then
        Return "00:00:00"
    EndIf
    Local $elapsedSeconds = TimerDiff($timerHandle) / 1000
    Local $hours = Int($elapsedSeconds / 3600)
    Local $minutes = Int(Mod($elapsedSeconds, 3600) / 60)
    Local $seconds = Mod($elapsedSeconds, 60)
    Return StringFormat("%02d:%02d:%02d", $hours, $minutes, $seconds)
EndFunc
#EndRegion