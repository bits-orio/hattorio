-- The remote interface, for other mods.
--
-- The mod tiles the surfaces of the planets in `mod/planets.lua`, and it
-- finds them by name. A mod that makes another surface for one of these
-- planets tells this mod which planet it is:
--
--   if remote.interfaces["hattorio"] then
--     remote.call("hattorio", "set_surface_planet", surface.index, "nauvis")
--   end
--
-- The surface then gets the cells and the settings of that planet. Make the
-- call when you create the surface, before its first chunk generates.

local Surface = require("mod.surface")

-- A surface, from its index or its name.
local function surface_of(id)
  if type(id) ~= "number" and type(id) ~= "string" then return nil end
  return game.get_surface(id)
end

remote.add_interface("hattorio", {
  --- Give a surface the tiling of a planet.
  -- @param surface  the index or the name of the surface
  -- @param planet   nauvis, vulcanus, fulgora, gleba or aquilo
  -- @return true if the surface has the tiling of this planet after the call
  set_surface_planet = function(surface, planet)
    surface = surface_of(surface)
    if not surface or type(planet) ~= "string" then return false end
    return Surface.assign(surface, planet)
  end,

  --- The planet whose tiling a surface has, or nil if the mod does not tile
  -- the surface.
  get_surface_planet = function(surface)
    surface = surface_of(surface)
    return surface and Surface.planet_of(surface) or nil
  end,
})
