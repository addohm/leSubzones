# leSubZones

WoW addon for **WoW Forever** (client "Camelot", product `wowf` (live; the beta is `wow_classic_beta`), TOC `16001`, modern Midnight-style API) that draws subzone borders, names and optional color fills on the world map and minimap. Borders come from the game's own terrain files, extracted offline by the Python tools. See `README.md` for user-facing docs.

## Layout

- `leSubZones/`: the addon, which is what gets installed. Renamed from `SUBZONES` (repo was SubZones-WoW-Forever); the internal names stayed: `SubzonesDB`, `SubzonesMapToggle`, `/subzones` + `/sz`, `SUBZONES_*` settings variables. `install_forever.cmd` deletes an installed `SUBZONES` folder so both don't load.
  - `leSubZones.lua`: all runtime code.
  - `SubzoneBorders.lua`: generated data (~750 KB). Never hand-edit it; regenerate with `tools/build_borders.py`.
  - `Build.lua`: `ns.Build = nil` in the repo; `install_forever.cmd` stamps the installed copy with the commit hash, shown by `/subzones debug`.
  - `leSubZones.toc`
  - `icon.tga`: 64×64 uncompressed 32-bit TGA of the round logo, the TOC's `## IconTexture` (AddOns list).
- `tools/`: offline data pipeline (Python 3, standard library except where noted). Needed to regenerate border data after game patches; not needed to run the addon.
  - `casc.py`: read-only CASC reader for the local install, with Blizzard CDN fallback.
  - `extract_game.py`: WDT/ADT → per-chunk area IDs → `data/game_areas.json`.
  - `borders.py`: shared geometry: grid → border polylines → smoothing → Lua writer.
  - `build_borders.py`: `game_areas.json` (or `--source site`) → `leSubZones/SubzoneBorders.lua`.
  - `extract_forever.cmd`: Windows; runs `extract_game.py` against the installed client (`WOWROOT` = the World of Warcraft folder), then commits and pushes only `data/game_areas.json`. The user runs it after a patch; then run `build_borders.py` here and commit `SubzoneBorders.lua`. CRLF.
  - `install_forever.cmd`: Windows; the same script as the other Forever addons (Lerep, leprofit). Runs from a `%TEMP%` copy, pulls from GitHub (explains a rewritten history), mirrors `leSubZones/` into `<WOW>\Interface\AddOns`, stamps `Build.lua`, packs `leSubZones-<version>.zip` on the desktop and says when a full restart is needed. `WOW` at the top defaults to `_forever_`. CRLF line endings (`.gitattributes`).
  - `package.py`: `leSubZones/` → `releases/leSubZones-<version>.zip` (TOC, the files it loads, the icon and LICENSE).
  - `compare.py`: wowforevermap.com `subzones.json` vs game, chunk by chunk → `data/comparison.md` + PNGs (needs Pillow).
  - `data/`: extraction output, the site's JSON, comparison report.
  - `cache/`: CDN downloads (~65 MB, safe to delete; refetched on demand).
- `releases/`: packaged zips for CurseForge / Wago, committed. Rebuild with `python tools/package.py` after a version bump.
- `LISTING.md`: CurseForge / Wago listing copy. Not part of the addon zip; keep the copy in step with features.
- `art/`: logos (1024 and 400 px squares, plus a round one with a transparent background) and a 1920×480 banner (README and listing header). Drawn from the real Elwynn borders; not part of the addon zip.

## Workflow

- **After every addon change**, commit and push; the user runs `tools\install_forever.cmd`, which pulls and mirrors `leSubZones/` into `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\leSubZones`, then `/reload`s (or restarts when the TOC changed). `/subzones debug` shows the installed build.
- **After a game patch:** the user runs `tools\extract_forever.cmd` (pushes `tools/data/game_areas.json`); pull, run `python tools/build_borders.py` (with `tools/data/subzones.json` downloaded, for the name fallback), check, commit and push. `extract_game.py` picks the product from `.build.info`: `wowf` (live, `_forever_`) first, then `wow_classic_beta`.
- **Testing:** there's no in-game test runner. Verify Lua by loading it in LuaJIT (`pip install lupa` in a throwaway venv, never system Python) against stubbed WoW APIs, then render the recorded lines/quads/labels with Pillow and look at the image. Keep harnesses in the scratchpad, not the project. State plainly that stub tests can't prove client behaviour; the user tests in-game and reports `/subzones debug` output.
- Error and crash logs live in `...\_forever_\Errors\`. Lua errors come via BugSack. Other addons (MapUtils, EllesmereUI, …) produce their own errors; check the stack before assuming it's ours.

## Data model

- Terrain: each ADT tile is 533⅓ yd = 16×16 chunks of 33⅓ yd. The MCNK header's area ID is at `+0x34`, and its IndexX/IndexY are at `+4`/`+8`.
- Continent grid: `row = tileY*16 + IndexY`, `col = tileX*16 + IndexX` (MAID index `i`: `tileX = i % 64`, `tileY = i // 64`).
- World coordinates: `worldX = (512 - row) * CHUNK` (north is +), `worldY = (512 - col) * CHUNK` (west is +).
- `SubzoneBorders.continents[continentID]` holds `areas[areaID] = {labelX, labelY, chunkCount}` (every area: subzones, zone-level areas, seas) and `lines[i] = {areaA, areaB (0 = none), x1, y1, ...}` in world coordinates. `names` is a fallback from the site.
- Known continent WDTs: 0 → 775971, 1 → 782779; 2991 (Zephras Isle) → 7198644 is auto-matched. 8 WDTs are encrypted (no keyring shipped). `AreaTable`/`Map` DB2 are encrypted too, so names and parents can only be read in-game.

## Runtime rules learned the hard way

- `C_Map.GetWorldPosFromMapPos` vectors are `(worldX, worldY)`, the same order as the data. Don't "auto-detect" axis order; a density heuristic picked the wrong order once.
- On Kalimdor and the Eastern Kingdoms, `C_Map.GetMapPosFromWorldPos` returns the **continent** map, not the zone. Map ownership therefore uses the parent continent's `C_Map.GetMapInfoAtPosition` (plus a check that no child city map is at the point). `GetMapPosFromWorldPos` is only a fallback (Zephras Isle has no continent map).
- Never draw on continent or world maps (`mapType < Zone`). Drawing a whole continent's borders froze and crashed the client. Keep the `MAX_SUBZONES_PER_MAP` cap.
- The zone-level area is dropped by name match with the map name, or else by being more than 35% of the map's chunks.
- `Blizzard_MapCanvas` is load-on-demand: no XML templates inheriting `MapCanvasPinTemplate`, and touch `MapCanvasDataProviderMixin` only in `Install()`.
- The world-map overlay is a plain frame on `WorldMapFrame:GetCanvas()` plus a data provider. Its frame level comes from its own pin frame level, `PIN_FRAME_LEVEL_SUBZONES`, inserted above `FOG_OF_WAR` (fallbacks after it), re-read on every draw. OpenMap inserts 80 levels of map art just above `MAP_EXPLORATION`; the old "exploration + 1" level put the lines under it. Fills are `SetColorTexture` quads shaped with `SetVertexOffset` (trapezoid decomposition).
- Minimap clipping: square minimaps clip to a rectangle inset by `Minimap:GetHitRectInsets()` (positive values only). EllesmereUI keeps the minimap canvas square (Blizzard's projection needs it) and hides top/bottom strips with a mask for its title bar or rectangular style, setting the hit rect insets to the same crop. `GetMinimapShape()` still says `SQUARE` there.
- Minimap mask: `hooksecurefunc(Minimap, "SetMaskTexture")` at file load records the texture (no getter exists); a MaskTexture with it, `SetAllPoints(Minimap)`, goes on every minimap line and casing. Masks set before leSubZones loads are missed, so the geometric clipping (shape, hit-rect crop, `minimapEdge` inset, range) always runs too.
- Lua 5.1: a multi-return call that isn't the last argument is truncated to one value (`f(g(), 0)`).

## Conventions

- Lua: tabs, `local` everything, comments explain *why*. Globals only for `SubzonesDB`, `SubzonesMapToggle`, slash and settings registration.
- Python: 4-space indent, stdlib-first, small functions, a module docstring with usage.
- Settings go in `DEFAULTS` and are exposed in the Settings panel (`RegisterSettings`), the right-click map menu and `/subzones` (alias `/sz`). New options need all three.
- Defaults: style `lines` (tint is opt-in), minimap on.
- The user prefers concise updates. Bump the TOC `## Version` on notable changes.

## Git

GitHub: `addohm/leSubzones` (public, GPLv3 in `LICENSE`), branch `main`. Everything committed is world-readable: no local paths, hostnames or private notes. `.gitignore` covers the global secret patterns, `tools/cache/`, `tools/data/subzones.json` (wowforevermap.com's data; never commit it) and `*.zip` except `releases/*.zip`. Record notable changes in CHANGELOG.md, and keep README/DEPLOY in step with them.
