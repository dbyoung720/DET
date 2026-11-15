{
  x86 下，寄存器顺序为：EAX/EDX/ECX
  x64 下，寄存器顺序为：RCX/RDX/R8/R9D

  通用寄存器：
  CPU  :
  EAX/EBX/ECX/EDX/EDI/ESI/EBP/ESP           32位 (x86)
  RAX/RBX/RCX/RDX/RDI/RSI/RBP/RSP/R8---R15  64位 (x64, EAX 寄存器是 RAX 寄存器的低 32 位)
  注意 EBX / RBX 需要保存和恢复

  SIMD寄存器：
  MMX    :   MM0 --- MM7                             064位                                         ( 主要针对浮点运算 )
  SSE2   :  XMM0--- XMM7                             128位  (4 * 32)                               ( 浮点 + 整数 )
  SSE4   :  XMM0--- XMM7(X86)  XMM0--- XMM15(X64)    128位  (4 * 32)                               ( 浮点 + 整数 )
  AVX    :  YMM0--- YMM7(X86)  YMM0--- YMM15(X64)    256位 (XMM 寄存器是 YMM 寄存器的低 128 位)    ( 浮点 )
  AVX2   :  YMM0---YMM15                             256位 (XMM 寄存器是 YMM 寄存器的低 128 位)    ( 浮点 + 整数 )
  AVX512 :  ZMM0---ZMM31                             512位 (YMM 寄存器是 ZMM 寄存器的低 256 位)    ( 浮点 + 整数 )
}

var
  FContrastTable  : array [-255 .. 255, 0 .. 255] of Byte;
  FSaturationTable: array [0 .. 510, 0 .. 765, 0 .. 255] of Byte;

type
  __m128i = record
  private
    { }
  public
    procedure _mm_loadu_si128(var A, B: Integer);
    procedure _mm_add_epi16(var A, B: Integer);
    procedure _mm_srli_epi16(var A, B: Integer);
    procedure _mm_and_si128(var A, B: Integer);
    procedure _mm_packus_epi16(var A, B: Integer);
    procedure _mm_storeu_si128(var A, B: Integer);
    case Integer of
      0:
        (m128i_i08: array [0 .. 15] of Int8); // 16个8位整数
      1:
        (m128i_i16: array [0 .. 7] of Int16); // 8个16位整数
      2:
        (m128i_i32: array [0 .. 3] of Int32); // 4个32位整数
      3:
        (m128i_i64: array [0 .. 1] of Int64); // 2个64位整数
  end;

  { __m128i }

procedure __m128i._mm_add_epi16(var A, B: Integer);
begin

end;

procedure __m128i._mm_and_si128(var A, B: Integer);
begin

end;

procedure __m128i._mm_loadu_si128(var A, B: Integer);
begin

end;

procedure __m128i._mm_packus_epi16(var A, B: Integer);
begin

end;

procedure __m128i._mm_srli_epi16(var A, B: Integer);
begin

end;

procedure __m128i._mm_storeu_si128(var A, B: Integer);
begin

end;

procedure BrightnessLineSSE2(pColorSrc, pColorDst: PRGBQuad; const bmpWidth, iPos: NativeInt);
{$IFDEF WIN32}
asm
  PUSH EBX
  MOV  EBX, iPos

  { iPos 为负数时，使用 PSUBUSB 饱和减法，减少亮度；iPos 为正数时，使用 PADDUSB 饱和加法，增加亮度 }
  TEST EBX, EBX
  JL  @DecBrightness

  { PADDUSB 饱和加法，增加亮度 }
@IncBrightness:
  IMUL    EBX,   $010101    // EBX = 00/iPos/iPos/iPos
  MOVD    XMM1,  EBX        // XMM1 = 00000000          || 00000000          || 00000000          || 00|ipos|ipos|ipos
  PSHUFD  XMM1,  XMM1, $00  // XMM1 = 00|ipos|ipos|ipos || 00|ipos|ipos|ipos || 00|ipos|ipos|ipos || 00|ipos|ipos|ipos
@FourPoint01:               // 4 个像素一循环
  MOVDQA  XMM0,  [EAX]      // XMM0 = A3R3G3B3  || A2R2G2B2  || A1R1G1B1 || A0R0G0B0
  PADDUSB XMM0,  XMM1       // 饱和加法，结果存放在 XMM0 中
  MOVDQA  [EDX], XMM0       // 将结果赋给 pColorDst
  ADD     EAX,   16         // pColorSrc 地址加 16，EAX 指向下4个像素的地址
  ADD     EDX,   16         // pColorDst 地址加 16，EDX 指向下4个像素的地址
  SUB     ECX,   4          // Width 减 4, 每 4 个像素一循环
  JNZ     @FourPoint01      // 循环
  JMP     @Exit

  { PSUBUSB 饱和减法，减少亮度 }
@DecBrightness:
  NEG     EBX
  IMUL    EBX,   $010101
  MOVD    XMM1,  EBX
  PSHUFD  XMM1,  XMM1, $00
@FourPoint02:
  MOVDQA  XMM0,  [EAX]
  PSUBUSB XMM0,  XMM1
  MOVDQA  [EDX], XMM0
  ADD     EAX,   16
  ADD     EDX,   16
  SUB     ECX,   4
  JNZ     @FourPoint02

@Exit:
  POP EBX
end;
{$ELSE IF WIN64}
asm
  .NOFRAME
  PUSH    RBX           // 保存被调用者保存寄存器
  MOV     R10, RCX      // R10 = 源指针
  MOV     R11, RDX      // R11 = 目标指针
  MOV     EBX, R9D      // EBX = iPos (使用低32位)
  TEST    EBX, EBX
  JL      @DecBrightness

@IncBrightness:                 // 增加亮度分支
  IMUL    EBX, $010101          // 创建32位亮度掩码 (BB GG RR)
  MOVD    XMM1, EBX             // 加载到XMM1
  PSHUFD  XMM1, XMM1, 0         // 广播到所有4个32位槽
  MOV     ECX, R8D              // ECX = 像素宽度计数器
@FourPoint01:                   // 4 个像素一循环
  MOVDQU  XMM0, [R10]           // 加载4个像素
  PADDUSB XMM0, XMM1            // 增加亮度
  MOVDQU  [R11], XMM0           // 存储结果
  ADD     R10, 16               // 前进源指针
  ADD     R11, 16               // 前进目标指针
  SUB     ECX, 4                // 每次处理4个像素
  JNZ     @FourPoint01          // 每次处理4个像素
  JMP     @Exit

@DecBrightness:                 // 减少亮度分支
  NEG     EBX                   //
  IMUL    EBX, $010101          // 创建32位亮度掩码 (BB GG RR)
  MOVD    XMM1, EBX             // 加载到XMM1
  PSHUFD  XMM1, XMM1, 0         // 广播到所有4个32位槽
  MOV     ECX, R8D              // ECX = 像素宽度计数器
@FourPoint02:                   // 4 个像素一循环
  MOVDQU  XMM0, [R10]           // 加载4个像素
  PSUBUSB XMM0, XMM1            // 减少亮度
  MOVDQU  [R11], XMM0           // 存储结果
  ADD     R10, 16               // pColorSrc 地址加 16，EAX 指向下4个像素的地址
  ADD     R11, 16               // pColorDst 地址加 16，EDX 指向下4个像素的地址
  SUB     ECX, 4                // 每次处理4个像素
  JNZ     @FourPoint02

@Exit:
  POP     RBX           // 恢复寄存器
end;
{$ELSE}
var
  I: Integer;
begin
  for I := 0 to bmpWidth - 1 do
  begin
    pColorDst^.rgbRed   := EnsureRange(pColorSrc^.rgbRed + iPos, 0, 255);
    pColorDst^.rgbGreen := EnsureRange(pColorSrc^.rgbGreen + iPos, 0, 255);
    pColorDst^.rgbBlue  := EnsureRange(pColorSrc^.rgbBlue + iPos, 0, 255);
    Inc(pColorSrc);
    Inc(pColorDst);
  end;
end;
{$ENDIF}

procedure BlendLineSSE2(pColorSrc, pColorDst: PRGBQuad; const bmpWidth: Integer; const iPos: Integer);
{$IFDEF WIN32}
asm
  PUSH EBX
  MOV  EBX, iPos

  { 准备 iPos 常量 }
  MOVD    XMM0, EBX          // XMM0 = [0, 0, 0, iPos]
  PSHUFLW XMM0, XMM0, 0      // XMM0 = [0        , 0        , iPos|iPos, iPos|iPos] 复制到所有16位通道
  PSHUFD  XMM0, XMM0, 0      // XMM0 = [iPos|iPos, iPos|iPos, iPos|iPos, iPos|iPos] 复制到所有32位通道
  MOV     EBX,  256          // EBX = 256
  SUB     EBX,  iPos         // EBX = 256 - iPos
  MOVD    XMM1, EBX          // XMM1 = [0, 0, 0, 255 - iPos]
  PSHUFLW XMM1, XMM1, 0      // XMM1 = [0                    , 0                    , 255 - iPos|255 - iPos, 255 - iPos|255 - iPos]
  PSHUFD  XMM1, XMM1, 0      // XMM1 = [255 - iPos|255 - iPos, 255 - iPos|255 - iPos, 255 - iPos|255 - iPos, 255 - iPos|255 - iPos]

@FOURPOINT:                  // 4 个像素一循环
  MOVUPS    XMM2,  [EAX]     // XMM2 = SRC A3R3G3B3  || A2R2G2B2  || A1R1G1B1 || A0R0G0B0
  MOVUPS    XMM3,  [EDX]     // XMM3 = DST A3R3G3B3  || A2R2G2B2  || A1R1G1B1 || A0R0G0B0

  { 解包到 16 位；原因：下面要进行两个 Byte 数字相乘，就上升到 WORD，所以需要解包，将一个字节扩充到两个字节 }
  PMOVZXBW   XMM4, XMM2      // SRC 像素低 64 位，低 2 个像素（占据 128 位）
  PMOVZXBW   XMM5, XMM3      // DST 像素低 64 位，低 2 个像素（占据 128 位）
  PUNPCKHBW  XMM2, XMM7      // SRC 像素高 64 位，高 2 个像素（占据 128 位）
  PUNPCKHBW  XMM3, XMM7      // DST 像素高 64 位，高 2 个像素（占据 128 位）

  { 应用 ALPHA 混合 }
  PMULLW XMM4, XMM0          // SRC * ALPHA         低 64 位
  PMULLW XMM5, XMM1          // DST * (256-ALPHA)   低 64 位
  PMULLW XMM2, XMM0          // SRC * ALPHA         高 64 位
  PMULLW XMM3, XMM1          // DST * (256-ALPHA)   高 64 位

  { 相加并除以 256 }
  PADDW XMM4, XMM5           // (SRC * ALPHA) + (DST * (256-ALPHA))  低 64 位
  PADDW XMM2, XMM3           // (SRC * ALPHA) + (DST * (256-ALPHA))  高 64 位
  PSRLW XMM4, 8              // 低 64 位除以 256
  PSRLW XMM2, 8              // 高 64 位除以 256

  { 打包回 8 位 }
  PACKUSWB XMM4, XMM2

  { 存储结果 }
  MOVDQU [EDX], XMM4

  ADD     EAX,   16            // pColorSrc 地址加 16，EAX 指向下4个像素的地址
  ADD     EDX,   16            // pColorDst 地址加 16，EDX 指向下4个像素的地址
  SUB     ECX,   4             // Width 减 4, 每 4 个像素一循环
  JNZ     @FourPoint           // 循环

  POP EBX
end;
{$ELSE IF WIN64}
asm
  // 保存非易失性寄存器 (RBX 和 XMM6)
  PUSH RBX
  SUB  RSP, $20
  MOVDQU [RSP],     XMM6     // 保存 XMM6
  MOVDQU [RSP+$10], XMM7     // 保存 XMM7

  // 创建零寄存器 (XMM7)
  PXOR XMM7, XMM7

  // 准备 iPos 常量 (XMM0)
  MOVD     XMM0, R9D       // R9D = iPos
  PSHUFLW  XMM0, XMM0, $00 // 广播到低64位的所有字
  PSHUFD   XMM0, XMM0, $00 // 广播到整个XMM0

  // 准备 256-iPos 常量 (XMM1)
  MOV      EBX, 256
  SUB      EBX, R9D
  MOVD     XMM1, EBX
  PSHUFLW  XMM1, XMM1, $00
  PSHUFD   XMM1, XMM1, $00

  // 设置循环计数器 (R10D = bmpWidth)
  MOV      R10D, R8D

  // 主循环 (每次处理4个像素)
@FourPoint:
  MOVUPS   XMM2, [RCX]     // 加载4个源像素
  MOVUPS   XMM3, [RDX]     // 加载4个目标像素

  // 解包源像素
  PMOVZXBW XMM4, XMM2      // 低64位 (2像素)
  PUNPCKHBW XMM2, XMM7     // 高64位 (2像素)

  // 解包目标像素
  PMOVZXBW XMM5, XMM3      // 低64位 (2像素)
  PUNPCKHBW XMM3, XMM7     // 高64位 (2像素)

  // 混合计算
  PMULLW   XMM4, XMM0      // 源低 * iPos
  PMULLW   XMM5, XMM1      // 目标低 * (256-iPos)
  PMULLW   XMM2, XMM0      // 源高 * iPos
  PMULLW   XMM3, XMM1      // 目标高 * (256-iPos)

  // 求和并除以256
  PADDW    XMM4, XMM5
  PADDW    XMM2, XMM3
  PSRLW    XMM4, 8
  PSRLW    XMM2, 8

  // 打包回字节并存储
  PACKUSWB XMM4, XMM2
  MOVDQU   [RDX], XMM4

  // 更新指针和计数器
  ADD      RCX, 16
  ADD      RDX, 16
  SUB      R10D, 4
  JNZ      @FourPoint

  // 恢复寄存器并返回
  MOVDQU XMM7, [RSP+$10]
  MOVDQU XMM6, [RSP]
  ADD    RSP, $20
  POP    RBX
end;
{$ELSE}
var
  X: Integer;
begin
  for X := 0 to bmpWidth - 1 do
  begin
    pColorDst^.R := (pColorDst^.R * (256 - iPos) + pColorSrc^.R * iPos) shr 8;
    pColorDst^.G := (pColorDst^.G * (256 - iPos) + pColorSrc^.G * iPos) shr 8;
    pColorDst^.B := (pColorDst^.B * (256 - iPos) + pColorSrc^.B * iPos) shr 8;
    Inc(pColorDst);
    Inc(pColorSrc);
  end;
end;
{$ENDIF}

const
  rGrayMask: array [0 .. 3] of DWORD = ($4D, $4D, $4D, $4D); // 77
  gGrayMask: array [0 .. 3] of DWORD = ($97, $97, $97, $97); // 151
  bGrayMask: array [0 .. 3] of DWORD = ($1C, $1C, $1C, $1C); // 28
  aGrayMask: array [0 .. 3] of DWORD = ($FF, $FF, $FF, $FF); // 255

procedure GrayLineSSE2(pColor: PByte; const bmpWidth: Integer);
{$IFDEF WIN32}
asm
  MOV     ECX,  EDX

  { 加载常量数组掩码 }
  MOVDQU    XMM1, [aGrayMask]               // XMM1 = 全FF掩码
  MOVDQU    XMM2, [bGrayMask]               // XMM2 = 全1C(B系数)
  MOVDQU    XMM3, [gGrayMask]               // XMM3 = 全97(G系数)
  MOVDQU    XMM4, [rGrayMask]               // XMM4 = 全4D(R系数)

@LOOP:
  MOVUPS  XMM0, [EAX]                       // XMM0 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  MOVAPS  XMM5, XMM0                        // XMM5 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  MOVAPS  XMM6, XMM0                        // XMM6 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|
  MOVAPS  XMM7, XMM0                        // XMM7 = |A3R3G3B3|A2R2G2B2|A1R1G1B1|A0R0G0B0|

  { 获取 4 个像素的 B3, B2, B1, B0 }
  PAND    XMM5, XMM1                        // XMM5 = |000000B3|000000B2|000000B1|000000B0|

  { 获取 4 个像素的 G3, G2, G1, G0 }
  PSRLD   XMM6, 8                           // XMM6 = |00A3R3G3|00A2R2G2|00A1R1G1|00A0R0G0|
  PAND    XMM6, XMM1                        // XMM6 = |000000G3|000000G2|000000G1|000000G0|

  { 获取 4 个像素的 R3, R2, R1, R0 }
  PSRLD   XMM7, 16                          // XMM7 = |0000A3R3|0000A2R2|0000A1R1|0000A0R0|
  PAND    XMM7, XMM1                        // XMM7 = |000000R3|000000R2|000000R1|000000R0|

  { 计算灰度值 }
  PMULLW  XMM5, XMM2                        // XMM5 = |B3 *  28|B2 *  28|B1 *  28|B0 *  28|
  PMULLW  XMM6, XMM3                        // XMM6 = |G3 * 151|G2 * 151|G1 * 151|G0 * 151|
  PMULLW  XMM7, XMM4                        // XMM7 = |R3 *  77|R2 *  77|R1 *  77|R0 *  77|
  PADDD   XMM5, XMM6                        // XMM5 = G+B
  PADDD   XMM5, XMM7                        // XMM5 = G+B+R
  PSRLD   XMM5, 8                           // XMM5 = (G+B+R) > 8 = |000000Y3|000000Y2|000000Y1|000000Y0|

  { 返回结果 }
  MOVAPS  XMM0, XMM5                        // 复用XMM0存放灰度值
  PSLLD   XMM5, 8                           // 左移8位 -> [0, Y, 0, 0]
  POR     XMM0, XMM5                        // 组合 -> [0, Y, 0, Y]
  PSLLD   XMM5, 8                           // 再左移8位 -> [Y, 0, 0, 0]
  POR     XMM0, XMM5                        // 最终组合 -> [Y, Y, Y, 0] (BGRA格式)
  MOVUPS  [EAX], XMM0                       // 写回内存

  ADD     EAX, 16                           // pColor 地址加 16，EAX 指向下4个像素的地址
  SUB     ECX, 4                            // Width 减 4, 每 4 个像素一循环
  JNZ     @LOOP                             // 循环
end;
{$ELSE IF WIN64}
asm
  MOVDQU    XMM1, [aGrayMask]               // XMM1 = 全FF掩码
  MOVDQU    XMM2, [bGrayMask]               // XMM2 = 全1C(B系数)
  MOVDQU    XMM3, [gGrayMask]               // XMM3 = 全97(G系数)
  MOVDQU    XMM4, [rGrayMask]               // XMM4 = 全4D(R系数)

@LOOP:
  MOVUPS  XMM0, [RCX]
  MOVAPS  XMM5, XMM0
  MOVAPS  XMM6, XMM0
  MOVAPS  XMM7, XMM0

  PAND    XMM5, XMM1
  PSRLD   XMM6, 8
  PAND    XMM6, XMM1
  PSRLD   XMM7, 16
  PAND    XMM7, XMM1

  PMULLW  XMM5, XMM2
  PMULLW  XMM6, XMM3
  PMULLW  XMM7, XMM4
  PADDD   XMM5, XMM6
  PADDD   XMM5, XMM7
  PSRLD   XMM5, 8

  MOVAPS  XMM0, XMM5
  PSLLD   XMM5, 8
  POR     XMM0, XMM5
  PSLLD   XMM5, 8
  POR     XMM0, XMM5
  MOVUPS  [RCX], XMM0

  ADD     RCX, 16
  SUB     RDX, 4
  JNZ     @LOOP
end;
{$ELSE}
var
  X      : Integer;
  byeGray: Byte;
begin
  for X := 0 to bmpWidth - 1 do
  begin
    byeGray := (306 * pColor^.R + 601 * pColor^.G + 117 * pColor^.B + 512) shr 10;
    pColor^ := TRGBQuad(RGB(byeGray, byeGray, byeGray));
    Inc(pColor);
  end;
end;
{$ENDIF}

{$IFDEF WIN32}
procedure GrayLineAVX2(pColor: PByte; const bmpWidth: Integer);
const
  // Shuffle masks for extracting B, G, R components (each mask is 32-byte aligned)
  ShuffleB: array [0 .. 31] of Byte = (0, 4, 8, 12, 16, 20, 24, 28, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80);
  ShuffleG: array [0 .. 31] of Byte = (1, 5, 9, 13, 17, 21, 25, 29, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80);
  ShuffleR: array [0 .. 31] of Byte = (2, 6, 10, 14, 18, 22, 26, 30, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80);
  c306: UInt32                      = 306;
  c601: UInt32                      = 601;
  c117: UInt32                      = 117;
  c512: UInt32                      = 512;
  c010101: UInt32                   = $00010101;
  cZero: UInt32                     = 0;
asm
  push  esi
  push  edi
  push  ebx

  // 参数已在 EAX(pColor) 和 EDX(bmpWidth) 中
  mov   esi, eax        // ESI = pColor
  mov   edi, edx        // EDI = bmpWidth

  // 计算8像素块的数量
  mov   ecx, edi
  shr   ecx, 3
  jz    @Tail           // 如果没有完整块，跳转到尾数处理

  // 加载常量到寄存器
  vmovdqu    ymm7, [ShuffleB]   // B分量掩码
  vmovdqu    ymm6, [ShuffleG]   // G分量掩码
  vmovdqu    ymm5, [ShuffleR]   // R分量掩码

  vpbroadcastd ymm4, [c306]     // 8个306
  vpbroadcastd ymm3, [c601]     // 8个601
  vpbroadcastd ymm2, [c117]     // 8个117
  vpbroadcastd ymm1, [c512]     // 8个512
  vpbroadcastd ymm0, [c010101]  // 8个0x010101

@ProcessLoop:
  // 加载像素数据到 ymm7 (临时覆盖 shuffle 掩码)
  vmovdqu    ymm7, [esi]        // 加载8个像素(32字节)

  // 提取B分量并扩展为32位整数 (使用 ymm5 作为临时寄存器)
  vpshufb    ymm5, ymm7, [ShuffleB]  // 直接从内存加载shuffle掩码
  vpmovzxbd  ymm5, xmm5              // ymm5 = 8个B分量

  // 提取G分量并扩展为32位整数 (使用 ymm6 作为临时寄存器)
  vpshufb    ymm6, ymm7, [ShuffleG]  // 直接从内存加载shuffle掩码
  vpmovzxbd  ymm6, xmm6              // ymm6 = 8个G分量

  // 提取R分量并扩展为32位整数 (使用 ymm7 作为临时寄存器)
  vpshufb    ymm7, ymm7, [ShuffleR]  // 重用已加载的像素数据
  vpmovzxbd  ymm7, xmm7              // ymm7 = 8个R分量

  // 灰度计算: (306*R + 601*G + 117*B + 512) >> 10
  vpmulld    ymm7, ymm7, ymm4   // R * 306
  vpmulld    ymm6, ymm6, ymm3   // G * 601
  vpmulld    ymm5, ymm5, ymm2   // B * 117

  vpaddd     ymm6, ymm6, ymm7   // R*306 + G*601
  vpaddd     ymm5, ymm5, ymm6   // R*306 + G*601 + B*117
  vpaddd     ymm5, ymm5, ymm1   // R*306 + G*601 + B*117 + 512
  vpsrld     ymm5, ymm5, 10     // R*306 + G*601 + B*117 + 512 >> 10

  // 复制灰度值到RGB通道，Alpha=0
  vpmulld    ymm5, ymm5, ymm0   // 灰度值 * 0x010101

  // 恢复shuffle掩码 (因为ymm6和ymm7被修改)
  vmovdqu    ymm6, [ShuffleG]   // 恢复G分量掩码
  vmovdqu    ymm7, [ShuffleB]   // 恢复B分量掩码

  // 存储处理后的像素
  vmovdqu    [esi], ymm5

  add       esi, 32            // 移动到下一个8像素块
  dec       ecx
  jnz       @ProcessLoop       // 处理所有完整块

  // 处理剩余像素(1-7个)
@Tail:
  mov       ecx, edi
  and       ecx, 7             // 剩余像素数
  jz        @Done              // 无剩余像素则结束

@TailLoop:
  // 处理单个像素
  mov       eax, [esi]         // 加载像素(BGRA)

  // 提取分量
  movzx     edx, al            // B分量
  movzx     ebx, ah            // G分量
  shr       eax, 16
  movzx     eax, al            // R分量

  // 计算灰度: (306*R + 601*G + 117*B + 512) >> 10
  imul      eax, 306
  imul      ebx, 601
  imul      edx, 117
  add       eax, ebx
  add       eax, edx
  add       eax, 512
  shr       eax, 10            // eax = 灰度值(0-255)

  // 构建灰度像素: 0x00gggggg (BGRA格式)
  mov       edx, eax
  shl       eax, 8
  or        eax, edx
  shl       edx, 16
  or        eax, edx           // eax = B=g, G=g, R=g, A=0

  mov       [esi], eax         // 存储处理后的像素

  add       esi, 4             // 下一个像素
  dec       ecx
  jnz       @TailLoop

@Done:
  vzeroupper                  // 清除YMM高位
  pop       ebx
  pop       edi
  pop       esi
end;
{$ENDIF}

const
  c_128: array [0 .. 15] of Byte = ($80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80);
  c_255: array [0 .. 15] of Byte = ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);
  c_ALL: array [0 .. 15] of Byte = ($FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00, $FF, $FF, $FF, $00);

procedure ExposureLineSSE2(pColor: PRGBQuad; bmpWidth: Integer);
{$IFDEF WIN32}
asm
  MOV     ECX, bmpWidth    // ECX = 像素数量

  // 加载常量到XMM寄存器
  MOVDQU  XMM1, [c_128]   // XMM1 = 128常量
  MOVDQU  XMM5, [c_255]   // XMM5 = 255常量
  MOVDQU  XMM7, [c_ALL]   // XMM7 = Alpha通道掩码

@LOOP:
  // 加载4像素(16字节)
  MOVDQU  XMM0, [EAX]      // 加载像素数据
  MOVDQA  XMM3, XMM0       // 保存原始值

  // 生成处理掩码(值<128的位置为FF)
  PXOR    XMM0, XMM1       // 异或128转换有符号范围
  PXOR    XMM2, XMM2       // 清零XMM2
  PCMPGTB XMM2, XMM0       // 生成掩码(值<128的位置为FF)

  // 计算取反值(255 - 原始值)
  MOVDQA  XMM4, XMM5       // 加载255常量
  PSUBB   XMM4, XMM3       // 计算取反值

  // 应用Alpha通道掩码
  PAND    XMM2, XMM7       // 屏蔽Alpha通道处理

  // 条件选择处理结果
  MOVDQA  XMM6, XMM2       // 备份掩码
  PAND    XMM2, XMM4       // 选择取反部分
  PANDN   XMM6, XMM3       // 选择保留部分
  POR     XMM2, XMM6       // 合并结果

  // 存储处理结果
  MOVDQU  [EAX], XMM2      // 存回内存

  // 移动指针并循环
  ADD     EAX, 16          // 前进16字节(4像素)
  SUB     ECX, 4
  JNZ     @LOOP
end;
{$ELSE IF WIN64}
asm
  // 加载常量到XMM寄存器
  MOVDQU  XMM1, [c_128]   // XMM1 = 128常量
  MOVDQU  XMM5, [c_255]   // XMM5 = 255常量
  MOVDQU  XMM7, [c_ALL]   // XMM7 = Alpha通道掩码

@LOOP:
  // 加载4像素(16字节)
  MOVDQU  XMM0, [RCX]      // 加载像素数据
  MOVDQA  XMM3, XMM0       // 保存原始值

  // 生成处理掩码(值<128的位置为FF)
  PXOR    XMM0, XMM1       // 异或128转换有符号范围
  PXOR    XMM2, XMM2       // 清零XMM2
  PCMPGTB XMM2, XMM0       // 生成掩码(值<128的位置为FF)

  // 计算取反值(255 - 原始值)
  MOVDQA  XMM4, XMM5       // 加载255常量
  PSUBB   XMM4, XMM3       // 计算取反值

  // 应用Alpha通道掩码
  PAND    XMM2, XMM7       // 屏蔽Alpha通道处理

  // 条件选择处理结果
  MOVDQA  XMM6, XMM2       // 备份掩码
  PAND    XMM2, XMM4       // 选择取反部分
  PANDN   XMM6, XMM3       // 选择保留部分
  POR     XMM2, XMM6       // 合并结果

  // 存储处理结果
  MOVDQU  [RCX], XMM2      // 存回内存

  // 移动指针并循环
  ADD     RCX, 16          // 前进16字节(4像素)
  SUB     RDX, 4
  JNZ     @LOOP
end;
{$ELSE}
var
  X: Integer;
begin
  for X := 0 to bmpWidth - 1 do
  begin
    pColor^.B := IfThen(pColor^.B < 128, not pColor^.B, pColor^.B);
    pColor^.G := IfThen(pColor^.G < 128, not pColor^.G, pColor^.G);
    pColor^.R := IfThen(pColor^.R < 128, not pColor^.R, pColor^.R);
    Inc(pColor);
  end;
end;
{$ENDIF}

const
  const_128: array [0 .. 15] of Byte = (128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128);
  const_255: array [0 .. 15] of Byte = (255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255);

procedure EmbossLineSSE2(pColor01, pColor02: PRGBQuad; pColorDst: PRGBQuad; bmpWidth: Integer); assembler;
{$IFDEF WIN32}
asm
  // 保存寄存器
  PUSH EBX
  MOV  EBX, bmpWidth

  // 加载常量
  MOVDQU XMM6, [CONST_128]  // XMM6 = [128, 128, 128, 128]
  MOVDQU XMM7, [CONST_255]  // XMM7 = [255, 255, 255, 255]

  // 主循环
@@LOOPSTART:
  // 加载 PCOLOR01 和 PCOLOR02 的 4 个像素
  MOVUPS XMM0, [EAX]  // XMM0 = [PCOLOR01[0], PCOLOR01[1], PCOLOR01[2], PCOLOR01[3]]
  MOVUPS XMM1, [EDX]  // XMM1 = [PCOLOR02[0], PCOLOR02[1], PCOLOR02[2], PCOLOR02[3]]

  ADD EDX, 16  // PCOLOR02 += 4

  // 计算差值并加上 128
  PSUBB XMM0, XMM1  // XMM0 = PCOLOR01 - PCOLOR02
  PADDB XMM0, XMM6  // XMM0 = (PCOLOR01 - PCOLOR02) + 128

  // 饱和操作，确保值在 0 到 255 之间
  PMINUB XMM0, XMM7  // XMM0 = MIN(XMM0, 255)
  PMAXUB XMM0, XMM6  // XMM0 = MAX(XMM0, 0)

  // 存储结果
  MOVUPS [ECX], XMM0

  // 更新指针
  ADD EAX, 16  // PCOLOR01 += 4
  ADD ECX, 16  // PCOLORDST += 4

  // 循环计数
  SUB EBX, 4
  JNZ @@LOOPSTART

  // 恢复寄存器
  POP EBX
end;
{$ELSE IF WIN64}
asm
  PUSH  RBX
  MOV   EBX, R9D

  // 加载常量
  MOVDQU XMM6, [CONST_128]  // XMM6 = [128, 128, 128, 128]
  MOVDQU XMM7, [CONST_255]  // XMM7 = [255, 255, 255, 255]

  // 主循环
@@LOOPSTART:
  // 加载 PCOLOR01 和 PCOLOR02 的 4 个像素
  MOVUPS XMM0, [RCX]  // XMM0 = [PCOLOR01[0], PCOLOR01[1], PCOLOR01[2], PCOLOR01[3]]
  MOVUPS XMM1, [RDX]  // XMM1 = [PCOLOR02[0], PCOLOR02[1], PCOLOR02[2], PCOLOR02[3]]

  ADD RDX, 16  // PCOLOR02 += 4

  // 计算差值并加上 128
  PSUBB XMM0, XMM1  // XMM0 = PCOLOR01 - PCOLOR02
  PADDB XMM0, XMM6  // XMM0 = (PCOLOR01 - PCOLOR02) + 128

  // 饱和操作，确保值在 0 到 255 之间
  PMINUB XMM0, XMM7  // XMM0 = MIN(XMM0, 255)
  PMAXUB XMM0, XMM6  // XMM0 = MAX(XMM0, 0)

  // 存储结果
  MOVUPS [R8], XMM0

  // 更新指针
  ADD RCX, 16  // PCOLOR01 += 4
  ADD R8,  16  // PCOLORDST += 4

  // 循环计数
  SUB EBX, 4
  JNZ @@LOOPSTART

  POP RBX
end;
{$ELSE}
var
  X: Integer;
begin
  for X := 0 to bmpWidth - 1 do
  begin
    Inc(pColor02);
    pColorDst^.R := EnsureRange(pColor01^.R - pColor02^.R + 128, 0, 255);
    pColorDst^.G := EnsureRange(pColor01^.G - pColor02^.G + 128, 0, 255);
    pColorDst^.B := EnsureRange(pColor01^.B - pColor02^.B + 128, 0, 255);
    Inc(pColor01);
    Inc(pColorDst);
  end;
end;
{$ENDIF}

procedure EngraveLineSSE2(pColor01, pColor02: PRGBQuad; pColorDst: PRGBQuad; bmpWidth: Integer); assembler;
{$IFDEF WIN32}
asm
  // 保存寄存器
  PUSH EBX
  MOV  EBX, bmpWidth

  // 加载常量
  MOVDQU XMM6, [CONST_128]  // XMM6 = [128, 128, 128, 128]

  // 主循环
@@LOOPSTART:
  // 加载 PCOLOR01 和 PCOLOR02 的 4 个像素
  MOVUPS XMM1, [EAX]  // XMM0 = [PCOLOR01[0], PCOLOR01[1], PCOLOR01[2], PCOLOR01[3]]
  MOVUPS XMM0, [EDX]  // XMM1 = [PCOLOR02[0], PCOLOR02[1], PCOLOR02[2], PCOLOR02[3]]

  ADD EDX, 16  // PCOLOR02 += 4

  // 计算差值并加上 128
  PSUBB XMM0, XMM1  // XMM0 = PCOLOR01 - PCOLOR02
  PADDB XMM0, XMM6  // XMM0 = (PCOLOR01 - PCOLOR02) + 128

  // 存储结果
  MOVUPS [ECX], XMM0

  // 更新指针
  ADD EAX, 16  // PCOLOR01 += 4
  ADD ECX, 16  // PCOLORDST += 4

  // 循环计数
  SUB EBX, 4
  JNZ @@LOOPSTART

  // 恢复寄存器
  POP EBX
end;
{$ELSE IF WIN64}
asm
  PUSH  RBX
  MOV   EBX, R9D

  // 加载常量
  MOVDQU XMM6, [CONST_128]  // XMM6 = [128, 128, 128, 128]

  // 主循环
@@LOOPSTART:
  // 加载 PCOLOR01 和 PCOLOR02 的 4 个像素
  MOVUPS XMM1, [RCX]  // XMM0 = [PCOLOR01[0], PCOLOR01[1], PCOLOR01[2], PCOLOR01[3]]
  MOVUPS XMM0, [RDX]  // XMM1 = [PCOLOR02[0], PCOLOR02[1], PCOLOR02[2], PCOLOR02[3]]

  ADD RDX, 16  // PCOLOR02 += 4

  // 计算差值并加上 128
  PSUBB XMM0, XMM1  // XMM0 = PCOLOR01 - PCOLOR02
  PADDB XMM0, XMM6  // XMM0 = (PCOLOR01 - PCOLOR02) + 128

  // 存储结果
  MOVUPS [R8], XMM0

  // 更新指针
  ADD RCX, 16  // PCOLOR01 += 4
  ADD R8,  16  // PCOLORDST += 4

  // 循环计数
  SUB EBX, 4
  JNZ @@LOOPSTART

  POP RBX
end;
{$ELSE}
var
  X: Integer;
begin
  for X := 0 to bmpWidth - 1 do
  begin
    Inc(pColor02);
    pColorDst^.R := EnsureRange(pColor02^.R - pColor01^.R + 128, 0, 255);
    pColorDst^.G := EnsureRange(pColor02^.G - pColor01^.G + 128, 0, 255);
    pColorDst^.B := EnsureRange(pColor02^.B - pColor01^.B + 128, 0, 255);
    Inc(pColor01);
    Inc(pColorDst);
  end;
end;
{$ENDIF}

procedure VertiLineSSE2(Line1, Line2: PByte; Count: Integer);
{$IFDEF WIN32}
asm
@@LOOP:
  MOVDQA  XMM0, [EAX]
  MOVDQA  XMM1, [EDX]
  MOVDQA  [EAX], XMM1
  MOVDQA  [EDX], XMM0

  ADD     EAX, 16
  ADD     EDX, 16
  DEC     ECX
  JNZ     @@LOOP
END;

{$ELSE IF WIN64}

ASM
@@LOOP:
  MOVDQA  XMM0, [RCX]
  MOVDQA  XMM1, [RDX]
  MOVDQA  [RCX], XMM1
  MOVDQA  [RDX], XMM0

  ADD     RCX, 16
  ADD     RDX, 16
  DEC     R8
  JNZ     @@LOOP
end;
{$ENDIF}

{ SSE 效率提升不高 }
procedure Rotate90LineSSE2(BaseSrc, BaseDst: PByte; const iHeight: Integer; const bmpWidthBytesSrc: NativeInt);
asm
  {$IFDEF WIN32}
  push    ebx
  push    esi
  push    edi

  shr     ecx, 2                // 循环次数 = iHeight/4
  mov     ebx, bmpWidthBytesSrc // ebx 存储 bmpWidthBytesSrc
  neg     ebx                   // 负步长用于向上访问内存
  lea     edi, [ebx*2]          // edi = 2*步长 (预计算)

@loop:
  // 正确加载4个垂直像素
  movd    xmm0, [eax]           // 像素0 (当前行)
  movd    xmm1, [eax+ebx]       // 像素1 (上1行)
  movd    xmm2, [eax+edi]       // 像素2 (上2行)

  // 正确计算第3行地址：ebx + edi = 3*步长
  lea     esi,  [eax+ebx]       // 计算第1行地址
  add     esi,  edi             // 第1行地址 + 2步 = 第3行地址
  movd    xmm3, [esi]           // 像素3 (上3行)

  // 组合像素到xmm0: [p0|p1|p2|p3]
  punpckldq  xmm0, xmm1         // [p1|p0]
  punpckldq  xmm2, xmm3         // [p3|p2]
  punpcklqdq xmm0, xmm2         // [p3|p2|p1|p0]

  // 更新指针
  lea     eax, [eax+edi*2]      // 源指针上移4行 (edi*2 = 4*步长)
  movdqu  [edx], xmm0           // 存储4像素
  add     edx, 16               // 目标指针前进16字节

  dec     ecx
  jnz     @loop

  pop     edi
  pop     esi
  pop     ebx
  {$ENDIF}
end;

procedure Rotate_SSE_Proc(const krx, kry, intOffset: Integer; const srcBits: PRGBQuadArray; dstBits: PRGBQuadArray; const rac, ras: Integer; const dstWidth, srcWidth, srcHeight: DWORD); assembler;
asm
  {$IFDEF  WIN32}
  PUSH    EBX

  MOV     EBX,   ECX            // EBX = intOffset
  MOV     ECX,   dstWidth       // ECX = dstWidth 循环计数
  MOVD    XMM1,  rac            // XMM1 = 0, 0, 0, rac
  MOVD    XMM0,  ras            // XMM0 = 0, 0, 0, ras
  SHUFPS  XMM0,  XMM1, 0        // XMM0 = rac, rac, ras, ras
  MOVD    XMM2,  krx            // XMM2 = 0, 0, 0, krx
  MOVD    XMM1,  kry            // XMM1 = 0, 0, 0, kry
  SHUFPS  XMM1,  XMM2, 0        // XMM1 = krx, krx, kry, kry

@LOOP:
  MOVD    XMM4,  ECX            // XMM4 = 0, 0, 0, dstX
  SHUFPS  XMM4,  XMM4, 0        // XMM4 = dstX, dstX, dstX, dstX

  PMULLD  XMM4,  XMM0           // dstX * rac | dstX * ras
  PSUBD   XMM4,  XMM1           // dstX * rac - krx | dstX * ras - kry
  PSRLD   XMM4,  8              // (dstX * rac - krx) shr 8 | (dstX * ras - kry) shr 8

  PEXTRD  EAX,   XMM4, 3        // EAX = (dstX * rac - krx) shr 8  = SrcX
  PEXTRD  EDX,   XMM4, 1        // EDX = (dstX * ras - kry) shr 8  = SrcY

  CMP   EAX,  srcWidth          // IF SrcX < srcWidth
  JNB   @NEXT                   //
  CMP   EDX,  srcHeight         // IF SrcY < srcHeight
  JNB   @NEXT                   //

  MOV  EDI,  EDX                // EDI = (dstX * ras - kry) shr 8  = SrcY
  IMUL EDI,  srcWidth           // EDI = SrcY * srcWidth
  ADD  EDI,  EAX                // EDI = SrcY * srcWidth + SrcX
  MOV  EDX,  [srcBits]          // EDI = [srcBits]
  MOV  EDI,  [EDX + EDI * 4]    // EDI = srcBits[SrcY * srcWidth + SrcX]

  MOV  EDX,  EBX                // EDX = intOffset
  ADD  EDX,  ECX                // EDX = intOffset + dstX
  MOV  ESI,  [dstBits]          // ESI = [dstBits]
  MOV  [ESI + EDX * 4], EDI     // dstBits[IndexRow * Integer(dstWidth) + dstX] = EDI

@NEXT:
  DEC  ECX
  JNZ  @LOOP

  POP  EBX
  {$IFEND}
end;

type
  TBMPAccess         = class(TBitmap);
  TBitmapImageAccess = class(TBitmapImage);

procedure Optimize07(bmpSrc, bmpDst: TBitmap; const RotaryAngle: double; const CenterX, CenterY, MoveX, MoveY: Integer; const ras: Integer = 0; rac: Integer = 0);
var
  srcBits  : PRGBQuadArray;
  dstBits  : PRGBQuadArray;
  cxc, cxs : Integer;
  cyc, cys : Integer;
  kcx, kcy : Integer;
  dstWidth : Integer;
  dstHeight: Integer;
  srcWidth : Integer;
  srcHeight: Integer;
begin
  srcBits   := TBitmapImageAccess(TBMPAccess(bmpSrc).FImage).FDIB.dsBm.bmBits;
  dstBits   := TBitmapImageAccess(TBMPAccess(bmpDst).FImage).FDIB.dsBm.bmBits;
  dstWidth  := bmpDst.Width;
  dstHeight := bmpDst.Height;
  srcWidth  := bmpSrc.Width;
  srcHeight := bmpSrc.Height;
  cxc       := (CenterX + MoveX) * rac;
  cxs       := (CenterX + MoveX) * ras;
  cys       := (CenterY + MoveY) * ras;
  cyc       := (CenterY + MoveY) * rac;
  kcx       := cxc - cys - CenterX * (1 shl 8);
  kcy       := cxs + cyc - CenterY * (1 shl 8);
  TParallel.For(0, dstHeight - 1,
    procedure(dstY: Integer)
    var
      krx, kry: Integer;
      intOffset: Integer;
    begin
      krx := kcx + dstY * ras;
      kry := kcy - dstY * rac;
      intOffset := dstY * dstWidth;
      Rotate_SSE_Proc(krx, kry, intOffset, srcBits, dstBits, rac, ras, dstWidth, srcWidth, srcHeight);
    end);
end;
