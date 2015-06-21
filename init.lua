
--- === hs._asm.filelistmenu ===
---
--- This module allows the easy creation of drop-down menubar items which contain file lists that match specified criteria.  The default settings make it trivial to create an Application launcher menu, but more complex menus are also possible.  The match criteria specified is also used to generate pathwatcher processes which keep the menu current.

--local module = require("hs._asm.filelistmenu.internal")
local module = {}

-- Need to add methods for adjusting status menu.  modify mods for status menu?

-- Technically not needed in hammerspoon, but good practice anyways
local pathwatcher = require "hs.pathwatcher"
local luafs       = require "hs.fs"
local menubar     = require "hs.menubar"
local application = require "hs.application"
local eventtap    = require "hs.eventtap"

-- private variables and methods -----------------------------------------

local l_generateAppList -- because this function is recursive, we have to pre-declare it to keep it local
l_generateAppList = function(self, startDir, expression, depth)
    local startDir = startDir or self.root
    local expression = expression or self.matchCriteria
    local depth = depth or 1
    local list = {}

    if depth > self.maxDepth then
        if self.warnings then print("Maximum search depth of "..self.maxDepth.." reached for menu "..self.label.." at "..startDir) end
    else
-- get files at this level -- we want a label and a path
        for name in luafs.dir(startDir) do
            local label, accept
            if type(expression) == "string" then
                label = name:match(expression)
            elseif type(expression) == "function" then
                accept, label = expression(name, startDir, "file")
                if not accept then label = nil end
            end
            if label then
                list[#list+1] = { title = label, fn = function() self.template(startDir.."/"..name) end }
            end
        end

        if self.subFolderBehavior ~= 0 then
-- get sub-dirs at this level -- we want a label and a table -- recursion!
            for name in luafs.dir(startDir) do
                if not (name == "." or name == "..") and luafs.attributes(startDir.."/"..name, "mode") == "directory" then
                    local label, accept
                    if type(expression) == "string" then
                        if not name:match(expression) then
                            accept = true
                            label = name
                        else
                            accept = false
                        end
                    elseif type(expression) == "function" then
                        accept, label = expression(name, startDir, "directory")
                        if accept and label == nil then label = name end
                    end
                    if accept then
                        local subDirs = l_generateAppList(self, startDir.."/"..name, expression, depth + 1)
                        if  next(subDirs) or not self.pruneEmpty then
                            if next(subDirs) then
                                list[#list+1] = { title = label, menu = subDirs, fn = function() self.folderTemplate(startDir.."/"..name) end }
                            else
                                list[#list+1] = { title = label, fn = function() self.folderTemplate(startDir.."/"..name) end }
                            end
                        end
                    end
                end
            end
        end
    end
    return list
end

local l_tableSortSubFolders
l_tableSortSubFolders = function(theTable, Behavior)
    table.sort(theTable, function(c,d)
        if (Behavior % 2 == 0) or (c.menu and d.menu) or not (c.menu or d.menu) then -- == 0 or 2 (ignored or mixed)
            return string.lower(c.title) < string.lower(d.title)
        else
            if Behavior == 1 then                                 -- == 1 (before)
                return c.menu and true
            else                                                  -- == 3 (after)
                return d.menu and true
            end
        end
    end)
    for _,v in ipairs(theTable) do
        if v.menu then l_tableSortSubFolders(v.menu, Behavior) end
    end
end


local l_sortMenuItems = function(self)
    if self.menuListRawData then
        l_tableSortSubFolders(self.menuListRawData, self.subFolderBehavior)
    end
end

local l_populateMenu = function(self)
    if self.menuUserdata then
        if type(self.root) == "string" then
            self.menuListRawData = l_generateAppList(self)
        elseif type(self.root) == "table" then
            self.menuListRawData = {}
            for i,v in pairs(self.root) do
                table.insert(self.menuListRawData, { title = i, menu = l_generateAppList(self, v), fn = function() self.folderTemplate(v) end })
            end
        else
            if self.warnings then print("Menu root for "..self.label.." must be a string or a table of strings.") end
        end
        l_sortMenuItems(self)
        self.menuLastUpdated = os.date()
    end
    return self
end

local l_updateMenuView = function(self)
    if self.menuUserdata then
        if self.menuView == 0 and self.icon then
            if self.menuUserdata:setIcon(self.icon) then
                self.menuUserdata:setTitle(nil)
            else
                self.menuUserdata:setTitle(self.label)
                self.menuUserdata:setIcon(nil)
            end
        else
            self.menuUserdata:setIcon(nil)
            self.menuUserdata:setTitle(self.label)
            if self.menuView == 2 and self.icon then
                self.menuUserdata:setIcon(self.icon)
            end
        end
    end
end

--- hs._asm.filelistmenu:showForMenu([item]) -> item
--- Method
--- Sets or retrieves how the menu appears in the menu bar -- as an icon, a label, or both.  Default is 0.
---
--- Parameters:
---  * `item` - optional argument to set the menu display style to icon, label, or both.  Internally this is a number, but you can specify it as a string: 0 == "icon", 1 == "label", 2 == "both"
---
--- Returns:
---  * The current (or changed) setting as a number from 0 to 2.
---
--- Notes:
---  * If the icon is not set or is un-renderable, then the label will be displayed even if this is set icon only (0).
local l_menuViewEval = function(self, x)
    if type(x) ~= "nil" then
        local y = tonumber(x) or 0
        if type(x) == "string" then
            if string.lower(x) == "icon"  then y = 0 end
            if string.lower(x) == "label" then y = 1 end
            if string.lower(x) == "both"  then y = 2 end
        end
        self.menuView = y
        l_updateMenuView(self)
    end
    return self.menuView
end

--- hs._asm.filelistmenu:subFolders([item]) -> item
--- Method
--- Sets or retrieves how the sub folders are sorted in the menu.  Default is 0.
---
--- Parameters:
---  * `item` - optional argument specify how subfolders are to be sorted within the menu list results.  Internally this is a number, but you can specify it as a string: 0 == "ignore", 1 == "before", 2 == "mixed", 3 == "after"
---
--- Returns:
---  * The current (or changed) setting as a number from 0 to 3.
---
--- Notes:
---  * If subfolders are ignored, then they are not examined for potential menu list items.
---  * Invalidates the menu cache if you change to or from Ignore (0), so a repopulation of the menu will take place next time the menu is clicked on.
local l_subFolderEval = function(self, x)
    if type(x) ~= "nil" then
        local y = tonumber(x) or 0
        if type(x) == "string" then
            if string.lower(x) == "ignore" then y = 0 end
            if string.lower(x) == "before" then y = 1 end
            if string.lower(x) == "mixed"  then y = 2 end
            if string.lower(x) == "after"  then y = 3 end
        end
        local populateNeeded = (y == 0) or (self.subFolderBehavior == 0)
        self.subFolderBehavior = y
        if populateNeeded then
            self.menuListRawData = nil
        else
            l_sortMenuItems(self)
        end
    end
    return self.subFolderBehavior
end

local l_doFileListMenu = function(self, mods)
    local showControlMenu = next(self.controlMenuMods) and true or false
    for i,v in pairs(mods) do if v and not self.controlMenuMods[i] then showControlMenu = false end end
    for i,v in pairs(self.controlMenuMods) do if v and not mods[i] then showControlMenu = false end end
    if not showControlMenu and self.rightMouseControlMenu then
        showControlMenu = eventtap.checkMouseButtons()["right"]
    end

    if showControlMenu then
        local optTable = {
            { title = self.label.." fileListMenu" },
            { title = "-" },
            { title = "Sub Directories - Ignore",  checked = ( self.subFolderBehavior == 0 ), fn = function() l_subFolderEval(self, 0) end },
            { title = "Sub Directories - Before",  checked = ( self.subFolderBehavior == 1 ), fn = function() l_subFolderEval(self, 1) end },
            { title = "Sub Directories - Mixed",   checked = ( self.subFolderBehavior == 2 ), fn = function() l_subFolderEval(self, 2) end },
            { title = "Sub Directories - After",   checked = ( self.subFolderBehavior == 3 ), fn = function() l_subFolderEval(self, 3) end },
            { title = "Prune Empty Directories",   checked = ( self.pruneEmpty ), fn = function() self.pruneEmpty = not self.pruneEmpty ; self.menuListRawData = nil ; end },
            { title = "-" },
            { title = "Show Icon",                 checked = ( self.menuView == 0 ),          fn = function() l_menuViewEval(self, 0) end  },
            { title = "Show Label",                checked = ( self.menuView == 1 ),          fn = function() l_menuViewEval(self, 1) end  },
            { title = "Show Both",                 checked = ( self.menuView == 2 ),          fn = function() l_menuViewEval(self, 2) end  },
            { title = "-" },
            { title = "Repopulate Now", fn = function() l_populateMenu(self) end },
            { title = "-" },
            { title = "List generated: "..self.menuLastUpdated, disabled = true },
            { title = "Last change seen: "..self.lastChangeSeen, disabled = true },
            { title = "-" },
            { title = "Remove Menu", fn = function() self:deactivate() end  },
        }
        if type(self.root) == "string" then
            table.insert(optTable, 2,
                { title = "Open "..self.root.." in Finder", fn = function() os.execute([[open -a Finder "]]..self.root..[["]]) end }
            )
        end
        return optTable
    else
        if not self.menuListRawData then l_populateMenu(self) end
        return self.menuListRawData
    end
end

local l_changeWatcher = function(self, paths)
    local doUpdate = false
    local name, path
    for _, v in pairs(paths) do
        name = string.sub(v,string.match(v, '^.*()/')+1)
        path = string.sub(v, 1, string.match(v, '^.*()/')-1)
        if type(self.matchCriteria) == "string" then
            if name:match(self.matchCriteria) then
                doUpdate = true
                break
            end
        elseif type(self.matchCriteria) == "function" then
            local accept, _ = self.matchCriteria(name, path, "update")
            if accept then
                doUpdate = true
                break
            end
        end
    end
    if doUpdate then
        self.lastChangeSeen = os.date()
        self.menuListRawData = nil        -- only rebuild when they actually look at it
        if self.warnings then print("Menu "..self.label.." Updated: "..name) end
    end
end

--- hs._asm.filelistmenu:deactivate() -> filelistmenu
--- Method
--- Removes the filelist menu from the menu bar, cancels the associated pathwatchers and clears the menu data from memory.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `filelistmenu` - returns the file list menu object.
---
--- Notes:
---  * The menu definition is not deleted, just it's cached data.  You could bring the menu back by issuing `savedMenu:activate()`.
local l_deactivateMenu = function(self)
    if self.menuUserdata then
        if type(self.watcher) == "table" then
            for _,v in ipairs(self.watcher) do v:stop() end
        else
            self.watcher:stop()
        end
        self.menuUserdata:delete()
    end
    self.watcher = nil
    self.menuListRawData = nil
    self.menuUserdata = nil
    return self
end

--- hs._asm.filelistmenu:activate() -> filelistmenu
--- Method
--- Puts the menu into the menubar and activates the pathwatcher(s) to determine when to update the menu.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `filelistmenu` - returns the file list menu object.
local l_activateMenu = function(self)
    if not self.menuUserdata then
        self.menuUserdata = menubar.new()
        if type(self.root) == "string" then
            self.watcher = pathwatcher.new(self.root, function(paths) l_changeWatcher(self, paths) end):start()
        elseif type(self.root) == "table" then
            self.watcher = {}
            for i,v in pairs(self.root) do
                table.insert(self.watcher, pathwatcher.new(v, function(paths) l_changeWatcher(self, paths) end):start())
            end
        else
            if self.warnings then print("Menu root for "..self.label.." must be a string or a table of strings.") end
        end
        l_updateMenuView(self)
        self.menuUserdata:setMenu(function(mods) return l_doFileListMenu(self, mods) end)
    end
    return self
end

local mt_fileListMenu = {
    __index = {
-- described above
        activate       = l_activateMenu,
-- described above
        deactivate     = l_deactivateMenu,
-- described above
        showForMenu    = l_menuViewEval,
-- described above
        subFolders     = l_subFolderEval,
--- hs._asm.filelistmenu:menuIcon([icon]) -> icon
--- Method
--- Sets or retrieves the menu's icon.  If the icon is changed, and the menu has been activated, then the change goes into effect immediately.
---
--- Parameters:
---  * `icon` - optional argument which specifies the icon's path, if it is a file, or defines the icon as an ASCII Art drawing.  See `hs.drawing.image` for more information.
---
--- Returns:
---  * The current (or changed) icon data.
---
--- Notes:
---  * If the file does not exist or the ASCII art is un-renderable, then the label is used instead.
        menuIcon       = function(self, x)
                            if type(x) == "string" then
                                self.icon = tostring(x)
                                l_updateMenuView(self)
                            end
                            return self.icon
                        end,
--- hs._asm.filelistmenu:menuLabel([label]) -> label
--- Method
--- Sets or retrieves the menu's label.  If the label is changed, and the menu has been activated, then the change goes into effect immediately.
---
--- Parameters:
---  * `label` - optional argument which specifies the menu's label
---
--- Returns:
---  * The current (or changed) label.
        menuLabel      = function(self, x)
                            if type(x) ~= "nil" then
                                self.label = tostring(x)
                                l_updateMenuView(self)
                            end
                            return self.label
                        end,
--- hs._asm.filelistmenu:subFolderDepth([depth]) -> depth
--- Method
--- Sets or retrieves the menu's label.
---
--- Parameters:
---  * `depth` - optional argument which specifies how deep the module should search for items which match the specified criteria.  Default is 10.
---
--- Returns:
---  * The current (or changed) depth.
---
--- Notes:
---  * Invalidates the menu cache, so a repopulation of the menu will take place next time the menu is clicked on.
        subFolderDepth = function(self, x)
                            if type(x) == "number" then
                                self.maxDepth = x
                                self.menuListRawData = nil
                            end
                            return self.maxDepth
                        end,
--- hs._asm.filelistmenu:showWarnings([bool]) -> bool
--- Method
--- Sets or retrieves whether or not warnings are printed to the Hammerspoon console.  Default is false.
---
--- Parameters:
---  * `bool` - optional argument which turns warning on or off.
---
--- Returns:
---  * The current (or changed) value.
---
--- Notes:
---  * Warnings are issued when the max search depth is reached and when changed files are detected.  These are not problems per se, though you may want to tweak some of your settings, but it can get annoying if you use the console a lot.
        showWarnings   = function(self, x)
                            if type(x) == "boolean" then
                                self.warnings = x
                            end
                            return self.warnings
                        end,
--- hs._asm.filelistmenu:controlMenu([mods]) -> mods
--- Method
--- Sets or retrieves the modifiers which allow selecting a control menu variant which allows changing sort options, etc.  Default is { ctrl=true }.
---
--- Parameters:
---  * `mods` - optional argument which is a table containing the as keys to non-false values which represent the modifier keys which can be held down while clicking on the drop-down menu to display a control menu for modifying the menu's appearance.  Set to {} (the empty table) to disable access to the control menu.  The possible keys are:
---     * cmd
---     * alt
---     * shift
---     * ctrl
---     * fn
---
--- Returns:
---  * The current (or changed) value.
        controlMenu    = function(self, x)
                            if type(x) == "table" then
                                self.controlMenuMods = x
                            end
                            return self.controlMenuMods
                        end,
--- hs._asm.filelistmenu:rightButtonSupport([boolean]) -> boolean
--- Method
--- Sets or retrieves the flag which whether or not right clicking on a menubar menu item will select the control menu variant which allows changing sort options, etc.  Default is `true`.
---
--- Parameters:
---  * Optional boolean value which sets the state of this flag
---
--- Returns:
---  * The current (or changed) value.
        rightButtonSupport = function(self, x)
                            if type(x) == "boolean" then
                                self.rightMouseControlMenu = x
                            end
                            return self.rightMouseControlMenu
                        end,
--- hs._asm.filelistmenu:pruneEmptyDirs([bool]) -> bool
--- Method
--- Sets or retrieves whether or not empty directories are pruned from the menu list.  Default is true.
---
--- Parameters:
---  * `bool` - optional argument which turns pruning on or off.
---
--- Returns:
---  * The current (or changed) value.
---
--- Notes:
---  * This determines if subdirectories are examined during the Directory pass of the population process.  See `hs._asm.filelistmenu:populate()` for more information on this process.
        pruneEmptyDirs = function(self, x)
                            if type(x) ~= "nil" then
                                self.pruneEmpty = x
                            end
                            return self.pruneEmpty
                        end,
--- hs._asm.filelistmenu:actionFunction([function]) -> function
--- Method
--- Sets or retrieves the function which specifies what action to take when an item is selected in the menu.  The default is a function which takes the path of the item selected and uses it as a parameter to `hs.application.launchOrFocus()`.
---
--- Parameters:
---  * `function` - optional argument defines a function which takes one argument and is invoked when the user selects an item from the menu.  The argument to the function is the path of the file which the menu item represents.
---
--- Returns:
---  * The current (or changed) function.
        actionFunction = function(self, x)
                            if type(x) == "function" then
                                self.template = x
                            end
                            return self.template
                        end,
--- hs._asm.filelistmenu:folderFunction([function]) -> function
--- Method
--- Sets or retrieves the function which specifies what action to take when a folder is selected in the menu.  The default is a function which takes the path of the fodler selected and opens it in the Finder.
---
--- Parameters:
---  * `function` - optional argument defines a function which takes one argument and is invoked when the user selects a folder from the menu.  The argument to the function is the path of the folder which the menu item represents.
---
--- Returns:
---  * The current (or changed) function.
---
--- Notes:
---  * A menu item is considered a "folder" if it was detected during the "Directory" pass of the population process (see `hs._asm.filelistmenu:populate()` for more information).  This item may or may not actually have sub items (i.e. be a sub-menu) in the menu itself, depending upon your match criteria and the prune settings.
        folderFunction = function(self, x)
                            if type(x) == "function" then
                                self.folderTemplate = x
                            end
                            return self.folderTemplate
                        end,
--- hs._asm.filelistmenu:rootDirectory(root) -> string|table
--- Method
--- Sets or retrieves the root directory/directories used for generating the file list of the menu. The default is "/Applications".
---
--- Parameters:
---  * `root` - optional argument which specifies the root directory for the menu (if it is a string) or a list of key-value pairs in a table where the key specifies an entry in the top level of the menu and the value specifies the path to be used as the root directory for the sub-menu of the entry.
---
--- Returns:
---  * The current (or changed) value.
---
--- Notes:
---  * If you forget to define the list as key-value pairs, then your top-level menu will consist of numbers.
---  * Invalidates the menu cache, so a repopulation of the menu will take place next time the menu is clicked on.
        rootDirectory  = function(self, x)
                            if type(x) == "string" or type(x) == "table" then
                                self.root = x
                                self.menuListRawData = nil
                            end
                            return self.root
                        end,
--- hs._asm.filelistmenu:menuCriteria(criteria) -> string|function
--- Method
--- Sets or retrieves the match criteria used to populate the menu. The default is "([^/]+)%.app$".
---
--- Parameters:
---  * `criteria` - optional string or function which specifies the match criteria for populating the menu.
---    * If the argument is a string then it is used as the match expression for the lua function `string.match()` against each filename found by traversing in the root directory/directories.  If you use parenthesis in the expression as a capture, then the first capture returned is used as the menu item label instead of the full filename when a match occurs.
---    * If the argument is a function, then it will be passed 3 arguments: filename, path (without the filename), purpose and is expected to return up to two parameters: true/false, [label]
---      * The purpose argument will be "file", "directory", or "update" indicating if the request is to determine if this is a match for a filename (menu item), a match for a sub-directory (menu sub-menu), or a match for triggering an update because of a file change within the directory root(s).
---      * The function should return true if this is a match and should be included, or false if it should be skipped, and an optional label.  If the label is specified, this will be displayed in the menu, rather than the filename.  Label is ignored for "update" matches and if the result is false.
---
--- Returns:
---  * The current (or changed) value.
---
--- Notes:
---  * See `hs._asm.filelistmenu:populate()` for more information on the difference between the "file" pass and the "directory" pass.
        menuCriteria   = function(self, x)
                            if type(x) ~= "nil" then
                                self.matchCriteria = x
                                self.menuListRawData = nil
                            end
                            return self.matchCriteria
                        end,
--- hs._asm.filelistmenu:populate() -> filelistmenu
--- Method
--- Scans the root directory/directories and builds the drop-down menu which will be displayed when the user clicks on the menu in the menubar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `filelistmenu` - returns the file list menu object.
---
--- Notes:
---  * Populating the menu occurs in two passes, the "file" match pass and the "directory" match pass.
---
---      During the file match pass, files or directories which are to be listed as menu items (not sub-menus) are identified for the current search folder.  During the directory match pass, directories are identified and recursively searched for additional items.  Directories which are searched are added to the menu as sub-menus.
---
---      If the match criteria is a string, then the following occurs during each pass:
---        * File pass: any item, file or directory, which matches the match criteria is included as an item at this level of the menu.
---        * Directory pass: any directory that was NOT matched during the file pass is entered and the populate process begins anew in this sub-directory.  If results are found, then they are included as a sub-menu at the current level with the directory name as the label.
---
---      If the match criteria is a function, the the following occurs during each pass:
---        * File pass: for each file and directory the function is invoked with the filename, path, and "file" as the purpose.  If this function returns `true`, then the filename is added as an item to the menu.
---        * Directory pass: for each directory -- even those matched during the file pass -- the function is invoked with the filename, path, and "directory" as the purpose.  If this function returns true, then the directory is entered and the populate process begins anew in this sub-directory.  If results are found, then they are included as a sub-menu at the current level with the directory name as the label.
---
---  * Each item matched during the "file" pass has their action attached to the `actionFunction`.
---  * Each item matched during the "directory" pass has their action attached to the `folderFunction`.
---  * If pruneEmptyDirs is set to true, then any examined sub-directory which does not contain any menu items is silently removed from the list.  If it is false, then empty subdirectories are included as menu items (i.e. no arrow to their right) and their action is tied to the `folderFunction`.
---  * Directories will only be examined up to `maxDepth` levels deep.
        populate       = function(self)
                            l_populateMenu(self)
                            return self
                        end,

-- default and place holder values
        subFolderBehavior = 0,
        menuView          = 0,
        matchCriteria     = "([^/]+)%.app$",
        template          = function(x) application.launchOrFocus(x) end,
        folderTemplate    = function(x) os.execute([[open -a Finder "]]..x..[["]]) end,
        root              = "/Applications",
        menuLastUpdated   = "not yet",
        lastChangeSeen    = "not yet",
        warnings          = false,
        pruneEmpty        = true,
        maxDepth          = 10,
        controlMenuMods   = { ["ctrl"]=true },
        rightMouseControlMenu = true,
    },
    __gc = function(self)
        return self:l_deactivateMenu()
    end,
    __tostring = function(self)
        return "This is the state data for menu "..self.label.."."
    end,
}
-- Public interface ------------------------------------------------------

--- hs._asm.filelistmenu.new(label) -> filelistmenu
--- Constructor
--- Creates a new filelist menu object.
---
--- Parameters:
---  * `label` - A string label for this menu.  It is used as the menu title, if no icon is provided.
---
--- Returns:
---  * `filelistmenu` - the object which represents the menu created and is used as the target for the API methods which govern the menu's appearance and behavior.
---
--- Notes:
---  * Technically the label can be left out, in which case a label is generated from the address of an empty table and used instead.  Since the label is the default menu title and also appears in warning messages, this default is not recommended.
module.new = function(menuLabel)
    local tmp = {}
    local menuLabel = menuLabel or tostring(tmp)
    tmp.label = tostring(menuLabel)
    return setmetatable(tmp, mt_fileListMenu)
end

--- hs._asm.filelistmenu:delete() -> nil
--- Method
--- Deletes the menu by first deactivating it and then clearing its metadata.
---
--- Parameters:
---  * None
---
--- Returns:
---  * nil
---
--- Notes:
---  * Unlike `deactivate`, this also removes the objects metadata, thus preventing the menu from being reactivated.
module.delete = function(self)
    if self then
        self:deactivate()
        setmetatable(self, nil)
    end
    return nil
end

-- Return Module Object --------------------------------------------------

return module
