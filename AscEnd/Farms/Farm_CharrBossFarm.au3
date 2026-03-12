#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Incognito/Coaxx

     Script Function:
        Charr Boss Farm - Pre Searing

#ce ----------------------------------------------------------------------------

; Starting Northlands Path
Global $NormalGatePath[6][2] = [ _
    [-11728, -16012], _
    [-12340, -13890], _
    [-12809, -12802], _
    [-13624, -11596], _
    [-12469, -8870], _
    [-11182, -7232] _
]

; Pathing from (Ashford -> gate lever)
Global $CharrGatePath[18][2] = [ _
    [-10813, -5410], _
    [-10630, -4006], _
    [-11138, -884], _
    [-11639, 1939], _
    [-11751, 2854], _
    [-11660, 3332], _
    [-11294, 3735], _
    [-10438, 4183], _
    [-9972, 4678], _
    [-9539, 6063], _
    [-9122, 8956], _
    [-9060, 10189], _
    [-9249, 11470], _
    [-9367, 12375], _
    [-9333, 12484], _
    [-9225, 12687], _
    [-7706, 12819], _
    [-5510, 12860] _
]

; From gate lever -> through portal
Global $CharrPortalPath[4][2] = [ _
    [-5508.00, 12787.00], _
    [-3619.77, 11411.51], _
    [-5427.94, 11994.94], _
    [-5507.54, 13734.43] _
]

Func Farm_CharrBossFarm()
    
    $CharrBossFarm = True ; Set this to 'True' if you only want to farm charr bosses, if 'False' will pickup all collectibles.
    CharrSetup()

    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        While CountSlots() > 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf
            
            CharrBossFarm()
        WEnd
    WEnd
EndFunc

Func CharrSetup()
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
            Attribute_LoadSkillTemplate("OgNEoIn99WgsihShNzVSLQC")
            Sleep(250)
            $gUpkeepSkills = $EmoUpkeep
            Sleep(1500)
        Case Else
            LogWarn("We do not have a viable build set up for your professions.")
            LogStatus("Bot will now pause.")
            $BotRunning = False
            ResetStart()
            Return
    EndSwitch
EndFunc

Func CharrBossFarm()
    If Map_GetMapID() = 164 Then
        LogInfo("We are in Ashford Abbey. Starting Charr Boss farming run...")
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

	ExitAshford()

    Other_RndSleep(250)
    
    ; 1) Ashford -> Charr Gate route 
    LogInfo("Running to Charr Gate...")
    RunTo($CharrGatePath)
    Sleep(1000)

    ; 2) Pull lever to open the door
    LogInfo("Opening the gate lever...")
    Agent_GoSignpost(GetNearestGadgetToAgent(-2))
    Sleep(250)
    
    ; 3) Through the gate portal
    LogInfo("Moving to the Charr portal...")
    RunTo($CharrPortalPath)
    Map_Move(-5598, 14178)
    Map_WaitMapLoading(147, 1)

    If Map_GetMapID() <> 147 Then
        LogError("Failed to arrive in the Northlands. Restarting...")
        Return
    EndIf

    Sleep(3000)

    LogInfo("Arrived in the Northlands, time to burn some furr.")
    
    $RunTime = TimerInit()

    UseSummoningStone()
    RunToUpkeep($NormalGatePath, $gUpkeepSkills)

    FirstGroup()

    Grawl() ; Fight Grawl if they are there?

    SecondGroup()

    LeftCorner()

    Bosses()

    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
    Resign()
    Sleep(5000)
    Map_ReturnToOutpost()
    Sleep(1000)
    Map_WaitMapLoading(164, 0)
    Sleep(1000)
EndFunc

Func FirstGroup()    
    $timer = TimerInit()

    Do
        StayAlive()
    Until GetNumberOfCharrInRangeOfXY(-11175, -7227, 3480) <= 5 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime

    LogInfo("Clearing first group of charr...")
    
    MoveUpkeepEx(-10930.39, -6798.76, $gUpkeepSkills)

    Local $target = GetNearestEnemyToAgent(-2)
    Agent_Attack($target)

    While GetNumberOfCharrInRangeOfAgent(-2, 2500) > 0 And Not GetPartyDead()
        StayAlive_Kill("CharrFilter")
    WEnd

    If GetPartyDead() Then Return False

    LogInfo("First group of charr cleared.")

    LogInfo("Preparing for second wave, moving back...")

    MoveUpkeepEx(-10930.39, -6798.76, $gUpkeepSkills)
    
    $timer = TimerInit()

    Do
        StayAlive()
    Until GetNumberOfCharrInRangeOfXY(-11175, -7227, 3000) > 3 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime

    Local $target = GetNearestEnemyToAgent(-2)

    Agent_Attack($target)

    While GetNumberOfCharrInRangeOfAgent(-2, 2500) > 0 And Not GetPartyDead()
        StayAlive_Kill("CharrFilter")
    WEnd

    If GetPartyDead() Then Return False

    LogInfo("Second group of charr cleared.")
    
    Sleep(250)
    LogInfo("Picking up loot...")
    Sleep(250)
    PickUpLoot()
EndFunc

Func Grawl()
    MoveUpkeepEx(-5639.52, -3424.85, $gUpkeepSkills)
    Sleep(250)
    LogInfo("Taking out the trash...")

    $timer = TimerInit()

    Do 
        StayAlive()
    Until GetNumberOfFoesInRangeOfAgent(-2, 900) > 0 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime - 90000

    StayAlive_Kill("EnemyFilter", 2000)

    If GetPartyDead() Then Return False

    LogInfo("Grawl will not be a problem anymore.")

    Sleep(250)
    LogInfo("Picking up loot?")
    Sleep(250)
    PickUpLoot()
EndFunc

Func SecondGroup()
    Do
        Sleep(250)
    Until Agent_GetAgentInfo(-2, "EnergyPercent") > 0.8 Or GetPartyDead()

    MoveUpkeepEx(-4128.60, -3726.73, $gUpkeepSkills)
    MoveUpkeepEx(-3020.96, -3535.49, $gUpkeepSkills)
    
    If GetPartyDead() Then Return False
    
    LogInfo("Waiting for second group of charr...")
    
    $timer = TimerInit()

    Do
        StayAlive()
    Until GetNumberOfCharrInRangeOfXY(-1283.85, -3241.65, 1000) > 2 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime

    While GetNumberOfCharrInRangeOfAgent(-2, 2500) > 0 And Not GetPartyDead()
        StayAlive_Kill("CharrFilter")
    WEnd

    If GetPartyDead() Then Return False

    LogInfo("Second group of charr cleared.")
EndFunc

Func LeftCorner()
    MoveUpkeepEx(-571.48, -1651.94, $gUpkeepSkills)

    $timer = TimerInit()

    LogInfo("Waiting for left corner group...")
    Do
        StayAlive()
    Until GetNumberOfCharrInRangeOfAgent(-2, 1500) > 2 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime
    
    If GetPartyDead() Then Return False
    
    Local $target = GetNearestEnemyToAgent(-2)

    Agent_Attack($target)

    MoveUpkeepEx(-571.48, -1651.94, $gUpkeepSkills) ; Move back incase we over aggro, imp can take a hit

    Agent_Attack($target)

    While GetNumberOfCharrInRangeOfXY(-571.48, -1651.94, 1400) > 0 And Not GetPartyDead()
        StayAlive_Kill("CharrFilter", 1400)
    WEnd

    If GetPartyDead() Then Return False

    LogInfo("Left corner group cleared.")
EndFunc

Func Bosses()
    Local $SmokeSkin = 1452

    MoveUpkeepEx(-891.72, -3335.87, $gUpkeepSkills)
    
    $timer = TimerInit()

    Do
        StayAlive()
    Until GetNumberOfCharrInRangeOfXY(-41.25, -3953.44, 1400) < 6 Or GetPartyDead() Or TimerDiff($timer) > $enemyKillTime

    If GetPartyDead() Then Return False

    Agent_Attack($SmokeSkin)

    While GetNumberOfCharrInRangeOfAgent(-2, 2500) > 0 And Not GetPartyDead()
        StayAlive_Kill("CharrFilter")
    WEnd
    
    If GetPartyDead() Then Return False
    
    LogInfo("Bosses cleared.")
    PickUpLoot()
EndFunc