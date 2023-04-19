ListLines(false)
ProcessSetPriority("BelowNormal")

KeyHistory(0)
; REMOVED: #NoEnv
#SingleInstance Ignore

;// SHQUERYRBINFO struct. Used for SHQueryRecycleBin().
SHQUERYRBINFO := Buffer(24, 0)
NumPut("UInt", 24, SHQUERYRBINFO)
;// The handle of shell32.dll. Used for LoadString().
shell32 := DllCall("GetModuleHandle", "Str", "shell32.dll", "Ptr")

Tray:= A_TrayMenu
Tray.Delete() ; V1toV2: not 100% replacement of NoStandard, Only if NoStandard is used at the beginning
;// 12850 is "Open" in en-US.
Tray.Add(LoadString(&shell32, 12850), RecycleBinFolderTray)
Tray.Add()
;// 10564 is "Empty Recycle &Bin" in en-US.
Tray.Add(StrReplace(LoadString(&shell32, 10564), ""), FileRecycleEmptyTray)
Tray.Add()
;// 12851 is "Close" in en-US.
Tray.Add(LoadString(&shell32, 12851), ExitAppTray)
Tray.Default := "1&"

TraySetIcon("shell32.dll", "-32", "1")

SetTimer(UpdateTray)
return

ExitAppTray(A_ThisMenuItem, A_ThisMenuItemPos, MyMenu)
{
    ExitApp()
    return
}

#+Del::
{
    FileRecycleEmptyWithPrompt()
    return
}

+!R::
{
    Run("Shell:RecycleBinFolder")
    return
}

RecycleBinFolderTray(A_ThisMenuItem, A_ThisMenuItemPos, MyMenu)
{ 
    Run("Shell:RecycleBinFolder")
    return
}

FileRecycleEmptyTray(A_ThisMenuItem, A_ThisMenuItemPos, MyMenu)
{
    FileRecycleEmptyWithPrompt()
    return
}

FileRecycleEmptyWithPrompt()
{
    if !SHQueryRecycleBin(0, SHQUERYRBINFO)
    {
        bytes := NumGet(SHQUERYRBINFO, A_PtrSize, "Int64")
        count := NumGet(SHQUERYRBINFO, A_PtrSize + 8, "Int64")
        if count
        {
            If (count = 1)
                msgResult := MsgBox("Are you sure you want to permanently delete this item?", "Delete File", 52)
            else
                msgResult := MsgBox("Are you sure you want to permanently delete these " count " items?", "Delete Multiple Items", 52)
            
            if (msgResult = "Yes")
                FileRecycleEmpty()
        }
    }
}

UpdateTray()
{
    if !SHQueryRecycleBin(0, SHQUERYRBINFO)
    {
        bytes := NumGet(SHQUERYRBINFO, A_PtrSize, "Int64") 
        count := NumGet(SHQUERYRBINFO, A_PtrSize + 8, "Int64")
        if count
        {
            ;// Enable "Empty Recycle Bin" and change the icon to the full bin.
            Tray.Enable("3&")
            TraySetIcon("shell32", "-33", "1")
            ; Tray.Icon("3&", "shell32", "-33")
        }
        else
        {
            ;// Disable "Empty Recycle Bin" and change the icon to the empty bin.
            Tray.Disable("3&")
            TraySetIcon("shell32", "-32", "1")
            ; Tray.Icon("3&", "shell32", "-32")
        }
        A_IconTip := Format("{}`n{}", count, FormatBytes(&bytes))
    }
return
}

FormatBytes(&r_bytes)
{
    ;// Format a number of bytes to a human-readable string.
    static s_symbols := ["B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB"]
    if !r_bytes
        return "0.00 B"
    n := Floor(Log(r_bytes) / Log(1024))
    return Round(r_bytes / 1024 ** n, 2) . " " . s_symbols[n + 1]
}

LoadString(&r_instance, r_id)
{
    ;// https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-loadstringa
    ;// https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-loadstringw
    static s_ptr := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32", "Ptr"), "AStr", "LoadString" . (1 ? "W" : "A"), "Ptr")
    VarSetStrCapacity(&string, 160 << 1)        ,DllCall(s_ptr, "Ptr", r_instance, "UInt", r_id, "Str", string, "Int", 160, "Int") ; V1toV2: if 'string' is NOT a UTF-16 string, use 'string := Buffer(160 << A_IsUnicode)'
    return string
}

SHQueryRecycleBin(r_root, r_SHQUERYRBINFO)
{
    ;// https://docs.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shqueryrecyclebina
    ;// https://docs.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shqueryrecyclebinw
    static s_ptr := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "shell32", "Ptr"), "AStr", "SHQueryRecycleBin" . (1 ? "W" : "A"), "Ptr")
    return DllCall(s_ptr, "Ptr", r_root, "Ptr", r_SHQUERYRBINFO, "Int")
}



