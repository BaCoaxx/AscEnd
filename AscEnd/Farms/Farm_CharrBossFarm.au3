#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Incognito

     Script Function:
        Charr Boss Farm - Pre Searing

#ce ----------------------------------------------------------------------------

; Res Shrine Piken
Global $ResPikenPath[10][2] = [ _
    [-16290, 265], _
    [-15484, -605], _
    [-14307, -2174], _
    [-13175, -3228], _
    [-13356, -3970], _
    [-14713, -5473], _
    [-14836, -6458], _
    [-14362, -8275], _
    [-14357, -10104], _
    [-13699, -11596] _
]

; Res Shrine Gate
Global $ResGatePath[5][2] = [ _
    [-11006, -16076], _
    [-11913, -14798], _
    [-12326, -13915], _
    [-12839, -12747], _
    [-13659, -11658] _
]

; Starting Northlands Path
Global $NormalGatePath[4][2] = [ _
    [-11728, -16012], _
    [-12340, -13890], _
    [-12809, -12802], _
    [-13624, -11596] _
]

; Pathing from (Ashford -> gate lever)
Global $CharrGatePath[10][2] = [ _
    [-10627.17, -4904.59], _
    [-11205.81, -1182.31], _ 
    [-11641.63, 3165.87], _
    [-9960.85, 4901.69], _
    [-8935.92, 9607.10], _
    [-9457.02, 11908.34], _
    [-9458.33, 12982.73], _
    [-8495.56, 12924.29], _
    [-7555.65, 12870], _
    [-5502.18, 12899.44] _
]

; From gate lever -> through portal
Global $CharrPortalPath[4][2] = [ _
    [-5508.00, 12787.00], _
    [-3619.77, 11411.51], _
    [-5427.94, 11994.94], _
    [-5507.54, 13734.43] _
]

; Full charr route checkpoints
Global $CharrFarmPath[9][2] = [ _
    [-12469.07, -8870.34], _  ; near oakheart on left by first charr group
    [-10939.57, -7653.62], _  ; first charr group
    [-5008.78, -4171.82], _  ; grawl
    [-3462.93, -3957.44], _  ; before first charr roaming group
    [-1976.49, -3610.97], _  ; charr roaming group middle top
    [-850.03, -3451.81], _  ; middle away from charr
    [-388.72, -3312.43], _  ; middle reposition
    [-377.84, -1027.94], _  ; middle reposition
    [1101.78, -3285.21] _   ; steps
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
        Sleep(2000)
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
    RunTo($CharrGatePath, True)
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

    $RunTime = TimerInit()
    Sleep(3000)
    UseSummoningStone()
    LogInfo("Arrived in the Northlands, time to burn some furr.")

    RunTo($NormalGatePath)
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
        AggroMoveToExFilter($g_a_RunPath[$i][0], $g_a_RunPath[$i][1], 3500, "CharrBossFilter")
        
        If GetIsDead() Then

            $deaths += 1
            If $deaths >= 10 Then
                LogError("We died 10 times in a row, ditching this run!")
                Return
            EndIf

            LogError("We died, starting over...")
            Sleep(12000) ; Time to respawn

            $spawn[0] = Agent_GetAgentInfo(-2, "X")
            $spawn[1] = Agent_GetAgentInfo(-2, "Y")
            Local $sp1 = ComputeDistance(-16290, 265, $spawn[0], $spawn[1]) ; Use piken shrine coords as reference
            
            Select
                Case $sp1 <= 1000
                    LogWarn("Respawned near Piken, let's get back to work!")
                    RunTo($ResPikenPath, True)
                Case Else
                    LogWarn("Respawned near the gate, the better of the two!")
                    RunTo($ResGatePath, True)
            EndSelect

            $i = 0
            Sleep(2000)
        EndIf
        
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

