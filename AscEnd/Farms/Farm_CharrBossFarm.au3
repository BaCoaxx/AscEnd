#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Incognito/Coaxx

     Script Function:
        Charr Boss Farm - Pre Searing

#ce ----------------------------------------------------------------------------

; Starting Northlands Path
Global $NormalGatePath[3][2] = [ _
    [-12398, -13343], _
    [-12996, -11276], _
    [-11087, -8753] _
]

; Pathing from (Ascalon -> gate lever)
Global $CharrGatePath[4][2] = [ _
    [3118, 6530], _
    [36, 6952], _
    [-3215, 12159], _
    [-5413, 12808] _
]

; If gate lever pull failed, path back up
Global $retrypath[5][2] = [ _
    [-5321, 11802], _
    [-3690, 11398], _
    [-3296, 11764], _
    [-3663, 12426], _
    [-5408, 12806] _
]

; From gate lever -> through portal
Global $CharrPortalPath[5][2] = [ _
    [-3925, 12379], _
    [-3760, 11583], _
    [-5409, 11872], _
    [-5497, 13166], _
    [-5572.39, 14130.93] _
]

Func Farm_CharrBossFarm()
    
    $CharrBossFarm = True ; Set this to 'True' if you only want to farm charr bosses, if 'False' will pickup all collectibles.
    InitialSetup()

    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()

        GateTrick()
        
        While CountSlots() > 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf
            
            CharrBossFarm()
        WEnd
    WEnd
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
        Map_RndTravel(148)
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

Func GateTrick() ; Set this up outside of initial for when we come back from inventory management.
    If Map_GetMapID() = 148 Then
        LogInfo("We are in Ascalon. Starting Charr Boss farming run...")
    ElseIf Map_GetMapID() <> 148 And Map_IsMapUnlocked(148) Then
        LogInfo("We are not in Ascalon. Teleporting to Ascalon...")
        Map_RndTravel(148)
        Sleep(2000)
    EndIf

    ExitAscalon() ; Gate trick setup
    Map_Move(7460.79, 5591.82)
    Map_WaitMapLoading(148, 0)
    Sleep(2000)
EndFunc

Func CharrBossFarm()
    ExitAscalon()
    
    ; 1) Ascalon -> Charr Gate route 
    LogInfo("Running to the Charr Gate...")
    RunTo($CharrGatePath)
    Sleep(1000)

    Local $attempts = 0

    Do
        $attempts += 1

        LogInfo("Opening the gate lever...")
        Agent_GoSignpost(GetNearestGadgetToAgent(-2))
        Sleep(250)

        LogInfo("Moving to the Charr portal...")
        RunTo($CharrPortalPath)
        Map_Move(-5598, 14178)
        Map_WaitMapLoading(147, 1)

        If Map_GetMapID() <> 147 Then
            LogError("Failed to arrive in the Northlands...")
            Sleep(1000)
            LogWarn("Retrying the lever...")
            RunTo($retrypath)
        EndIf
    Until Map_GetMapID() = 147 Or $attempts >= 5

    If Map_GetMapID() <> 147 Then
        LogError("Could not reach the Northlands after 5 attempts...")
        LogWarn("Restarting from Ascalon...")
        UpdateStats()
        Other_RndSleep(250)
        Resign()
        Sleep(5000)
        Map_ReturnToOutpost()
        Sleep(1000)
        Map_WaitMapLoading(148, 0)
        Sleep(1000)
        Return
    EndIf

    Sleep(3000)

    LogInfo("Arrived in the Northlands, time to burn some furr.")
    
    $RunTime = TimerInit()

    UseSummoningStone()
    RunToUpkeep($NormalGatePath, $gUpkeepSkills)

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

    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
    Resign()
    Sleep(5000)
    Map_ReturnToOutpost()
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
    ; First standing/wait spot
    MoveUpkeepEx(-381, -2202, $gUpkeepSkills)

    $timer = TimerInit()

    LogInfo("Waiting for left corner group...")
    Do
        StayAlive()
    Until GetNumberOfCharrInRangeOfAgent(-2, 1500) > 2 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime

    If GetPartyDead() Then Return False

    Local $target = GetNearestCharrToAgent(-2)

    If $target <> 0 Then
        Agent_Attack($target)
        Sleep(500)
    EndIf

    ; Move-back safety spot
    MoveUpkeepEx(316, -2627, $gUpkeepSkills)

    If $target <> 0 Then Agent_Attack($target)

    LogInfo("Clearing left corner ele boss group...")

    ; First kill spot
    If StayAlive_Kill(316, -2627, "CharrFilter", 2300) Then
        LogInfo("Left corner first kill spot cleared.")
    EndIf

    If GetPartyDead() Then Return False

    ; Second kill spot
    MoveUpkeepEx(614, -2627, $gUpkeepSkills)

    If StayAlive_Kill(614, -2627, "CharrFilter", 2400) Then
        LogInfo("Left corner ele boss cleared.")
    EndIf

    If GetPartyDead() Then Return False

    LogInfo("Picking up left corner ele boss loot...")
    PickUpLootInRange(3700, 614, -2627)

    Return True
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
    LogInfo("Clearing remaining boss group...")

    ; Kill spot 1
    MoveUpkeepEx(1276, -2344, $gUpkeepSkills)

    If StayAlive_Kill(1276, -2344, "CharrFilter", 2500) Then
        LogInfo("Boss kill spot 1 cleared.")
    EndIf

    If GetPartyDead() Then Return False

    Sleep(750)

    ; Kill spot 2
    MoveUpkeepEx(1276, -2344, $gUpkeepSkills)

    If StayAlive_Kill(1276, -2344, "CharrFilter", 3400) Then
        LogInfo("Boss kill spot 2 cleared.")
    EndIf

    If GetPartyDead() Then Return False

    Sleep(1000)

    LogInfo("Picking up remaining boss loot...")

    ; Loot after both boss spots are clear
    PickUpLootInRange(4800, 1276, -2344)

    If GetPartyDead() Then Return False

    LogInfo("Bosses complete.")
    Return True
EndFunc