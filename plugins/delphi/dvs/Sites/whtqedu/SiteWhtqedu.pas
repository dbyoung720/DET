unit SiteWhtqedu;

// ============================================================
// 达达兔影院 (www.whtqedu.net) myui 模板站点适配器
//   搜索: /search?wd={URL编码词}
//         卡片 <div class="myui-vodlist__detail"><h4 class="title...">
//              <a href="/ddt/{id}.html">标题</a>
//   详情: /ddt/{id}.html
//         线路 tab: <a href="#playlistN" data-toggle="tab">线路名</a>
//         剧集块:   <div id="playlistN"> ... <a href="/play/{id}-{sid}-{nid}.html">集名</a>
//   播放: /play/{id}-{sid}-{nid}.html
//         ★本站特殊：页面无明文 m3u8，需三步解析：
//           1) 从 <div id="ys-player" data-play-api="..." data-play-token="...">
//           2) GET {SITE_ROOT}{api}?t={URL编码token}  -> JSON {ok,mode,url}
//           3) url 为 iframe 地址，取其 query 的 url 参数(URL解码) -> 真实 m3u8
//   m3u8: 两级 master(#EXT-X-STREAM-INF) -> media -> .ts（分片为绝对跨域 URL）
//   站点脚本: sites\whtqedu\ProxyHelper.mjs（递归展开，支持绝对 URL 分片）
// ============================================================

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.NetEncoding,
  System.JSON, System.RegularExpressions, Winapi.Windows, SiteIntf;

type
  TSiteWhtqedu = class(TSiteBase)
  private
    FSiteRoot: string;
    FWorkDir: string;
    FSourcePlaylistFile: string;
    FProxyHelperFile: string;
    function MakeAbsolute(const AUrl: string): string;
    function StripTags(const AText: string): string;
    function LineNameFor(AList: TStringList; const AIndex: string): string;
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
  SITE_ROOT = 'https://www.whtqedu.net';

constructor TSiteWhtqedu.Create(ACtx: TSiteContext);
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

  Ctx.Log('TSiteWhtqedu created. proxy=' + FProxyHelperFile + ' exist=' + BoolToStr(TFile.Exists(FProxyHelperFile), True));
end;

class function TSiteWhtqedu.Id: string;
begin
  Result := 'whtqedu';
end;

class function TSiteWhtqedu.DisplayName: string;
begin
  Result := '达达兔影院';
end;

class function TSiteWhtqedu.DefaultKeyword: string;
begin
  Result := '凡人修仙传';
end;

function TSiteWhtqedu.MakeAbsolute(const AUrl: string): string;
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

function TSiteWhtqedu.StripTags(const AText: string): string;
var
  TagRe: TRegEx;
begin
  TagRe := TRegEx.Create('<[^>]+>', []);
  Result := Trim(TagRe.Replace(AText, ' '));
end;

function TSiteWhtqedu.LineNameFor(AList: TStringList; const AIndex: string): string;
begin
  Result := Trim(AList.Values[AIndex]);
  if Result = '' then Result := '线路' + AIndex;
end;

function TSiteWhtqedu.Search(const AKeyword: string; AVideos: TStrings;
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
  Html := Ctx.HttpGetText(FSiteRoot + '/search?wd=' +
    TNetEncoding.URL.Encode(AKeyword), FSiteRoot + '/');
  Ctx.Log('Search html len=' + IntToStr(Length(Html)));

  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    Re := TRegEx.Create('<div class="myui-vodlist__detail">\s*<h4 class="title[^>]*>\s*<a href="/ddt/(\d+)\.html"[^>]*>([\s\S]*?)</a>', [roIgnoreCase, roSingleLine]);
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

function TSiteWhtqedu.LoadDetail(const ASlug: string; out AEpisodes: TEpisodeArray): Boolean;
var
  Html, LineName, Vid, Sid, Nid, Key: string;
  TabRe, BlockRe, LinkRe: TRegEx;
  TabMs, BlockMs, LinkMs: TMatchCollection;
  LineNames, Seen: TStringList;
  I, J, N, StartIdx, L, Half, Num: Integer;
  Tmp: TEpisode;
begin
  Result := False;
  SetLength(AEpisodes, 0);
  Html := Ctx.HttpGetText(FSiteRoot + '/ddt/' + ASlug + '.html', FSiteRoot + '/');
  Ctx.Log('LoadDetail ' + ASlug + ' html len=' + IntToStr(Length(Html)));

  LineNames := TStringList.Create;
  Seen := TStringList.Create;
  try
    LineNames.Sorted := True;
    LineNames.Duplicates := dupIgnore;
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;

    // 线路名 tab: <a href="#playlistN" data-toggle="tab">线路名</a>，存 N=线路名
    TabRe := TRegEx.Create('<a href="#playlist(\d+)"[^>]*>\s*([^<]+?)\s*</a>', [roIgnoreCase, roSingleLine]);
    TabMs := TabRe.Matches(Html);
    for I := 0 to TabMs.Count - 1 do LineNames.Add(TabMs[I].Groups[1].Value + '=' + Trim(TabMs[I].Groups[2].Value));

    // 每个 <div id="playlistN"> 选集块，块内剧集为正文序
    BlockRe := TRegEx.Create('<div id="playlist(\d+)"[^>]*>([\s\S]*?)(?=<div id="playlist|\Z)', [roIgnoreCase, roSingleLine]);
    BlockMs := BlockRe.Matches(Html);
    LinkRe := TRegEx.Create('<a[^>]*href="/play/(\d+)-(\d+)-(\d+)\.html"[^>]*>([^<]+)</a>', [roIgnoreCase, roSingleLine]);
    for I := 0 to BlockMs.Count - 1 do
    begin
      StartIdx := Length(AEpisodes);
      LinkMs := LinkRe.Matches(BlockMs[I].Groups[2].Value);
      for J := 0 to LinkMs.Count - 1 do
      begin
        Vid := LinkMs[J].Groups[1].Value;
        Sid := LinkMs[J].Groups[2].Value;
        Nid := LinkMs[J].Groups[3].Value;
        Key := Sid + '|' + Nid;
        if Seen.IndexOf(Key) >= 0 then Continue;
        Seen.Add(Key);

        LineName := LineNameFor(LineNames, Sid);
        SetLength(AEpisodes, Length(AEpisodes) + 1);
        N := High(AEpisodes);
        AEpisodes[N].Num := Nid;
        AEpisodes[N].LineNo := LineName;
        AEpisodes[N].DataId := Sid;
        AEpisodes[N].PageUrl := FSiteRoot + '/play/' + Vid + '-' +  Sid + '-' + Nid + '.html';
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

function TSiteWhtqedu.ResolveM3U8(const APageUrl: string): string;
var
  Html, Api, Token, ApiUrl, JsonText, IframeUrl, UrlParam, PathPart: string;
  QPos: Integer;
  M: TMatch;
  Root: TJSONValue;
  Obj: TJSONObject;
  V: TJSONValue;
begin
  Result := '';
  Html := Ctx.HttpGetText(APageUrl, FSiteRoot + '/');
  Ctx.Log('ResolveM3U8 page=' + APageUrl + ' len=' + IntToStr(Length(Html)));

  // 步骤1: 提取 data-play-api 与 data-play-token
  M := TRegEx.Match(Html, 'data-play-api="([^"]+)"', [roIgnoreCase]);
  if not M.Success then raise Exception.Create('播放页未找到 data-play-api');
  Api := Trim(M.Groups[1].Value);

  M := TRegEx.Match(Html, 'data-play-token="([^"]+)"', [roIgnoreCase]);
  if not M.Success then raise Exception.Create('播放页未找到 data-play-token');
  Token := Trim(M.Groups[1].Value);
  Ctx.Log('ResolveM3U8 api=' + Api + ' token=' + Copy(Token, 1, 40) + '...');

  // 步骤2: 调用播放 API (?t=URL编码token)
  ApiUrl := MakeAbsolute(Api) + '?t=' + TNetEncoding.URL.Encode(Token);
  JsonText := Ctx.HttpGetText(ApiUrl, APageUrl);
  Ctx.Log('ResolveM3U8 api response=' + Copy(JsonText, 1, 300));

  Root := TJSONObject.ParseJSONValue(JsonText);
  if Root = nil then raise Exception.Create('播放 API 返回不是有效 JSON');
  try
    if not (Root is TJSONObject) then raise Exception.Create('播放 API 返回格式错误');
    Obj := TJSONObject(Root);

    V := Obj.GetValue('ok');
    if (V <> nil) and (V.Value <> 'true') then raise Exception.Create('播放 API 返回失败: ' + JsonText);

    V := Obj.GetValue('url');
    if V = nil then raise Exception.Create('播放 API 缺少 url 字段');
    IframeUrl := Trim(V.Value);
    if IframeUrl = '' then raise Exception.Create('播放地址为空');

    // 步骤3: 判断 url 是否为直接 m3u8（只看 '?' 之前的路径部分，避免 iframe
    //        地址的 query 里含 %2Findex.m3u8 被误判），否则从 iframe 取 url 参数
    PathPart := IframeUrl;
    QPos := Pos('?', PathPart);
    if QPos > 0 then PathPart := Copy(PathPart, 1, QPos - 1);
    if (Pos('.m3u8', PathPart) > 0) then
    begin
      // 直接 m3u8 地址
      Result := IframeUrl;
    end
    else
    begin
      // iframe 模式：从地址 query 中提取 url 参数并 URL 解码
      M := TRegEx.Match(IframeUrl, '[?&]url=([^&]+)', [roIgnoreCase]);
      if not M.Success then raise Exception.Create('iframe 地址中未找到 url 参数: ' + IframeUrl);
      UrlParam := TNetEncoding.URL.Decode(M.Groups[1].Value);
      if (UrlParam = '') or (Pos('.m3u8', UrlParam) = 0) then raise Exception.Create('解析出的播放地址无效: ' + UrlParam);
      Result := UrlParam;
    end;
  finally
    Root.Free;
  end;
end;

function TSiteWhtqedu.DownloadPlaylistAndBuildCmd(const AM3U8Url: string; ADownload: Boolean; const AToken: string): string;
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

function TSiteWhtqedu.BuildPlayCommand(const AEpisode: TEpisode): string;
begin
  LastResolvedUrl := ResolveM3U8(AEpisode.PageUrl);
  Ctx.Log('Resolved m3u8=' + LastResolvedUrl);
  Result := DownloadPlaylistAndBuildCmd(LastResolvedUrl, False, '');
end;

function TSiteWhtqedu.BuildDownloadCommand(const AEpisode: TEpisode; const AToken: string): string;
begin
  Result := DownloadPlaylistAndBuildCmd(ResolveM3U8(AEpisode.PageUrl), True, AToken);
end;

procedure TSiteWhtqedu.Cleanup;
begin
  Ctx.StopProxy;
end;

end.
