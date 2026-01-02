; Example demonstrating the use of the Disable/Enable methods to disable/enable the Close menu item.

#Requires AutoHotkey v2.0
#Include ..\Lib\SystemMenu Class.ahk

MyGui := Gui()
MyGui.Show('w250 h250')
MyGui.OnEvent('Close', (*) => (MsgBox('The Gui.OnEvent method can also be used to prevent the GUI window from closing.'), true))

SysMenu := SystemMenu(MyGui)

SysMenu.Disable('Close')

MsgBox 'The Close menu item is now disabled.`nThe GUI window cannot be closed by clicking on the Close button.`n`nClick OK or press Enter to re-enable it.'

SysMenu.Enable('Close')
