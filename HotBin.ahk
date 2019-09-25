ListLines, Off
SetWorkingDir, %A_ScriptDir%

#KeyHistory 0
#NoEnv
#SingleInstance Ignore

IconFile := A_WinDir . "\System32\Shell32.dll"
IconEmpty := -32
IconFull := -33
BytesOffset := A_PtrSize
TotalOffset := BytesOffset + 8

NumPut(VarSetCapacity(SHQueryRBInfo, 24, 0), SHQueryRBInfo, "UInt")
SHQueryRecycleBin := DllCall("Kernel32\GetProcAddress", "Ptr", DllCall("Kernel32\GetModuleHandle" . (A_IsUnicode ? "W" : "A"), "Str", "Shell32", "Ptr"), "AStr", "SHQueryRecycleBin" . (A_IsUnicode ? "W" : "A"), "Ptr")

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

SetTimer, UpdateTray
return

+!E::
EmptyRecycleBin:
FileRecycleEmpty
return

+!Q::
QuitHotBin:
ExitApp
return

+!R::
OpenRecycleBin:
Run, Shell:RecycleBinFolder
return

UpdateTray:
if !DllCall(SHQueryRecycleBin, "Ptr", 0, "Ptr", &SHQueryRBInfo, "Int")
{
    Bytes := NumGet(SHQueryRBInfo, BytesOffset, "Int64")
    Total := NumGet(SHQueryRBInfo, TotalOffset, "Int64")
    Menu, Tray, % Total ? "Enable" : "Disable", 3&
    Menu, Tray, Icon, %IconFile%, % Total ? IconFull : IconEmpty, 1
    Menu, Tray, Icon, 3&, %IconFile%, % Total ? IconFull : IconEmpty
    Menu, Tray, Tip, % Total . " (" . FormatBytes(Bytes) . ")"
}
return

LangReadLine(byref r_LineNumber, byref r_Default)
{
    FileReadLine, Value, Lang\%A_Language%.txt, %r_LineNumber%
    return Value == "" ? r_Default : Value
}

FormatBytes(byref r_Bytes)
{
    static s_Symbols := ["KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"] 
    if !r_Bytes
        return "0.00 B"
    n := Floor(Log(r_Bytes) / Log(1024))
    return Round(r_Bytes / 1024 ** n, 2) . " " . s_Symbols[n]
}
