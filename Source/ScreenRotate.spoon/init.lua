--- === ScreenRotate ===
---
--- Toggle rotation on external screens
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/ScreenRotate.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/ScreenRotate.spoon.zip)
---
--- Makes the following simplifying assumptions:
--- * That you only toggle between two positions for rotated/not
---   rotated (configured in `rotating_angles`, and which apply to all
---   screens)
--- * That "rotated" means "taller than wider", for the purposes of
---   determining if the screen is rotated upon initialization.

local obj={}
obj.__index = obj

-- Metadata
obj.name = "ScreenRotate"
obj.version = "0.1"
obj.author = "Diego Zamboni <diego@zzamboni.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Spoon self.logger
obj.logger = hs.logger.new('ScreenRotate')

--- ScreenRotate.screens_to_skip
--- Variable
--- Lua patterns for screens that shouldn't be rotated, even if they match one of the patterns. Defaults to `{ "Color LCD" }`, which excludes the built-in display on a laptop.
obj.screens_to_skip = { "Color LCD" }

--- ScreenRotate.rotating_angles
--- Variable
--- Two-element table containing the rotation angles for "normal" and "rotated". Defaults to `{ 0, 90 }` and should only be changed if you really know what you are doing.
obj.rotating_angles = { 0, 90 }

-- Internal variable caching the IDs of screens that are currently rotated.
obj._rotated = { }

-- Internal variable caching the screens found in the system
obj._screens = {}

function obj:setRotation(scrname, rotate)
   self.logger.df("obj:setRotation(%s, %s)", scrname, rotate)
   if obj._screens[scrname] ~= nil then
      self._rotated[scrname]=rotate
      obj._screens[scrname]:rotate(obj.config.rotating_angles[self._rotated[scrname] and 2 or 1])
   end
end

function obj:toggleRotation(scrname)
   self.logger.df("obj:toggleRotation(%s)", scrname)
   obj:findScreens()
   if obj._screens[scrname] ~= nil then
      self.logger.i(string.format("Rotating screen '%s' (matching key '%s')", obj._screens[scrname]:name(), scrname))
      obj:setRotation(scrname, not self._rotated[scrname])
   else
      self.logger.wf("Rotation triggered, but I didn't find any screen matching '%s' - skipping", scrname)
   end
end

function filteredScreenFind(scr)
   local scrs = { hs.screen.find(scr) }
   for i,s in ipairs(scrs) do
      local skip = false
      for j,p in ipairs(obj.screens_to_skip) do
         if string.match(s:name(), p) then
            skip = true
         end
      end
      if not skip then
         return s
      end
   end
   return nil
end

function obj:findScreens()
   for k,v in pairs(self.toggle_rotate_keys) do
      local scr = filteredScreenFind(k)
      obj._screens[k] = scr
      if scr ~= nil then
         scrname = scr:name()
         self.logger.df("Found screen %s (matching key '%s'), setting up for rotation", scrname, k)
         local mode = scr:currentMode()
         -- Determine if the screen is currently rotated
         obj:setRotation(k, mode.h > mode.w)
      else
         self.logger.df("Found no screen matching '%s', skipping rotation", k)
      end
   end
end

--- ScreenRotate:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for ScreenRotate.
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details to rotate screens. Instead of fixed "key names", each key must be the name of a screen to rotate, or a Lua pattern - in this case the first screen to match the pattern will be rotated. The value is a table containing the hotkey modifier/key details as usual. You can use the key `[".*"]` to match the first external screen, which should be sufficient unless you have more than one external screen.
function obj:bindHotkeys(mapping)
   self.toggle_rotate_keys = mapping
   for k,v in pairs(mapping) do
      self.logger.df("Setting up screen binding rotation for screen matching '%s' with key %s", k, v)
      hs.hotkey.bindSpec(v, function() self:toggleRotation(k) end)
   end
end

return obj