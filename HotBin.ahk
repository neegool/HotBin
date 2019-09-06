ListLines, Off
SetWorkingDir, %A_ScriptDir%

#KeyHistory 0
#NoEnv
#SingleInstance Ignore

IconFile := A_WinDir . "\System32\Shell32.dll"
IconEmpty := -32
IconFull := -33

NumPut(VarSetCapacity(SHQueryRBInfo, 24, 0), SHQueryRBInfo, "UInt")
SHQueryRecycleBin := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "Shell32", "Ptr"), "AStr", "SHQueryRecycleBin" . (A_IsUnicode ? "W" : "A"), "Ptr")

GoSub, MakeTray
SetTimer, UpdateTray
return

MakeTray:
Menu, Tray, NoIcon
Menu, Tray, NoStandard
Menu, Tray, Add, % LangReadLine(1, "Open"), OpenRecycleBin
Menu, Tray, Add
Menu, Tray, Add, % LangReadLine(2, "Empty"), EmptyRecycleBin
Menu, Tray, Add
Menu, Tray, Add, % LangReadLine(3, "Quit"), QuitHotBin
Menu, Tray, Default, 1&
Menu, Tray, Icon
Menu, Tray, Icon, %IconFile%, %IconEmpty%, 1
return

+!E::
EmptyRecycleBin:
FileRecycleEmpty
return

+!O::
OpenRecycleBin:
Run, Shell:RecycleBinFolder
return

UpdateTray:
DllCall(SHQueryRecycleBin, "Ptr", 0, "Ptr", &SHQueryRBInfo, "Int")
Bytes := NumGet(SHQueryRBInfo, A_PtrSize, "Int64")
Total := NumGet(SHQueryRBInfo, A_PtrSize + 8, "Int64")
Tip := Total . " (" . FormatBytes(Bytes) . ")"
Menu, Tray, Icon
Menu, Tray, % Total ? "Enable" : "Disable", 3&
Menu, Tray, Icon, %IconFile%, % Total ? IconFull : IconEmpty, 1
Menu, Tray, Icon, 3&, %IconFile%, % Total ? IconFull : IconEmpty
Menu, Tray, Tip, % Tip
return

+!Q::
QuitHotBin:
ExitApp
return

LangReadLine(byref _LineNumber, byref _Default)
{
    FileReadLine, Value, Lang\%A_Language%.txt, %_LineNumber%
    return Value == "" ? _Default : Value
}

FormatBytes(byref _Bytes)
{
    static IEC := ["B", "KiB", "MiB", "GiB", "TiB"]
    Log2 := Log(Floor(Max(_Bytes, 0))) / Log(1024)
    return RegexReplace(Round(1024 ** (Log2 - Floor(Log2)), 2), "\.?0+$") . " " . IEC[Max(Floor(Log2), 0) + 1]
}
