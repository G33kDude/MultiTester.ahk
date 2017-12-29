#NoEnv
SetBatchLines, -1

; Settings array for the RichCode controls
DefaultSettings :=
( LTrim Join Comments
{
	"TabSize": 4,
	"Indent": "`t",
	"FGColor": 0xEDEDCD,
	"BGColor": 0x3F3F3F,
	"Font": {"Typeface": "Consolas", "Size": 11},
	
	"UseHighlighter": True,
	"HighlightDelay": 200,
	"Colors": {
		"Comments":     0x7F9F7F,
		"Functions":    0x7CC8CF,
		"Keywords":     0xE4EDED,
		"Multiline":    0x7F9F7F,
		"Numbers":      0xF79B57,
		"Punctuation":  0x97C0EB,
		"Strings":      0xCC9893
	}
}
)

Settings :=
( LTrim Join
{
	"AHK": {
		"base": DefaultSettings,
		"Highlighter": Func("HighlightAHK"),
		"Colors": {
			"A_Builtins": 0xF79B57,
			"Commands":   0xCDBFA3,
			"Directives": 0x7CC8CF,
			"Flow":       0xE4EDED,
			"KeyNames":   0xCB8DD9
		}
	},
	"CSS": {
		"base": DefaultSettings,
		"Highlighter": Func("HighlightCSS"),
		"Colors": {
			"ColorCodes": 0x7CC8CF,
			"Properties": 0xCDBFA3,
			"Selectors":  0xE4EDED
		}
	},
	"HTML": {
		"base": DefaultSettings,
		"Highlighter": Func("HighlightHTML"),
		"Colors": {
			"Attributes": 0x7CC8CF,
			"Entities":   0xF79B57,
			"Tags":       0xCDBFA3
		}
	},
	"JS": {
		"base": DefaultSettings,
		"Highlighter": Func("HighlightJS"),
		"Colors": {
			"Builtins":     0xE4EDED,
			"Constants":    0xF79B57,
			"Declarations": 0xCDBFA3
		}
	}
}
)

x := new Editor(Settings)
x.Open("samples\pages.json")
return

class Editor
{
	Title := "MultiTester"
	
	__New(Settings)
	{
		Menus :=
		( Join
		[
			["&File", [
				["&Run`tAlt+R", this.Run.Bind(this)],
				["&Save`tCtrl+S", this.Save.Bind(this)],
				["&Open`tCtrl+O", this.Open.Bind(this)]
			]]
		]
		)
		
		Gui, New, +Resize +hWndhMainWindow
		this.hMainWindow := hMainWindow
		this.Menus := MenuBar(Menus)
		Gui, Menu, % this.Menus[1]
		Gui, Margin, 5, 5
		
		
		; Add code editors
		AHK := new RichCode(Settings.AHK)
		CSS := new RichCode(Settings.CSS)
		HTML := new RichCode(Settings.HTML)
		JS := new RichCode(Settings.JS)
		
		AHK.Value := "; AHK"
		CSS.Value := "/* CSS */"
		HTML.Value := "<!-- HTML -->"
		JS.Value := "// JavaScript"
		
		this.Editors := {"HTML": HTML, "CSS": CSS, "JS": JS, "AHK": AHK}
		
		
		WinEvents.Register(this.hMainWindow, this)
		
		Gui, Show, w640 h480, % this.Title
	}
	
	GuiClose()
	{
		WinEvents.Unregister(this.hMainWindow)
		ExitApp
	}
	
	GuiSize(GuiHwnd, EventInfo, Width, Height)
	{
		GuiControl, Move, % this.Editors.HTML.hWnd, % "x" Width/2*0 " y" Height/2*0 " w" Width/2 " h" Height/2
		GuiControl, Move, % this.Editors.CSS.hWnd , % "x" Width/2*0 " y" Height/2*1 " w" Width/2 " h" Height/2
		GuiControl, Move, % this.Editors.JS.hWnd  , % "x" Width/2*1 " y" Height/2*0 " w" Width/2 " h" Height/2
		GuiControl, Move, % this.Editors.AHK.hWnd , % "x" Width/2*1 " y" Height/2*1 " w" Width/2 " h" Height/2
	}
	
	Run()
	{
		Script := BuildScript(this.Editors.HTML.Value, this.Editors.CSS.Value
		, this.Editors.JS.Value, this.Editors.AHK.Value)
		ExecScript(Script,, A_AhkPath)
	}
	
	Save()
	{
		Gui, +OwnDialogs
		FileSelectFile, FilePath, S18,, % this.Title " - Save Code", *.json
		if ErrorLevel
			return
		
		FileOpen(FilePath (FilePath ~= "i)\.json$" ? "" : ".json"), "w")
		.Write(Jxon_Dump({"HTML": this.Editors.HTML.Value
		, "CSS": this.Editors.CSS.Value
		, "JS": this.Editors.JS.Value
		, "AHK": this.Editors.AHK.Value}))
	}
	
	Open(FilePath:="")
	{
		if (FilePath == "")
		{
			Gui, +OwnDialogs
			FileSelectFile, FilePath, 3,, % this.Title " - Open Code", *.json
			if ErrorLevel
				return
		}
		
		Code := Jxon_Load(FileOpen(FilePath, "r").Read())
		this.Editors.HTML.Value := Code.HTML
		this.Editors.CSS.Value := Code.CSS
		this.Editors.JS.Value := Code.JS
		this.Editors.AHK.Value := Code.AHK
	}
}

BuildScript(HTML, CSS, JS, AHK)
{
	HTML := ToB64(HTML)
	CSS := ToB64(CSS)
	JS := ToB64(JS)
	
	Script =
	(
#NoEnv
SetBatchLines, -1

Gui, +Resize
Gui, Margin, 0, 0
Gui, Add, ActiveX, vWB w640 h480, Shell.Explorer
Gui, Show

WB.Navigate("about:<!DOCTYPE html><meta "
. "http-equiv='X-UA-Compatible' content='IE=edge'>")
while WB.ReadyState < 4
	Sleep, 50

WB.document.write("<body>" FromB64("%HTML%") "</body>")

Style := WB.document.createElement("style")
Style.type := "text/css"
Style.styleSheet.cssText := FromB64("%CSS%")
WB.document.body.appendChild(Style)

%AHK%

Script := WB.document.createElement("script")
Script.text := FromB64("%JS%")
WB.document.body.appendChild(Script)
return

GuiSize:
GuiControl, Move, WB, x0 y0 w`%A_GuiWidth`% h`%A_GuiHeight`%
return

GuiClose:
ExitApp
return

FromB64(ByRef Text)
{
	DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &Text, "UInt", StrLen(Text)
	, "UInt", 0x1, "Ptr", 0, "UInt*", OutLen, "Ptr", 0, "Ptr", 0)
	VarSetCapacity(Out, OutLen)
	DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &Text, "UInt", StrLen(Text)
	, "UInt", 0x1, "Str", Out, "UInt*", OutLen, "Ptr", 0, "Ptr", 0)
	return StrGet(&Out, OutLen, Encoding)
}
	)
	
	return Script
}

#Include lib\AutoHotkey-JSON\Jxon.ahk
#Include lib\RichCode.ahk\RichCode.ahk
#Include lib\RichCode.ahk\Highlighters\AHK.ahk
#Include lib\RichCode.ahk\Highlighters\CSS.ahk
#Include lib\RichCode.ahk\Highlighters\HTML.ahk
#Include lib\RichCode.ahk\Highlighters\JS.ahk
#Include lib\Util.ahk
#Include lib\WinEvents.ahk