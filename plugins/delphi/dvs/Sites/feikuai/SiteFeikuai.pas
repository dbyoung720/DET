unit SiteFeikuai;

// ============================================================
// 飞快TV (feikuai.in) 苹果CMS(mxprocms)站点适配器
//   搜索: /vodsearch/{关键词}-------------.html
//   详情: /voddetail/{id}.html            按 module-play-list 分线路剧集
//   播放: /vodplay/{id}-{线路}-{集数}.html
//         player_aaaa JSON 的 url 字段 = Base64(URLEncode(m3u8))，encrypt=2
//         解码链路: Base64 解码 -> URL 解码 -> 真实 m3u8 地址
//   m3u8: 两级结构 master(#EXT-X-STREAM-INF) -> media -> .ts
//   站点脚本: sites\feikuai\ProxyHelper.mjs（递归展开两级 m3u8）
// ============================================================

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.NetEncoding,
  System.JSON, System.RegularExpressions, Winapi.Windows, SiteIntf;

type
  TSiteFeikuai = class(TSiteBase)
  private
    FSiteRoot: string;
    FWorkDir: string;
    FSourcePlaylistFile: string;
    FProxyHelperFile: string;
    function MakeAbsolute(const AUrl: string): string;
    function StripTags(const AText: string): string;
    function DecodePlayerUrl(const AEncoded: string): string;
    function ResolveM3U8(const APageUrl: string): string;
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
  SITE_ROOT = 'https://feikuai.in';

constructor TSiteFeikuai.Create(ACtx: TSiteContext);
var
  SiteExe: string;
begin
  inherited Create(ACtx);
  // 本站 ID，日志写入 log\日期\feikuai\
  BindSiteId;
  FSiteRoot := SITE_ROOT;
  FWorkDir := IncludeTrailingPathDelimiter(ACtx.TempRoot + Id);
  ForceDirectories(FWorkDir);
  FSourcePlaylistFile := TPath.Combine(FWorkDir, 'source.m3u8');

  SiteExe := SiteExeDir(ACtx.ExeDir);
  FProxyHelperFile := TPath.Combine(SiteExe, 'ProxyHelper.mjs');

  Ctx.Log('TSiteFeikuai created. proxy=' + FProxyHelperFile + ' exist=' + BoolToStr(TFile.Exists(FProxyHelperFile), True));
end;

class function TSiteFeikuai.Id: string;
begin
  Result := 'feikuai';
end;

class function TSiteFeikuai.DisplayName: string;
begin
  Result := '飞快TV';
end;

class function TSiteFeikuai.DefaultKeyword: string;
begin
  Result := '凡人修仙传';
end;

function TSiteFeikuai.MakeAbsolute(const AUrl: string): string;
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

function TSiteFeikuai.StripTags(const AText: string): string;
var
  TagRe: TRegEx;
begin
  TagRe := TRegEx.Create('<[^>]+>', []);
  Result := Trim(TagRe.Replace(AText, ' '));
end;

// player_aaaa.url 解码: Base64 -> URL 解码 -> m3u8
function TSiteFeikuai.DecodePlayerUrl(const AEncoded: string): string;
var
  B64: TBase64Encoding;
  UrlEncoded, Padded: string;
  R: Integer;
begin
  Result := '';
  Padded := Trim(AEncoded);
  if Padded = '' then
    Exit;
  // Base64 补齐 padding（本站 url 长度一般是 4 的倍数，这里做容错）
  R := Length(Padded) mod 4;
  if R = 2 then
    Padded := Padded + '=='
  else if R = 3 then
    Padded := Padded + '=';
  B64 := TBase64Encoding.Create(0);
  try
    UrlEncoded := B64.Decode(Padded);
  finally
    B64.Free;
  end;
  // 解码 %XX -> 明文 https://...m3u8
  Result := TNetEncoding.URL.Decode(UrlEncoded);
end;

function TSiteFeikuai.Search(const AKeyword: string; AVideos: TStrings;
  out ASlugs: TSlugArray): Boolean;
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
  Html := Ctx.HttpGetText(FSiteRoot + '/vodsearch/' + TNetEncoding.URL.Encode(AKeyword) + '-------------.html', FSiteRoot + '/');
  Ctx.Log('Search html len=' + IntToStr(Length(Html)));

  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    Re := TRegEx.Create('<div class="module-card-item-title">\s*<a\s+href="/voddetail/(\d+)\.html"[^>]*>([\s\S]*?)</a>', [roIgnoreCase, roSingleLine]);
    Ms := Re.Matches(Html);
    for I := 0 to Ms.Count - 1 do
    begin
      Slug := Ms[I].Groups[1].Value;
      if (Slug = '') or (Seen.IndexOf(Slug) >= 0) then Continue;
      Seen.Add(Slug);

      Title := TNetEncoding.HTML.Decode(StripTags(Ms[I].Groups[2].Value));
      Title := Trim(StringReplace(Title, #13, ' ', [rfReplaceAll]));
      Title := Trim(StringReplace(Title, #10, ' ', [rfReplaceAll]));
      while Pos('  ', Title) > 0 do Title := StringReplace(Title, '  ', ' ', [rfReplaceAll]);
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

function TSiteFeikuai.LoadDetail(const ASlug: string;
  out AEpisodes: TEpisodeArray): Boolean;
var
  Html, LineName, Key, Vid, Sid, Nid: string;
  Re, LinkRe, TabRe: TRegEx;
  LinkMs, TabMs: TMatchCollection;
  Parts: TArray<string>;
  TabList, Seen: TStringList;
  P, I, J, N, LineIdx, StartIdx, L, Half: Integer;
  Tmp: TEpisode;
begin
  Result := False;
  SetLength(AEpisodes, 0);
  Html := Ctx.HttpGetText(FSiteRoot + '/voddetail/' + ASlug + '.html', FSiteRoot + '/');
  Ctx.Log('LoadDetail ' + ASlug + ' html len=' + IntToStr(Length(Html)));

  TabList := TStringList.Create;
  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;

    // 线路名，顺序与下面的剧集列表一一对应
    TabRe := TRegEx.Create('data-dropdown-value="([^"]+)"', [roIgnoreCase, roSingleLine]);
    TabMs := TabRe.Matches(Html);
    for I := 0 to TabMs.Count - 1 do TabList.Add(TabMs[I].Groups[1].Value);

    // 每个 module-play-list 区块对应一条线路
    Re := TRegEx.Create('<div\s+class="module-play-list">', [roIgnoreCase]);
    Parts := Re.Split(Html);
    LineIdx := 0;
    for P := 1 to High(Parts) do
    begin
      if LineIdx < TabList.Count then
        LineName := TabList[LineIdx]
      else
        LineName := '线路' + IntToStr(LineIdx + 1);
      Inc(LineIdx);
      StartIdx := Length(AEpisodes);

      LinkRe := TRegEx.Create('<a[^>]*href="/vodplay/(\d+)-(\d+)-(\d+)\.html"[^>]*>\s*<span>([^<]+)</span>', [roIgnoreCase, roSingleLine]);
      LinkMs := LinkRe.Matches(Parts[P]);
      for J := 0 to LinkMs.Count - 1 do
      begin
        Vid := LinkMs[J].Groups[1].Value;
        Sid := LinkMs[J].Groups[2].Value;
        Nid := LinkMs[J].Groups[3].Value;
        Key := Sid + '|' + Nid;
        if Seen.IndexOf(Key) >= 0 then
          Continue;
        Seen.Add(Key);

        SetLength(AEpisodes, Length(AEpisodes) + 1);
        N := High(AEpisodes);
        AEpisodes[N].Num := Nid;
        AEpisodes[N].LineNo := LineName;
        AEpisodes[N].DataId := Sid;
        AEpisodes[N].PageUrl := FSiteRoot + '/vodplay/' + Vid + '-' + Sid + '-' + Nid + '.html';
      end;

      // 同一线路内按集数倒序变成正序
      if Length(AEpisodes) - StartIdx > 1 then
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
    Ctx.Log('LoadDetail found ' + IntToStr(Length(AEpisodes)) + ' episodes');
    Result := Length(AEpisodes) > 0;
  finally
    Seen.Free;
    TabList.Free;
  end;
end;

function TSiteFeikuai.ResolveM3U8(const APageUrl: string): string;
var
  Html, JsonText, EncUrl: string;
  M: TMatch;
  Root: TJSONValue;
  Obj: TJSONObject;
  V: TJSONValue;
begin
  Result := '';
  Html := Ctx.HttpGetText(APageUrl, FSiteRoot + '/');
  Ctx.Log('ResolveM3U8 page=' + APageUrl + ' len=' + IntToStr(Length(Html)));

  M := TRegEx.Match(Html, 'var\s+player_aaaa\s*=\s*(\{[\s\S]*?\})\s*</script>', [roIgnoreCase, roSingleLine]);
  if not M.Success then raise Exception.Create('播放页未找到 player_aaaa 数据');

  JsonText := M.Groups[1].Value;
  Root := TJSONObject.ParseJSONValue(JsonText);
  if Root = nil then raise Exception.Create('播放页配置不是有效 JSON');
  try
    if not (Root is TJSONObject) then raise Exception.Create('播放页配置格式错误');
    Obj := TJSONObject(Root);

    V := Obj.GetValue('encrypt');
    if V <> nil then Ctx.Log('播放页 encrypt=' + V.Value);

    V := Obj.GetValue('url');
    if V = nil then raise Exception.Create('播放配置缺少 url 字段');
    EncUrl := Trim(V.Value);
    if EncUrl = '' then raise Exception.Create('播放地址为空，可能需要登录');

    // 本站 url 为 Base64(URLEncode(m3u8))；若站点改回明文则直接使用
    Result := DecodePlayerUrl(EncUrl);
    if (Result = '') or (not Result.StartsWith('http')) then Result := MakeAbsolute(Result);
    Ctx.Log('Decoded m3u8=' + Result);
  finally
    Root.Free;
  end;
end;

function TSiteFeikuai.DownloadPlaylistAndBuildCmd(const AM3U8Url: string; ADownload: Boolean; const AToken: string): string;
var
  M3U8Text, Head, SourceFile: string;
begin
  Ctx.Log('BuildPlayCommand url=' + AM3U8Url);
  // 默认路径；预下载失败时让脚本自行 curl 重试
  if ADownload then
    SourceFile := TPath.Combine(FWorkDir, 'download_source_' + AToken + '.m3u8')
  else
    SourceFile := FSourcePlaylistFile;

  // 预下载主列表（失败不影响启动，脚本会自行 curl 下载）
  try
    M3U8Text := Ctx.HttpGetText(AM3U8Url, FSiteRoot + '/');
    if M3U8Text <> '' then
    begin
      Head := Copy(StringReplace(M3U8Text, #10, '|', [rfReplaceAll]), 1, 400);
      Ctx.Log('M3U8 len=' + IntToStr(Length(M3U8Text)) + ' head=' + Head);
      if ADownload then
        SourceFile := TPath.Combine(FWorkDir, 'download_source_' + AToken + '.m3u8')
      else
        SourceFile := FSourcePlaylistFile;
      ForceDirectories(ExtractFilePath(SourceFile));
      TFile.WriteAllText(SourceFile, M3U8Text, TEncoding.UTF8);
    end;
  except
    on E: Exception do Ctx.Log('M3U8 pre-download FAILED (proxy will retry): ' + E.Message);
  end;

  if ADownload then
  begin
    // 独立下载代理，不影响 VLC 正在使用的播放代理
    Result := Ctx.StartDownloadProxy(FProxyHelperFile, SourceFile, AM3U8Url, AToken);
    if Result = '' then raise Exception.Create('启动下载代理失败，请检查 Node 运行环境');
    Ctx.Log('Using DOWNLOAD PROXY url=' + Result);
  end
  else
  begin
    // 只让 VLC 播本地代理地址，避免直连远程 HTTPS 触发证书弹窗
    if Ctx.StartLocalProxy(FProxyHelperFile, SourceFile, AM3U8Url) then
    begin
      Result := '"http://127.0.0.1:' + IntToStr(Ctx.ProxyPort) + '/index.m3u8" --no-video-title-show';
      Ctx.Log('Using LOCAL PROXY command=' + Result);
    end
    else
      raise Exception.Create('启动本地分片代理失败，请检查 Node 运行环境');
  end;
end;

function TSiteFeikuai.BuildPlayCommand(const AEpisode: TEpisode): string;
begin
  LastResolvedUrl := ResolveM3U8(AEpisode.PageUrl);
  Ctx.Log('Resolved m3u8=' + LastResolvedUrl);
  Result := DownloadPlaylistAndBuildCmd(LastResolvedUrl, False, '');
end;

function TSiteFeikuai.BuildDownloadCommand(const AEpisode: TEpisode; const AToken: string): string;
begin
  Result := DownloadPlaylistAndBuildCmd(ResolveM3U8(AEpisode.PageUrl), True, AToken);
end;

procedure TSiteFeikuai.Cleanup;
begin
  Ctx.StopProxy;
end;

end.
