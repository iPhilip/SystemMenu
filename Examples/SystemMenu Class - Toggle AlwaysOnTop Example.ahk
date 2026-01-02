; Example demonstrating the use of the Insert method to toggle the AlwaysOnTop property of a GUI window.

#Requires AutoHotkey v2.0
#Include ..\Lib\SystemMenu Class.ahk

MyGui := Gui()
MyGui.Show('w250 h250')

SysMenu := SystemMenu(MyGui)
SysMenu.Insert('Close', '&Always on top', ToggleAlwaysOnTop)
SysMenu.Insert('Close')
SysMenu.Show()

ToggleAlwaysOnTop(this) {
   this.ToggleCheck('Always on top')
   WinSetAlwaysOnTop -1, this.hwnd
}
