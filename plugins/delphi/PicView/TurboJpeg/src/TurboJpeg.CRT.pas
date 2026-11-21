unit TurboJpeg.CRT;

interface

implementation

uses Winapi.Windows, TurboJpeg.Force;

const
  CRTNames: array [0 .. 35] of PAnsiChar =
    (
      'malloc', 'free', 'calloc', 'realloc', 'memcpy', 'memmove', 'memset', 'memcmp', 'memchr', 'strcmp', 'strlen', 'strncpy', 'strrchr', 'strstr',
      '_stricmp', 'qsort', {$IFDEF CPUX86}'_setjmp3'{$ELSE}'setjmp'{$ENDIF}, 'longjmp', 'exit', 'fopen_s', 'fclose', 'feof', 'ferror', 'fflush',
      'fread', 'fwrite', 'fgetc', 'fputc', 'ungetc', 'strerror_s', 'getenv_s', '_putenv_s', nil, nil, nil, '__acrt_iob_func'
    );

var
  CRTHandle: THandle;

procedure InitCRT;
begin
  CRTHandle := LoadLibrary('msvcrt.dll');
  if CRTHandle = 0 then Exit;

  for var i := 0 to High(CRTNames) do
  begin
    if CRTNames[i] <> nil then SetCRTPtr(i, GetProcAddress(CRTHandle, CRTNames[i]));
  end;
end;

initialization
  InitCRT;

end.
