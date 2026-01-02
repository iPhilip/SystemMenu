; Example demonstrating the use of the Rename method to rename standard menu items.

#Requires AutoHotkey v2.0
#Include ..\Lib\SystemMenu Class.ahk

MyGui := Gui()
MyGui.Show('w250 h250')

SysMenu := SystemMenu(MyGui)
SysMenu.Rename('Move', 'Shift')
SysMenu.Rename('Size', 'Resize')
SysMenu.Rename('Close', 'Hide')
SysMenu.Show()
