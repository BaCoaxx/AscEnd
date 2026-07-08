#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Coaxx

     Script Function:
        Red Iris Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $IrisPath[2][3] = [ _
    [-10784.77, -5936.46, ""], _
    [-9838.80, -4794.23, "RedIris"] _
]

Func Farm_RedIris()
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()

        IrisSetup()

        While CountSlots() > 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf

            If $NickRun Then
                Local $currentCount = GetItemCountByModelID($NickItem[0])
                If Not $TwoFiddy Then
                    If $currentCount >= 25 Then
                        LogInfo("Nicholas farm goal reached! Collected " & $currentCount & " " & $NickItem[1])
                        Return
                    EndIf
                Else
                    If $currentCount >= 250 Then
                        LogInfo("Nicholas farm goal reached! Collected " & $currentCount & " " & $NickItem[1])
                        Return
                    EndIf
                EndIf
            EndIf

            IrisFarm()
        WEnd
    WEnd
EndFunc

Func IrisSetup()
    If Map_GetMapID() = 164 Then
        LogInfo("We are in Ashford Abbey. Starting Iris farming run...")
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

Func IrisFarm()
    If Map_GetMapID() <> 164 Then
        RndTravel(164)
    EndIf

    ExitAshford()

    Sleep(1000)

    $RunTime = TimerInit()

    UseSummoningStone()
    RunToIris($IrisPath)

    If SurvivorMode() Or GetPartyDead() Then Return
    
    Other_RndSleep(250)
    LogInfo("Iris farming run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)
EndFunc

Func IrisPickup()
    
    Local $lAgentArray = Item_GetItemArray()
    Local $maxitems = $lAgentArray[0]
    
    For $i = 1 To $maxitems
        Local $aItemPtr = $lAgentArray[$i]
        Local $aItemAgentID = Item_GetItemInfoByPtr($aItemPtr, "AgentID")
        
        If $aItemAgentID = 0 Then ContinueLoop
        
        ; Is it an Iris?
        Local $lModelID = Item_GetItemInfoByPtr($aItemPtr, "ModelID")
        If $lModelID <> $GC_I_MODELID_RED_IRIS_FLOWER Then ContinueLoop
        
        If CanPickup($aItemPtr) Then
            MoveTo(Agent_GetAgentInfo($aItemAgentID, "X"), Agent_GetAgentInfo($aItemAgentID, "Y"), 25)
            Sleep(250)
            Item_PickUpItem($aItemAgentID)
            Local $lDeadlock = TimerInit()
            While GetItemAgentExists($aItemAgentID)
                Sleep(100)
                If GetPartyDead() Then ExitLoop
                If TimerDiff($lDeadlock) > 5000 Then ExitLoop
            WEnd
            
            LogInfo("Red Iris collected!")
            Return True
        EndIf
    Next
    
    LogWarn("Who needs a Red Iris anyway? Not I-ris.")
    Return False
EndFunc

Func RunToIris($g_a_RunPath)
    For $i = 0 To UBound($g_a_RunPath) - 1
        MoveTo($g_a_RunPath[$i][0], $g_a_RunPath[$i][1], 50)
        
        If SurvivorMode() Or GetPartyDead() Then
            LogError("Run failed. Restarting...")
            Return
        EndIf

        If $g_a_RunPath[$i][2] = "RedIris" Then IrisPickUp()
    Next
EndFunc