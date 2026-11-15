$Host.UI.RawUI.ForegroundColor = 'Green'

if ($PSScriptRoot) { Set-Location -LiteralPath $PSScriptRoot }

$ISPCX86 = 'F:\Green\Language\scoop\x86\apps\ispc\current\ispc.exe'
$ISPCX64 = 'F:\Green\Language\scoop\x64\apps\ispc\current\ispc.exe'

$ispcSource = @'

// ===== 图像反色 =====
export void invert_row(uniform uint32 *uniform row_ptr, uniform int width)
{
    foreach (x = 0 ... width) 
    {
        uint32 p   = row_ptr[x];
        row_ptr[x] = (~p & 0x00FFFFFFu) | (p & 0xFF000000u);
    }
}

// ===== 图像灰度图 =====
export void gray_row(uniform uint32 *uniform row_ptr, uniform int width)
{
    foreach (x = 0 ... width) 
    {
        uint32 p = row_ptr[x];
        uint32 b =  p        & 0x000000FFu;
        uint32 g = (p >>  8) & 0x000000FFu;
        uint32 r = (p >> 16) & 0x000000FFu;
        uint32 a =  p        & 0xFF000000u;
        uint32 gray = (77u * r + 150u * g + 29u * b + 128u) >> 8;
        row_ptr[x]  = a | (gray << 16) | (gray << 8) | gray;
    }
}

// ===== 水平镜像 =====
export void hflip_row(uniform uint32 *uniform row_ptr, uniform int width)
{
    uniform int half = width / 2;
    foreach (x = 0 ... half)
    {
        int xr      = width - 1 - x;
        uint32 tmp  = row_ptr[x];
        row_ptr[x]  = row_ptr[xr];
        row_ptr[xr] = tmp;
    }
}

// ===== 垂直镜像 =====
export void vflip_rows(uniform uint32 *uniform row_a, uniform uint32 *uniform row_b, uniform int width)
{
    foreach (x = 0 ... width)
    {
        uint32 tmp = row_a[x];
        row_a[x]   = row_b[x];
        row_b[x]   = tmp;
    }
}

// ===== 透明叠加：全局 alpha =====
// src_row 为前景，dst_row 为背景，结果写回 dst_row。
// 公式：out = src * alpha/255 + dst * (1 - alpha/255)
// alpha 是 uniform 值 [0, 255]，0 = 完全透明（dst 不变），255 = 完全不透明（dst = src）。
// 8 位整数近似：(src*a + dst*(255-a) + 128) >> 8，误差 ≤ 1/255。
// 若需精确 255 除法，将 >>8 改为 /255 即可（代价是 SIMD 除法变慢）。
export void blend_row_const(uniform uint32 *uniform src_row,
                            uniform uint32 *uniform dst_row,
                            uniform int width,
                            uniform int alpha)
{
    uniform uint32 a   = (uint32)alpha;
    uniform uint32 inv = 255u - a;

    foreach (x = 0 ... width)
    {
        uint32 s = src_row[x];
        uint32 d = dst_row[x];

        uint32 sr = (s >> 16) & 0xFFu;
        uint32 sg = (s >>  8) & 0xFFu;
        uint32 sb =  s        & 0xFFu;
        uint32 sa = (s >> 24) & 0xFFu;

        uint32 dr = (d >> 16) & 0xFFu;
        uint32 dg = (d >>  8) & 0xFFu;
        uint32 db =  d        & 0xFFu;
        uint32 da = (d >> 24) & 0xFFu;

        uint32 r = (sr * a + dr * inv + 128u) >> 8;
        uint32 g = (sg * a + dg * inv + 128u) >> 8;
        uint32 b = (sb * a + db * inv + 128u) >> 8;
        uint32 o = (sa * a + da * inv + 128u) >> 8;

        dst_row[x] = (o << 24) | (r << 16) | (g << 8) | b;
    }
}


// ===== 透明叠加：逐像素 alpha =====
// 使用 src_row 像素自带 alpha 作为权重：
//   out_rgb = src_rgb * src_a + dst_rgb * (1 - src_a)
// 输出 alpha 采用 "over" 合成：out_a = src_a + dst_a * (1 - src_a)
// 若 dst 是已知不透明底图（da = 255），可将 out_a 简化固定为 255，能省 2 条指令。
export void blend_row_alpha(uniform uint32 *uniform src_row,
                            uniform uint32 *uniform dst_row,
                            uniform int width)
{
    foreach (x = 0 ... width)
    {
        uint32 s = src_row[x];
        uint32 d = dst_row[x];

        uint32 sa  = (s >> 24) & 0xFFu;
        uint32 inv = 255u - sa;

        uint32 sr = (s >> 16) & 0xFFu;
        uint32 sg = (s >>  8) & 0xFFu;
        uint32 sb =  s        & 0xFFu;

        uint32 dr = (d >> 16) & 0xFFu;
        uint32 dg = (d >>  8) & 0xFFu;
        uint32 db =  d        & 0xFFu;
        uint32 da = (d >> 24) & 0xFFu;

        uint32 r = (sr * sa + dr * inv + 128u) >> 8;
        uint32 g = (sg * sa + dg * inv + 128u) >> 8;
        uint32 b = (sb * sa + db * inv + 128u) >> 8;

        // over 合成：a_out = sa + da*(1 - sa)/255
        uint32 o = (sa + ((da * inv + 128u) >> 8));
        if (o > 255u) o = 255u;

        dst_row[x] = (o << 24) | (r << 16) | (g << 8) | b;
    }
}

// ===== RGB 转 HSV（float 输出，高精度）=====
//   h_row[x]: 色相 0~360
//   s_row[x]: 饱和度 0~1
//   v_row[x]: 明度  0~1
// 三个输出缓冲由调用方分配，长度均 >= width。
export void rgb_to_hsv_float_row(uniform uint32 *uniform src_row,
                                 uniform float  *uniform h_row,
                                 uniform float  *uniform s_row,
                                 uniform float  *uniform v_row,
                                 uniform int width)
{
    foreach (x = 0 ... width)
    {
        uint32 p = src_row[x];
        float r = (float)( p        & 0x000000FFu) * (1.0f / 255.0f);
        float g = (float)((p >>  8) & 0x000000FFu) * (1.0f / 255.0f);
        float b = (float)((p >> 16) & 0x000000FFu) * (1.0f / 255.0f);

        float maxc = max(max(r, g), b);
        float minc = min(min(r, g), b);
        float delta = maxc - minc;

        float h = 0.0f;
        float s = 0.0f;
        float v = maxc;

        if (delta > 0.0f)
        {
            s = delta / maxc;
            float inv_delta = 1.0f / delta;
            if (maxc == r)
            {
                h = (g - b) * inv_delta;
                if (h < 0.0f) h += 6.0f;
            }
            else if (maxc == g)
            {
                h = 2.0f + (b - r) * inv_delta;
            }
            else
            {
                h = 4.0f + (r - g) * inv_delta;
            }
            h *= 60.0f;
        }

        h_row[x] = h;
        s_row[x] = s;
        v_row[x] = v;
    }
}

// ===== HSV 转 RGB（float 输入，与 rgb_to_hsv_float_row 严格反向）=====
//   h_row[x]: 色相 0~360
//   s_row[x]: 饱和度 0~1
//   v_row[x]: 明度  0~1
// 输出到 dst_row[x]，位布局与 rgb_to_hsv_float_row 的输入一致：
//   A<<24 | B<<16 | G<<8 | R
// alpha 固定为 0xFF（不透明），因为 rgb_to_hsv_float_row 不携带 alpha。
export void hsv_to_rgb_float_row(uniform float  *uniform h_row,
                                 uniform float  *uniform s_row,
                                 uniform float  *uniform v_row,
                                 uniform uint32 *uniform dst_row,
                                 uniform int width)
{
    foreach (x = 0 ... width)
    {
        float h = h_row[x];
        float s = s_row[x];
        float v = v_row[x];

        float r = v;
        float g = v;
        float b = v;

        if (s > 0.0f)
        {
            float hh = h * (1.0f / 60.0f);
            if (hh >= 6.0f) hh = 0.0f;
            else if (hh < 0.0f) hh = 0.0f;

            int   i  = (int)hh;
            float ff = hh - (float)i;

            float minc = v * (1.0f - s);               // "p" 分量
            float q    = v * (1.0f - s * ff);          // 递减侧
            float t    = v * (1.0f - s * (1.0f - ff)); // 递增侧

            if      (i == 0) { r = v;    g = t;    b = minc; }
            else if (i == 1) { r = q;    g = v;    b = minc; }
            else if (i == 2) { r = minc; g = v;    b = t;    }
            else if (i == 3) { r = minc; g = q;    b = v;    }
            else if (i == 4) { r = t;    g = minc; b = v;    }
            else             { r = v;    g = minc; b = q;    }
        }

        uint32 ru = (uint32)(r * 255.0f + 0.5f);
        uint32 gu = (uint32)(g * 255.0f + 0.5f);
        uint32 bu = (uint32)(b * 255.0f + 0.5f);
        if (ru > 255u) ru = 255u;
        if (gu > 255u) gu = 255u;
        if (bu > 255u) bu = 255u;

        dst_row[x] = 0xFF000000u | (bu << 16) | (gu << 8) | ru;
    }
}

// ===== 任意角度旋转（逆向映射，定点 Q16.16，最近邻）=====
// 逐个输出像素从源图像反算采样位置：
//   x_src = cx + dx*cos + dy*sin
//   y_src = cy - dx*sin + dy*cos
// 其中 dx = x_out - cx，dy = y_out - cy（Q16.16）
//
// 参数约定：
//   center_x_fx, center_y_fx  旋转中心，Q16.16 = round(像素坐标 * 65536)
//   cos_fx, sin_fx            旋转角三角函数，Q16.16 = round(cos/sin * 65536)
//   y_out                     本函数写入的目标行号
//   bg_color                  越界像素的填充色（含 alpha）
//
// 中间乘积使用 int64：dx 可达 ±2^27、cos 达 ±2^15，Q16.16 乘法需要 int64 保精度。
// 若限制图像尺寸 (width*height <= ~2^12)，可将 int64 换成 int32 并降 cos 精度为 Q1.15。
export void rotate_row_nearest(
    uniform uint32 *uniform src_bitmap,
    uniform int src_width,
    uniform int src_height,
    uniform uint32 *uniform dst_bitmap,
    uniform int dst_width,
    uniform int center_x_fx,
    uniform int center_y_fx,
    uniform int cos_fx,
    uniform int sin_fx,
    uniform int y_out,
    uniform uint32 bg_color)
{
    uniform int64 dy_fx  = ((int64)y_out << 16) - (int64)center_y_fx;
    uniform int64 dy_cos = dy_fx * (int64)cos_fx;
    uniform int64 dy_sin = dy_fx * (int64)sin_fx;

    uniform uint32 *uniform dst_row = dst_bitmap + y_out * dst_width;

    foreach (x_out = 0 ... dst_width)
    {
        int64 dx_fx  = ((int64)x_out << 16) - (int64)center_x_fx;
        int64 dx_cos = dx_fx * (int64)cos_fx;
        int64 dx_sin = dx_fx * (int64)sin_fx;

        int64 x_src_fx = (int64)center_x_fx + (( dx_cos + dy_sin) >> 16);
        int64 y_src_fx = (int64)center_y_fx + ((-dx_sin + dy_cos) >> 16);

        int x_src = (int)(x_src_fx >> 16);
        int y_src = (int)(y_src_fx >> 16);

        uint32 pixel = bg_color;
        if (x_src >= 0 && x_src < src_width && y_src >= 0 && y_src < src_height)
        {
            pixel = src_bitmap[y_src * src_width + x_src];
        }
        dst_row[x_out] = pixel;
    }
}


// ===== 任意角度旋转（逆向映射，定点 Q16.16，双线性插值）=====
// 权重使用 8 位小数（fx/fy ∈ [0,255]，w00+w10+w01+w11 = 65536）。
// 越界的邻居用 bg_color 对应分量替代，保证边缘平滑过渡到背景。
export void rotate_row_bilinear(
    uniform uint32 *uniform src_bitmap,
    uniform int src_width,
    uniform int src_height,
    uniform uint32 *uniform dst_bitmap,
    uniform int dst_width,
    uniform int center_x_fx,
    uniform int center_y_fx,
    uniform int cos_fx,
    uniform int sin_fx,
    uniform int y_out,
    uniform uint32 bg_color)
{
    uniform int64 dy_fx  = ((int64)y_out << 16) - (int64)center_y_fx;
    uniform int64 dy_cos = dy_fx * (int64)cos_fx;
    uniform int64 dy_sin = dy_fx * (int64)sin_fx;

    uniform uint32 *uniform dst_row = dst_bitmap + y_out * dst_width;

    uniform int bg_a = (bg_color >> 24) & 0xFF;
    uniform int bg_r = (bg_color >> 16) & 0xFF;
    uniform int bg_g = (bg_color >>  8) & 0xFF;
    uniform int bg_b =  bg_color        & 0xFF;

    foreach (x_out = 0 ... dst_width)
    {
        int64 dx_fx  = ((int64)x_out << 16) - (int64)center_x_fx;
        int64 dx_cos = dx_fx * (int64)cos_fx;
        int64 dx_sin = dx_fx * (int64)sin_fx;

        int64 x_src_fx = (int64)center_x_fx + (( dx_cos + dy_sin) >> 16);
        int64 y_src_fx = (int64)center_y_fx + ((-dx_sin + dy_cos) >> 16);

        int x0 = (int)(x_src_fx >> 16);
        int y0 = (int)(y_src_fx >> 16);
        int fx = (int)((x_src_fx >> 8) & 0xFF);   // 0..255
        int fy = (int)((y_src_fx >> 8) & 0xFF);   // 0..255

        bool in_x0 = (x0     >= 0) && (x0     < src_width);
        bool in_x1 = (x0 + 1 >= 0) && (x0 + 1 < src_width);
        bool in_y0 = (y0     >= 0) && (y0     < src_height);
        bool in_y1 = (y0 + 1 >= 0) && (y0 + 1 < src_height);

        int p00_a = bg_a, p00_r = bg_r, p00_g = bg_g, p00_b = bg_b;
        int p10_a = bg_a, p10_r = bg_r, p10_g = bg_g, p10_b = bg_b;
        int p01_a = bg_a, p01_r = bg_r, p01_g = bg_g, p01_b = bg_b;
        int p11_a = bg_a, p11_r = bg_r, p11_g = bg_g, p11_b = bg_b;

        if (in_x0 && in_y0)
        {
            uint32 px = src_bitmap[ y0      * src_width + x0    ];
            p00_a = (px >> 24) & 0xFF; p00_r = (px >> 16) & 0xFF;
            p00_g = (px >>  8) & 0xFF; p00_b =  px        & 0xFF;
        }
        if (in_x1 && in_y0)
        {
            uint32 px = src_bitmap[ y0      * src_width + x0 + 1];
            p10_a = (px >> 24) & 0xFF; p10_r = (px >> 16) & 0xFF;
            p10_g = (px >>  8) & 0xFF; p10_b =  px        & 0xFF;
        }
        if (in_x0 && in_y1)
        {
            uint32 px = src_bitmap[(y0 + 1) * src_width + x0    ];
            p01_a = (px >> 24) & 0xFF; p01_r = (px >> 16) & 0xFF;
            p01_g = (px >>  8) & 0xFF; p01_b =  px        & 0xFF;
        }
        if (in_x1 && in_y1)
        {
            uint32 px = src_bitmap[(y0 + 1) * src_width + x0 + 1];
            p11_a = (px >> 24) & 0xFF; p11_r = (px >> 16) & 0xFF;
            p11_g = (px >>  8) & 0xFF; p11_b =  px        & 0xFF;
        }

        // 权重（和 = 65536）
        int w00 = (256 - fx) * (256 - fy);
        int w10 =  fx       * (256 - fy);
        int w01 = (256 - fx) *  fy;
        int w11 =  fx       *  fy;

        int r = (p00_r * w00 + p10_r * w10 + p01_r * w01 + p11_r * w11) >> 16;
        int g = (p00_g * w00 + p10_g * w10 + p01_g * w01 + p11_g * w11) >> 16;
        int b = (p00_b * w00 + p10_b * w10 + p01_b * w01 + p11_b * w11) >> 16;
        int a = (p00_a * w00 + p10_a * w10 + p01_a * w01 + p11_a * w11) >> 16;

        dst_row[x_out] = ((uint32)a << 24) | ((uint32)r << 16) | ((uint32)g << 8) | (uint32)b;
    }
}

'@

Set-Content -LiteralPath 'bmp32.ispc' -Value $ispcSource -Encoding ASCII

$exitCode = 0
try 
{
    & $ISPCX86 'bmp32.ispc' -o 'bmp32_x86_avx2.o' -h 'bmp32_x86.h' '--target=avx2'
    if ($LASTEXITCODE -ne 0) { $exitCode = $LASTEXITCODE }

    & $ISPCX86 'bmp32.ispc' -o 'bmp32_x86_sse4.o' -h 'bmp32_x86.h' '--target=sse4'
    if ($LASTEXITCODE -ne 0) { $exitCode = $LASTEXITCODE }

    & $ISPCX64 'bmp32.ispc' -o 'bmp32_x64_avx2.o' -h 'bmp32_x64.h' '--target=avx2'
    if ($LASTEXITCODE -ne 0) { $exitCode = $LASTEXITCODE }

    & $ISPCX64 'bmp32.ispc' -o 'bmp32_x64_sse4.o' -h 'bmp32_x64.h' '--target=sse4'
    if ($LASTEXITCODE -ne 0) { $exitCode = $LASTEXITCODE }
}
finally 
{
    Remove-Item -LiteralPath 'bmp32.ispc' -Force -ErrorAction SilentlyContinue
}

if ($exitCode -ne 0) 
{
    Write-Host "ispc 编译失败，退出码: $exitCode" -ForegroundColor Red
    exit $exitCode
}

Write-Host ''
Write-Host 'Press any key to continue . . .'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
