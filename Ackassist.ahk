


#NoEnv
#SingleInstance, Force
#Persistent
#InstallKeybdHook
#UseHook
#KeyHistory, 0
#HotKeyInterval 1
#MaxHotkeysPerInterval 127
SetKeyDelay, -1, 1
SetControlDelay, -1
SetMouseDelay, -1
SetWinDelay, -1
SendMode, InputThenPlay
SetBatchLines, -1
ListLines, Off
CoordMode, Pixel, Screen, RGB
CoordMode, Mouse, Screen

PID := DllCall("GetCurrentProcessId")
Process, Priority, %PID%, High

class JSON
{
class Load extends JSON.Functor
{
Call(self, ByRef text, reviver:="")
{
this.rev := IsObject(reviver) ? reviver : false
this.keys := this.rev ? {} : false
static quot := Chr(34), bashq := "\" . quot
, json_value := quot . "{[01234567890-tfn"
, json_value_or_array_closing := quot . "{[]01234567890-tfn"
, object_key_or_object_closing := quot . "}"
key := ""
is_key := false
root := {}
stack := [root]
next := json_value
pos := 0
while ((ch := SubStr(text, ++pos, 1)) != "") {
if InStr(" `t`r`n", ch)
continue
if !InStr(next, ch, 1)
this.ParseError(next, text, pos)
holder := stack[1]
is_array := holder.IsArray
if InStr(",:", ch) {
next := (is_key := !is_array && ch == ",") ? quot : json_value
} else if InStr("}]", ch) {
ObjRemoveAt(stack, 1)
next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"
} else {
if InStr("{[", ch) {
static json_array := Func("Array").IsBuiltIn || ![].IsArray ? {IsArray: true} : 0
(ch == "{")
? ( is_key := true
, value := {}
, next := object_key_or_object_closing )
: ( value := json_array ? new json_array : []
, next := json_value_or_array_closing )
ObjInsertAt(stack, 1, value)
if (this.keys)
this.keys[value] := []
} else {
if (ch == quot) {
i := pos
while (i := InStr(text, quot,, i+1)) {
value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")
static tail := A_AhkVersion<"2" ? 0 : -1
if (SubStr(value, tail) != "\")
break
}
if (!i)
this.ParseError("'", text, pos)
value := StrReplace(value,  "\/",  "/")
, value := StrReplace(value, bashq, quot)
, value := StrReplace(value,  "\b", "`b")
, value := StrReplace(value,  "\f", "`f")
, value := StrReplace(value,  "\n", "`n")
, value := StrReplace(value,  "\r", "`r")
, value := StrReplace(value,  "\t", "`t")
pos := i
i := 0
while (i := InStr(value, "\",, i+1)) {
if !(SubStr(value, i+1, 1) == "u")
this.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))
uffff := Abs("0x" . SubStr(value, i+2, 4))
if (A_IsUnicode || uffff < 0x100)
value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
}
if (is_key) {
key := value, next := ":"
continue
}
} else {
value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)
static number := "number", integer :="integer"
if value is %number%
{
if value is %integer%
value += 0
}
else if (value == "true" || value == "false")
value := %value% + 0
else if (value == "null")
value := ""
else
this.ParseError(next, text, pos, i)
pos += i-1
}
next := holder==root ? "" : is_array ? ",]" : ",}"
}
is_array? key := ObjPush(holder, value) : holder[key] := value
if (this.keys && this.keys.HasKey(holder))
this.keys[holder].Push(key)
}
}
return this.rev ? this.Walk(root, "") : root[""]
}
ParseError(expect, ByRef text, pos, len:=1)
{
static quot := Chr(34), qurly := quot . "}"
line := StrSplit(SubStr(text, 1, pos), "`n", "`r").Length()
col := pos - InStr(text, "`n",, -(StrLen(text)-pos+1))
msg := Format("{1}`n`nLine:`t{2}`nCol:`t{3}`nChar:`t{4}"
,     (expect == "")     ? "Extra data"
: (expect == "'")    ? "Unterminated string starting at"
: (expect == "\")    ? "Invalid \escape"
: (expect == ":")    ? "Expecting ':' delimiter"
: (expect == quot)   ? "Expecting object key enclosed in double quotes"
: (expect == qurly)  ? "Expecting object key enclosed in double quotes or object closing '}'"
: (expect == ",}")   ? "Expecting ',' delimiter or object closing '}'"
: (expect == ",]")   ? "Expecting ',' delimiter or array closing ']'"
: InStr(expect, "]") ? "Expecting JSON value or array closing ']'"
:                      "Expecting JSON value(string, number, true, false, null, object or array)"
, line, col, pos)
static offset := A_AhkVersion<"2" ? -3 : -4
throw Exception(msg, offset, SubStr(text, pos, len))
}
Walk(holder, key)
{
value := holder[key]
if IsObject(value) {
for i, k in this.keys[value] {
v := this.Walk(value, k)
if (v != JSON.Undefined)
value[k] := v
else
ObjDelete(value, k)
}
}
return this.rev.Call(holder, key, value)
}
}
class Dump extends JSON.Functor
{
Call(self, value, replacer:="", space:="")
{
this.rep := IsObject(replacer) ? replacer : ""
this.gap := ""
if (space) {
static integer := "integer"
if space is %integer%
Loop, % ((n := Abs(space))>10 ? 10 : n)
this.gap .= " "
else
this.gap := SubStr(space, 1, 10)
this.indent := "`n"
}
return this.Str({"": value}, "")
}
Str(holder, key)
{
value := holder[key]
if (this.rep)
value := this.rep.Call(holder, key, ObjHasKey(holder, key) ? value : JSON.Undefined)
if IsObject(value) {
static type := A_AhkVersion<"2" ? "" : Func("Type")
if (type ? type.Call(value) == "Object" : ObjGetCapacity(value) != "") {
if (this.gap) {
stepback := this.indent
this.indent .= this.gap
}
is_array := value.IsArray
if (!is_array) {
for i in value
is_array := i == A_Index
until !is_array
}
str := ""
if (is_array) {
Loop, % value.Length() {
if (this.gap)
str .= this.indent
v := this.Str(value, A_Index)
str .= (v != "") ? v . "," : "null,"
}
} else {
colon := this.gap ? ": " : ":"
for k in value {
v := this.Str(value, k)
if (v != "") {
if (this.gap)
str .= this.indent
str .= this.Quote(k) . colon . v . ","
}
}
}
if (str != "") {
str := RTrim(str, ",")
if (this.gap)
str .= stepback
}
if (this.gap)
this.indent := stepback
return is_array ? "[" . str . "]" : "{" . str . "}"
}
} else
return ObjGetCapacity([value], 1)=="" ? value : this.Quote(value)
}
Quote(string)
{
static quot := Chr(34), bashq := "\" . quot
if (string != "") {
string := StrReplace(string,  "\",  "\\")
, string := StrReplace(string, quot, bashq)
, string := StrReplace(string, "`b",  "\b")
, string := StrReplace(string, "`f",  "\f")
, string := StrReplace(string, "`n",  "\n")
, string := StrReplace(string, "`r",  "\r")
, string := StrReplace(string, "`t",  "\t")
static rx_escapable := A_AhkVersion<"2" ? "O)[^\x20-\x7e]" : "[^\x20-\x7e]"
while RegExMatch(string, rx_escapable, m)
string := StrReplace(string, m.Value, Format("\u{1:04x}", Ord(m.Value)))
}
return quot . string . quot
}
}
Undefined[]
{
get {
static empty := {}, vt_empty := ComObject(0, &empty, 1)
return vt_empty
}
}
class Functor
{
__Call(method, ByRef arg, args*)
{
if IsObject(method)
return (new this).Call(method, arg, args*)
else if (method == "")
return (new this).Call(arg, args*)
}
}
}
init:
; --- Updated Script with Triggerbot Checkbox ---
; === BASIC SETUP ===
#NoEnv
#SingleInstance Force
#Persistent
SetBatchLines, -1
ListLines Off
CoordMode, Pixel, Screen, RGB
CoordMode, Mouse, Screen
SetKeyDelay, -1, 1
SetControlDelay, -1
SetMouseDelay, -1
SetWinDelay, -1
SendMode InputThenPlay
#NoTrayIcon
DetectHiddenWindows On


global espPID
global ESPDotEnabled := true
global CurrentStyle := "Dark"
global FPSCounter := 240
global LastFPSTime := A_TickCount
global LastHealthCheckTime := A_TickCount
global ESPDotColor := "4B0082"
global DotSize := 40
global OffsetX := 0
global OffsetY := 49
global FOV_X := 200
global FOV_Y := 200
global ESPEnabled := true
global CrosshairDeadZone := 30
global RobloxTitle := "Roblox"
; Global Variables
toggle_key := "-"
exit_key := "End"
activate_key := "XButton1"
fov_range := 2.2
color_sensitivity := 25
target_colors := ["0x000000", "0xFFFFFF"]
delay_between_clicks := 55
If !WinExist("Roblox") {
    MsgBox, open roblox first lmao.
    ExitApp
}

CreateWatermark() {
    Global
    Gui, 99:Destroy
    Gui, 99:+AlwaysOnTop -Caption +ToolWindow +E0x80000 +LastFound +Owner
    Gui, 99:Color, 000000  ; Black background (used for transparency)
    Gui, 99:Font, s10 cWhite Bold, Consolas
    Gui, 99:Add, Text, BackgroundTrans, ack ware  (ahk)`nVersion: v1.55`nPAID | HWID Locked`nMenu Key: Insert
    hwnd := WinExist()

    ; Make black color transparent
    WinSet, TransColor, 000000, ahk_id %hwnd%

    ; Position watermark near bottom-left
    SysGet, screenHeight, 1
    posY := screenHeight - 140
    Gui, 99:Show, x10 y%posY% NoActivate
}



CreateWatermark()




Sleep, 8000
if WinExist("ahk_exe RobloxPlayerBeta.exe") {
    Run, %ComSpec% /c title AckWare Loader ^|^| AckWare v1.0 && color 0F && echo [ + ] Roblox detected. Initializing AckWare... && timeout /t 2 >nul
    RunWait, %ComSpec% /c "%A_ScriptDir%\spinner.bat"
} else {
    Run, %ComSpec% /c title AckWare Loader ^|^| AckWare v1.0 && color 0C && echo [ ! ] Roblox NOT found! Launch Roblox first to use AckWare. && timeout /t 3 >nul
    ExitApp
}



SetTimer, UpdateLoader, %animationSpeed%
return

UpdateLoader:
    elapsed := A_TickCount - loadStartTime
    if (elapsed >= fakeLoadDuration) {
        SetTimer, UpdateLoader, Off
        Gui, Destroy
        Gosub, RunMainScript
        return
    }

    ; Update dots and loading text
    dots := (dots + 1) > 3 ? 0 : (dots + 1)
    GuiControl,, LoadingLabel, % loadingText . SubStr("...", 1, dots)

    ; Update progress
    percent := Floor((elapsed / fakeLoadDuration) * 100)
    GuiControl,, ProgressBar, %percent%

    ; Fake Logs
    if (elapsed >= 1000 && elapsed < 2000) {
       
    } else if (elapsed >= 2000 && elapsed < 2500) {
        
    } else if (elapsed >= 3000 && elapsed < 3500) {
        
    } else if (elapsed >= 4000 && elapsed < 4500) {
       
    } else if (elapsed >= 5000) {
        logText := "Injection complete. Launching... "
        GuiControl,, StatusLabel, "Status: Undetected "
    }

    GuiControl,, LogText, %logText%
return




; === MAIN GUI FUNCTION ===
RunMainScript:
    configuration := A_LineFile . "\..\config.json"
    if (FileExist(configuration)) {
        File := FileOpen(configuration, "r")
        configData := File.Read()
        File.Close()
        config := JSON.Load(configData)
    } else {
        MsgBox, config file not found
        ExitApp
    }

GetHWID()
{
    DriveGet, Serial, Serial, C:
    return Serial
}

allowedHWID := "" ; <- paste your real HWID here

currentHWID := GetHWID()


if (currentHWID = allowedHWID) ; simple string comparison, 100% works
{
    MsgBox, 64, HWID Correct, Welcome!
}
else
{
    MsgBox, 16, Access Denied, Your HWID is not authorized!
    ExitApp
}

ShowGui:
Gui, +Hwndgui_id -Caption +AlwaysOnTop
WinSet, Transparent, 205, % "ahk_id" gui_id
Gui, Font, cWhite s10 bold, Consolas
Gui, Font, s10, Minecraftia
Gui, Add, Picture, x15 y400 w260 h225 Icon1, ackassist.png
Gui, Add, Text, x20 y800 w200 h220, @ispoketothedevil on discord for help
Gui, Add, Tab2, x10 y10 w250 h355 vMainTab, Aim Assist|Triggerbot|Settings





; === AIM ASSIST TAB ===
Gui, Tab, Aim Assist 
Gui, Color,, 0xA9A9A9

Gui, Add, Text, x20 y35 w120 h20, FOV X:
Gui, Add, Edit, x150 y35 w100 h20 vFOV_X, % config.FOV_X

Gui, Add, Text, x20 y60 w120 h20, FOV Y:
Gui, Add, Edit, x150 y60 w100 h20 vFOV_Y, % config.FOV_Y

Gui, Add, Text, x20 y90 w120 h20, HeadOffset:
Gui, Add, Edit, x150 y90 w100 h20 vHeadOffset, % config.HeadOffset

Gui, Add, Text, x20 y120 w120 h20, HumanoidOffset:
Gui, Add, Edit, x150 y120 w100 h20 vHumanoidOffset, % config.HumanoidOffset

Gui, Add, Text, x20 y150 w120 h20, UpperTorsoOffset:
Gui, Add, Edit, x150 y150 w100 h20 vUpperTorsoOffset, % config.UpperTorsoOffset

Gui, Add, Text, x20 y180 w120 h20, PredictionAmount:
Gui, Add, Edit, x150 y180 w100 h20 vPredictionAmount, % config.PredictionAmount

Gui, Add, Text, x20 y210 w120 h20, Bone:
Gui, Add, DropDownList, x150 y210 w100 vBone, Head|HumanoidRootPart|UpperTorso
GuiControl,, Bone, % config.Bone

Gui, Add, Text, x20 y240 w120 h20, Key:
Gui, Add, Edit, x150 y240 w100 h20 vKey, % config.Key

Gui, Add, Text, x20 y270 w120 h20, SmoothnessFactor:
Gui, Add, Edit, x150 y270 w100 h20 vSmoothnessFactor, % config.SmoothnessFactor


Gui, Add, Button, x20 y300 w110 h30 gSaveConfig, Save Settings
Gui, Add, Button, x140 y300 w110 h30 gStartScript, Inject


; === TRIGGERBOT TAB ===
Gui, Tab, Triggerbot
Gui, Add, Text, x20 y40 w200 h60, The Activation Key is "-"
Gui, Add, Checkbox, x30 y80 vTriggerbotCheckbox gLaunchTriggerbot, Enable Triggerbot

; === SETTINGS TAB ===
Gui, Tab, Settings

Gui, Add, Text, x20 y50 w120 h20, Theme Style:
Gui, Add, DropDownList, x150 y50 w100 vStylePreset gApplyStyle, Default|Dark|Matrix|Space|SteamPunk|Fantasy|Cyberpunk|Retro|Neon|Minimalist|Toxic|Military|Hacker
GuiControl,, StylePreset, % CurrentStyle


Gui, Add, Text, x20 y90 w120 h20, Aim Style:
Gui, Add, DropDownList, x150 y90 w100 vAimStyle, Smooth|Blatant
GuiControl,, AimStyle, % config.AimStyle

Gui, Add, Text, x20 y130 w120 h50, Snap Distance:
Gui, Add, Edit, x150 y140 w100 h20 vSnapDistance, % config.SnapDistance

Gui, Add, Text, x20 y170 w120 h40, Snap Strength:
Gui, Add, Edit, x150 y180 w100 h20 vSnapStrength, % config.SnapStrength

Gui, Add, Text, x20 y210 w120 h40, Pixel Step:
Gui, Add, Edit, x150 y220 w100 h20 vPixelStep, % config.PixelStep

Gui, Add, Button, x15 y290 w120 h30 gOpenESP, Open ESP.ahk
Gui, Add, Button, x140 y290 w120 h30 gImportConfig, Import Config
Gui, Add, Text, x20 y325 w120 h40, F1 to toggle ESP Dot

Gui, Add, Checkbox, x20 y370 w300 h40 vAutoPredictionEnabled gToggleAutoPrediction, Enable Auto Prediction

Gui, Add, Text, x20 y210 w120 h20, Prediction Factor:
Gui, Add, Slider, x20 y260 w120 h30 vPredictionFactor Range:0-5 w200, 2

; Background blur overlay
Gui, +AlwaysOnTop -Caption +ToolWindow +E0x80000 +HwndOverlayGui
Gui, Color, 0x1a1a1a
Gui, Show, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight%, BlurOverlay

return


; Initialize transparency parameters for fade-in effect
currentTransparency := 2     ; Start at fully transparent (0)
finalTransparency := 200     ; Fade in to this transparency value (0 to 255 range)
fadeSpeed := 8              ; Speed of fade-in effect (higher value = slower fade)
SetTimer, FadeInAnimation, 15 ; Run every 30 milliseconds
return

FadeInAnimation:
    ; Increase transparency value by fadeSpeed
    currentTransparency := currentTransparency + fadeSpeed
    
    ; Stop the fade when reaching the final transparency
    if (currentTransparency >= finalTransparency) {
        currentTransparency := finalTransparency
        SetTimer, FadeInAnimation, Off  ; Stop the timer once fade-in is complete
    }
    
    ; Apply the current transparency value to the overlay window
    WinSet, Transparent, %currentTransparency%, ahk_id %OverlayGui%
return



; --- Checkbox and Slider Action Handlers ---
gToggleAutoPrediction:
    ; Handle checkbox toggle (if needed)
    MsgBox, Auto Prediction Enabled: %AutoPredictionEnabled%
return


OpenESP: ; Open ESP.ahk file 
    Run, %A_ScriptDir%\esp.ahk
return


UpdateFPS:
    ; Randomly generate FPS between 200 and 249
    Random, randomFPS, 200, 249
    
    ; Update FPS label on GUI
    GuiControl,, FPSLabel, % "FPS: " . randomFPS
return







ApplyStyle:
Gui, Submit, NoHide
CurrentStyle := StylePreset
switch CurrentStyle {
    case "Default":
        Gui, Color, 0xA9A9A9
        Gui, Font, s10, Consolas
    case "Dark":
        Gui, Color, 0x202020
        Gui, Font, s10, Bold
    case "Matrix":
        Gui, Color, 0x003300
        Gui, Font, s12, Terminal
    case "Cyberpunk":
        Gui, Color, 0x111111
        Gui, Font, s10, Orbitron
        GuiControl,, FPSLabel, FPS: 240
    case "Retro":
        Gui, Color, 0xFFF4F2
        Gui, Font, s10, Press Start 2P
    case "Space":
        Gui, Color, 0x0F0F3C
        Gui, Font, s10, Aharoni
    case "SteamPunk":
        Gui, Color, 0x4B3F32
        Gui, Font, s12, Arial
    case "Fantasy":
        Gui, Color, 0x804000
        Gui, Font, s10, Bold

    ; 🔹 New Styles:
    case "Minimalist":
        Gui, Color, 0xFFFFFF
        Gui, Font, s10, Segoe UI

    case "Toxic":
        Gui, Color, 0x003300
        Gui, Font, s10, Courier New
        GuiControl,, FPSLabel, ⚠ Toxic Mode ⚠


    case "Military":
        Gui, Color, 0x556B2F
        Gui, Font, s10, Impact

    case "Hacker":
        Gui, Color, 0x000000
        Gui, Font, s10, Lucida Console
        GuiControl,, FPSLabel, >_ Terminal Online
}
return


ShowNotification(message) {
    Gui, +AlwaysOnTop +ToolWindow -Caption
    Gui, Color, 0xFF0000 ; Red color
    Gui, Font, cWhite s12 bold, Arial
    Gui, Add, Text, x100 y100 w300 h30 vNotifyText, %message%
    Gui, Show, w500 h200
    Sleep, 3000
    Gui, Destroy
}

; Toggle the aim assist functionality
gToggleAimAssist:
    Gui, Submit, NoHide  ; Save the GUI settings
    if (AimAssistToggle) {
        MsgBox, Aim Assist is now ENABLED.
        ; Code to enable aim assist (e.g., activating a loop or setting flags)
        ; You can add any relevant functionality here to activate your aim assist
    } else {
        MsgBox, Aim Assist is now DISABLED.
        ; Code to disable aim assist (e.g., stopping a loop or clearing flags)
        ; Deactivate or stop the processes that were running for aim assist
    }
return



; -------------------- Player Detection and Auto-Targeting --------------------
DetectPlayerAndAutoTarget() {
    ; Example: Detect enemy player color or position and automatically target them
    PixelSearch, AimPixelX, AimPixelY, 0, 0, A_ScreenWidth, A_ScreenHeight, 0xFF0000, 25, Fast RGB
    if (!ErrorLevel) {
        ShowNotification("Target Found!")
        ; Implement auto-targeting behavior here
        ; Triggerbot functionality added here
        TriggerBot(AimPixelX, AimPixelY)  ; Trigger the bot to shoot when target is found
    }
}

TriggerBot(x, y) {
    ; Simulate a key press (usually the fire key) when a target is found
    ; This assumes your fire key is set to "LMB" (left mouse button) or a specific key.
    ; You can replace "LMB" with any specific key configured for shooting (e.g., spacebar or mouse button)
    
    ; Move the mouse to the target location to simulate aim
    MouseMove, x, y, 0  ; Move the mouse directly to the target
    Sleep, 50  ; Small delay to make the movement look more natural
    Click, Left  ; Left click to fire the weapon (triggerbot action)
}

; -------------------- Smooth/Blatant Aim Assist --------------------
global aimAssistRunning := false
global prevTargetX := 0
global prevTargetY := 0
global prevTime := 0
global velocityBufferX := []
global velocityBufferY := []
global stickyLockActive := false
global initialLockedPixelCount := 1 ; Store initial pixel count
global initialLockedCoordinates := [] ; Store initial locked coordinates
global lastAvgVelX := 0
global lastAvgVelY := 0
global autoPredictionEnabled := false
global predictionFactor := 0.8  ; Default prediction factor if auto prediction is disabled
global aimAssistRunning := false
global toggleActive := false

_RunAimAssist:
    Gui, Submit, NoHide
    mode := config.AimAssistMode ? config.AimAssistMode : "Hold"
    currentKeyState := GetKeyState(config.Key, "P")

    if (mode = "Hold") {
        aimAssistRunning := currentKeyState
    }
    else if (mode = "Toggle") {
        ; If key is pressed now and wasn't pressed last check, toggle
        if (currentKeyState && !lastKeyState) {
            aimAssistRunning := !aimAssistRunning
            ShowNotification(aimAssistRunning ? "Aim Assist ENABLED (Toggle Mode)" : "Aim Assist DISABLED (Toggle Mode)")
        }
    }

    lastKeyState := currentKeyState  ; Update last state for toggle tracking


centerX := A_ScreenWidth // 2
centerY := A_ScreenHeight // 2
radius := config.FOVAmount
targetColor := config.TargetColor
pixelStep := config.pixelStep
smoothFactor := config.smoothFactor
snapStrength := config.SnapStrength ?? 4.0
minSnapDistance := config.minSnapDistance

; Auto prediction feature logic
if (autoPredictionEnabled) {
    predictionFactor := config.PredictionAmount ; Use value from GUI settings
}

closestDist := 20
bestX := ""
bestY := ""
totalWhitePixels := 1
currentCoordinates := []

; Loop to scan pixels in the FOV
Loop % (2 * radius // pixelStep) {
    xOffset := (A_Index * pixelStep) - radius
    Loop % (2 * radius // pixelStep) {
        yOffset := (A_Index * pixelStep) - radius
        if (xOffset**2 + yOffset**7.5 > radius**2)
            continue

        x := centerX + xOffset
        y := centerY + yOffset
        if (x < 0 || y < 0 || x > A_ScreenWidth || y > A_ScreenHeight)
            continue

        PixelGetColor, pixelColor, x, y, RGB
        if (pixelColor = targetColor) {
            currentCoordinates.Push([x, y])
            totalWhitePixels++
            dist := Sqrt((x - centerX)**2 + (y - centerY)**2)
            if (dist < closestDist)
                closestDist := dist, bestX := x, bestY := y
        }
    }
}

; In your main loop or aim assist logic
if (AimAssistMode = "Toggle") {
    ; Logic for toggle mode, i.e., activate/deactivate aim assist on key press
    if (GetKeyState(config.Key, "P")) {
        ; Activate aim assist if key is pressed
        MsgBox, Aim Assist Activated (Toggle Mode)
    }
} else if (AimAssistMode = "Hold") {
    ; Logic for hold mode, i.e., aim assist is active as long as the key is held down
    if (GetKeyState(config.Key, "P")) {
        ; Keep aim assist active while key is held
        MsgBox, Aim Assist Active (Hold Mode)
    } else {
        ; Deactivate aim assist when key is released
        MsgBox, Aim Assist Deactivated (Hold Mode)
    }
}

; Sticky lock mechanism to ensure the aimbot stays on the same target
if (!stickyLockActive && totalWhitePixels > 0) {
    initialLockedCoordinates := currentCoordinates
    initialLockedPixelCount := totalWhitePixels
    stickyLockX := bestX
    stickyLockY := bestY
    stickyLockActive := true
}

if (stickyLockActive) {
    matchingCount := 0
    for _, current in currentCoordinates {
        for _, locked in initialLockedCoordinates {
            if (Abs(current[1] - locked[1]) < 5 && Abs(current[2] - locked[2]) < 5) {
                matchingCount++
                break
            }
        }
    }

    matchPercentage := matchingCount / initialLockedPixelCount * 100

    if (matchPercentage < 60) {
        stickyLockActive := false
        bestX := "", bestY := ""
    } else {
        bestX := stickyLockX
        bestY := stickyLockY
    }
}

; Apply smoothing to the movement
if (stickyLockActive) {
    currentTime := A_TickCount
    deltaTime := (currentTime - prevTime) / 1000.0
    if (deltaTime = 0)
        deltaTime := 0.021

    velX := (bestX - prevTargetX) / deltaTime
    velY := (bestY - prevTargetY) / deltaTime

    PushVelocity(velocityBufferX, velX)
    PushVelocity(velocityBufferY, velY)

    avgVelX := AverageVelocity(velocityBufferX)
    avgVelY := AverageVelocity(velocityBufferY)

    ; Smooth movement by applying average velocity and prediction factor
    MoveX := (bestX - centerX + avgVelX * predictionFactor) / smoothFactor
    MoveY := (bestY - centerY + avgVelY * predictionFactor) / smoothFactor

    ; Apply mouse movement
    DllCall("mouse_event", "UInt", 0x0001, "Int", MoveX, "Int", MoveY, "UInt", 0, "UInt", 0)

    prevTargetX := bestX
    prevTargetY := bestY
    prevTime := currentTime
}

aimAssistRunning := false
return

ChangeAimMode:
    Gui, Submit, NoHide  ; Save the selected option from the drop-down
    if (AimMode = "Toggle") {
        ; Code to set aim assist to toggle mode (e.g., use key press to toggle on/off)
        AimAssistMode := "Toggle"
        MsgBox, Aim Assist is now in Toggle Mode.
    } else if (AimMode = "Hold") {
        ; Code to set aim assist to hold mode (e.g., hold key to keep aim assist active)
        AimAssistMode := "Hold"
        MsgBox, Aim Assist is now in Hold Mode.
    }
return

; --- Auto Prediction Toggle ---
ToggleAutoPrediction:
    Gui, Submit
    autoPredictionEnabled := AutoPredictionEnabled
    return

; --- Helper Functions ---
PushVelocity(ByRef buffer, value) {
    maxLength := 5
    buffer.Push(value)
    if (buffer.Length() > maxLength)
        buffer.RemoveAt(1)
}

AverageVelocity(buffer) {
    sum := 0
    for _, val in buffer
        sum += val
    return (buffer.Length() > 0) ? (sum / buffer.Length()) : 0
}

Clamp(val, min, max) {
    if (val < min)
        return min
    if (val > max)
        return max
    return val
}


StartScript:
Gui, Submit, NoHide
FOVAmount := config.FOVAmount  ; If you still use this somewhere else, but replaced by FOV_X and FOV_Y below
HeadOffset := config.HeadOffset
HumanoidOffset := config.HumanoidOffset
UpperTorsoOffset := config.UpperTorsoOffset
PredictionAmount := config.PredictionAmount
Bone := config.Bone
Key := config.Key
SmoothnessFactor := config.SmoothnessFactor * 0.6
FireDelay := config.FireDelay
Sensitivity := config.Sensitivity
FOV_X := config.FOV_X
FOV_Y := config.FOV_Y   

MsgBox Cheat Injected! Open Roblox

HoldMode := false
EMCol := 0xFDFDFC
ColVn := 2
ZeroX := 955
ZeroY := 500
CFovX := 40
CFovY := 95
ScanL := ZeroX - CFovX
ScanT := ZeroY - CFovY
ScanR := ZeroX + CFovX
ScanB := ZeroY + CFovY

global targetLocked := false
global lockedX := 0
global lockedY := 0
global prevTargetX := 0
global prevTargetY := 0
global prevTime := A_TickCount

; --- Updated Aimbot Script ---
Loop {
    if ((!HoldMode && GetKeyState(Key, "P")) or GetKeyState("nothing", "P")) {
        ; Only attempt to lock on a new target if there is no existing target locked
        if (!targetLocked) {
            ; Updated to check within FOV_X and FOV_Y bounds instead of FOVAmount
            PixelSearch, AimPixelX, AimPixelY, ZeroX - FOV_X, ZeroY - FOV_Y, ZeroX + FOV_X, ZeroY + FOV_Y, EMCol, ColVn, Fast RGB
            if (!ErrorLevel) {
                lockedX := AimPixelX
                lockedY := AimPixelY
                targetLocked := true
                prevTargetX := lockedX
                prevTargetY := lockedY
                prevTime := A_TickCount
            }
        } else {
            ; Once a target is locked, continue tracking that same target
            PixelGetColor, pixelColor, lockedX, lockedY, RGB
            if (pixelColor != EMCol) {
                ; If the target's color changes (i.e., it is no longer in the FOV), unlock the target
                targetLocked := false
                continue
            }
        }

        if (targetLocked) {
            currentTime := A_TickCount
            deltaTime := (currentTime - prevTime) / 1000.0
            if (deltaTime = 0)
                deltaTime := 0.020

            ; Calculate base aim
            rawAimX := lockedX - ZeroX
            rawAimY := lockedY - ZeroY

            ; Calculate velocity (how fast the target moved)
            velX := (lockedX - prevTargetX) / deltaTime
            velY := (lockedY - prevTargetY) / deltaTime

            ; Calculate velocity magnitude (how much movement)
            velMagnitude := Sqrt(velX**2 + velY**2)

            ; Only apply prediction if moving enough
            predX := 0
            predY := 0
            if (velMagnitude > 2) {  ; threshold: 2 pixels/sec
                predX := velX * PredictionAmount
                predY := velY * PredictionAmount
            }

            ; Apply prediction to aim
            AimX := rawAimX + predX
            AimY := rawAimY + predY

            ; Apply bone offset
            DirY := 0
            if (Bone = "Head")
                DirY := HeadOffset
            else if (Bone = "HumanoidRootPart")
                DirY := HumanoidOffset
            else if (Bone = "UpperTorso")
                DirY := UpperTorsoOffset

            AimY += DirY

            ; Adaptive smoothness based on velocity
            adaptiveSmoothnessFactor := SmoothnessFactor * (1 + velMagnitude * 0.01)  ; Adjust smoothness factor dynamically based on velocity

            ; Smooth movement
            MoveX := Floor(AimX / adaptiveSmoothnessFactor)
            MoveY := Floor(AimY / adaptiveSmoothnessFactor)

            ; Avoid micro-movements
            if (Abs(MoveX) < 1)
                MoveX := (MoveX > 0) ? 1 : -1
            if (Abs(MoveY) < 1)
                MoveY := (MoveY > 0) ? 1 : -1

            ; Apply mouse movement
            DllCall("mouse_event", "UInt", 0x0001, "Int", MoveX, "Int", MoveY, "UInt", 0, "UInt", 0)

            ; Save for next frame
            prevTargetX := lockedX
            prevTargetY := lockedY
            prevTime := currentTime
        }

    } else {
        ; Unlock the target when the key is released (or if "nothing" is pressed)
        targetLocked := false
    
}




    ; Triggerbot stays the same
    if (TriggerbotCheckbox && GetKeyState(TriggerbotKey, "P")) {
        Sleep, FireDelay
        PixelSearch, AimPixelX, AimPixelY, 0, 0, A_ScreenWidth, A_ScreenHeight, EMCol, Sensitivity, Fast RGB
        if (!ErrorLevel)
            Click
    }
}

ToolTip, Target found at %targetX%, %targetY%
SetTimer, RemoveTip, -500
RemoveTip:
ToolTip
return


SaveConfig:
    ; Open file selection dialog
    FileSelectFile, selectedFile, S16, , Save config as..., JSON Files (*.json)
    if (selectedFile = "")
        return  ; User cancelled

    ; Ensure file has .json extension
    if (!InStr(selectedFile, ".json"))
        selectedFile .= ".json"

    ; Update GUI controls and get values
    Gui, Submit, NoHide  ; Ensure all controls' values are updated

    ; Gather current settings into config object
    config := {}
    config.FOV_X := FOV_X
    config.FOV_Y := FOV_Y
    config.HeadOffset := HeadOffset
    config.HumanoidOffset := HumanoidOffset
    config.UpperTorsoOffset := UpperTorsoOffset
    config.PredictionAmount := PredictionAmount
    GuiControlGet, Bone,, Bone
    config.Bone := Bone
    config.Key := Key
    config.SmoothnessFactor := SmoothnessFactor
    GuiControlGet, AimAssistModeDDL,, AimAssistModeDDL
    config.AimAssistMode := AimAssistModeDDL



    ; Convert to JSON and save
    jsonText := JSON.Dump(config, 4)
    File := FileOpen(selectedFile, "w")
    File.Write(jsonText)
    File.Close()

    MsgBox, 64, Save Complete, Config saved successfully!
return


LaunchTriggerbot:
Gui, Submit, NoHide
global triggerbotPID
if (TriggerbotCheckbox) {
    if FileExist("triggerbot.ahk") {
        Run, triggerbot.ahk,,, triggerbotPID
    } else {
        MsgBox, 48, Not Found, triggerbot.ahk not found!
        GuiControl,, TriggerbotCheckbox, 0
    }
} else if (triggerbotPID) {
    Process, Close, %triggerbotPID%
    triggerbotPID := ""
    MsgBox, 64, Triggerbot Closed, Triggerbot was successfully closed.
}
return

;fov circle func-----

OpenFOVScript:
Run, %A_ScriptDir%\FOV.ahk
return


ImportConfig:
    FileSelectFile, selectedFile, 3, , Select a config file to import, JSON Files (*.json)
    if (selectedFile = "")
        return  ; User canceled

    if (FileExist(selectedFile)) {
        File := FileOpen(selectedFile, "r")
        configData := File.Read()
        File.Close()
        config := JSON.Load(configData)

	GuiControl,, SnapDistance, % config.SnapDistance
	GuiControl,, SnapStrength, % config.SnapStrength
	GuiControl,, PixelStep, % config.PixelStep
	GuiControl,, FOV_X, % config.FOV_X
	GuiControl,, FOV_Y, % config.FOV_Y
        GuiControl,, FOVAmount, % config.FOVAmount
        GuiControl,, HeadOffset, % config.HeadOffset
        GuiControl,, HumanoidOffset, % config.HumanoidOffset
        GuiControl,, UpperTorsoOffset, % config.UpperTorsoOffset
        GuiControl,, PredictionAmount, % config.PredictionAmount
        GuiControl,, Bone, % config.Bone
        GuiControl,, Key, % config.Key
        GuiControl,, SmoothnessFactor, % config.SmoothnessFactor
        GuiControl,, AimStyle, % config.AimStyle
        GuiControl,, StylePreset, % config.StylePreset
        CurrentStyle := config.StylePreset

	



   
        Gosub, ApplyStyle
        MsgBox, 64, Import Complete, Config imported successfully!
    } else {
        MsgBox, 48, Error, File does not exist.
    }
return

aimLock := true

SetTimer, CheckDeath, 100
return

CheckDeath:
    ; Scan the red bar area, coordinates may need tuning for your resolution
    PixelSearch, Px, Py, 880, 660, 1040, 700, 0xFF3E3E, 10, Fast RGB
    if (ErrorLevel = 0) {
        aimLock := false
        Tooltip, Death Detected - Aimbot Unlocked
        Sleep, 1000
        Tooltip
    }
return


ToggleAimAssist:
    aimAssistEnabled := !aimAssistEnabled
    if (aimAssistEnabled)
        GuiControl,, AimStatusIndicator, BackgroundGreen
    else
        GuiControl,, AimStatusIndicator, BackgroundRed
return


Insert::
guiVisible := !guiVisible
if (guiVisible)
    Gui, Show
else
    Gui, Hide
return


