#include-once

#cs ----------------------------------------------------------------------------

     AutoIt Version: 3.3.18.0
     Author:         Incognito

     Script Function:
        Charr Boss Farm Looped - Pre Searing

#ce ----------------------------------------------------------------------------

; Starting Northlands Path
Global $NormalGatePathL[2][2] = [ _
    [-12036.01, -14715.39], _
    [-11087, -8753] _
]

; Pathing from (Ascalon -> gate lever)
Global $CharrGatePathL[4][2] = [ _
    [3118, 6530], _
    [36, 6952], _
    [-3215, 12159], _
    [-5413, 12808] _
]

; After charr farming, run back to the portal.
Global $RunBackPath[7][2] = [ _
    [-2703, -3874], _
    [-9018, -5112], _
    [-12717, -9127], _
    [-11811, -9887], _
    [-13022, -11138], _
    [-12626, -12638], _
   	[-11652, -16955] _
]

; If gate lever pull failed, path back up
Global $retrypathL[3][2] = [ _
    [-2951.23, 11156.55], _
	[-4714.87, 12992.08], _
    [-5508.00, 12787.00] _
]

; From gate lever -> through portal
Global $CharrPortalPathL[5][2] = [ _
    [-3925, 12379], _
    [-3760, 11583], _
    [-5409, 11872], _
    [-5526.94, 13157.09], _
    [-5588.25, 13831.14] _
]

Func Farm_CharrBossFarmLooped()

    $CharrBossFarm = True ; When true - doesn't remove sc skills and will only pick up charr carvings when collectibles are ticked in loot config.
    InitialSetup()

    While 1
        If Not $BotRunning Then
            ResetStart()
            Return
        EndIf

        ; Only do inventory when space is getting low
        If CountSlots() < 4 Then
            LogInfo("Inventory is getting full. Running inventory management...")

            InventoryPre()

            ; Only leave if inventory put us back in Ascalon
            If Map_GetMapID() <> 148 Then
			    Map_RndTravel(148)
				Map_WaitMapLoading(148, 0)
				Sleep(1250)
		    EndIf

        Else
            Switch Map_GetMapID()
                Case 148
                    If Not $hasBonus Then GetBonus()
                    LeaveAscOutpost()

                Case 146
                    LogWarn("Returned to map 146. Retrying the lever...")

                Case 147
                    LogInfo("Already in Northlands. Restarting farm...")

                Case Else
                    LogWarn("Bad map state. Mapping back to Ascalon...")
                    Map_RndTravel(148)
                    Map_WaitMapLoading(148, 0)
                    Sleep(1250)
            EndSwitch
        EndIf

        CharrBossFarmLooped()
    WEnd
EndFunc

Func LeaveAscOutpost()
    If Map_GetMapID() <> 148 Then Return

    LogInfo("Leaving Ascalon outpost for farming...")

    ExitAscalon()
    Sleep(1250)
EndFunc

Func CharrBossFarmLooped()

    ; If already in Northlands, do NOT run Ascalon gate/lever logic again.
    If Map_GetMapID() = 147 Then
        LogInfo("Already in Northlands. Starting run from portal side...")
    Else
        ; We are not in Northlands, so we must be in Ascalon/outside Ascalon gate area.
        If ComputeDistance(Agent_GetAgentInfo(-2, "X"), Agent_GetAgentInfo(-2, "Y"), -4855.79, 12787.73) > 2500 Then
            LogInfo("Running to the Charr Gate...")
            RunTo($CharrGatePathL)
            Sleep(1000)
        Else
            LogInfo("Already outside the gate. Preparing portal run...")
            RunTo($retrypathL)
            Sleep(500)
        EndIf

        Local $attempts = 0

        Do
            $attempts += 1

            LogInfo("Opening the gate lever...")
            Agent_GoSignpost(GetNearestGadgetToAgent(-2))
            Sleep(250)

            LogInfo("Moving to the Charr portal...")
            RunTo($CharrPortalPathL)
            Map_Move(-5598, 14178)
            Map_WaitMapLoading(147, 0)

            If Map_GetMapID() <> 147 Then
                LogError("Failed to arrive in the Northlands...")
                Sleep(1000)
                LogWarn("Retrying the lever...")
                RunTo($retrypathL)
            EndIf
        Until Map_GetMapID() = 147 Or $attempts >= 5

        If Map_GetMapID() <> 147 Then
            LogError("Could not reach the Northlands after 5 attempts...")
            Return False
        EndIf
    EndIf

    Sleep(1450)

    LogInfo("Arrived in the Northlands, time to burn some furr.")

    $RunTime = TimerInit()

    UseSummoningStone()
    RunToUpkeep($NormalGatePathL, $gUpkeepSkills)

    Switch $gProf
        Case 63
            If Not GetPartyDead() Then FirstGroupEmo()
            If Not GetPartyDead() Then GrawlEmo()
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

   ; Safety: if dead, reset
    If GetPartyDead() Then
        LogWarn("Dead while returning. Mapping to Ascalon...")
        Map_RndTravel(148)
        Map_WaitMapLoading(148, 0)
        Sleep(1250)
        Return False
    EndIf

    LogInfo("Run complete. Restarting from portal...")
    UpdateStats()
    Other_RndSleep(250)
    RunBackToPortal()
    Return True
EndFunc

Func RunBackToPortal()
    LogInfo("Running back to the Charr portal...")

    If GetPartyDead() Then
        LogWarn("Dead while returning. Mapping to Ascalon...")
        Map_RndTravel(148)
        Map_WaitMapLoading(148, 0)
        Sleep(1250)
        Return False
    EndIf

    If Map_GetMapID() <> 147 Then
        LogWarn("Not in Northlands. Mapping to Ascalon...")
        Map_RndTravel(148)
        Map_WaitMapLoading(148, 0)
        Sleep(1250)
        Return False
    EndIf

    RunToUpkeep($RunBackPath, $gUpkeepSkills)

    ; After running back through the portal, you should be on map 146
    Map_WaitMapLoading(146, 0)
    Sleep(750)

    If Map_GetMapID() = 146 Then
        LogWarn("Returned to Lakeside County. Retrying the lever...")
        Return True
    EndIf

    LogWarn("Did not make it to Lakeside County after portal return. Mapping to Ascalon...")
    Map_RndTravel(148)
    Map_WaitMapLoading(148, 0)
    Sleep(1250)
    Return False
EndFunc