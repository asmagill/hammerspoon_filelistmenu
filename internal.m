#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <lauxlib.h>

/// hs._asm.filelistmenu.keyModifiers() -> table
/// Function
/// Returns a table containing the current key modifiers being pressed *at this instant*.
///
/// Parameters:
///  None
///
/// Returns:
///  * Returns a table containing boolean values indicating which keyboard modifiers were held down when the menubar item was clicked; The possible keys are:
///     * cmd
///     * alt
///     * shift
///     * ctrl
///     * fn
///
/// Notes:
///  * This is a useful function to check within an action or folder function if you wish to provide multiple possible actions when the user selects a menu item, as it is an instantaneous poll, rather then an event which will be queued until a lua callback can interpret it.
static int checkKeyMods(lua_State* L) {

    NSUInteger theFlags = [NSEvent modifierFlags] ;
    BOOL isCommandKey = (theFlags & NSCommandKeyMask) != 0;
    BOOL isShiftKey = (theFlags & NSShiftKeyMask) != 0;
    BOOL isOptKey = (theFlags & NSAlternateKeyMask) != 0;
    BOOL isCtrlKey = (theFlags & NSControlKeyMask) != 0;
    BOOL isFnKey = (theFlags & NSFunctionKeyMask) != 0;

    lua_newtable(L);

    lua_pushboolean(L, isCommandKey);
    lua_setfield(L, -2, "cmd");

    lua_pushboolean(L, isShiftKey);
    lua_setfield(L, -2, "shift");

    lua_pushboolean(L, isOptKey);
    lua_setfield(L, -2, "alt");

    lua_pushboolean(L, isCtrlKey);
    lua_setfield(L, -2, "ctrl");

    lua_pushboolean(L, isFnKey);
    lua_setfield(L, -2, "fn");

    return 1;
}

/// hs._asm.filelistmenu.mouseButtons() -> table
/// Function
/// Returns a table containing the current mouse buttons being pressed *at this instant*.
///
/// Parameters:
///  None
///
/// Returns:
///  * Returns an array containing indicies starting from 1 up to the highest numbered button currently being pressed where the index is `true` if the button is currently pressed or `false` if it is not.
///  * Special hash tag synonyms for `left` (button 1) and `right` (button 2) are also set to true if these buttons are currently being pressed.
///
/// Notes:
///  * This is a useful function to check within an action or folder function if you wish to provide multiple possible actions when the user selects a menu item, as it is an instantaneous poll, rather then an event which will be queued until a lua callback can interpret it.
static int checkMouseButtons(lua_State* L) {
    NSUInteger theButtons = [NSEvent pressedMouseButtons] ;
    NSUInteger i = 0 ;

    lua_newtable(L);

    while (theButtons != 0) {
        if (theButtons & 0x1) {
            if (i == 0) {
                lua_pushboolean(L, TRUE) ;
                lua_setfield(L, -2, "left") ;
            } else if (i == 1) {
                lua_pushboolean(L, TRUE) ;
                lua_setfield(L, -2, "right") ;
            }

//             lua_pushinteger(L, i + 1) ;
//             lua_pushboolean(L, TRUE) ;
//             lua_settable(L, -3) ;
        }
        lua_pushinteger(L, i + 1) ;
        lua_pushboolean(L, theButtons & 0x1) ;
        lua_settable(L, -3) ;
        i++ ;
        theButtons = theButtons >> 1 ;
    }
    return 1;
}

// Functions for returned object when module loads
static const luaL_Reg nstaskLib[] = {
    {"keyModifiers",    checkKeyMods},
    {"mouseButtons",    checkMouseButtons},
    {NULL,              NULL}
};

int luaopen_hs__asm_filelistmenu_internal(lua_State* L) {
    luaL_newlib(L, nstaskLib);
    return 1;
}
