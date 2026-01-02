; Example demonstrating the use of the Disable/Enable methods to disable/enable the Size menu item.

#Requires AutoHotkey v2.0
#Include ..\Lib\SystemMenu Class.ahk

MyGui := Gui('+Resize')
MyGui.Show('w250 h250')

SysMenu := SystemMenu(MyGui)
SysMenu.Disable('Size')

MsgBox 'The Size menu item is now disabled.`nThe GUI window cannot be resized.`n`nClick OK or press Enter to re-enable it.'

SysMenu.Enable('Size')
