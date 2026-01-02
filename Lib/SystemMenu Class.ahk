#Requires AutoHotkey v2.0

; class SystemMenu
;
; A class for modifying a window's system menu.
;
; Author: iPhilip
;
; User Properties:
;
; Count
; Name[Pos]
; String[Pos]
; Callback[MenuItem]
;
; User Methods:
;
; IsEnabled(MenuItem)
; Enable(MenuItem)
; Disable(MenuItem)
;
; Append(MenuItemName?, Callback?)
; Insert(MenuItem, MenuItemName?, Callback?)
; Rename(MenuItem, NewItemName)
; Delete(MenuItem)
;
; Check(MenuItem)
; UnCheck(MenuItem)
; ToggleCheck(MenuItem)
;
; Show()
; Redraw()
; Reset()
; Revert()
; Clear()
;
; The MenuItem parameter can be either an integer representing the one-based position of the item,
; or the name of the menu item as displayed to the left of the tab character (without the & character).
; In other words, the Close menu item ('&Close`tAlt+F4') is simply accessed using the 'Close' string.
; Note that a value of 1 for MenuItem refers to the first menu item while a value of '1' refers to the menu item by the name '1'.
; The maximum number of non-standard menu items is 3,839 ((0xF000 - 1) >> 4).
; Except for portions of error messages, the class is locale-agnostic.
; See the specific property or method below for more details.

class SystemMenu
{
   static SC_SIZE        := 0xF000
   static SC_MOVE        := 0xF010
   static SC_MINIMIZE    := 0xF020
   static SC_MAXIMIZE    := 0xF030
   static SC_CLOSE       := 0xF060
   static SC_RESTORE     := 0xF120
   
   static WS_MAXIMIZEBOX := 0x00010000
   static WS_MINIMIZEBOX := 0x00020000
   static WS_SIZEBOX     := 0x00040000
   static WS_MAXIMIZE    := 0x01000000
   static WS_MINIMIZE    := 0x20000000
   
   static MF_BYCOMMAND   := 0x00000000
   static MF_ENABLED     := 0x00000000
   static MF_STRING      := 0x00000000
   static MF_GRAYED      := 0x00000001
   static MF_DISABLED    := 0x00000002
   static MF_BYPOSITION  := 0x00000400
   static MF_SEPARATOR   := 0x00000800
   
   static MFS_GRAYED     := 0x00000003
   static MFS_CHECKED    := 0x00000008
   static MFT_SEPARATOR  := 0x00000800
   
   static MIIM_STATE     := 0x00000001
   static MIIM_ID        := 0x00000002
   static MIIM_STRING    := 0x00000040
   static MIIM_FTYPE     := 0x00000100
   
   static WM_SYSCOMMAND  := 0x0112
   
   static __New() => this.Prototype.Class := this
   
   __New(hwnd, StringCaseSense := false) {
      this.hwnd  := IsObject(hwnd) ? hwnd.hwnd : hwnd
      this.hMenu := this.GetSystemMenu(false)
      this.Style := WinGetStyle(hwnd) & ~(this.Class.WS_MINIMIZE | this.Class.WS_MAXIMIZE)
      
      this.ItemsByPos := []
      this.ItemsByName := Map()
      this.ItemsByName.CaseSense := this.StringCaseSense := StringCaseSense
      
      Loop this.GetMenuItemCount() {
         ItemID := this.GetMenuItemID(A_Index)
         ItemName := this.Strip(this.GetMenuItemName(A_Index))
         this.ItemsByPos.Push({ID: ItemID, Name: ItemName})
         if ItemID
            this.ItemsByName[ItemName] := ItemID
      }
      
      this.CallbackMap := Map()
      this.BoundFunc := ObjBindMethod(this, 'SysMenuCallback')
      ObjRelease(ObjPtr(this))
   }
   
   __Delete() {
      try this.Reset()
      ObjPtrAddRef(this)
      this.BoundFunc := UnSet
   }
   
   ; ---------------
   ; User Properties
   ; ---------------
   
   ; Gets the number of items in the system menu.
   
   Count => this.ItemsByPos.Length
   
   ; Gets the name of the item specified by its one-based position, e.g. 'Close'.
   
   Name[Pos] => this.ItemsByPos[Pos].Name
   
   ; Gets the full string of the item specified by its one-based position, e.g. '&Close`tAlt+F4'.
   
   String[Pos] => this.GetMenuItemName(Pos)
   
   ; Gets or sets the callback object of the item specified by MenuItem.
   ; For standard system menu items, separators, or if the non-standard menu item's callback was deleted, the return value of the getter is an empty string.
   ; If the value associated with the setter is not a callable object, the existing callback object is deleted.
   
   Callback[MenuItem]
   {
      get {
         if ID := this.GetID(MenuItem)
            if this.CallbackMap.Has(ID)
               return this.CallbackMap[ID]
      }
      
      set {
         if ID := this.GetID(MenuItem) {
            if HasMethod(Value) {
               if !this.CallbackMap.Count
                  OnMessage this.Class.WM_SYSCOMMAND, this.BoundFunc
               this.CallbackMap[ID] := Value
            } else if this.CallbackMap.Has(ID) {
               this.CallbackMap.Delete(ID)
               if !this.CallbackMap.Count
                  OnMessage this.Class.WM_SYSCOMMAND, this.BoundFunc, 0
            }
         }
      }
   }
   
   ; ------------
   ; User Methods
   ; ------------
   
   ; Determines if a menu item is enabled or not.
   ; Except for the Move menu item, the method returns true or false.
   ; If the Move menu item has been disabled, the method returns an empty string.
   ; If there are no errors, the method returns true if the item is enabled and false if it's not.
   
   IsEnabled(MenuItem) {
      
      if !ID := this.GetID(MenuItem)  ; The menu item is a separator.
         return false
      
      Switch {
         Case ID < this.Class.SC_SIZE:  ; Non-standard menu items
            return !(this.GetMenuItemState(ID) & (this.Class.MF_DISABLED | this.Class.MF_GRAYED))
         Case ID = this.Class.SC_SIZE:
            return WinGetStyle(this.hwnd) & this.Class.WS_SIZEBOX = this.Class.WS_SIZEBOX
         Case ID = this.Class.SC_MOVE:
            try return !(this.GetMenuItemState(ID) & (this.Class.MF_DISABLED | this.Class.MF_GRAYED))
         Case ID = this.Class.SC_MINIMIZE:
            return WinGetStyle(this.hwnd) & this.Class.WS_MINIMIZEBOX = this.Class.WS_MINIMIZEBOX
         Case ID = this.Class.SC_MAXIMIZE:
            return WinGetStyle(this.hwnd) & this.Class.WS_MAXIMIZEBOX = this.Class.WS_MAXIMIZEBOX
         Case ID = this.Class.SC_CLOSE:
            return !(this.GetMenuItemState(ID) & (this.Class.MF_DISABLED | this.Class.MF_GRAYED))
         Case ID = this.Class.SC_RESTORE:
            return WinGetMinMax(this.hwnd) ? !(this.GetMenuItemState(ID) & (this.Class.MF_DISABLED | this.Class.MF_GRAYED)) : false
      }
   }
   
   ; Enables a menu item.
   ; The cases for the Move and Restore menu items exist for sake of documentation
   ; as the Move menu item is enabled by default and the Restore menu item is
   ; enabled by default when the window is minimized or maximized and these menu
   ; items cannot be enabled after being disabled.
   ; Use the Revert or the Reset methods to re-enable them.
   ; The Restore menu item is only enabled when the window is minimized or maximized.
   ; If there are no errors, the method retuns true if the item is not a separator and false otherwise.
   
   Enable(MenuItem) {
      
      if !ID := this.GetID(MenuItem)  ; The menu item is a separator.
         return false
      
      Switch {
         Case ID < this.Class.SC_SIZE:  ; Non-standard menu items
            this.EnableMenuItem(ID, this.Class.MF_BYCOMMAND | this.Class.MF_ENABLED)
         Case ID = this.Class.SC_SIZE:
            WinSetStyle('+' this.Class.WS_SIZEBOX, this.hwnd)
         Case ID = this.Class.SC_MOVE:
            try
               this.EnableMenuItem(this.Class.SC_MOVE, this.Class.MF_BYCOMMAND | this.Class.MF_ENABLED)
            catch
               throw Error('The Move menu item cannot be enabled.', -1)
         Case ID = this.Class.SC_MINIMIZE:
            WinSetStyle('+' this.Class.WS_MINIMIZEBOX, this.hwnd)
         Case ID = this.Class.SC_MAXIMIZE:
            WinSetStyle('+' this.Class.WS_MAXIMIZEBOX, this.hwnd)
         Case ID = this.Class.SC_CLOSE:
            this.EnableMenuItem(ID, this.Class.MF_BYCOMMAND | this.Class.MF_ENABLED)
         Case ID = this.Class.SC_RESTORE:
            if WinGetMinMax(this.hwnd)
               try
                  this.EnableMenuItem(ID, this.Class.MF_BYCOMMAND | this.Class.MF_ENABLED)
               catch
                  throw Error('The Restore menu item cannot be enabled.', -1)
      }
      
      return true
   }
   
   ; Disables a menu item.
   ; The Move and Restore menu items cannot be disabled again after being disabled.
   ; Use the Revert or the Reset methods to re-enable these items.
   ; The Restore menu item is only disabled when the window is minimized or maximized.
   ; If there are no errors, the method retuns true.
   
   Disable(MenuItem) {
      
      if !ID := this.GetID(MenuItem)  ; The menu item is a separator.
         return true
      
      Switch {
         Case ID < this.Class.SC_SIZE:  ; Non-standard menu items
            this.EnableMenuItem(ID, this.Class.MF_BYCOMMAND | this.Class.MF_GRAYED)
         Case ID = this.Class.SC_SIZE:
            WinSetStyle('-' this.Class.WS_SIZEBOX, this.hwnd)
         Case ID = this.Class.SC_MOVE:
            try
               this.ForciblyDisableMenuItem(ID)
            catch
               throw Error('The Move menu item is already disabled.', -1)
         Case ID = this.Class.SC_MINIMIZE:
            WinSetStyle('-' this.Class.WS_MINIMIZEBOX, this.hwnd)
         Case ID = this.Class.SC_MAXIMIZE:
            WinSetStyle('-' this.Class.WS_MAXIMIZEBOX, this.hwnd)
         Case ID = this.Class.SC_CLOSE:
            this.EnableMenuItem(ID, this.Class.MF_BYCOMMAND | this.Class.MF_GRAYED)
         Case ID = this.Class.SC_RESTORE:
            if WinGetMinMax(this.hwnd)
               try
                  this.ForciblyDisableMenuItem(ID)
               catch
                  throw Error('The Restore menu item is already disabled.', -1)
      }
      
      return true
   }
   
   ; Appends a menu item or a separator.
   ; If MenuItemName is specified, a menu item is appended. In this case, the Callback parameter must also be specified.
   ; If MenuItemName is not specified, a separator is appended. In this case, the Callback parameter is ignored.
   ; The callback function must accept one parameter: the class instance.
   ; If there are no errors, the method returns true.
   
   Append(MenuItemName?, Callback?) {
      if IsSet(MenuItemName) {
         if !IsSet(Callback)
            throw ValueError('Missing callback function.', -1)
         if !this.CallbackMap.Count
            OnMessage this.Class.WM_SYSCOMMAND, this.BoundFunc
         
         Flags := this.Class.MF_STRING
         ID := this.CallbackMap.Count ? Max(this.CallbackMap*) + 0x0010 : 0x0010
         if ID = this.Class.SC_SIZE
            throw Error('Exceeded maximum identifier value.')
         
         this.CallbackMap[ID] := Callback
         this.ItemsByPos.Push({ID: ID, Name: this.Strip(MenuItemName)})
         this.ItemsByName[MenuItemName] := ID
      } else {
         Flags := this.Class.MF_SEPARATOR
         this.ItemsByPos.Push({ID: 0, Name: ''})
      }
      
      if !DllCall('User32.dll\AppendMenuW', 'Ptr', this.hMenu, 'UInt', Flags, 'UPtr', ID ?? 0, 'WStr', MenuItemName ?? '', 'Int')
         throw OSError('AppendMenuW failed.', -1, this.FormatError(A_LastError))
      
      return true
   }
   
   ; Inserts a new menu item above the specified menu item (MenuItem).
   ; If MenuItemName is not specified, a separator is inserted.
   ; If MenuItemName is specified, a callback function (Callback) must be specified.
   ; The callback function must accept one parameter: the class instance.
   ; If there are no errors, the method returns the position of the specified item.
   
   Insert(MenuItem, MenuItemName?, Callback?) {
      
      Pos := this.GetPos(MenuItem)
      
      MENUITEMINFO := Buffer(16 + 8 * A_PtrSize)
      NumPut 'UInt', MENUITEMINFO.Size, MENUITEMINFO, 0  ; cbSize
      
      if IsSet(MenuItemName) {
         if !IsSet(Callback)
            throw ValueError('Missing callback function.', -1)
         if !this.CallbackMap.Count
            OnMessage this.Class.WM_SYSCOMMAND, this.BoundFunc
         
         ID := this.CallbackMap.Count ? Max(this.CallbackMap*) + 0x0010 : 0x0010
         if ID = this.Class.SC_SIZE
            throw Error('Exceeded maximum identifier value.')
         this.CallbackMap[ID] := Callback
         
         ItemName := this.Strip(MenuItemName)
         this.ItemsByPos.InsertAt(Pos, {ID: ID, Name: ItemName})
         this.ItemsByName[ItemName] := ID
         
         NumPut 'UInt', this.Class.MIIM_ID | this.Class.MIIM_STRING, MENUITEMINFO, 4  ; fMask
         NumPut 'UInt', ID, MENUITEMINFO, 16  ; wID
         NumPut 'Ptr', StrPtr(MenuItemName), MENUITEMINFO, 16 + 5 * A_PtrSize  ; dwTypeData
      } else {
         this.ItemsByPos.InsertAt(Pos, {ID: 0, Name: ''})
         NumPut 'UInt', this.Class.MIIM_FTYPE, 'UInt', this.Class.MFT_SEPARATOR, MENUITEMINFO, 4  ; fMask, fType
      }
      
      if !DllCall('User32.dll\InsertMenuItemW', 'Ptr', this.hMenu, 'UInt', Pos - 1, 'Int', true, 'Ptr', MENUITEMINFO, 'Int')
         throw OSError('InsertMenuItemW failed.', -1, this.FormatError(A_LastError))
      
      return Pos
   }
   
   ; Renames a menu item.
   ; If the menu item is a separator, the method does nothing and returns false.
   ; Otherwise, if there are no errors, the method returns the position of the renamed item.
   ; Except for separators, all menu items (standard and non-standard) can be renamed.
   
   Rename(MenuItem, NewItemName) {
      
      Pos := this.GetPos(MenuItem)
      Item := this.ItemsByPos[Pos]
      
      if !Item.ID  ; The menu item is a separator.
         return false
      
      ItemName := this.Strip(NewItemName)
      this.ItemsByPos[Pos] := {ID: Item.ID, Name: ItemName}
      this.ItemsByName[ItemName] := this.ItemsByName.Delete(Item.Name)
      
      MENUITEMINFO := Buffer(16 + 8 * A_PtrSize)
      NumPut 'UInt', MENUITEMINFO.Size, MENUITEMINFO, 0  ; cbSize
      NumPut 'UInt', this.Class.MIIM_STRING, MENUITEMINFO, 4  ; fMask
      NumPut 'Ptr', StrPtr(NewItemName), MENUITEMINFO, 16 + 5 * A_PtrSize  ; dwTypeData
      
      if !DllCall('User32.dll\SetMenuItemInfoW', 'Ptr', this.hMenu, 'UInt', Pos - 1, 'Int', true, 'Ptr', MENUITEMINFO, 'Int')
         throw OSError('SetMenuItemInfoW failed.', -1, this.FormatError(A_LastError))
      
      return Pos
   }
   
   ; Deletes a menu item.
   ; If there are no errors, the method returns the position of the deleted item.
   
   Delete(MenuItem) {
      
      Pos := this.GetPos(MenuItem)
      ID := this.ItemsByPos[Pos].ID
      
      if ID && this.CallbackMap.Has(ID) {
         this.CallbackMap.Delete(ID)
         if !this.CallbackMap.Count
            OnMessage this.Class.WM_SYSCOMMAND, this.BoundFunc, 0
      }
      
      if ID
         this.ItemsByName.Delete(MenuItem is Integer ? this.ItemsByPos[MenuItem].Name : MenuItem)
      this.ItemsByPos.RemoveAt(Pos)
      
      if !DllCall('User32.dll\DeleteMenu', 'Ptr', this.hMenu, 'UInt', Pos - 1, 'UInt', this.Class.MF_BYPOSITION, 'Int')
         throw OSError('DeleteMenu failed.', -1, this.FormatError(A_LastError))
      
      return Pos
   }
   
   ; Adds a checkmark to a menu item.
   ; If the menu item is a separator and there are no errors, the method does nothing and returns false.
   ; Otherwise, if there are no errors, the method returns true.
   
   Check(MenuItem) {
      
      if !ID := this.GetID(MenuItem)  ; The menu item is a separator.
         return false
      
      MENUITEMINFO := Buffer(16 + 8 * A_PtrSize)
      NumPut 'UInt', MENUITEMINFO.Size, 'UInt', this.Class.MIIM_STATE, MENUITEMINFO, 0  ; cbSize, fMask
      NumPut 'UInt', this.GetMenuItemState(ID) | this.Class.MFS_CHECKED, MENUITEMINFO, 12  ; fState
      
      if !DllCall('User32.dll\SetMenuItemInfoW', 'Ptr', this.hMenu, 'UInt', ID, 'Int', false, 'Ptr', MENUITEMINFO, 'Int')
         throw OSError('SetMenuItemInfoW failed.', -1, this.FormatError(A_LastError))
      
      return true
   }
   
   ; Removes a checkmark from a menu item.
   ; If the menu item is a separator and there are no errors, the method does nothing and returns false.
   ; Otherwise, if there are no errors, the method returns true.
   
   UnCheck(MenuItem) {
      
      if !ID := this.GetID(MenuItem)  ; The menu item is a separator.
         return false
      
      MENUITEMINFO := Buffer(16 + 8 * A_PtrSize)
      NumPut 'UInt', MENUITEMINFO.Size, 'UInt', this.Class.MIIM_STATE, MENUITEMINFO, 0  ; cbSize, fMask
      NumPut 'UInt', this.GetMenuItemState(ID) & ~this.Class.MFS_CHECKED, MENUITEMINFO, 12  ; fState
      
      if !DllCall('User32.dll\SetMenuItemInfoW', 'Ptr', this.hMenu, 'UInt', ID, 'Int', false, 'Ptr', MENUITEMINFO, 'Int')
         throw OSError('SetMenuItemInfoW failed.', -1, this.FormatError(A_LastError))
      
      return true
   }
   
   ; Toggles the default checkmark for a menu item.
   ; If the menu item is a separator and there are no errors, the method does nothing and returns false.
   ; Otherwise, if there are no errors, the method returns true.
   
   ToggleCheck(MenuItem) {
      
      if !ID := this.GetID(MenuItem)  ; The menu item is a separator.
         return false
      
      State := this.GetMenuItemState(ID)
      if State & this.Class.MFS_CHECKED
         State &= ~this.Class.MFS_CHECKED
      else
         State |= this.Class.MFS_CHECKED
      
      MENUITEMINFO := Buffer(16 + 8 * A_PtrSize)
      NumPut 'UInt', MENUITEMINFO.Size, 'UInt', this.Class.MIIM_STATE, MENUITEMINFO, 0  ; cbSize, fMask
      NumPut 'UInt', State, MENUITEMINFO, 12  ; fState
      
      if !DllCall('User32.dll\SetMenuItemInfoW', 'Ptr', this.hMenu, 'UInt', ID, 'Int', false, 'Ptr', MENUITEMINFO, 'Int')
         throw OSError('SetMenuItemInfoW failed.', -1, this.FormatError(A_LastError))
      
      return true
   }
   
   ; Show the system menu.
   ; The method does not return until the menu is manually closed by selecting an item or pressing the Escape key.
   ; If there are no errors, the method returns an empty string.
   ;
   ; Note: This method could be implemented using the TrackPopupMenu WinAPI fundtion but the state of the
   ; system menu items shown using that function does not match their actual state.
   ; It seems easier to simulate the global hotkey (Alt+Space).
   ; Reference: https://stackoverflow.com/questions/21691352/system-menu-shown-by-trackpopupmenu-does-not-matches-the-window-state
   
   Show() {
      WinActivate this.hwnd
      Send '!{Space}'
   }
   
   ; Redraws the system memu.
   ; If the system menu is modified, this method can be called to draw the changed menu.
   ; If there is no error, the method returns an empty string.
   
   Redraw() {
      if !DllCall('User32.dll\DrawMenuBar', 'Ptr', this.hwnd, 'Int')
         throw OSError('DrawMenuBar failed.', -1, this.FormatError(A_LastError))
   }
   
   ; Resets the system menu back to the default state.
   ; If there are no errors, the method returns an empty string.
   
   Reset() {
      if !WinExist(this.hwnd)
         throw Error("The window doesn't exist.", -1)
      Switch WinGetMinMax()
      {
         Case 0:
            WinSetStyle(this.Style)
         Case 1:
            WinSetStyle(this.Style | this.Class.WS_MAXIMIZE)
         Case -1:
            WinSetStyle(this.Style | this.Class.WS_MINIMIZE)
      }
      this.Revert()
   }
   
   ; Resets the system menu back to the default state without resetting the menu item styles.
   ; If there are no errors, the method returns an empty string.
   
   Revert() {
      this.GetSystemMenu(true)
      this.hMenu := this.GetSystemMenu(false)
      
      this.ItemsByPos.Lenth := 0
      this.ItemsByName.Clear()
      
      Loop this.GetMenuItemCount() {
         ItemID := this.GetMenuItemID(A_Index)
         ItemName := this.Strip(this.GetMenuItemName(A_Index))
         this.ItemsByPos.Push({ID: ItemID, Name: ItemName})
         if ItemID
            this.ItemsByName[ItemName] := ItemID
      }
      
      if this.CallbackMap.Count {
         this.CallbackMap.Clear()
         OnMessage this.Class.WM_SYSCOMMAND, this.BoundFunc, 0
      }
   }
   
   ; Clears the system menu, including non-standard items.
   ; The deafult system menu can be restored using the Reset method.
   ; If there are no errors, the method returns an empty string.
   
   Clear() {
      Loop this.ItemsByPos.Length
         if !DllCall('User32.dll\DeleteMenu', 'Ptr', this.hMenu, 'UInt', 0, 'UInt', this.Class.MF_BYPOSITION, 'Int')
            throw OSError('DeleteMenu failed.', -1, this.FormatError(A_LastError))
      
      this.ItemsByPos.Lenth := 0
      this.ItemsByName.Clear()
      
      if this.CallbackMap.Count {
         this.CallbackMap.Clear()
         OnMessage this.Class.WM_SYSCOMMAND, this.BoundFunc, 0
      }
   }
   
   ; --------------
   ; Helper Methods
   ; --------------
   
   ; Class callback
   
   SysMenuCallback(wParam, lParam, msg, hwnd) {
      Critical
      if hwnd = this.hwnd {
         ID := wParam & 0xFFF0
         if this.CallbackMap.Has(ID)
            this.CallbackMap[ID].Call(this)
      }
   }
   
   ; Gets the ID of a menu item. The ID of separators is zero.
   ; Throws a ValueError if the menu item is invalid.
   
   GetID(MenuItem) {
      if MenuItem is Integer {
         try ID := this.ItemsByPos[MenuItem].ID
      } else if MenuItem = ''
         throw ValueError('Invalid menu item.', -2, 'Empty string')
      else
         try ID := this.ItemsByName[MenuItem]
      if !IsSet(ID)
         throw ValueError('Invalid menu item.', -2, MenuItem)
      return ID
   }
   
   ; Gets the one-based position of the menu item.
   ; Throws a ValueError if the menu item is invalid.
   
   GetPos(MenuItem) {
      if MenuItem is Integer {
         if this.ItemsByPos.Has(MenuItem)
            Pos := MenuItem
      } else if MenuItem = ''
         throw ValueError('Invalid menu item.', -2, 'Empty string')
      else {
         for Item in this.ItemsByPos {
            if this.StringCaseSense && Item.Name == MenuItem
            || !this.StringCaseSense && Item.Name = MenuItem {
               Pos := A_Index
               break
            }
         }
      }
      if !IsSet(Pos)
         throw ValueError('Invalid menu item.', -2, MenuItem)
      return Pos
   }
   
   ; Gets the menu handle (Revert = false) or resets the window menu back to the default state (Revert = true).
   ; If Revert is false and the window is missing the system menu, an error is thrown.
   ; If Revert is true, the current window menu is destroyed.
   ; If there are no errors, the method returns a handle to the copy of the window menu when Revert is false or zero otherwise.
   
   GetSystemMenu(Revert) {
      hMenu := DllCall('User32.dll\GetSystemMenu', 'Ptr', this.hwnd, 'Int', Revert, 'Ptr')
      if !Revert && !hMenu
         throw Error('The window is missing the system menu.', -2)
      return hMenu
   }
   
   ; Gets the number of items in the menu.
   
   GetMenuItemCount() {
      Count := DllCall('User32.dll\GetMenuItemCount', 'Ptr', this.hMenu, 'Int')
      if Count = -1
         throw OSError('GetMenuItemCount failed.', -2, this.FormatError(A_LastError))
      return Count
   }
   
   ; Gets the state of the menu item. See the refeence below for possible values of the returned value.
   ; Reference: https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-menuiteminfow
   
   GetMenuItemState(ID) {
      MENUITEMINFO := Buffer(16 + 8 * A_PtrSize)
      NumPut 'UInt', MENUITEMINFO.Size, 'UInt', this.Class.MIIM_STATE, MENUITEMINFO, 0  ; cbSize, fMask
      this.GetMenuItemInfo(ID, MENUITEMINFO, false)
      return NumGet(MENUITEMINFO, 12, 'UInt')  ; fState
   }
   
   ; Gets the ID of the menu item.
   
   GetMenuItemID(Pos) {
      MENUITEMINFO := Buffer(16 + 8 * A_PtrSize)
      NumPut 'UInt', MENUITEMINFO.Size, 'UInt', this.Class.MIIM_ID, MENUITEMINFO, 0  ; cbSize, fMask
      this.GetMenuItemInfo(Pos, MENUITEMINFO, true)
      return NumGet(MENUITEMINFO, 16, 'UInt')  ; wID
   }
   
   ; Gets the name of the menu item.
   
   GetMenuItemName(Pos) {
      MENUITEMINFO := Buffer(16 + 8 * A_PtrSize)
      NumPut 'UInt', MENUITEMINFO.Size, 'UInt', this.Class.MIIM_STRING, MENUITEMINFO, 0  ; cbSize, fMask
      NumPut 'Ptr', 0, MENUITEMINFO, 16 + 5 * A_PtrSize  ; dwTypeData
      this.GetMenuItemInfo(Pos, MENUITEMINFO, true)
      NoChars := NumGet(MENUITEMINFO, 16 + 6 * A_PtrSize, 'UInt')  ; cch
      NameBuffer := Buffer((NoChars + 1) * 2)
      NumPut 'Ptr', NameBuffer.Ptr, 'UInt', NoChars + 1, MENUITEMINFO, 16 + 5 * A_PtrSize  ; dwTypeData, cch
      this.GetMenuItemInfo(Pos, MENUITEMINFO, true)
      return StrGet(NameBuffer, NoChars, 'UTF-16')
   }
   
   ; Method common to the GetMenuItemCount, GetMenuItemState, and GetMenuItemName methods.
   
   GetMenuItemInfo(Command, MENUITEMINFO, ByPosition) {
      if !DllCall('User32.dll\GetMenuItemInfoW', 'Ptr', this.hMenu, 'UInt', Command - ByPosition, 'Int', ByPosition, 'Ptr', MENUITEMINFO, 'Int')
         throw OSError('GetMenuItemInfoW failed.', -2, this.FormatError(A_LastError))
   }
   
   ; Enables/disables a menu item, depending on the Flags parameter.
   
   EnableMenuItem(Command, Flags) {
      PrevState := DllCall('User32.dll\EnableMenuItem', 'Ptr', this.hMenu, 'UInt', Command, 'UInt', Flags, 'Int')
      if PrevState = -1
         throw ValueError('The menu item does not exist.', -2, Format('0x{:04X}', Command))
      return PrevState
   }
   
   ; Forcibly disables of a menu item. Used when EnableMenuItem with the MF_GRAYED flag doesn't work.
   ; Menu items disabled using this method cannot be enabled using EnableMenuItem.
   ; Use the Revert or the Reset methods to re-enable them.
   ; Reference: https://stackoverflow.com/a/2602709
   
   ForciblyDisableMenuItem(ID) {
      MENUITEMINFO := Buffer(16 + 8 * A_PtrSize)
      NumPut 'UInt', MENUITEMINFO.Size, 'UInt', this.Class.MIIM_STATE | this.Class.MIIM_ID, MENUITEMINFO, 0  ; cbSize, fMask
      NumPut 'UInt', this.GetMenuItemState(ID) | this.Class.MFS_GRAYED, 'UInt', 0, MENUITEMINFO, 12  ; fState, wID
      
      if !DllCall('User32.dll\SetMenuItemInfoW', 'Ptr', this.hMenu, 'UInt', ID, 'Int', false, 'Ptr', MENUITEMINFO, 'Int')
         throw OSError('SetMenuItemInfoW failed.', -2, this.FormatError(A_LastError))
   }
   
   ; Strips ItemName so that menu items can be more easily referenced by the user.
   ; The method first removes the string following the tab character (including the tab character), then strips any single '&' occurrences, and finally changes any '&&' occurrences to '&'.
   ; For example, the string '&Close && Exit`tAlt+F4' is reduced to 'Close & Exit'.
   
   Strip(ItemName) => RegExReplace(RegExReplace(RegExReplace(ItemName, '(.*?)(\t.*)*', '$1'), '(?<!&)&([^&])', '$1'), '&\K&')
   
   ; Formats the error mesage by removing the error number in paranthesis, including the parentheses and the space character.
   
   FormatError(ErrorNo) => RegExReplace(OSError(ErrorNo).Message, '^\([x[:xdigit:]]+\) ')
}
