; Example demonstrating the use of the Disable/Revert methods to disable/enable the Restore menu item.

#Requires AutoHotkey v2.0
#Include ..\Lib\SystemMenu Class.ahk

MyGui := Gui('+Resize')
MyGui.Show('w250 h250')

MsgBox
MyGui.Maximize()

SysMenu := SystemMenu(MyGui)
SysMenu.Disable('Restore')

MsgBox 'The Restore menu item is now disabled.`nThe GUI window cannot be restored.`n`nClick OK or press Enter to re-enable it.'

SysMenu.Revert()
