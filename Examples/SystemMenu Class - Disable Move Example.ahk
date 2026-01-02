; Example demonstrating the use of the Disable/Revert methods to disable/enable the Move menu item.

#Requires AutoHotkey v2.0
#Include ..\Lib\SystemMenu Class.ahk

MyGui := Gui()
MyGui.Show('w250 h250')

SysMenu := SystemMenu(MyGui)
SysMenu.Disable('Move')

MsgBox 'The Move menu item is now disabled.`nThe GUI window cannot be moved by dragging the title bar.`n`nClick OK or press Enter to reset the system menu.'

SysMenu.Revert()
