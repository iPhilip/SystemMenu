#Requires AutoHotkey v2.0

; AddAlwaysOnTopToSystemMenu(hwnd, Remove := false)
;
; Description:
; Adds/Removes an '&Always On Top' menu item followed by a separator above the 'Close' menu item to the system menu of a window.
;
; Author: iPhilip
;
; Parameters:
;   1. hwnd   - handle of a window or an object with the hwnd property.
;   2. Remove - boolean value that determines if the function adds or removes the menu item (and its separator). If omitted, it defaults to false.
;
; Return value:
; The function returns true if the item (and separator) is added to the system menu and false if it's removed.

AddAlwaysOnTopToSystemMenu(hwnd, Remove := false)
{
   static ItemPos  := 7  ; Position of the 'Close' item.
   static ItemName := '&Always On Top'
   
   static IDs  := Map()
   static Wins := Map()
   
   static MIIM_STATE    := 0x00000001
   static MIIM_ID       := 0x00000002
   static MIIM_STRING   := 0x00000040
   static MIIM_FTYPE    := 0x00000100
   
   static MFS_UNCHECKED := 0x00000000
   static MFS_CHECKED   := 0x00000008
   
   static MFT_STRING    := 0x00000000
   static MFT_SEPARATOR := 0x00000800
   
   static WS_EX_TOPMOST := 0x00000008
   static WM_SYSCOMMAND := 0x0112
   static SC_SIZE       := 0xF000
   
   ; Allow hwnd to be an object with the hwnd property, e.g. a Gui object.
   
   if IsObject(hwnd)
      hwnd := hwnd.hwnd
   
   ; If Remove is considered true,
   ;   - Restore the window's original always-on-top state.
   ;   - Unregister the the previously registered callback.
   ;   - Revert the window's system menu to the default state.
   
   if Remove {
      Obj := Wins.Delete(hwnd)
      IDs.Delete(Obj.ID)
      WinSetAlwaysOnTop Obj.IsAlwaysOnTop, hwnd
      OnMessage WM_SYSCOMMAND, Obj.BoundFunc, 0
      return DllCall('User32.dll\GetSystemMenu', 'Ptr', hwnd, 'Int', true, 'Ptr')
   }
   
   ; Get the handle to a copy of the system menu.
   ; If the window doesn't have a system menu (see the Gui '-SysMenu' option), an error is thrown.
   
   hMenu := DllCall('User32.dll\GetSystemMenu', 'Ptr', hwnd, 'Int', false, 'Ptr')
   if !hMenu
      throw Error('The window is missing the system menu.', -1)
   
   ; Get the next ID.
   
   ID := IDs.Count ? Max(IDs*) + 0x0010 : 0x0010
   if ID = SC_SIZE
      throw Error('Exceeded maximum identifier value.', -1)
   IDs[ID] := hMenu
   
   ; Get the window's current always-on-top state.
   
   IsAlwaysOnTop := WinGetExStyle(hwnd) & WS_EX_TOPMOST = WS_EX_TOPMOST
   
   ; Insert the item above the Close menu item.
   
   MENUITEMINFO := Buffer(16 + 8 * A_PtrSize)
   NumPut 'UInt', MENUITEMINFO.Size  ; cbSize
        , 'UInt', MIIM_STATE | MIIM_ID | MIIM_STRING | MIIM_FTYPE  ; fMask
        , 'UInt', MFT_STRING  ; fType
        , 'UInt', IsAlwaysOnTop ? MFS_CHECKED : MFS_UNCHECKED  ; fState
        , 'UInt', ID, MENUITEMINFO, 0  ; wID
   NumPut 'Ptr', StrPtr(ItemName), MENUITEMINFO, 16 + 5 * A_PtrSize  ; dwTypeData
   
   if !DllCall('User32.dll\InsertMenuItemW', 'Ptr', hMenu, 'UInt', ItemPos - 1, 'Int', true, 'Ptr', MENUITEMINFO, 'Int')
      throw OSError('InsertMenuItemW failed.', -1, FormatError(A_LastError))
   
   ; Add a separator above the item.
   
   NumPut 'UInt', MIIM_FTYPE, 'UInt', MFT_SEPARATOR, MENUITEMINFO, 4  ; fMask, fType
   if !DllCall('User32.dll\InsertMenuItemW', 'Ptr', hMenu, 'UInt', ItemPos, 'Int', true, 'Ptr', MENUITEMINFO, 'Int')
      throw OSError('InsertMenuItemW failed.', -1, FormatError(A_LastError))
   
   ; Set the Mask for subsequent calls to ToggleAlwaysOnTop.
   
   NumPut 'UInt', MIIM_STATE, MENUITEMINFO, 4  ; fMask
   
   ; Register a function to monitor when the user chooses a command from the system menu.
   
   OnMessage WM_SYSCOMMAND, BoundFunc := ToggleAlwaysOnTop.Bind(hMenu)
   
   ; Save information that can be used to reset the system menu.
   
   Wins[hwnd] := {ID: ID, IsAlwaysOnTop: IsAlwaysOnTop, BoundFunc: BoundFunc}
   return true
   
   ToggleAlwaysOnTop(hMenu, wParam, lParam, msg, hwnd) {
      Critical
      
      SC := wParam & 0xFFF0
      if !(IDs.Has(SC) && IDs[SC] = hMenu)
         return
      
      ; Toggle the window's always-on-top state.
      
      WinSetAlwaysOnTop -1, hwnd
      
      ; Get the menu item's state.
      
      if !DllCall('User32.dll\GetMenuItemInfoW', 'Ptr', hMenu, 'UInt', SC, 'Int', false, 'Ptr', MENUITEMINFO, 'Int')
         throw OSError('GetMenuItemInfoW failed.', -1, FormatError(A_LastError))
      MenuItemState := NumGet(MENUITEMINFO, 12, 'UInt')  ; fState
      
      ; Toggle the menu item's checked state.
      
      if MenuItemState & MFS_CHECKED
         MenuItemState &= ~MFS_CHECKED
      else
         MenuItemState |= MFS_CHECKED
      
      NumPut 'UInt', MenuItemState, MENUITEMINFO, 12  ; fState
      if !DllCall('User32.dll\SetMenuItemInfoW', 'Ptr', hMenu, 'UInt', SC, 'Int', false, 'Ptr', MENUITEMINFO, 'Int')
         throw OSError('SetMenuItemInfoW failed.', -1, FormatError(A_LastError))
   }
   
   FormatError(ErrorNo) => RegExReplace(OSError(ErrorNo).Message, '^\([x[:xdigit:]]+\) ')
}

/*
typedef struct tagMENUITEMINFOW {
  UINT      cbSize;           4
  UINT      fMask;            4
  UINT      fType;            4
  UINT      fState;           4
  UINT      wID;              A_PtrSize
  HMENU     hSubMenu;         A_PtrSize
  HBITMAP   hbmpChecked;      A_PtrSize
  HBITMAP   hbmpUnchecked;    A_PtrSize
  ULONG_PTR dwItemData;       A_PtrSize
  LPWSTR    dwTypeData;       A_PtrSize
  UINT      cch;              A_PtrSize
  HBITMAP   hbmpItem;         A_PtrSize
} MENUITEMINFOW               16 + 8 * A_PtrSize
