unit SevenZip.Static;

{ 7-Zip C 层的静态链接单元
  32 位、64 位均由 clang-cl 生成 COFF OBJ，由 Delphi 直接链接。
  全部内存由 Delphi 内存管理器提供，不依赖 7z.dll / MSVCRT。 
}

interface

uses System.SysUtils, System.Classes, System.IOUtils;

type
  E7zError = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer);
    property Code: Integer read FCode;
  end;

  T7zArchive = class
  private
    FHandle: Pointer;
    FData  : TBytes;
    procedure Check(ACode: Integer);
  public
    constructor Create(const AData: TBytes);
    destructor Destroy; override;
    function Count: Integer;
    function IsDir(AIndex: Integer): Boolean;
    function Name(AIndex: Integer): string;
    function Size(AIndex: Integer): UInt64;
    function Extract(AIndex: Integer): TBytes;
    procedure ExtractToFile(AIndex: Integer; const AFileName: string);
    procedure ExtractAll(const ADir: string);
  end;

function SevenZipVersion: Integer;
function Crc32Of(const AData: TBytes): Cardinal;
procedure LzmaCompress(const ASrc: TBytes; ALevel: Integer; out ADest, AProps: TBytes);
function LzmaDecompress(const ASrc, AProps: TBytes; AExpectedSize: NativeUInt): TBytes;
function SResText(ACode: Integer): string;

implementation

const
  SZ_OK                = 0;
  SZ_ERROR_DATA        = 1;
  SZ_ERROR_MEM         = 2;
  SZ_ERROR_CRC         = 3;
  SZ_ERROR_UNSUPPORTED = 4;
  SZ_ERROR_PARAM       = 5;
  SZ_ERROR_INPUT_EOF   = 6;
  SZ_ERROR_OUTPUT_EOF  = 7;
  SZ_ERROR_FAIL        = 11;

type
  TMemAllocProc = function(AUser: Pointer; ASize: NativeUInt): Pointer; stdcall;
  TMemFreeProc  = procedure(AUser: Pointer; APtr: Pointer); stdcall;

procedure SzsInitialize(AAlloc: TMemAllocProc; AFree: TMemFreeProc; AUser: Pointer); stdcall; {$IFDEF WIN32} external name '_SzsInitialize@12' {$ELSE} external name 'SzsInitialize' {$ENDIF};
function SzsVersion: Cardinal; stdcall; {$IFDEF WIN32} external name '_SzsVersion@0' {$ELSE} external name 'SzsVersion' {$ENDIF};
function Szs7zOpen(AData: Pointer; ASize: NativeUInt; out AHandle: Pointer): Integer; stdcall; {$IFDEF WIN32} external name '_Szs7zOpen@12' {$ELSE} external name 'Szs7zOpen' {$ENDIF};
procedure Szs7zClose(AHandle: Pointer); stdcall; {$IFDEF WIN32} external name '_Szs7zClose@4' {$ELSE} external name 'Szs7zClose' {$ENDIF};
function Szs7zCount(AHandle: Pointer): Integer; stdcall; {$IFDEF WIN32} external name '_Szs7zCount@4' {$ELSE} external name 'Szs7zCount' {$ENDIF};
function Szs7zIsDir(AHandle: Pointer; AIndex: Integer): Integer; stdcall; {$IFDEF WIN32} external name '_Szs7zIsDir@8' {$ELSE} external name 'Szs7zIsDir' {$ENDIF};
function Szs7zNameLen(AHandle: Pointer; AIndex: Integer): Integer; stdcall; {$IFDEF WIN32} external name '_Szs7zNameLen@8' {$ELSE} external name 'Szs7zNameLen' {$ENDIF};
function Szs7zGetName(AHandle: Pointer; AIndex: Integer; ABuf: PWideChar; ABufLen: Integer): Integer; stdcall; {$IFDEF WIN32} external name '_Szs7zGetName@16' {$ELSE} external name 'Szs7zGetName' {$ENDIF};
function Szs7zSize(AHandle: Pointer; AIndex: Integer): UInt64; stdcall; {$IFDEF WIN32} external name '_Szs7zSize@8' {$ELSE} external name 'Szs7zSize' {$ENDIF};
function Szs7zExtract(AHandle: Pointer; AIndex: Integer; AOut: PByte; AOutCap: NativeUInt; var AOutLen: NativeUInt): Integer; stdcall; {$IFDEF WIN32} external name '_Szs7zExtract@20' {$ELSE} external name 'Szs7zExtract' {$ENDIF};
function SzsLzmaCompress(ADest: PByte; var ADestLen: NativeUInt; ASrc: PByte; ASrcLen: NativeUInt; AProps: PByte; var APropsSize: NativeUInt; ALevel: Integer): Integer; stdcall; {$IFDEF WIN32} external name '_SzsLzmaCompress@28' {$ELSE} external name 'SzsLzmaCompress' {$ENDIF};
function SzsLzmaUncompress(ADest: PByte; var ADestLen: NativeUInt; ASrc: PByte; var ASrcLen: NativeUInt; AProps: PByte; APropsSize: NativeUInt): Integer; stdcall; {$IFDEF WIN32} external name '_SzsLzmaUncompress@24' {$ELSE} external name 'SzsLzmaUncompress' {$ENDIF};
function SzsCrc32(AData: PByte; ALen: NativeUInt): Cardinal; stdcall; {$IFDEF WIN32} external name '_SzsCrc32@8' {$ELSE} external name 'SzsCrc32' {$ENDIF};

{$IFDEF WIN32}
  {$I .\obj\link_x86.inc}
  {$I .\obj\syms_x86.inc}
{$ELSE}
  {$I .\obj\link_x64.inc}
  {$I .\obj\syms_x64.inc}
{$ENDIF}

function SResText(ACode: Integer): string;
begin
  case ACode of
    SZ_OK:
      Result := '成功';
    SZ_ERROR_DATA:
      Result := '数据错误';
    SZ_ERROR_MEM:
      Result := '内存不足';
    SZ_ERROR_CRC:
      Result := 'CRC 校验失败';
    SZ_ERROR_UNSUPPORTED:
      Result := '不支持的格式或算法';
    SZ_ERROR_PARAM:
      Result := '参数错误';
    SZ_ERROR_INPUT_EOF:
      Result := '输入数据不完整';
    SZ_ERROR_OUTPUT_EOF:
      Result := '输出缓冲区不足';
    SZ_ERROR_FAIL:
      Result := '解压失败';
  else
    Result := '7-Zip 错误 ' + IntToStr(ACode);
  end;
end;

constructor E7zError.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited Create(SResText(ACode) + '（错误码 ' + IntToStr(ACode) + '）');
end;

function MemAlloc(AUser: Pointer; ASize: NativeUInt): Pointer; stdcall;
begin
  Result := nil;
  try
    GetMem(Result, ASize);
  except
    Result := nil;
  end;
end;

procedure MemFree(AUser: Pointer; APtr: Pointer); stdcall;
begin
  if APtr <> nil then FreeMem(APtr);
end;

function SevenZipVersion: Integer;
begin
  Result := Integer(SzsVersion);
end;

function Crc32Of(const AData: TBytes): Cardinal;
begin
  if Length(AData) = 0 then
    Result := SzsCrc32(nil, 0)
  else
    Result := SzsCrc32(@AData[0], Length(AData));
end;

procedure LzmaCompress(const ASrc: TBytes; ALevel: Integer; out ADest, AProps: TBytes);
var
  DestLen, PropsSize, Cap: NativeUInt;
  Code                   : Integer;
begin
  ADest := nil;
  SetLength(AProps, 5);
  PropsSize := 5;
  Cap       := Length(ASrc) + Length(ASrc) div 4 + 65536;
  if Cap < 65536 then Cap := 65536;
  repeat
    SetLength(ADest, Cap);
    DestLen := Cap;
    if Length(ASrc) > 0 then
      Code := SzsLzmaCompress(@ADest[0], DestLen, @ASrc[0], Length(ASrc), @AProps[0], PropsSize, ALevel)
    else
      Code := SzsLzmaCompress(@ADest[0], DestLen, nil, 0, @AProps[0], PropsSize, ALevel);
    if Code = SZ_ERROR_OUTPUT_EOF then Cap := Cap + Cap div 2 + 65536;
  until Code <> SZ_ERROR_OUTPUT_EOF;
  if Code <> SZ_OK then raise E7zError.CreateCode(Code);
  SetLength(ADest, DestLen);
  SetLength(AProps, PropsSize);
end;

function LzmaDecompress(const ASrc, AProps: TBytes; AExpectedSize: NativeUInt): TBytes;
var
  DestLen, SrcLen: NativeUInt;
  Code           : Integer;
begin
  SetLength(Result, AExpectedSize);
  DestLen := AExpectedSize;
  SrcLen  := Length(ASrc);
  if AExpectedSize = 0 then Exit;
  
  if SrcLen = 0 then
    Code := SzsLzmaUncompress(@Result[0], DestLen, nil, SrcLen, @AProps[0], Length(AProps))
  else
    Code := SzsLzmaUncompress(@Result[0], DestLen, @ASrc[0], SrcLen, @AProps[0], Length(AProps));
  if Code <> SZ_OK then raise E7zError.CreateCode(Code);
  SetLength(Result, DestLen);
end;

{ T7zArchive }

constructor T7zArchive.Create(const AData: TBytes);
var
  Code: Integer;
  P   : Pointer;
begin
  inherited Create;
  FHandle := nil;
  FData   := AData;
  P       := nil;
  if Length(FData) > 0 then P  := @FData[0];
  Code := Szs7zOpen(P, Length(FData), FHandle);
  Check(Code);
end;

destructor T7zArchive.Destroy;
begin
  if FHandle <> nil then Szs7zClose(FHandle);
  FHandle := nil;
  inherited Destroy;
end;

procedure T7zArchive.Check(ACode: Integer);
begin
  if ACode <> SZ_OK then raise E7zError.CreateCode(ACode);
end;

function T7zArchive.Count: Integer;
begin
  Result := Szs7zCount(FHandle);
end;

function T7zArchive.IsDir(AIndex: Integer): Boolean;
begin
  Result := Szs7zIsDir(FHandle, AIndex) = 1;
end;

function T7zArchive.Name(AIndex: Integer): string;
var
  N  : Integer;
  Buf: array of WideChar;
begin
  N := Szs7zNameLen(FHandle, AIndex);
  if N < 0 then raise E7zError.CreateCode(SZ_ERROR_PARAM);
  if N = 0 then Exit('');
  SetLength(Buf, N + 1);
  Szs7zGetName(FHandle, AIndex, @Buf[0], N + 1);
  Result := string(PWideChar(@Buf[0]));
end;

function T7zArchive.Size(AIndex: Integer): UInt64;
begin
  Result := Szs7zSize(FHandle, AIndex);
end;

function T7zArchive.Extract(AIndex: Integer): TBytes;
var
  N   : NativeUInt;
  Code: Integer;
  Buf : array of Byte;
begin
  N := NativeUInt(Size(AIndex));
  SetLength(Buf, N + 1);
  Code := Szs7zExtract(FHandle, AIndex, @Buf[0], N + 1, N);
  Check(Code);
  SetLength(Result, N);
  if N > 0 then Move(Buf[0], Result[0], N);
end;

procedure T7zArchive.ExtractToFile(AIndex: Integer; const AFileName: string);
var
  Data  : TBytes;
  Stream: TFileStream;
begin
  Data   := Extract(AIndex);
  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(Data) > 0 then Stream.WriteBuffer(Data[0], Length(Data));
  finally
    Stream.Free;
  end;
end;

function SafeRelPath(const AName: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := StringReplace(AName, '/', '\', [rfReplaceAll]);
  Result := StringReplace(Result, '..', '_', [rfReplaceAll]);
  for I  := 1 to Length(Result) do
  begin
    C := Result[I];
    if C in ['"', '<', '>', '|', '*', '?', ':'] then Result[I] := '_';
  end;
  while (Length(Result) > 0) and (Result[1] = '\') do Delete(Result, 1, 1);
end;

procedure T7zArchive.ExtractAll(const ADir: string);
var
  Rel, Full: string;
begin
  for var I := 0 to Count - 1 do
  begin
    if IsDir(I) then Continue;

    Rel := SafeRelPath(Name(I));
    if Rel = '' then Continue;

    Full := TPath.Combine(ADir, Rel);
    TDirectory.CreateDirectory(TPath.GetDirectoryName(Full));
    ExtractToFile(I, Full);
  end;
end;

initialization
  SzsInitialize(MemAlloc, MemFree, nil);

end.
