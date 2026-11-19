unit SiteFiilacurent;

// ============================================================
// 貔貅洞天 (www.fiilacurent.net) 苹果CMS(maccms y_md_3 模板)站点适配器
//   搜索: GET /search.html?wd={URL编码词}
//         结果区 <ul class="search-list"> 内
//           <h5 class="subject ..."><a href="/video/{id}.html">
//             <b><b style="color:red;">标题高亮</b>年份</b><span class="douban_score">评分</span></a>
//          （标题需剥离标签并去掉 douban_score 评分 span；侧边栏 TOP100 不在 search-list 内，天然排除）
//   详情: /video/{id}.html
//         线路 tab: <a class="tab-nav" title="线路3">线路3</a>
//         选集块:   <ul class="episodes-list ..."> ... <li><a href="/play/{id}/{sid}/{nid}.html">集名</a>
//         线路名与选集块按顺序一一对应；sid 从链接提取（显示名与 sid 可能不一致）
//   播放: /play/{id}/{sid}/{nid}.html
//         player_aaaa JSON 的 url 字段为明文 m3u8（encrypt=0），无需解码
//   m3u8: 单级、无加密、相对路径分片(0000000.ts)、**URL 含中文路径**(/第01集/)
//         —— ResolveM3U8 对小 ASCII 之外的字符做 percent 编码，保证传给 Node/curl 的是纯 ASCII
//   站点脚本: sites\fiilacurent\ProxyHelper.mjs（相对分片 absUrl 拼接、TLS 偶发失败直连→代理回退）
//   UA: 主站 Cloudflare 拦完整 Chrome UA(403)，用短 UA 'Mozilla/5.0' 直连；CDN 不拦 UA
// ============================================================

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.NetEncoding,
  System.JSON, System.Net.HttpClient, System.Net.URLClient,
  System.RegularExpressions, Winapi.Windows, SiteIntf;

type
  TSiteFiilacurent = class(TSiteBase)
  private
    FSiteRoot: string;
    FWorkDir: string;
    FSourcePlaylistFile: string;
    FProxyHelperFile: string;
    FDirectHttp: THTTPClient;  // 直连客户端（不设代理）：本站 Cloudflare 对完整 UA/代理出口返回 403
    function HttpGetSmart(const AUrl, AReferer: string): string; // 直连优先，失败回退系统代理
    function MakeAbsolute(const AUrl: string): string;
    function EncodeNonAsciiUrl(const AUrl: string): string;      // 非 ASCII 字符转 UTF-8 %XX
    function StripTags(const AText: string): string;
    function ResolveM3U8(const APageUrl: string): string;
    function DownloadPlaylistAndBuildCmd(const AM3U8Url: string; ADownload: Boolean; const AToken: string): string;
  public
    constructor Create(ACtx: TSiteContext); override;
    destructor Destroy; override;
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
  SITE_ROOT = 'https://www.fiilacurent.net';

constructor TSiteFiilacurent.Create(ACtx: TSiteContext);
var
  SiteExe: string;
begin
  inherited Create(ACtx);
  BindSiteId;  // 日志写入 log\日期\fiilacurent\
  FSiteRoot := SITE_ROOT;
  FWorkDir := IncludeTrailingPathDelimiter(ACtx.TempRoot + Id);
  ForceDirectories(FWorkDir);
  FSourcePlaylistFile := TPath.Combine(FWorkDir, 'source.m3u8');

  SiteExe := SiteExeDir(ACtx.ExeDir);
  FProxyHelperFile := TPath.Combine(SiteExe, 'ProxyHelper.mjs');

  // 本站 Cloudflare 拦截完整 Chrome UA（返回 403），短 UA 可正常访问。
  // 自建直连客户端：不设 ProxySettings，用短 UA；失败时再回退系统代理。
  FDirectHttp := THTTPClient.Create;
  FDirectHttp.UserAgent := 'Mozilla/5.0';

  Ctx.Log('TSiteFiilacurent created. proxy=' + FProxyHelperFile + ' exist=' + BoolToStr(TFile.Exists(FProxyHelperFile), True));
end;

destructor TSiteFiilacurent.Destroy;
begin
  FDirectHttp.Free;
  inherited;
end;

// 直连优先；若直连失败(403/异常，如本机无直连能力)则回退到系统代理。
function TSiteFiilacurent.HttpGetSmart(const AUrl, AReferer: string): string;
var
  Resp: IHTTPResponse;
  Headers: TNetHeaders;
begin
  Result := '';
  try
    if AReferer <> '' then
    begin
      SetLength(Headers, 1);
      Headers[0].Name := 'Referer';
      Headers[0].Value := AReferer;
      Resp := FDirectHttp.Get(AUrl, nil, Headers);
    end
    else
      Resp := FDirectHttp.Get(AUrl);
    if Resp.StatusCode = 200 then
    begin
      Result := Resp.ContentAsString(TEncoding.UTF8);
      Exit;
    end;
    Ctx.Log('HttpGetSmart direct HTTP=' + IntToStr(Resp.StatusCode) + ', fallback system proxy: ' + AUrl);
  except
    on E: Exception do Ctx.Log('HttpGetSmart direct EX: ' + E.Message + ', fallback system proxy');
  end;
  Result := Ctx.HttpGetText(AUrl, AReferer);
end;

class function TSiteFiilacurent.Id: string;
begin
  Result := 'fiilacurent';
end;

class function TSiteFiilacurent.DisplayName: string;
begin
  Result := '貔貅洞天';
end;

class function TSiteFiilacurent.DefaultKeyword: string;
begin
  Result := '凡人修仙传';
end;

function TSiteFiilacurent.MakeAbsolute(const AUrl: string): string;
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

// 保留所有 ASCII 可见字符(33..126)，其余字符(含中文)按 UTF-8 字节转 %XX。
// 这样 m3u8 中文路径(/第01集/)变为纯 ASCII，避免 Windows 下把中文参数传给 Node/curl 时的编码错乱。
function TSiteFiilacurent.EncodeNonAsciiUrl(const AUrl: string): string;
var
  I, J: Integer;
  C: Char;
  Bytes: TBytes;
begin
  Result := '';
  for I := 1 to Length(AUrl) do
  begin
    C := AUrl[I];
    if (Ord(C) >= 33) and (Ord(C) <= 126) then
      Result := Result + C
    else
    begin
      Bytes := TEncoding.UTF8.GetBytes(C);
      for J := 0 to High(Bytes) do Result := Result + '%' + IntToHex(Bytes[J], 2);
    end;
  end;
end;

function TSiteFiilacurent.StripTags(const AText: string): string;
var
  TagRe: TRegEx;
begin
  TagRe := TRegEx.Create('<[^>]+>', []);
  Result := Trim(TagRe.Replace(AText, ' '));
end;

function TSiteFiilacurent.Search(const AKeyword: string; AVideos: TStrings; out ASlugs: TSlugArray): Boolean;
var
  Html: string;
  Re, ScoreRe: TRegEx;
  Ms: TMatchCollection;
  Title, Slug, RawTitle: string;
  Seen: TStringList;
  I: Integer;
begin
  SetLength(ASlugs, 0);
  AVideos.Clear;
  Html := HttpGetSmart(FSiteRoot + '/search.html?wd=' + TNetEncoding.URL.Encode(AKeyword), FSiteRoot + '/');
  Ctx.Log('Search html len=' + IntToStr(Length(Html)));

  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    Re := TRegEx.Create('<h5\s+class="subject[^"]*"[^>]*>\s*<a[^>]*href="/video/(\d+)\.html"[^>]*>([\s\S]*?)</a>', [roIgnoreCase, roSingleLine]);
    ScoreRe := TRegEx.Create('<span[^>]*class="douban_score"[^>]*>[\s\S]*?</span>', [roIgnoreCase, roSingleLine]);
    Ms := Re.Matches(Html);
    for I := 0 to Ms.Count - 1 do
    begin
      Slug := Ms[I].Groups[1].Value;
      if (Slug = '') or (Seen.IndexOf(Slug) >= 0) then Continue;
      Seen.Add(Slug);

      RawTitle := ScoreRe.Replace(Ms[I].Groups[2].Value, '');
      Title := TNetEncoding.HTML.Decode(StripTags(RawTitle));
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

function TSiteFiilacurent.LoadDetail(const ASlug: string;
  out AEpisodes: TEpisodeArray): Boolean;
var
  Html, Vid, Sid, Nid: string;
  LineRe, BlockRe, LinkRe: TRegEx;
  LineMs, BlockMs, LinkMs: TMatchCollection;
  LineNames, Seen: TStringList;
  I, J, N, StartIdx, L, Half, Num, LineIdx: Integer;
  Tmp: TEpisode;
begin
  Result := False;
  SetLength(AEpisodes, 0);
  Html := HttpGetSmart(FSiteRoot + '/video/' + ASlug + '.html', FSiteRoot + '/');
  Ctx.Log('LoadDetail ' + ASlug + ' html len=' + IntToStr(Length(Html)));

  LineNames := TStringList.Create;
  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;

    // 线路名按出现顺序收集：第 I 个 tab-nav 对应第 I 个 episodes-list 块
    // class 可能带附加类(如 "tab-nav on")，用 [^"]* 宽松匹配；title 也可能在 class 之前
    LineRe := TRegEx.Create('<a[^>]*class="[^"]*tab-nav[^"]*"[^>]*title="([^"]+)"', [roIgnoreCase, roSingleLine]);
    LineMs := LineRe.Matches(Html);
    for I := 0 to LineMs.Count - 1 do LineNames.Add(Trim(LineMs[I].Groups[1].Value));

    // 每个 <ul class="episodes-list ..."> 选集块
    BlockRe := TRegEx.Create('<ul\s+class="episodes-list[^"]*"[^>]*>([\s\S]*?)</ul>', [roIgnoreCase, roSingleLine]);
    BlockMs := BlockRe.Matches(Html);
    LinkRe := TRegEx.Create('<a[^>]*href="/play/(\d+)/(\d+)/(\d+)\.html"[^>]*>([^<]+)</a>', [roIgnoreCase, roSingleLine]);
    for I := 0 to BlockMs.Count - 1 do
    begin
      StartIdx := Length(AEpisodes);
      if I < LineNames.Count then
        LineIdx := I
      else
        LineIdx := -1;
      LinkMs := LinkRe.Matches(BlockMs[I].Groups[1].Value);
      for J := 0 to LinkMs.Count - 1 do
      begin
        Vid := LinkMs[J].Groups[1].Value;
        Sid := LinkMs[J].Groups[2].Value;
        Nid := LinkMs[J].Groups[3].Value;
        if Seen.IndexOf(Sid + '|' + Nid) >= 0 then
          Continue;
        Seen.Add(Sid + '|' + Nid);

        SetLength(AEpisodes, Length(AEpisodes) + 1);
        N := High(AEpisodes);
        AEpisodes[N].Num := Nid;
        if LineIdx >= 0 then
          AEpisodes[N].LineNo := LineNames[LineIdx]
        else
          AEpisodes[N].LineNo := '线路' + Sid;
        AEpisodes[N].DataId := Sid;
        AEpisodes[N].PageUrl := FSiteRoot + '/play/' + Vid + '/' +
          Sid + '/' + Nid + '.html';
      end;

      // 页面为正序(第01集...第N集)，翻转成倒序(最新集在前)；已是倒序则不翻
      if Length(AEpisodes) - StartIdx > 1 then
      begin
        Num := StrToIntDef(AEpisodes[StartIdx].Num, 0);
        if Num < StrToIntDef(AEpisodes[High(AEpisodes)].Num, 0) then
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
    Ctx.Log('LoadDetail found ' + IntToStr(Length(AEpisodes)) + ' episodes');
    Result := Length(AEpisodes) > 0;
  finally
    Seen.Free;
    LineNames.Free;
  end;
end;

function TSiteFiilacurent.ResolveM3U8(const APageUrl: string): string;
var
  Html, JsonText, Url: string;
  M: TMatch;
  Root: TJSONValue;
  Obj: TJSONObject;
  V: TJSONValue;
begin
  Result := '';
  Html := HttpGetSmart(APageUrl, FSiteRoot + '/');
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
    if (V <> nil) and (V.Value <> '0') then Ctx.Log('注意: encrypt=' + V.Value + '，本站通常应为明文配置');

    V := Obj.GetValue('url');
    if V = nil then raise Exception.Create('播放配置缺少 url 字段');
    Url := Trim(V.Value);
    if Url = '' then raise Exception.Create('播放地址为空，可能需要登录');

    // 中文路径(/第01集/)做 percent 编码，保证下游 Node/curl 拿到纯 ASCII URL
    Result := EncodeNonAsciiUrl(MakeAbsolute(Url));
  finally
    Root.Free;
  end;
end;

function TSiteFiilacurent.DownloadPlaylistAndBuildCmd(const AM3U8Url: string; ADownload: Boolean; const AToken: string): string;
var
  M3U8Text, Head, SourceFile: string;
begin
  Ctx.Log('BuildPlayCommand url=' + AM3U8Url);
  if ADownload then
    SourceFile := TPath.Combine(FWorkDir, 'download_source_' + AToken + '.m3u8')
  else
    SourceFile := FSourcePlaylistFile;

  // 预下载主列表（失败不影响启动，脚本会自行 curl 下载）
  try
    M3U8Text := HttpGetSmart(AM3U8Url, FSiteRoot + '/');
    if M3U8Text <> '' then
    begin
      Head := Copy(StringReplace(M3U8Text, #10, '|', [rfReplaceAll]), 1, 400);
      Ctx.Log('M3U8 len=' + IntToStr(Length(M3U8Text)) + ' head=' + Head);
      ForceDirectories(ExtractFilePath(SourceFile));
      TFile.WriteAllText(SourceFile, M3U8Text, TEncoding.UTF8);
    end;
  except
    on E: Exception do
      Ctx.Log('M3U8 pre-download FAILED (proxy will retry): ' + E.Message);
  end;

  if ADownload then
  begin
    Result := Ctx.StartDownloadProxy(FProxyHelperFile, SourceFile, AM3U8Url, AToken);
    if Result = '' then
      raise Exception.Create('启动下载代理失败，请检查 Node 运行环境');
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

function TSiteFiilacurent.BuildPlayCommand(const AEpisode: TEpisode): string;
begin
  LastResolvedUrl := ResolveM3U8(AEpisode.PageUrl);
  Ctx.Log('Resolved m3u8=' + LastResolvedUrl);
  Result := DownloadPlaylistAndBuildCmd(LastResolvedUrl, False, '');
end;

function TSiteFiilacurent.BuildDownloadCommand(const AEpisode: TEpisode; const AToken: string): string;
begin
  Result := DownloadPlaylistAndBuildCmd(ResolveM3U8(AEpisode.PageUrl), True, AToken);
end;

procedure TSiteFiilacurent.Cleanup;
begin
  Ctx.StopProxy;
end;

end.
