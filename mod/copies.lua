-- Surfaces that are a copy of a planet under another name.
--
-- Multi-Team Support gives each team a surface of its own for each planet.
-- The surface has one of two names:
--
--   mts-<planet>-<N>    with Space Age, where the copy is a planet of its own
--   team-<N>-<planet>   without Space Age
--
-- A copy of a planet gets the tiling of that planet.
--
-- Pure: this module does not use the Factorio API, so it runs under plain Lua
-- in CI.

local Copies = {}

local floor, ceil = math.floor, math.ceil

local CHUNK = 32

--- The planet that a surface with this name is a copy of, or nil.
function Copies.planet_of(name)
  return name:match("^mts%-(.+)%-%d+$") or name:match("^team%-%d+%-(.+)$")
end

--- The chunks that an area covers completely, as chunk positions.
--
-- @param left_top, right_bottom  tile positions; right_bottom is exclusive,
--                                the same as Factorio's chunk areas
function Copies.chunks_in(left_top, right_bottom)
  local out = {}
  for cy = ceil(left_top.y / CHUNK), floor(right_bottom.y / CHUNK) - 1 do
    for cx = ceil(left_top.x / CHUNK), floor(right_bottom.x / CHUNK) - 1 do
      out[#out + 1] = { x = cx, y = cy }
    end
  end
  return out
end

return Copies
