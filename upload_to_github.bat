@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

set "REMOTE_URL=git@github.com:Cu-One/EEE109Lab2report.git"
set "DEFAULT_BRANCH=main"

if "%~1"=="" (
    set "COMMIT_MESSAGE=Auto update %date% %time%"
) else (
    set "COMMIT_MESSAGE=%*"
)

where git >nul 2>nul
if errorlevel 1 (
    echo Git is not installed or not in PATH.
    exit /b 1
)

for /f "delims=" %%i in ('git config --get user.name 2^>nul') do set "GIT_USER_NAME=%%i"
for /f "delims=" %%i in ('git config --get user.email 2^>nul') do set "GIT_USER_EMAIL=%%i"
if not defined GIT_USER_NAME (
    echo Git user.name is not set.
    echo Run: git config --global user.name "Your Name"
    exit /b 1
)
if not defined GIT_USER_EMAIL (
    echo Git user.email is not set.
    echo Run: git config --global user.email "you@example.com"
    exit /b 1
)

git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo Initializing git repository...
    git init
    if errorlevel 1 exit /b 1
)

for /f "delims=" %%i in ('git remote get-url origin 2^>nul') do set "CURRENT_REMOTE=%%i"
if not defined CURRENT_REMOTE (
    echo Adding origin remote...
    git remote add origin "%REMOTE_URL%"
) else (
    if /I not "!CURRENT_REMOTE!"=="%REMOTE_URL%" (
        echo Updating origin remote...
        git remote set-url origin "%REMOTE_URL%"
    )
)
if errorlevel 1 exit /b 1

git symbolic-ref --quiet --short HEAD >nul 2>nul
if errorlevel 1 (
    echo Switching to %DEFAULT_BRANCH%...
    git checkout -B %DEFAULT_BRANCH%
) else (
    for /f "delims=" %%i in ('git branch --show-current') do set "CURRENT_BRANCH=%%i"
    if /I not "!CURRENT_BRANCH!"=="%DEFAULT_BRANCH%" (
        echo Switching to %DEFAULT_BRANCH%...
        git checkout -B %DEFAULT_BRANCH%
    )
)
if errorlevel 1 exit /b 1

echo Staging files...
git add -A
if errorlevel 1 exit /b 1

git diff --cached --quiet
if errorlevel 1 (
    echo Creating commit...
    git commit -m "%COMMIT_MESSAGE%"
    if errorlevel 1 exit /b 1
) else (
    echo No staged changes to commit.
)

echo Pushing to origin/%DEFAULT_BRANCH%...
git push -u origin %DEFAULT_BRANCH%
if errorlevel 1 (
    echo Push failed. Check SSH authentication, remote permissions, or whether the remote already has conflicting history.
    exit /b 1
)

echo Remote repository updated.
exit /b 0
