#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Skale Fin Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $SkaleSetup[10][2] = [ _
    [-8595, -6568], _
    [-6951, -6772], _
    [-6465, -7068], _
    [-5162, -10982], _
    [-4610, -12248], _
    [-2326, -14004], _
    [817, -16124], _
    [1956, -18115], _
    [3914, -19674], _
    [4143, -19758] _
]

Global $SkalePath1[6][2] = [ _
    [2079, -18318], _
    [910, -16191], _
    [-2069, -14633], _
    [-2332, -14641], _
    [-2528, -15227], _
    [-3398, -15805] _
]

Global $SkaleFarm1[5][2] = [ _
    [-3746, -15898], _
    [-3374, -17231], _
    [-2749, -18649], _
    [-1568, -19209], _
    [-380, -19433] _
]

Global $SkalePath2[6][2] = [ _
    [-1568, -19209], _
    [-2517, -18502], _
    [-3619, -16209], _
    [-3407, -15809], _
    [-2398, -15259], _
    [-2213, -14285] _
]

Global $SkaleFarm2[2][2] = [ _
    [-1764, -13115], _
    [-1013, -11793] _
]

Global $SkalePath3[4][2] = [ _
    [-478, -15145], _
    [1095, -16530], _
    [1886, -18057], _
    [4139, -19782] _
]

Func Farm_Skale()
    Local $Skale[1][2] = [[429, "Skale Fins"]] 
    While 1
        If CountSlots() < $invCheck Then InventoryPre()
        If Not $BotRunning Then
            ResetStart()
            Return
        EndIf
        
        If Not $hasBonus Then GetBonus()
        
        SkaleSetup()

        While CountSlotS() >= $minRegSlots
            If Not $BotRunning Then
              If Not $NickRun And Not $TwoFiddy Then
                ResetStart()
              EndIf
              Return
            EndIf

            If $NickRun Or $TwoFiddy Then
              Local $currentCount = GetItemCountByModelID($Skale[0][0])
              Local $targetCount, $msg

              If $NickRun Then
                $targetCount = 25
                $msg = "Nicholas farm goal reached! "
              ElseIf $TwoFiddy Then
                $targetCount = 250
                $msg = "You got that mad stack brother! "
              EndIf

              If $currentCount >= $targetCount Then
                LogInfo($msg & "Collected " & $currentCount & " " & $Skale[0][1])
                Return
              EndIf
            EndIf
            
            Skale()

            If GetPartyDead() Or SurvivorMode() Then
                LogError("Run failed. Restarting...")
                ExitLoop
            EndIf
        WEnd
    WEnd
EndFunc

Func SkaleSetup()
    If Map_GetMapID() = 164 Then
        LogInfo("We are in Ashford Abbey. Starting the Skale Fin farm...")
    ElseIf Map_GetMapID() <> 164 And Map_IsMapUnlocked(164) Then
        LogInfo("We are not in Ashford Abbey. Teleporting to Ashford...")
        RndTravel(164)
        Sleep(2000)
    ElseIf Not Map_IsMapUnlocked(164) Then
        LogWarn("Ashford Abbey is not unlocked on this character, lets try to run there...")
        While Not UnlockAshford()
            LogError("Failed to unlock Ashford Abbey. Retrying...")
            Sleep(2000)
        WEnd
    EndIf

    ExitAshford()
    Sleep(1000)

    LogInfo("Did you hear what Prince Rurik got for Lady Althea?")

    RunTo($SkaleSetup)

    LogInfo("He went fishing and gave her a codpiece.")
    
    Sleep(500)
EndFunc

Func Skale()
    If GetPartyDead() Or SurvivorMode() Then Return

    Map_InitMapIsLoaded()
    Map_Move(4545, -19766)
    Map_WaitMapIsLoaded()

    Sleep(1000)

    Map_InitMapIsLoaded()
    Map_Move(-17382, 17060)
    Map_WaitMapIsLoaded()

    Sleep(1000)

    $RunTime = TimerInit()

    LogInfo("Skale hunting season never ends!")
    
    UseSummoningStone()
    Cache_SkillBar()
    
    RunTo($SkalePath1)

    If GetPartyDead() Or SurvivorMode() Then Return

    LogInfo("These skales really weigh on me.")
    
    RunToSkale($SkaleFarm1)

    If GetPartyDead() Or SurvivorMode() Then Return

    LogInfo("Searing? Never heard of her.")
    
    RunTo($SkalePath2)

    If GetPartyDead() Or SurvivorMode() Then Return

    LogInfo("Oops! I did it again..")
    
    RunToSkale($SkaleFarm2)

    If GetPartyDead() Or SurvivorMode() Then Return

    LogInfo("One skale at a time before the sky turns red.")

    RunTo($SkalePath3)

    If GetPartyDead() Or SurvivorMode() Then Return

    LogInfo("Nice day for fishing, aint it?")

    Other_RndSleep(250)
    
    LogInfo("Run complete. Restarting...")
    UpdateStats()
EndFunc

Func RunToSkale($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        AggroMoveSmartFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 1400, 1400, $SkaleFilter, True)
        If GetPartyDead() Or SurvivorMode() Then Return
        Sleep(100)
    Next
EndFunc