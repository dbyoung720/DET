unit Site4kvm;

// ============================================================
// 4kvm.org 站点解析器
//   继承 TSiteBase，实现 Search / LoadDetail / BuildPlayCommand。
//   站点专属的常量、正则、临时目录、WASM 签名逻辑全部封装在本单元。
//   执行脚本放在 sites\4kvm\ 下（SignHelper.mjs / ProxyHelper.mjs）。
// ============================================================

interface

uses
   Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.NetEncoding,
   System.JSON, System.RegularExpressions, System.Generics.Collections, SiteIntf;

type
  TSite4kvm = class(TSiteBase)
  private
    FSiteRoot: string;
    FWorkDir: string;          // 本站点临时目录 TempRoot\4kvm\
    FSecret: string;
    FUserLink: string;
    FWasmJsUrl: string;
    FWasmBinUrl: string;
    FUsedJsUrl: string;
    FUsedWasmUrl: string;
    FJsFile: string;
    FWasmFile: string;
    FHelperFile: string;
    FOutFile: string;
    FSourcePlaylistFile: string;
    FProxyHelperFile: string;
    function MakeAbsolute(const AUrl: string): string;
    function ExtractFirst(const AText, APattern: string): string;
    procedure WriteFileAtomic(const AFileName: string; const AData: TBytes);
    procedure EnsureWasmFiles;
    function RunSignHelper(const ADataId, ASecret, APlayKey: string): string;
    function ResolveM3U8(const ADataId: string): string;
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
  SITE_ROOT = 'https://www.4kvm.org';

constructor TSite4kvm.Create(ACtx: TSiteContext);
var
  SiteExe: string;
begin
  inherited Create(ACtx);
  // 绑定站点 ID：本站点的日志自此进入 log/日期/4kvm/
  BindSiteId;
  FSiteRoot := SITE_ROOT;
  FWorkDir := IncludeTrailingPathDelimiter(ACtx.TempRoot + Id);
  ForceDirectories(FWorkDir);

  FJsFile := TPath.Combine(FWorkDir, 'nbmovie_wasm.mjs');
  FWasmFile := TPath.Combine(FWorkDir, 'nbmovie_wasm_bg.wasm');
  FOutFile := TPath.Combine(FWorkDir, 'signed_url.txt');
  FSourcePlaylistFile := TPath.Combine(FWorkDir, 'source.m3u8');

  SiteExe := SiteExeDir(ACtx.ExeDir);
  FHelperFile := TPath.Combine(SiteExe, 'SignHelper.mjs');
  FProxyHelperFile := TPath.Combine(SiteExe, 'ProxyHelper.mjs');

  Ctx.Log('TSite4kvm created. helper=' + FHelperFile + ' proxy=' + FProxyHelperFile + ' exist=' +
    BoolToStr(TFile.Exists(FHelperFile), True) + '/' +
    BoolToStr(TFile.Exists(FProxyHelperFile), True));
end;

destructor TSite4kvm.Destroy;
begin
  inherited;
end;

class function TSite4kvm.Id: string;
begin
  Result := '4kvm';
end;

class function TSite4kvm.DisplayName: string;
begin
  Result := '4KVM 视频';
end;

class function TSite4kvm.DefaultKeyword: string;
begin
  Result := '凡人修仙传';
end;

function TSite4kvm.MakeAbsolute(const AUrl: string): string;
begin
  if AUrl.StartsWith('http') then
    Result := AUrl
  else if AUrl.StartsWith('/') then
    Result := FSiteRoot + AUrl
  else
    Result := FSiteRoot + '/' + AUrl;
end;

function TSite4kvm.ExtractFirst(const AText, APattern: string): string;
var
  M: TMatch;
begin
  Result := '';
  M := TRegEx.Match(AText, APattern, [roIgnoreCase, roSingleLine]);
  if M.Success and (M.Groups.Count > 1) then Result := Trim(M.Groups[1].Value);
end;

function TSite4kvm.Search(const AKeyword: string; AVideos: TStrings; out ASlugs: TSlugArray): Boolean;
var
  Html: string;
  Re, TagRe: TRegEx;
  Ms : TMatchCollection;
  M: TMatch;
  Link, Title, Slug: string;
  Seen: TStringList;
  I, P: Integer;
begin
  SetLength(ASlugs, 0);
  AVideos.Clear;
  Html := Ctx.HttpGetText(FSiteRoot + '/search?q=' + TNetEncoding.URL.Encode(AKeyword));

  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    Re := TRegEx.Create('<a\b[^>]*href="([^"]*/play/[a-z0-9_-]+)"[^>]*>([\s\S]*?)</a>', [roIgnoreCase, roSingleLine]);
    Ms := Re.Matches(Html);
    TagRe := TRegEx.Create('<[^>]+>', []);

    for I := 0 to Ms.Count - 1 do
    begin
      M := Ms[I];
      Link := M.Groups[1].Value;
      Slug := Copy(Link, LastDelimiter('/', Link) + 1, MaxInt);
      P := Pos('?', Slug);
      if P > 0 then Slug := Copy(Slug, 1, P - 1);
      P := Pos('#', Slug);
      if P > 0 then Slug := Copy(Slug, 1, P - 1);
      if (Slug = '') or (Seen.IndexOf(Slug) >= 0) then Continue;
      Seen.Add(Slug);

      Title := TNetEncoding.HTML.Decode(TagRe.Replace(M.Groups[2].Value, ' '));
      Title := Trim(StringReplace(Title, #13, ' ', [rfReplaceAll]));
      Title := Trim(StringReplace(Title, #10, ' ', [rfReplaceAll]));
      while Pos('  ', Title) > 0 do Title := StringReplace(Title, '  ', ' ', [rfReplaceAll]);
      if Length(Title) > 70 then Title := Copy(Title, 1, 70) + '...';
      if Title = '' then Title := Slug;

      SetLength(ASlugs, Length(ASlugs) + 1);
      ASlugs[High(ASlugs)] := Slug;
      AVideos.Add(Title);
    end;
    Result := True;
  finally
    Seen.Free;
  end;
end;

function TSite4kvm.LoadDetail(const ASlug: string; out AEpisodes: TEpisodeArray): Boolean;
var
  Html, TagText, DataId, EpNo, LineNo, Href, Tmp: string;
  TagRe: TRegEx;
  Tags: TMatchCollection;
  I, N: Integer;
  Seen: TStringList;
begin
  FSecret := ASlug;
  FUserLink := '';
  FWasmJsUrl := '';
  FWasmBinUrl := '';
  SetLength(AEpisodes, 0);

  Html := Ctx.HttpGetText(FSiteRoot + '/play/' + ASlug);

  FUserLink := ExtractFirst(Html, 'userlink\s*[:=]\s*[''"]([^''"]+)[''"]');
  Tmp := ExtractFirst(Html, '(?:data-js|src)\s*=\s*[''"]([^''"]*nbmovie_wasm[^''"]*\.js)[''"]');
  if Tmp = '' then
    Tmp := ExtractFirst(Html, '(nbmovie_wasm[^''"\s>]*\.js)');
  if Tmp <> '' then
    FWasmJsUrl := MakeAbsolute(Tmp);

  Tmp := ExtractFirst(Html, '(?:data-bg)\s*=\s*[''"]([^''"]*\.wasm)[''"]');
  if Tmp = '' then
    Tmp := ExtractFirst(Html, '(nbmovie_wasm[^''"\s>]*\.wasm)');
  if Tmp = '' then
    Tmp := StringReplace(FWasmJsUrl, '.js', '_bg.wasm', [rfIgnoreCase]);
  if Tmp <> '' then
    FWasmBinUrl := MakeAbsolute(Tmp);

  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    TagRe := TRegEx.Create('<a\b[^>]*href="[^"]*/play/[a-z0-9_-]+"[^>]*>', [roIgnoreCase, roSingleLine]);
    Tags := TagRe.Matches(Html);

    for I := 0 to Tags.Count - 1 do
    begin
      TagText := Tags[I].Value;
      DataId := ExtractFirst(TagText, 'dataid\s*=\s*[''"]?([0-9]+)');
      if DataId = '' then Continue;
      if Seen.IndexOf(DataId) >= 0 then Continue;
      Seen.Add(DataId);

      EpNo := ExtractFirst(TagText, 'data-episode\s*=\s*[''"]?([0-9]+)');
      if EpNo = '' then EpNo := IntToStr(Seen.Count);
      LineNo := ExtractFirst(TagText, 'data-line\s*=\s*[''"]?([0-9]+)');
      if LineNo = '' then LineNo := '1';
      Href := ExtractFirst(TagText, 'href\s*=\s*[''"]([^''"]+)[''"]');
      if Href = '' then Href := '/play/' + FSecret;
      if Pos('/play/', Href) = 1 then
        Href := FSiteRoot + Href
      else if not Href.StartsWith('http') then
        Href := FSiteRoot + '/' + Href;

      SetLength(AEpisodes, Length(AEpisodes) + 1);
      N := High(AEpisodes);
      AEpisodes[N].Num := EpNo;
      AEpisodes[N].LineNo := LineNo;
      AEpisodes[N].DataId := DataId;
      AEpisodes[N].PageUrl := Href;
    end;
  finally
    Seen.Free;
  end;

  // 按集数倒序（最新集在前）
  for I := 0 to High(AEpisodes) - 1 do
    for N := I + 1 to High(AEpisodes) do
      if StrToIntDef(AEpisodes[N].Num, 0) > StrToIntDef(AEpisodes[I].Num, 0) then
      begin
        Tmp := AEpisodes[I].Num; AEpisodes[I].Num := AEpisodes[N].Num; AEpisodes[N].Num := Tmp;
        Tmp := AEpisodes[I].LineNo; AEpisodes[I].LineNo := AEpisodes[N].LineNo; AEpisodes[N].LineNo := Tmp;
        Tmp := AEpisodes[I].DataId; AEpisodes[I].DataId := AEpisodes[N].DataId; AEpisodes[N].DataId := Tmp;
        Tmp := AEpisodes[I].PageUrl; AEpisodes[I].PageUrl := AEpisodes[N].PageUrl; AEpisodes[N].PageUrl := Tmp;
      end;

  Result := True;
end;

// 原子写入：先写唯一临时文件，再重试删除目标并改名。
// 避免固定文件被残留 node 进程或杀软短暂占用时 WriteAllBytes 抛 Access denied。
procedure TSite4kvm.WriteFileAtomic(const AFileName: string; const AData: TBytes);
begin
  ForceDirectories(ExtractFilePath(AFileName));
  var TmpName := AFileName + '.' + IntToStr(GetCurrentProcessId) + '.' + IntToStr(GetTickCount64) + '.tmp';
  // 写到唯一临时文件（不与任何正在使用的目标文件冲突）
  TFile.WriteAllBytes(TmpName, AData);
  // 重试删除旧目标（可能被占用），再原子改名
  for var I := 1 to 20 do
  begin
    try
      if TFile.Exists(AFileName) then
        TFile.Delete(AFileName);
      TFile.Move(TmpName, AFileName);
      Exit;
    except
      if I = 20 then
      begin
        // 最后一次仍失败：尽力清理临时文件，向上抛出
        try TFile.Delete(TmpName); except end;
        raise;
      end;
      Sleep(150);
    end;
  end;
end;

procedure TSite4kvm.EnsureWasmFiles;
begin
  if (FWasmJsUrl = '') or (FWasmBinUrl = '') then raise Exception.Create('页面中未找到 WASM 签名配置，请重新加载影片');

  // 工作目录已改为程序自身目录下的 .work（见 TSiteContext.Create），
  // 不受系统 Temp 清理/杀软按进程拦截影响；写入前仍确保目录存在。
  ForceDirectories(FWorkDir);

  // URL 变化或文件缺失时重新下载；WriteFileAtomic 用唯一临时文件 + 重试，
  // 化解文件被短暂占用导致的 Access denied。路径字段保持不变，避免层层嵌套。
  if (FUsedJsUrl <> FWasmJsUrl) or (not TFile.Exists(FJsFile)) then
  begin
    WriteFileAtomic(FJsFile, Ctx.HttpGetBytes(FWasmJsUrl));
    FUsedJsUrl := FWasmJsUrl;
  end;
  if (FUsedWasmUrl <> FWasmBinUrl) or (not TFile.Exists(FWasmFile)) then
  begin
    WriteFileAtomic(FWasmFile, Ctx.HttpGetBytes(FWasmBinUrl));
    FUsedWasmUrl := FWasmBinUrl;
  end;
end;

function TSite4kvm.RunSignHelper(const ADataId, ASecret, APlayKey: string): string;
var
  NODE_EXE : string;
  NodeExe, Cmd: string;
  SI: TStartupInfo;
  PI: TProcessInformation;
  SL: TStringList;
begin
  if not TFile.Exists(FHelperFile) then
    raise Exception.Create('缺少 SignHelper.mjs：' + FHelperFile);

  NODE_EXE := ExtractFilePath(ParamStr(0)) + 'plugins\nodejs\node.exe';
  if TFile.Exists(NODE_EXE) then NodeExe := NODE_EXE else NodeExe := 'node.exe';
  if TFile.Exists(FOutFile) then TFile.Delete(FOutFile);
  Cmd := '"' + NodeExe + '" "' + FHelperFile + '" "' + ADataId + '" "' +
         ASecret + '" "1080" "' + APlayKey + '" "' + FJsFile + '" "' +
         FWasmFile + '" "' + FOutFile + '"';

  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  if not CreateProcess(nil, PChar(Cmd), nil, nil, False, CREATE_NO_WINDOW, nil, nil, SI, PI) then raise Exception.Create('无法启动 Node.js（用于计算播放签名）');
  try
    if WaitForSingleObject(PI.hProcess, 60000) <> WAIT_OBJECT_0 then raise Exception.Create('播放签名计算超时');
  finally
    CloseHandle(PI.hThread);
    CloseHandle(PI.hProcess);
  end;

  if not TFile.Exists(FOutFile) then raise Exception.Create('签名助手没有生成结果');
  SL := TStringList.Create;
  try
    SL.LoadFromFile(FOutFile, TEncoding.UTF8);
    Result := Trim(SL.Text);
  finally
    SL.Free;
  end;
  if Result.StartsWith('ERROR:') then
    raise Exception.Create('签名失败: ' + Copy(Result, 7, MaxInt));
  if (Result = '') or (Pos('/video/play', Result) <> 1) then
    raise Exception.Create('签名结果无效: ' + Result);
end;

function TSite4kvm.ResolveM3U8(const ADataId: string): string;
var
  Signed, JsonText, Url: string;
  Root, DataObj: TJSONObject;
  Arr: TJSONArray;
  Item: TJSONValue;
  I: Integer;
begin
  Result := '';
  if FUserLink = '' then raise Exception.Create('未能从详情页取得 userlink');

  EnsureWasmFiles;
  Signed := RunSignHelper(ADataId, FSecret, FUserLink);
  JsonText := Ctx.HttpGetText(MakeAbsolute(Signed), FSiteRoot + '/');

  Root := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
  if Root = nil then raise Exception.Create('播放接口返回的不是有效 JSON');
  try
    if Root.GetValue<Integer>('code') <> 200 then raise Exception.Create('播放接口错误: ' + Root.GetValue<string>('msg'));
    DataObj := Root.GetValue('data') as TJSONObject;
    if DataObj = nil then raise Exception.Create('播放接口没有 data 字段');
    Arr := DataObj.GetValue('quality_urls') as TJSONArray;
    if Arr = nil then raise Exception.Create('播放接口没有 quality_urls 字段');
    for I := 0 to Arr.Count - 1 do
    begin
      Item := Arr.Items[I];
      if not (Item is TJSONObject) then Continue;
      if TJSONObject(Item).GetValue<Boolean>('locked') then Continue;
      Url := TJSONObject(Item).GetValue<string>('url');
      if Url.StartsWith('http') then Exit(Url);
    end;
    raise Exception.Create('没有可用的播放线路');
  finally
    Root.Free;
  end;
end;

function TSite4kvm.DownloadPlaylistAndBuildCmd(const AM3U8Url: string; ADownload: Boolean; const AToken: string): string;
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

function TSite4kvm.BuildPlayCommand(const AEpisode: TEpisode): string;
begin
  LastResolvedUrl := ResolveM3U8(AEpisode.DataId);
  Ctx.Log('Resolved m3u8=' + LastResolvedUrl);
  Result := DownloadPlaylistAndBuildCmd(LastResolvedUrl, False, '');
end;

function TSite4kvm.BuildDownloadCommand(const AEpisode: TEpisode; const AToken: string): string;
begin
  Result := DownloadPlaylistAndBuildCmd(ResolveM3U8(AEpisode.DataId), True, AToken);
end;

procedure TSite4kvm.Cleanup;
begin
  Ctx.StopProxy;
end;

end.
