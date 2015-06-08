#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <lauxlib.h>

/// hs._asm.filelistmenu.keyModifiers() -> table
/// Function
/// Returns a table containing the current key modifiers being pressed *at this instant*.  This makes it a useful function to check within an action or folder function if you wish to provide multiple possible actions when the user selects a menu item.
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

// Functions for returned object when module loads
static const luaL_Reg nstaskLib[] = {
    {"keyModifiers",    checkKeyMods},
    {NULL,              NULL}
};

int luaopen_hs__asm_filelistmenu_internal(lua_State* L) {
    luaL_newlib(L, nstaskLib);
    return 1;
}
