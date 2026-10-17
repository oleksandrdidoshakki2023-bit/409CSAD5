@echo off
setlocal EnableExtensions EnableDelayedExpansion

where mvn >nul 2>nul
if not errorlevel 1 (
    call mvn -B clean verify
    exit /b !ERRORLEVEL!
)

if defined MAVEN_HOME if exist "%MAVEN_HOME%\bin\mvn.cmd" set "MAVEN_CMD=%MAVEN_HOME%\bin\mvn.cmd"

if not defined MAVEN_CMD if defined ProgramFiles call :find_idea_maven "%ProgramFiles%\JetBrains"
if not defined MAVEN_CMD if defined ProgramFiles(x86) call :find_idea_maven "%ProgramFiles(x86)%\JetBrains"
if not defined MAVEN_CMD if defined LOCALAPPDATA call :find_idea_maven "%LOCALAPPDATA%\Programs\JetBrains"

if not defined MAVEN_CMD (
    echo Maven was not found. Install Maven and add it to PATH, or set MAVEN_HOME to its installation directory.
    exit /b 1
)

call "!MAVEN_CMD!" -B clean verify
exit /b !ERRORLEVEL!

:find_idea_maven
for /d %%I in ("%~1\IntelliJ IDEA*") do (
    for /d %%M in ("%%~I\plugins\maven\lib\maven*") do (
        if not defined MAVEN_CMD if exist "%%~M\bin\mvn.cmd" set "MAVEN_CMD=%%~M\bin\mvn.cmd"
    )
)
exit /b 0