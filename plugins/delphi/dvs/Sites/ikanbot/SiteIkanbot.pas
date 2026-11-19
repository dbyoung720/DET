unit SiteIkanbot;

// ============================================================
// 爱看机器人 (2025v.ikanbot.com) 全网聚合搜索站点适配器
//   搜索: GET /search?q={URL编码词}
//         结果 <a href="/play/{id}" class="title-text">标题</a>
//   详情: /play/{id} （页面无明文线路，线路/剧集由 JS 调 API 获取）
//         从页面提取 3 个隐藏域：current_id / e_token / mtype
//         token 算法(逆向 get_tks)：取 current_id 后4位，逐位
//           off = digit mod 3 + 1，从 e_token 当前串切 off..off+8 共8字符，
//           然后从 e_token 删除前 off+8 字符，各片段拼接。
//         API: GET /api/getResN?videoId={id}&mtype={mtype}&token={token}
//         返回 data.list[]，每元素 resData 是 JSON 数组字符串：
//           [{"flag":"xlm3u8","url":"第01集$m3u8#第02集$m3u8#..."}]
//         分段：按 '#' 分集，每段取首个 'http' 起到末尾为 URL，之前为集名
//           （兼容 '第01集$url$yhm3u8' 多段 flag 后缀）
//   m3u8: 各第三方 CDN，多为单级 + AES-128 加密(key 相对路径,分片跨域绝对URL)
//   站点脚本: sites\ikanbot\ProxyHelper.mjs（改写 #EXT-X-KEY 的 URI 为本地 /key/）
//   注: 每集 PageUrl 直接存 m3u8 地址，BuildPlayCommand 无需再解析播放页
// ============================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.NetEncoding,
  System.JSON, System.RegularExpressions, System.Generics.Collections,  SiteIntf;

type
  TSiteIkanbot = class(TSiteBase)
  private
    FSiteRoot: string;
    FWorkDir: string;
    FSourcePlaylistFile: string;
    FProxyHelperFile: string;
    function MakeAbsolute(const AUrl: string): string;
    function StripTags(const AText: string): string;
    function CalcToken(const AId, AEToken: string): string;
    function ExtractHiddenValue(const AHtml, AId: string): string;
    procedure ParseResData(const AResJson, ALineName, ADataId: string;
      var AEpisodes: TEpisodeArray; var ASeen: TStringList);
    function DownloadPlaylistAndBuildCmd(const AM3U8Url: string; ADownload: Boolean; const AToken: string): string;
  public
    constructor Create(ACtx: TSiteContext); override;
    class function Id: string; override;
    class function DisplayName: string; override;
    class function DefaultKeyword: string; override;
    function Search(const AKeyword: string; AVideos: TStrings; out ASlugs: TSlugArray): Boolean; override;
    function LoadDetail(const ASlug: string; out AEpisodes: TEpisodeArray): Boolean; override;
    function BuildPlayCommand(const AEpisode: TEpisode): string; override;
    function BuildDownloadCommand(const AEpisode: TEpisode; const AToken: string): string; override;
    procedure Cleanup; override;
  end;

implementation

const
  SITE_ROOT = 'https://2025v.ikanbot.com';

constructor TSiteIkanbot.Create(ACtx: TSiteContext);
var
  SiteExe: string;
begin
  inherited Create(ACtx);
  BindSiteId;
  FSiteRoot := SITE_ROOT;
  FWorkDir := IncludeTrailingPathDelimiter(ACtx.TempRoot + Id);
  ForceDirectories(FWorkDir);
  FSourcePlaylistFile := TPath.Combine(FWorkDir, 'source.m3u8');

  SiteExe := SiteExeDir(ACtx.ExeDir);
  FProxyHelperFile := TPath.Combine(SiteExe, 'ProxyHelper.mjs');

  Ctx.Log('TSiteIkanbot created. proxy=' + FProxyHelperFile + ' exist=' + BoolToStr(TFile.Exists(FProxyHelperFile), True));
end;

class function TSiteIkanbot.Id: string;
begin
  Result := 'ikanbot';
end;

class function TSiteIkanbot.DisplayName: string;
begin
  Result := '爱看机器人';
end;

class function TSiteIkanbot.DefaultKeyword: string;
begin
  Result := '凡人修仙传';
end;

function TSiteIkanbot.MakeAbsolute(const AUrl: string): string;
begin
  if AUrl.StartsWith('http') then
    Result := AUrl
  else if AUrl.StartsWith('//') then
    Result := 'https:' + AUrl
  else if AUrl.StartsWith('/') then
    Result := FSiteRoot + AUrl
  else
    Result := FSiteRoot + '/' + AUrl;
end;

function TSiteIkanbot.StripTags(const AText: string): string;
var
  TagRe: TRegEx;
begin
  TagRe := TRegEx.Create('<[^>]+>', []);
  Result := Trim(TagRe.Replace(AText, ' '));
end;

function TSiteIkanbot.ExtractHiddenValue(const AHtml, AId: string): string;
var
  M: TMatch;
begin
  Result := '';
  M := TRegEx.Match(AHtml, '<input[^>]*id="' + AId + '"[^>]*value="([^"]*)"', [roIgnoreCase]);
  if M.Success then Result := Trim(M.Groups[1].Value);
end;

function TSiteIkanbot.CalcToken(const AId, AEToken: string): string;
var
  Last4, ET, Part: string;
  I, Digit, Off: Integer;
begin
  Result := '';
  if Length(AId) >= 4 then
    Last4 := Copy(AId, Length(AId) - 3, 4)
  else
    Last4 := AId;
  ET := AEToken;
  for I := 1 to Length(Last4) do
  begin
    Digit := StrToIntDef(Last4[I], 0);
    Off := (Digit mod 3) + 1;
    // JS substring(off, off+8) 为 0-based -> Delphi Copy 1-based: off+1
    Part := Copy(ET, Off + 1, 8);
    Result := Result + Part;
    // JS et = et.substring(off+8) -> 删除前 off+8 个字符
    if Off + 8 < Length(ET) then
      ET := Copy(ET, Off + 8 + 1, MaxInt)
    else
      ET := '';
  end;
end;

function TSiteIkanbot.Search(const AKeyword: string; AVideos: TStrings; out ASlugs: TSlugArray): Boolean;
var
  Html: string;
  Re: TRegEx;
  Ms: TMatchCollection;
  Title, Slug: string;
  Seen: TStringList;
  I: Integer;
begin
  SetLength(ASlugs, 0);
  AVideos.Clear;
  Html := Ctx.HttpGetText(FSiteRoot + '/search?q=' + TNetEncoding.URL.Encode(AKeyword), FSiteRoot + '/');
  Ctx.Log('Search html len=' + IntToStr(Length(Html)));

  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    Re := TRegEx.Create('<a href="/play/(\d+)" class="title-text">([\s\S]*?)</a>', [roIgnoreCase, roSingleLine]);
    Ms := Re.Matches(Html);
    for I := 0 to Ms.Count - 1 do
    begin
      Slug := Ms[I].Groups[1].Value;
      if (Slug = '') or (Seen.IndexOf(Slug) >= 0) then Continue;
      Seen.Add(Slug);

      Title := TNetEncoding.HTML.Decode(StripTags(Ms[I].Groups[2].Value));
      Title := Trim(StringReplace(Title, #13, ' ', [rfReplaceAll]));
      Title := Trim(StringReplace(Title, #10, ' ', [rfReplaceAll]));
      while Pos('  ', Title) > 0 do
        Title := StringReplace(Title, '  ', ' ', [rfReplaceAll]);
      if Length(Title) > 70 then
        Title := Copy(Title, 1, 70) + '...';
      if Title = '' then
        Title := Slug;

      SetLength(ASlugs, Length(ASlugs) + 1);
      ASlugs[High(ASlugs)] := Slug;
      AVideos.Add(Title);
    end;
    Ctx.Log('Search found ' + IntToStr(Length(ASlugs)) + ' videos');
    Result := True;
  finally
    Seen.Free;
  end;
end;

procedure TSiteIkanbot.ParseResData(const AResJson, ALineName, ADataId: string; var AEpisodes: TEpisodeArray; var ASeen: TStringList);
var
  Arr: TJSONArray;
  Obj: TJSONObject;
  V: TJSONValue;
  UrlField, Seg, NamePart, M3u8: string;
  HttpPos, DollarPos, I, J, N, StartIdx, L, Half, NumFirst, NumLast: Integer;
  Tmp: TEpisode;
  Parts: TStringList;
begin
  Arr := TJSONObject.ParseJSONValue(AResJson) as TJSONArray;
  if Arr = nil then Exit;
  try
    for I := 0 to Arr.Count - 1 do
    begin
      if not (Arr.Items[I] is TJSONObject) then Continue;
      Obj := TJSONObject(Arr.Items[I]);
      V := Obj.GetValue('url');
      if V = nil then Continue;
      UrlField := V.Value;
      if UrlField = '' then Continue;

      StartIdx := Length(AEpisodes);
      Parts := TStringList.Create;
      try
        Parts.Delimiter := '#';
        Parts.StrictDelimiter := True;
        Parts.DelimitedText := UrlField;
        for J := 0 to Parts.Count - 1 do
        begin
          Seg := Trim(Parts[J]);
          if Seg = '' then Continue;
          // 找首个 http，之前为集名，之后为 URL（兼容 $flag 后缀）
          HttpPos := Pos('http', Seg);
          if HttpPos <= 0 then Continue;
          NamePart := Trim(Copy(Seg, 1, HttpPos - 1));
          M3u8 := Copy(Seg, HttpPos, MaxInt);
          // 截掉可能的 $flag 后缀（形如 url$yhm3u8）
          DollarPos := Pos('$', M3u8);
          if DollarPos > 0 then M3u8 := Copy(M3u8, 1, DollarPos - 1);
          if (M3u8 = '') or (Pos('.m3u8', M3u8) = 0) then Continue;
          // 去掉集名里残留的 $ 及后缀
          DollarPos := Pos('$', NamePart);
          if DollarPos > 0 then
            NamePart := Trim(Copy(NamePart, 1, DollarPos - 1));
          if NamePart = '' then
            NamePart := IntToStr(J + 1);

          if ASeen.IndexOf(M3u8) >= 0 then Continue;
          ASeen.Add(M3u8);

          SetLength(AEpisodes, Length(AEpisodes) + 1);
          N := High(AEpisodes);
          AEpisodes[N].Num := NamePart;
          AEpisodes[N].LineNo := ALineName;
          AEpisodes[N].DataId := ADataId;
          AEpisodes[N].PageUrl := M3u8;
        end;
      finally
        Parts.Free;
      end;

      // 线路内翻转成倒序(最新集在前)；仅当页面正序时翻
      if Length(AEpisodes) - StartIdx > 1 then
      begin
        NumFirst := StrToIntDef(TRegEx.Replace(AEpisodes[StartIdx].Num, '[^0-9]', ''), 0);
        NumLast  := StrToIntDef(TRegEx.Replace(AEpisodes[High(AEpisodes)].Num, '[^0-9]', ''), 0);
        if NumFirst < NumLast then
        begin
          Half := (Length(AEpisodes) - StartIdx) div 2;
          for L := 0 to Half - 1 do
          begin
            Tmp := AEpisodes[StartIdx + L];
            AEpisodes[StartIdx + L] := AEpisodes[High(AEpisodes) - L];
            AEpisodes[High(AEpisodes) - L] := Tmp;
          end;
        end;
      end;
    end;
  finally
    Arr.Free;
  end;
end;

function TSiteIkanbot.LoadDetail(const ASlug: string; out AEpisodes: TEpisodeArray): Boolean;
var
  PageHtml, ApiUrl, JsonText, ET, MType, Token, ResStr: string;
  V: TJSONValue;
  Root: TJSONObject;
  DataObj, ItemObj: TJSONObject;
  ListArr: TJSONArray;
  LineName, DataId: string;
  Seen: TStringList;
  I: Integer;
begin
  SetLength(AEpisodes, 0);

  // 步骤1: 抓播放页，提取 current_id / e_token / mtype
  PageHtml := Ctx.HttpGetText(FSiteRoot + '/play/' + ASlug, FSiteRoot + '/');
  Ctx.Log('LoadDetail ' + ASlug + ' page len=' + IntToStr(Length(PageHtml)));

  ET := ExtractHiddenValue(PageHtml, 'e_token');
  MType := ExtractHiddenValue(PageHtml, 'mtype');
  if ET = '' then raise Exception.Create('播放页未找到 e_token');

  // 步骤2: 生成 token 并调用 API
  Token := CalcToken(ASlug, ET);
  ApiUrl := FSiteRoot + '/api/getResN?videoId=' + ASlug + '&mtype=' + MType + '&token=' + Token;
  Ctx.Log('LoadDetail api=' + ApiUrl);
  JsonText := Ctx.HttpGetText(ApiUrl, FSiteRoot + '/play/' + ASlug);
  Ctx.Log('LoadDetail api response len=' + IntToStr(Length(JsonText)));

  Root := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
  if Root = nil then raise Exception.Create('API 返回不是有效 JSON');
  try
    V := Root.GetValue('state');
    if (V <> nil) and (V.Value <> '1') then  raise Exception.Create('API 返回失败: ' + Copy(JsonText, 1, 200));
    V := Root.GetValue('data');
    if not (V is TJSONObject) then raise Exception.Create('API 缺少 data');
    DataObj := TJSONObject(V);
    V := DataObj.GetValue('list');
    if not (V is TJSONArray) then raise Exception.Create('API 缺少 data.list');
    ListArr := TJSONArray(V);

    Seen := TStringList.Create;
    try
      Seen.Sorted := True;
      Seen.Duplicates := dupIgnore;
      for I := 0 to ListArr.Count - 1 do
      begin
        if not (ListArr.Items[I] is TJSONObject) then Continue;
        ItemObj := TJSONObject(ListArr.Items[I]);
        V := ItemObj.GetValue('resData');
        if V = nil then Continue;
        ResStr := V.Value;
        if ResStr = '' then Continue;

        // 线路名用 flag（resData 数组首元素的 flag），DataId 用 siteId
        LineName := '线路' + IntToStr(I + 1);
        DataId := '';
        V := ItemObj.GetValue('siteId');
        if V <> nil then DataId := V.Value;

        ParseResData(ResStr, LineName, DataId, AEpisodes, Seen);
      end;
    finally
      Seen.Free;
    end;

    Ctx.Log('LoadDetail found ' + IntToStr(Length(AEpisodes)) + ' episodes');
    Result := Length(AEpisodes) > 0;
  finally
    Root.Free;
  end;
end;

function TSiteIkanbot.DownloadPlaylistAndBuildCmd(const AM3U8Url: string; ADownload: Boolean; const AToken: string): string;
var
  M3U8Text, Head, SourceFile: string;
begin
  Ctx.Log('BuildPlayCommand url=' + AM3U8Url);
  if ADownload then
    SourceFile := TPath.Combine(FWorkDir, 'download_source_' + AToken + '.m3u8')
  else
    SourceFile := FSourcePlaylistFile;

  try
    M3U8Text := Ctx.HttpGetText(AM3U8Url, FSiteRoot + '/');
    if M3U8Text <> '' then
    begin
      Head := Copy(StringReplace(M3U8Text, #10, '|', [rfReplaceAll]), 1, 400);
      Ctx.Log('M3U8 len=' + IntToStr(Length(M3U8Text)) + ' head=' + Head);
      ForceDirectories(ExtractFilePath(SourceFile));
      TFile.WriteAllText(SourceFile, M3U8Text, TEncoding.UTF8);
    end;
  except
    on E: Exception do Ctx.Log('M3U8 pre-download FAILED (proxy will retry): ' + E.Message);
  end;

  if ADownload then
  begin
    Result := Ctx.StartDownloadProxy(FProxyHelperFile, SourceFile, AM3U8Url, AToken);
    if Result = '' then raise Exception.Create('启动下载代理失败，请检查 Node 运行环境');
    Ctx.Log('Using DOWNLOAD PROXY url=' + Result);
  end
  else
  begin
    if Ctx.StartLocalProxy(FProxyHelperFile, SourceFile, AM3U8Url) then
    begin
      Result := '"http://127.0.0.1:' + IntToStr(Ctx.ProxyPort) + '/index.m3u8" --no-video-title-show';
      Ctx.Log('Using LOCAL PROXY command=' + Result);
    end
    else
      raise Exception.Create('启动本地分片代理失败，请检查 Node 运行环境');
  end;
end;

function TSiteIkanbot.BuildPlayCommand(const AEpisode: TEpisode): string;
begin
  // 本站 PageUrl 即 m3u8 地址，无需再解析播放页
  LastResolvedUrl := MakeAbsolute(AEpisode.PageUrl);
  Ctx.Log('Resolved m3u8=' + LastResolvedUrl);
  Result := DownloadPlaylistAndBuildCmd(LastResolvedUrl, False, '');
end;

function TSiteIkanbot.BuildDownloadCommand(const AEpisode: TEpisode; const AToken: string): string;
begin
  Result := DownloadPlaylistAndBuildCmd(MakeAbsolute(AEpisode.PageUrl), True, AToken);
end;

procedure TSiteIkanbot.Cleanup;
begin
  Ctx.StopProxy;
end;

end.
