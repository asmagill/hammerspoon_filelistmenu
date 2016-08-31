hs._asm.filelistmenu
====================

* August 31, 2016 - Updated so detached menus suppress "Remove Menu" in the Control Menu. Makefile modified to put module in `$(PREFIX)/hs/_asm/` to conform with my other modules.

This module allows the easy creation of drop-down menubar items which contain file lists that match specified criteria.  The default settings make it trivial to create an Application launcher menu, but more complex menus are also possible.  The match criteria specified is also used to generate pathwatcher processes which keep the menu current.

See the `examples` directory for sample implementations.

Because this module requires the `hs.menubar` module and the ASCII Art POD, this module is only supported by Hammerspoon and will not work, without porting some additional code, with Mjolnir.

### Local Install

A prepackaged version of this module may be found in this directory with the name `filelistmenu-v0.x.tar.gz`. This can be installed by downloading the file and then expanding it as follows:

~~~sh
$ cd ~/.hammerspoon # or wherever your Hammerspoon init.lua file is located
$ tar -xzf ~/Downloads/canvas-v0.x.tar.gz # or wherever your downloads are located
~~~

If you wish to install this module from the repository source, you can do the following:

~~~bash
$ git clone https://github.com/asmagill/hammerspoon_filelistmenu
$ cd hammerspoon_filelistmenu
$ [PREFIX=~/.hammerspoon] make install
~~~

Note that if you do not provide `PREFIX`, then it defaults to ~/.hammerspoon.

### Usage

~~~lua
flm = require("hs._asm.filelistmenu")
theMenu = flm.new(label)
~~~

### Functions

~~~lua
theMenu:activate() -> filelistmenu
~~~
Puts the menu into the menubar and activates the pathwatcher(s) to determine when to update the menu.

Parameters:
 * None

Returns:
 * `filelistmenu` - returns the file list menu object.


~~~lua
theMenu:actionFunction([function]) -> function
~~~
Sets or retrieves the function which specifies what action to take when an item is selected in the menu.  The default is a function which takes the path of the item selected and uses it as a parameter to `hs.application.launchOrFocus()`.

Parameters:
 * `function` - optional argument defines a function which takes one argument and is invoked when the user selects an item from the menu.  The argument to the function is the path of the file which the menu item represents.

Returns:
 * The current (or changed) function.


~~~lua
theMenu:controlMenu([mods]) -> mods
~~~
Sets or retrieves the modifiers which allow selecting a control menu variant which allows changing sort options, etc.  Default is { ctrl=true }.

Parameters:
 * `mods` - optional argument which is a table containing the as keys to non-false values which represent the modifier keys which can be held down while clicking on the drop-down menu to display a control menu for modifying the menu's appearance.  Set to {} (the empty table) to disable access to the control menu.  The possible keys are:
    * cmd
    * alt
    * shift
    * ctrl
    * fn

Returns:
 * The current (or changed) value.


~~~lua
theMenu:deactivate() -> filelistmenu
~~~
Removes the filelist menu from the menu bar, cancels the associated pathwatchers and clears the menu data from memory.

Parameters:
 * None

Returns:
 * `filelistmenu` - returns the file list menu object.

Notes:
 * The menu definition is not deleted, just it's cached data.  You could bring the menu back by issuing `savedMenu:activate()`.


~~~lua
theMenu:delete() -> nil
~~~
Deletes the menu by first deactivating it and then clearing its metadata.

Parameters:
 * None

Returns:
 * nil

Notes:
 * Unlike `deactivate`, this also removes the objects metadata, thus preventing the menu from being reactivated.


~~~lua
theMenu:folderFunction([function]) -> function
~~~
Sets or retrieves the function which specifies what action to take when a folder is selected in the menu.  The default is a function which takes the path of the fodler selected and opens it in the Finder.

Parameters:
 * `function` - optional argument defines a function which takes one argument and is invoked when the user selects a folder from the menu.  The argument to the function is the path of the folder which the menu item represents.

Returns:
 * The current (or changed) function.

Notes:
 * A menu item is considered a "folder" if it was detected during the "Directory" pass of the population process (see `hs._asm.filelistmenu:populate()` for more information).  This item may or may not actually have sub items (i.e. be a sub-menu) in the menu itself, depending upon your match criteria and the prune settings.


~~~lua
flm.keyModifiers() -> table
~~~
Returns a table containing the current key modifiers being pressed *at this instant*.  This makes it a useful function to check within an action or folder function if you wish to provide multiple possible actions when the user selects a menu item.

Parameters:
 * None

Returns:
 * Returns a table containing boolean values indicating which keyboard modifiers were held down when the menubar item was clicked; The possible keys are:
    * cmd
    * alt
    * shift
    * ctrl
    * fn


~~~lua
theMenu:menuCriteria(criteria) -> string|function
~~~
Sets or retrieves the match criteria used to populate the menu. The default is "([^/]+)%.app$".

Parameters:
 * `criteria` - optional string or function which specifies the match criteria for populating the menu.
   * If the argument is a string then it is used as the match expression for the lua function `string.match()` against each filename found by traversing in the root directory/directories.  If you use parenthesis in the expression as a capture, then the first capture returned is used as the menu item label instead of the full filename when a match occurs.
   * If the argument is a function, then it will be passed 3 arguments: filename, path (without the filename), purpose and is expected to return up to two parameters: true/false, [label]
     * The purpose argument will be "file", "directory", or "update" indicating if the request is to determine if this is a match for a filename (menu item), a match for a sub-directory (menu sub-menu), or a match for triggering an update because of a file change within the directory root(s).
     * The function should return true if this is a match and should be included, or false if it should be skipped, and an optional label.  If the label is specified, this will be displayed in the menu, rather than the filename.  Label is ignored for "update" matches and if the result is false.

Returns:
 * The current (or changed) value.

Notes:
 * See `hs._asm.filelistmenu:populate()` for more information on the difference between the "file" pass and the "directory" pass.


~~~lua
theMenu:menuIcon([icon]) -> icon
~~~
Sets or retrieves the menu's icon.  If the icon is changed, and the menu has been activated, then the change goes into effect immediately.

Parameters:
 * `icon` - optional argument which specifies the icon's path, if it is a file, or defines the icon as an ASCII Art drawing.  See `hs.drawing.image` for more information.

Returns:
 * The current (or changed) icon data.

Notes:
 * If the file does not exist or the ASCII art is un-renderable, then the label is used instead.


~~~lua
theMenu:menuLabel([label]) -> label
~~~
Sets or retrieves the menu's label.  If the label is changed, and the menu has been activated, then the change goes into effect immediately.

Parameters:
 * `label` - optional argument which specifies the menu's label

Returns:
 * The current (or changed) label.


~~~lua
flm.new(label) -> filelistmenu
~~~
Creates a new filelist menu object.

Parameters:
 * `label` - A string label for this menu.  It is used as the menu title, if no icon is provided.

Returns:
 * `filelistmenu` - the object which represents the menu created and is used as the target for the API methods which govern the menu's appearance and behavior.

Notes:
 * Technically the label can be left out, in which case a label is generated from the address of an empty table and used instead.  Since the label is the default menu title and also appears in warning messages, this default is not recommended.


~~~lua
theMenu:populate() -> filelistmenu
~~~
Scans the root directory/directories and builds the drop-down menu which will be displayed when the user clicks on the menu in the menubar.

Parameters:
 * None

Returns:
 * `filelistmenu` - returns the file list menu object.

Notes:
 * Populating the menu occurs in two passes, the "file" match pass and the "directory" match pass.

     During the file match pass, files or directories which are to be listed as menu items (not sub-menus) are identified for the current search folder.  During the directory match pass, directories are identified and recursively searched for additional items.  Directories which are searched are added to the menu as sub-menus.

     If the match criteria is a string, then the following occurs during each pass:
      * File pass: any item, file or directory, which matches the match criteria is included as an item at this level of the menu.
      * Directory pass: any directory that was NOT matched during the file pass is entered and the populate process begins anew in this sub-directory.  If results are found, then they are included as a sub-menu at the current level with the directory name as the label.

   If the match criteria is a function, the the following occurs during each pass:
      * File pass: for each file and directory the function is invoked with the filename, path, and "file" as the purpose.  If this function returns `true`, then the filename is added as an item to the menu.
      * Directory pass: for each directory -- even those matched during the file pass -- the function is invoked with the filename, path, and "directory" as the purpose.  If this function returns true, then the directory is entered and the populate process begins anew in this sub-directory.  If results are found, then they are included as a sub-menu at the current level with the directory name as the label.

 * Each item matched during the "file" pass has their action attached to the `actionFunction`.
 * Each item matched during the "directory" pass has their action attached to the `folderFunction`.
 * If pruneEmptyDirs is set to true, then any examined sub-directory which does not contain any menu items is silently discarded.  If it is false, then empty subdirectories are included as menu items (i.e. no arrow to their right) and their action is tied to the `folderFunction`.
 * Directories will only be examined up to `maxDepth` levels deep.


~~~lua
theMenu:pruneEmptyDirs([bool]) -> bool
~~~
Sets or retrieves whether or not empty directories are pruned from the menu list.  Default is true.

Parameters:
 * `bool` - optional argument which turns pruning on or off.

Returns:
 * The current (or changed) value.

Notes:
 * This determines if subdirectories are examined during the Directory pass of the population process.  See `hs._asm.filelistmenu:populate()` for more information on this process.


~~~lua
theMenu:rootDirectory(root) -> string|table
~~~
Sets or retrieves the root directory/directories used for generating the file list of the menu. The default is "/Applications".

Parameters:
 * `root` - optional argument which specifies the root directory for the menu (if it is a string) or a list of key-value pairs in a table where the key specifies an entry in the top level of the menu and the value specifies the path to be used as the root directory for the sub-menu of the entry.

Returns:
 * The current (or changed) value.

Notes:
 * If you forget to define the list as key-value pairs, then your top-level menu will consist of numbers.
 * Invalidates the menu cache, so a repopulation of the menu will take place next time the menu is clicked on.


~~~lua
theMenu:showForMenu([item]) -> item
~~~
Sets or retrieves how the menu appears in the menu bar -- as an icon, a label, or both.  Default is 0.

Parameters:
 * `item` - optional argument to set the menu display style to icon, label, or both.  Internally this is a number, but you can specify it as a string: 0 = "icon", 1 = "label", 2 = "both"

Returns:
 * The current (or changed) setting as a number from 0 to 2.

Notes:
 * If the icon is not set or is un-renderable, then the label will be displayed even if this is set icon only (0).


~~~lua
theMenu:showWarnings([bool]) -> bool
~~~
Sets or retrieves whether or not warnings are printed to the Hammerspoon console.  Default is false.

Parameters:
 * `bool` - optional argument which turns warning on or off.

Returns:
 * The current (or changed) value.

Notes:
 * Warnings are issued when the max search depth is reached and when changed files are detected.  These are not problems per se, though you may want to tweak some of your settings, but it can get annoying if you use the console a lot.


~~~lua
theMenu:subFolders([item]) -> item
~~~
Sets or retrieves how the sub folders are sorted in the menu.  Default is 0.

Parameters:
 * `item` - optional argument specify how subfolders are to be sorted within the menu list results.  Internally this is a number, but you can specify it as a string: 0 = "ignore", 1 = "before", 2 = "mixed", 3 = "after"

Returns:
 * The current (or changed) setting as a number from 0 to 3.

Notes:
 * If subfolders are ignored, then they are not examined for potential menu list items.
 * Invalidates the menu cache if you change to or from Ignore (0), so a repopulation of the menu will take place next time the menu is clicked on.


~~~lua
theMenu:subFolderDepth([depth]) -> depth
~~~
Sets or retrieves the menu's label.

Parameters:
 * `depth` - optional argument which specifies how deep the module should search for items which match the specified criteria.  Default is 10.

Returns:
 * The current (or changed) depth.

Notes:
 * Invalidates the menu cache, so a repopulation of the menu will take place next time the menu is clicked on.


### Documentation

The json file provided contains the documentation for this module in a format suitable for use with Hammerspoon's `hs.doc.fromJSONFile(file)` function.  In the near future, I hope to provide a simple mechanism for combining multiple json files into one set of documents for use within the appropriate console and Dash docsets.

### License

> Released under MIT license.
>
> Copyright (c) 2015 Aaron Magill
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
>
