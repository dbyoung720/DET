program Test7zStatic;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes, SevenZip.Static;

var
  Src, Dest, Props, Back: TBytes;
  S: string;
  I: Integer;
  Crc: Cardinal;
begin
  Writeln('7-Zip version: ', SevenZipVersion);
  try
    { CRC32 已知向量: "123456789" = 0xCBF43926 }
    S := '123456789';
    Crc := Crc32Of(TEncoding.ASCII.GetBytes(S));
    Writeln(Format('CRC32("123456789") = %.8x (expect cbf43926)', [Crc]));
    if Crc <> $CBF43926 then raise Exception.Create('CRC32 test FAILED');

    { LZMA 往返 }
    S := '';
    for I := 1 to 500 do S := S + 'The quick brown fox jumps over the lazy dog 0123456789 ';
    Src := TEncoding.UTF8.GetBytes(S);
    LzmaCompress(Src, 6, Dest, Props);
    Back := LzmaDecompress(Dest, Props, Length(Src));
    Writeln(Format('LZMA roundtrip: %d -> %d bytes, match=%s', [Length(Src), Length(Dest), BoolToStr(CompareMem(@Src[0], @Back[0], Length(Src)), True)]));
    if not CompareMem(@Src[0], @Back[0], Length(Src)) then raise Exception.Create('LZMA roundtrip FAILED');

    Writeln('ALL TESTS PASSED');
  except
    on E: Exception do
    begin
      Writeln('FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.
