-- Stable hat identity: the descent path from the root to the hat, packed as
-- bytes.
--
-- The key is exact by construction, because no float ever goes into it. It is
-- deliberately NOT string.format on a coordinate. That uses %.14g and loses
-- enough precision that two different hats can get the same id, or one hat
-- can get two ids.
--
-- Each prefix is an ancestor: ancestor(key, k) names the level-k supertile.
-- So a future region or territory layer gets a hierarchy for free.

local I = {}

function I.encode(path)
  local parts = {}
  for i = 1, #path do
    local v = path[i]
    assert(type(v) == "number" and v >= 0 and v <= 254,
           "child index out of range: " .. tostring(v))
    parts[i] = string.char(v + 1)
  end
  return table.concat(parts)
end

function I.decode(key)
  local out = {}
  for i = 1, #key do
    out[i] = key:byte(i) - 1
  end
  return out
end

function I.ancestor(key, level)
  return key:sub(1, level)
end

function I.depth(key)
  return #key
end

return I
