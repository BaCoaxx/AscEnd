#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Farmer Hamnet - Pre Searing

#ce ----------------------------------------------------------------------------

Global $HamnetPath[2][2] = [ _
    [1926, 6161], _
    [2749, 3953] _
]

Global $currLevel = 0
Global $oldLevel = 0
Global $HamnetState

Func Farm_Hamnet()
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        HamnetSetup()

        While CountSlotS() > 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf

            Hamnet()
        WEnd
    WEnd
EndFunc

Func HamnetSetup()
    If Map_GetMapID() = 165 Then
        LogInfo("We are in Foible's Fair. Starting the bandit farm...")
    ElseIf Map_GetMapID() <> 165 And Map_IsMapUnlocked(165) Then
        LogInfo("We are not in Foible's Fair. Teleporting to Foible's Fair...")
        Map_RndTravel(165)
        Sleep(2000)
    ElseIf Not Map_IsMapUnlocked(165) Then
        LogWarn("Foible's Fair is not unlocked on this character, lets try to run there...")
        While Not UnlockFoibles()
            LogError("Failed to unlock Foible's Fair.  Retrying...")
            Sleep(2000)
        WEnd
    EndIf

    QuestActive(0x4A1)
    Sleep(750)
    $HamnetState = Quest_GetQuestInfo(0x4A1, "LogState")

    If $HamnetState = 1 Then
        LogInfo("Lets kill some Banditos!")
    ElseIf $HamnetState = 0 Then
        LogInfo("We don't have the Hamnet quest!")
        LogWarn("Check to see when it's next available.")
        LogStatus("Bot will now pause...")
        $BotRunning = False
        Return
    ElseIf $HamnetState = 3 Then
        LogInfo("Hamnet quest is completed!")
        LogError("Cannot proceed with the farm.")
        LogStatus("Bot will now pause...")
        $BotRunning = False
        Return
    EndIf

    Sleep(1000)

    MoveTo(-29.32, 8804.68)
    Map_Move(400, 7550) ; Gate trick setup
    Map_WaitMapLoading(161, 1)
    Sleep(2000)
    Map_Move(400, 7800)
    Map_WaitMapLoading(165, 0)
EndFunc

Func Hamnet()
    Sleep(2000)

    $currLevel = Agent_GetAgentInfo(-2, "Level")

    If $_19Stop And $currLevel >= 19 Then
        LogWarn("Reached level 19, stopping the farm.")
        LogStatus("Bot will now pause.")
        $BotRunning = False
        Return
    EndIf

    If $currLevel > $oldLevel Then
        LogWarn("You are now level " & $currLevel & "!")
        Sleep(750)
        $oldLevel = $currLevel
    EndIf

    Sleep(250)
    Map_Move(400, 7550)
    Map_WaitMapLoading(161, 1)
    Sleep(1000)

    $RunTime = TimerInit()

    LogInfo("Got imps? ")
    Sleep(250)
    UseSummoningStone()
    Sleep(250)
    RunTo($HamnetPath)
    Sleep(250)
    MoveTo(2650, 5122)
    AggroMoveSmartFilter(2574, 5885, 2200, 2200, $BanditFilter, True)

    If SurvivorMode() Then LogError("Survivor mode activated!")
    
    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Sleep(250)
    Resign()
    Sleep(5000)
    Map_ReturnToOutpost()
    Sleep(1000)
    Map_WaitMapLoading(165, 0)
    Sleep(1000)
EndFunc