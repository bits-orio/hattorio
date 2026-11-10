-- Finds the tiles of an area that are on a band.
--
-- Pure: this module does not use the Factorio API, so it runs under plain Lua
-- in CI. A tile is a band tile if its centre is within half the band width of
-- any hat edge.
--
-- PERFORMANCE. The obvious method tests every tile against every edge. That
-- is O(tiles x hats x edges), and it took 39.7 ms per chunk in measurement,
-- fifty times the cost of the tiling descent. This module rasterises each
-- edge into its own bounding box, clipped to the area. So it looks only at
-- tiles that can be near the edge.
--
-- Mirror marking: a reflected hat paints its own edges in the mirror variant.
-- Where a reflected hat and an unreflected hat share an edge, the reflected
-- hat wins. That is an OR over the hats that cover a tile, so the result does
-- not depend on the iteration order. This is important, because two clients
-- must agree.

local G = require("hat.geometry")

local Bands = {}

local floor, ceil = math.floor, math.ceil

--- @param tiling  a hat.tiling instance
--- @param geom    from mod.config.geometry, plus tile names
--- @param area    { left, top, right, bottom } in tile coordinates; right and
---               bottom are exclusive, the same as Factorio's chunk areas
--- @return array of { x = , y = , mirror = boolean }, in scan order
function Bands.for_area(tiling, geom, area)
  local unit, half = geom.unit, geom.half

  -- Query a box larger than the area. A hat with its centre outside the area
  -- can still have an edge that crosses it.
  local pad = geom.band + 2
  local hats = tiling:hats_in_box({
    left = area.left - pad, top = area.top - pad,
    right = area.right + pad, bottom = area.bottom + pad,
  })

  local left, top = area.left, area.top
  local right, bottom = area.right - 1, area.bottom - 1

  -- rows[ty][tx] = false for a plain band tile, true for a mirror one
  local rows = {}
  local dist = G.dist_to_segment

  for i = 1, #hats do
    local mirror = hats[i].reflected
    local edges = G.edges(hats[i].xf, unit)
    for j = 1, #edges do
      local s = edges[j]
      local x1, y1, x2, y2 = s[1], s[2], s[3], s[4]

      -- only tiles within `half` of the bounding box of this segment can match
      local lo_x = floor((x1 < x2 and x1 or x2) - half)
      local hi_x = ceil((x1 > x2 and x1 or x2) + half)
      local lo_y = floor((y1 < y2 and y1 or y2) - half)
      local hi_y = ceil((y1 > y2 and y1 or y2) + half)

      if lo_x < left then lo_x = left end
      if hi_x > right then hi_x = right end
      if lo_y < top then lo_y = top end
      if hi_y > bottom then hi_y = bottom end

      for ty = lo_y, hi_y do
        local row = rows[ty]
        local py = ty + 0.5
        for tx = lo_x, hi_x do
          if row == nil or row[tx] ~= true then
            if dist(tx + 0.5, py, x1, y1, x2, y2) < half then
              if row == nil then
                row = {}
                rows[ty] = row
              end
              if mirror or row[tx] == nil then
                row[tx] = mirror
              end
            end
          end
        end
      end
    end
  end

  -- Emit in scan order, so that the result never depends on the order of the
  -- hats.
  local out = {}
  for ty = top, bottom do
    local row = rows[ty]
    if row then
      for tx = left, right do
        local m = row[tx]
        if m ~= nil then
          out[#out + 1] = { x = tx, y = ty, mirror = m }
        end
      end
    end
  end
  return out
end

return Bands
