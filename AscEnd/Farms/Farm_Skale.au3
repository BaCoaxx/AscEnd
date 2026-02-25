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

Global $SkaleFarm1[13][2] = [ _
    [2008, -18155], _
    [840, -16260], _
    [-1004, -14234], _
    [-1589, -13323], _
    [-2169, -12429], _
    [-3101, -11898], _
    [-4474, -13221], _
    [-4214, -14827], _
    [-3812, -15729], _
    [-3375, -16871], _
    [-2721, -18156], _
    [-1989, -18791], _
    [-1438, -19012] _
]

Global $SkaleFarm2[17][2] = [ _
    [-1232, -12202], _
    [-318, -10787], _
    [701, -9421], _
    [1106, -8077], _
    [1529, -7412], _
    [2630, -5706], _
    [3229, -4448], _
    [4856, -3117], _
    [6085, -3625], _
    [7402, -3856], _
    [8660, -4144], _
    [11574, -3147], _
    [11919, -1498], _
    [12111, -712], _
    [11175, -4149], _
    [11883, -5267], _
    [11811, -7078] _
]

Global $SkalePath1[5][2] = [ _
    [-2181, -18754], _
    [-3112, -17432], _
    [-3409, -15841], _
    [-2384, -15052], _
    [-2437, -14040] _
]

Global $SkalePath2[8][2] = [ _
    [11218, -8771], _
    [9704, -10970], _
    [9322, -12461], _
    [8786, -13679], _
    [6614, -14993], _
    [5267, -16351], _
    [4297, -17163], _
    [4085, -19713] _
]

Func Farm_Skale()
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        SkaleSetup()

        While CountSlotS() > 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf

            Skale()

            If SurvivorMode() Then
                LogError("Survivor mode activated!")
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

    LogInfo("Did you hear what Prince Rurik got for Lady Althea?")
    RunTo($SkaleSetup)
    LogInfo("He went fishing and gave her a codpiece.")
    
    Sleep(500)

    Map_Move(4545, -19766)
    Map_WaitMapLoading(162, 1)
    Sleep(1000)
EndFunc

Func Skale()
    Map_Move(-17382, 17060)
    Map_WaitMapLoading(146, 1)

    Sleep(1000)

    $RunTime = TimerInit()

    LogInfo("Skale hunting season never ends!")
    
    UseSummoningStone()
    
    RunToSkale($SkaleFarm1)
    LogInfo("These skales really weigh on me.")
    
    RunTo($SkalePath1)
    LogInfo("Beware of the troll underneath...")
    
    RunToSkale($SkaleFarm2)
    LogInfo("Searing? Never heard of her.")
    
    RunTo($SkalePath2)
    LogInfo("One skale at a time before the sky turns red.")

    
    Other_RndSleep(250)
    
    LogInfo("Run complete. Restarting...")
    UpdateStats()
    If SurvivorMode() Then Return
    Sleep(1000)
    Map_Move(4545, -19766)
    Map_WaitMapLoading(162, 1)
    Sleep(1000)
EndFunc

Func RunToSkale($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        AggroMoveSmartFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 1800, 1800, $SkaleFilter, True, 1800)
        If SurvivorMode() Then Return
        Sleep(100)
    Next
EndFunc