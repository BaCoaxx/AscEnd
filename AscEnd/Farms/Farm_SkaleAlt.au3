#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         BareBuns69

     Script Function:
        Skale Alt Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $SkaleFarmAlt[4][2] = [ _
    [16060, 2900], _
    [14107, 1935], _
    [16539, 717], _
    [17989, 2234] _
]

Func Farm_SkaleAlt()
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        SkaleAltSetup()

        While CountSlots() > 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf

            SkaleAlt()
        WEnd
    WEnd
EndFunc

Func SkaleAltSetup()
    If Map_GetMapID() = 166 Then
        LogInfo("We are in Fort Ranik. Starting the Skale Alt farm...")
    ElseIf Map_GetMapID() <> 166 And Map_IsMapUnlocked(166) Then
        LogInfo("We are not in Fort Ranik. Teleporting to Fort Ranik...")
        Map_RndTravel(166)
        Sleep(2000)
    ElseIf Not Map_IsMapUnlocked(166) Then
        LogWarn("Fort Ranik is not unlocked on this character, lets try to run there...")
        While Not UnlockRanik()
            LogError("Failed to unlock Fort Ranik.  Retrying...")
            Sleep(2000)
        WEnd
    EndIf

    $spawn[0] = Agent_GetAgentInfo(-2, "X")
    $spawn[1] = Agent_GetAgentInfo(-2, "Y")
    Local $sp1 = ComputeDistance(23020, 10125, $spawn[0], $spawn[1])
        
    Select
        Case $sp1 <= 2400
            LogInfo("I heard you like your buns bare?")
            MoveTo(22865, 11380)
            MoveTo(22958, 11149)
        Case $sp1 > 2400 And $sp1 <= 4200
            LogInfo("Lady Althea calls me Thunder Buns!")
            MoveTo(23038, 11847)
        Case $sp1 > 4200
            LogInfo("Is it true about Gwen?")
            MoveTo(23186, 13527)
            MoveTo(23038, 11847)
    EndSelect

        MoveTo(22552, 7515) ; Gate trick setup
        Map_Move(22530, 7300)
        Map_WaitMapLoading(162, 1)
        Sleep(2000)
        Map_Move(22538, 7280)
        Map_WaitMapLoading(166, 0)
        Sleep(2000)
EndFunc

Func SkaleAlt()
    Other_RndSleep(250)
    MoveTo(22552, 7515)
    Map_Move(22530, 7300)
    Map_WaitMapLoading(162, 1)
    Sleep(1000)

    $RunTime = TimerInit()

    UseSummoningStone()
    RunTo($SkaleFarmAlt)
    Sleep(500)
    AggroMoveSmartFilter(17989, 2234, 2000, 2000, $SkaleFilter, True, 2000)
    Other_RndSleep(250)
    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
    Resign()
    Sleep(5000)
    Map_ReturnToOutpost()
    Sleep(1000)
    Map_WaitMapLoading(166, 0)
    Sleep(1000)
EndFunc