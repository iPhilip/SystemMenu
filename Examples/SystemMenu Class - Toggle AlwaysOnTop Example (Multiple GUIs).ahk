; Example demonstrating the use of the Insert/Check methods to toggle the AlwaysOnTop property of two GUI windows.

#Requires AutoHotkey v2.0
#Include ..\Lib\SystemMenu Class.ahk

MyGui1 := Gui( , 'Gui #1')
MyGui2 := Gui('+AlwaysOnTop', 'Gui #2')
MyGui1.Show('x100 y100 w250 h250')
MyGui2.Show('x200 y200 w250 h250')

SysMenu1 := SystemMenu(MyGui1)
SysMenu1.Insert('Close', '&Always on top', ToggleAlwaysOnTop)
SysMenu1.Insert('Close')

SysMenu2 := SystemMenu(MyGui2)
SysMenu2.Insert('Close', '&Always on top', ToggleAlwaysOnTop)
SysMenu2.Insert('Close')
SysMenu2.Check('Always on top')
SysMenu2.Show()

ToggleAlwaysOnTop(this) {
   this.ToggleCheck('Always on top')
   WinSetAlwaysOnTop -1, this.hwnd
}
