; Example demonstrating the use of the Name property and the IsEnabled method to show which menu item is enabled.

#Requires AutoHotkey v2.0
#Include ..\Lib\SystemMenu Class.ahk

MyGui := Gui()
MyGui.Show('w200 h200')

SysMenu := SystemMenu(MyGui)

List := ''
Loop SysMenu.Count {
   Name := SysMenu.Name[A_Index]
   List .= A_Index '. ' (Name = '' ? '<Separator>' : Name) ' is' (SysMenu.IsEnabled(A_Index) ? '' : ' not') ' enabled.`n'
}
MsgBox List
