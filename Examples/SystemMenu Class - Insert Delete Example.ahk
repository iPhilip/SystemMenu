; Example demonstrating the use of the Insert/Delete methods to add/delete a menu item.

#Requires AutoHotkey v2.0
#Include ..\Lib\SystemMenu Class.ahk

MyGui := Gui()
MyGui.Show('w250 h250')

SysMenu := SystemMenu(MyGui)
SysMenu.Insert('Close', '&This && that', (*) => )
Pos := SysMenu.Insert('Close')

MsgBox 'The GUI window now has a new menu item.`nClick OK or press Enter to restore the system menu to its default state.'

SysMenu.Delete(Pos--)
SysMenu.Delete(Pos)

; Alternative approach
;
; SysMenu.Revert()
