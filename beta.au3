#include <SendMessage.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <MCKeys.au3>
#include <SimulKey.au3>
#include <Array.au3>

; REQUIRED: %appdata%\.minecraft\options.txt > pauseOnLostFocus:false
; Known Bugs: SimulKey will not release keyboard button on termination
;
; Supported parameters:
;
; --hidewindow=false
; --holdtime=5000
; --eatfood=true
; --eatfoodticks=20
; --hotkeyfood=2
; --hotkeypickaxe=1
;
Global $Name = "Toothpick"
Global $Version = 1.0

Global $HideWindow = False
Global $HoldKeyTime = 5000 ; 5 seconds - controls mining & eating time
Global $EatFoodTicks = 5
Global $EatFood = True
Global $HotkeyFood = 2
Global $HotkeyPickaxe = 1

Global $MinecraftHandleClass = "[CLASS:LWJGL]"
Global $hWndControl = WinGetHandle($MinecraftHandleClass)
Global $MCPath = EnvGet("appdata") & "\.minecraft\"
Global $MCOptions = "options.txt"
Global $buttonUP, $buttonDOWN, $WindowTitle
Global $Hotkey[4]
#cs =================
	0 - attack key
	1 - use key
	2 - hotbar key 1
	3 - hotbar key 2
#ce =================

StartUp()

Func userInput()
	If ( $CmdLine[0] == 0 ) Then Return
	Local $split
	For $i = $CmdLine[0] To 1 Step -1
		ConsoleWrite("Checking user input" & @CRLF)
		$split = StringSplit($CmdLine[$i], "=")
		_ArrayDisplay($split)
		Switch $split[1]
			Case "--hidewindow"
				If ( StringUpper($split[2] == "TRUE") ) Then
					$HideWindow = True
				Else
					$HideWindow = False
				EndIf
			Case "--holdtime"
				If ( IsNumber(Number($split[2])) ) Then
					$HoldKeyTime = Number($split[2])
				EndIf
			Case "--eatfood"
				If ( StringUpper($split[2] == "TRUE") ) Then
					$EatFood = True
				Else
					$EatFood = False
				EndIf
			Case "--eatfoodticks"
				If ( IsNumber(Number($split[2])) ) Then
					$EatFoodTicks = Number($split[1])
				EndIf
			Case "--hotkeyfood"
				ConsoleWrite("user input: hotkeyFood: ")
				$split[2] = Number($split[2])
				If ( IsNumber($split[2]) AND $split[2] >= 1 AND $split[2] <= 9 ) Then
					ConsoleWrite($split[2] & @CRLF)
					$HotkeyFood = $split[2]
				EndIf
			Case "--hotkeypickaxe"
				ConsoleWrite("user input: hotkeyPickaxe: ")
				$split[2] = Number($split[2])
				If ( IsNumber($split[2]) AND $split[2] >= 1 AND $split[2] <= 9 ) Then
					ConsoleWrite($split[2] & @CRLF)
					$HotkeyPickaxe = $split[2]
				EndIf
		EndSwitch
	Next
EndFunc

Func StartUp()
	userInput()
	If ( FileExists($MCPath) ) Then
		If ( FileExists($MCPath & $MCOptions) ) Then
			If ( DetectHotkeys($MCPath & $MCOptions) ) Then
				If WinExists($MinecraftHandleClass) Then
					$WindowTitle = WinGetTitle($MinecraftHandleClass)
					WinSetTitle($MinecraftHandleClass, "", $Name & " v." & $Version & " - " & $WindowTitle)
					If ( $HideWindow ) Then
						WinSetState($MinecraftHandleClass, "", @SW_HIDE)
						WinSetState($MinecraftHandleClass, "", @SW_DISABLE)
					EndIf
					SendKey($Hotkey[2])
					HotKeySet("{Esc}", "Terminate")
					Loop()
				Else
					ConsoleWrite("ERROR: Minecraft isn't running!" & @CRLF)
				EndIf
			Else
				ConsoleWrite("ERROR: Unable to detect hotkeys!" & @CRLF)
			EndIf
		Else
			ConsoleWrite("Unable to find options.txt file" & @CRLF)
		EndIf
	Else
		ConsoleWrite("Unable to find minecraft folder" & @CRLF)
	EndIf
EndFunc

Func DetectHotkeys($path)
	If ( Not FileExists($path) ) Then
		Return False
	EndIf
	Local $lines, $split
	_FileReadToArray($path, $lines)
	For $i = $lines[0] To 1 Step -1
		$split = StringSplit(StringStripWS($lines[$i], 8), ":")
		If ( $split[0] <> 2 ) Then
			ContinueLoop
		EndIf
		If ( $split[1] == "key_key.attack" ) Then
			$Hotkey[0] = $split[2]
			ConsoleWrite("ATTACK KEY: " & NumberToKey($split[2]) & @CRLF)
		ElseIf ( $split[1] == "key_key.use" ) Then
			$Hotkey[1] = $split[2]
			ConsoleWrite("USE KEY: " & NumberToKey($split[2]) & @CRLF)
		ElseIf ( $split[1] == "key_key.hotbar." & $HotkeyPickaxe ) Then
			$Hotkey[2] = $split[2]
			ConsoleWrite("HOTBAR PICKAXE KEY: " & NumberToKey($split[2]) & @CRLF)
		ElseIf ( $split[1] == "key_key.hotbar." & $HotkeyFood ) Then
			$Hotkey[3] = $split[2]
			ConsoleWrite("HOTBAR FOOD KEY: " & NumberToKey($split[2]) & @CRLF)
		EndIf
	Next
	Return True
	If ( $Hotkey[0] == "" OR $Hotkey[0] == False OR $Hotkey[1] == "" OR $Hotkey[1] == False OR $Hotkey[2] == "" OR $Hotkey[2] == False OR $Hotkey[3] == "" OR $Hotkey[3] == False ) Then
		ConsoleWrite("Unable to detect hotkeys!")
		Return False
	EndIf
EndFunc

Func NumberToKey($number)
	For $i = $MCKEYMAP[0][0] To 1 Step -1
		If ( $number == $MCKEYMAP[$i][0] ) Then
		 Return $MCKEYMAP[$i][1]
		 ExitLoop
		EndIf
	Next
	Return False
EndFunc

Func SendKey($key, $hold = 0)
	If ( $key > 0 ) Then
		if ( $hold ) Then
			SimulKey($hWndControl, StringTrimLeft(StringTrimRight(NumberToKey($key), 1), 1), 0, "skip", $HoldKeyTime)
		Else
			ControlSend($MinecraftHandleClass, "", "", NumberToKey($key))
		EndIf
	Else
		Local $k, $TimerBegin
		$k = NumberToKey($key)
		If ( $k == "left" ) Then
			$buttonUP = $WM_LBUTTONUP
			$buttonDOWN = $WM_LBUTTONDOWN
		ElseIf ( $k == "right" ) Then
			$buttonUP = $WM_RBUTTONUP
			$buttonDOWN = $WM_RBUTTONDOWN
		ElseIf ( $k == "middle" ) Then
			$buttonUP = $WM_MBUTTONUP
			$buttonDOWN = $WM_MBUTTONDOWN
		EndIf
		_SendMessage($hWndControl, $buttonDOWN)
		$TimerBegin = TimerInit()
		While ( $HoldKeyTime > TimerDiff($TimerBegin) )
			Sleep(100)
		WEnd
		_SendMessage($hWndControl, $buttonUP)
	EndIf
EndFunc

Func Loop()
	Local $Ticks = 0
	Local $TimerBegin, $TimerDiff
	if ( $EatFood ) Then
		While 1
			Sleep(100)
			ConsoleWrite("Mining" & @CRLF)
			SendKey($Hotkey[0], 1)
			$Ticks = 1 + $Ticks
			ConsoleWrite("$Ticks: " & $Ticks & @CRLF)
			If ( $Ticks > $EatFoodTicks ) Then
				ConsoleWrite("Changing to food" & @CRLF)
				SendKey($Hotkey[3])
				ConsoleWrite("Eating" & @CRLF)
				SendKey($Hotkey[1], 1)
				ConsoleWrite("Changing to Pickaxe" & @CRLF)
				SendKey($Hotkey[2])
				$Ticks = 0
			EndIf
		WEnd
	Else
		While 1
			Sleep(100)
			SendKey($Hotkey[0], 1)
		WEnd
	EndIf
EndFunc


Func Terminate()
	; release keys if possible
	SimulKey($hWndControl, $Hotkey[0], 0, "up")
	SimulKey($hWndControl, $Hotkey[1], 0, "up")
	_SendMessage($hWndControl, $buttonUP)
	; Restore original title
	WinSetTitle($MinecraftHandleClass, "", $WindowTitle)
	If ( $HideWindow ) Then
		WinSetState($MinecraftHandleClass, "", @SW_ENABLE)
		WinSetState($MinecraftHandleClass, "", @SW_SHOW)
	EndIf
	ConsoleWrite("Bye!" & @CRLF)
	Exit 0
EndFunc