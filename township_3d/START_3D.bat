@echo off
cd /d "%~dp0"
echo ========================================
echo   TOOLVAULT 3D TOWNSHIP DEMO
 echo ========================================
echo Open http://localhost:5500 after it starts.
echo.
where dart >nul 2>nul
if not errorlevel 1 (
  dart run serve.dart
  goto :end
)
where py >nul 2>nul
if not errorlevel 1 (
  py -3 server.py
  goto :end
)
where python >nul 2>nul
if not errorlevel 1 (
  python server.py
  goto :end
)
echo Dart and Python cannot be found.
echo Start in a fresh VS Code terminal after installing Flutter.
echo Or use VS Code Live Server to open index.html.
pause
:end
