; Example demonstrating the use of the AddAlwaysOnTopToSystemMenu function with two GUI windows.

#Requires AutoHotkey v2.0
#Include ..\Lib\AddAlwaysOnTopToSystemMenu.ahk

MyGui1 := Gui(, 'Gui #1')
MyGui2 := Gui('+AlwaysOnTop', 'Gui #2')
MyGui1.Show('w250 h250')
MyGui2.Show('w250 h250')

AddAlwaysOnTopToSystemMenu(MyGui1)
AddAlwaysOnTopToSystemMenu(MyGui2)
MsgBox 'The GUI windows now have an "Always On Top" menu item.`nClick OK or press Enter to restore the system menu of Gui #1 to its default state.', , 0x40000
AddAlwaysOnTopToSystemMenu(MyGui1, true)
MsgBox 'Click OK or press Enter to restore the system menu of Gui #2 to its default state.', , 0x40000
AddAlwaysOnTopToSystemMenu(MyGui2, true)
