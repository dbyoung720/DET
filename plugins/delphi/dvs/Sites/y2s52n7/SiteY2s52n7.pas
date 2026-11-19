unit SiteY2s52n7;

// ============================================================
// 爱电影 (www.y2s52n7.com) Next.js 签名 API 站点适配器
//   全站数据走 REST API: https://www.y2s52n7.com/mw-movie/anonymous/*
//   签名(逆向 49858 模块):
//     sign = SHA1( MD5( sortedParams + '&key=<SIGNKEY>&t=<毫秒时间戳>' ).hex ).hex
//     GET 参数先按键排序拼 k=v&k=v，过滤空值；无参数时拼接串为 key=...&t=...
//   请求头: sign / t / deviceId(UUID) / authorization(空)
//     ★ 不能带 Referer（带 Referer 会被伪装成 404 拦截）
//     ★ 频率限流敏感：连续请求会被伪装 404，需节流(≥2.5s)+失败等待重试
//   接口:
//     GET /anonymous/video/searchByWord?keyword=&pageNum=&pageSize=
//       -> data.result.list[] (vodId / vodName / vodClass / vodTotal)
//     GET /anonymous/video/detail?id=
//       -> data.episodeList[] (nid / name / sort) 正序，需翻转成倒序
//     GET /anonymous/v2/video/episode/url?id=&nid=&clientType=1
//       -> data.list[] {flag,needLogin,resolutionName,url}
//          取 flag=true(免登录)项的 url；若无则取 needLogin=false 项
//   m3u8: 单级 + 分片带 sign/t/whip query，whip 绑定请求出口 IP，
//         必须本机直连(不走系统代理)；分片相对路径由代理脚本 absUrl 拼接
//   站点脚本: sites\y2s52n7\ProxyHelper.mjs
// ============================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.NetEncoding,
  System.JSON, System.Hash, System.Net.HttpClient, System.Net.URLClient,
  System.RegularExpressions, System.DateUtils, System.Generics.Collections, SiteIntf;

type
  TSiteY2s52n7 = class(TSiteBase)
  private
    FSiteRoot: string;
    FApiBase: string;
    FWorkDir: string;
    FSourcePlaylistFile: string;
    FProxyHelperFile: string;
    FHttp: THTTPClient;
    FLastApiTick: Int64;
    FDeviceId: string;
    function ApiGetJson(const APath: string; const AParams: TStringList; out AJson: TJSONObject): Boolean;
    function ParamSig(const AParams: TStringList; const ATick: Int64): string;
    procedure Throttle;
    function ResolveM3U8(const AEpisode: TEpisode): string;
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
  SITE_ROOT = 'https://www.y2s52n7.com';
  API_BASE  = SITE_ROOT + '/mw-movie';
  SIGN_KEY  = 'cb808529bae6b6be45ecfab29a4889bc';

constructor TSiteY2s52n7.Create(ACtx: TSiteContext);
begin
  inherited Create(ACtx);
  BindSiteId;
  FSiteRoot := SITE_ROOT;
  FApiBase := API_BASE;
  FWorkDir := IncludeTrailingPathDelimiter(ACtx.TempRoot + Id);
  ForceDirectories(FWorkDir);
  FSourcePlaylistFile := TPath.Combine(FWorkDir, 'source.m3u8');
  FProxyHelperFile := TPath.Combine(SiteExeDir(ACtx.ExeDir), 'ProxyHelper.mjs');

  // 本站 API/CDN 必须直连，显式清空代理设置
  FHttp := THTTPClient.Create;
  FHttp.UserAgent := USER_AGENT;


  FLastApiTick := 0;
  FDeviceId := '{' + LowerCase(THashMD5.GetHashString(IntToStr(GetTickCount64) + IntToStr(GetCurrentProcessId) + USER_AGENT)) + '}';

  Ctx.Log('TSiteY2s52n7 created. proxy=' + FProxyHelperFile + ' exist=' + BoolToStr(TFile.Exists(FProxyHelperFile), True));
end;

destructor TSiteY2s52n7.Destroy;
begin
  FHttp.Free;
  inherited;
end;

class function TSiteY2s52n7.Id: string;
begin
  Result := 'y2s52n7';
end;

class function TSiteY2s52n7.DisplayName: string;
begin
  Result := '爱电影';
end;

class function TSiteY2s52n7.DefaultKeyword: string;
begin
  Result := '凡人修仙传';
end;

procedure TSiteY2s52n7.Throttle;
var
  NowTick, Elapsed: Int64;
begin
  NowTick := GetTickCount64;
  if FLastApiTick > 0 then
  begin
    Elapsed := NowTick - FLastApiTick;
    if Elapsed < 2600 then
      Sleep(2600 - Elapsed);
  end;
  FLastApiTick := GetTickCount64;
end;

function TSiteY2s52n7.ParamSig(const AParams: TStringList; const ATick: Int64): string;
var
  Sorted: TStringList;
  I: Integer;
  Joined, Raw, Md5Hex: string;
begin
  Sorted := TStringList.Create;
  try
    Sorted.Sorted := True;
    for I := 0 to AParams.Count - 1 do
      if AParams[I] <> '' then
        Sorted.Add(AParams.Names[I] + '=' + AParams.ValueFromIndex[I]);
    Joined := '';
    for I := 0 to Sorted.Count - 1 do
    begin
      if Joined <> '' then Joined := Joined + '&';
      Joined := Joined + Sorted[I];
    end;
  finally
    Sorted.Free;
  end;
  if Joined <> '' then
    Raw := Joined + '&'
  else
    Raw := '';
  Raw := Raw + 'key=' + SIGN_KEY + '&t=' + IntToStr(ATick);
  Md5Hex := THashMD5.GetHashString(Raw);
  Result := THashSHA1.GetHashString(Md5Hex);
end;

function TSiteY2s52n7.ApiGetJson(const APath: string; const AParams: TStringList; out AJson: TJSONObject): Boolean;
var
  Attempt, I: Integer;
  Url, Sign, TickStr, Joined: string;
  Resp: IHTTPResponse;
  Headers: TNetHeaders;
  RespText: string;
  Sorted: TStringList;
begin
  Result := False;
  AJson := nil;

  for Attempt := 1 to 6 do
  begin
    Throttle;
    // 真实 Unix 毫秒时间戳（与 JS Date.now() 一致）
    TickStr := IntToStr(MillisecondsBetween(Now, EncodeDate(1970, 1, 1)));

    Sign := ParamSig(AParams, StrToInt64(TickStr));

    // 组装 query（过滤空值），与签名用同一批参数
    Sorted := TStringList.Create;
    try
      Sorted.Sorted := True;
      for I := 0 to AParams.Count - 1 do
        if AParams[I] <> '' then
          Sorted.Add(AParams.Names[I] + '=' + TNetEncoding.URL.Encode(AParams.ValueFromIndex[I]));
      Joined := '';
      for I := 0 to Sorted.Count - 1 do
      begin
        if Joined <> '' then Joined := Joined + '&';
        Joined := Joined + Sorted[I];
      end;
    finally
      Sorted.Free;
    end;

    Url := FApiBase + APath;
    if Joined <> '' then Url := Url + '?' + Joined;

    // 动态设置签名头
    // 动态设置签名头（不要设置空值头，WinHTTP 会报 12150）
    SetLength(Headers, 3);
    Headers[0].Name := 'deviceId'; Headers[0].Value := FDeviceId;
    Headers[1].Name := 'sign';     Headers[1].Value := Sign;
    Headers[2].Name := 't';        Headers[2].Value := TickStr;

    try
      Resp := FHttp.Get(Url, nil, Headers);
      RespText := Resp.ContentAsString(TEncoding.UTF8);
      if Resp.StatusCode = 200 then
      begin
        AJson := TJSONObject.ParseJSONValue(RespText) as TJSONObject;
        if (AJson <> nil) and (AJson is TJSONObject) then
        begin
          if TJSONObject(AJson).GetValue<Integer>('code', -1) = 200 then
          begin
            Result := True;
            Exit;
          end;
        end;
        FreeAndNil(AJson);
        Ctx.Log('ApiGetJson bad-code attempt=' + IntToStr(Attempt) + ' resp=' + Copy(RespText, 1, 200));
      end
      else
        Ctx.Log('ApiGetJson HTTP=' + IntToStr(Resp.StatusCode) + ' attempt=' + IntToStr(Attempt));
    except
      on E: Exception do
        Ctx.Log('ApiGetJson EX attempt=' + IntToStr(Attempt) + ' ' + E.Message);
    end;
    // 限流/失败：递增等待后重试
    Sleep(1500 * Attempt);
  end;
end;

function TSiteY2s52n7.Search(const AKeyword: string; AVideos: TStrings; out ASlugs: TSlugArray): Boolean;
var
  Params: TStringList;
  Root: TJSONObject;
  DataObj, ResultObj: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
  Obj: TJSONObject;
  V: TJSONValue;
  Slug, Title: string;
begin
  Result := False;
  SetLength(ASlugs, 0);
  AVideos.Clear;
  Params := TStringList.Create;
  try
    Params.Add('keyword=' + AKeyword);
    Params.Add('pageNum=1');
    Params.Add('pageSize=40');
    if not ApiGetJson('/anonymous/video/searchByWord', Params, Root) then
      Exit;
    try
      DataObj := Root.GetValue('data') as TJSONObject;
      if DataObj = nil then Exit;
      ResultObj := DataObj.GetValue('result') as TJSONObject;
      if ResultObj = nil then Exit;
      Arr := ResultObj.GetValue('list') as TJSONArray;
      if Arr = nil then Exit;

      for I := 0 to Arr.Count - 1 do
      begin
        Obj := Arr.Items[I] as TJSONObject;
        if Obj = nil then Continue;
        V := Obj.GetValue('vodId'); if V = nil then Continue;
        Slug := V.Value;
        V := Obj.GetValue('vodName'); if V = nil then Continue;
        Title := V.Value;
        V := Obj.GetValue('vodClass');
        if (V <> nil) and (V.Value <> '') then Title := Title + ' [' + V.Value + ']';
        SetLength(ASlugs, Length(ASlugs) + 1);
        ASlugs[High(ASlugs)] := Slug;
        AVideos.Add(Title);
      end;
      Ctx.Log('Search found ' + IntToStr(Length(ASlugs)) + ' videos');
      Result := True;
    finally
      Root.Free;
    end;
  finally
    Params.Free;
  end;
end;

function TSiteY2s52n7.LoadDetail(const ASlug: string;  out AEpisodes: TEpisodeArray): Boolean;
var
  Params: TStringList;
  Root: TJSONObject;
  DataObj: TJSONObject;
  Arr: TJSONArray;
  Obj, EpObj: TJSONObject;
  I, Half, L, N1, N2: Integer;
  Tmp: TEpisode;
begin
  Result := False;
  SetLength(AEpisodes, 0);
  Params := TStringList.Create;
  try
    Params.Add('id=' + ASlug);
    if not ApiGetJson('/anonymous/video/detail', Params, Root) then Exit;
    try
      DataObj := Root.GetValue('data') as TJSONObject;
      if DataObj = nil then Exit;
      Arr := DataObj.GetValue('episodeList') as TJSONArray;
      if Arr = nil then Exit;

      for I := 0 to Arr.Count - 1 do
      begin
        Obj := Arr.Items[I] as TJSONObject;
        if Obj = nil then Continue;
        EpObj := Obj;
        if EpObj.GetValue('nid') = nil then Continue;
        SetLength(AEpisodes, Length(AEpisodes) + 1);
        N1 := High(AEpisodes);
        AEpisodes[N1].DataId := EpObj.GetValue('nid').Value;
        if EpObj.GetValue('name') <> nil then
          AEpisodes[N1].Num := '第' + EpObj.GetValue('name').Value + '集'
        else
          AEpisodes[N1].Num := IntToStr(I + 1);
        AEpisodes[N1].LineNo := '默认线路';
        // 播放 API 需要 vid + nid，用 '|' 编码进 PageUrl
        AEpisodes[N1].PageUrl := ASlug + '|' + AEpisodes[N1].DataId;
      end;

      // 页面正序 -> 翻转成倒序（最新集在前）
      if Length(AEpisodes) > 1 then
      begin
        N1 := StrToIntDef(TRegEx.Replace(AEpisodes[0].Num, '[^0-9]', ''), 0);
        N2 := StrToIntDef(TRegEx.Replace(AEpisodes[High(AEpisodes)].Num, '[^0-9]', ''), 0);
        if N1 < N2 then
        begin
          Half := Length(AEpisodes) div 2;
          for L := 0 to Half - 1 do
          begin
            Tmp := AEpisodes[L];
            AEpisodes[L] := AEpisodes[High(AEpisodes) - L];
            AEpisodes[High(AEpisodes) - L] := Tmp;
          end;
        end;
      end;

      Ctx.Log('LoadDetail ' + ASlug + ' found ' + IntToStr(Length(AEpisodes)) + ' episodes');
      Result := Length(AEpisodes) > 0;
    finally
      Root.Free;
    end;
  finally
    Params.Free;
  end;
end;

function TSiteY2s52n7.ResolveM3U8(const AEpisode: TEpisode): string;
var
  Vid, Nid: string;
  Params: TStringList;
  Root: TJSONObject;
  DataObj: TJSONObject;
  Arr: TJSONArray;
  Obj: TJSONObject;
  I: Integer;
  Url, FlagStr: string;
  BestFlag, BestNoLogin: string;
  NeedLoginV: TJSONValue;
begin
  Result := '';
  Vid := '';
  // ASlug(vodId) 未随 TEpisode 传递，这里从 PageUrl 里编码 "vid|nid"
  if Pos('|', AEpisode.PageUrl) > 0 then
  begin
    Vid := Copy(AEpisode.PageUrl, 1, Pos('|', AEpisode.PageUrl) - 1);
    Nid := Copy(AEpisode.PageUrl, Pos('|', AEpisode.PageUrl) + 1, MaxInt);
  end
  else
    Nid := AEpisode.PageUrl;

  if Vid = '' then raise Exception.Create('缺少视频 ID，无法解析播放地址');

  Params := TStringList.Create;
  try
    Params.Add('id=' + Vid);
    Params.Add('nid=' + Nid);
    Params.Add('clientType=1');
    if not ApiGetJson('/anonymous/v2/video/episode/url', Params, Root) then raise Exception.Create('播放地址 API 请求失败');
    try
      DataObj := Root.GetValue('data') as TJSONObject;
      if DataObj = nil then Exit;
      Arr := DataObj.GetValue('list') as TJSONArray;
      if Arr = nil then Exit;

      BestFlag := '';
      BestNoLogin := '';
      for I := 0 to Arr.Count - 1 do
      begin
        Obj := Arr.Items[I] as TJSONObject;
        if Obj = nil then Continue;
        if Obj.GetValue('url') = nil then Continue;
        Url := Trim(Obj.GetValue('url').Value);
        if Pos('.m3u8', Url) = 0 then Continue;
        NeedLoginV := Obj.GetValue('needLogin');
        if Obj.GetValue('flag') <> nil then FlagStr := Obj.GetValue('flag').Value else FlagStr := '';
        // flag=true 为免登录线路；needLogin=false 也可以
        if (FlagStr = 'true') and (BestFlag = '') then BestFlag := Url;
        if (NeedLoginV <> nil) and (NeedLoginV.Value = 'false') and (BestNoLogin = '') then
          BestNoLogin := Url;
      end;
      if BestFlag <> '' then Result := BestFlag
      else if BestNoLogin <> '' then Result := BestNoLogin
      else if Arr.Count > 0 then
      begin
        // 兜底：取第一个有 url 的
        Obj := Arr.Items[0] as TJSONObject;
        if (Obj <> nil) and (Obj.GetValue('url') <> nil) then Result := Obj.GetValue('url').Value;
      end;
      Ctx.Log('ResolveM3U8 vid=' + Vid + ' nid=' + Nid + ' url=' + Copy(Result, 1, 160));
    finally
      Root.Free;
    end;
  finally
    Params.Free;
  end;
end;

function TSiteY2s52n7.DownloadPlaylistAndBuildCmd(const AM3U8Url: string; ADownload: Boolean; const AToken: string): string;
var
  M3U8Text, Head, SourceFile: string;
begin
  Ctx.Log('DownloadPlaylist url=' + Copy(AM3U8Url, 1, 200));
  if ADownload then
    SourceFile := TPath.Combine(FWorkDir, 'download_source_' + AToken + '.m3u8')
  else
    SourceFile := FSourcePlaylistFile;

  try
    M3U8Text := Ctx.HttpGetText(AM3U8Url, '');
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

function TSiteY2s52n7.BuildPlayCommand(const AEpisode: TEpisode): string;
begin
  LastResolvedUrl := ResolveM3U8(AEpisode);
  Result := DownloadPlaylistAndBuildCmd(LastResolvedUrl, False, '');
end;

function TSiteY2s52n7.BuildDownloadCommand(const AEpisode: TEpisode; const AToken: string): string;
begin
  Result := DownloadPlaylistAndBuildCmd(ResolveM3U8(AEpisode), True, AToken);
end;

procedure TSiteY2s52n7.Cleanup;
begin
  Ctx.StopProxy;
end;

end.
