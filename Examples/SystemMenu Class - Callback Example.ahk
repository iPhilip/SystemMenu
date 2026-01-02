; Example demonstrating the use of the Callback property.
; The script shows hows the order of execution of the 'Close' and 'Minimize' menu items
; relative to the same events defined using the Gui.OnEvent method.

#Requires AutoHotkey v2.0
#Include ..\Lib\SystemMenu Class.ahk

MyGui := Gui()
MyGui.Show('w250 h250')
MyGui.OnEvent('Close', (*) => MsgBox('OnEvent method - Closing the window...'))
MyGui.OnEvent('Size', (GuiObj, MinMax, *) => MinMax = -1 ? MsgBox('OnEvent method - the window has been minimized.') : '')

SysMenu := SystemMenu(MyGui)
SysMenu.Insert('Close', '&This &&&& that', ThisThat)
SysMenu.Insert('Close')

SysMenu.Callback['Close'] := Close
SysMenu.Callback['Minimize'] := Minimize

ThisThat(this) => MsgBox('SystemMenu class - The system menu has ' this.Count ' items.')
Close(this)    => MsgBox('SystemMenu class - Closing the window...')
Minimize(this) => MsgBox('SystemMenu class - Minimizing the window...')

MsgBox 'Select the new menu item or minimize/close the window to demonstrate the effect of using the Callback property.'
