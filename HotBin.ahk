ListLines, Off
Process, Priority,, BelowNormal

#KeyHistory 0
#NoEnv
#SingleInstance Ignore

;// SHQUERYRBINFO struct. Used for SHQueryRecycleBin().
NumPut(VarSetCapacity(SHQUERYRBINFO, 24, 0), SHQUERYRBINFO, "UInt")
;// The handle of shell32.dll. Used for LoadString().
shell32 := DllCall("GetModuleHandle", "Str", "shell32.dll", "Ptr")

Menu, Tray, NoIcon
Menu, Tray, NoStandard
;// 12850 is "Open" in en-US.
Menu, Tray, Add, % LoadString(shell32, 12850), RecycleBinFolder
Menu, Tray, Add
;// 10564 is "Empty Recycle &Bin" in en-US.
Menu, Tray, Add, % StrReplace(LoadString(shell32, 10564), "&"), FileRecycleEmpty
Menu, Tray, Add
;// 12851 is "Close" in en-US.
Menu, Tray, Add, % LoadString(shell32, 12851), ExitApp
Menu, Tray, Default, 1&
Menu, Tray, Icon
Menu, Tray, Icon, shell32.dll, -32, 1

SetTimer, UpdateTray
return

ExitApp:
ExitApp
return

+!E::
FileRecycleEmpty:
FileRecycleEmpty
return

+!R::
RecycleBinFolder:

Run, Shell:RecycleBinFolder
return

UpdateTray:
if !SHQueryRecycleBin(0, SHQUERYRBINFO)
{
    bytes := NumGet(SHQUERYRBINFO, A_PtrSize, "Int64")
   ,count := NumGet(SHQUERYRBINFO, A_PtrSize + 8, "Int64")
    if count
    {   
        ;// Enable "Empty Recycle Bin" and change the icon to the full bin.
        Menu, Tray, Enable, 3&
        Menu, Tray, Icon, shell32, -33, 1
        Menu, Tray, Icon, 3&, shell32, -33
    }
    else
    {
        ;// Disable "Empty Recycle Bin" and change the icon to the empty bin.
        Menu, Tray, Disable, 3&
        Menu, Tray, Icon, shell32, -32, 1
        Menu, Tray, Icon, 3&, shell32, -32
    }
    Menu, Tray, Tip, % Format("{}`n{}", count, FormatBytes(bytes))
}
return

FormatBytes(byref r_bytes)
{
    ;// Format a number of bytes to a human-readable string.
    static s_symbols := ["B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB"]
    if !r_bytes
        return "0.00 B"
    n := Floor(Log(r_bytes) / Log(1024))
    return Round(r_bytes / 1024 ** n, 2) . " " . s_symbols[n + 1]
}

LoadString(byref r_instance, byref r_id)
{
    ;// https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-loadstringa
    ;// https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-loadstringw
    static s_ptr := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32", "Ptr"), "AStr", "LoadString" . (A_IsUnicode ? "W" : "A"), "Ptr")
    VarSetCapacity(string, 160 << A_IsUnicode)
   ,DllCall(s_ptr, "Ptr", r_instance, "UInt", r_id, "Str", string, "Int", 160, "Int")
    return string
}

SHQueryRecycleBin(byref r_root, byref r_SHQUERYRBINFO)
{
    ;// https://docs.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shqueryrecyclebina
    ;// https://docs.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shqueryrecyclebinw
    static s_ptr := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "shell32", "Ptr"), "AStr", "SHQueryRecycleBin" . (A_IsUnicode ? "W" : "A"), "Ptr")    
    return DllCall(s_ptr, "Ptr", r_root, "Ptr", &r_SHQUERYRBINFO, "Int")
}
