unit SiteIntf;

// ============================================================
// 站点接口单元：多站点架构的基础
//   - TEpisode / TEpisodeArray : 通用剧集数据结构
//   - TSiteContext : 运行时公共服务（HTTP动态代理 / 本地分片代理 / VLC / 日志）
//   - TSiteBase : 所有站点解析器的抽象基类
//   - TSiteClass : 站点类引用类型（用于注册工厂）
// 新增站点：继承 TSiteBase 实现三个核心方法，再到 SiteRegistry 注册即可。
// ============================================================

interface

uses Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.Net.HttpClient, System.Net.URLClient, System.Win.Registry;

const
  USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

type
  TEpisode = record
    Num: string;       // 集数
    LineNo: string;    // 线路
    DataId: string;    // 分集 ID
    PageUrl: string;   // 地址
  end;
  TEpisodeArray = array of TEpisode;
  TSlugArray    = array of string;

  // ---------- 运行时公共服务 ----------
  // 单个下载代理槽位：每个下载任务一个独立 node 进程，按 token 隔离
  TDownloadProxySlot = record
    Token: string;
    Process: TProcessInformation;
    Running: Boolean;
    Port: Integer;
  end;

  TSiteContext = class
  private
    FHttp: THTTPClient;
    FLastProxyUrl: string;
    FProxyProcess: TProcessInformation;
    FProxyRunning: Boolean;
    FProxyPort: Integer;
    FDownloadProxies: array of TDownloadProxySlot;
    FExeDir: string;
    FTempRoot: string;
    FCurrentSiteId: string;
    function GetCurrentProxyUrl: string;
    function FindDownloadSlot(const AToken: string): Integer;
    procedure EnsureHttpClient;
    function GetCurrentSiteId: string;
    procedure SetCurrentSiteId(const AValue: string);
  public
    constructor Create(const AExeDir: string);
    destructor Destroy; override;
    // HTTP（自动跟随系统代理的动态变化）
    function HttpGetText(const AUrl: string; const AReferer: string = ''): string;
    function HttpGetBytes(const AUrl: string): TBytes;
    // 本地分片代理：下载 m3u8 → 启动 Node 代理 → 返回本地播放端口
    function StartLocalProxy(const AHelperFile, APlaylistFile, AM3U8Url: string): Boolean;
    procedure StopProxy;
    // 下载专用代理：与播放代理分离，下载时不会停止 VLC 正在播放的流
    function StartDownloadProxy(const AHelperFile, APlaylistFile, AM3U8Url, AToken: string): string;
    procedure StopDownloadProxy(const AToken: string);
    procedure StopAllDownloadProxies;
    property ProxyPort: Integer read FProxyPort;
    // 外部 VLC 播放
    procedure PlayInVlc(const ACmdTail: string);
    // 日志：<exe目录>\log\yyyy-mm-dd\<站点ID>\
    //   app.log   主程序与站点调试日志
    //   proxy.log 分片代理日志
    //   vlc.log   VLC 播放器日志
    function LogDirFor(const ASiteId: string): string;
    function CurrentLogDir: string;
    // 工具
    procedure Log(const S: string);
    property ExeDir: string read FExeDir;
    property TempRoot: string read FTempRoot;
    property CurrentSiteId: string read GetCurrentSiteId write SetCurrentSiteId;
  end;

  // ---------- 站点解析器抽象基类 ----------
  TSiteBase = class abstract
  private
    FCtx: TSiteContext;
    FLastResolvedUrl: string;
  protected
    property Ctx: TSiteContext read FCtx;
    property LastResolvedUrl: string read FLastResolvedUrl write FLastResolvedUrl;
    // 派生类在自身构造函数中调用，确保站点日志目录从一开始就正确
    procedure BindSiteId;
  public
    constructor Create(ACtx: TSiteContext); virtual;
    destructor Destroy; override;
    // 站点元信息（类方法：无需实例即可读取，便于列表展示）
    class function Id: string; virtual;                         // 目录名，如 '4kvm'
    class function DisplayName: string; virtual; abstract;    // 下拉框显示名
    class function DefaultKeyword: string; virtual;           // 默认搜索词
    class function SiteExeDir(const AExeDir: string): string; virtual; // 站点脚本目录
    // 核心解析（各站点实现）
    function Search(const AKeyword: string; AVideos: TStrings; out ASlugs: TSlugArray): Boolean; virtual; abstract;
    function LoadDetail(const ASlug: string; out AEpisodes: TEpisodeArray): Boolean; virtual; abstract;
    function BuildPlayCommand(const AEpisode: TEpisode): string; virtual; abstract;
    // 下载专用：返回本地代理 m3u8 地址，绝不停止播放代理
    function BuildDownloadCommand(const AEpisode: TEpisode; const AToken: string): string; virtual;
    // 清理自身资源（换站点 / 销毁时调用）
    procedure Cleanup; virtual;
    // 最近一次 BuildPlayCommand 解析出的原始播放地址（供界面回填）
    property ResolvedUrl: string read FLastResolvedUrl;
    // 当前站点 ID（实例方式取用，供日志分目录）
    function SiteId: string;
  end;

  TSiteClass = class of TSiteBase;
  function CheckVlcExePath : string;

implementation

function CheckVlcExePath : string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'plugins\vlc\vlc.exe';
end;

function StreamToBytes(AStream: TStream): TBytes;
begin
  SetLength(Result, AStream.Size);
  AStream.Position := 0;
  if Length(Result) > 0 then AStream.ReadBuffer(Result[0], Length(Result));
end;

{ TSiteContext }

constructor TSiteContext.Create(const AExeDir: string);
begin
  inherited Create;
  FExeDir := IncludeTrailingPathDelimiter(AExeDir);
  FTempRoot := IncludeTrailingPathDelimiter(AExeDir) + '.work' + PathDelim;
  ForceDirectories(FTempRoot);
  FHttp         := nil;
  FLastProxyUrl := '';
  FProxyPort    := 0;
  FProxyRunning := False;
  SetLength(FDownloadProxies, 0);
  FCurrentSiteId := '_global';
end;

destructor TSiteContext.Destroy;
begin
  StopAllDownloadProxies;
  StopProxy;
  FreeAndNil(FHttp);
  inherited;
end;

function TSiteContext.LogDirFor(const ASiteId: string): string;
begin
  var Sid := Trim(ASiteId);
  if Sid = '' then Sid := '_global';
  Result := IncludeTrailingPathDelimiter(FExeDir) + 'log' + PathDelim + FormatDateTime('yyyy-MM-dd', Now) + PathDelim + Sid + PathDelim;
end;

function TSiteContext.CurrentLogDir: string;
begin
  Result := LogDirFor(FCurrentSiteId);
end;

function TSiteContext.GetCurrentSiteId: string;
begin
  Result := FCurrentSiteId;
end;

procedure TSiteContext.SetCurrentSiteId(const AValue: string);
begin
  FCurrentSiteId := Trim(AValue);
  if FCurrentSiteId = '' then FCurrentSiteId := '_global';
end;

procedure TSiteContext.Log(const S: string);
var
  Dir, Fn: string;
  F: TFileStream;
  Line: string;
  Bytes: TBytes;
  Mode: Word;
begin
  try
    Dir := CurrentLogDir;
    ForceDirectories(Dir);
    Fn := TPath.Combine(Dir, 'app.log');
    Line := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' ' + S + sLineBreak;
    Bytes := TEncoding.UTF8.GetBytes(Line);
    // 文件不存在时用 fmCreate 创建，已存在则以读写方式追加到末尾
    if TFile.Exists(Fn) then
      Mode := fmOpenReadWrite or fmShareDenyWrite
    else
      Mode := fmCreate or fmShareDenyWrite;
    F := TFileStream.Create(Fn, Mode);
    try
      F.Seek(0, soEnd);
      if Length(Bytes) > 0 then F.WriteBuffer(Bytes[0], Length(Bytes));
    finally
      F.Free;
    end;
  except
    on E: Exception do
      // 日志失败不影响主流程
      OutputDebugString(PChar('Log failed: ' + E.Message));
  end;
end;

function TSiteContext.GetCurrentProxyUrl: string;
var
  Reg: TRegistry;
  S: string;
  P: Integer;
begin
  Result := '';
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if not Reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Internet Settings') then Exit;
    try
      if not Reg.ValueExists('ProxyEnable') then Exit;
      if Reg.ReadInteger('ProxyEnable') <> 1 then Exit;
      if not Reg.ValueExists('ProxyServer') then Exit;
      S := Trim(Reg.ReadString('ProxyServer'));
    finally
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
  if S = '' then Exit;
  if Pos('=', S) > 0 then
  begin
    P := Pos(';', S);
    if P > 0 then S := Copy(S, 1, P - 1);
    P := Pos('=', S);
    if P > 0 then S := Copy(S, P + 1, MaxInt);
  end;
  if Pos('://', S) = 0 then S := 'http://' + S;
  Result := S;
end;

procedure TSiteContext.EnsureHttpClient;
begin
  var PUrl := GetCurrentProxyUrl;
  if Assigned(FHttp) and (PUrl = FLastProxyUrl) then Exit;
  FreeAndNil(FHttp);
  FHttp := THTTPClient.Create;
  FHttp.UserAgent := USER_AGENT;
  if PUrl <> '' then FHttp.ProxySettings := TProxySettings.Create(PUrl);
  FLastProxyUrl := PUrl;
  Log('EnsureHttpClient proxy=' + PUrl);
end;

function TSiteContext.HttpGetText(const AUrl: string; const AReferer: string): string;
var
  Resp   : IHTTPResponse;
  Headers: TNetHeaders;
begin
  EnsureHttpClient;
  if AReferer <> '' then
  begin
    SetLength(Headers, 1);
    Headers[0].Name := 'Referer';
    Headers[0].Value := AReferer;
    Resp := FHttp.Get(AUrl, nil, Headers);
  end
  else
    Resp := FHttp.Get(AUrl);
  if Resp.StatusCode <> 200 then raise Exception.CreateFmt('HTTP %d : %s', [Resp.StatusCode, AUrl]);
  Result := Resp.ContentAsString(TEncoding.UTF8);
end;

function TSiteContext.HttpGetBytes(const AUrl: string): TBytes;
var
  Resp: IHTTPResponse;
begin
  EnsureHttpClient;
  Resp := FHttp.Get(AUrl);
  if Resp.StatusCode <> 200 then raise Exception.CreateFmt('HTTP %d : %s', [Resp.StatusCode, AUrl]);
  Result := StreamToBytes(Resp.ContentStream);
end;

procedure TSiteContext.StopProxy;
begin
  if not FProxyRunning then Exit;
  
  try
    TerminateProcess(FProxyProcess.hProcess, 0);
  except
  end;
  
  try
    CloseHandle(FProxyProcess.hThread);
  except
  end;
  
  try
    CloseHandle(FProxyProcess.hProcess);
  except
  end;
  
  FProxyRunning := False;
  FProxyPort := 0;
end;

function TSiteContext.FindDownloadSlot(const AToken: string): Integer;
begin
  Result := -1;
  for var I := 0 to High(FDownloadProxies) do
    if FDownloadProxies[I].Token = AToken then Exit(I);
end;

procedure TSiteContext.StopDownloadProxy(const AToken: string);
begin
  var I := FindDownloadSlot(AToken);
  if I < 0 then Exit;
  if FDownloadProxies[I].Running then
  begin
    try TerminateProcess(FDownloadProxies[I].Process.hProcess, 0); except end;
    try CloseHandle(FDownloadProxies[I].Process.hThread); except end;
    try CloseHandle(FDownloadProxies[I].Process.hProcess); except end;
    FDownloadProxies[I].Running := False;
    FDownloadProxies[I].Port := 0;
  end;
end;

procedure TSiteContext.StopAllDownloadProxies;
begin
  for var I := 0 to High(FDownloadProxies) do
    if FDownloadProxies[I].Running then
    begin
      try TerminateProcess(FDownloadProxies[I].Process.hProcess, 0); except end;
      try CloseHandle(FDownloadProxies[I].Process.hThread); except end;
      try CloseHandle(FDownloadProxies[I].Process.hProcess); except end;
      FDownloadProxies[I].Running := False;
      FDownloadProxies[I].Port := 0;
    end;
  SetLength(FDownloadProxies, 0);
end;

function TSiteContext.StartDownloadProxy(const AHelperFile, APlaylistFile, AM3U8Url, AToken: string): string;
var
  NODE_EXE : string;
  NodeExe, Cmd, ReadyFile, LogDir: string;
  SI: TStartupInfo;
  Port, SlotIdx: Integer;
begin
  Result := '';
  Log('StartDownloadProxy begin token=' + AToken);
  if not TFile.Exists(AHelperFile) then
  begin
    Log('StartDownloadProxy abort: helper missing ' + AHelperFile);
    Exit;
  end;

  NODE_EXE := ExtractFilePath(ParamStr(0)) + 'plugins\nodejs\node.exe';
  if TFile.Exists(NODE_EXE) then
    NodeExe := NODE_EXE
  else
    NodeExe := 'node.exe';

  // 每个任务独立 logDir/ready 文件：多任务互不干扰，绝不触碰播放代理的 proxy_used.txt
  LogDir := IncludeTrailingPathDelimiter(CurrentLogDir) + 'download' + PathDelim + AToken + PathDelim;
  ForceDirectories(LogDir);
  while (Length(LogDir) > 0) and (LogDir[Length(LogDir)] = PathDelim) do SetLength(LogDir, Length(LogDir) - 1);
  ReadyFile := TPath.Combine(LogDir, 'proxy_ready_dl.txt');
  if TFile.Exists(ReadyFile) then TFile.Delete(ReadyFile);

  Cmd := '"' + NodeExe + '" "' + AHelperFile + '" "' + APlaylistFile + '" "0" "' + AM3U8Url + '" "' + ReadyFile + '" "' + LogDir + '"';
  Log('StartDownloadProxy cmd=' + Cmd);

  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SlotIdx := FindDownloadSlot(AToken);
  if SlotIdx < 0 then
  begin
    SetLength(FDownloadProxies, Length(FDownloadProxies) + 1);
    SlotIdx := High(FDownloadProxies);
    FDownloadProxies[SlotIdx].Token := AToken;
    FDownloadProxies[SlotIdx].Running := False;
    FDownloadProxies[SlotIdx].Port := 0;
  end
  else if FDownloadProxies[SlotIdx].Running then
    StopDownloadProxy(AToken);

  if not CreateProcess(nil, PChar(Cmd), nil, nil, False, CREATE_NO_WINDOW, nil, nil, SI, FDownloadProxies[SlotIdx].Process) then
  begin
    Log('StartDownloadProxy CreateProcess FAILED err=' + IntToStr(GetLastError));
    Exit;
  end;
  
  FDownloadProxies[SlotIdx].Running := True;
  Log('StartDownloadProxy node started token=' + AToken + ' pid=' + IntToStr(FDownloadProxies[SlotIdx].Process.dwProcessId));

  for var I := 1 to 150 do
  begin
    Sleep(100);
    if TFile.Exists(ReadyFile) then
    begin
      Port := StrToIntDef(Trim(TFile.ReadAllText(ReadyFile)), 0);
      if Port > 0 then
      begin
        FDownloadProxies[SlotIdx].Port := Port;
        Result := 'http://127.0.0.1:' + IntToStr(Port) + '/index.m3u8';
        Log('StartDownloadProxy READY at try ' + IntToStr(I) + ' port=' + IntToStr(Port));
        Exit;
      end;
      Break;
    end;
  end;
  Log('StartDownloadProxy READY TIMEOUT');
  StopDownloadProxy(AToken);
end;

function TSiteContext.StartLocalProxy(const AHelperFile, APlaylistFile, AM3U8Url: string): Boolean;
var
  NODE_EXE                       : string;
  NodeExe, Cmd, ReadyFile, LogDir: string;
  SI                             : TStartupInfo;
begin
  Result := False;
  Log('StartLocalProxy begin');
  if not TFile.Exists(AHelperFile) then
  begin
    Log('StartLocalProxy abort: helper missing ' + AHelperFile);
    Exit;
  end;
  
  NODE_EXE := ExtractFilePath(ParamStr(0)) + 'plugins\nodejs\node.exe';
  if TFile.Exists(NODE_EXE) then
    NodeExe := NODE_EXE
  else
    NodeExe := 'node.exe';

  StopProxy;
  LogDir := CurrentLogDir;
  ForceDirectories(LogDir);
  // 传给 Node 的命令行参数不能以反斜杠结尾，否则末尾反斜杠+引号会被当成转义引号，
  // 导致脚本收到的 LOG_DIR 路径出错，proxy.log / proxy_used.txt 写不进日志目录。
  while (Length(LogDir) > 0) and (LogDir[Length(LogDir)] = '\') do SetLength(LogDir, Length(LogDir) - 1);
  ReadyFile := TPath.Combine(LogDir, 'proxy_ready_' + IntToStr(GetCurrentProcessId) + '.txt');
  if TFile.Exists(ReadyFile) then TFile.Delete(ReadyFile);

  // 端口传 0：由 Node 代理自动选空闲端口，避开残留旧进程占用固定端口
  // 第 6 个参数为日志目录，代理脚本把 proxy.log 写入该目录
  Cmd := '"' + NodeExe + '" "' + AHelperFile + '" "' + APlaylistFile + '" "0" "' + AM3U8Url + '" "' + ReadyFile + '" "' + LogDir + '"';
  Log('StartLocalProxy cmd=' + Cmd);

  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  if not CreateProcess(nil, PChar(Cmd), nil, nil, False, CREATE_NO_WINDOW, nil, nil, SI, FProxyProcess) then
  begin
    Log('StartLocalProxy CreateProcess FAILED err=' + IntToStr(GetLastError));
    Exit;
  end;
  
  FProxyRunning := True;
  Log('StartLocalProxy node started pid=' + IntToStr(FProxyProcess.dwProcessId));

  for var I := 1 to 150 do
  begin
    Sleep(100);
    if TFile.Exists(ReadyFile) then
    begin
      FProxyPort := StrToIntDef(Trim(TFile.ReadAllText(ReadyFile)), 0);
      if FProxyPort > 0 then
      begin
        Log('StartLocalProxy READY at try ' + IntToStr(I) + ' port=' + IntToStr(FProxyPort));
        Exit(True);
      end;
      Break;
    end;
  end;
  Log('StartLocalProxy READY TIMEOUT');
end;

procedure TSiteContext.PlayInVlc(const ACmdTail: string);
var
  Cmd, VlcLog, LogDir: string;
  SI                 : TStartupInfo;
  PI                 : TProcessInformation;
begin
  if not TFile.Exists(CheckVlcExePath) then raise Exception.Create('未找到 VLC: ' + CheckVlcExePath);

  LogDir := CurrentLogDir;
  ForceDirectories(LogDir);
  VlcLog := TPath.Combine(LogDir, 'vlc.log');
  if TFile.Exists(VlcLog) then
    try
      TFile.Delete(VlcLog);
    except
    end;

  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  Cmd := '"' + CheckVlcExePath + '" ' + ACmdTail + ' --no-one-instance --no-video-title-show --verbose=2 --file-logging --logfile="' + VlcLog + '"';
  Log('PlayInVlc cmd=' + Cmd);
  if not CreateProcess(nil, PChar(Cmd), nil, nil, False, 0, nil, nil, SI, PI) then
  begin
    Log('PlayInVlc CreateProcess FAILED err=' + IntToStr(GetLastError));
    raise Exception.Create('无法启动外部 VLC 播放器');
  end;
  
  Log('PlayInVlc started pid=' + IntToStr(PI.dwProcessId));
  CloseHandle(PI.hThread);
  CloseHandle(PI.hProcess);
end;

{ TSiteBase }

constructor TSiteBase.Create(ACtx: TSiteContext);
begin
  inherited Create;
  FCtx := ACtx;
end;

destructor TSiteBase.Destroy;
begin
  Cleanup;
  inherited;
end;

class function TSiteBase.Id: string;
begin
  Result := '';
end;

class function TSiteBase.DefaultKeyword: string;
begin
  Result := '';
end;

class function TSiteBase.SiteExeDir(const AExeDir: string): string;
begin
  Result := IncludeTrailingPathDelimiter(AExeDir) + 'plugins\sites' + PathDelim + Id + PathDelim;
end;

function TSiteBase.SiteId: string;
begin
  Result := Id;
end;

procedure TSiteBase.BindSiteId;
begin
  if FCtx <> nil then FCtx.CurrentSiteId := Id;
end;

procedure TSiteBase.Cleanup;
begin
end;

function TSiteBase.BuildDownloadCommand(const AEpisode: TEpisode; const AToken: string): string;
begin
  Result := '';
end;

end.
