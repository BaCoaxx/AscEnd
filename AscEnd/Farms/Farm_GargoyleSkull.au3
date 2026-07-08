#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Incognito

     Script Function:
        Gargoyle Skull Farm - Pre Searing

#ce ----------------------------------------------------------------------------

Global $GargPath1[8][2] = [ _ ; Barradin to entrance
    [-7879, 1439], _
    [-7894, 2398], _
    [-7390, 2797], _
    [-5410, 3031], _
    [-4257, 3123], _
    [-4137, 4612], _
    [-4177, 6637], _
    [-4142, 8031] _
]

Global $GargPath2[2][2] = [ _ ; Inside catacombs, move closer
    [-8467, 15243], _
    [-7552, 15349] _
]

Global $GargPath3[4][2] = [ _ ; Reset coords
    [-7508, 15363], _
    [-9068, 15338], _
    [-10349, 15744], _
    [-11297, 16216] _
]

Global $aGargPhrases[6] = [ _ ; Let's liven up a very mundane slow farm
    "The gargoyle lunges. You introduce it to the floor. Permanently.", _
    "Ugly bastard. At least it died doing what it loved, being in the way.", _
    "You've killed so many of these things down here you're starting to feel bad for the stone. Almost.", _
    "Another gruesome nightmare put out of its misery. The catacombs smell worse than it did.", _
    "It took three swings and your last shred of patience, but the gargoyle won't be anyone's problem anymore.", _
    "Can you hear that Mr Gargoyle? That's the sound of inevitability..." _
]

Global $GargPhrase = 0

Func Farm_GargoyleSkull()
    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
        
        GargoyleSkullSetup()

        While CountSlotS() > 1
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

            GargoyleSkull()

            If SurvivorMode() Or GetPartyDead() Then
                LogError("Run failed. Restarting...")
                ExitLoop
            EndIf
        WEnd
    WEnd
EndFunc

Func GargoyleSkullSetup()
    If Map_GetMapID() = 163 Then
        LogInfo("We are in Barradin Estate. Starting the Gargoyle Skull farm...")
    ElseIf Map_GetMapID() <> 163 And Map_IsMapUnlocked(163) Then
        LogInfo("We are not in Barradin Estate. Teleporting to Barradin Estate...")
        RndTravel(163)
        Sleep(2000)
    ElseIf Not Map_IsMapUnlocked(163) Then
        LogWarn("Barradin Estate is not unlocked on this character, lets try to run there...")
        While Not UnlockBarradin()
            LogError("Failed to unlock Barradin Estate. Retrying...")
            Sleep(2000)
        WEnd
    EndIf

    ExitBarradin()

    Sleep(1000)

    RunTo($GargPath1)
    LogInfo("Who dares to toil, with the gargoyle? ME!")

    Sleep(500)
EndFunc

Func GargoyleSkull()
    If GetPartyDead() Or SurvivorMode() Then Return
    
    MoveTo(-3579, 9052)
    Map_InitMapIsLoaded()
    Map_Move(-2862, 9414)
    Map_WaitMapIsLoaded()
    
    Sleep(1000)
    
    $RunTime = TimerInit()

    RunTo($GargPath2)

    UseSummoningStone()
    GargoyleKillPhrase()
    AggroMoveSmartFilter(-6655, 15657, 2000, 2000)

    If GetPartyDead() Or SurvivorMode() Then Return

    LogInfo("Run complete. Restarting...")
    UpdateStats()
    Other_RndSleep(250)

    RunTo($GargPath3)

    Map_InitMapIsLoaded()
    Map_Move(-4000, 9560)
    Map_WaitMapIsLoaded()
    Sleep(2000)
EndFunc

Func GargoyleKillPhrase()
    LogInfo($aGargPhrases[$GargPhrase])
    $GargPhrase = Mod($GargPhrase + 1, UBound($aGargPhrases))
EndFunc