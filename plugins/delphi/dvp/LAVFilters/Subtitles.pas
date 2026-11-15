unit Subtitles;

{ 字幕解析与存储：SRT / ASS(SSA) Dialogue / VTT / SMI 基础支持；内嵌字幕流采样与外挂字幕共用同一存储 }

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, System.RegularExpressions;

type
  TSubtitleItem = record
    StartUs: Int64;   // 微秒
    EndUs  : Int64;   // 
    Text   : string;  // 已去除标记，换行为 #13#10
  end;

// 时间换算（DirectShow 100ns <-> 微秒）
function DsToUs(Ds: Int64): Int64; inline;
function UsToDs(Us: Int64): Int64; inline;

// 去除 ASS 覆盖标记 {…} 与 HTML 标记
function StripSubTags(const S: string): string;

// 解析外挂字幕文件（自动识别 SRT / ASS / SSA / VTT / SMI）
procedure ParseSubtitleFile(const FileName: string; List: TList<TSubtitleItem>);

// 解析一条完整的 DirectShow 字幕采样（UTF8/ASS 文本，带采样时间，微秒）
procedure AddSampleText(List: TList<TSubtitleItem>; StartUs, EndUs: Int64; const Txt: string; const Subtype: TGUID; const FormatType: TGUID; const FmtData: PByte; FmtSize: Integer);

// 在某时间点（含延迟偏移，微秒）取当前字幕；P = PosUs - DelayUs
function FindSubtitleText(const List: TList<TSubtitleItem>; PosUs: Int64; DelayUs: Int64; out Text: string): Boolean;

// 读取文本文件（UTF-8 / UTF-16 BOM / ANSI 回退）
function ReadSubtitleText(const FileName: string): string;

implementation

// ---- 时间换算 ----
function DsToUs(Ds: Int64): Int64;
begin
  Result := Ds div 10;
end;

function UsToDs(Us: Int64): Int64;
begin
  Result := Us * 10;
end;

// ---- 通用清洗 ----
function StripSubTags(const S: string): string;
var
  InBrace: Boolean;
begin
  var SB := TStringBuilder.Create(Length(S));
  try
    InBrace := False;
    for var i := 1 to Length(S) do
    begin
      if S[i] = '{' then
        InBrace := True
      else if S[i] = '}' then
        InBrace := False
      else if not InBrace then
        SB.Append(S[i]);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function StripHtml(const S: string): string;
begin
  Result := TRegEx.Replace(S, '</?[biu]>', '', [roIgnoreCase]);
  Result := TRegEx.Replace(Result, '</?font[^>]*>', '', [roIgnoreCase]);
end;

function NormalizeNewlines(const S: string): string;
begin
  Result := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
end;

// ---- 时间解析 ----
function TryParseTimeUs(const S: string; out Us: Int64): Boolean;
var
  Parts: TArray<string>;
  H, M, Sec, MSec, FracLen: Integer;
  DotPos: Integer;
  S2, Frac: string;
begin
  Result := False;
  Us := 0;
  S2 := Trim(S);
  DotPos := Pos('.', S2);
  if DotPos = 0 then DotPos := Pos(',', S2);
  if DotPos > 0 then
  begin
    Frac := Trim(Copy(S2, DotPos + 1, MaxInt));
    MSec := 0;
    if TryStrToInt(Frac, MSec) then
    begin
      FracLen := Length(Frac);
      if FracLen = 2 then
        MSec := MSec * 10
      else if FracLen = 1 then
        MSec := MSec * 100
      else if FracLen > 3 then
        MSec := StrToIntDef(Copy(Frac, 1, 3), 0);
    end
    else
      MSec := 0;
    S2 := Trim(Copy(S2, 1, DotPos - 1));
  end
  else
    MSec := 0;
  Parts := S2.Split([':']);
  case Length(Parts) of
    3:
      begin
        H := StrToIntDef(Parts[0], 0);
        M := StrToIntDef(Parts[1], 0);
        Sec := StrToIntDef(Parts[2], 0);
      end;
    2:
      begin
        H := 0;
        M := StrToIntDef(Parts[0], 0);
        Sec := StrToIntDef(Parts[1], 0);
      end;
    1:
      begin
        H := 0;
        M := 0;
        Sec := StrToIntDef(Parts[0], 0);
      end;
  else
    Exit;
  end;
  // 必须用 Int64 运算：*1000 再 *1000 后 35 分钟以上就会超出 Integer 范围
  Us := ((Int64(H) * 3600 + Int64(M) * 60 + Sec) * 1000 + MSec) * 1000;
  Result := True;
end;

procedure AddItem(List: TList<TSubtitleItem>; S, E: Int64; const Txt: string);
var
  It: TSubtitleItem;
begin
  if Trim(Txt) = '' then Exit;
  
  if E <= S then E := S + 2000000;
  It.StartUs := S;
  It.EndUs := E;
  It.Text := Txt;
  List.Add(It);
end;

// ---- ASS / SSA ----

// Dialogue: [Layer|Marked],Start,End,Style,Name,MarginL,MarginR,MarginV,Effect,Text
procedure ParseAssLines(Lines: TArray<string>; List: TList<TSubtitleItem>);
var
  L, Rest, Txt: string;
  M           : TMatch;
  Flds        : TArray<string>;
  S, E        : Int64;
  i, j        : Integer;
  SB          : TStringBuilder;
begin
  for i := 0 to High(Lines) do
  begin
    L := Trim(Lines[i]);
    if not L.StartsWith('Dialogue:', True) then Continue;
    Rest := Trim(Copy(L, Length('Dialogue:') + 1, MaxInt));
    M := TRegEx.Match(Rest, '^\s*[^,]*,\s*([^,]+),\s*([^,]+),\s*(.*)$');
    if not M.Success then Continue;
    if not TryParseTimeUs(M.Groups[1].Value, S) then Continue;
    if not TryParseTimeUs(M.Groups[2].Value, E) then Continue;
    Rest := M.Groups[3].Value;
    // Rest = Style,Name,MarginL,MarginR,MarginV,Effect,Text（跳过前 6 个字段）
    Flds := Rest.Split([',']);
    if Length(Flds) > 6 then
    begin
      SB := TStringBuilder.Create;
      for j := 6 to High(Flds) do
      begin
        if SB.Length > 0 then
          SB.Append(',');
        SB.Append(Flds[j]);
      end;
      Txt := SB.ToString;
      SB.Free;
    end
    else
      Txt := Rest;
    Txt := StringReplace(Txt, '\N', #13#10, [rfReplaceAll, rfIgnoreCase]);
    Txt := StringReplace(Txt, '\n', ' ', [rfReplaceAll]);
    Txt := StringReplace(Txt, '\h', ' ', [rfReplaceAll]);
    Txt := StripSubTags(Txt);
    StripHtml(Txt);
    AddItem(List, S, E, Txt);
  end;
end;

// ---- SRT / VTT ----
procedure ParseSrtLines(Lines: TArray<string>; List: TList<TSubtitleItem>);
var
  i    : Integer;
  L    : string;
  S, E : Int64;
  Txt  : string;
  State: Integer; // 0=找时间行 1=收集文本
begin
  S := 0; E := 0; Txt := ''; State := 0;
  for i := 0 to High(Lines) do
  begin
    L := Trim(Lines[i]);
    if State = 0 then
    begin
      if (L <> '') and (Pos('-->', L) > 0) then
      begin
        var SepPos := Pos('-->', L);
        if TryParseTimeUs(Trim(Copy(L, 1, SepPos - 1)), S) and
           TryParseTimeUs(Trim(Copy(L, SepPos + 4, MaxInt)), E) then
        begin
          Txt := '';
          State := 1;
        end;
      end;
    end
    else
    begin
      if L = '' then
      begin
        if Txt <> '' then
        begin
          AddItem(List, S, E, Txt);
          Txt := '';
        end;
        State := 0;
      end
      else
      begin
        if Txt <> '' then
          Txt := Txt + #13#10;
        Txt := Txt + StripHtml(L);
    // StripHtml is function now
      end;
    end;
  end;
  if Txt <> '' then
    AddItem(List, S, E, Txt);
end;

// ---- SMI ----
procedure ParseSmiContent(const Content: string; List: TList<TSubtitleItem>);
var
  Matches: TArray<TMatch>;
  MC     : TMatchCollection;
  i      : Integer;
  StartMs, NextMs: Int64;
  Txt: string;
begin
  MC := TRegEx.Matches(Content, '<sync\s+start\s*=\s*(\d+)[^>]*>(.*?)</sync>', [roIgnoreCase, roSingleLine]);
  SetLength(Matches, MC.Count);
  for i := 0 to MC.Count - 1  do Matches[i] := MC[i];
  for i := 0 to High(Matches) do
  begin
    StartMs := StrToInt64Def(Matches[i].Groups[1].Value, 0);
    Txt := TRegEx.Replace(Matches[i].Groups[2].Value, '<[^>]+>', '');
    Txt := Trim(StringReplace(Txt, '&nbsp;', ' ', [rfReplaceAll, rfIgnoreCase]));
    Txt := StringReplace(Txt, '<br>', #13#10, [rfReplaceAll, rfIgnoreCase]);
    if Txt = '' then Continue;
    if i < High(Matches) then
      NextMs := StrToInt64Def(Matches[i + 1].Groups[1].Value, StartMs + 3000)
    else
      NextMs := StartMs + 3000;
    AddItem(List, StartMs * 1000, NextMs * 1000, Txt);
  end;
end;

// ---- 入口 ----
procedure ParseSubtitleFile(const FileName: string; List: TList<TSubtitleItem>);
begin
  var Content := ReadSubtitleText(FileName);
  var Ext     := LowerCase(ExtractFileExt(FileName));
  if (Ext = '.ass') or (Ext = '.ssa') then
    ParseAssLines(NormalizeNewlines(Content).Split([#10]), List)
  else if (Ext = '.smi') or (Ext = '.sami') then
    ParseSmiContent(Content, List)
  else
  begin
    if TRegEx.IsMatch(Content, 'Dialogue\s*:') and not TRegEx.IsMatch(Content, '-->') then
      ParseAssLines(NormalizeNewlines(Content).Split([#10]), List)
    else
      ParseSrtLines(NormalizeNewlines(Content).Split([#10]), List);
  end;
end;

// ---- 内嵌字幕采样 ----
procedure AddSampleText(List: TList<TSubtitleItem>; StartUs, EndUs: Int64; const Txt: string; const Subtype: TGUID; const FormatType: TGUID; const FmtData: PByte; FmtSize: Integer);
var
  Body: string;
begin
  Body := StringReplace(Txt, '\N', #13#10, [rfReplaceAll, rfIgnoreCase]);
  Body := StripSubTags(Body);
  StripHtml(Body);
  AddItem(List, StartUs, EndUs, Body);
end;

function FindSubtitleText(const List: TList<TSubtitleItem>; PosUs: Int64; DelayUs: Int64; out Text: string): Boolean;
var
  It: TSubtitleItem;
begin
  Result := False;
  Text  := '';
  var P := PosUs - DelayUs;
  for It in List do
  begin
    if (P >= It.StartUs) and (P <= It.EndUs) then
    begin
      Text := It.Text;
      Result := True;
      Exit;
    end;
  end;
end;

function ReadSubtitleText(const FileName: string): string;
var
  FS  : TFileStream;
  Size: Integer;
  Buf : TBytes;
  Enc : TEncoding;
  S   : string;
begin
  Result := '';
  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Size := FS.Size;
    SetLength(Buf, Size);
    if Size > 0 then FS.ReadBuffer(Buf[0], Size);
    if (Size >= 3) and (Buf[0] = $EF) and (Buf[1] = $BB) and (Buf[2] = $BF) then
    begin
      // UTF-8 BOM
      Result := TEncoding.UTF8.GetString(Copy(Buf, 3, Size - 3));
    end
    else if (Size >= 2) and (Buf[0] = $FF) and (Buf[1] = $FE) then
      Result := TEncoding.Unicode.GetString(Copy(Buf, 2, Size - 2))
    else if (Size >= 2) and (Buf[0] = $FE) and (Buf[1] = $FF) then
      Result := TEncoding.BigEndianUnicode.GetString(Copy(Buf, 2, Size - 2))
    else
    begin
      // 无 BOM：先按 UTF-8，发现 U+FFFD 则回退 ANSI
      Enc := TEncoding.GetEncoding(65001);
      S := Enc.GetString(Buf);
      if Pos(#$FFFD, S) > 0 then S := TEncoding.Default.GetString(Buf);
      Result := S;
    end;
  finally
    FS.Free;
  end;
end;

end.
