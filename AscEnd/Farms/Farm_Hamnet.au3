#include-once

#cs ----------------------------------------------------------------------------

	 AutoIt Version: 3.3.18.0
	 Author:         Coaxx

	 Script Function:
		Farmer Hamnet - Pre Searing

#ce ----------------------------------------------------------------------------

Global $HamnetPath[3][2] = [ _
    [1709, 6516], _
    [2425, 5497], _
    [2646, 4491] _
]

Global $currLevel = 0
Global $oldLevel = 0
Global $memClear = 0
Global $HamnetState

Func Farm_Hamnet()
    
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBoners Then GetBoners()
        
        HamnetSetup()

        While CountSlotS() > 1
            If Not $BotRunning Then ResetStart() Return

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

    Quest_ActiveQuest(0x4A1)
    $HamnetState = Quest_GetQuestInfo(0x4A1, "LogState")

    If $HamnetState = 1 Then
        LogInfo("Lets kill some Banditos!")
    ElseIf $HamnetState = 0 Then
        LogInfo("We don't have the Hamnet quest!")
        LogWarn("Check to see when it's next available.")
        LogStatus("Bot will now pause.")
        $BotRunning = False
        Return
    ElseIf $HamnetState = 3 Then
        LogInfo("Hamnet quest is completed!")
        LogError("Cannot proceed with the farm.")
        LogStatus("Bot will now pause.")
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
    Sleep(2000)
EndFunc

Func Hamnet()
    If $memClear >= 10 Then
        Memory_Clear()
        Sleep(4000)
        $memClear = 0
    EndIf

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

    Other_RndSleep(250)
    Map_Move(400, 7550)
    Map_WaitMapLoading(161, 1)
    Sleep(2000)

    $RunTime = TimerInit()

    Local $lDeadlock = TimerInit()

    While TimerDiff($lDeadlock) < 300000 ; 5 minute deadlock
        LogInfo("Got imps? ")
        Sleep(250)
        UseSummoningStone()
        Sleep(250)
        RunToHamnet($HamnetPath)
        Other_RndSleep(250)
        LogInfo("Run complete. Restarting...")
        UpdateStats()
        Other_RndSleep(250)
        Resign()
        Sleep(5000)
        Map_ReturnToOutpost()
        Sleep(1000)
        Map_WaitMapLoading(165, 0)
        Sleep(1000)
        ExitLoop
    WEnd

    If TimerDiff($lDeadlock) >= 300000 Then
        LogError("DEADLOCK DETECTED: Run exceeded 5 minutes!")
        Resign()
        Sleep(5000)
        Map_ReturnToOutpost()
        Sleep(1000)
        Map_WaitMapLoading(165, 0)
        Sleep(1000)
        LogWarn("Recovered from deadlock, restarting...")
    EndIf
    
    $memClear += 1
EndFunc

Func RunToHamnet($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        AggroMoveToExFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 2500, "BanditFilter")
        If SurvivorMode() Then
            LogError("Survivor mode activated!")
            Return
        EndIf
    Next
EndFunc

Func BanditFilter($aAgentPtr) ; Custom filter for bandits in pre.

	If Agent_GetAgentInfo($aAgentPtr, 'Allegiance') <> 3 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'HP') <= 0 Then Return False
    If Agent_GetAgentInfo($aAgentPtr, 'IsDead') > 0 Then Return False

    Local $ModelID = Agent_GetAgentInfo($aAgentPtr, 'PlayerNumber')
    Local $BanditModelIDs[10] = [1346, 1420, 1421, 1422, 7824, 7825, 7839, 7840, 7857, 7858] ; Array of bandit model IDs
    Local $IsBandit = False
    For $i = 0 To UBound($BanditModelIDs) - 1
        If $ModelID == $BanditModelIDs[$i] Then
            $IsBandit = True
            ExitLoop
        EndIf
    Next
    If Not $IsBandit Then Return False

    Return True
EndFunc
