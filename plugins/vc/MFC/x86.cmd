@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -Name Console -Namespace Win32 -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow(); [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'; [Win32.Console]::ShowWindow([Win32.Console]::GetConsoleWindow(), 3)" >nul 2>nul
setlocal enabledelayedexpansion
color A

set CurrentCD=%~dp0

:: VS2022 安装路径
for %%G in (Community,Professional,Enterprise) do (
  if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\%%G" (
    set "VSInstallPath=%ProgramFiles(x86)%\Microsoft Visual Studio\2022\%%G"
  )
  if exist "%ProgramFiles%\Microsoft Visual Studio\2022\%%G" (
    set "VSInstallPath=%ProgramFiles%\Microsoft Visual Studio\2022\%%G"
  )
)

if "%VSInstallPath%"=="" (
  echo "Visual Studio 2022 not found"
  pause
  exit /b 1
)

call "%VSInstallPath%\Common7\Tools\vsdevcmd.bat" -no_logo -arch=x86

CD /D %CurrentCD%exe

:: 打补丁
call git apply --ignore-space-change --ignore-whitespace -v ..\dll.patch

:: 编译
MSBuild.exe MFC01.sln /nologo /consoleloggerparameters:Verbosity=minimal /maxcpucount:16 /nodeReuse:true^
	/target:Build /property:Configuration=Release;Platform=x86

:: 清除
git clean -xfd
git checkout .
pause
