-- A collision layer. The band tiles have it, and data-final-fixes gives it to
-- buildings.
--
-- Two prototypes collide only if they SHARE a layer. The character, vehicles
-- and rails never get this layer, so they cross bands freely. Anything that
-- does get it cannot be placed on a band. The game then refuses the placement
-- natively: the preview is red, blueprints skip the tiles, and construction
-- bots never try to build there.
data:extend({
  { type = "collision-layer", name = "hattorio_band" },
})
