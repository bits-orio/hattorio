std = "lua52"
max_line_length = 100

-- Factorio's Lua environment. The game provides these, not Lua.
local factorio_globals = {
  "data", "mods", "settings", "defines", "game", "script",
  "prototypes", "remote", "commands", "rendering", "log", "serpent",
  "table_size", "helpers",
}

-- storage is the persistent table of the mod. Factorio provides it and mods
-- write to it, so it is not read-only.
local factorio_writable = { "storage", "table" }

files["prototypes"] = {
  read_globals = factorio_globals,
  -- Factorio adds table.deepcopy
  globals = factorio_writable,
}

files["mod"] = {
  read_globals = factorio_globals,
  globals = factorio_writable,
}

files["spec"] = { std = "+busted" }

-- hat/ deliberately has no Factorio dependencies. It must load under plain
-- lua5.2, so that CI can test it. No Factorio globals here.
files["hat"] = {}
