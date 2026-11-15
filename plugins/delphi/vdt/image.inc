const
  c_PixBGRAMask: DWORD            = $FF;
  c_GraySSERioR: DWORD            = $4D;
  c_GraySSERioG: DWORD            = $97;
  c_GraySSERioB: DWORD            = $1C;

procedure GraySSE42(pColor: PByte; const bmpWidth: Integer);
asm
  {$IFDEF WIN64}
  MOV     RAX,  RCX
  {$IFEND}

  MOVSS   XMM1, [c_PixBGRAMask]             // XMM1 = 000000000000000000000000000000FF
  MOVSS   XMM2, [c_GraySSERioB]             // XMM2 = 0000000000000000000000000000001C
  MOVSS   XMM3, [c_GraySSERioG]             // XMM3 = 00000000000000000000000000000097
  MOVSS   XMM4, [c_GraySSERioR]             // XMM4 = 0000000000000000000000000000004D
  SHUFPS  XMM1, XMM1, 0                     // XMM1 = 000000FF000000FF000000FF000000FF
  SHUFPS  XMM2, XMM2, 0                     // XMM2 = 0000001C0000001C0000001C0000001C
  SHUFPS  XMM3, XMM3, 0                     // XMM3 = 00000097000000970000009700000097
  SHUFPS  XMM4, XMM4, 0                     // XMM4 = 0000004D0000004D0000004D0000004D

@LOOP:
  {$IFDEF WIN64}
  MOVUPS  XMM0, [RAX]                       // XMM0 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  {$ELSE}
  MOVUPS  XMM0, [EAX]                       // XMM0 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  {$IFEND}
  MOVAPS  XMM5, XMM0                        // XMM5 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  MOVAPS  XMM6, XMM0                        // XMM6 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  MOVAPS  XMM7, XMM0                        // XMM7 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|

  // 获取 4 个像素的 B3, B2, B1, B0
  ANDPS   XMM5, XMM1                        // XMM5 = |000000B3|000000B2|000000B1|000000B0|

  // 获取 4 个像素的 G3, G2, G1, G0
  PSRLD   XMM6, 8                           // XMM6 = |00A3R3G3|00A2R2G2|00A1R1G1|00A0R0G0|
  ANDPS   XMM6, XMM1                        // XMM6 = |000000G3|000000G2|000000G1|000000G0|

  // 获取 4 个像素的 R3, R2, R1, R0
  PSRLD   XMM7, 16                          // XMM7 = |0000A3R3|0000A2R2|0000A1R1|0000A0R0|
  ANDPS   XMM7, XMM1                        // XMM7 = |000000R3|000000R2|000000R1|000000R0|

  // 计算灰度值
  PMULLW  XMM5, XMM2                        // XMM5 = |B3 *  28|B2 *  28|B1 *  28|B0 *  28|
  PMULLW  XMM6, XMM3                        // XMM6 = |G3 * 151|G2 * 151|G1 * 151|G0 * 151|
  PMULLW  XMM7, XMM4                        // XMM7 = |R3 *  77|R2 *  77|R1 *  77|R0 *  77|
  PADDD   XMM5, XMM6                        // XMM5 = G+B
  PADDD   XMM5, XMM7                        // XMM5 = G+B+R
  PSRLD   XMM5, 8                           // XMM5 = |000000Y3|000000Y2|000000Y1|000000Y0|

  // 返回结果
  MOVAPS  XMM6, XMM5                        // XMM6  = |000000Y3|000000Y2|000000Y1|000000Y0|
  MOVAPS  XMM7, XMM5                        // XMM7  = |000000Y3|000000Y2|000000Y1|000000Y0|
  PSLLD   XMM6, 8                           // XMM6  = |0000Y300|0000Y200|0000Y100|0000Y000|
  PSLLD   XMM7, 16                          // XMM7  = |00Y30000|00Y20000|00Y10000|00Y00000|
  ORPS    XMM5, XMM6                        // XMM5  = |0000Y3Y3|0000Y2Y2|0000Y1Y1|0000Y0Y0|
  ORPS    XMM5, XMM7                        // XMM5  = |00Y3Y3Y3|00Y2Y2Y2|00Y1Y1Y1|00Y0Y0Y0|
  {$IFDEF WIN64}
  MOVUPS  [RAX], XMM5                       // [RAX] = XMM5
  {$ELSE}
  MOVUPS  [EAX], XMM5                       // [EAX] = XMM5
  {$IFEND}

  {$IFDEF WIN64}
  ADD     RAX, 16                           // pColor 地址加 16，RAX 指向下4个像素的地址
  SUB     RDX, 4                            // Width 减 4, 每 4 个像素一循环
  {$ELSE}
  ADD     EAX, 16                           // pColor 地址加 16，EAX 指向下4个像素的地址
  SUB     EDX, 4                            // Width 减 4, 每 4 个像素一循环
  {$IFEND}
  JNZ     @LOOP                             // 循环
end;

procedure GrayBmp32(bmp: TBitmap);
var
  StartScanLine: NativeInt;
  bmpWidthBytes: NativeInt;
begin
  StartScanLine := NativeInt(bmp.ScanLine[0]);
  bmpWidthBytes := NativeInt(bmp.ScanLine[1]) - NativeInt(bmp.ScanLine[0]);

  TParallel.For(0, bmp.Height - 1,
    procedure(Y: Integer)
    begin
      {$IF DEFINED(WIN32) OR DEFINED(WIN64)}
      var pColor := PByte(StartScanLine + Y * bmpWidthBytes);
      GraySSE42(pColor, bmp.Width);
      {$ELSE}
      var pColor := PRGBQuad(StartScanLine + Y * bmpWidthBytes);
      for var X : Integer := 0 to bmp.Width - 1 do
      begin
        var byeGray : Byte := (306 * pColor^.rgbRed + 601 * pColor^.rgbGreen + 117 * pColor^.rgbBlue + 512) shr 10;
        pColor^ := TRGBQuad(RGB(byeGray, byeGray, byeGray));
        Inc(pColor);
      end;
      {$ENDIF}
    end);
end;
