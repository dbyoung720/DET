@echo off
setlocal enabledelayedexpansion
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -Name Console -Namespace Win32 -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow(); [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'; [Win32.Console]::ShowWindow([Win32.Console]::GetConsoleWindow(), 3)" >nul 2>nul
Color A

:: --- 配置区 ---
set Platform=x64
set "CurrentDIR=%~dp0"
set "LIBYUV_DIR=F:\source\libyuv"  
set "BUILD__DIR=%~dp0vs%Platform%"       
set "INSSDK_DIR=%~dp0_install\%Platform%"       
set "VCPKG_PATH=F:\Green\Language\vcpkg\installed\%Platform%-windows-static"

:: --- VS2026 安装路径 --- 
for %%G in (Community,Professional,Enterprise) do (
  if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\18\%%G" (
    set "VSInstallPath=%ProgramFiles(x86)%\Microsoft Visual Studio\18\%%G"
  )
  if exist "%ProgramFiles%\Microsoft Visual Studio\18\%%G" (
    set "VSInstallPath=%ProgramFiles%\Microsoft Visual Studio\18\%%G"
  )
)

if "%VSInstallPath%"=="" (
  echo "Visual Studio 2026 not found"
  pause & exit /b 1
)

:: --- 初始化 MSVC 环境 ---
call "%VSInstallPath%\VC\Auxiliary\Build\vcvarsall.bat" %Platform%
set "INCLUDE=%VCPKG_PATH%\include;%INCLUDE%"
set "LIB=%VCPKG_PATH%\lib;%VCToolsInstallDir%atlmfc\lib\%VsPlatform%;%LIB%"
set "UseEnv=True"
set "VSCMAKE=Visual Studio 18 2026"
set "Path=%scoop%\shims;%Path%"

:: --- 清理旧构建 ---
if exist "%BUILD__DIR%" rd /s /q "%BUILD__DIR%"

:: --- 打补丁 ---
pushd "%LIBYUV_DIR%"
git apply --ignore-space-change --ignore-whitespace -v %CurrentDIR%libyuv.patch
popd

:: --- CMake 配置 (动态库, x64, Release) ---
cmake -G "%VSCMAKE%" -S "%LIBYUV_DIR%" -B "%BUILD__DIR%" -T CLangCL -A %Platform% -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX="%INSSDK_DIR%" -DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded$<$<CONFIG:Debug>:Debug>"
if errorlevel 1 (
    echo [错误] CMake 配置失败。
    pause & exit /b 1
)

:: --- CMake 编译安装 ---
cmake --build "%BUILD__DIR%" --parallel --config Release --target install
if errorlevel 1 (
    echo [错误] 编译失败。
    pause & exit /b 1
)

:: --- 源代码恢复 ---
pushd "%LIBYUV_DIR%"
git clean -xfd
git checkout .
popd

echo  编译完成！
pause
