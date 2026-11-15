unit YUV2RGB;
{
  P010LE 10bit Limited BT.601 YUV420 转 RGB; 替换 FFMPEG 中的 sws_scale 函数，测试解码效率；
  Y取值范围： 0 --- 1023
  U取值范围： 0 --- 858
  V取值范围： 0 --- 930
}

interface

uses Winapi.Windows, System.Threading;

{ 一次读取 2 个像素 }
procedure YUV420P010LEToRGB32_2Pixel_ONE(ySrc: PByte; yStride: Integer; uvSrc: PByte; uvStride: Integer; pBits: PDWORD; const iWidth, iHeight: Integer);
procedure YUV420P010LEToRGB32_2Pixel_TWO(ySrc: PByte; yStride: Integer; uvSrc: PByte; uvStride: Integer; pBits: PDWORD; const iWidth, iHeight: Integer);

{ 一次读取 8 个像素 }
procedure YUV420P010LEToRGB32_8Pixel(ySrc: PByte; yStride: Integer; uvSrc: PByte; uvStride: Integer; pBits: PDWORD; const iWidth, iHeight: Integer);

implementation

{$I YUV2RGB.INC}

const
  SCALE_OFFSET = 512;

type
  PArr8W  = ^TArr8W;
  TArr8W  = array[0 .. 7]  of WORD;

function clamp(Val : Single; min, max : Byte) : Byte; inline;
begin
  if Val < min then
    Result := 0
  else if Val > max then
    Result := 255
  else
    Result := Round(Val);
end;

{ YUV TO RGB 浮点数版本 }
procedure YUV2RGB_Float(Y, U, V: Integer; dstPtr : PDWORD); inline;
var
  CY, CU, CV : Integer;
  Rm, Gm, Bm : Single;
  R, G, B    : Integer;
begin
  CY := Y - 64;
  CU := U - 512;
  CV := V - 512;

  Rm := 1.164 * CY + 00000 * CU + 1.596 * CV;
  Gm := 1.164 * CY - 0.391 * CU - 0.813 * CV;
  Bm := 1.164 * CY + 2.018 * CU + 00000 * CV;

  R := clamp(Rm * 255 / 1023, 0, 255);
  G := clamp(Gm * 255 / 1023, 0, 255);
  B := clamp(Bm * 255 / 1023, 0, 255);

  dstPtr^ := (B or (G shl 8) or (R shl 16) or ($FF shl 24));
end;

{ YUV TO RGB 定点优化版本 }
procedure YUV2RGB_Integer(Y, U, V: Integer; dstPtr : PDWORD); inline;
var
  CY, CU, CV : Integer;
  R, G, B    : Integer;
begin
  CY := Y - 64;
  CU := U - 512;
  CV := V - 512;

  R := (298 * CY + 000 * CU + 409 * CV + 128) div 256;
  G := (298 * CY - 100 * CU - 208 * CV + 128) div 256;
  B := (298 * CY + 516 * CU + 000 + CV + 128) div 256;

  R := R * 255 div 1023;
  G := G * 255 div 1023;
  B := B * 255 div 1023;

  if R < 0 then R := 0 else if R > 255 then R := 255;
  if G < 0 then G := 0 else if G > 255 then G := 255;
  if B < 0 then B := 0 else if B > 255 then B := 255;

  dstPtr^ := (B or (G shl 8) or (R shl 16) or ($FF shl 24));
end;

{ YUV TO RGB 查表优化版本 }
procedure YUV2RGB_Table(Y, U, V : Integer; dstPtr:PDWORD);
var
  R, G, B : Byte;
begin
  R := scaleTab[(yTab[Y] + vTabR[V] + 128)            div 256 + SCALE_OFFSET];
  G := scaleTab[(yTab[Y] + uTabG[U] + vTabG[V] + 128) div 256 + SCALE_OFFSET];
  B := scaleTab[(yTab[Y] + uTabB[U] + 128)            div 256 + SCALE_OFFSET];

  dstPtr^ := (B or (G shl 8) or (R shl 16) or ($FF shl 24));
end;

{ 一次读取 2 个像素；U、V 值读取表两次； U、V 值是相同的。可优化 }
procedure YUV420P010LEToRGB32_2Pixel_TWO(ySrc: PByte; yStride: Integer; uvSrc: PByte; uvStride: Integer; pBits: PDWORD; const iWidth, iHeight: Integer);
var
  yFirstAddress  : PByte;
  uvFirstAddress : PByte;
  bmpFirstAddress: PByte;
begin
  yFirstAddress  := ySrc;
  uvFirstAddress := uvSrc;
  bmpFirstAddress:= PByte(pBits) + (iHeight - 1) * iWidth * 4;

  TParallel.For(0, iHeight - 1,
    procedure(Y: Integer)
    var
      yRow, uvRow     : PWORD;
      dstRow          : PDWORD;
      I               : Integer;
      yVal1, yVal2    : Integer;
      uVal, vVal      : Integer;
    begin
      yRow   := PWORD(yFirstAddress  + Y * yStride);
      uvRow  := PWORD(uvFirstAddress + (Y shr 1) * uvStride);
      dstRow := PDWORD(bmpFirstAddress - Y * iWidth * 4);

      for I := 0 to iWidth div 2 - 1 do
      begin
        yVal1:= yRow^  shr 6; Inc(yRow);
        yVal2:= yRow^  shr 6; Inc(yRow);
        uVal := uvRow^ shr 6; Inc(uvRow);
        vVal := uvRow^ shr 6; Inc(uvRow);

        YUV2RGB_Table(yVal1, uVal, vVal, dstRow);  Inc(dstRow);
        YUV2RGB_Table(yVal2, uVal, vVal, dstRow);  Inc(dstRow);
      end;
    end
  );
end;

{ 一次读取 2 个像素；U、V 值只读取表一次 }
procedure YUV420P010LEToRGB32_2Pixel_ONE(ySrc: PByte; yStride: Integer; uvSrc: PByte; uvStride: Integer; pBits: PDWORD; const iWidth, iHeight: Integer);
var
  yFirstAddress  : PByte;
  uvFirstAddress : PByte;
  bmpFirstAddress: PByte;
begin
  yFirstAddress  := ySrc;
  uvFirstAddress := uvSrc;
  bmpFirstAddress:= PByte(pBits) + (iHeight - 1) * iWidth * 4;

  TParallel.For(0, iHeight - 1,
    procedure(Y: Integer)
    var
      yRow, uvRow     : PWORD;
      dstRow          : PDWORD;
      I               : Integer;
      yVal0, yVal1    : Integer;
      uVal, vVal      : Integer;
      uG, uB          : Integer;
      vR, vG          : Integer;
      y0, y1          : Integer;
      R, G, B         : Integer;
    begin
      yRow   := PWORD(yFirstAddress  + Y * yStride);
      uvRow  := PWORD(uvFirstAddress + (Y shr 1) * uvStride);
      dstRow := PDWORD(bmpFirstAddress - Y * iWidth * 4);

      for I := 0 to iWidth div 2 - 1 do
      begin
        yVal0:= yRow^  shr 6; Inc(yRow);
        yVal1:= yRow^  shr 6; Inc(yRow);
        uVal := uvRow^ shr 6; Inc(uvRow);
        vVal := uvRow^ shr 6; Inc(uvRow);

        uG := uTabG[uVal];  uB := uTabB[uVal];
        vR := vTabR[vVal];  vG := vTabG[vVal];

        { 第 1 个像素 }
        y0      := yTab[yVal0];
        R       := scaleTab[(y0 + vR           + 128) div 256 + SCALE_OFFSET];
        G       := scaleTab[(y0 + uG + vG      + 128) div 256 + SCALE_OFFSET];
        B       := scaleTab[(y0 + uB           + 128) div 256 + SCALE_OFFSET];
        dstRow^ := (B or (G shl 8) or (R shl 16) or ($FF shl 24));
        Inc(dstRow);

        { 第 2 个像素 }
        y1      := yTab[yVal1];
        R       := scaleTab[(y1 + vR           + 128) div 256 + SCALE_OFFSET];
        G       := scaleTab[(y1 + uG + vG      + 128) div 256 + SCALE_OFFSET];
        B       := scaleTab[(y1 + uB           + 128) div 256 + SCALE_OFFSET];
        dstRow^ := (B or (G shl 8) or (R shl 16) or ($FF shl 24));
        Inc(dstRow);
      end;
    end
  );
end;

{ 可进行 SIMD 优化 }
procedure YUVToRGB_Eight(yRow, uvRow: PWORD; var dstRow: PDWORD); inline;
begin
  var TTT := PArr8W(yRow);
  var PPP := PArr8W(uvRow);
  YUV2RGB_Table(TTT[0] shr 6, PPP[0] shr 6, PPP[1] shr 6, dstRow);  Inc(dstRow);
  YUV2RGB_Table(TTT[1] shr 6, PPP[0] shr 6, PPP[1] shr 6, dstRow);  Inc(dstRow);
  YUV2RGB_Table(TTT[2] shr 6, PPP[2] shr 6, PPP[3] shr 6, dstRow);  Inc(dstRow);
  YUV2RGB_Table(TTT[3] shr 6, PPP[2] shr 6, PPP[3] shr 6, dstRow);  Inc(dstRow);
  YUV2RGB_Table(TTT[4] shr 6, PPP[4] shr 6, PPP[5] shr 6, dstRow);  Inc(dstRow);
  YUV2RGB_Table(TTT[5] shr 6, PPP[4] shr 6, PPP[5] shr 6, dstRow);  Inc(dstRow);
  YUV2RGB_Table(TTT[6] shr 6, PPP[6] shr 6, PPP[7] shr 6, dstRow);  Inc(dstRow);
  YUV2RGB_Table(TTT[7] shr 6, PPP[6] shr 6, PPP[7] shr 6, dstRow);  Inc(dstRow);
end;

{ 一次读取 8 个像素 }
procedure YUV420P010LEToRGB32_8Pixel(ySrc: PByte; yStride: Integer; uvSrc: PByte; uvStride: Integer; pBits: PDWORD; const iWidth, iHeight: Integer);
begin
  var yFirstAddress  := ySrc;
  var uvFirstAddress := uvSrc;
  var bmpFirstAddress:= PByte(pBits) + (iHeight - 1) * iWidth * 4;

  TParallel.For(0, iHeight - 1,
    procedure(Y: Integer)
    begin
      var yRow   := PWORD(yFirstAddress  + Y * yStride);
      var uvRow  := PWORD(uvFirstAddress + (Y shr 1) * uvStride);
      var dstRow := PDWORD(bmpFirstAddress - Y * iWidth * 4);

      for var I := 0 to iWidth div 8 - 1 do
      begin
        YUVToRGB_Eight(yRow, uvRow, dstRow);

        Inc(yRow, 8);
        Inc(uvRow, 8);
      end;
    end
  );
end;

end.
