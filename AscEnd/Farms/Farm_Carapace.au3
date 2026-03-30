#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Dull Carapace Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $CarapaceSetup[10][2] = [ _
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

Global $CarapacePath1[2][2] = [ _
    [-14918, 15433], _
    [-15188, 14815] _
]

Global $CarapaceFarm[11][2] = [ _
    [-15358, 14551], _
    [-16805, 12898], _
    [-17370, 10669], _
    [-16618, 8814], _
    [-18950, 8400], _
    [-20347, 7509], _
    [-19935, 5051], _
    [-18909, 3565], _
    [-17312, 1740], _
    [-15768, 69], _
    [-15382, 646] _
]

Global $CarapacePath2[16][2] = [ _
    [-16339, 671], _
    [-16974, 1652], _
    [-18175, 2754], _
    [-19377, 4139], _
    [-19882, 5180], _
    [-20080, 6759], _
    [-19883, 7776], _
    [-19184, 8291], _
    [-18626, 8446], _
    [-17740, 9094], _
    [-17326, 10450], _
    [-17404, 11969], _
    [-16488, 13237], _
    [-15536, 14213], _
    [-15003, 15083], _
    [-14748, 15998] _
]

Func Farm_Carapace()
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        CarapaceSetup()

        While CountSlotS() > 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf

            If $NickRun Then
                Local $currentCount = GetItemCountByModelID($NickItem[0])
                If $currentCount >= 25 Then
                    LogInfo("Nicholas farm goal reached! Collected " & $currentCount & " " & $NickItem[1])
                    Return
                EndIf
            EndIf

            Carapace()

            If SurvivorMode() Then
                LogError("Survivor mode activated!")
                ExitLoop
            EndIf
        WEnd
    WEnd
EndFunc

Func CarapaceSetup()
    If Map_GetMapID() = 164 Then
        LogInfo("We are in Ashford Abbey. Starting the Dull Carapace farm...")
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
    Sleep(1000)

    LogInfo("Rumour has it, Sarah is out looking for Myrtle Weed again. Fifth time this week!")
    RunTo($CarapaceSetup)
    LogInfo("Oh Mr Twindle, if only she knew...")
    
    Sleep(500)
EndFunc

Func Carapace()
    Map_Move(4545, -19766)
    Map_WaitMapLoading(162, 1)
    Sleep(1000)

    $RunTime = TimerInit()

    LogInfo("I wish I could hold onto this moment, like a leaf clinging to a branch.")
    
    UseSummoningStone()
    
    RunTo($CarapacePath1)
    LogInfo("Crunchy underfoot. I should probably tread lighter.")
    
    RunToCarapace($CarapaceFarm)
    LogInfo("They fall so easily. Guess everything does, eventually...")
    
    RunTo($CarapacePath2)
    LogInfo("Autumn is nature's way of reminding us that letting go can be beautiful.")

    Other_RndSleep(250)
    
    LogInfo("Run complete. Restarting...")
    UpdateStats()
    If SurvivorMode() Then Return
    Sleep(1000)
    Map_Move(-17382, 17060)
    Map_WaitMapLoading(146, 1)
    Sleep(1000)
EndFunc

Func RunToCarapace($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        AggroMoveSmartFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 1400, 1400, $CarapaceFilter, True, 1400)
        If SurvivorMode() Then Return
        Sleep(100)
    Next
EndFunc