#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Incognito

     Script Function:
        Charr Boss Farm - Pre Searing

#ce ----------------------------------------------------------------------------

; Pathing from (Ashford -> gate lever)
Global $CharrGatePath[12][2] = [ _
    [-10627.17, -4904.59], _
    [-11205.81, -1182.31], _ 
    [-11641.63, 3165.87], _
    [-9960.85,  4901.69], _
    [-8935.92,  9607.10], _
    [-9457.02,  11908.34], _
    [-9458.33,  12982.73], _
    [-8495.56,  12924.29], _
    [-7555.65, 12870], _
    [-5508.00, 12787.00], _
    [-5758.45, 12803.25], _
    [-5502.18, 12899.44] _
]

; From gate lever -> through portal
Global $CharrPortalPath[3][2] = [ _
    [-3619.77, 11411.51], _
    [-5427.94, 11994.94], _
    [-5507.54, 13734.43] _
]

; Full charr route checkpoints
Global $CharrFarmPath[17][2] = [ _
   [-11629.00, -15956.36], _ ; Shrine
   [-12033.32, -14604.69], _ ; Away from shrine
   [-12584.11, -12676.72], _ ; Before oaks on right wall
   [-12048.53, -10065.56], _ ; Middle broken structure
   [-11199.42, -8363.05], _ ; Near oakheart on left by first charr group
   [-10901.07, -7369.80], _ ; First charr group
   [-8526.15, -5173.89], _ ; Right side of build past first charr group
   [-5625.61, -4524.08], _ ; Grawl
   [-3462.93, -3957.44], _ ; Before first charr roaming group
   [-1976.49, -3610.97], _ ; Charr roaming group middle top
   [-382.61, -2287.24], _ ; Before left group of charr
   [67.48, -2287.14], _ ; Left group of charr
   [-171.74, -1022.21], _ ; Pull back from left group of charr
   [-597.83, -1017.77], _ ; Middle between fire shrines
   [-148.26, -4245.54], _ ; Right side of charr group
   [-597.83, -1017.77], _ ; Middle between fire shrines
   [872.97, -3282.22] _ ; Final charr fight
]

Func Farm_CharrBossFarm()
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        CharrSetup()
        
        $CharrBossPickup = False ; Set this to 'True' if you want to pick up collectors items/blues on charr run, if 'False' will only pick up purples and higher
        
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
        Sleep(1000)
    EndIf
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
    
    ; 2) Pull lever to open the door
    LogInfo("Opening the gate lever...")
    Agent_GoSignpost(GetNearestGadgetToAgent(-2))
    Sleep(250)
    
    ; 3) Through the gate portal
    LogInfo("Moving to Charr portal...")
    RunTo($CharrPortalPath)
    Map_Move(-5598, 14178)
    Map_WaitMapLoading(147, 1)

    $RunTime = TimerInit()
    Sleep(3000)
    UseSummoningStone()
    LogInfo("Arrived at Charr map. Starting checkpoints...")

    RunToCBF($CharrFarmPath)

    LogInfo("Run complete. Restarting...")
    Resign()
    Sleep(5000)
    Map_ReturnToOutpost()
    Sleep(1000)
    Map_WaitMapLoading(164, 0)
    Sleep(1000)
EndFunc

Func RunToCBF($g_a_RunPath)
    For $i = 0 To UBound($g_a_RunPath) - 1
        AggroMoveToExFilter($g_a_RunPath[$i][0], $g_a_RunPath[$i][1], 2500, "CharrBossFilter")
        If SurvivorMode() Then
            LogError("Survivor mode activated!")
            Return
        EndIf
    Next
EndFunc

Func CharrBossFilter($aAgentPtr) ; Custom filter for CharrBoss that applies to farm.
	If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False
    Local $ModelID = Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber')
    Local $CharrBossID[7] = [1453, 1656, 1450, 1656, 1451, 1656, 1638] ; Array of charr boss model IDs
    Local $IsCharrBoss = False
    For $i = 0 To UBound($CharrBossID) - 1
        If $ModelID == $CharrBossID[$i] Then
            $IsCharrBoss = True
            ExitLoop
        EndIf
    Next
    If Not $IsCharrBoss Then Return False
    Return True
EndFunc

