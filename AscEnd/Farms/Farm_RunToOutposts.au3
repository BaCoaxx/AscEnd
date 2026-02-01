#include-once

#cs ----------------------------------------------------------------------------

	 AutoIt Version: 3.3.18.0
	 Author:         Coaxx

	 Script Function:
		RunToOutposts

#ce ----------------------------------------------------------------------------

Global $Ashford[9][2] = [ _
    [6000, 3172], _
    [4345, 413], _
    [1665, -3587], _
    [0, -5360], _
    [-2500, -6337], _
    [-3908, -6971], _
    [-5919, -6860], _
    [-8193, -6325], _
    [-10800, -6213] _
]

Global $Foibles1[10][2] = [ _
    [-11081, -7924], _
    [-11429, -9657], _
    [-11708, -11038], _
    [-12085, -12690], _
    [-12521, -14480], _
    [-12944, -15820], _
    [-12250, -17199], _
    [-11552, -18787], _
    [-10713, -19145], _
    [-12617, -20123] _
]

Global $Foibles2[10][2] = [ _
    [8468, 17712], _
    [8270, 16493], _
    [7072, 15513], _
    [6032, 15367], _
    [5011, 13406], _
    [3456, 11111], _
    [2522, 9896], _
    [1748, 7755], _
    [1109, 6779], _
    [620, 7311] _
]

Global $Ranik1[17][2] = [ _
    [6002, 2568], _
    [5479, 655], _
    [5435, -1486], _
    [5900, -3333], _
    [7062, -5208], _
    [8249, -7551], _
    [9327, -8769], _
    [9527, -9839], _
    [9627, -11272], _
    [9181, -12522], _
    [9336, -13162], _
    [7586, -14406], _
    [6261, -15311], _
    [5408, -16356], _
    [4219, -17012], _
    [4009, -19226], _
    [4157, -19693] _
]

Global $Ranik2[24][2] = [ _
    [-14552, 15990], _
    [-13824, 14783], _
    [-12054, 14465], _
    [-10826, 13151], _
    [-9043, 11752], _
    [-6701, 10264], _
    [-3927, 8904], _
    [-2099, 7864], _
    [91, 6563], _
    [899, 6259], _
    [3066, 6269], _
    [4548, 5354], _
    [5943, 5528], _
    [6868, 5023], _
    [7717, 3908], _
    [8760, 2667], _
    [10875, 2703], _
    [12456, 2593], _
    [14964, 1196], _
    [18830, 1523], _
    [19224, 2164], _
    [22044, 3655], _
    [22535, 4732], _
    [22610, 6887] _
]

Global $Barradin1[11][2] = [ _
    [4343, 5631], _
    [2300, 6670], _
    [-337, 7103], _
    [-3468, 9849], _
    [-4531, 11453], _
    [-7478, 11814], _
    [-8767, 10876], _
    [-9144, 8252], _
    [-11047, 7611], _
    [-12431, 8422], _
    [-13356, 10012] _
]

Global $Barradin2[27][2] = [ _
    [21175, 13361], _
    [20466, 13785], _
    [19368, 13238], _
    [18748, 12590], _
    [17284, 11856], _
    [15319, 8789], _
    [14090, 6254], _
    [12757, 4515], _
    [12281, 3138], _
    [11284, 3041], _
    [10567, 3221], _
    [10046, 1045], _
    [11911, -683], _
    [11343, -2455], _
    [7948, -3225], _
    [6000, -4012], _
    [3000, -3143], _
    [661, -3136], _
    [-168, -3384], _
    [-731, -2105], _
    [-2003, -2064], _
    [-3390, -392], _
    [-6184, -206], _
    [-7780, -178], _
    [-7890, 879], _
    [-7910, 1415], _
    [-7531, 1424] _
]

Func Farm_RunToOutposts()
    
    If CountSlots() < 4 Then InventoryPre()
    If Not $hasBoners Then GetBoners()
    
    Sleep(2000)
    LogInfo("Running to outposts.")
    RunOutpost()
    LogStatus("Bot will now pause.")
    $BotRunning = False
    ResetStart()
    Return
EndFunc

Func RunOutpost()
    LogInfo("Let's go for a stroll.")
    
    ; Run each outpost until we get there
    Local $outposts = ["Ashford", "Barradin", "Ranik", "Foibles"]
    For $outpost In $outposts
        Local $success = False
        While Not $success

            If Not $BotRunning Then ResetStart() Return

            Switch $outpost
                Case "Ashford"
                    $success = UnlockAshford()
                Case "Barradin"
                    $success = UnlockBarradin()
                Case "Ranik"
                    $success = UnlockRanik()
                Case "Foibles"
                    $success = UnlockFoibles()
            EndSwitch
            
            If Not $success Then
                LogError("Failed to unlock " & $outpost & ". Retrying...")
                Sleep(2000)
            EndIf
        WEnd
    Next
    
    LogWarn("All outposts, brutally unlocked!!")
EndFunc

Func UnlockAshford()
    If Map_IsMapUnlocked(164) Then
        LogError("Ashford Abbey is already unlocked.")
        Return True
    EndIf
    
    LogInfo("Heading to Ashford Abbey..")
    If Map_GetMapID() <> 148 Then Map_RndTravel(148)
    ExitAscalon()
    $RunTime = TimerInit()
    UseSummoningStone()
    
    If Not RunToMove($Ashford) Then Return False
    
    UpdateStats()
    Map_Move(-11250, -6200)
    Map_WaitMapLoading(164, 0)
    Sleep(1000)
    
    If Map_GetMapID() = 164 Then
        LogWarn("Ashford Abbey unlocked.")
        Return True
    EndIf
    
    Return False
EndFunc

Func UnlockBarradin()
    If Map_IsMapUnlocked(163) Then
        LogError("Barradin Estate is already unlocked.")
        Return True
    EndIf
    
    LogInfo("Heading to Barradin Estate..")
    If Map_GetMapID() <> 148 Then Map_RndTravel(148)
    ExitAscalon()
    $RunTime = TimerInit()
    UseSummoningStone()
    
    If Not RunToMove($Barradin1) Then Return False
    
    Map_Move(-14650, 10030)
    Map_WaitMapLoading(160, 1)
    Sleep(1000)
    UseSummoningStone()
    
    If Not RunToMove($Barradin2) Then Return False
    
    UpdateStats()
    Map_Move(-7200, 1427)
    Map_WaitMapLoading(163, 0)
    Sleep(1000)
    
    If Map_GetMapID() = 163 Then
        LogWarn("Barradin Estate unlocked.")
        Return True
    EndIf
    
    Return False
EndFunc

Func UnlockRanik()
    If Map_IsMapUnlocked(166) Then
        LogError("Fort Ranik is already unlocked.")
        Return True
    EndIf
    
    LogInfo("Heading to Fort Ranik..")
    If Map_GetMapID() <> 148 Then Map_RndTravel(148)
    ExitAscalon()
    $RunTime = TimerInit()
    UseSummoningStone()
    
    If Not RunToMove($Ranik1) Then Return False
    
    Map_Move(4300, -19900)
    Map_WaitMapLoading(162, 1)
    UseSummoningStone()
    
    If Not RunToMove($Ranik2) Then Return False
    
    UpdateStats()
    Map_Move(22600, 7250)
    Map_WaitMapLoading(166, 0)
    Sleep(1000)
    
    If Map_GetMapID() = 166 Then
        LogWarn("Fort Ranik unlocked.")
        Return True
    EndIf
    
    Return False
EndFunc

Func UnlockFoibles()
    If Map_IsMapUnlocked(167) Then
        LogError("Foibles Fair is already unlocked.")
        Return True
    EndIf
    
    LogInfo("Heading to Foibles Fair..")
    If Map_GetMapID() <> 164 Then Map_RndTravel(164)
    ExitAshford()
    $RunTime = TimerInit()
    UseSummoningStone()
    
    If Not RunToMove($Foibles1) Then Return False
    
    Map_Move(-14000, -20200)
    Map_WaitMapLoading(161, 1)
    Sleep(1000)
    UseSummoningStone()
    
    If Not RunToMove($Foibles2) Then Return False
    
    UpdateStats()
    Map_Move(300, 7700)
    Map_WaitMapLoading(167, 0)
    Sleep(1000)
    
    If Map_GetMapID() = 167 Then
        LogWarn("Foibles Fair unlocked.")
        Return True
    EndIf
    
    Return False
EndFunc

Func RunToMove($g_ai2_RunPath)
    For $i = 0 To UBound($g_ai2_RunPath, 1) - 1
        MoveTo($g_ai2_RunPath[$i][0], $g_ai2_RunPath[$i][1])
        If SurvivorMode() Or GetPartyDead() Then
            LogError("Party died or survivor mode triggered during run!")
            Return False
        EndIf
    Next
    Return True
EndFunc