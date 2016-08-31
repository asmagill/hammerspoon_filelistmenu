#
# If you haven't already, perform the following before
# typing 'make':
#
# sudo ln -s /Applications/Hammerspoon.app/Contents/Frameworks/LuaSkin.framework /Library/Frameworks/LuaSkin.framework
#
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

MODULE := $(current_dir)
PREFIX ?= ~/.hammerspoon

OBJCFILE = internal.m
LUAFILE  = init.lua
SOFILE  := $(OBJCFILE:.m=.so)
DEBUG_CFLAGS ?= -g

CC=cc
EXTRA_CFLAGS ?= -fobjc-arc
CFLAGS  += $(DEBUG_CFLAGS) -Wall -Wextra $(EXTRA_CFLAGS)
LDFLAGS += -dynamiclib -undefined dynamic_lookup $(EXTRA_LDFLAGS)

ifeq ($(wildcard $(CURDIR)/$(OBJCFILE)),)

### Lua Only

all: verify

install: install-lua

else

### Lua and Objective-C live together in perfect harmony

all: verify $(SOFILE)

$(SOFILE): $(OBJCFILE)
	$(CC) $(OBJCFILE) $(CFLAGS) $(LDFLAGS) -o $@

install: install-objc install-lua

endif

### Common

verify: $(LUAFILE)
	luac-5.3 -p $(LUAFILE) && echo "Passed" || echo "Failed"

install-objc: $(SOFILE)
	mkdir -p $(PREFIX)/hs/_asm/$(MODULE)
	install -m 0644 $(SOFILE) $(PREFIX)/hs/_asm/$(MODULE)

install-lua: $(LUAFILE)
	mkdir -p $(PREFIX)/hs/_asm/$(MODULE)
	install -m 0644 $(LUAFILE) $(PREFIX)/hs/_asm/$(MODULE)

clean:
	rm -v -rf $(SOFILE) *.dSYM

uninstall:
	rm -v -f $(PREFIX)/hs/_asm/$(MODULE)/$(LUAFILE)
	rm -v -f $(PREFIX)/hs/_asm/$(MODULE)/$(SOFILE)
	rmdir -p $(PREFIX)/hs/_asm/$(MODULE) ; exit 0

.PHONY: all clean uninstall verify install install-objc install-lua
