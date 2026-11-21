unit TurboJpeg.Bitmap;

interface

uses System.SysUtils, System.Classes, Vcl.Graphics, TurboJpeg.Static;

function TjDecodeToBitmap(const Data: TBytes; out Bmp: TBitmap): Boolean;
function TjDecodeToBitmapScaled(const Data: TBytes; MaxWidth, MaxHeight: Integer; out Bmp: TBitmap; out ActualWidth, ActualHeight: Integer): Boolean;
function TjEncodeFromBitmap(Bmp: TBitmap; Quality: Integer; Subsamp: Integer; out Data: TBytes): Boolean;
function TjScanLinePitch(Bmp: TBitmap): Integer;

implementation

function TjRowPitch(AWidth: Integer): Integer;
begin
  Result := (AWidth * 3 + 3) and not 3;
end;

function TjScanLinePitch(Bmp: TBitmap): Integer;
begin
  if (Bmp = nil) or (Bmp.Width <= 0) then Exit(0);

  Result := TjRowPitch(Bmp.Width);
end;

type
  TBMPAccess         = class(TBitmap);
  TBitmapImageAccess = class(TBitmapImage);

function TjDecodeToBitmap(const Data: TBytes; out Bmp: TBitmap): Boolean;
var
  h                 : TTjHandle;
  w, ih, Subsamp    : Integer;
  src               : PByte;
  dst               : PByte;
  rowPitch, dstPitch: Integer;
begin
  Bmp := nil;
  if Length(Data) = 0 then raise Exception.Create('JPEG data is empty');

  h := tjInitDecompress;
  if h = nil then raise Exception.Create('tjInitDecompress failed: ' + TjLastError);
  try
    src := PByte(@Data[0]);
    if tjDecompressHeader2(h, src, LongWord(Length(Data)), w, ih, Subsamp) <> 0 then raise Exception.Create('read JPEG header failed: ' + TjLastError);

    //rowPitch := TjRowPitch(w);
    rowPitch := w * 4;
    dstPitch := rowPitch;
    GetMem(dst, dstPitch * ih);
    try
      if tjDecompress2(h, src, LongWord(Length(Data)), dst, w, dstPitch, ih, TJPF_BGRA, TJFLAG_BOTTOMUP) <> 0 then raise Exception.Create('JPEG decode failed: ' + TjLastError);

      Bmp := TBitmap.Create;
      try
        Bmp.PixelFormat := pf32bit;
        Bmp.Width       := w;
        Bmp.Height      := ih;
        Move(dst^, TBitmapImageAccess(TBMPAccess(bmp).FImage).FDIB.dsBm.bmBits^, w * ih * 4);
        Result := True;
      except
        Bmp.Free;
        Bmp := nil;
        raise;
      end;
    finally
      FreeMem(dst);
    end;
  finally
    tjDestroy(h);
  end;
end;

function TjDecodeToBitmapScaled(const Data: TBytes; MaxWidth, MaxHeight: Integer; out Bmp: TBitmap; out ActualWidth, ActualHeight: Integer): Boolean;
var
  h             : TTjHandle;
  w, ih, Subsamp: Integer;
  src, dst      : PByte;
  dstPitch      : Integer;
  sf, sfi       : PTjScalingFactor;
  nsf, i, sw, sh: Integer;
begin
  Bmp          := nil;
  ActualWidth  := 0;
  ActualHeight := 0;
  if Length(Data) = 0 then raise Exception.Create('JPEG data is empty');

  h := tjInitDecompress;
  if h = nil then raise Exception.Create('tjInitDecompress failed: ' + TjLastError);
  try
    src := PByte(@Data[0]);
    if tjDecompressHeader2(h, src, LongWord(Length(Data)), w, ih, Subsamp) <> 0 then raise Exception.Create('read JPEG header failed: ' + TjLastError);

    sf    := tjGetScalingFactors(nsf);
    sw    := w;
    sh    := ih;
    for i := 0 to nsf - 1 do
    begin
      sfi := PTjScalingFactor(NativeInt(sf) + NativeInt(i) * SizeOf(TTjScalingFactor));
      if ((Int64(w) * sfi^.num + sfi^.denom - 1) div sfi^.denom <= MaxWidth) and ((Int64(ih) * sfi^.num + sfi^.denom - 1) div sfi^.denom <= MaxHeight) then
      begin
        sw := (Int64(w)  * sfi^.num + sfi^.denom - 1) div sfi^.denom;
        sh := (Int64(ih) * sfi^.num + sfi^.denom - 1) div sfi^.denom;
        Break;
      end;
    end;

    ActualWidth  := sw;
    ActualHeight := sh;
    dstPitch     := sw * 4;// TjRowPitch(sw);
    GetMem(dst, dstPitch * sh);
    try
      if tjDecompress2(h, src, LongWord(Length(Data)), dst, sw, dstPitch, sh, TJPF_BGRA, 0) <> 0 then raise Exception.Create('JPEG scaled decode failed: ' + TjLastError);

      Bmp := TBitmap.Create;
      try
        Bmp.PixelFormat := pf32bit;
        Bmp.Width       := sw;
        Bmp.Height      := sh;
        Move(dst^, TBitmapImageAccess(TBMPAccess(bmp).FImage).FDIB.dsBm.bmBits^, sw * sh * 4);
        Result := True;
      except
        Bmp.Free;
        Bmp := nil;
        raise;
      end;
    finally
      FreeMem(dst);
    end;
  finally
    tjDestroy(h);
  end;
end;

function TjEncodeFromBitmap(Bmp: TBitmap; Quality: Integer; Subsamp: Integer; out Data: TBytes): Boolean;
var
  h         : TTjHandle;
  tmp       : TBitmap;
  srcBmp    : TBitmap;
  outBuf    : PByte;
  outSize   : LongWord;
  srcBuf    : PByte;
  srcPitch  : Integer;
  y         : Integer;
  sRow, dRow: PByte;
  w, ih     : Integer;
begin
  Data := nil;
  if Bmp = nil then raise Exception.Create('bitmap is nil');

  tmp := nil;
  if Bmp.PixelFormat = pf24bit then
    srcBmp := Bmp
  else
  begin
    tmp := TBitmap.Create;
    try
      tmp.Assign(Bmp);
      tmp.PixelFormat := pf24bit;
      srcBmp          := tmp;
    except
      tmp.Free;
      raise;
    end;
  end;

  h := tjInitCompress;
  if h = nil then
  begin
    tmp.Free;
    raise Exception.Create('tjInitCompress failed: ' + TjLastError);
  end;
  try
    w        := srcBmp.Width;
    ih       := srcBmp.Height;
    srcPitch := TjRowPitch(w);
    GetMem(srcBuf, srcPitch * ih);
    try
      for y := 0 to ih - 1 do
      begin
        sRow := srcBmp.ScanLine[y];
        dRow := srcBuf + NativeInt(y) * srcPitch;
        Move(sRow^, dRow^, w * 3);
      end;

      outBuf  := nil;
      outSize := 0;
      if tjCompress2(h, srcBuf, w, srcPitch, ih, TJPF_BGR, outBuf, outSize, Subsamp, Quality, 0) <> 0 then raise Exception.Create('JPEG encode failed: ' + TjLastError);
      try
        SetLength(Data, outSize);
        if outSize > 0 then Move(outBuf^, Data[0], outSize);
        Result := True;
      finally
        tjFree(outBuf);
      end;
    finally
      FreeMem(srcBuf);
    end;
  finally
    tjDestroy(h);
    tmp.Free;
  end;
end;

end.
