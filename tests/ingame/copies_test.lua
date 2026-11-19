-- Multi-Team Support gives each team a surface of its own for each planet,
-- and names it after the planet. These tests make such surfaces by hand, so
-- they run without that mod. The busted suite tests the names.

local Surface = require("mod.surface")
local Terrain = require("mod.terrain")

local CX, CY = 40, 40
local AREA = { left_top = { x = CX * 32, y = CY * 32 },
               right_bottom = { x = CX * 32 + 32, y = CY * 32 + 32 } }

local function generate(surface)
  surface.request_to_generate_chunks({ CX * 32 + 16, CY * 32 + 16 }, 0)
  surface.force_generate_chunk_requests()
end

local function band_tiles(surface)
  local g = Surface.get(surface)
  return surface.count_tiles_filtered({ area = AREA, name = { g.tile, g.mirror_tile } })
end

-- The total of the finite ore in the test chunk.
local function ore(surface)
  local sum = 0
  for _, e in pairs(surface.find_entities_filtered({ area = AREA, type = "resource" })) do
    if not e.prototype.infinite_resource then sum = sum + e.amount end
  end
  return sum
end

-- The chunk event of the test chunk, as the game sends it.
local function chunk_event(surface)
  return { surface = surface, position = { x = CX, y = CY }, area = AREA, tick = game.tick }
end

local function team_copy()
  local nauvis = game.surfaces["nauvis"]
  return game.surfaces["team-1-nauvis"]
    or game.create_surface("team-1-nauvis", nauvis.map_gen_settings)
end

test("a team's copy of nauvis has the geometry of nauvis", function()
  local copy = team_copy()
  assert(Surface.is_tiled(copy), "the copy is not tiled")
  assert(Surface.get(copy) == Surface.get(game.surfaces["nauvis"]),
    "the copy has a geometry of its own")
end)

test("a surface with a similar name is not tiled", function()
  local other = game.create_surface("team-nauvis")
  assert(not Surface.is_tiled(other), "team-nauvis is tiled")
  game.delete_surface(other)
end)

test("a new chunk on a team's copy gets bands", function()
  local copy = team_copy()
  generate(copy)
  after_ticks(1, function()
    assert(band_tiles(copy) > 0, "the chunk has no band tiles")
  end)
end)

-- Multi-Team Support copies each chunk of nauvis to the same chunk of the
-- team's surface. The copy has the bands and the raised ore already. The
-- chunk event of the same tick must not raise the ore again.
test("a chunk that is a copy of a nauvis chunk keeps its ore", function()
  local nauvis, copy = game.surfaces["nauvis"], team_copy()
  generate(nauvis)
  generate(copy)
  nauvis.create_entity({ name = "iron-ore", amount = 1000,
    position = { CX * 32 + 16.5, CY * 32 + 16.5 } })
  after_ticks(1, function()
    nauvis.clone_area({
      source_area = AREA, destination_area = AREA, destination_surface = copy,
      clone_tiles = true, clone_entities = true, clone_decoratives = true,
      expand_map = false,
    })
    local before = ore(copy)
    assert(before == ore(nauvis), "the copy does not have the ore of nauvis")
    assert(band_tiles(copy) == band_tiles(nauvis), "the copy does not have the bands of nauvis")

    Terrain.on_chunk_generated(chunk_event(copy))
    assert(ore(copy) == before, "the chunk event changed the ore of a copy")

    -- The record of the copy is for one tick. A chunk that generates later
    -- at the same position gets the usual work.
    after_ticks(1, function()
      Terrain.on_chunk_generated(chunk_event(copy))
      assert(ore(copy) > before, "the chunk event of a later tick did nothing")
    end)
  end)
end)
