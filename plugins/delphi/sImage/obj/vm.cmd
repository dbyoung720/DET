@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
COLOR A

:: VS2022 °²×°Â·¾¶
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
  exit /b
)

call "%VSInstallPath%\Common7\Tools\vsdevcmd.bat" -no_logo -arch=x86

cl /O2 /D "_UNICODE" /D "UNICODE" /MT /GS- /W0 /nologo /c /Zi /TC vm.c

pause
