#include-once

#Region Calculations
;~ Description: Returns the distance between two coordinate pairs.
Func ComputeDistance($aX1, $aY1, $aX2, $aY2)
    Return Sqrt(($aX1 - $aX2) ^ 2 + ($aY1 - $aY2) ^ 2)
EndFunc   ;==>ComputeDistance

;~ Description: Returns the squared distance (faster, for comparisons) **Must Square the Range aswell.**
Func ComputeDistanceSquared($aX1, $aY1, $aX2, $aY2)
    Local $lDeltaX = $aX1 - $aX2
    Local $lDeltaY = $aY1 - $aY2
    Return $lDeltaX * $lDeltaX + $lDeltaY * $lDeltaY
EndFunc   ;==>ComputeDistanceSquared

Func ATan2($y, $x)
    Return ATan($y / $x) + (($x < 0) ? (($y < 0) ? -3.14159265358979 : 3.14159265358979) : 0)
EndFunc   ;==>ATan2

;~ Description: Returns the distance between two agents.
Func GetDistance($aAgent1 = -1, $aAgent2 = -2)
    If IsDllStruct($aAgent1) = 0 Then $aAgent1 = Agent_GetAgentPtr($aAgent1)
    If IsDllStruct($aAgent2) = 0 Then $aAgent2 = Agent_GetAgentPtr($aAgent2)
    Return Sqrt((Agent_GetAgentInfo($aAgent1, "X") - Agent_GetAgentInfo($aAgent2, "X")) ^ 2 + (Agent_GetAgentInfo($aAgent1, "Y") - Agent_GetAgentInfo($aAgent2, "Y")) ^ 2)
EndFunc   ;==>GetDistance

Func CalculateAverageTime()
    Local $averagetime
    Local $timesum = 0

    For $i = 1 To UBound($AvgTime)
        $timesum += $AvgTime[$i-1]
    Next

    $averagetime = $timesum/UBound($AvgTime)
    $averagetime = Round($averagetime)
    $AvgRunTimeMinutes = Int($averagetime / 60)
    $AvgRunTimeSeconds = Mod($averagetime , 60)
EndFunc   ;==> CalculateAverageTime

Func CalculateFastestTime()
    Local $fastesttime
    Local $currtime

    For $i = 1 To UBound($AvgTime)
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
EndFunc   ;==> CalculateFastestTime
#EndRegion Calculations

#Region Travel
Func RndTravel($aMapID)
    Map_RndTravel($aMapID, True, True, GetSelectedRegion())
EndFunc   ;==>RndTravel
#EndRegion Travel

#Region Other
;~ Description: Resign.
Func Resign()
    Chat_SendChat('resign', '/')
EndFunc   ;==>Resign

Func GetIsDead($aAgent = -2)
    Return Agent_GetAgentInfo($aAgent, "IsDead")
EndFunc   ;==>GetIsDead

Func GetEnergy($aAgent = -2)
    Return Agent_GetAgentInfo($aAgent, "CurrentEnergy")
EndFunc   ;==>GetEnergy

Func GetEnergyPercent($aAgent = -2)
    Return Agent_GetAgentInfo($aAgent, "EnergyPercent")
EndFunc   ;==>GetEnergyPercent
#EndRegion

#Region Movement
Func RunTo($g_ai2_RunPath, $aRandom = 50, $aFightBack = False)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        MoveTo($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], $aRandom, $aFightBack)
        If SurvivorMode(40) Or GetPartyDead() Then Return
    Next
EndFunc   ;==>RunTo

Func RunToUpkeep($g_ai2_RunPath, $upkeepSkills)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        MoveUpkeepEx($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], $upkeepSkills)
    Next
EndFunc   ;==>RunToUpkeep

Func MoveTo($aX, $aY, $aRandom = 50, $aFightBack = False)
    Local $lBlocked = 0
    Local $lMapLoading = Map_GetInstanceInfo("Type"), $lMapLoadingOld
    Local $lDestX = $aX + Random(-$aRandom, $aRandom)
    Local $lDestY = $aY + Random(-$aRandom, $aRandom)

    If GetPartyDead() Then Return
    If SurvivorMode(40) Then Return

    Map_Move($lDestX, $lDestY, 0)

    ; Check for healing on route
    If NeedHeal(95) Then UseHeal()

    Do
        Sleep(100)

        If GetPartyDead() Then Return
        If SurvivorMode(40) Then Return

        $lMapLoadingOld = $lMapLoading
        $lMapLoading = Map_GetInstanceInfo("Type")
        If $lMapLoading <> $lMapLoadingOld Then Return

        ; Check for enemies attacking us and fight back
        If $aFightBack Then
            Local $nearestEnemy = GetNearestEnemyToAgent(-2, 1500, $GC_I_AGENT_TYPE_LIVING, 1, "EnemyFilter")
            If $nearestEnemy <> 0 Then
                If Agent_GetAgentInfo($nearestEnemy, "IsAttacking") Then
                    LogWarn("Enemy is attacking us!")
                    AggroMoveSmartFilter(Agent_GetAgentInfo($nearestEnemy, "X"), Agent_GetAgentInfo($nearestEnemy, "Y"), 1000, 1000)
                EndIf
            EndIf
        EndIf

        ; Check after fightback
        If NeedHeal(95) Then UseHeal()

        If Agent_GetAgentInfo(-2, "MoveX") == 0 And Agent_GetAgentInfo(-2, "MoveY") == 0 Then
            $lBlocked += 1
            $lDestX = $aX + Random(-$aRandom, $aRandom)
            $lDestY = $aY + Random(-$aRandom, $aRandom)
            If $lBlocked == 14 Then
                Chat_SendChat("Stuck", "/")
                If SurvivorMode(40) Then Return
            EndIf

            ; Check for healing in case we get stuck amongst enemies
            If NeedHeal(95) Then UseHeal()

            Map_Move($lDestX, $lDestY, 0)
            If SurvivorMode(40) Then Return
        EndIf
    Until ComputeDistanceSquared(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), $lDestX, $lDestY) < 25 * 25 Or $lBlocked > 20 Or GetPartyDead()
EndFunc   ;==>MoveTo

Func MoveUpkeepEx($aX, $aY, $aUpkeepSkills = 0, $aOrderedSkills = 0, $bCastInOrder = False, $Range = 85, $aRandom = 50)
    If GetPartyDead() Then Return False

    Local $lDestX = $aX + Random(-$aRandom, $aRandom)
    Local $lDestY = $aY + Random(-$aRandom, $aRandom)
    Local $PendingSkills[0]

    While ComputeDistanceSquared(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), $lDestX, $lDestY) > $Range * $Range And Not GetPartyDead()
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
                    If IsRecharged($aOrderedSkills[$i]) Then UseSkillEx($aOrderedSkills[$i], -2)
                    Sleep(150)
                Next
            EndIf
        Else
            If IsArray($aUpkeepSkills) Then
                Local $IsQueued[UBound($aUpkeepSkills)]
                
                For $i = 0 To UBound($aUpkeepSkills) - 1

                    Local $slot = $aUpkeepSkills[$i]
                    Local $aSkill = Skill_GetSkillBarInfo($slot, "SkillID")

                    Local $hasEffect = Agent_GetAgentEffectInfo(-2, $aSkill, "HasEffect")
                    Local $skillDuration = Agent_GetAgentEffectInfo(-2, $aSkill, "Duration")
                    Local $timeRemaining = Agent_GetAgentEffectInfo(-2, $aSkill, "TimeRemaining")

                    Local $recastTime = ($skillDuration * 1000) / 8

                    If Not $hasEffect Or $timeRemaining <= $recastTime Then ; If skill is not active or about to expire, use it if it's recharged
                        If IsRecharged($slot) Then
                            UseSkillEx($slot, -2)
                        Else
                            If Not $IsQueued[$i] Then ; We catch and reapply any skills that weren't recharged
                                $IsQueued[$i] = True
                                _ArrayAdd($PendingSkills, $i)
                            EndIf
                        EndIf
                    EndIf

                    If GetPartyDead() Then Return False

                Next

                For $j = 0 To UBound($PendingSkills) - 1 ; Reapply any missed skills here

                    Local $i = $PendingSkills[$j]
                    Local $slot = $aUpkeepSkills[$i]

                    If IsRecharged($slot) Then
                        UseSkillEx($slot, -2)
                        $IsQueued[$i] = False
                    EndIf
                Next
            EndIf
        EndIf

        Map_Move($lDestX, $lDestY, 0)
        Sleep(100)
    WEnd
EndFunc   ;==>MoveUpkeepEx
#EndRegion

#Region Healing
; Healing skill IDs for Pre-Searing
Global $g_aHealingSkills[8] = [ _
    $GC_I_SKILL_ID_HEALING_SIGNET, _
    $GC_I_SKILL_ID_ORISON_OF_HEALING, _
    $GC_I_SKILL_ID_HEALING_BREEZE, _
    $GC_I_SKILL_ID_DIVINE_HEALING, _
    $GC_I_SKILL_ID_HEAL_AREA, _
    $GC_I_SKILL_ID_REVERSAL_OF_FORTUNE, _
    $GC_I_SKILL_ID_HEALING_SPRING, _
    $GC_I_SKILL_ID_TROLL_UNGUENT  _
]

; Check if skill ID is a healing skill
Func IsHealingSkill($skillID)
    For $i = 0 To UBound($g_aHealingSkills) - 1
        If $skillID = $g_aHealingSkills[$i] Then Return True
    Next
    Return False
EndFunc

; Get first recharged healing skill on bar
Func GetHealOnBar()
    For $slot = 1 To 8
        Local $skillID = Skill_GetSkillbarInfo($slot, "SkillID")
        If IsHealingSkill($skillID) Then
            If IsRecharged($slot) And Not Agent_GetAgentEffectInfo(-2, $skillID, "HasEffect") Then Return $slot
        EndIf
    Next
    Return 0
EndFunc

; Check if HP is below threshold percentage
Func NeedHeal($Threshold = 70)
    If Map_GetInstanceInfo("IsExplorable") Then
        If Agent_GetAgentInfo(-2, 'CurrentHP') <= Agent_GetAgentInfo(-2, 'MaxHP') * ($Threshold / 100) Then
            Return True
        EndIf
    EndIf
    Return False
EndFunc

; Use one healing skill and return
Func UseHeal()
    Local $healSlot = GetHealOnBar()
    If $healSlot = 0 Then Return False
    
    Local $skillID = Skill_GetSkillbarInfo($healSlot, "SkillID")
    Local $skillName = Skill_GetSkillInfo($skillID, "SkillName")
    Local $energyCost = Skill_GetSkillInfo($skillID, "EnergyCost")
    
    Do
        Sleep(250)
    Until GetEnergy(-2) >= $energyCost

    LogWarn("Using healing skill: " & $skillName)
    
    UseSkillEx($healSlot, -2)
    
    Return True
EndFunc
#EndRegion

#Region Fighting
Func AggroMoveSmartFilter($aX, $aY, $AggroRange = 1320, $maxdistance = 3500, $filterArray = 0, $KO = False, $LootRange = 0)

    If GetPartyDead() Then Return
    $TimerToKill = TimerInit()
    Local $iBlocked = 0
    Local $Enemy
    Local $Distance

    Map_Move($aX, $aY)
    $coords[0] = Agent_GetAgentInfo(-2, 'X')
    $coords[1] = Agent_GetAgentInfo(-2, 'Y')
    
    Do
        If GetPartyDead() Then ExitLoop
        Other_RndSleep(250)
        $oldCoords = $coords

        $CurX = Agent_GetAgentInfo(-2, "X")
        $CurY = Agent_GetAgentInfo(-2, "Y")

        ; Check for healing in case some grawl lobbed a brick
        If NeedHeal(70) Then UseHeal()

        If GetNumberOfFoesInRangeOfAgent(-2, $AggroRange, $GC_I_AGENT_TYPE_LIVING, 1, "EnemyFilter") > 0 Then
            If GetPartyDead() Then ExitLoop
            
            $Enemy = GetNearestEnemyToAgent(-2, $AggroRange, $GC_I_AGENT_TYPE_LIVING, 1, "EnemyFilter")
            If GetPartyDead() Then ExitLoop
            $Distance = ComputeDistance(Agent_GetAgentInfo($Enemy, 'X'), Agent_GetAgentInfo($Enemy, 'Y'), Agent_GetAgentInfo(-2, 'X'), Agent_GetAgentInfo(-2, 'Y'))
            If $Distance < $AggroRange And $Enemy <> 0 And Not GetPartyDead() Then
            

                _UAI_Fight($CurX, $CurY, $AggroRange, $maxdistance, $g_i_FinisherMode, 0, $filterArray, $KO)

                If SurvivorMode() Then Return

                Other_RndSleep(250)
                
                ; Check for healing after combat
                If NeedHeal(50) Then UseHeal()

                Other_RndSleep(250)
            EndIf
        EndIf

        If CountSlots() <> 0 and GetPartyDead() = False Then
            If TimerDiff($TimerToKill) > 180000 Then Return
            If $LootRange <> 0 Then
                PickUpLootInRange($LootRange, $CurX, $CurY)
            Else
                PickUpLoot()
            EndIf
        EndIf

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
EndFunc   ;==>AggroMoveSmartFilter

Func _UAI_Fight($a_f_x, $a_f_y, $a_f_AggroRange = 1320, $a_f_MaxDistanceToXY = 3500, _
        $a_i_FightMode = $g_i_FinisherMode, $a_b_SwitchWeaponSets = False, _
        $a_v_PlayerNumber = 0, $a_b_KillOnly = False, _
        $a_s_ExitCallback = "", $a_i_CallTargetMode = $GC_UAI_TARGET_MODE_CALL)

        $g_i_BestTarget = 0
        $g_i_ForceTarget = 0
        $g_i_AttackTarget = 0
        $g_i_LastCalledTarget = 0
        $g_i_FightMode = $a_i_FightMode
        $g_b_CacheWeaponSet = $a_b_SwitchWeaponSets
        $g_i_TargetMode = $a_i_CallTargetMode
        $g_v_AvoidPlayerNumbers = -1

        Local $l_i_MyOldMap = Map_GetMapID(), $l_i_MapLoadingOld = Map_GetInstanceInfo("Type")
        Local $l_v_PriorityTargets = 0

        If IsArray($a_v_PlayerNumber) Then
                Local $l_a_Prio[UBound($a_v_PlayerNumber)]
                Local $l_a_Avoid[UBound($a_v_PlayerNumber)]
                Local $l_i_PC = 0, $l_i_AC = 0
                For $j = 0 To UBound($a_v_PlayerNumber) - 1
                        If $a_v_PlayerNumber[$j] > 0 Then
                                $l_a_Prio[$l_i_PC] = $a_v_PlayerNumber[$j]
                                $l_i_PC += 1
                        ElseIf $a_v_PlayerNumber[$j] < 0 Then
                                $l_a_Avoid[$l_i_AC] = Abs($a_v_PlayerNumber[$j])
                                $l_i_AC += 1
                        EndIf
                Next
                If $l_i_PC > 0 Then
                        ReDim $l_a_Prio[$l_i_PC]
                        $l_v_PriorityTargets = $l_a_Prio
                EndIf
                If $l_i_AC > 0 Then
                        ReDim $l_a_Avoid[$l_i_AC]
                        $g_v_AvoidPlayerNumbers = $l_a_Avoid
                EndIf
        ElseIf $a_v_PlayerNumber > 0 Then
                $l_v_PriorityTargets = $a_v_PlayerNumber
        ElseIf $a_v_PlayerNumber < 0 Then
                $g_v_AvoidPlayerNumbers = Abs($a_v_PlayerNumber)
        EndIf

        Local $l_b_HasPriority = IsArray($l_v_PriorityTargets) Or $l_v_PriorityTargets <> 0

        If $l_b_HasPriority Then
                UAI_UpdateAgentCache($a_f_AggroRange)
                $g_i_ForceTarget = UAI_FindAgentByPlayerNumber($l_v_PriorityTargets, -2, $a_f_AggroRange, "UAI_Filter_IsLivingEnemy")
                If $g_i_ForceTarget = 0 And $a_b_KillOnly Then Return True
        EndIf

        If $g_b_CacheWeaponSet Then UAI_DetermineWeaponSets()

        Do
                If SurvivorMode() Then Return
                If Agent_GetDistanceToXY($a_f_x, $a_f_y) > $a_f_AggroRange Then ExitLoop
                If $g_i_ForceTarget <> 0 And UAI_GetAgentInfoByID($g_i_ForceTarget, $GC_UAI_AGENT_IsDead) Then
                        $g_i_ForceTarget = UAI_FindAgentByPlayerNumber($l_v_PriorityTargets, -2, $a_f_AggroRange, "UAI_Filter_IsLivingEnemy")
                        If $g_i_ForceTarget = 0 And $a_b_KillOnly Then ExitLoop
                EndIf
                If $g_i_TargetMode = $GC_UAI_TARGET_MODE_FOLLOW Then
                        Local $l_i_FollowTarget = UAI_GetPartyCalledTarget()
                        If $l_i_FollowTarget <> 0 Then $g_i_ForceTarget = $l_i_FollowTarget
                EndIf
                _UAI_UseSkills($a_f_x, $a_f_y, $a_f_AggroRange, $a_f_MaxDistanceToXY)
        Until UAI_CountEnemyInPartyAggroRange($a_f_AggroRange) = 0 Or Agent_GetAgentInfo(-2, "IsDead") Or Party_IsWiped() Or Map_GetMapID() <> $l_i_MyOldMap Or Map_GetInstanceInfo("Type") <> $l_i_MapLoadingOld Or ($a_s_ExitCallback <> "" And Call($a_s_ExitCallback))
EndFunc   ;==>_UAI_Fight

Func _UAI_UseSkills($a_f_x, $a_f_y, $a_f_AggroRange = 1320, $a_f_MaxDistanceToXY = 3500)
        For $skillSlot = 1 To 8
                If UAI_GetStaticSkillInfo($skillSlot, $GC_UAI_STATIC_SKILL_SkillID) = 0 Then ContinueLoop
                If SurvivorMode() Then Return

                If $g_b_SkillChanged = True And Cache_EndFormChangeBuild($skillSlot) Then $g_b_SkillChanged = False

;~         UPDATE CACHE FIRST
                UAI_UpdateAgentCache($a_f_AggroRange)

                If Not UAI_IsEnemyInPartyAggroRange($a_f_AggroRange) Then ExitLoop
                If UAI_GetPlayerInfo($GC_UAI_AGENT_IsDead) Or UAI_GetPlayerInfo($GC_UAI_AGENT_IsKnockedDown) Or Map_GetInstanceInfo("Type") <> $GC_I_MAP_TYPE_EXPLORABLE Then ExitLoop
                If SurvivorMode() Then Return

;~ DISTANCE CHECKS
                If $a_f_MaxDistanceToXY <> 0 And Agent_GetDistanceToXY($a_f_x, $a_f_y) > $a_f_MaxDistanceToXY Then ExitLoop

                ; If no enemy is in the player's range but a hero has aggro on one, move toward it. Only chase while the player is still within aggro range of the fight origin.
                If Not UAI_IsAgentInRange(-2, $a_f_AggroRange, "UAI_Filter_IsLivingEnemy|UAI_Filter_IsNotAvoided") _
                                And Agent_GetDistanceToXY($a_f_x, $a_f_y) <= $a_f_AggroRange Then
                        Local $l_i_PartyRangeEnemy = UAI_GetNearestEnemyInPartyRange($a_f_AggroRange)
                        If $l_i_PartyRangeEnemy <> 0 Then
                                Local $l_f_EnemyX = UAI_GetAgentInfoByID($l_i_PartyRangeEnemy, $GC_UAI_AGENT_X)
                                Local $l_f_EnemyY = UAI_GetAgentInfoByID($l_i_PartyRangeEnemy, $GC_UAI_AGENT_Y)
                                Map_Move($l_f_EnemyX, $l_f_EnemyY, 0)
                                Sleep(500)
                        EndIf
                        ExitLoop ; Next call handles the remainder
                EndIf

;~ WEAPON CHECK
                If $g_b_CacheWeaponSet Then UAI_ShouldSwitchWeaponSet()

;~         AUTO ATTACK
                If UAI_CanAutoAttack() Then
                        UAI_AutoAttack($a_f_AggroRange)
                Else
                        If UAI_GetPlayerInfo($GC_UAI_AGENT_IsAttacking) Then Core_ControlAction($GC_I_CONTROL_ACTION_CANCEL_ACTION)
                EndIf
                If SurvivorMode() Then Return

;~         PRIORITY SKILLS
                If UAI_PrioritySkills($a_f_AggroRange) Then
                        Local $l_i_UsedSlot = @extended
                        If $l_i_UsedSlot = $skillSlot Then
                                Sleep(128)
                                ContinueLoop
                        EndIf
                        UAI_UpdateAgentCache($a_f_AggroRange)
                EndIf
                If SurvivorMode() Then Return

;~         BUNDLE TO DROP
                UAI_DropBundle($a_f_AggroRange)
                If SurvivorMode() Then Return

;~         NORMAL SKILLS
                UAI_TryUseSkill($skillSlot, $a_f_AggroRange)
                If SurvivorMode() Then Return

                Sleep(128)
        Next

        Return True
EndFunc   ;==>_UAI_UseSkills

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

        ; Check for healing in case some grawl lobbed a brick
        If NeedHeal(70) Then UseHeal()
        
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
        
        ; Check for healing after combat
        If NeedHeal(50) Then UseHeal()

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

Func FightExFilter($AggroRange, $filterFunc = "EnemyFilter")
    If GetPartyDead() Then Return
    If SurvivorMode() Then Return
    
    Local $target
    Local $distance
    Local $useSkill
    Local $energy
    Local $lastId = 99999, $coordinate[2], $timer

        Do
            If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
            If TimerDiff($TimerToKill) > 180000 Then Exitloop
            If GetPartyDead() Then Exitloop
            If SurvivorMode() Then Return

            ; Check for healing before engaging target
            If NeedHeal(70) Then UseHeal()

            $target = GetNearestEnemyToAgent(-2, 1700, $GC_I_AGENT_TYPE_LIVING, 1, $filterFunc)
            If GetPartyDead() Then Exitloop
            If SurvivorMode() Then Return
            $distance = ComputeDistance(Agent_GetAgentInfo($target, 'X'), Agent_GetAgentInfo($target, 'Y'), Agent_GetAgentInfo(-2, 'X'), Agent_GetAgentInfo(-2, 'Y'))
            
            If $target <> 0 AND $distance < $AggroRange And Not GetPartyDead() Then
                If TimerDiff($TimerToKill) > 180000 Then Exitloop
                
                If Agent_GetAgentInfo($target, 'ID') <> $lastId Then
                    If GetPartyDead() Then Exitloop
                    If SurvivorMode() Then Return
                    
                    Agent_ChangeTarget($target)
                    Other_RndSleep(150)
                    Agent_CallTarget($target)
                    Other_RndSleep(150)
                    
                    ; Check for healing after we've called them stupid
                    If NeedHeal(70) Then UseHeal()

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
                            
                            ; I didn't mean it, I'm sorry..
                            If NeedHeal(70) Then UseHeal()
                            
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
                        
                        ; Check for healing before engaging
                        If NeedHeal(70) Then UseHeal()

                        $target = GetNearestEnemyToAgent(-2, 1700, $GC_I_AGENT_TYPE_LIVING, 1, $filterFunc)
                        If GetPartyDead() Then Exitloop
                        If SurvivorMode() Then Return
                        $distance = GetDistance($target, -2)

                        If $distance < 1250 And Not GetPartyDead() Then
                            If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
                            If TimerDiff($TimerToKill) > 180000 Then Exitloop
                            
                            For $i = 1 To 8
                                If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
                                If TimerDiff($TimerToKill) > 180000 Then Exitloop
                                If GetPartyDead() Then Exitloop
                                If SurvivorMode() Then Return
                                If Agent_GetAgentInfo($target, 'IsDead') Then ExitLoop
                                
                                ; Get skill ID for current slot
                                Local $currentSkillID = Skill_GetSkillbarInfo($i, "SkillID")

                                ; Skip healing skills - they're handled separately
                                If IsHealingSkill($currentSkillID) Then ContinueLoop
                                                                
                                $distance = GetDistance($target, -2)
                                If $distance > $AggroRange Then ExitLoop

                                $energy = GetEnergy(-2)
                                
                                ; Deal with adrenaline skills
                                If IsAdrenal($currentSkillID) Then
                                    If Skill_GetSkillbarInfo($i, "Adrenaline") < Skill_GetSkillInfo($currentSkillID, "Adrenaline") Then ContinueLoop
                                EndIf
                                
                                If IsRecharged($i) And $energy >= Skill_GetSkillInfo(Skill_GetSkillbarInfo($i, "SkillID"), "EnergyCost") And Not GetPartyDead() Then
                                    If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
                                    If TimerDiff($TimerToKill) > 180000 Then Exitloop
                                    $useSkill = $i
                                    
                                    UseSkillEx($useSkill, $target)
                                    Other_RndSleep(150)
                                    If GetPartyDead() Then Exitloop
                                    If SurvivorMode() Then Return
                                    Agent_Attack($target)
                                    Other_RndSleep(150)
                                EndIf

                                If NeedHeal(95) Then UseHeal()

                                If TimerDiff($TimerToKill) > 180000 Then Exitloop
                                If $i = 8 Then $i = 0
                                If GetPartyDead() Then Exitloop
                                If SurvivorMode() Then Return
                            Next
                        EndIf
                        
                        If TimerDiff($TimerToKill) > 180000 Then Exitloop
                        If GetPartyDead() Then Exitloop
                        If SurvivorMode() Then Return
                        Agent_Attack($target)
                        $distance = GetDistance($target, -2)
                    Until Agent_GetAgentInfo($target, 'HP') < 0.005 Or $distance > $AggroRange Or TimerDiff($timer) > 20000 Or GetPartyDead() Or TimerDiff($TimerToKill) > 180000
            EndIf

            If GetNumberOfFoesInRangeOfAgent(-2, 1700) = 0 Then Exitloop
            If TimerDiff($TimerToKill) > 180000 Then Exitloop
            If GetPartyDead() Then Exitloop
            If SurvivorMode() Then Return
            $target = GetNearestEnemyToAgent(-2, 1700, $GC_I_AGENT_TYPE_LIVING, 1, $filterFunc)
            If GetPartyDead() Then Exitloop
            If SurvivorMode() Then Return
            $distance = GetDistance($target, -2)
        Until Agent_GetAgentInfo($target, 'ID') = 0 Or $distance > $AggroRange Or GetPartyDead() Or TimerDiff($TimerToKill) > 180000

        If CountSlots() <> 0 And Not GetPartyDead() Then
            If TimerDiff($TimerToKill) > 180000 Then Return
            PickUpLoot()
        EndIf
EndFunc   ;==>FightExFilter

Func GetPartyDead()
    Return GetIsDead(-2)
EndFunc   ;==>GetPartyDead - This is just because, and thats a 'wrap.'

Func SurvivorMode($Threshold = 65)
    If $Survivor = True Then
        If Agent_GetAgentInfo(-2, 'CurrentHP') <= Agent_GetAgentInfo(-2, 'MaxHP') * ($Threshold / 100) Then
            Return True
        EndIf
    EndIf
    Return False
EndFunc   ;==> SurvivorMode

Func GetMyHP()
    Return Agent_GetAgentInfo(-2, "HPPercent")
EndFunc   ;==> GetMyHP

Func GetEffectTimeRemainingEx($aAgent = -2, $aSkillID = 0, $aInfo = "TimeRemaining")
    Return Agent_GetAgentEffectInfo($aAgent, $aSkillID, $aInfo)
EndFunc   ;==>GetEffectTimeRemainingEx

Func StayAlive()

    Local $timer = TimerInit()
    Local $maxKillTime = 180000
    Local $PendingSkills[0]

    ; Repop Imp
    If Not Agent_GetAgentEffectInfo(-2, 2886, "HasEffect") And Not HasImp(-2) Then
        UseSummoningStone()
    EndIf

    ; Upkeep these skills
    If IsArray($gUpkeepSkills) Then
        Local $IsQueued[UBound($gUpkeepSkills)]

        For $i = 0 To UBound($gUpkeepSkills) - 1

            Local $slot = $gUpkeepSkills[$i]
            Local $aSkill = Skill_GetSkillBarInfo($slot, "SkillID")

            Local $hasEffect = Agent_GetAgentEffectInfo(-2, $aSkill, "HasEffect")
            Local $skillDuration = Agent_GetAgentEffectInfo(-2, $aSkill, "Duration")
            Local $timeRemaining = Agent_GetAgentEffectInfo(-2, $aSkill, "TimeRemaining")

            Local $recastTime = ($skillDuration * 1000) / 8

            If Not $hasEffect Or $timeRemaining <= $recastTime Then ; If skill is not active or about to expire, use it if it's recharged
                If IsRecharged($slot) Then
                    UseSkillEx($slot, -2)
                Else
                    If Not $IsQueued[$i] Then ; We catch and reapply any skills that weren't recharged
                        $IsQueued[$i] = True
                        _ArrayAdd($PendingSkills, $i)
                    EndIf
                EndIf
            EndIf

            If GetPartyDead() Then Return False

        Next

        For $j = 0 To UBound($PendingSkills) - 1 ; Reapply any missed skills here

            Local $i = $PendingSkills[$j]
            Local $slot = $gUpkeepSkills[$i]

            If IsRecharged($slot) Then
                UseSkillEx($slot, -2)
                $IsQueued[$i] = False
            EndIf
        Next
    EndIf
EndFunc   ;==>Stay Alive

Func StayAlive_Kill($refX, $refY, $filterFunc = "EnemyFilter", $range = 2500)

    Local $timer = TimerInit()
    Local $maxKillTime = 180000
    
    Local $target, $targetCaster, $currentDistance, $targetX, $targetY
    Local $myX, $myY, $angle, $newX, $newY

    Local $tolerance = 150
    Local $adjustFactor = 0.6
    Local $desiredDistance = 900
    Local $PendingSkills[0]

    If GetPartyDead() Then Return False

    Switch $filterFunc
        Case "CharrFilter"
            If GetNumberOfCharrInRangeOfXY($refX, $refY, $range) = 0 Then Return True
        Case "EnemyFilter"
            If GetNumberOfFoesInRangeOfAgent(-2, $range) = 0 Then Return True
    EndSwitch

    Do
        ; Repop Imp
        If Not Agent_GetAgentEffectInfo(-2, 2886, "HasEffect") And Not HasImp(-2) Then
            UseSummoningStone()
        EndIf

        ; Upkeep these skills
        If IsArray($gUpkeepSkills) Then
            Local $IsQueued[UBound($gUpkeepSkills)]

            For $i = 0 To UBound($gUpkeepSkills) - 1

                Local $slot = $gUpkeepSkills[$i]
                Local $aSkill = Skill_GetSkillBarInfo($slot, "SkillID")

                Local $hasEffect = Agent_GetAgentEffectInfo(-2, $aSkill, "HasEffect")
                Local $skillDuration = Agent_GetAgentEffectInfo(-2, $aSkill, "Duration")
                Local $timeRemaining = Agent_GetAgentEffectInfo(-2, $aSkill, "TimeRemaining")

                Local $recastTime = ($skillDuration * 1000) / 8

                If Not $hasEffect Or $timeRemaining <= $recastTime Then ; If skill is not active or about to expire, use it if it's recharged
                    If IsRecharged($slot) Then
                        UseSkillEx($slot, -2)
                    Else
                        If Not $IsQueued[$i] Then ; We catch and reapply any skills that weren't recharged
                            $IsQueued[$i] = True
                            _ArrayAdd($PendingSkills, $i)
                        EndIf
                    EndIf
                EndIf

                If GetPartyDead() Then Return False

            Next

            For $j = 0 To UBound($PendingSkills) - 1 ; Reapply any missed skills here

                Local $i = $PendingSkills[$j]
                Local $slot = $gUpkeepSkills[$i]

                If IsRecharged($slot) Then
                    UseSkillEx($slot, -2)
                    $IsQueued[$i] = False
                EndIf
            Next
        EndIf

        If GetNumberOfCharrInRangeOfXY($refX, $refY, $range) = 0 Then Return True

        $targetCaster = GetNearestEnemyToAgent(-2, $range, $GC_I_AGENT_TYPE_LIVING, 1, "CharrCasterFilter")
        
        $target = GetNearestEnemyToAgent(-2, $range, $GC_I_AGENT_TYPE_LIVING, 1, $filterFunc)

        If Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_WAND Or Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_STAFF Or Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_BOW Then
            Agent_Attack($target)
        EndIf

        Switch $gProf
            Case 63
                EmoKill($targetCaster, $target)
            Case 42
                NecroKill($targetCaster, $target)
            Case Else
                Agent_Attack($target)
        EndSwitch

        If TimerDiff($timer) >= 900000 Then Return ; Deadlock Return after 15 mins in the function
        $myX = Agent_GetAgentInfo(-2, "X")
        $myY = Agent_GetAgentInfo(-2, "Y")

        $currentDistance = GetDistance($target, -2)
        
        If Abs($currentDistance - $desiredDistance) > $tolerance Then
            
            $targetX = Agent_GetAgentInfo($target, "X")
            $targetY = Agent_GetAgentInfo($target, "Y")
            
            $angle = ATan2($targetY - $myY, $targetX - $myX)


            $newX = $targetX - ($desiredDistance * Cos($angle))
            $newY = $targetY - ($desiredDistance * Sin($angle))


            $newX = $myX + ($newX - $myX) * $adjustFactor
            $newY = $myY + ($newY - $myY) * $adjustFactor
            
            Map_Move($newX, $newY)

            $myX = Agent_GetAgentInfo(-2, "X")
            $myY = Agent_GetAgentInfo(-2, "Y")
        EndIf

    Until GetNumberOfFoesInRangeOfAgent(-2, $range) = 0 Or ComputeDistanceSquared($refX, $refY, $myX, $myY) >= $range * $range Or GetPartyDead() Or TimerDiff($timer) >= $maxKillTime

    Return Not GetPartyDead()
EndFunc   ;==>StayAlive_Kill

Func EmoKill($targC, $targ)

    Local $targetCaster = $targC
    Local $target = $targ

    If IsRecharged(1) Then
        UseSkillEx(1, -2) ; Glyph
    EndIf

    ; We target the caster first as generally the caster's will heal or be bundled up with other casters.
    Local $fsTarget = ($targetCaster <> 0) ? $targetCaster : $target
    If IsRecharged(2) Then
        UseSkillEx(2, $fsTarget) ; Firestorm
    EndIf

    If Not Agent_GetAgentEffectInfo(-2, 288, "HasEffect") Then ; Healing Breeze
        If IsRecharged(8) Then
            UseSkillEx(8, -2)
        EndIf
    EndIf

    If IsRecharged(3) Then
        UseSkillEx(3, $target) ; Bane Signet
    EndIf

    If IsRecharged(4) Then
        UseSkillEx(4, $target) ; Flare
    EndIf

    If IsRecharged(5) And NeedHeal(70) Then
        UseSkillEx(5, -2) ; Reversal of Fortune
    EndIf

    If IsRecharged(6) And NeedHeal(70) Then
        UseSkillEx(6, -2) ; Shielding Hands
    EndIf
EndFunc

Func NecroKill($targC, $targ)
    Local $aMe = Agent_GetAgentPtr(-2)
    If $aMe = 0 Then Return

    Local $hp = GetMyHP()
    Local $energy = GetEnergyPercent()

    Local $corpse = GetNearestCorpseToAgent(-2, 1600)
    Local $corpseCount = GetNumberOfCorpseInRangeOfAgent(-2, 1600)
    Local $minionCount = GetNumberOfMinionsInRangeOfAgent(-2, 1600)

    Local $fightTarget = 0
    If $targC <> 0 Then
        $fightTarget = $targC
    Else
        $fightTarget = $targ
    EndIf

    ; 1. Heal only when actually needed
    If IsRecharged(1) And $hp < 0.70 Then
        UseSkillEx(1, -2)
        Sleep(250)
        Return
    EndIf

    ; 2. Build minions, but do not let it completely lock out damage
    ; assuming skill 3 = minion skill
    If $minionCount < 8 And $corpse <> 0 And $corpseCount > 0 And $energy > 0.30 Then
        If IsRecharged(3) Then
            UseSkillEx(3, $corpse)
            Sleep(250)
        EndIf
    EndIf

    ; 3. Damage skill 2
    If IsRecharged(2) And $fightTarget <> 0 Then
        UseSkillEx(2, $fightTarget)
        Sleep(200)
    EndIf

    ; 4. Damage skill 4
    If IsRecharged(4) And $fightTarget <> 0 Then
        UseSkillEx(4, $fightTarget)
        Sleep(200)
    EndIf

    ; 5. Damage skill 5
    If IsRecharged(5) And $fightTarget <> 0 Then
        UseSkillEx(5, $fightTarget)
        Sleep(200)
    EndIf

    ; 6. If under cap, try minion again after damage
    If $minionCount < 8 And $corpse <> 0 And $energy > 0.20 Then
        If IsRecharged(3) Then
            UseSkillEx(3, $corpse)
            Sleep(250)
        EndIf
    EndIf

 EndFunc   ;==>NecroKill
#EndRegion

#Region AgentFilters

Global $CharrFilter[12] = [1450, 1451, 1453, 1638, 1640, 1643, 1648, 1652, 1654, 1656, 1658, 1662]

Global $BanditFilter[10] = [1420, 1421, 1422, 1423, 7824, 7825, 7839, 7840, 7857, 7858]

Global $SpiderAloeFilter[5] = [1401, 1403, 1426, 1428, 1429]

Global $EnchLodesFilter[2] = [1415, 1414]

Global $WurmFilter[2] = [1346, 1442]

Global $SkellyFilter[2] = [1518, 1520]

Global $SkaleFilter[4] = [1433, 1431, 1432, 1436]

Global $CarapaceFilter[2] = [1409, 1405]

Global $GrawlNecklaceFilter[3] = [1438, 1437, 1439]

Func EnemyFilter($aAgentPtr)

    If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False

    Return True
EndFunc   ;==>EnemyFilter

Func CorpseFilter($aAgentPtr)

    If $aAgentPtr = 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, "Allegiance") <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, "HP") > 0 Then Return False
    
    Return True
EndFunc   ;==>CorpseFilter

Func CharrFilter($aAgentPtr)

    If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False

    Local $ModelID = Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber')
    Local $CharrModelIDs[15] = [1649, 1640, 1641, 1643, 1648, 1652, 1654, 1658, 1662, 1453, 1450, 1451, 1656, 1638, 1659] ; Array of Charr model IDs
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

Func ImpFilter($aAgentPtr)

    If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 6 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False

    Return Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber') = 513
EndFunc   ;==>ImpFilter

Func CharrCasterFilter($aAgentPtr)

    If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False

    Local $ModelID = Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber')
    Local $CharrModelIDs[8] = [1452, 1450, 1451, 1453, 1649, 1638, 1659, 1641] ; 4 Bosses + Shaman, Chaot, Hunter, Ashen Claw
    Local $IsCharr = False
    For $i = 0 To UBound($CharrModelIDs) - 1
        If $ModelID == $CharrModelIDs[$i] Then
            $IsCharr = True
            ExitLoop
        EndIf
    Next
    If Not $IsCharr Then Return False

    Return True
EndFunc   ;==>CharrCasterFilter

Func BanditFilter($aAgentPtr)

    If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False

    Local $ModelID = Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber')
    Local $BanditModelIDs[10] = [1420, 1421, 1422, 1423, 7824, 7825, 7839, 7840, 7857, 7858] ; Array of bandit model IDs
    Local $IsBandit = False
    For $i = 0 To UBound($BanditModelIDs) - 1
        If $ModelID == $BanditModelIDs[$i] Then
            $IsBandit = True
            ExitLoop
        EndIf
    Next
    If Not $IsBandit Then Return False

    Return True
EndFunc   ;==>BanditFilter

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
EndFunc   ;==>UnnaturalSeeds

Func NPCFilter($aAgentPtr)

    If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 6 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False

    Return True
EndFunc   ;==>NPCFilter

Func NickFilter($aAgentPtr)

    If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 6 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber') <> 7710 Then Return False

    Return True
EndFunc   ;==>NickFilter

Func MinionFilter($aAgentPtr)

    If $aAgentPtr = 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 1 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsMinion') = 0 Then Return False

    Return True
EndFunc   ;==>MinionFilter
#EndRegion

#Region Agents
Func GetNearestEnemyToAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 1, $aCustomFilter = "EnemyFilter")
    Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc   ;==>GetNearestEnemyToAgent

Func GetNearestNPCToAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 1, $aCustomFilter = "NPCFilter")
    Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc   ;==>GetNearestNPCToAgent

Func GetNearestGadgetToAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_GADGET, $aReturnMode = 1)
    Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode)
EndFunc   ;==>GetNearestGadgetToAgent

Func GetNearestCharrToAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 1, $aCustomFilter = "CharrFilter")
    Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc   ;==>GetNearestCharrToAgent

Func GetNearestCorpseToAgent($aAgentID = -2, $aRange = 1300, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 1, $aCustomFilter = "CorpseFilter")
    Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc   ;==>GetNearestCorpseToAgent

Func GetNumberOfFoesInRangeOfAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 0, $aCustomFilter = "EnemyFilter")
    Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc   ;==>GetNumberOfFoesInRangeOfAgent

Func GetNumberOfCharrInRangeOfAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 0, $aCustomFilter = "CharrFilter")
    Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc   ;==>GetNumberOfCharrInRangeOfAgent

Func GetNumberOfCharrInRangeOfXY($aX, $aY, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 0, $aCustomFilter = "CharrFilter")
    Return GetAgentsFromXY($aX, $aY, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc   ;==>GetNumberOfCharrInRangeOfXY

Func GetNumberOfMinionsInRangeOfAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 0, $aCustomFilter = "MinionFilter")
    Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc   ;==>GetNumberOfMinionsInRangeOfAgent

Func GetNumberOfCorpseInRangeOfAgent($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 0, $aCustomFilter = "CorpseFilter")
    Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc   ;==>GetNumberOfCorpseInRangeOfAgent

Func HasImp($aAgentID = -2, $aRange = 3000, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 0, $aCustomFilter = "ImpFilter")
    Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter) >= 1
EndFunc   ;==>HasImp

Func GetNick($aAgentID = -2, $aRange = 1320, $aType = $GC_I_AGENT_TYPE_LIVING, $aReturnMode = 1, $aCustomFilter = "NickFilter")
    Return GetAgents($aAgentID, $aRange, $aType, $aReturnMode, $aCustomFilter)
EndFunc   ;==>GetNick

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

Func IsAdrenal($aSkill)
    Return Skill_GetSkillInfo($aSkill, "Adrenaline") <> 0 ? True : False
EndFunc   ;==>IsAdrenal

Func UseSkillEx($aSkill, $aTgt = -2, $aTimeout = 3000)
    If GetIsDead(-2) Then Return
    If Not $aTgt <> 0 Then Return
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
EndFunc   ;==>CountSlots

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

Func PickUpLootInRange($range = 1500, $refx = "", $refy = "")

    Local $lAgentArray = Item_GetItemArray()
    Local $maxitems = IsArray($lAgentArray) ? $lAgentArray[0] : 0
    
    If $refx = "" Or $refy = "" Then
        $refx = Agent_GetAgentInfo(-2, "X")
        $refy = Agent_GetAgentInfo(-2, "Y")
    EndIf

    If GetPartyDead() Then Return
    For $i = 1 To $maxitems
        If GetPartyDead() Then ExitLoop
        Local $aItemPtr = $lAgentArray[$i]
        Local $aItemAgentID = Item_GetItemInfoByPtr($aItemPtr, "AgentID")
        Local $itemX = Agent_GetAgentInfo($aItemAgentID, "X")
        Local $itemY = Agent_GetAgentInfo($aItemAgentID, "Y")

        If GetPartyDead() Then ExitLoop
        If $aItemAgentID = 0 Then ContinueLoop ; If Item is not on the ground
        If ComputeDistanceSquared($refx, $refy, $itemX, $itemY) > $range * $range Then ContinueLoop ; If Item is out of range

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
EndFunc   ;==>PickUpLootInRange

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
    ElseIf ($lModelID == $GC_I_MODELID_DYE) Then	; Dye items
        If $aExtraID == $GC_I_EXTRAID_DYE_BLACK Then Return $isBlackPickup
        If $aExtraID == $GC_I_EXTRAID_DYE_WHITE Then Return $isWhitePickup ; Only pick White and Black ones
        Return $isOtherPickup ; Pick all dyes
    ElseIf $lRarity == $RARITY_Gold Then ; Gold items
        Return $isGoldPickup
    ElseIf $lRarity == $RARITY_Purple Then ; Purple items
        Return $isPurplePickup
    ElseIf $lRarity == $RARITY_Blue Then ; Blue items
        Return $isBluePickup
    ElseIf $lModelID == $ITEM_ID_Lockpicks Then
        Return True
    ElseIf $lModelID == 22269 Then	; Cupcakes
        Return True
    ElseIf $lModelID == $GC_I_MODELID_LUNAR_TOKEN Then ; Lunar Tokens
        Return True
    ElseIf $lModelID == $GC_I_MODELID_VICTORY_TOKEN Then ; Victory Tokens
        Return True
    ElseIf IsPreCollectable($aItemPtr) Then
        If $CharrBossFarm Then
            If $lModelID == 423 Then ; Still going to grab those charr carvings
                Return $isCollPickup
            Else
                Return False
            EndIf
        Else
            Return $isCollPickup
        EndIf
    ElseIf $lModelID == $ExpertSalvKit Then
        Return True
    ElseIf IsPcon($aItemPtr) Then ; ==== Pcons ==== or all event items
        Return $isPconsPickup
    ElseIf IsRareMaterial($aItemPtr) Then	; Rare Mats
        Return False
    ElseIf $lModelID == $CharrSalvKit Then
        Return $isCSalvPickup
    ElseIf $lModelID == 16453 Then
        Return $isCBagPickup
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
 EndFunc   ;==>GetItemMaxDmg

Func GetGoldCharacter()
    Return Item_GetInventoryInfo("GoldCharacter")
EndFunc   ;==>GetGoldCharacter

Func GetGoldStorage()
    Return Item_GetInventoryInfo("GoldStorage")
EndFunc   ;==>GetGoldStorage

Func InventoryPre()
    LogInfo("Travelling to Ascalon City (Pre-Searing)")
    RndTravel($GC_I_MAP_ID_ASCALON_CITY_OUTPOST)
    
    Sleep(3000)
    
    LogInfo("Moving to Merchant..")
    MerchantAscalonPre()
    Sleep(2000)
    
    If GetGoldCharacter() < 100 Or CountSlots() < 1 Then
        LogWarn("Selling common items to get 100 gold minimum, and free inventory space.")
        For $i = 1 To 4
            PreSell($i)
            If GetGoldCharacter() >= 100 And CountSlots() >= 1 Then ExitLoop
        Next
    EndIf
    
    If GetGoldCharacter() >= 100 And CountSlots() >= 1 Then
        LogInfo("Identifying items..")
        For $i = 1 To 4
            Ident($i)
        Next
        
        LogInfo("Selling items..")
        For $i = 1 To 4
            Sell($i)
        Next
    ElseIf GetGoldCharacter() < 100 Then
        LogError("Not enough gold to buy ID kit, returning...")
        Return
    EndIf

    If CountSlots() < $minCharrSlots And $CharrBossFarm Then
        DanceParty()
        UpdateStats()
        Return
    ElseIf CountSlots() < $minRegSlots And Not $CharrBossFarm Then
        DanceParty()
        UpdateStats()
        Return
    EndIf

    UpdateStats()
    
    LogWarn("Inventory management complete!")

    Sleep(500)
EndFunc   ;==>InventoryPre

Func DanceParty()
    LogWarn("## INveNtoRy hAs reACHeD MAx CAtERPIlLArs! ## NOw SHuT uP AND DAnCe BAbY! ##")

    Local $DanceSpots[4][2] = [[7595.43, 6957.02], [8780.70, 5798.01], [9878.40, 4910.21], [9205.81, 5175.33]]
    Local $i = Random(0, 3, 1)

    MoveTo($DanceSpots[$i][0], $DanceSpots[$i][1], 100)
    Sleep(1000)
    Chat_SendChat("dance", "/")
    Sleep(250)
    
    $BotRunning = False
EndFunc

Func MerchantAscalonPre()
    Local $spX = Agent_GetAgentInfo(-2, "X")
    Local $spY = Agent_GetAgentInfo(-2, "Y")
    Local $sp1 = ComputeDistance(8436, 4819, $spX, $spY)

    If $sp1 > 3000 Then MoveTo(8339.99, 6202.35)
    
    MoveTo(8488.07, 4870.26)
    
    LogInfo("Talking to Merchant..")
    Local $guy = GetNearestNPCToAgent(-2, 1320, $GC_I_AGENT_TYPE_LIVING, 1, "NPCFilter")
    Agent_GoNPC($guy)
    Sleep(1000)
EndFunc   ;==> MerchantAscalonPre

Func Ident($BagIndex)
    Local $BagPtr
    Local $aItemPtr

    $BagPtr = Item_GetBagPtr($BagIndex)
    For $ii = 1 To Item_GetBagInfo($BagPtr, "Slots")
        If FindIdentificationKit() = 0 Then
            Local $j = 0
            Do
                Merchant_BuyItem($NormalIDKit, 1)
                Sleep(1000)
                $j = $j + 1
            Until FindIdentificationKit() <> 0 Or $j = 3
            If $j = 3 Then ExitLoop
            Sleep(1000)
        EndIf
        $aItemPtr = Item_GetItemBySlot($BagIndex, $ii)
        If Item_GetItemInfoByPtr($aItemPtr, "ItemID") = 0 Then ContinueLoop
        If Item_GetItemInfoByPtr($aItemPtr, "IsIdentified") Then ContinueLoop
        Item_IdentifyItem($aItemPtr, "Normal")
        Sleep(250)
    Next
EndFunc   ;==>Ident

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
    Local $lItemID
    Local $myLevel = Agent_GetAgentInfo(-2, "Level")
    
    If GetEffectTimeRemainingEx(-2, 2886) <> 0 Then Return False  ; Summoning Sickness
    For $i = 1 To 4
        For $j = 1 To Item_GetBagInfo(Item_GetBagPtr($i), 'Slots')
            $lItemPtr = Item_GetItemBySlot($i, $j)
            $lItemID = Item_GetItemInfoByPtr($lItemPtr, 'ModelID')
            For $ii = 0 to UBound($SummoningStone) - 1
                If $lItemID = $SummoningStone[$ii] Then
                    If $lItemID = 30847 And $myLevel > 19 Then Return False ; Only return false if level is above 19 when using imp
                    Item_UseItem($lItemPtr)
                    Sleep(250)
                    Return True
                EndIf
            Next
        Next
    Next
    Return False
EndFunc	   ;==>UseSummoningStone

Func GetBonus()
    RndTravel($GC_I_MAP_ID_ASCALON_CITY_OUTPOST)
 
    If FindSummoningStone() Then
        LogInfo("Summoning stone found!")
        Sleep(1000)
        DeleteBonusItems()
        Sleep(2500)
        Return
    EndIf

    LogError("No stone found, grabbing bonus items!")
    Chat_SendChat("bonus", "/")
    Other_RndSleep(2500)

    DeleteBonusItems()

    If FindSummoningStone() Then
        LogInfo("Bonus items collected successfully.")
    Else
        LogError("No bonus items available..")
    EndIf

    Other_RndSleep(2500)
    $hasBonus = True
EndFunc   ;==>GetBonus

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

Func QuestActive($questID)
    
    Local $bHasQuest = InQuestLog($questID)

    If $bHasQuest = True Then
        LogInfo("Quest is in our quest log!")
        Ui_ActiveQuest($questID)
    Else
        LogInfo("Quest is not in our quest log!")
    EndIf

    Sleep(250)
EndFunc   ;==>QuestActive

Func InQuestLog($questID)

    Local $l_questArray = GetQuestArray()
    If $l_questArray = 0 Then Return False

    For $i = 0 To UBound($l_questArray) - 1
        If $l_questArray[$i] = $questID Then
            Return True
        EndIf
    Next

    Return False
EndFunc   ;==>InQuestLog

Func GetQuestArray()
    Local $l_i_Size = World_GetWorldInfo("QuestLogSize")
    If $l_i_Size = 0 Then Return 0

    Local $l_ai_QuestArray[$l_i_Size]
    Local $l_i_Count = 0

    For $l_i_Idx = 0 To $l_i_Size - 1
        Local $l_ai_OffsetQuestLog[5] = [0, 0x18, 0x2C, 0x52C, 0x34 * $l_i_Idx]
        Local $l_ap_QuestPtr = Memory_ReadPtr($g_p_BasePointer, $l_ai_OffsetQuestLog, "long")
        Local $l_i_QuestID = $l_ap_QuestPtr[1]
        If $l_i_QuestID <> 0 Then
            $l_ai_QuestArray[$l_i_Count] = $l_i_QuestID
            $l_i_Count += 1
        EndIf
    Next

    If $l_i_Count = 0 Then Return 0
    ReDim $l_ai_QuestArray[$l_i_Count]
    Return $l_ai_QuestArray
EndFunc   ;==>GetQuestArray

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
EndFunc   ;==> PreSell

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
EndFunc   ;==> Sell

Func CanPreSell($aItemPtr)
    Local $lRarity = Item_GetItemInfoByPtr($aItemPtr, "Rarity")
    Local $lIsIdentified = Item_GetItemInfoByPtr($aItemPtr, "IsIdentified")
    
    ; Only sell white and blue items to get enough money or free slots
    If $lRarity <> $RARITY_White And $lRarity <> $RARITY_Blue Then Return False

    Return True
EndFunc   ;==> CanPreSell

Func CanSell($aItem)
    Local $IsRareMod = IsRareMod($aItem)
    Local $IsRareRunePre = IsRareRunePre($aItem)
    Local $IsInsignia = IsRareInsigniaPre($aItem)
    Local $IsCharrRelated = IsCharrRelated($aItem)
    Local $IsDye = IsDye($aItem)
    Local $IsBlue = IsBlue($aItem)
    Local $IsPurple = IsPurple($aItem)
    Local $IsGold = IsGold($aItem)
    Local $IsPreCollectable = IsPreCollectable($aItem)
    Local $RareSkin = IsRareSkin($aItem)
    Local $Pcon = IsPcon($aItem)
    Local $Material = IsRareMaterial($aItem)
    Local $IsSpecial = IsSpecialItem($aItem)
    Local $IsCaster = IsPerfectCaster($aItem)
    Local $IsStaff = IsPerfectStaff($aItem)
    Local $IsShield = IsPerfectShield($aItem)
    Local $IsReq8 = IsReq8Max($aItem)
    Local $IsReq7 = IsReq7Max($aItem)
    Local $IsTome = IsRegularTome($aItem)
    Local $IsEliteTome = IsEliteTome($aItem)
    Local $IsTyriaAnniSkin = IsTyriaAnniSkin($aItem)
    Local $IsCanthaAnniSkin = IsCanthaAnniSkin($aItem)
    Local $IsElonaAnniSkin = IsElonaAnniSkin($aItem)
    Local $IsEotnAnniSkin = IsEotnAnniSkin($aItem)
    Local $IsAnyCampAnniSkin = IsAnyCampAnniSkin($aItem)

    Local $type = Item_GetItemInfoByPtr($aItem, "ItemType")

    Switch $IsBlue
    Case True
        If $IsRareMod Or $IsRareRunePre Or $IsInsignia Then Return False
        Return $isBlueSell ; Is blue
    EndSwitch

    Switch $IsPurple
    Case True
        If $IsRareMod Or $IsRareRunePre Or $IsInsignia Then Return False
        Return $isPurpleSell ; Is purple
    EndSwitch

    Switch $IsGold
    Case True
        If $IsRareMod Or $IsRareRunePre Or $IsInsignia Or $IsSpecial Then Return False
        Return $isGoldSell ; Is gold
    EndSwitch
    
    Switch $IsDye
        Case $GC_I_EXTRAID_DYE_BLACK
            Return $isBlackSell
        Case $GC_I_EXTRAID_DYE_WHITE
            Return $isWhiteSell
        Case Else
            Return $isOtherSell
    EndSwitch

    Switch $IsCharrRelated
    Case True   
        Switch $ModelID
            Case 18721
                Return $isCSalvSell
            Case 16453
                Return $isCBagSell
        EndSwitch
    EndSwitch

    Switch $IsPreCollectable
    Case True
       Return $isCollSell ; Is pre-collectable
    EndSwitch

    Switch $IsSpecial
    Case True
       Return False ; Is special item (Ecto, TOT, etc)
    EndSwitch
 
    Switch $Pcon
    Case True
       Return $isPconsSell ; Is a Pcon
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

    Switch $IsInsignia
    Case True
       Return False
    EndSwitch
    
    Switch $IsRareRunePre
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
  EndFunc   ;==> CanSell
#EndRegion

#Region Items
Func IsBlue($aItem)
    Local $lRarity = Item_GetItemInfoByPtr($aItem, "Rarity")
    
    If $lRarity = $RARITY_Blue Then
        Return True
    EndIf
    Return False
EndFunc   ;==> IsBlue

Func IsPurple($aItem)
    Local $lRarity = Item_GetItemInfoByPtr($aItem, "Rarity")
    
    If $lRarity = $RARITY_Purple Then
        Return True
    EndIf
    Return False
EndFunc   ;==> IsPurple

Func IsGold($aItem)
    Local $lRarity = Item_GetItemInfoByPtr($aItem, "Rarity")
    
    If $lRarity = $RARITY_Gold Then
        Return True
    EndIf
    Return False
EndFunc   ;==> IsGold

Func IsDye($aItem)
    Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")
    If $ModelID <> $GC_I_MODELID_DYE Then Return False

    Local $ExtraID = Item_GetItemInfoByPtr($aItem, "ExtraID")

    Switch $ExtraID
        Case $GC_I_EXTRAID_DYE_BLACK
            Return $ExtraID
        Case $GC_I_EXTRAID_DYE_WHITE
            Return $ExtraID
        Case Else
            Return $ExtraID
    EndSwitch

    Return False
EndFunc   ;==> IsDye

Func IsCharrRelated($aItem)
    Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

    Switch $ModelID
    Case 18721, 16453
       Return $ModelID ; Charr Salv Kit, Charr Bag
    EndSwitch
    Return False
EndFunc   ;==> IsCharrRelated

Func IsPreCollectable($aItem)
    Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

    Switch $ModelID
    Case 2994
       Return True ; Red iris,
    Case 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433 ; Spider Leg, Charr Carving, Icy Lodes, Dull Carap, Garg Skull, Worn Belt, Unnatural Seed, Skale Fin (Pre), Skele Limb, Ench Lodes, Grawl Neck, Baked Husk.
        Return True
    EndSwitch
    Return False
EndFunc   ;==> IsPreCollectable

Func IsBonusJunk($aItem)
    Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

    For $i = 0 To UBound($GC_BonusWeapons) - 1
        If $ModelID = $GC_BonusWeapons[$i] Then Return True
    Next

    Return False
EndFunc   ;==> IsBonusJunk

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
EndFunc   ;==> IsRareSkin 

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
EndFunc   ;==> IsTyriaAnniSkin

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
EndFunc   ;==> IsCanthaAnniSkin

Func IsElonaAnniSkin($aItem)
    Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

    Switch $ModelID
    Case 2471
       Return True ; Sunspear
    EndSwitch
    Return False
EndFunc   ;==> IsElonaAnniSkin

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
EndFunc   ;==> IsEotnAnniSkin

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
EndFunc   ;==> IsAnyCampAnniSkin

Func IsPcon($aItem)
    Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

    Switch $ModelID
    Case 910, 2513, 5585, 6049, 6366, 6367, 6375, 15477, 19171, 19172, 19173, 22190, 24593, 28435, 30855, 31145, 31146, 35124, 36682
       Return True ; Alcohol
    Case 6376, 21809, 21810, 21813, 36683
       Return True ; Party
    Case 18345, 21492, 21812, 22269, 22644, 22752, 28436, 36681
       Return True ; Sweets
    Case 6370, 21488, 21489, 22191, 26784, 28433
       Return True ; DP Removal
    Case 15837, 21490, 30648, 31020
       Return True ; Tonic
    EndSwitch
    Return False
EndFunc   ;==> IsPcon

Func IsRareMaterial($aItem)
    Local $M = Item_GetItemInfoByPtr($aItem, "ModelID")
    Local $Type = Item_GetItemInfoByPtr($aItem, "ItemType")
 
    If $Type <> 11 Then Return False	; Some items have the same model ID, so the type of rare mats is 11
    Switch $M
    Case 922, 923, 926, 927, 928, 930, 931, 932, 935, 936, 937, 938, 939, 941, 942, 943, 944, 945, 949, 950, 951, 952, 956, 6532, 6533
       Return True ; Rare Mats
    EndSwitch
    Return False
EndFunc   ;==> IsRareMaterial

Func IsSpecialItem($aItem)
    Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

    Switch $ModelID
    Case 5656, 18345, 21491, 37765, 21833, 28433, 28434
       Return True ; Special - ToT etc
    Case 22751
       Return True ; Lockpicks
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
    Case 31149
        Return True ;Gifts of the Huntsman
    EndSwitch
    Return False
EndFunc   ;==> IsSpecialItem

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
EndFunc   ;==> IsPerfectCaster

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
EndFunc   ;==> IsPerfectStaff

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
EndFunc   ;==> IsPerfectShield

Func IsRareMod($aItem)
    Local $ModStruct = Item_GetModStruct($aItem)

    ; =========================
    ; MARTIAL – % Stance
    ; =========================
    Local $Stance10 = StringInStr($ModStruct, "0A00A822", 0, 1)
    Local $Stance11 = StringInStr($ModStruct, "0B00A822", 0, 1)
    Local $Stance12 = StringInStr($ModStruct, "0C00A822", 0, 1)
    Local $Stance13 = StringInStr($ModStruct, "0D00A822", 0, 1)
    Local $Stance14 = StringInStr($ModStruct, "0E00A822", 0, 1)
    Local $Stance15 = StringInStr($ModStruct, "0F00A822", 0, 1)

    ; =========================
    ; MARTIAL – % HP > 50%
    ; =========================
    Local $HP5010 = StringInStr($ModStruct, "0A327822", 0, 1)
    Local $HP5011 = StringInStr($ModStruct, "0B327822", 0, 1)
    Local $HP5012 = StringInStr($ModStruct, "0C327822", 0, 1)
    Local $HP5013 = StringInStr($ModStruct, "0D327822", 0, 1)
    Local $HP5014 = StringInStr($ModStruct, "0E327822", 0, 1)
    Local $HP5015 = StringInStr($ModStruct, "0F327822", 0, 1)

    ; =========================
    ; CASTER – Fire +1
    ; =========================
    Local $Fire15 = StringInStr($ModStruct, "0F0A1824", 0, 1)
    Local $Fire16 = StringInStr($ModStruct, "100A1824", 0, 1)
    Local $Fire17 = StringInStr($ModStruct, "110A1824", 0, 1)
    Local $Fire18 = StringInStr($ModStruct, "120A1824", 0, 1)
    Local $Fire19 = StringInStr($ModStruct, "130A1824", 0, 1)
    Local $Fire20 = StringInStr($ModStruct, "140A1824", 0, 1)

    ; =========================
    ; CASTER – Death +1
    ; =========================
    Local $Death15 = StringInStr($ModStruct, "0F051824", 0, 1)
    Local $Death16 = StringInStr($ModStruct, "10051824", 0, 1)
    Local $Death17 = StringInStr($ModStruct, "11051824", 0, 1)
    Local $Death18 = StringInStr($ModStruct, "12051824", 0, 1)
    Local $Death19 = StringInStr($ModStruct, "13051824", 0, 1)
    Local $Death20 = StringInStr($ModStruct, "14051824", 0, 1)

    ; =========================
    ; CASTER – Domination +1
    ; =========================
    Local $Dom15 = StringInStr($ModStruct, "0F021824", 0, 1)
    Local $Dom16 = StringInStr($ModStruct, "10021824", 0, 1)
    Local $Dom17 = StringInStr($ModStruct, "11021824", 0, 1)
    Local $Dom18 = StringInStr($ModStruct, "12021824", 0, 1)
    Local $Dom19 = StringInStr($ModStruct, "13021824", 0, 1)
    Local $Dom20 = StringInStr($ModStruct, "14021824", 0, 1)

    ; =========================
    ; vs Charr
    ; =========================
    Local $SCharr = StringInStr($ModStruct, "00018080", 0, 1)



    If $Stance10 > 0 Or $Stance11 > 0 Or $Stance12 > 0 Or $Stance13 > 0 Or $Stance14 > 0 Or $Stance15 > 0 Then
        Return True
    ElseIf $HP5010 > 0 Or $HP5011 > 0 Or $HP5012 > 0 Or $HP5013 > 0 Or $HP5014 > 0 Or $HP5015 > 0 Then
        Return True
    ElseIf $Fire15 > 0 Or $Fire16 > 0 Or $Fire17 > 0 Or $Fire18 > 0 Or $Fire19 > 0 Or $Fire20 > 0 Then
        Return True
    ElseIf $Death15 > 0 Or $Death16 > 0 Or $Death17 > 0 Or $Death18 > 0 Or $Death19 > 0 Or $Death20 > 0 Then
        Return True
    ElseIf $Dom15 > 0 Or $Dom16 > 0 Or $Dom17 > 0 Or $Dom18 > 0 Or $Dom19 > 0 Or $Dom20 > 0 Then
        Return True
    ElseIf $SCharr > 0 Then
        Return True
    Else
        Return False
    EndIf

EndFunc   ;==> IsRareMod

Func IsRareRunePre($aItem)
    Local $ModStruct = Item_GetModStruct($aItem)

    Local $SupVigor = StringInStr($ModStruct, "C202EA27", 0, 1) ; Sup vigor rune

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
    Local $minorIllusion = StringInStr($ModStruct, "0101E821", 0, 1) ; minor Illusion
    Local $minorDomination = StringInStr($ModStruct, "0102E821", 0, 1) ; minor Domination
    Local $minorBlood = StringInStr($ModStruct, "0104E821", 0, 1) ; minor Blood
    Local $minorDeath = StringInStr($ModStruct, "0105E821", 0, 1) ; minor Death
    Local $minorCurses = StringInStr($ModStruct, "0107E821", 0, 1) ; minor Curses
    Local $minorAir = StringInStr($ModStruct, "0108E821", 0, 1) ; minor Air
    Local $minorEarth = StringInStr($ModStruct, "0109E821", 0, 1) ; minor Earth
    Local $minorFire = StringInStr($ModStruct, "010AE821", 0, 1) ; minor Fire
    Local $minorWater = StringInStr($ModStruct, "010BE821", 0, 1) ; minor Water
    Local $minorSmiting = StringInStr($ModStruct, "010EE821", 0, 1) ; minor Smiting
    Local $minorAxe = StringInStr($ModStruct, "0112E821", 0, 1) ; minor Axe
    Local $minorHammer = StringInStr($ModStruct, "0113E821", 0, 1) ; minor Hammer
    Local $minorSword = StringInStr($ModStruct, "0114E821", 0, 1) ; minor Sword
    Local $minorAbsorption = StringInStr($ModStruct, "FC000824", 0, 1) ; minor Absorption
    Local $minorBeast = StringInStr($ModStruct, "0116E821", 0, 1) ; minor Beast
    Local $minorWilderness = StringInStr($ModStruct, "0118E821", 0, 1) ; minor Wilderness

    Local $runeAttunement = StringInStr($ModStruct, "11020824", 0, 1) ; Attunement
    Local $runeRecovery = StringInStr($ModStruct, "13020824", 0, 1) ; Recovery
    Local $runeRestoration = StringInStr($ModStruct, "14020824", 0, 1) ; Restoration
    Local $runeClarity = StringInStr($ModStruct, "15020824", 0, 1) ; Clarity
    Local $runePurity = StringInStr($ModStruct, "16020824", 0, 1) ; Purity

    Local $majorFast = StringInStr($ModStruct, "0200E821", 0, 1) ; major Fastcast
    Local $majorVigor = StringInStr($ModStruct, "C202E927", 0, 1) ; major Vigor

    If $minorStrength > 0 Or $minorTactics > 0 Or $minorExpertise > 0 Or $minorMarksman > 0 Or $minorHealing > 0 Or $minorProt > 0 Or $minorDivine > 0 Then
        Return True
    ElseIf $minorSoul > 0 Or $minorFastcast > 0 Or $minorInsp > 0 Or $minorEnergy > 0 Or $minorSpawn > 0 Or $minorScythe > 0 Or $minorMystic > 0 Then
        Return True
    ElseIf $minorVigor > 0 Or $minorVitae > 0 Or $majorFast > 0 Or $majorVigor > 0 Then
        Return True
    ElseIf $SupVigor > 0 Then
        Return True
    ElseIf $minorIllusion > 0 Or $minorDomination > 0 Or $minorBlood > 0 Or $minorDeath > 0 Or $minorCurses > 0 Then
        Return True
    ElseIf $minorAir > 0 Or $minorEarth > 0 Or $minorFire > 0 Or $minorWater > 0 Or $minorSmiting > 0 Then
        Return True
    ElseIf $minorAxe > 0 Or $minorHammer > 0 Or $minorSword > 0 Or $minorAbsorption > 0 Then
        Return True
    ElseIf $minorBeast > 0 Or $minorWilderness > 0 Then
        Return True
    ElseIf $runeAttunement > 0 Or $runeRecovery > 0 Or $runeRestoration > 0 Or $runeClarity > 0 Or $runePurity > 0 Then
        Return True
    Else
        Return False
    EndIf
EndFunc   ;==> IsRareRunePre

Func IsRareInsigniaPre($aItem)
    Local $ModStruct = Item_GetModStruct($aItem)
    Local $Sentinel = StringInStr($ModStruct, "FB010824", 0, 1) ; Sentinel insig
    Local $Tormentor = StringInStr($ModStruct, "EC010824", 0, 1) ; Tormentor insig
    Local $WindWalker = StringInStr($ModStruct, "02020824", 0, 1) ; Windwalker insig
    Local $Prodigy = StringInStr($ModStruct, "E3010824", 0, 1) ; Prodigy insig
    Local $Shamans = StringInStr($ModStruct, "04020824", 0, 1) ; Shamans insig
    Local $Nightstalker = StringInStr($ModStruct, "E1010824", 0, 1) ; Nightstalker insig
    Local $Centurions = StringInStr($ModStruct, "07020824", 0, 1) ; Centurions insig
    Local $Blessed = StringInStr($ModStruct, "E9010824", 0, 1) ; Blessed insig
    Local $Radiant = StringInStr($ModStruct, "E5010824", 0, 1) ; Radiant insig
    Local $Survivor = StringInStr($ModStruct, "E6010824", 0, 1) ; Survivor insig
    Local $Stalwart = StringInStr($ModStruct, "E7010824", 0, 1) ; Stalwart insig
    Local $Brawler = StringInStr($ModStruct, "E8010824", 0, 1) ; Brawler insig
    Local $Herald = StringInStr($ModStruct, "EA010824", 0, 1) ; Herald insig
    Local $Sentry = StringInStr($ModStruct, "EB010824", 0, 1) ; Sentry insig
    Local $Frostbound = StringInStr($ModStruct, "FC010824", 0, 1) ; Frostbound insig
    Local $Earthbound = StringInStr($ModStruct, "FD010824", 0, 1) ; Earthbound insig
    Local $Pyrebound = StringInStr($ModStruct, "FE010824", 0, 1) ; Pyrebound insig
    Local $Stormbound = StringInStr($ModStruct, "FF010824", 0, 1) ; Stormbound insig
    Local $Beastmaster = StringInStr($ModStruct, "00020824", 0, 1) ; Beastmaster insig
    Local $Scout = StringInStr($ModStruct, "01020824", 0, 1) ; Scout insig
    Local $Knight = StringInStr($ModStruct, "F9010824", 0, 1) ; Knight insig
    Local $Dreadnought = StringInStr($ModStruct, "FA010824", 0, 1) ; Dreadnought insig
    Local $Lieutenant = StringInStr($ModStruct, "08020824", 0, 1) ; Lieutenant insig
    Local $Stonefist = StringInStr($ModStruct, "09020824", 0, 1) ; Stonefist insig
    Local $Wanderer = StringInStr($ModStruct, "F6010824", 0, 1) ; Wanderer insig
    Local $Disciple = StringInStr($ModStruct, "F7010824", 0, 1) ; Disciple insig
    Local $Anchorite = StringInStr($ModStruct, "F8010824", 0, 1) ; Anchorite insig
    Local $Prismatic = StringInStr($ModStruct, "F1010824", 0, 1) ; Prismatic insig
    Local $Hydromancer = StringInStr($ModStruct, "F2010824", 0, 1) ; Hydromancer insig
    Local $Geomancer = StringInStr($ModStruct, "F3010824", 0, 1) ; Geomancer insig
    Local $Pyromancer = StringInStr($ModStruct, "F4010824", 0, 1) ; Pyromancer insig
    Local $Aeromancer = StringInStr($ModStruct, "F5010824", 0, 1) ; Aeromancer insig
    Local $Undertaker = StringInStr($ModStruct, "ED010824", 0, 1) ; Undertaker insig
    Local $Bonelace = StringInStr($ModStruct, "EE010824", 0, 1) ; Bonelace insig
    Local $MinionMaster = StringInStr($ModStruct, "EF010824", 0, 1) ; MinionMaster insig
    Local $Blighter = StringInStr($ModStruct, "F0010824", 0, 1) ; Blighter insig
    Local $Bloodstained = StringInStr($ModStruct, "0A020824", 0, 1) ; Bloodstained insig
    Local $Artificer = StringInStr($ModStruct, "E2010824", 0, 1) ; Artificer insig
    Local $Virtuoso = StringInStr($ModStruct, "E4010824", 0, 1) ; Virtuoso insig

    If $Sentinel > 0 Or $Tormentor > 0 Or $WindWalker > 0 Or $Prodigy > 0 Or $Shamans > 0 Or $Nightstalker > 0 Or $Centurions > 0 Or $Blessed > 0 Then
        Return True
    ElseIf $Radiant > 0 Or $Survivor > 0 Or $Stalwart > 0 Or $Brawler > 0 Or $Herald > 0 Or $Sentry > 0 Then
        Return True
    ElseIf $Frostbound > 0 Or $Earthbound > 0 Or $Pyrebound > 0 Or $Stormbound > 0 Or $Beastmaster > 0 Or $Scout > 0 Then
        Return True
    ElseIf $Knight > 0 Or $Dreadnought > 0 Or $Lieutenant > 0 Or $Stonefist > 0 Then
        Return True
    ElseIf $Wanderer > 0 Or $Disciple > 0 Or $Anchorite > 0 Then
        Return True
    ElseIf $Prismatic > 0 Or $Hydromancer > 0 Or $Geomancer > 0 Or $Pyromancer > 0 Or $Aeromancer > 0 Then
        Return True
    ElseIf $Undertaker > 0 Or $Bonelace > 0 Or $MinionMaster > 0 Or $Blighter > 0 Or $Bloodstained > 0 Then
        Return True
    ElseIf $Artificer > 0 Or $Virtuoso > 0 Then
        Return True
    Else
        Return False
    EndIf
EndFunc   ;==> IsRareInsigniaPre

Func IsSellableInsigniaPre($aItem)
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
EndFunc   ;==> IsSellableInsignia

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
EndFunc   ;==> IsReq8Max

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
EndFunc   ;==> IsReq7Max

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
EndFunc   ;==> GetItemMaxReq8

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
EndFunc   ;==> GetItemMaxReq7

Func IsRegularTome($aItem)
    Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

    Switch $ModelID
    Case 21796, 21797, 21798, 21799, 21800, 21801, 21802, 21803, 21804, 21805
       Return True
    EndSwitch
    Return False
EndFunc   ;==> IsRegularTome

Func IsEliteTome($aItem)
    Local $ModelID = Item_GetItemInfoByPtr($aItem, "ModelID")

    Switch $ModelID
    Case 21786, 21787, 21788, 21789, 21790, 21791, 21792, 21793, 21794, 21795
       Return True ; All Elite Tomes
    EndSwitch
    Return False
EndFunc   ;==> IsEliteTome

Func IsFiveE($aItem)
    Local $ModStruct = Item_GetModStruct($aItem)
    Local $t = Item_GetItemInfoByPtr($aItem, "ItemType")
    If (IsIHaveThePower($ModStruct) And $t = 2) Then Return True	; (Nur für Äxte)
EndFunc   ;==> IsFiveE

Func IsIHaveThePower($ModStruct)
    Local $EnergyAlways5 = StringInStr($ModStruct, "0500D822", 0 ,1) ; Energy +5
    If $EnergyAlways5 > 0 Then Return True
EndFunc   ;==> IsIHaveThePower

Func IsMaxAxe($aItem)
    Local $Type = Item_GetItemInfoByPtr($aItem, "ItemType")
    Local $Dmg = GetItemMaxDmg($aItem)
    Local $Req = GetItemReq($aItem)

    If $Type == 2 And $Dmg == 28 And $Req == 9 Then
        Return True
    Else
        Return False
    EndIf
EndFunc   ;==> IsMaxAxe

Func IsMaxDagger($aItem)
    Local $Type = Item_GetItemInfoByPtr($aItem, "ItemType")
    Local $Dmg = GetItemMaxDmg($aItem)
    Local $Req = GetItemReq($aItem)

    If $Type == 32 And $Dmg == 17 And $Req == 9 Then
        Return True
    Else
        Return False
    EndIf
EndFunc   ;==> IsMaxDagger
#EndRegion

#Region Constants

; ==== Constants ====
Global Enum $DIFFICULTY_NORMAL, $DIFFICULTY_HARD
Global Enum $INSTANCETYPE_OUTPOST, $INSTANCETYPE_EXPLORABLE, $INSTANCETYPE_LOADING
Global Enum $RANGE_ADJACENT=156, $RANGE_NEARBY=240, $RANGE_AREA=312, $RANGE_EARSHOT=1000, $RANGE_SPELLCAST = 1085, $RANGE_SPIRIT = 2500, $RANGE_COMPASS = 5000
Global Enum $RANGE_ADJACENT_2=156^2, $RANGE_NEARBY_2=240^2, $RANGE_AREA_2=312^2, $RANGE_EARSHOT_2=1000^2, $RANGE_SPELLCAST_2=1085^2, $RANGE_SPIRIT_2=2500^2, $RANGE_COMPASS_2=5000^2
Global Enum $PROF_NONE, $PROF_WARRIOR, $PROF_RANGER, $PROF_MONK, $PROF_NECROMANCER, $PROF_MESMER, $PROF_ELEMENTALIST, $PROF_ASSASSIN, $PROF_RITUALIST, $PROF_PARAGON, $PROF_DERVISH

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

; Build upkeeps
Global $gProf
Global $gUpkeepSkills
Global $EmoUpkeep[2] = [8, 7]
Global $NecroUpKeep[1] = [1]

;~ General Items
Global $General_Items_Array[6] = [2989, 2991, 2992, 5899, 5900, 22751]
Global Const $ITEM_ID_Lockpicks = 22751

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

Global $Array_pscon[39] = [910, 5585, 6366, 6375, 22190, 24593, 28435, 30855, 31145, 35124, 36682, 6376, 21809, 21810, 21813, 36683, 21492, 21812, 22269, 22644, 22752, 28436,15837, 21490, 30648, 31020, 6370, 21488, 21489, 22191, 26784, 28433, 5656, 18345, 21491, 37765, 21833, 28433, 28434]

Global $PIC_MATS[26][2] = [["Fur Square", 941],["Bolt of Linen", 926],["Bolt of Damask", 927],["Bolt of Silk", 928],["Glob of Ectoplasm", 930],["Steel of Ignot", 949],["Deldrimor Steel Ingot", 950],["Monstrous Claws", 923],["Monstrous Eye", 931],["Monstrous Fangs", 932],["Rubies", 937],["Sapphires", 938],["Diamonds", 935],["Onyx Gemstones", 936],["Lumps of Charcoal", 922],["Obsidian Shard", 945],["Tempered Glass Vial", 939],["Leather Squares", 942],["Elonian Leather Square", 943],["Vial of Ink", 944],["Rolls of Parchment", 951],["Rolls of Vellum", 952],["Spiritwood Planks", 956],["Amber Chunk", 6532],["Jadeite Shard", 6533]]

Global $Array_Store_ModelIDs460[147] = [474, 476, 486, 522, 525, 811, 819, 822, 835, 610, 2994, 19185, 22751, 4629, 24630, 4631, 24632, 27033, 27035, 27044, 27046, 27047, 7052, 5123 _
        , 1796, 21797, 21798, 21799, 21800, 21801, 21802, 21803, 21804, 1805, 910, 2513, 5585, 6049, 6366, 6367, 6375, 15477, 19171, 22190, 24593, 28435, 30855, 31145, 31146, 35124, 36682 _
        , 6376 , 6368 , 6369 , 21809 , 21810, 21813, 29436, 29543, 36683, 4730, 15837, 21490, 22192, 30626, 30630, 30638, 30642, 30646, 30648, 31020, 31141, 31142, 31144, 1172, 15528 _
        , 15479, 19170, 21492, 21812, 22269, 22644, 22752, 28431, 28432, 28436, 1150, 35125, 36681, 3256, 3746, 5594, 5595, 5611, 5853, 5975, 5976, 21233, 22279, 22280, 6370, 21488 _
        , 21489, 22191, 35127, 26784, 28433, 18345, 21491, 28434, 35121, 921, 922, 923, 925, 926, 927, 928, 929, 930, 931, 932, 933, 934, 935, 936, 937, 938, 939, 940, 941, 942, 943 _
        , 944, 945, 946, 948, 949, 950, 951, 952, 953, 954, 955, 956, 6532, 6533]

;~ Identification and Salvaging Stuff
Global Const $SupIDKit = 5899
Global Const $ExpertSalvKit = 2991
Global Const $Ectoplasm_ID = 930
Global Const $CharrSalvKit = 18721
Global Const $NormalIDKit = 2989

;~ Coordinates
Global $coords[2]
Global $X
Global $Y

;~ Timer -> For when killing takes too long or enemies are stuck
Global $TimerToKill = 0

Global $Survivor = False
Global $_19Stop = False
Global $spawn[2] = [0, 0]
Global $hasBonus = False
Global $CharrBossFarm = False
Global $NickRun = False
Global $TwoFiddy = False

;~ Inventory - FreeSlots
Global $invCheck = 4
Global $minCharrSlots = 4
Global $minRegSlots = 1

Global $timer = TimerInit()
Global $enemyKillTime = 120000
Global $TotalTime = 0
Global $RunTime = 0
#EndRegion

#Region Gui
Func LogInfo($sText)
    _LogWrite("INFO", $sText)
EndFunc

Func LogWarn($sText)
    _LogWrite("WARN", $sText)
EndFunc

Func LogStatus($sText)
    _LogWrite("STATUS", $sText)
EndFunc

Func LogError($sText)
    _LogWrite("ERROR", $sText)
EndFunc

Func _LogWrite($sLevel, $sText)
    Local $sLine = _
        @CRLF & "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] [" & $sLevel & "] " & _
        $sText

    ; GUI console
    If IsDeclared("g_h_EditText") Then
        Local $l_x_Color
        Switch $sLevel
            Case "ERROR"
                $l_x_Color = 0x322CCA ; Red
            Case "WARN"
                $l_x_Color = 0x790984 ; Purple
            Case "STATUS"
                $l_x_Color = 0xC76D09 ; Blue
            Case "INFO"
                $l_x_Color = 0x000000 ; Black
        EndSwitch

        ; Append text with color
        _GUICtrlRichEdit_SetSel($g_h_EditText, -1, -1)
        _GUICtrlRichEdit_SetCharColor($g_h_EditText, $l_x_Color)
        _GUICtrlRichEdit_AppendText($g_h_EditText, $sLine)
        _GUICtrlEdit_Scroll($g_h_EditText, 1)
    EndIf

    ; File log (crash safe)
    Local $hFile = FileOpen($g_s_LogFile, $FO_APPEND)
    If $hFile <> -1 Then
        FileWrite($hFile, $sLine)
        FileClose($hFile)
    EndIf
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