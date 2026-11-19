local Copies = require("mod.copies")

describe("copies of a planet", function()
  it("reads the planet from the Space Age name of a team's copy", function()
    assert.equal("nauvis", Copies.planet_of("mts-nauvis-1"))
    assert.equal("vulcanus", Copies.planet_of("mts-vulcanus-12"))
  end)

  it("reads the planet from the name of a team's copy without Space Age", function()
    assert.equal("nauvis", Copies.planet_of("team-1-nauvis"))
    assert.equal("nauvis", Copies.planet_of("team-12-nauvis"))
  end)

  it("keeps a hyphen in the name of the planet", function()
    assert.equal("neo-nauvis", Copies.planet_of("mts-neo-nauvis-3"))
    assert.equal("neo-nauvis", Copies.planet_of("team-3-neo-nauvis"))
  end)

  it("returns nil for a surface that is not a copy", function()
    for _, name in ipairs({
      "nauvis", "vulcanus", "platform-1", "mts-nauvis", "mts-nauvis-x",
      "team-nauvis", "team-x-nauvis", "team-1-", "my-mts-nauvis-1",
    }) do
      assert.is_nil(Copies.planet_of(name), name)
    end
  end)

  it("lists the one chunk of a chunk area", function()
    local chunks = Copies.chunks_in({ x = -64, y = 32 }, { x = -32, y = 64 })
    assert.same({ { x = -2, y = 1 } }, chunks)
  end)

  it("lists every chunk that an area covers completely", function()
    local chunks = Copies.chunks_in({ x = 0, y = 0 }, { x = 64, y = 32 })
    assert.same({ { x = 0, y = 0 }, { x = 1, y = 0 } }, chunks)
  end)

  it("leaves out a chunk that an area covers only in part", function()
    assert.same({}, Copies.chunks_in({ x = 1, y = 0 }, { x = 32, y = 32 }))
    local chunks = Copies.chunks_in({ x = -10, y = -10 }, { x = 70, y = 40 })
    assert.same({ { x = 0, y = 0 }, { x = 1, y = 0 } }, chunks)
  end)
end)
