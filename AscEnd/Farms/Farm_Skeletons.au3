#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Incognito

     Script Function:
        Skeleton Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $SkelePath1[3][2] = [ _
    [13835.00, 2074.74], _
    [13870.79, -410.51], _
    [12607.06, -435.57] _
]

Global $SkeleFarm1[2][2] = [ _
    [11593.40, -423.30], _
    [9960.12, -693.21] _
]

Global $SkeleFarm2[10][2] = [ _
    [10974.93, -290.63], _
    [10524.65, 162.73], _
    [9453.36, 1028.12], _
    [9105.03, 1099.28], _
    [8008.07, 1163.78], _
    [7672.85, 947.64], _
    [6666.75, -159.94], _
    [4591.15, -771.00], _
	[2802.85, -1543.34], _
	[1785.55, -1956.05]  _
 ]

Func Farm_SkeletonLimbs()
    Local $SkeletonLimbs[1][2] = [[430, "Skeleton Limbs"]] 

    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()

        SkeletonSetup()

        While CountSlotS() > 1
            If Not $BotRunning Then
              If Not $NickRun And Not $TwoFiddy Then
                ResetStart()
              EndIf
              Return
            EndIf

            If $NickRun Or $TwoFiddy Then
              Local $currentCount = GetItemCountByModelID($SkeletonLimbs[0][0])
              Local $targetCount, $msg

              If $NickRun Then
                $targetCount = 25
                $msg = "Nicholas farm goal reached! "
              ElseIf $TwoFiddy Then
                $targetCount = 250
                $msg = "You got that mad stack brother! "
              EndIf

              If $currentCount >= $targetCount Then
                LogInfo($msg & "Collected " & $currentCount & " " & $SkeletonLimbs[0][1])
                Return
              EndIf
            EndIf

            SkeletonLimbs()
        WEnd
    WEnd
EndFunc

Func SkeletonSetup()
    If Map_GetMapID() = 164 Then
        LogInfo("We are in Ashford Abbey. Starting the Skeleton Limbs farm...")
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
EndFunc

Func SkeletonLimbs()
    If Map_GetMapID() <> 164 Then
        RndTravel(164)
    EndIf

    MoveTo(-13613, -7065)
    Map_InitMapIsLoaded()
    Map_Move(-14379, -7090)
    Map_WaitMapIsLoaded()
    Sleep(1000)

    $RunTime = TimerInit()
    
    RunTo($SkelePath1)

    If GetPartyDead() Or SurvivorMode() Then Return

    LogInfo("Come hither o pile of bones....")

    Sleep(1000)

    UseSummoningStone()

    RunToSkelly($SkeleFarm1)
    
    If GetPartyDead() Or SurvivorMode() Then Return
    
    LogInfo("I'm a bonafide hustler! Mhmm let's go.")
    RunToSkelly($SkeleFarm2)

    If GetPartyDead() Or SurvivorMode() Then Return
    
    Other_RndSleep(250)
    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
EndFunc

Func RunToSkelly($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        AggroMoveSmartFilter($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1], 1800, 1800, $SkellyFilter, True, 1800)
        If Survivor() Or GetPartyDead() Then
            LogError("Run failed. Restarting...")
            Return
        EndIf
        Sleep(100)
    Next
EndFunc