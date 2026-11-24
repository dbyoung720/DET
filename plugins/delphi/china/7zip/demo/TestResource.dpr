program TestResource;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes, Winapi.Windows, SevenZip.Static;

{ Load an RCDATA resource from a DLL into a memory stream. }
function LoadRcDataToStream(const ADll, AResName: string): TMemoryStream;
var
  hMod: HMODULE;
  hRes: HRSRC;
  hGlob: HGLOBAL;
  Ptr: Pointer;
  Size: DWORD;
begin
  Result := TMemoryStream.Create;
  hMod := LoadLibraryEx(PChar(ADll), 0, LOAD_LIBRARY_AS_DATAFILE);
  if hMod = 0 then raise Exception.CreateFmt('LoadLibraryEx failed: %s (err=%d)', [ADll, GetLastError]);
  try
    hRes := FindResource(hMod, PChar(AResName), RT_RCDATA);
    if hRes = 0 then raise Exception.CreateFmt('FindResource(%s) failed: err=%d', [AResName, GetLastError]);
    Size := SizeofResource(hMod, hRes);
    hGlob := LoadResource(hMod, hRes);
    if hGlob = 0 then raise Exception.Create('LoadResource failed');
    Ptr := LockResource(hGlob);
    if Ptr = nil then raise Exception.Create('LockResource failed');
    Result.WriteBuffer(Ptr^, Size);
    Result.Position := 0;
    Writeln(Format('  resource "%s" loaded: %d bytes', [AResName, Size]));
  finally
    FreeLibrary(hMod);
  end;
end;

var
  DllPath: string;
  Mem: TMemoryStream;
  Bytes, Data: TBytes;
  Arc: T7zArchive;
  I: Integer;
begin
  try
    if ParamCount < 1 then
      DllPath := 'F:\Source\7zip\DelphiStatic\china.dll'
    else
      DllPath := ParamStr(1);

    Writeln('Loading 7z from RCDATA resource of: ', DllPath);
    Mem := LoadRcDataToStream(DllPath, 'CHINA');
    try
      SetLength(Bytes, Mem.Size);
      if Mem.Size > 0 then
      begin
        Mem.Position := 0;
        Mem.ReadBuffer(Bytes[0], Mem.Size);
      end;
    finally
      Mem.Free;
    end;
    Writeln(Format('  memory stream: %d bytes', [Length(Bytes)]));

    Arc := T7zArchive.Create(Bytes);
    try
      Writeln(Format('7z opened OK, entries=%d', [Arc.Count]));
      for I := 0 to Arc.Count - 1 do
      begin
        Writeln(Format('  [%d] %s  size=%d  dir=%s', [I, Arc.Name(I), Arc.Size(I), BoolToStr(Arc.IsDir(I), True)]));
        if not Arc.IsDir(I) then
        begin
          Data := Arc.Extract(I);
          Writeln(Format('       extracted %d bytes, crc32=%.8x', [Length(Data), Crc32Of(Data)]));
        end;
      end;
    finally
      Arc.Free;
    end;
    Writeln('RESOURCE EXTRACT TEST PASSED');
  except
    on E: Exception do
    begin
      Writeln('FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.
