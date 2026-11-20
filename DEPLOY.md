# Deploying leSubzones

leSubZones is a client-side WoW addon. There's no server: "deploying" means copying the addon folder into the game's AddOns folder.

## First-time setup

1. Clone the repo anywhere: `git clone https://github.com/addohm/leSubzones.git`.
2. Open `tools\install_forever.cmd` and check `WOW` at the top: it's the client folder, by default `C:\Program Files (x86)\World of Warcraft\_forever_`, the live game. Change it for another install (for example `_classic_beta_`).
3. Run `tools\install_forever.cmd` from a terminal, then start the game and make sure **leSubZones** is enabled in the AddOns list.

   To install by hand instead, copy the `leSubZones` folder (not the repo root) into `<WoW>\_forever_\Interface\AddOns\`.

4. Check it on a zone map: `/subzones debug` reports the subzone count, data source, the minimap's size and shape, the map layer, version and build (the commit the script installed, or `release` for a zip install).

Only `leSubZones.toc`, `Build.lua`, `leSubZones.lua`, `SubzoneBorders.lua` and `icon.tga` are needed. Everything in `tools/` is for regenerating data.

## Shipping a change

1. Edit `leSubZones/leSubZones.lua`. Never hand-edit `SubzoneBorders.lua`; it's generated.
2. Push, run `tools\install_forever.cmd`, then `/reload` (or restart the game if it says so) and test. The script only installs what's on GitHub.
3. Bump `## Version` in `leSubZones.toc` and add a CHANGELOG entry.
4. Run `python tools/package.py` to build `releases/leSubZones-<version>.zip`. That zip is what gets uploaded to CurseForge and Wago.
5. Commit and push, including the new zip.

## The install script

`tools\install_forever.cmd` (the same script as the other Forever addons) does, in order:

- `git pull --ff-only` (it only gets what's pushed, so push first). The pull can update the script itself, so it runs from a copy in `%TEMP%`. If the pull fails because GitHub's history was rewritten (this copy's last commit isn't in it any more), it says so and prints the two commands that move the copy onto GitHub's: `git fetch origin --tags --force` and `git reset --hard origin/main` (they throw away commits and edits made only in the copy).
- Mirrors `leSubZones\` into `<WOW>\Interface\AddOns\leSubZones\` (`robocopy /MIR`), creating it on the first run. If `WOW` itself doesn't exist it stops, since the path is probably wrong.
- Writes the commit into the installed `leSubZones\Build.lua`, so `/subzones debug` shows it as the build. "-dirty" means the copy included uncommitted changes.
- Packs `leSubZones-<version>.zip` on the desktop: `git archive` of the committed addon, without the build stamp. It's handy for sharing; the CurseForge / Wago zip still comes from `tools/package.py`.
- Says whether `/reload` is enough. WoW reads an addon's file list only when the game starts, so when `leSubZones.toc` changed you must restart the game.

If creating or copying fails, the WoW folder may need the script to run as administrator. The script needs CRLF line endings to run reliably; `.gitattributes` makes git check it out that way.

To roll back, check out the previous commit's `leSubZones/` folder and copy it in again.

## Updating border data after a game patch

Requires Python 3. Pillow is needed only for `compare.py`'s images.

The easy way, on the Windows PC with the game: run `tools\extract_forever.cmd` from a terminal. It pulls, downloads wowforevermap.com's subzones if they're missing (used only to recognise Zephras Isle), runs `extract_game.py` against the installed client, then commits and pushes only `tools/data/game_areas.json` (about 2 MB; plain git, no LFS needed). `build_borders.py` is then run from that file, anywhere, and the new `SubzoneBorders.lua` committed. `WOWROOT` at the top of the script is the World of Warcraft folder itself, not `_forever_`. Pushing needs a GitHub login with write access on that PC.

By hand:

```
python tools/extract_game.py      # reads the installed client; fetches missing files from Blizzard's CDN
python tools/build_borders.py     # writes leSubZones/SubzoneBorders.lua
```

The first extraction takes about 6 minutes. CDN downloads are cached in `tools/cache/`, which isn't committed. The product is picked from `.build.info`: `wowf` (live WoW: Forever), else `wow_classic_beta`. Use `--product` to pick another, and `--wdt ID=FDID` for a continent that isn't identified automatically.

To re-run the comparison, first download the site's data to `tools/data/subzones.json` (also not committed):

```
curl -o tools/data/subzones.json https://wowforevermap.com/subzones.json
python tools/compare.py
```

## Configuration

There's nothing to configure for deployment. Player settings are saved by the game in the `SubzonesDB` SavedVariable.
