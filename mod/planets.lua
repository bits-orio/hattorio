-- The surfaces that get a tiling.
--
-- This is a set, not a list. mod/surface.lua tests membership by name.
-- Anything that is not here keeps vanilla terrain. That includes space
-- platforms, and any planet from another mod that we have no settings for.
--
-- Band colour is NOT per planet. It is one setting for every surface, so that
-- the mod looks like one thing and not like five.
return {
  nauvis = true,
  vulcanus = true,
  fulgora = true,
  gleba = true,
  aquilo = true,
}
