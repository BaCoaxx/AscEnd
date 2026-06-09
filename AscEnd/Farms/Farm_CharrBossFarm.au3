#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Incognito/Coaxx

     Script Function:
        Charr Boss Farm Loop - Pre Searing

#ce ----------------------------------------------------------------------------

; Starting Northlands Path
Global $NormalGatePathLoop[3][2] = [ _
    [-12398, -13343], _
    [-12996, -11276], _
    [-11087, -8753] _
]

; Pathing from (Ascalon -> gate lever)
Global $CharrGatePathLoop[5][2] = [ _
    [3118, 6530], _
    [36, 6952], _
    [-3215, 12159], _
    [-4820, 12844], _
    [-5386, 12815] _
]

; If gate lever pull failed, path back up
Global $retrypathLoop[6][2] = [ _
    [-5321, 11802], _
    [-3690, 11398], _
    [-3296, 11764], _
    [-3663, 12426], _
    [-4820, 12844], _
    [-5386, 12815] _
]

; From gate lever -> through portal
Global $CharrPortalPathLoop[5][2] = [ _
    [-3925, 12379], _
    [-3760, 11583], _
    [-5409, 11872], _
    [-5497, 13166], _
    [-5572.39, 14130.93] _
]

; After charr farming, run back to the portal.
Global $RunBackPath[5][2] = [ _
    [-9018, -5112], _
    [-12717, -9127], _
    [-11811, -9887], _
    [-13022, -11138], _
    [-12626, -12638] _
]

Func Farm_CharrBossFarm()
    
    $CharrBossFarm = True ; Set this to 'True' if you only want to farm charr bosses, if 'False' will pickup all collectibles.
    InitialSetup()

    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
 
        While CountSlots() > 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf
            
            If Map_GetMapID() <> 148 Then
                RndTravel(148)
            EndIf

            RunToGate()

            While CountSlots() > 1
                If $NickRun Then
                    Local $currentCount = GetItemCountByModelID($NickItem[0])
                    If $currentCount >= 25 Then
                        LogInfo("Nicholas farm goal reached! Collected " & $currentCount & " " & $NickItem[1])
                        Return
                    EndIf
                EndIf

                If Not CharrCombatLoop() Then ExitLoop
            WEnd
        WEnd
    WEnd
EndFunc

Func RunToGate() ; Exit and run to the charr gate
    ExitAscalon()
    LogInfo("Running to the Charr Gate...")
    RunTo($CharrGatePathLoop)
    Sleep(1000)
EndFunc

Func OpenGate() ; Pull lever until we get to the Northlands
    
    If Map_GetMapID() <> 146 Then Return ; Keep track of where we are - Failsafe(Should be in Lakeside Country)

    Do
        LogInfo("Opening the gate lever...")
        Agent_GoSignpost(GetNearestGadgetToAgent(-2))
        Sleep(250)

        LogInfo("Moving to the Charr portal...")
        RunTo($CharrPortalPathLoop, 0)
        Map_InitMapIsLoaded()
        Map_Move(-5598, 14178)
        Map_WaitMapIsLoaded()

        If Map_GetMapID() <> 147 Then
            LogError("Failed to arrive in the Northlands...")
            Sleep(1000)
            LogWarn("Retrying the lever...")
            RunTo($retrypathLoop, 0)
        EndIf
    Until Map_GetMapID() = 147

EndFunc

Func CharrCombatLoop() ; Combat loop for charr bosses
    If Not $BotRunning Then Return False
    
    OpenGate()
    
    If Map_GetMapID() <> 147 Then Return False ; Keep track of where we are - Failsafe(Should be in the Northlands)

    LogInfo("Arrived in the Northlands, time to burn some furr.")
    
    $RunTime = TimerInit()

    UseSummoningStone()
    RunToUpkeep($NormalGatePathLoop, $gUpkeepSkills)

    Switch $gProf
        Case 63
            If Not GetPartyDead() Then FirstGroupEmo()
            If Not GetPartyDead() Then GrawlEmo() ; Fight Grawl if they are there?
            If Not GetPartyDead() Then SecondGroupEmo()
            If Not GetPartyDead() Then LeftCornerEmo()
            If Not GetPartyDead() Then BossesEmo()
        Case 42
            If Not GetPartyDead() Then FirstGroupNecro()
            If Not GetPartyDead() Then GrawlNecro()
            If Not GetPartyDead() Then SecondGroupNecro()
            If Not GetPartyDead() Then LeftCornerNecro()
            If Not GetPartyDead() Then BossesNecro()
    EndSwitch

    If GetPartyDead() Then
        LogWarn("You died because you couldn't fight your way out of a paper bag...")
        LogInfo("Returning to Ascalon...")
        UpdateStats()
        Return False
    EndIf

    LogInfo("Run complete. Running back to portal...")
    UpdateStats()

    Other_RndSleep(250)

    If Not RunBackToPortal() Then
        LogWarn("Failed to make it to the portal...")
        LogInfo("Returning to Ascalon...")
        Return False
    EndIf

    Return True
EndFunc

Func RunBackToPortal()
    LogInfo("Bless the tree of hindrance!!")
    MoveTo(798, -3309)
    RunToUpkeep($RunBackPath, $gUpkeepSkills)

    If GetPartyDead() Then
        LogWarn("Died on our way to the portal...")
        Return False
    EndIf

    Map_InitMapIsLoaded()
    Map_Move(-11652, -16955)
    Map_WaitMapIsLoaded()
    Sleep(750)

    If Map_GetMapID() = 146 Then
        LogWarn("Returned to Lakeside County. Retrying the lever...")
        RunTo($retrypathLoop)
        Return True
    EndIf

    Return False
EndFunc

Func InitialSetup()
    QuestActive(0x2E)
    Local $cAgState = Quest_GetQuestInfo(0x2E, "LogState")
    If $cAgState <> 1 Then
        LogInfo("Charr quest is not active. We are clear to proceed to the northlands.")
    Else
        LogWarn("Charr quest is active, we will abandon it so the way is clear.")
        Quest_AbandonQuest(0x2E)
        Sleep(2000)
    EndIf

    If Map_GetInstanceInfo("Type") <> 0 Then
        RndTravel(148)
    EndIf

    Sleep(1000)

    Local $Pri = Agent_GetAgentInfo(-2, "Primary")
    Local $Sec = Agent_GetAgentInfo(-2, "Secondary")

    $gProf =  ($Pri * 10) + $Sec ; Identify prof combos

    Switch $gProf
        Case 63
            LogInfo("Loading E/Mo upkeep skills and build...")
            Sleep(500)
            Attribute_LoadSkillTemplate("OgNEoKfN+XgsihShNzVSLQC")
            Sleep(250)
            $gUpkeepSkills = $EmoUpkeep
            Sleep(1500)
        Case 42
            LogInfo("Loading N/R upkeep skills and build...")
            Sleep(500)
            Attribute_LoadSkillTemplate("OAJUQqyaScF+ONTpNZi2zBAA")
            Sleep(250)
            $gUpkeepSkills = $NecroUpKeep
            Sleep(1500)
        Case Else
            LogWarn("We do not have a viable build setup for your profession.")
            LogStatus("Bot will now pause.")
            $BotRunning = False
            ResetStart()
            Return
    EndSwitch
EndFunc

Func FirstGroupEmo()    
    LogInfo("Clearing first group of charr...")
    
    MoveUpkeepEx(-10469.5, -7268.5, $gUpkeepSkills)

    Local $target = GetNearestCharrToAgent(-2)
    
    If Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_WAND Or Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_STAFF Or Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_BOW Then
        Agent_Attack($target)
    EndIf

    If StayAlive_Kill(-10317, -5215,"CharrFilter", 2600) Then
        LogInfo("First group of charr cleared.")
        Sleep(250)
        LogInfo("Picking up loot...")
        Sleep(250)
        PickUpLootInRange(2800)
    EndIf

    If GetPartyDead() Then Return False
EndFunc

Func FirstGroupNecro()
    LogInfo("Clearing first group of charr...")

    MoveUpkeepEx(-10587.55, -6728.15, $gUpkeepSkills)

    Local $target = GetNearestCharrToAgent(-2)

    Agent_Attack($target)

    If StayAlive_Kill(-10510.99, -6543.00,"CharrFilter", 2000) Then
        LogInfo("First group of charr cleared.")
        Sleep(250)
        LogInfo("Picking up loot...")
        Sleep(250)
        PickUpLootInRange(2000)
    EndIf

    If GetPartyDead() Then Return False
EndFunc

Func GrawlEmo()
    MoveUpkeepEx(-5605.52, -3688.85, $gUpkeepSkills)
    Sleep(250)

    $timer = TimerInit()

    Do 
        StayAlive()
    Until GetNumberOfFoesInRangeOfAgent(-2, 1800) > 0 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime - 105000

    If GetPartyDead() Then Return False

    If GetNumberOfFoesInRangeOfAgent(-2, 1800) = 0 Then
        LogInfo("No Grawl found!")
        Return True
    EndIf

    If StayAlive_Kill(-5605.52, -3688.85, "EnemyFilter", 1800) Then
        LogInfo("Grawl will not be a problem anymore.")
        Sleep(250)
        LogInfo("Picking up loot?")
        Sleep(250)
        PickUpLootInRange(2000, -5605.52, -3688.85)
    EndIf

    If GetPartyDead() Then Return False
EndFunc

Func GrawlNecro()
    MoveUpkeepEx(-5527.56, -4527.28, $gUpkeepSkills)
    LogInfo("Checking for grawl...")
    $timer = TimerInit()

    Do
        StayAlive()
        Sleep(100)
    Until GetNumberOfFoesInRangeOfAgent(-2, 1600) > 0 Or TimerDiff($timer) > 5000 Or GetPartyDead()

    If GetPartyDead() Then Return False

    ; Skip if nothing is there
    If GetNumberOfFoesInRangeOfAgent(-2, 1600) = 0 Then
        LogInfo("No grawl found, moving on.")
        Return True
    EndIf

    LogInfo("Taking out the trash...")
    If StayAlive_Kill(-5271.52, -4490.23, "EnemyFilter", 1500) Then
        LogInfo("Grawl cleared.")
    EndIf
    If GetPartyDead() Then Return False
    Return True
EndFunc

Func SecondGroupEmo()
    Do
        Sleep(250)
    Until GetEnergyPercent() > 0.8 Or GetPartyDead()

    If GetPartyDead() Then Return False

    MoveUpkeepEx(-4128.60, -3726.73, $gUpkeepSkills)
    MoveUpkeepEx(-3020.96, -3535.49, $gUpkeepSkills)
    
    If GetPartyDead() Then Return False
    
    LogInfo("Waiting for second group of charr...")
    
    $timer = TimerInit()

    Do
        StayAlive()
    Until GetNumberOfCharrInRangeOfXY(-964.62, -3168.00, 2400) > 2 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime

    If GetPartyDead() Then Return False

    If StayAlive_Kill(-964.62, -3168.00, "CharrFilter", 2400) Then LogInfo("Second group of charr cleared.")

    If GetPartyDead() Then Return False
EndFunc

Func SecondGroupNecro()
    LogInfo("Clearing second group of charr...")

    MoveUpkeepEx(-2558.01, -3666.43, $gUpkeepSkills)
    If GetPartyDead() Then Return False

    Local $target = GetNearestCharrToAgent(-2)
    If $target <> 0 Then Agent_Attack($target)

    If StayAlive_Kill(-2558.01, -3666.43, "CharrFilter", 2000) Then
        LogInfo("First group of charr cleared.")
        LogInfo("Checking for nearby foes...")
    EndIf

    If GetPartyDead() Then Return False
    
    Return True
EndFunc

Func LeftCornerEmo()
    MoveUpkeepEx(-571.48, -1651.94, $gUpkeepSkills)

    $timer = TimerInit()

    LogInfo("Waiting for left corner group...")
    Do
        StayAlive()
    Until GetNumberOfCharrInRangeOfAgent(-2, 1500) > 2 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime
    
    If GetPartyDead() Then Return False
    
    Local $target = GetNearestCharrToAgent(-2)

    If Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_WAND Or Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_STAFF Or Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_BOW Then
        Agent_Attack($target)
    EndIf

    MoveUpkeepEx(-571.48, -1651.94, $gUpkeepSkills) ; Move back incase we over aggro, imp can take a hit

    If Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_WAND Or Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_STAFF Or Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_BOW Then
        Agent_Attack($target)
    EndIf

    If StayAlive_Kill(-571.48, -1651.94, "CharrFilter", 1500) Then LogInfo("Left corner group cleared.")

    If GetPartyDead() Then Return False
EndFunc

Func LeftCornerNecro()
    MoveUpkeepEx(-146.63, -2284.94, $gUpkeepSkills)

    $timer = TimerInit()

    LogInfo("Waiting for left corner group...")
    
    Do
        StayAlive()
    Until GetNumberOfCharrInRangeOfAgent(-2, 1500) > 2 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime

    If GetPartyDead() Then Return False

    Local $target = GetNearestCharrToAgent(-2)

    Agent_Attack($target)

    MoveUpkeepEx(-146.63, -2284.94, $gUpkeepSkills) ; Move back incase we over aggro, imp can take a hit

    Agent_Attack($target)

    If StayAlive_Kill(-146.63, -2284.94, "CharrFilter", 2200) Then LogInfo("Left corner group cleared.")

    If GetPartyDead() Then Return False
EndFunc

Func BossesEmo()
    Local $SmokeSkin = 1452

    MoveUpkeepEx(-891.72, -3335.87, $gUpkeepSkills)
    
    $timer = TimerInit()

    Do
        StayAlive()
    Until GetNumberOfCharrInRangeOfXY(-41.25, -3953.44, 1400) < 6 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime

    If GetPartyDead() Then Return False

    If Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_WAND Or Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_STAFF Or Agent_GetAgentInfo(-2, "WeaponItemType") == $GC_I_TYPE_BOW Then
        Agent_Attack($SmokeSkin)
    EndIf

    If StayAlive_Kill(625.78, -3160.56, "CharrFilter", 2800) Then
        LogInfo("Bosses cleared.")
        Sleep(250)
        LogInfo("Picking up loot...")
        Sleep(250)
        PickUpLootInRange(1800, 1606.00, -3324.00)
        Sleep(250)
        PickUpLootInRange(1800, -571.48, -1651.94)
        Sleep(250)
        PickUpLootInRange(1800, -1283.85, -3241.65)
    EndIf
    
    If GetPartyDead() Then Return False
EndFunc

Func BossesNecro()
Local $SmokeSkin = 1452
    Local $timer

    MoveUpkeepEx(-891.72, -3335.87, $gUpkeepSkills)

    $timer = TimerInit()

    Do
        StayAlive()
        Sleep(100)
    Until GetNumberOfCharrInRangeOfXY(-485.44, 3128.33, 2700) < 6 Or GetPartyDead() Or TimerDiff($timer) > 1250

    If GetPartyDead() Then Return False

    LogInfo("Clearing boss group...")
    StayAlive_Kill(625.78, -3160.56, "CharrFilter", 2700)

    If GetPartyDead() Then Return False

    LogInfo("Picking up boss loot...")

    MoveTo(625.78, -3160.56)
    Sleep(750)

    PickUpLootInRange(3500, 625.78, -3160.56)
    Sleep(750)

    PickUpLootInRange(3500, 625.78, -3160.56)
    Sleep(750)

    PickUpLootInRange(3500, 625.78, -3160.56)

    If GetPartyDead() Then Return False

    LogInfo("Bosses complete.")
    Return True
EndFunc