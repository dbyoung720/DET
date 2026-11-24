program Test7zOpen;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes, SevenZip.Static;

var
  Bytes, Data: TBytes;
  Arc: T7zArchive;
  Stream: TFileStream;
  I: Integer;
begin
  try
    Stream := TFileStream.Create(ParamStr(1), fmOpenRead);
    try
      SetLength(Bytes, Stream.Size);
      if Stream.Size > 0 then  Stream.ReadBuffer(Bytes[0], Stream.Size);
    finally
      Stream.Free;
    end;

    Arc := T7zArchive.Create(Bytes);
    try
      Writeln(Format('7z opened OK, entries=%d', [Arc.Count]));
      for I := 0 to Arc.Count - 1 do
      begin
        Writeln(Format('  [%d] %s  size=%d  dir=%s', [I, Arc.Name(I), Arc.Size(I), BoolToStr(Arc.IsDir(I), True)]));
        if (not Arc.IsDir(I)) and (I = 0) then
        begin
          Data := Arc.Extract(I);
          Writeln(Format('       extracted %d bytes, crc32=%.8x', [Length(Data), Crc32Of(Data)]));
        end;
      end;
    finally
      Arc.Free;
    end;
    Writeln('7Z EXTRACT TEST PASSED');
  except
    on E: Exception do
    begin
      Writeln('FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.
