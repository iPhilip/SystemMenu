; Example demonstrating the use of the AddAlwaysOnTopToSystemMenu function with a GUI window.

#Requires AutoHotkey v2.0
#Include ..\Lib\AddAlwaysOnTopToSystemMenu.ahk

MyGui := Gui()
MyGui.Show('w250 h250')

AddAlwaysOnTopToSystemMenu(MyGui)
MsgBox 'The GUI window now has an "Always On Top" menu item.`nClick OK or press Enter to restore the system menu to its default state.'
AddAlwaysOnTopToSystemMenu(MyGui, true)
