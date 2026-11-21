# Changelog

All notable changes to leSubzones. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- The world map's **Subzones** checkbox can sit in any corner of the map (bottom-left by default). Pick it under **Map button** in the options panel, **Button position** in the right-click menu, or `/subzones corner <tl|tr|bl|br>`. On the right-hand corners the label sits to the left of the box.
- **Minimap shape** (Auto / Round / Square). Auto keeps reading `GetMinimapShape()`. Round or Square overrides it for UIs that reshape the minimap without defining that function, which left a square minimap's corners empty. Also in the right-click menu and `/subzones shape`.
- **Minimap edge** (0–20 px, default 2): how far inside the minimap's edge the borders stop, for minimaps whose frame covers part of the map. Also in the right-click menu (0/2/5/10/15 px) and `/subzones edge <0-20>`.
- Minimap borders take on the minimap's own mask whenever a minimap addon sets one, so they're trimmed to exactly the shape it shows (round, square, cropped or anything else). `/subzones debug` shows the mask it saw. Masks set before SUBZONES loads can't be seen; the shape and crop clipping still apply then.
- **Minimap range** (25–100% of the minimap's radius) limits the minimap borders to the area around you. Also in the right-click menu (25/50/75/100%) and `/subzones range <25-100>`.

### Changed

- Border data re-extracted from the live WoW: Forever client (`wowf` 1.60.1.70959). The terrain is unchanged from the beta build it came from (1.60.1.70334): every chunk on all three continents matches, so only the build label changes.
- The addon is now **leSubZones** (was SUBZONES): its folder, TOC, title, options panel and chat name. `/subzones` and `/sz` stay. Saved settings live in a file named after the addon folder, so they start from the defaults once. `tools\install_forever.cmd` removes the old `SUBZONES` folder from AddOns, so the two don't both load.
- The repository is now [addohm/leSubzones](https://github.com/addohm/leSubzones) (renamed from SubZones-WoW-Forever; old links redirect).
- `extract_game.py` picks the installed product itself: `wowf` (live WoW: Forever) first, then `wow_classic_beta`. New `tools/extract_forever.cmd` runs it on the Windows PC with the game and pushes only `tools/data/game_areas.json`, so the borders can be rebuilt from it here.
- `/subzones debug` also reports the minimap (size, screen position, scale, shape setting and the shape minimap addons report, zoom, lines drawn) and the world map layer the overlay is on.
- `tools/install_beta.cmd` is replaced by `tools/install_forever.cmd`, the same install script as the other Forever addons. It installs into the live `_forever_` client by default (`WOW` at the top), runs from a temporary copy so a pull can update it, explains how to recover when GitHub's history was rewritten, marks builds with uncommitted changes `-dirty`, packs `SUBZONES-<version>.zip` on the desktop and says when the game needs a full restart instead of `/reload`.

### Fixed

- With map art addons such as OpenMap, the borders and names were hidden under the map art. SUBZONES now adds its own layer to the world map's pin frame levels, above all map art and below the icons.
- On EllesmereUI's square minimap with a title bar (and its rectangular one), minimap borders ran past the shown map onto the title bar and below the frame. SUBZONES now reads the hidden top and bottom strips from the minimap's hit rect insets, which EllesmereUI sets to its crop, and clips to the part that's shown. `/subzones debug` lists them as hidden edges.
- The minimap now redraws when a minimap addon changes its reported shape.

## [1.0.0] - 2026-10-23

First public release, for CurseForge and Wago.

### Added

- SUBZONES addon for WoW Forever (TOC 16001). It draws subzone borders and names on the world map, with optional color fills (styles: Lines only, Lines + tint, Tint only).
- Subzone borders on the minimap for your current zone. They're clipped to round or square minimaps and turn with Rotate Minimap.
- Options panel under Settings → AddOns → SUBZONES, a right-click menu on the world map's **Subzones** checkbox, and `/subzones` (`/sz`) commands.
- Border data extracted from the game's own terrain files (per-chunk area IDs), covering Eastern Kingdoms, Kalimdor and Zephras Isle.
- Data tools: a CASC reader with Blizzard CDN fallback (`casc.py`), terrain extraction (`extract_game.py`), border generation (`build_borders.py`) and a comparison against wowforevermap.com (`compare.py`). The comparison shows 99.95% of chunks match.
- `/subzones debug` shows the addon version and installed build.
- The logo as the addon's icon in the AddOns list (`icon.tga`).
- Release tooling: `tools/package.py` builds `releases/SUBZONES-<version>.zip`, and `tools/install_beta.cmd` pulls from GitHub and installs into the beta client, stamping the commit into `Build.lua`.
- CurseForge / Wago listing copy in `LISTING.md`, and logos and a banner in `art/`.
- `Author`, `X-License` and `X-Website` fields in the TOC.
- Licensed under GPLv3 (`LICENSE`, also packed into the release zip). The repository is public.
- Standard docs: README, CLAUDE, CHANGELOG, DEPLOY and SECURITY.

### Fixed

- The world map froze and the client crashed when opening continent maps. Subzones are now drawn only on zone-level maps, with a per-map safety cap.
- Kalimdor and Eastern Kingdoms zones showed no subzones. Map ownership now uses the continent map's own hover lookup.
