unit bmp32_AVX2;

interface

uses System.Win.Crtl;

procedure gray_row_avx2(row_ptr: Pointer; width: Integer); cdecl;

implementation

{$L 'bmp32_x64_avx2.o'}

procedure gray_row_avx2(row_ptr: Pointer; width: Integer); cdecl; external name 'gray_row';

end.
