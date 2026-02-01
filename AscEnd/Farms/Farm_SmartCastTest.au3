#include-once

#cs ----------------------------------------------------------------------------

	 AutoIt Version: 3.3.18.0
	 Author:         Coaxx

	 Script Function:
		Smart Cast Test - Pre Searing

#ce ----------------------------------------------------------------------------

Global $SCPath[8][2] = [ _
    [-10415, -5415], _
    [-10342, -3819], _
    [-10374, -2275], _
    [-10444, -284], _
    [-9636, -300], _
    [-9632, -1476], _
    [-9625, -3531], _
    [-9622, -5470] _
]

Func Farm_SmartCastTest()

    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBoners Then GetBoners()

        SCSetup()

	    While CountSlots() > 1
		    SCTest()
	    WEnd
    WEnd
EndFunc

Func SCSetup()
    If Map_GetMapID() = 164 Then
        LogInfo("We are in Ashford Abbey. Starting Smart Cast Test...")
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

    ExitAshford() ; Gate trick setup
    Map_Move(-11100, -6200)
    Map_WaitMapLoading(164, 0)
    Sleep(2000)
EndFunc

Func SCTest()
    Map_Move(-11089, -6250) ; Leave Ashford Abbey
    Map_WaitMapLoading(146, 1)
    Cache_SkillBar()

    Sleep(1000)

	$RunTime = TimerInit()

    UseSummoningStone()
    Other_RndSleep(250)
    RunToSC($SCPath)
    Other_RndSleep(250)
    LogInfo("Smart Cast Test complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
    Resign()
    Sleep(5000)
    Map_ReturnToOutpost()
    Sleep(1000)
    Map_WaitMapLoading(164, 0)
    Sleep(1000)
EndFunc

Func RunToSC($g_a_RunPath)
    For $i = 0 To UBound($g_a_RunPath) - 1
        AggroMoveToExFilter($g_a_RunPath[$i][0], $g_a_RunPath[$i][1], 1300)
        If SurvivorMode() Then
            LogError("Survivor mode activated!")
            Return
        EndIf
    Next
EndFunc