@echo off
..\bin\nesasm3 sprites.asm
if %errorlevel% neq 0 exit /b %errorlevel%
start sprites.nes
pause
