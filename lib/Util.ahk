SendMessage(Msg, wParam, lParam, hWnd)
{
	; DllCall("SendMessage", "UPtr", hWnd, "UInt", Msg, "UPtr", wParam, "Ptr", lParam, "UPtr")
	SendMessage, Msg, wParam, lParam,, ahk_id %hWnd%
	return ErrorLevel
}

; Modified from https://github.com/cocobelgica/AutoHotkey-Util/blob/master/ExecScript.ahk
ExecScript(Script, Params="", AhkPath="")
{
	static Shell := ComObjCreate("WScript.Shell")
	Name := "\\.\pipe\AHK_CQT_" A_TickCount
	Pipe := []
	Loop, 3
	{
		Pipe[A_Index] := DllCall("CreateNamedPipe"
		, "Str", Name
		, "UInt", 2, "UInt", 0
		, "UInt", 255, "UInt", 0
		, "UInt", 0, "UPtr", 0
		, "UPtr", 0, "UPtr")
	}
	if !FileExist(AhkPath)
		throw Exception("AutoHotkey runtime not found: " AhkPath)
	if FileExist(Name)
	{
		Exec := Shell.Exec(AhkPath " /CP65001 " Name " " Params)
		DllCall("ConnectNamedPipe", "UPtr", Pipe[2], "UPtr", 0)
		DllCall("ConnectNamedPipe", "UPtr", Pipe[3], "UPtr", 0)
		FileOpen(Pipe[3], "h", "UTF-8").Write(Script)
	}
	else ; Running under WINE with improperly implemented pipes
	{
		FileOpen(Name := "AHK_CQT_TMP.ahk", "w").Write(Script)
		Exec := Shell.Exec(AhkPath " /CP65001 " Name " " Params)
	}
	Loop, 3
		DllCall("CloseHandle", "UPtr", Pipe[A_Index])
	return Exec
}

MenuBar(Menu)
{
	static MenuName := 0
	Menus := ["MenuBar_" MenuName++]
	for each, Item in Menu
	{
		Ref := Item[2]
		if IsObject(Ref) && Ref._NewEnum()
		{
			SubMenus := MenuBar(Ref)
			Menus.Push(SubMenus*), Ref := ":" SubMenus[1]
		}
		Menu, % Menus[1], Add, % Item[1], %Ref%
	}
	return Menus
}

ToB64(Text)
{
	VarSetCapacity(In, StrPut(Text, Encoding))
	InLen := StrPut(Text, &In, Encoding)-1
	DllCall("Crypt32.dll\CryptBinaryToString", "Ptr", &In
	, "UInt", InLen, "UInt", 0x40000001, "Ptr", 0, "UInt*", OutLen)
	VarSetCapacity(Out, OutLen * (1+A_IsUnicode))
	DllCall("Crypt32.dll\CryptBinaryToString", "Ptr", &In
	, "UInt", InLen, "UInt", 0x40000001, "Str", Out, "UInt*", OutLen)
	return Out
}