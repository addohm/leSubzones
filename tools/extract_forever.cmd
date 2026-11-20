@echo off
rem Read the subzone data out of your WoW: Forever client and send it to GitHub: extracts every
rem terrain chunk's area ID into tools\data\game_areas.json (about 2 MB), then commits and pushes
rem only that file. The border data the addon draws is rebuilt from it afterwards. Run it from a
rem terminal (from any folder) after a game patch. The first run takes about 6 minutes.
rem Needs Python 3 (python.org) and a GitHub login that can push to the repo.
setlocal

rem git pull can update this very file, and cmd reads a running script from disk line by line, so
rem the script runs from a temporary copy. The original folder is passed along as the second argument.
if not "%~1"=="--copy" (
  copy /y "%~f0" "%TEMP%\subzones_extract.cmd" >nul
  call "%TEMP%\subzones_extract.cmd" --copy "%~dp0"
  exit /b
)

rem The repo is the folder above this script's tools folder.
for %%i in ("%~2..") do set "REPO=%%~fi"
rem The World of Warcraft folder itself (not _forever_): the client's files are shared from there.
set "WOWROOT=C:\Program Files (x86)\World of Warcraft"
set "OUT=tools/data/game_areas.json"
set "RESULT=0"

if not exist "%WOWROOT%\.build.info" (
  echo Can't find a WoW install at "%WOWROOT%". Fix WOWROOT at the top of this script.
  set "RESULT=1"
  goto done
)
set "PY="
where py >nul 2>&1 && set "PY=py -3"
if not defined PY where python >nul 2>&1 && set "PY=python"
if not defined PY (
  echo Python 3 isn't installed. Get it from https://www.python.org/downloads/ and run this again.
  set "RESULT=1"
  goto done
)

git -C "%REPO%" pull --ff-only
if errorlevel 1 (
  echo git pull failed, so nothing was extracted. Run tools\install_forever.cmd: it explains why.
  set "RESULT=1"
  goto done
)

rem wowforevermap.com's subzones (not committed) tell the script which map is Zephras Isle.
if not exist "%REPO%\tools\data\subzones.json" (
  curl -s -f -o "%REPO%\tools\data\subzones.json" https://wowforevermap.com/subzones.json
  if errorlevel 1 echo Couldn't download wowforevermap.com's subzones; Zephras Isle may be skipped.
)

%PY% "%REPO%\tools\extract_game.py" --wow-dir "%WOWROOT%"
if errorlevel 1 (
  echo The extraction failed; nothing was sent. Copy the messages above into the chat.
  set "RESULT=1"
  goto done
)

git -C "%REPO%" diff --quiet -- %OUT%
if not errorlevel 1 (
  echo The data hasn't changed since the last extraction: nothing to send.
  goto done
)
git -C "%REPO%" commit -q -m "Extract terrain areas from the WoW: Forever client" -- %OUT%
if errorlevel 1 (
  echo Couldn't commit. If git asks who you are, set your name and email:
  echo   git config --global user.name "Your Name"
  echo   git config --global user.email "you@example.com"
  set "RESULT=1"
  goto done
)
git -C "%REPO%" push -q
if errorlevel 1 (
  echo Couldn't push. Are you signed in to GitHub on this PC? The commit is kept: run
  echo   git -C "%REPO%" push
  echo once you are.
  set "RESULT=1"
  goto done
)
echo Sent %OUT% to GitHub. The borders are rebuilt from it next.

:done
exit /b %RESULT%
