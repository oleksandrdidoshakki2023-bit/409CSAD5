@echo off
setlocal

call mvn -B clean verify
exit /b %ERRORLEVEL%