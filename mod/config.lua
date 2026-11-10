-- Takes the numbers from the settings and gives the numbers for the geometry.
--
-- Pure: this module does not use the Factorio API, so it runs under plain Lua
-- in CI, together with hat/. All code that reads `settings` or `storage` is in
-- mod/surface.lua.

local Ti = require("hat.tiling")

local Config = {}

Config.MIN_SIZE, Config.MAX_SIZE = 15, 90
Config.MIN_BAND, Config.MAX_BAND = 1, 6
Config.DEFAULT_SIZE, Config.DEFAULT_BAND = 41, 3

-- The sizes and widths in the settings dropdowns. MIN and MAX above still
-- limit any value that comes from somewhere else. These are only the choices
-- that a player gets, and we measured each one. We did not guess.
--
-- At band 3 (see CELL_STATS below for every band):
--
--   size  cell area   largest blueprint reusable in EVERY cell
--     15     63 t       5x5      very hard
--     26    294 t       10x10    hard
--     41    858 t       17x17    normal
--     52  1,473 t       22x22    easy
Config.SIZE_CHOICES = { 15, 26, 41, 52 }
Config.BAND_CHOICES = { 1, 2, 3, 4 }

-- A Factorio map is 2e6 x 2e6, so its half-diagonal is about 1.41e6.
-- Ti:coverage() is the CIRCUMRADIUS of a hexagonal root. A square region
-- inside that circle is not fully tiled, because its corners are outside it.
-- So ask for well above the half-diagonal, never the half-width.
Config.REQUIRED_COVER = 1.6e6

local function clamp1(v, lo, hi, default)
  if type(v) ~= "number" then return default end
  if v ~= v then return lo end                 -- x ~= x is the only NaN test
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

function Config.clamp(size, band)
  return clamp1(size, Config.MIN_SIZE, Config.MAX_SIZE, Config.DEFAULT_SIZE),
         clamp1(band, Config.MIN_BAND, Config.MAX_BAND, Config.DEFAULT_BAND)
end

--- Everything the mod needs to place cells, derived from two settings.
-- @return { size, band, unit, depth, half }
function Config.geometry(size, band)
  size, band = Config.clamp(size, band)
  local unit = Ti.unit_for_hat_size(size)
  local depth = Ti.depth_covering(unit, Config.REQUIRED_COVER)
  if not depth then
    error("hattorio: no emitted depth covers the map at cell size " .. size)
  end
  return { size = size, band = band, unit = unit, depth = depth, half = band / 2 }
end

-- Measured properties of every combination the dropdowns offer.
--
-- These values are not fitted. For each one, we rasterised the interior of a
-- cell at that size and band width, and took the worst case across all
-- orientations:
--
--   area       buildable tiles in a cell
--   square     largest axis-aligned square that fits EVERY cell, so the
--              largest blueprint that you can reuse everywhere
--   drillable  fraction of the ore in a cell that a 3x3 mining drill can reach
--
-- Here exact values are better than a fit. The settings offer sixteen
-- combinations, and we know all sixteen. Config.fit_drillable below is only a
-- fallback for values that did not come from a dropdown.
Config.CELL_STATS = {
  [15] = { [1] = { area = 113,  square = 6,  drillable = 0.364 },
           [2] = { area = 94,   square = 5,  drillable = 0.242 },
           [3] = { area = 63,   square = 5,  drillable = 0.108 },
           [4] = { area = 46,   square = 4,  drillable = 0.054 } },
  [26] = { [1] = { area = 388,  square = 11, drillable = 0.610 },
           [2] = { area = 346,  square = 11, drillable = 0.522 },
           [3] = { area = 294,  square = 10, drillable = 0.426 },
           [4] = { area = 256,  square = 9,  drillable = 0.343 } },
  [41] = { [1] = { area = 1012, square = 19, drillable = 0.742 },
           [2] = { area = 939,  square = 18, drillable = 0.682 },
           [3] = { area = 858,  square = 17, drillable = 0.613 },
           [4] = { area = 790,  square = 16, drillable = 0.557 } },
  [52] = { [1] = { area = 1670, square = 24, drillable = 0.801 },
           [2] = { area = 1581, square = 23, drillable = 0.749 },
           [3] = { area = 1473, square = 22, drillable = 0.695 },
           [4] = { area = 1385, square = 21, drillable = 0.645 } },
}

--- Measured properties of a cell, or nil for a combination that we never
-- measured.
function Config.cell_stats(size, band)
  size, band = Config.clamp(size, band)
  local row = Config.CELL_STATS[size]
  return row and row[band] or nil
end

--- Fallback estimate, fitted to all sixteen measurements.
--
-- The worst error is 7.5 percentage points. The earlier fit had 14.6. It was
-- calibrated on six points and was very wrong at small cells. It said that
-- 20% of the ore was reachable at size 15 band 4, but the true value is 5.4%.
-- So it compensated too little exactly where compensation matters most.
function Config.fit_drillable(size, band)
  size, band = Config.clamp(size, band)
  local d = 1 - (2.3 * band + 7.9) / size
  if d < 0.05 then d = 0.05 end
  if d > 1.0 then d = 1.0 end
  return d
end

--- The fraction of the ore in a cell that a 3x3 mining drill can reach.
function Config.drillable_fraction(size, band)
  local stats = Config.cell_stats(size, band)
  if stats then return stats.drillable end
  return Config.fit_drillable(size, band)
end

--- How much to raise ore richness, to offset the ore that bands put out of
-- reach.
function Config.richness_multiplier(size, band)
  return 1 / Config.drillable_fraction(size, band)
end

--- Is this combination so tight that you can barely play it?
--
-- A mining drill and an assembling machine are both 3x3. If the largest square
-- that fits every cell is smaller than 5, almost nothing fits with room to
-- connect it.
function Config.is_severe(size, band)
  local stats = Config.cell_stats(size, band)
  return stats ~= nil and stats.square < 5
end

return Config
