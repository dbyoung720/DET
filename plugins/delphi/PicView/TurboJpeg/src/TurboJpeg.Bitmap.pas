unit TurboJpeg.Bitmap;

interface

uses System.SysUtils, System.Math, System.Classes, Vcl.Graphics, TurboJpeg.Static;

function TjDecodeToBitmap(const Data: TBytes; out Bmp: TBitmap): Boolean;
function TjDecodeToBitmapScaled(const Data: TBytes; MaxWidth, MaxHeight: Integer; out Bmp: TBitmap; out ActualWidth, ActualHeight: Integer): Boolean;
function TjEncodeFromBitmap(Bmp: TBitmap; Quality: Integer; Subsamp: Integer; out Data: TBytes): Boolean;
function TjScanLinePitch(Bmp: TBitmap): Integer;

implementation

type
  TBMPAccess         = class(TBitmap);
  TBitmapImageAccess = class(TBitmapImage);

function TjRowPitch(AWidth: Integer): Integer;
begin
  Result := AWidth * 4;
end;

function TjScanLinePitch(Bmp: TBitmap): Integer;
begin
  if (Bmp = nil) or (Bmp.Width <= 0) then Exit(0);

  Result := TjRowPitch(Bmp.Width);
end;

function TjDIBBase(Bmp: TBitmap): PByte;
begin
  Bmp.ScanLine[0];
  Result := TBitmapImageAccess(TBMPAccess(Bmp).FImage).FDIB.dsBm.bmBits;
end;

procedure TjBlitBuffer(Src, DstBase: PByte; W, H, Pitch: Integer);
var
  y   : Integer;
  s, d: PByte;
begin
  if Int64(H) * Pitch <= MaxInt then
    Move(Src^, DstBase^, H * Pitch)
  else
  begin
    s     := Src;
    d     := DstBase;
    for y := 0 to H - 1 do
    begin
      Move(s^, d^, Pitch);
      Inc(s, Pitch);
      Inc(d, Pitch);
    end;
  end;
end;

function TjDecodeToBitmap(const Data: TBytes; out Bmp: TBitmap): Boolean;
var
  H             : TTjHandle;
  W, ih, Subsamp: Integer;
  Src           : PByte;
  dst           : PByte;
  dstPitch      : Integer;
begin
  Bmp    := nil;
  if Length(Data) = 0 then raise Exception.Create('JPEG data is empty');

  H := tjInitDecompress;
  if H = nil then
    raise Exception.Create('tjInitDecompress failed: ' + TjLastError);
  try
    Src := PByte(@Data[0]);
    if tjDecompressHeader2(H, Src, LongWord(Length(Data)), W, ih, Subsamp) <> 0 then raise Exception.Create('read JPEG header failed: ' + TjLastError);

    dstPitch := TjRowPitch(W);
    GetMem(dst, Int64(dstPitch) * ih);
    try
      if tjDecompress2(H, Src, LongWord(Length(Data)), dst, W, dstPitch, ih, TJPF_BGRA, TJFLAG_BOTTOMUP) <> 0 then raise Exception.Create('JPEG decode failed: ' + TjLastError);

      Bmp := TBitmap.Create;
      try
        Bmp.PixelFormat := pf32bit;
        Bmp.Width       := W;
        Bmp.Height      := ih;
        TjBlitBuffer(dst, TjDIBBase(Bmp), W, ih, dstPitch);
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
    tjDestroy(H);
  end;
end;

procedure TjBoxDownscaleBGRA(Src, dst: PByte; SrcW, SrcH, SrcPitch: Integer; DstW, DstH, dstPitch: Integer);
var
  tx, ty, sx0, sx1, sy0, sy1, sx, sy: Integer;
  sumB, sumG, sumR, cnt             : Cardinal;
  p, q                              : PByte;
begin
  for ty := 0 to DstH - 1 do
  begin
    sy0 := ty * SrcH div DstH;
    sy1 := ((ty + 1) * SrcH + DstH - 1) div DstH;
    if sy1 <= sy0 then sy1  := sy0 + 1;
    q      := dst + NativeInt(ty) * dstPitch;
    for tx := 0 to DstW - 1 do
    begin
      sx0 := tx * SrcW div DstW;
      sx1 := ((tx + 1) * SrcW + DstW - 1) div DstW;
      if sx1 <= sx0 then sx1  := sx0 + 1;
      sumB   := 0;
      sumG   := 0;
      sumR   := 0;
      cnt    := 0;
      for sy := sy0 to sy1 - 1 do
      begin
        p      := Src + NativeInt(sy) * SrcPitch + NativeInt(sx0) * 4;
        for sx := sx0 to sx1 - 1 do
        begin
          Inc(sumB, p[0]);
          Inc(sumG, p[1]);
          Inc(sumR, p[2]);
          Inc(p, 4);
          Inc(cnt);
        end;
      end;
      if cnt > 0 then
      begin
        q[0] := Byte(sumB div cnt);
        q[1] := Byte(sumG div cnt);
        q[2] := Byte(sumR div cnt);
        q[3] := 255;
      end;
      Inc(q, 4);
    end;
  end;
end;

function TjDecodeToBitmapScaled(const Data: TBytes; MaxWidth, MaxHeight: Integer; out Bmp: TBitmap; out ActualWidth, ActualHeight: Integer): Boolean;
var
  H                     : TTjHandle;
  W, ih, Subsamp        : Integer;
  Src, dec, pack        : PByte;
  decPitch, packPitch   : Integer;
  sf, sfi               : PTjScalingFactor;
  nsf, i, dw, dh, tw, th: Integer;
  ratio                 : Double;
begin
  Bmp          := nil;
  ActualWidth  := 0;
  ActualHeight := 0;
  if Length(Data) = 0 then raise Exception.Create('JPEG data is empty');
  if (MaxWidth <= 0) or (MaxHeight <= 0) then raise Exception.Create('Thumbnail size must be positive');

  H := tjInitDecompress;
  if H = nil then raise Exception.Create('tjInitDecompress failed: ' + TjLastError);
  try
    Src := PByte(@Data[0]);
    if tjDecompressHeader2(H, Src, LongWord(Length(Data)), W, ih, Subsamp) <> 0 then raise Exception.Create('read JPEG header failed: ' + TjLastError);

    ratio := MaxWidth / W;
    if MaxHeight / ih < ratio then ratio := MaxHeight / ih;
    if ratio > 1 then ratio := 1;
    tw      := Max(1, Floor(W * ratio + 0.5));
    th      := Max(1, Floor(ih * ratio + 0.5));
    if tw > MaxWidth  then tw := MaxWidth;
    if th > MaxHeight then th := MaxHeight;

    sf    := tjGetScalingFactors(nsf);
    dw    := W;
    dh    := ih;
    for i := nsf - 1 downto 0 do
    begin
      sfi := PTjScalingFactor(NativeInt(sf) + NativeInt(i) * SizeOf(TTjScalingFactor));
      if ((Int64(W) * sfi^.num + sfi^.denom - 1) div sfi^.denom >= tw) and ((Int64(ih) * sfi^.num + sfi^.denom - 1) div sfi^.denom >= th) then
      begin
        dw := (Int64(W) * sfi^.num + sfi^.denom - 1) div sfi^.denom;
        dh := (Int64(ih) * sfi^.num + sfi^.denom - 1) div sfi^.denom;
        Break;
      end;
    end;

    decPitch := TjRowPitch(dw);
    GetMem(dec, Int64(decPitch) * dh);
    try
      if tjDecompress2(H, Src, LongWord(Length(Data)), dec, dw, decPitch, dh, TJPF_BGRA, 0) <> 0 then raise Exception.Create('JPEG scaled decode failed: ' + TjLastError);

      packPitch := TjRowPitch(tw);
      GetMem(pack, Int64(packPitch) * th);
      try
        if (dw = tw) and (dh = th) then
          TjBlitBuffer(dec, pack, tw, th, packPitch)
        else
          TjBoxDownscaleBGRA(dec, pack, dw, dh, decPitch, tw, th, packPitch);

        Bmp := TBitmap.Create;
        try
          Bmp.PixelFormat := pf32bit;
          Bmp.Width       := tw;
          Bmp.Height      := th;
          TjBlitBuffer(pack, TjDIBBase(Bmp), tw, th, packPitch);
          ActualWidth  := tw;
          ActualHeight := th;
          Result       := True;
        except
          Bmp.Free;
          Bmp := nil;
          raise;
        end;
      finally
        FreeMem(pack);
      end;
    finally
      FreeMem(dec);
    end;
  finally
    tjDestroy(H);
  end;
end;

function TjEncodeFromBitmap(Bmp: TBitmap; Quality: Integer; Subsamp: Integer; out Data: TBytes): Boolean;
var
  H       : TTjHandle;
  tmp     : TBitmap;
  srcBmp  : TBitmap;
  outBuf  : PByte;
  outSize : LongWord;
  srcBuf  : PByte;
  SrcPitch: Integer;
  W, ih   : Integer;
begin
  Data   := nil;
  if Bmp = nil then raise Exception.Create('bitmap is nil');
  if (Bmp.Width <= 0) or (Bmp.Height <= 0) then raise Exception.Create('bitmap is empty');

  tmp := nil;
  if Bmp.PixelFormat = pf32bit then
    srcBmp := Bmp
  else
  begin
    tmp := TBitmap.Create;
    try
      tmp.Assign(Bmp);
      tmp.PixelFormat := pf32bit;
      srcBmp          := tmp;
    except
      tmp.Free;
      raise;
    end;
  end;

  H := tjInitCompress;
  if H = nil then
  begin
    tmp.Free;
    raise Exception.Create('tjInitCompress failed: ' + TjLastError);
  end;
  try
    W        := srcBmp.Width;
    ih       := srcBmp.Height;
    SrcPitch := TjRowPitch(W);
    GetMem(srcBuf, Int64(SrcPitch) * ih);
    try
      TjBlitBuffer(TjDIBBase(srcBmp), srcBuf, W, ih, SrcPitch);

      outBuf  := nil;
      outSize := 0;
      if tjCompress2(H, srcBuf, W, SrcPitch, ih, TJPF_BGRA, outBuf, outSize, Subsamp, Quality, TJFLAG_BOTTOMUP) <> 0 then raise Exception.Create('JPEG encode failed: ' + TjLastError);
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
    tjDestroy(H);
    tmp.Free;
  end;
end;

end.
