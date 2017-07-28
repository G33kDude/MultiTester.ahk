class RichEdit
{
	static Msftedit := DllCall("LoadLibrary", "Str", "Msftedit.dll")
	
	Value[]
	{
		Get
		{
			GuiControlGet, Value,, % this.hWnd
			return Value
		}
		
		Set
		{
			GuiControl,, % this.hWnd, %Value%
			return Value
		}
	}
	
	__New(BGColor, FGColor, Contents="", TabSize=4)
	{
		Gui, Add, Custom, ClassRichEdit50W hWndhWnd +0x5031b1c4 +E0x20000, %Contents%
		this.hWnd := hWnd
		
		; Set background color
		SendMessage, 0x443, 0, BGColor,, ahk_id %hWnd% ; EM_SETBKGNDCOLOR
		
		; Set FG color
		VarSetCapacity(CharFormat, 116, 0)
		NumPut(116, CharFormat, 0, "UInt") ; cbSize := sizeOf(CHARFORMAT2)
		NumPut(0x40000000, CharFormat, 4, "UInt") ; dwMask := CFM_COLOR
		NumPut(FGColor, CharFormat, 20, "UInt") ; crTextColor := 0xBBGGRR
		SendMessage, 0x444, 0, &CharFormat,, ahk_id %hWnd% ; EM_SETCHARFORMAT
		
		; Set tab size to 4
		VarSetCapacity(TabStops, 4, 0), NumPut(TabSize*4, TabStops, "UInt")
		SendMessage, 0x0CB, 1, &TabStops,, ahk_id %hWnd% ; EM_SETTABSTOPS
		
		; Change text limit from 32,767 to max
		SendMessage, 0x435, 0, -1,, ahk_id %hWnd% ; EM_EXLIMITTEXT
		
		; Disable inconsistent formatting
		SendMessage, 0x4CC, 1, 1,, ahk_id %hWnd% ; EM_SETEDITSTYLE SES_EMULATESYSEDIT
		SendMessage, 0x452, 100, 0,, ahk_id %hWnd% ; EM_SETUNDOLIMIT
		
		OnMessage(0x100, this.OnMessage.Bind(hWnd))
	}
	
	OnMessage(wParam, lParam, Msg, hWnd)
	{
		if (hWnd != this)
			return
		
		if (Msg == 0x100) ; WM_KEYDOWN
		{
			if (wParam == GetKeyVK("Tab"))
			{
				ControlGet, Selected, Selected,,, % "ahk_id" hWnd
				if (Selected == "" && !GetKeyState("Shift"))
					SendMessage, 0xC2, 1, &(x:="`t"),, % "ahk_id" hWnd ; EM_REPLACESEL
				else if GetKeyState("Shift")
					RichEdit.Unindent(hWnd)
				else
					RichEdit.Indent(hWnd)
				return False
			}
			else if (wParam == GetKeyVK("Escape"))
				return False
		}
		
	}
	
	Indent(hWnd)
	{
		GuiControlGet, Text,, %hWnd%
		Text := StrSplit(Text, "`n", "`r")
		
		VarSetCapacity(s, 8, 0), SendMessage(0x0B0, &s, &s+4, hWnd) ; EM_GETSEL
		Left := NumGet(s, 0, "UInt"), Right := NumGet(s, 4, "UInt")
		
		Top := SendMessage(0x436, 0, Left, hWnd) ; EM_EXLINEFROMCHAR
		Bottom := SendMessage(0x436, 0, Right, hWnd) ; EM_EXLINEFROMCHAR
		
		Count := Bottom-Top + 1
		Loop, % Count
			Text[A_Index+Top] := "`t" Text[A_Index+Top]
		for each, Line in Text
			Out .= "`r`n" Line
		Out := SubStr(Out, 3)
		
		GuiControl,, %hWnd%, %Out%
		
		NumPut(NumGet(s, "UInt") + 1, &s, "UInt")
		NumPut(NumGet(s, 4, "UInt") + Count, &s, 4, "UInt")
		SendMessage(0x437, 0, &s, hWnd) ; EM_EXSETSEL
	}
	
	Unindent(hWnd)
	{
		GuiControlGet, Text,, %hWnd%
		Text := StrSplit(Text, "`n", "`r")
		
		VarSetCapacity(s, 8, 0), SendMessage(0x0B0, &s, &s+4, hWnd) ; EM_GETSEL
		Left := NumGet(s, 0, "UInt"), Right := NumGet(s, 4, "UInt")
		
		Top := SendMessage(0x436, 0, Left, hWnd) ; EM_EXLINEFROMCHAR
		Bottom := SendMessage(0x436, 0, Right, hWnd) ; EM_EXLINEFROMCHAR
		
		Removed := 0
		Loop, % Bottom-Top + 1
			if InStr(Text[A_Index+Top], "`t") == 1
				Text[A_Index+Top] := SubStr(Text[A_Index+Top], 2), Removed++
		for each, Line in Text
			Out .= "`r`n" Line
		Out := SubStr(Out, 3)
		
		GuiControl,, %hWnd%, %Out%
		
		NumPut(NumGet(s, "UInt") - 1, &s, "UInt")
		NumPut(NumGet(s, 4, "UInt") - Removed, &s, 4, "UInt")
		SendMessage(0x437, 0, &s, hWnd) ; EM_EXSETSEL
	}
}