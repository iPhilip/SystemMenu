; Example demonstrating the use of the Clear method.

#Requires AutoHotkey v2.0
#Include ..\Lib\SystemMenu Class.ahk

MyGui := Gui()
MyGui.Show('w250 h250')

SysMenu := SystemMenu(MyGui)
SysMenu.Clear()

MsgBox 'The window now has an empty system menu.`nClick OK or press Enter to restore the system menu to its default state.'

SysMenu.Revert()
