# Toolchain

This page lists the tools that the project actually uses, and the reasons. We
removed everything that was proposed but not adopted. The reasons for the
arithmetic choices are in sections 5 and 14 of `hattorio-design.md`.

## Runtime: Lua 5.2.1

We did not choose this. Factorio embeds Lua 5.2.1, and the mod runs inside it.

This has two effects on the code:

- **No integer subtype.** Every number is a double, which is exact only up to
  2^53. For this reason the tiling core stores values and not exact integers.
  See design section 5.
- **`tostring` uses `%.14g` and loses precision.** For this reason a hat's
  identity is a packed descent path (`hat/index.lua`) and never a formatted
  coordinate. The first scaffold made the identity from
  `string.format("%.3f", ...)`. That can give two hats the same id, or give
  one hat two ids.

When the pipeline writes floats for Lua to read, it uses `%.17g`. This format
round-trips a double exactly. A test checks that every written value survives
the round trip.

## Testing: busted and luassert

We used red-green-refactor for all the work. The tests are in
`spec/*_spec.lua`, and busted finds them through `.busted`.

The tests must run under **Lua 5.2 specifically**. Lua 5.3 and later add an
integer subtype, so on 5.4 the tests would hide the all-doubles behaviour that
the core depends on. CI pins 5.2 for the same reason.

On Arch, `lua52-busted` installs the rock outside PATH, and its shebang points
at Lua 5.5, where its modules do not exist. The Makefile uses a `busted` on
PATH if there is one. If not, it uses the rock path.

**Property-style tests are plain loops over fixed seeds**, not a generative
library. We considered `lua-quickcheck` and dropped it. No luarocks package on
Arch includes a CLI, so you can install it only if you build it from source.
Fixed seeds are also easier to reproduce.

## Static analysis: luacheck

`make lint` and CI run luacheck over `hat/`, `mod/`, `prototypes/` and
`spec/`. The standard is zero warnings.

**We use no static type checker.** We considered Teal and rejected it. It has
no definitions for the Factorio API, so every call to the game would become
an untyped escape hatch. It also adds a build step from `.tl` to `.lua`. In
the design phase we chose LuaLS annotations, but we never added them, and the
code has none today. If you want types, use LuaLS annotations, and adopt them
as a deliberate decision.

## Layout

```text
hat/     tiling core, no Factorio dependencies, loads under plain lua5.2
tools/   offline pipeline (Python 3, stdlib only) and dev renderers
data/    generated Lua data; regenerate with `make data`, never hand-edit
spec/    busted tests, plus fixtures exported from the pipeline
wiki/    source for the GitHub wiki; publish with `make wiki`
```

The important split is this: `hat/` has no Factorio dependencies, so it runs
in CI under plain Lua, and `tools/` never ships. The exact arithmetic stays
offline, where it costs nothing. Only the values ship.

## Verification strategy

We considered formal verification and dropped it. No practical tools exist
for Lua. The mechanised semantics for Lua are research artefacts, not
verifiers.

In its place, three layers of checks run:

1. **Offline proofs** (`tools/verify.py`). The pipeline checks the generated
   tiling for overlapping hats and for gaps (with a flood fill). It checks
   that the density of reflected hats converges to 1/(phi^4+1), and that the
   hat counts match F(2n+3)^2 exactly.
2. **Golden fixtures.** The pipeline exports a reference patch, and the Lua
   descent must produce the same patch. This tests the code that ships against
   the arithmetic that we proved correct.
3. **Invariant tests.** `spec/invariants_spec.lua` searches the shipped
   modules for `math.sin`, `math.cos`, `math.random` and `^`. None of these
   give identical bits on all platforms.

## Functional core

The `hat/` modules are pure. They have no mutable state and do not use the
Factorio API, and every function is total over its inputs. Side effects
belong in the layer that talks to Factorio.

We got here from the determinism constraint, not from a principle. But the
result matches SUPER (side effects at the edge, uncoupled logic, pure and
total functions, explicit data flow, replaceable by value). Design section 7
gives the three rules that make this explicit.

There is one deliberate exception. The descent changes its output accumulator
in place, for speed. The accumulator is local to `hat/tiling.lua` and never
leaves it.

## Releasing

`info.json` is the only source of truth for the version. Everything else must
agree with it. `tools/check_version.py` checks this on every push, not only
when you make a release:

- the changelog must have a `Version: X.Y.Z` entry for the version, and that
  entry must be first
- the changelog must start with exactly 99 dashes, or Factorio does not load
  the mod and shows an unhelpful message
- if you give a release tag, it must be `v<version>`

To make a release, push a tag:

```bash
# bump info.json and add a changelog entry first
git tag v0.2.0 && git push origin v0.2.0
```

`.github/workflows/release.yml` then verifies the version and runs the full
suite under Lua 5.2. It builds the zip, attaches it to a GitHub release and
uploads it to the Factorio mod portal.

The portal upload needs a repository secret called `FACTORIO_API_KEY`. Get the
key from <https://factorio.com/profile> with the *ModPortal: Upload Mods*
permission. The upload runs in a GitHub environment called `mod-portal`. You
can give that environment a required reviewer, so that a person approves
before anything is published.

**You cannot withdraw a release from the portal.** For this reason every check
runs before the upload step and not after it. Also, a branch push never
starts the upload. Only a tag starts it, or a manual dispatch that asks for it
explicitly.
