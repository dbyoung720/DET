unit bmp32_SSE4;

interface

uses System.Win.Crtl;

procedure gray_row_sse4(row_ptr: Pointer; width: Integer); cdecl;

implementation

{$L 'bmp32_x64_sse4.o'}

procedure gray_row_sse4(row_ptr: Pointer; width: Integer); cdecl; external name 'gray_row';

end.
