local planets = require("mod.planets")
local colours = require("mod.colours")

-- Two independent startup settings control the band appearance. STYLE sets
-- the shader on the surface, and COLOUR sets the tint of that shader.
--
-- Both styles copy `deepwater`. Its transitions are drawn for liquid that
-- meets land, which is the edge that a rift needs. It also has the only
-- animated shader in the base game.
--
-- We tried a glowing style with the lava shader and removed it. It looked
-- like a hazard, not a void, and it clashed with the calm look of the rest of
-- the mod.
local STYLE = settings.startup["hattorio-band-style"].value
local COLOUR = settings.startup["hattorio-band-colour"].value

-- Only the effect is different between styles. The colours come from
-- COLOUR.
local STYLE_EFFECT = {
  liquid = "water",
  void = nil,
}

local c = colours[COLOUR] or colours.violet
local effect = STYLE_EFFECT[STYLE]

local function band_tile(name, highlight, map_color)
  local src = data.raw.tile["deepwater"]
  if not src then
    error("hattorio: base tile 'deepwater' does not exist")
  end
  local t = table.deepcopy(src)
  t.name = name
  t.map_color = map_color
  t.order = "z[hattorio]"
  t.localised_name = { "tile-name.hattorio-band" }

  -- Only the band layer. The tile blocks nothing else, so the character and
  -- vehicles pass over it. It is a rift that you can step across.
  t.collision_mask = { layers = { hattorio_band = true } }

  t.effect = effect
  t.effect_color = c.body
  t.effect_color_secondary = highlight

  -- Not water. The tile must not feed an offshore pump or merge with lakes.
  -- It must not be minable or appear in blueprints, and it must never
  -- autoplace.
  t.fluid = nil
  t.transition_merges_with_tile = nil
  t.autoplace = nil
  t.minable = nil
  t.mined_sound = nil
  t.can_be_part_of_blueprint = false
  t.walking_speed_modifier = nil
  t.factoriopedia_alternative = nil

  return t
end

local tiles = {}
for planet, _ in pairs(planets) do
  tiles[#tiles + 1] = band_tile("hattorio-band-" .. planet, c.highlight, c.body)
  tiles[#tiles + 1] = band_tile("hattorio-band-" .. planet .. "-mirror", c.mirror, c.mirror)
end

data:extend(tiles)
