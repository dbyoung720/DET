unit SiteGangju;

// ============================================================
// 港剧网（gangjuwang.tv / 苹果CMS）站点解析器
//   搜索: /search/{关键词}-------------.html
//   详情: /content/{id}.html            列出各线路的剧集
//   播放: /play/{id}-{线路}-{集数}.html  页面内 player_aaaa JSON 直接给出 m3u8 地址
//   m3u8 为两级结构(master->media)，由 ProxyHelper.mjs 递归展开
//   站点脚本: sites\gangju\ProxyHelper.mjs（本地分片代理）
// ============================================================

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.NetEncoding,
  System.JSON, System.RegularExpressions, Winapi.Windows, SiteIntf;

type
  TSiteGangju = class(TSiteBase)
  private
    FSiteRoot: string;
    FWorkDir: string;
    FSourcePlaylistFile: string;
    FProxyHelperFile: string;
    function MakeAbsolute(const AUrl: string): string;
    function StripTags(const AText: string): string;
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
  SITE_ROOT = 'https://www.gangjuwang.tv';

constructor TSiteGangju.Create(ACtx: TSiteContext);
var
  SiteExe: string;
begin
  inherited Create(ACtx);
  // 绑定站点 ID：日志进入 log\日期\gangju\
  BindSiteId;
  FSiteRoot := SITE_ROOT;
  FWorkDir := IncludeTrailingPathDelimiter(ACtx.TempRoot + Id);
  ForceDirectories(FWorkDir);
  FSourcePlaylistFile := TPath.Combine(FWorkDir, 'source.m3u8');

  SiteExe := SiteExeDir(ACtx.ExeDir);
  FProxyHelperFile := TPath.Combine(SiteExe, 'ProxyHelper.mjs');

  Ctx.Log('TSiteGangju created. proxy=' + FProxyHelperFile + ' exist=' + BoolToStr(TFile.Exists(FProxyHelperFile), True));
end;

class function TSiteGangju.Id: string;
begin
  Result := 'gangju';
end;

class function TSiteGangju.DisplayName: string;
begin
  Result := '港剧网';
end;

class function TSiteGangju.DefaultKeyword: string;
begin
  Result := '凡人修仙传';
end;

function TSiteGangju.MakeAbsolute(const AUrl: string): string;
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

function TSiteGangju.StripTags(const AText: string): string;
var
  TagRe: TRegEx;
begin
  TagRe := TRegEx.Create('<[^>]+>', []);
  Result := Trim(TagRe.Replace(AText, ' '));
end;

function TSiteGangju.Search(const AKeyword: string; AVideos: TStrings; out ASlugs: TSlugArray): Boolean;
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
  Html := Ctx.HttpGetText(FSiteRoot + '/search/' + TNetEncoding.URL.Encode(AKeyword) + '-------------.html', FSiteRoot + '/');
  Ctx.Log('Search html len=' + IntToStr(Length(Html)));

  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    // 搜索结果条目：<a class="video-pic loading" href="/content/3246.html" title="凡人修仙传" ...>
    Re := TRegEx.Create('<a[^>]*class="video-pic[^"]*"[^>]*href="/content/(\d+)\.html"[^>]*title="([^"]+)"',
      [roIgnoreCase, roSingleLine]);
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

function TSiteGangju.LoadDetail(const ASlug: string;
  out AEpisodes: TEpisodeArray): Boolean;
var
  Html, LineName: string;
  Re, LinkRe, TabRe: TRegEx;
  Ms, LinkMs: TMatchCollection;
  Parts: TArray<string>;
  TabList, Seen: TStringList;
  Key, Vid, Sid, Nid: string;
  I, N, PI, JI, NI, StartIdx, L, Half, Num: Integer;
  Tmp: TEpisode;
begin
  Result := False;
  SetLength(AEpisodes, 0);
  Html := Ctx.HttpGetText(FSiteRoot + '/content/' + ASlug + '.html', FSiteRoot + '/');
  Ctx.Log('LoadDetail ' + ASlug + ' html len=' + IntToStr(Length(Html)));

  TabList := TStringList.Create;
  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;

    // 线路名称标签：<a class="gico xxx" ...>线路G</a>（按出现顺序）
    TabRe := TRegEx.Create('<a\s+class="gico[^"]*"[^>]*>([^<]+)</a>', [roIgnoreCase, roSingleLine]);
    Ms := TabRe.Matches(Html);
    for I := 0 to Ms.Count - 1 do TabList.Add(Trim(Ms[I].Groups[1].Value));

    // 每个 con_playlist_N 区块对应一条线路的剧集列表
    Re := TRegEx.Create('<ul[^>]*id="con_playlist_\d+"[^>]*>', [roIgnoreCase]);
    Parts := Re.Split(Html);
    NI := 0;
    for PI := 1 to High(Parts) do
    begin
      if NI < TabList.Count then
        LineName := TabList[NI]
      else
        LineName := '线路' + IntToStr(NI + 1);
      Inc(NI);
      StartIdx := Length(AEpisodes);

      LinkRe := TRegEx.Create('<a\s+href="/play/(\d+)-(\d+)-(\d+)\.html"[^>]*title="[^"]*?第(\d+)集[^"]*"[^>]*>', [roIgnoreCase, roSingleLine]);
      LinkMs := LinkRe.Matches(Parts[PI]);
      for JI := 0 to LinkMs.Count - 1 do
      begin
        Vid := LinkMs[JI].Groups[1].Value;
        Sid := LinkMs[JI].Groups[2].Value;
        Nid := LinkMs[JI].Groups[3].Value;
        Key := Sid + '|' + Nid;
        if Seen.IndexOf(Key) >= 0 then Continue;
        Seen.Add(Key);

        SetLength(AEpisodes, Length(AEpisodes) + 1);
        N := High(AEpisodes);
        AEpisodes[N].Num := Nid;
        AEpisodes[N].LineNo := LineName;
        AEpisodes[N].DataId := Sid;
        AEpisodes[N].PageUrl := FSiteRoot + '/play/' + Vid + '-' + Sid + '-' + Nid + '.html';
      end;

      // 页面本身通常已倒序；这里再确保每条线路内按集数倒序（最新在前）
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
    TabList.Free;
  end;
end;

function TSiteGangju.ResolveM3U8(const APageUrl: string): string;
var
  Html, JsonText, Url: string;
  M: TMatch;
  Root: TJSONValue;
  Obj: TJSONObject;
  V: TJSONValue;
begin
  Result := '';
  Html := Ctx.HttpGetText(APageUrl, FSiteRoot + '/');
  Ctx.Log('ResolveM3U8 page=' + APageUrl + ' len=' + IntToStr(Length(Html)));

  M := TRegEx.Match(Html, 'var\s+player_aaaa\s*=\s*(\{[\s\S]*?\})\s*</script>', [roIgnoreCase, roSingleLine]);
  if not M.Success then raise Exception.Create('播放页未找到 player_aaaa 配置');

  JsonText := M.Groups[1].Value;
  Root := TJSONObject.ParseJSONValue(JsonText);
  if Root = nil then raise Exception.Create('播放配置不是有效的 JSON');
  try
    if not (Root is TJSONObject) then raise Exception.Create('播放配置格式错误');
    Obj := TJSONObject(Root);

    V := Obj.GetValue('encrypt');
    if (V <> nil) and (V.Value <> '0') then Ctx.Log('警告: encrypt=' + V.Value + '（本站按明文处理）');

    V := Obj.GetValue('url');
    if V = nil then raise Exception.Create('播放配置缺少 url 字段');
    Url := Trim(V.Value);
    if Url = '' then raise Exception.Create('播放地址为空（可能需要登录）');

    Result := MakeAbsolute(Url);
  finally
    Root.Free;
  end;
end;

function TSiteGangju.DownloadPlaylistAndBuildCmd(const AM3U8Url: string; ADownload: Boolean; const AToken: string): string;
var
  M3U8Text, Head, SourceFile: string;
begin
  Ctx.Log('BuildPlayCommand url=' + AM3U8Url);
  // 默认路径：预下载失败时代理脚本仍需一个有效源文件
  if ADownload then
    SourceFile := TPath.Combine(FWorkDir, 'download_source_' + AToken + '.m3u8')
  else
    SourceFile := FSourcePlaylistFile;

  // 预先下载主列表仅作代理脚本的回退来源；失败不影响后续（脚本会自行 curl 下载）
  try
    M3U8Text := Ctx.HttpGetText(AM3U8Url, FSiteRoot + '/');
    if M3U8Text <> '' then
    begin
      Head := Copy(StringReplace(M3U8Text, #10, '|', [rfReplaceAll]), 1, 400);
      Ctx.Log('M3U8 len=' + IntToStr(Length(M3U8Text)) + ' head=' + Head);
      // 防御：临时目录可能被系统清理，写入前确保存在
      // 下载使用独立的源列表文件，避免覆盖播放代理正在使用的文件
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
    // 下载走独立代理进程，绝不停止 VLC 正在使用的播放代理
    Result := Ctx.StartDownloadProxy(FProxyHelperFile, SourceFile, AM3U8Url, AToken);
    if Result = '' then raise Exception.Create('下载代理创建失败，请检查 Node 运行环境');
    Ctx.Log('Using DOWNLOAD PROXY url=' + Result);
  end
  else
  begin
    // 只让 VLC 播放本地代理地址，绝不直连远程 HTTPS（避免 VLC 弹出证书对话框）
    if Ctx.StartLocalProxy(FProxyHelperFile, SourceFile, AM3U8Url) then
    begin
      Result := '"http://127.0.0.1:' + IntToStr(Ctx.ProxyPort) + '/index.m3u8" --no-video-title-show';
      Ctx.Log('Using LOCAL PROXY command=' + Result);
    end
    else
      raise Exception.Create('本地播放代理启动失败，请检查 Node 环境后重试');
  end;
end;

function TSiteGangju.BuildPlayCommand(const AEpisode: TEpisode): string;
begin
  LastResolvedUrl := ResolveM3U8(AEpisode.PageUrl);
  Ctx.Log('Resolved m3u8=' + LastResolvedUrl);
  Result := DownloadPlaylistAndBuildCmd(LastResolvedUrl, False, '');
end;

function TSiteGangju.BuildDownloadCommand(const AEpisode: TEpisode; const AToken: string): string;
begin
  Result := DownloadPlaylistAndBuildCmd(ResolveM3U8(AEpisode.PageUrl), True, AToken);
end;

procedure TSiteGangju.Cleanup;
begin
  Ctx.StopProxy;
end;

end.
