@echo off
setlocal enabledelayedexpansion
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -Name Console -Namespace Win32 -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow(); [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'; [Win32.Console]::ShowWindow([Win32.Console]::GetConsoleWindow(), 3)" >nul 2>nul

set "CurrentCD=%~dp0"
Color A

set "REG_KEY=HKEY_CURRENT_USER\SOFTWARE\Embarcadero\BDS\37.0"
set "REG_VUE=App"
set "bdsPath="
for /F "tokens=2*" %%A in ('reg query "%REG_KEY%" /v "%REG_VUE%" 2^>nul') do ( set "bdsPath=%%B" )
if not defined bdsPath (
    echo 未找到 Delphi 13.2 安装路径
    pause
    exit /b 1
)

:: Delphi 13.2 安装路径
for %%I in ("!bdsPath!") do ( set "DelphiPath=%%~dpI" )
if "!DelphiPath:~-1!"=="\" set "DelphiPath=!DelphiPath:~0,-1!"

:: 将 Delphi bin 加入 PATH
set "Path=!DelphiPath!;!Path!"

set "RSVARS_PATH=!DelphiPath!\rsvars.bat"
if not exist "!RSVARS_PATH!" (
    echo 未找到 rsvars.bat：!RSVARS_PATH!
    pause
    exit /b 1
)

:: 切换到脚本所在目录
pushd "!CurrentCD!"

:: 设置项目组文件名和输出日志目录
set "GROUP_PROJ=!CurrentCD!All.groupproj"
set "LOG_DIR=!CurrentCD!"

:: 调用 rsvars.bat 设置编译环境
echo Initializing Delphi environment...
call "!RSVARS_PATH!"
if errorlevel 1 (
    echo [ERROR] 初始化 Delphi 环境失败。
    popd
    pause
    exit /b 1
)

:: 编译 Win32 Release
echo.
echo ==================================================
echo Building Win32 Release...
echo ==================================================
msbuild "!GROUP_PROJ!" /t:Build /p:Config=Release /p:Platform=Win32 /p:DCC_UseMSBuildExternally=true "/l:FileLogger,Microsoft.Build.Engine;logfile=!LOG_DIR!Win32_Release.log;verbosity:minimal"

if errorlevel 1 (
    echo [ERROR] Win32 Release build failed. Check log: !LOG_DIR!Win32_Release.log
    popd
    pause
    exit /b 1
)
echo Win32 Release build succeeded.

:: 编译 Win64 Release
echo.
echo ==================================================
echo Building Win64 Release...
echo ==================================================
msbuild "!GROUP_PROJ!" /t:Build /p:Config=Release /p:Platform=Win64 /p:DCC_UseMSBuildExternally=true "/l:FileLogger,Microsoft.Build.Engine;logfile=!LOG_DIR!Win64_Release.log;verbosity:minimal"

if errorlevel 1 (
    echo [ERROR] Win64 Release build failed. Check log: !LOG_DIR!Win64_Release.log
    popd
    pause
    exit /b 1
)
echo Win64 Release build succeeded.

echo.
echo ==================================================
echo All builds completed successfully.
echo ==================================================
popd

pause
endlocal
