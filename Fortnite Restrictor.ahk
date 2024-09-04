#Persistent
#NoEnv
#Warn, All, Off
#MaxMem
#SingleInstance Force
#NoTrayIcon

global iniFile := "data\fnrestrict.ini"
global passwordKey := "https://github.com/evillurker/FortniteRestrictor"  ; Key for encryption/decryption
if !FileExist(A_ScriptDir "\data")
    FileCreateDir, %A_ScriptDir%\data
if !FileExist(A_ScriptDir "\data\fnrestrict.ico")
    FileInstall, data\fnrestrict.ico, %A_ScriptDir%\data\fnrestrict.ico, 0
if !FileExist(A_ScriptDir "\data\fnrestrict.ini")
    FileInstall, data\fnrestrict.ini, %A_ScriptDir%\data\fnrestrict.ini, 0
; Load or set the default password
IniRead, encryptedPassword, %iniFile%, Settings, Password, NoPassword
if (encryptedPassword = "NoPassword")
{
    encryptedPassword := encryptStr("admin", passwordKey)
    IniWrite, %encryptedPassword%, %iniFile%, Settings, Password
}
if FileExist("data\fnrestrict.ico")
	Menu, tray, Icon, data\fnrestrict.ico, 1, 1
; Load the allowed times from the INI file
allowedTimes := LoadAllowedTimes()

OpenPasswordGui()

; Function to format time ranges
FormatTimeRanges(timeRanges)
{
    output := ""
    for index, range in timeRanges
    {
        if (output != "")
            output .= ", "
        output .= range[1] . "-" . range[2]
    }
    return output
}

; Hotkey to open the GUI
^!o::OpenPasswordGUI()

; Open the password GUI
OpenPasswordGUI()
{
    Gui, 1:New
    Gui, 1:Add, Text, x10 y20, Enter Password:
    Gui, 1:Add, Edit, x120 y15 vPasswordInput Password ; Password input field
    Gui, 1:Add, Button, Default x250 y15 gSubmitPassword, OK
    Gui, 1:Add, Button, x200 y60 gExitApp, Cancel
    Gui, 1:Add, Button, x50 y60 gChangePassword, Change Password
    Gui, 1:Show, w300 h100, Fortnite Restrictor
    return
}

SubmitPassword:
Gui, Submit, NoHide

; Decrypt the password from the INI
storedPassword := decryptStr(encryptedPassword, passwordKey)

if (PasswordInput = storedPassword)
{
    ; Hide the password prompt GUI
    Gui, Hide

    ; Create the main GUI for setting allowed hours
    Gui, 2:New
    Gui, 2:Add, Text,, Set Allowed Hours (Example for specific day: 14:00-15:00, 22:00-23:00):

    ; Define days of the week in order
    days := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    ; Loop through days and create inputs for each
    yPos := 40
    for index, key in days
    {
        formattedTimes := FormatTimeRanges(allowedTimes[key])
        Gui, 2:Add, Text, x10 y%yPos%, %key%:
        Gui, 2:Add, Edit, x120 y%yPos% w400 v%key%Input, %formattedTimes%
        yPos += 30
    }

    Gui, 2:Add, Button, x150 y%yPos% gSaveHours, Save
    Gui, 2:Add, Button, x250 y%yPos% gStopTimer, Stop
    Gui, 2:Add, Button, x350 y%yPos% gExitApp, Exit
    Gui, 2:Show,, Fortnite Restrictor
}
else
{
    MsgBox, 16, Error, Incorrect password. Try again.
}

return

ChangePassword:
Gui, Submit, NoHide
Gui, 4:New
Gui, 4:Add, Text, x10 y10, Enter Current Password:
Gui, 4:Add, Edit, x150 y10 vCurrentPassword Password, ; Current password input field
Gui, 4:Add, Text, x10 y40, Enter New Password:
Gui, 4:Add, Edit, x150 y40 vNewPassword Password, ; New password input field
Gui, 4:Add, Button, Default x150 y70 gSubmitNewPassword, OK
Gui, 4:Add, Button, x10 y70 gCancelChangePassword, Cancel
Gui, 1: Hide
Gui, Show, w300 h110, Change Password
return

SubmitNewPassword:
Gui, 4:Submit, NoHide

; Decrypt the password from the INI
storedPassword := decryptStr(encryptedPassword, passwordKey)

if (CurrentPassword = storedPassword)
{
    ; Check if the new password is the same as the current one
    if (NewPassword = CurrentPassword)
    {
        MsgBox, 16, Error, The new password cannot be the same as the current password. Please choose a different password.
        return  ; Exit the function without saving the password
    }

    ; Encrypt and save the new password
    encryptedPassword := encryptStr(NewPassword, passwordKey)
    IniWrite, %encryptedPassword%, %iniFile%, Settings, Password

    Gui, 4:Destroy
    MsgBox, 64, Password Change, Password changed successfully!
    Gui, 1: Show
}
else
{
    MsgBox, 16, Error, Incorrect current password. Please try again.
}


return

CancelChangePassword:
Gui, 4:Destroy
Gui, 1:Show
return

SaveHours:
Gui, 2:Submit, NoHide
; Save the hours set by the user
for key, value in allowedTimes
{
    GuiControlGet, timeRanges,, %key%Input

    ; Validate the input format
    if (!ValidateTimeRanges(timeRanges))
    {
        MsgBox, 16, Error, Invalid time format for %key%. Please use the format HH:MM-HH:MM.
        return
    }

    allowedTimes[key] := ParseTimeRanges(timeRanges)
}

; Save to INI file
SaveAllowedTimes(allowedTimes)

; Close the GUI after saving
Gui, 2:Destroy
SetTimer, CheckProcesses, 15000 ; Check every minute
MsgBox, 64, Hours Saved, Hours saved! Fortnite and Epic Games are only allowed to run during the specified hours.
return

ValidateTimeRanges(timeRanges)
{
    Loop, Parse, timeRanges, `,
    {
        timeRange := Trim(A_LoopField)
        if (!RegExMatch(timeRange, "^\d{2}:\d{2}-\d{2}:\d{2}$"))
            return false
    }
    return true
}

ParseTimeRanges(timeRanges)
{
    newRanges := []
    Loop, Parse, timeRanges, `,
    {
        timeRange := Trim(A_LoopField)
        if (InStr(timeRange, "-"))
        {
            StringSplit, timesArray, timeRange, -
            newRanges.Push([Trim(timesArray1), Trim(timesArray2)])
        }
    }
    return newRanges
}

CheckProcesses:
FormatTime, CurrentHour,, H:mm
FormatTime, CurrentDay,, WDay

dayOfWeek := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][CurrentDay]

allowed := false
for index, range in allowedTimes[dayOfWeek]
{
    if (IsTimeInRange(CurrentHour, range[1], range[2]))
    {
        allowed := true
        break
    }
}

if (!allowed)
{
    ; Check if the processes are running

    if ProcessExist("FortniteClient-Win64-Shipping.exe")
    {
        ; Prepare the allowed hours message
        allowedHours := FormatTimeRanges(allowedTimes[dayOfWeek])
        MsgBox, 48, Process Closing, Fortnite closing: The allowed hours for today are `n`n%allowedHours%

        ; Close the processes if outside allowed hours
        Process, Close, FortniteClient-Win64-Shipping.exe
    }
}

return

ProcessExist(processName)
{
    Process, Exist, %processName%
    return ErrorLevel
}

return

IsTimeInRange(currentTime, startTime, endTime)
{
    if (endTime == "00:00")
        endTime := "23:59"
    return (currentTime >= startTime && currentTime <= endTime)
}

SaveAllowedTimes(allowedTimes)
{
    global iniFile
    for key, value in allowedTimes
    {
        formattedTimes := FormatTimeRanges(value)
        IniWrite, %formattedTimes%, %iniFile%, AllowedTimes, %key%
    }
}

LoadAllowedTimes()
{
    global iniFile
    defaultTimes := { "Sunday": [["13:00", "16:00"], ["18:00", "20:00"], ["21:00", "23:00"]],"Monday": [["13:00", "16:00"], ["18:00", "20:00"], ["21:00", "23:00"]],"Tuesday": [["13:00", "16:00"], ["18:00", "20:00"], ["21:00", "23:00"]],"Wednesday": [["13:00", "16:00"], ["18:00", "20:00"], ["21:00", "23:00"]],"Thursday": [["13:00", "16:00"], ["18:00", "20:00"], ["21:00", "23:00"]],"Friday": [["09:00", "14:00"], ["17:00", "00:00"]],"Saturday": [["09:00", "14:00"], ["17:00", "00:00"]] }

    loadedTimes := {}
    for key, default in defaultTimes
    {
        defaultTimesFormatted := FormatTimeRanges(default)
        IniRead, times, %iniFile%, AllowedTimes, %key%, %defaultTimesFormatted%
        loadedTimes[key] := ParseTimeRanges(times)
    }
    return loadedTimes
}

StopTimer:
SetTimer, CheckProcesses, Off
MsgBox, 64, Timer Stop, Timer stopped. Processes will not be checked.
return

ExitApp:
ExitApp
return

GuiClose:
ExitApp
return


; Encrypt / Decrypt Password

encryptStr(str="",pass="")
{
If !(enclen:=(strput(str,"utf-16")*2))
    return "Error: Nothing to Encrypt"
If !(passlen:=strput(pass,"utf-8")-1)
    return "Error: No Pass"
enclen:=mod(enclen,4) ? (enclen) : (enclen-2)
Varsetcapacity(encbin,enclen,0)
strput(str,&encbin,enclen/2,"utf-16")
Varsetcapacity(passbin,passlen+=mod((4-mod(passlen,4)),4),0)
strput(pass,&passbin,strlen(pass),"utf-8")
_encryptbin(&encbin,enclen,&passbin,passlen)
return _crypttobase64(&encbin,enclen)
}

decryptStr(str="",pass="")
{
If !((strput(str,"utf-16")*2))
    return "Error: Nothing to Decrypt"
If !((passlen:=strput(pass,"utf-8")-1))
    return "Error: No Pass"
Varsetcapacity(passbin,passlen+=mod((4-mod(passlen,4)),4),0)
strput(pass,&passbin,strlen(pass),"utf-8")
enclen:=_cryptfrombase64(str,encbin)
_decryptbin(&encbin,enclen,&passbin,passlen)
return strget(&encbin,"utf-16")
}

_MCode(mcode)
{
  static e := {1:4, 2:1}, c := (A_PtrSize=8) ? "x64" : "x86"
  if (!regexmatch(mcode, "^([0-9]+),(" c ":|.*?," c ":)([^,]+)", m))
    return
  if (!DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", 0, "uint*", s, "ptr", 0, "ptr", 0))
    return
  p := DllCall("GlobalAlloc", "uint", 0, "ptr", s, "ptr")
  if (c="x64")
    DllCall("VirtualProtect", "ptr", p, "ptr", s, "uint", 0x40, "uint*", op)
  if (DllCall("crypt32\CryptStringToBinary", "str", m3, "uint", 0, "uint", e[m1], "ptr", p, "uint*", s, "ptr", 0, "ptr", 0))
    return p
  DllCall("GlobalFree", "ptr", p)
}

_encryptbin(bin1pointer,bin1len,bin2pointer,bin2len){
  static encrypt := _MCode("2,x86:U1VWV4t0JBCLTCQUuAAAAAABzoPuBIsWAcKJFinCAdAPr8KD6QR164tsJByLfCQYi3QkEItMJBSLH7gAAAAAixYBwjHaiRYx2inCAdAPr8KDxgSD6QR154PHBIPtBHXQuAAAAABfXl1bww==,x64:U1ZJicpJidNMidZMidlIAc64AAAAAEiD7gSLFgHCiRYpwgHQD6/CSIPpBHXpuAAAAABBixhMidZMidmLFgHCMdqJFjHaKcIB0A+vwkiDxgRIg+kEdeVJg8AESYPpBHXbuAAAAABeW8M=") ;reserved
b:=0
Loop % bin1len/4
{
a:=numget(bin1pointer+0,bin1len-A_Index*4,"uint")
numput(a+b,bin1pointer+0,bin1len-A_Index*4,"uint")
b:=(a+b)*a
}
Loop % bin2len/4
{
c:=numget(bin2pointer+0,(A_Index-1)*4,"uint")
b:=0
Loop % bin1len/4
{
a:=numget(bin1pointer+0,(A_Index-1)*4,"uint")
numput((a+b)^c,bin1pointer+0,(A_Index-1)*4,"uint")
b:=(a+b)*a
}
}
}

_decryptbin(bin1pointer,bin1len,bin2pointer,bin2len){
  static decrypt := _MCode("2,x86:U1VWV4tsJByLfCQYAe+D7wSLH7gAAAAAi3QkEItMJBSLFjHaKcKJFgHQD6/Cg8YEg+kEdeuD7QR11LgAAAAAi3QkEItMJBQBzoPuBIsWKcKJFgHQD6/Cg+kEde24AAAAAF9eXVvD,x64:U1ZJicpJidNNAchJg+gEuAAAAABBixhMidZMidmLFjHaKcKJFgHQD6/CSIPGBEiD6QR16UmD6QR140yJ1kyJ2UgBzrgAAAAASIPuBIsWKcKJFgHQD6/CSIPpBHXruAAAAABeW8M=") ;reserved

Loop % bin2len/4
{
c:=numget(bin2pointer+0,bin2len-A_Index*4,"uint")
b:=0
Loop % bin1len/4
{
a:=numget(bin1pointer+0,(A_Index-1)*4,"uint")
numput(a:=(a^c)-b,bin1pointer+0,(A_Index-1)*4,"uint")
b:=(a+b)*a
}
}
b:=0
Loop % bin1len/4
{
a:=numget(bin1pointer+0,bin1len-A_Index*4,"uint")
numput(a:=a-b,bin1pointer+0,bin1len-A_Index*4,"uint")
b:=(a+b)*a
}
}

_crypttobase64(binpointer,binlen)
{
    s:=0
    DllCall("crypt32\CryptBinaryToStringW","ptr",binpointer,"uint",binlen,"uint",1,"ptr",   0,"uint*",s)
    VarSetCapacity(out,s*2,0)
    DllCall("crypt32\CryptBinaryToStringW","ptr",binpointer,"uint",binlen,"uint",1,"ptr",&out,"uint*",s)
    return strget(&out,"utf-16")
}

_cryptfrombase64(string,byref bin)
{
    DllCall("crypt32\CryptStringToBinaryW", "wstr",string,"uint",0,"uint",1,"ptr",0,"uint*",s,"ptr",0,"ptr",0)
    VarSetCapacity(bin,s,0)
    DllCall("crypt32\CryptStringToBinaryW", "wstr",string,"uint",0,"uint",1,"ptr",&bin,"uint*",s,"ptr",0,"ptr",0)
    return s
}