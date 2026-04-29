#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Incognito/Coaxx

     Script Function:
        Charr Boss Farm Loop - Pre Searing

#ce ----------------------------------------------------------------------------

; Starting Northlands Path
Global $NormalGatePathLoop[3][2] = [ _
    [-12398, -13343], _
    [-12996, -11276], _
    [-11087, -8753] _
]

; Pathing from (Ascalon -> gate lever)
Global $CharrGatePathLoop[4][2] = [ _
    [3118, 6530], _
    [36, 6952], _
    [-3215, 12159], _
    [-5413, 12808] _
]

; If gate lever pull failed, path back up
Global $retrypathLoop[5][2] = [ _
    [-5321, 11802], _
    [-3690, 11398], _
    [-3296, 11764], _
    [-3663, 12426], _
    [-5408, 12806] _
]

; From gate lever -> through portal
Global $CharrPortalPathLoop[5][2] = [ _
    [-3925, 12379], _
    [-3760, 11583], _
    [-5409, 11872], _
    [-5497, 13166], _
    [-5572.39, 14130.93] _
]

; After charr farming, run back to the portal.
Global $RunBackPath[6][2] = [ _
    [-2703, -3874], _
    [-9018, -5112], _
    [-12717, -9127], _
    [-11811, -9887], _
    [-13022, -11138], _
    [-12626, -12638] _
]

Func Farm_CharrBossFarmLoop()
    
    $CharrBossFarm = True ; Set this to 'True' if you only want to farm charr bosses, if 'False' will pickup all collectibles.
    InitialSetup()

    While 1
        If CountSlots() < 4 Then InventoryPre()
        If Not $hasBonus Then GetBonus()
 
        While CountSlots() > 1
            If Not $BotRunning Then
                ResetStart()
                Return
            EndIf
            
            If Map_GetMapID() <> 148 Then
                Map_RndTravel(148)
            EndIf

            RunToGate()

            While True
                If Not CharrCombatLoop() Then ExitLoop
            WEnd
        WEnd
    WEnd
EndFunc

Func RunToGate() ; Exit and run to the charr gate
    ExitAscalon()
    LogInfo("Running to the Charr Gate...")
    RunTo($CharrGatePathLoop)
    Sleep(1000)
EndFunc

Func OpenGate() ; Pull lever until we get to the Northlands
    
    Do
        LogInfo("Opening the gate lever...")
        Agent_GoSignpost(GetNearestGadgetToAgent(-2))
        Sleep(250)

        LogInfo("Moving to the Charr portal...")
        RunTo($CharrPortalPathLoop)
        Map_InitMapIsLoaded()
        Map_Move(-5598, 14178)
        Map_WaitMapIsLoaded()

        If Map_GetMapID() <> 147 Then
            LogError("Failed to arrive in the Northlands...")
            Sleep(1000)
            LogWarn("Retrying the lever...")
            RunTo($retrypathLoop)
        EndIf
    Until Map_GetMapID() = 147

EndFunc

Func CharrCombatLoop() ; Combat loop for charr bosses
    OpenGate()
    LogInfo("Arrived in the Northlands, time to burn some furr.")
    
    $RunTime = TimerInit()

    UseSummoningStone()
    RunToUpkeep($NormalGatePathLoop, $gUpkeepSkills)

    Switch $gProf
        Case 63
            If Not GetPartyDead() Then FirstGroupEmo()
            If Not GetPartyDead() Then GrawlEmo() ; Fight Grawl if they are there?
            If Not GetPartyDead() Then SecondGroupEmo()
            If Not GetPartyDead() Then LeftCornerEmo()
            If Not GetPartyDead() Then BossesEmo()
        Case 42
            If Not GetPartyDead() Then FirstGroupNecro()
            If Not GetPartyDead() Then GrawlNecro()
            If Not GetPartyDead() Then SecondGroupNecro()
            If Not GetPartyDead() Then LeftCornerNecro()
            If Not GetPartyDead() Then BossesNecro()
    EndSwitch

    If GetPartyDead() Then
        LogWarn("You died because you couldn't fight your way out of a paper bag...")
        LogInfo("Returning to Ascalon...")
        UpdateStats()
        Other_RndSleep(250)
        Resign()
        Sleep(5000)
        Map_ReturnToOutpost()
        Return False
    EndIf

    LogInfo("Run complete. Running back to portal...")
    UpdateStats()

    Other_RndSleep(250)

    If Not RunBackToPortal() Then
        LogWarn("Failed to make it to the portal...")
        LogInfo("Returning to Ascalon...")
        Return False
    EndIf

    Return True
EndFunc

Func RunBackToPortal()
    RunToUpkeep($RunBackPath, $gUpkeepSkills)

    If GetPartyDead() Then
        LogWarn("Died on our way to the portal...")
        Return False
    EndIf

    Map_InitMapIsLoaded()
    Map_Move(-11652, -16955)
    Map_WaitMapIsLoaded()
    Sleep(750)

    If Map_GetMapID() = 146 Then
        LogWarn("Returned to Lakeside County. Retrying the lever...")
        RunTo($retrypathLoop)
        Return True
    EndIf

    Return False
EndFunc