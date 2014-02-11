; #FUNCTION# ====================================================================================================================
; Name...........: SimulKey
; Description ...: Simulate a Key-Send to a specified handle in the Background
; Author ........: Felix Lehmann
; Modified.......: If you modify this Script, please enter your name here
; Remarks .......: -
; Related .......: -
; Parameters ....: $hwnd = Specified Window to Send to
; ...............: $key = Key or String to Send (If String $string have to be enabled [see $string])
; ...............: $string = Set this to 1 If your "$key" is a string
; ...............: $state = Set this to 'up' or 'down' if u want a special event | Default is press the Key 1 Time
; ...............: $delay = The delay to hold the key down
; Return Values .: 1 = Done | -1 = Couldn't load user32.dll
; Link ..........; -
; ===============================================================================================================================
Func SimulKey($hWnd, $key, $string = 0, $state = 'skip', $delay = 10)
	;//Open DLL (user32)
	$user32 = DllOpen('user32.dll')
	If $user32 = -1 Then
		SetError(-1, 1, -1)
	EndIf

	;//Handle Special Keys
	Switch StringLower($key)
		Case 'enter'
			$WM_ENTER = 0x0d
			$dCall = DllCall($user32, 'int', "MapVirtualKey", 'int', $WM_ENTER, 'int', 0)
			$lParam = BitOR(BitShift($dCall[0], -16), 1)
		Case 'space'
			$WM_SPACE = 0x20
			$dCall = DllCall($user32, 'int', "MapVirtualKey", 'int', $WM_SPACE, 'int', 0)
			$lParam = BitOR(BitShift($dCall[0], -16), 1)
		Case 'tab'
			$WM_TAB = 0x09
			$dCall = DllCall($user32, 'int', "MapVirtualKey", 'int', $WM_TAB, 'int', 0)
			$lParam = BitOR(BitShift($dCall[0], -16), 1)
			;//Handle Standard Keys
		Case Else
			;//Stringmode 1
			If $string = 1 Then
				$split = StringSplit($key, "")
				For $ctn = 1 To $split[0]
					$split[$ctn] = Asc(StringLower($split[$ctn]))
				Next
				For $ctn = 1 To $split[0]
					$dCall = DllCall($user32, 'int', "VkKeyScan", 'int', $split[$ctn])
					$lParamAsc = DllCall($user32, 'int', "MapVirtualKey", 'int', $dCall[0], 'int', 0)
					$lParam = BitOR(BitShift($lParamAsc[0], -16), 1)
					$lUpParam = BitOR($lParam, 0xC0000000)
					DllCall($user32, 'int', "PostMessage", 'hwnd', $hWnd, 'int', $WM_KEYDOWN, 'int', $dCall[0], 'int', $lParam)
					Sleep($delay)
					DllCall($user32, 'int', "PostMessage", 'hwnd', $hWnd, 'int', $WM_KEYUP, 'int', $dCall[0], 'int', $lUpParam)
					Sleep(100)
				Next
				;//Stringmode 0
			ElseIf $string = 0 Then
				$key = Asc(StringLower($key))
				$dCall = DllCall($user32, 'int', "VkKeyScan", 'int', $key)
				$lParamAsc = DllCall($user32, 'int', "MapVirtualKey", 'int', $dCall[0], 'int', 0)
				$lParam = BitOR(BitShift($lParamAsc[0], -16), 1)
			EndIf
	EndSwitch
	$lUpParam = BitOR($lParam, 0xC0000000)
	If $string = 0 Then
		Switch StringLower($state)
			Case 'skip'
				DllCall($user32, 'int', "PostMessage", 'hwnd', $hWnd, 'int', $WM_KEYDOWN, 'int', $dCall[0], 'int', $lParam)
				Sleep($delay)
				DllCall($user32, 'int', "PostMessage", 'hwnd', $hWnd, 'int', $WM_KEYUP, 'int', $dCall[0], 'int', $lUpParam)
			Case 'down'
				DllCall($user32, "int", "PostMessage", "hwnd", $hWnd, "int", $WM_KEYDOWN, "int", $dCall[0], "int", $lParam)
			Case 'up'
				DllCall($user32, "int", "PostMessage", "hwnd", $hWnd, "int", $WM_KEYUP, "int", $dCall[0], "int", $lParam)
		EndSwitch
	EndIf
	DllClose($user32)
	Return 1
EndFunc   ;==>SimulKey