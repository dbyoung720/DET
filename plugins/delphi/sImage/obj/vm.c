#include <windows.h>
#include <immintrin.h>
#include <omp.h>

//c++、x86 平台，使用 avx2 优化，将一幅32位位图图像(bgra)进行垂直镜像。

void vmirror01(unsigned char* bmpData, int width, int height) 
{
    const int pixelSize = 4; // BGRA每个像素4字节
    int rowBytes = width * pixelSize;
    unsigned char* topRow    = bmpData;
    unsigned char* bottomRow = bmpData + (height - 1) * rowBytes;

    for (int y = 0; y < height / 2; ++y) 
    {
        int x = 0;
        
        // 使用AVX2每次处理32字节（8个像素）
        for (; x + 31 < rowBytes; x += 32) 
        {
            // 加载顶部和底部行的256位数据
            __m256i top    = _mm256_loadu_si256((__m256i*)(topRow + x));
            __m256i bottom = _mm256_loadu_si256((__m256i*)(bottomRow + x));
            
            // 交换数据
            _mm256_storeu_si256((__m256i*)(topRow + x), bottom);
            _mm256_storeu_si256((__m256i*)(bottomRow + x), top);
        }
        
        // 处理剩余不足32字节的部分
        for (; x < rowBytes; ++x) 
        {
            //std::swap(topRow[x], bottomRow[x]);
            unsigned char temp = topRow[x];
            topRow[x]    = bottomRow[x];
            bottomRow[x] = temp;
       }
        topRow    += rowBytes;
        bottomRow -= rowBytes;
    }
}

void vmirror02(unsigned char* bmpData, int width, int height) 
{
    const int pixelSize = 4; // BGRA每个像素4字节
    const int rowBytes = width * pixelSize;
    
    // 使用OpenMP并行化外层循环
    #pragma omp parallel for
    for (int y = 0; y < height / 2; ++y) 
    {
        unsigned char* topRow    = bmpData + y * rowBytes;
        unsigned char* bottomRow = bmpData + (height - 1 - y) * rowBytes;
        
        int x = 0;
        
        // 使用AVX2每次处理32字节（8个像素）
        for (; x + 31 < rowBytes; x += 32) 
        {
            // 加载顶部和底部行的256位数据
            __m256i top    = _mm256_loadu_si256((__m256i*)(topRow + x));
            __m256i bottom = _mm256_loadu_si256((__m256i*)(bottomRow + x));
            
            // 交换数据
            _mm256_storeu_si256((__m256i*)(topRow + x), bottom);
            _mm256_storeu_si256((__m256i*)(bottomRow + x), top);
        }
        
        // 处理剩余不足32字节的部分
        for (; x < rowBytes; ++x) 
        {
            unsigned char temp = topRow[x];
            topRow[x]    = bottomRow[x];
            bottomRow[x] = temp;
        }
    }
}
