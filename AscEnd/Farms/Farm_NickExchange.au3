#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Nicholas Sandford Exchange

#ce ----------------------------------------------------------------------------

Global $NickPath[17][2] = [ _
    [22494, 4774], _
    [22401, 4316], _
    [20791, 3326], _
    [17206, 3220], _
    [16473, 3210], _
    [16753, 5600], _
    [16734, 7686], _
    [17271, 8356], _
    [17349, 8785], _
    [16899, 10182], _
    [15917, 10751], _
    [14750, 11212], _
    [14313, 11642], _
    [13724, 13095], _
    [14269, 13921], _
    [15082, 15039], _
    [15253, 16440] _
]

Func Farm_NickExchange()
        If CountSlots() < 1 Then
            LogWarn("We don't have any free slots for the exchange.")
            LogInfo("Please make sure you have at least 1 free slot.")
            LogStatus("Bot will now pause...")
            $BotRunning = False
            Return
        EndIf

        While 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf

            NickExchange()
        WEnd
EndFunc

Func NickExchange()
    Local $NickCount = GetItemCountByModelID(_GetNicholasItemByOffset(0)[0])

    If $NickCount = 0 Then
        LogWarn("We don't currently have today's item.")
        LogStatus("Bot will now pause...")
        $BotRunning = False
        Return
    ElseIf $NickCount >= 1 And $NickCount < 5 Then
        LogWarn("A hero so slow, I half expect the item to collect itself out of pity.")
        LogStatus("Bot will now pause...")
        $BotRunning = False
        Return
    ElseIf $NickCount >= 5 Then
        Local $ExchangeCount = Floor($NickCount / 5)
        LogInfo("Success, you aren't just a Chicken Chaser after all!")
        Sleep(250)
        LogInfo("We have " & $NickCount & " "& _GetNicholasItemByOffset(0)[1] & ". That's " & $ExchangeCount & " exchange/s.")
        Sleep(500)
    EndIf

    If Map_GetMapID() = 166 Then
        LogInfo("We are in Fort Ranik. Let's go find Nicholas...")
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
            LogInfo("A hero's worth is measured in spoils, not titles.")
            MoveTo(22865, 11380)
            MoveTo(22958, 11149)
        Case $sp1 > 2400 And $sp1 <= 4200
            LogInfo("Even Grendich Courthouse remembers the diligent collector.")
            MoveTo(23038, 11847)
        Case $sp1 > 4200
            LogInfo("Yak's Bend waits for no one who leaves treasures behind.")
            MoveTo(23186, 13527)
            MoveTo(23038, 11847)
    EndSelect

    MoveTo(22552, 7515)
    Map_Move(22530, 7300)
    Map_WaitMapLoading(162, 1)
    Sleep(1000)

    $RunTime = TimerInit()

    UseSummoningStone()

    RunTo($NickPath)
    Sleep(500)
    Agent_GoNPC(GetNick())
    Sleep(500)
    Ui_Dialog(0x85)
    Sleep(500)

    If $ExchangeCount = 1 Then
        Ui_Dialog(0x84)
    Else
        Ui_Dialog(0x86)
    EndIf

    Sleep(1000)

    LogInfo("Nichalos Sandford exchange completed!")
    LogStatus("Bot will now pause...")
    $BotRunning = False
    Return
EndFunc