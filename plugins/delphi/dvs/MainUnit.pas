unit MainUnit;

// ============================================================
// 主程序：仅负责界面调度，不写任何站点专属解析逻辑。
//   站点解析见 Sites\<id>\SiteXxx.pas；公共服务见 SiteIntf.pas；
//   站点注册见 Sites\SiteRegistry.pas。
// ============================================================

interface

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils, System.Classes, System.Variants, System.IOUtils, System.NetEncoding,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Clipbrd, Vcl.Buttons, System.Generics.Collections, SiteIntf;

type
  // 单个下载任务：一个独立 ffmpeg 进程 + 一个独立下载代理（按 Token 对应）
  TDownloadTask = class
    Token: string;          // 唯一标识，用于对应下载代理槽位
    FfProcess: TProcessInformation;
    ProcRunning: Boolean;
    OutFile: string;
    DisplayName: string;    // 剧名_集号
    FfLogFile: string;
  end;

  TfrmVideoSearch = class(TForm)
    pnlTop: TPanel;
    cbbSite: TComboBox;
    cbbVideos: TComboBox;
    edtKeyword: TEdit;
    btnSearch: TButton;
    lblUser: TLabel;
    edtUsername: TEdit;
    lblPass: TLabel;
    edtPassword: TEdit;
    lblStatus: TLabel;
    lvEpisodes: TListView;
    pnlHint: TPanel;
    lblHint: TLabel;
    imgProxy: TImage;
    lblProxyText: TLabel;
    btnDownload: TSpeedButton;
    tmrProxy: TTimer;
    tmrDownload: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure cbbVideosChange(Sender: TObject);
    procedure cbbSiteChange(Sender: TObject);
    procedure edtKeywordKeyPress(Sender: TObject; var Key: Char);
    procedure lvEpisodesDblClick(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure tmrProxyTimer(Sender: TObject);
    procedure tmrDownloadTimer(Sender: TObject);
  private
    FCtx: TSiteContext;
    FSite: TSiteBase;
    FVideoSlugs: TSlugArray;
    FEpisodes: TEpisodeArray;
    FInitializing: Boolean;
    FLastPlayUsedProxy: Boolean;
    FTasks: TList<TDownloadTask>;
    FTaskSeq: Integer;
//    function ExtractLocalUrl(const ACmd: string): string;
    function SafeFileName(const S: string): string;
    procedure UpdateProxyIndicator;
    procedure SetProxyImage(AColor: TColor);
    procedure TerminateAllTasks;
    procedure RefreshTaskStatus;
    procedure FillSiteCombo;
    procedure ActivateSite(AIndex: Integer);
    procedure AdjustEpisodeColumns;
  public
  end;

var
  frmVideoSearch: TfrmVideoSearch;

implementation

{$R *.dfm}

uses
  SiteManager, SiteRegistry;   // SiteRegistry 触发各站点注册

const
  CLR_PROXY_ON    = $003535DC; // 红：视频数据走本地代理
  CLR_PROXY_OFF   = $00D77800; // 蓝：未走代理（默认）
  PROXY_USED_FILE = 'proxy_used.txt';

procedure TfrmVideoSearch.FillSiteCombo;
var
  I: Integer;
  C: TSiteClass;
begin
  cbbSite.Items.Clear;
  for I := 0 to GSiteManager.Count - 1 do
  begin
    C := GSiteManager.SiteClass(I);
    if C <> nil then cbbSite.Items.Add(C.DisplayName);
  end;
end;

procedure TfrmVideoSearch.ActivateSite(AIndex: Integer);
begin
  FLastPlayUsedProxy := False;
  tmrProxy.Enabled   := False;
  UpdateProxyIndicator;
  FreeAndNil(FSite);
  SetLength(FVideoSlugs, 0);
  SetLength(FEpisodes, 0);
  cbbVideos.Items.Clear;
  lvEpisodes.Clear;

  FSite := GSiteManager.CreateSite(AIndex, FCtx);
  if FSite = nil then
  begin
    lblStatus.Caption := '站点初始化失败';
    Exit;
  end;

  // 日志按站点分目录：log/日期/站点ID
  FCtx.CurrentSiteId := FSite.SiteId;

  edtKeyword.Text := FSite.DefaultKeyword;
  ActiveControl   := edtKeyword;
  edtKeyword.SelectAll;
  if TFile.Exists(CheckVlcExePath) then
    lblStatus.Caption := '请输入片名后点击搜索'
  else
    lblStatus.Caption := '未找到 VLC: ' + CheckVlcExePath;
  FCtx.Log('ActivateSite -> ' + FSite.Id);
end;

procedure TfrmVideoSearch.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  FSite              := nil;
  FLastPlayUsedProxy := False;
  FTasks             := TList<TDownloadTask>.Create;
  FTaskSeq           := 0;
  FCtx               := TSiteContext.Create(ExtractFilePath(ParamStr(0)));
  FCtx.Log('=== FormCreate ===');

  FInitializing := True;
  try
    FillSiteCombo;
    if cbbSite.Items.Count > 0 then
    begin
      // 默认选中"爱电影"，若该站点不存在则回退到第一项
      I := cbbSite.Items.IndexOf('爱电影');
      if I < 0 then I := 0;
      cbbSite.ItemIndex := I;
    end;
  finally
    FInitializing := False;
  end;

  if cbbSite.ItemIndex >= 0 then
    ActivateSite(cbbSite.ItemIndex)
  else
    lblStatus.Caption := '没有可用站点';
  UpdateProxyIndicator;
  AdjustEpisodeColumns;
end;

// 地址列占满列表剩余宽度：前三列固定，地址列随窗体大小变化，
// 预留 24px 给垂直滚动条与边框，避免内容撑出水平滚动条。
procedure TfrmVideoSearch.AdjustEpisodeColumns;
var
  FixedW, AddrW: Integer;
begin
  if lvEpisodes.Columns.Count < 4 then Exit;
  FixedW := lvEpisodes.Columns[0].Width + lvEpisodes.Columns[1].Width + lvEpisodes.Columns[2].Width;
  AddrW := lvEpisodes.ClientWidth - FixedW - 24;
  if AddrW < 120 then AddrW := 120;
  lvEpisodes.Columns[3].Width := AddrW;
end;

procedure TfrmVideoSearch.FormResize(Sender: TObject);
begin
  AdjustEpisodeColumns;
end;

procedure TfrmVideoSearch.FormDestroy(Sender: TObject);
begin
  // 关闭程序：终止所有 ffmpeg 本体（直接句柄，可靠释放 mp4 占用），
  // 随后 FCtx 析构会 StopAllDownloadProxies + StopProxy 清掉所有 node 代理。
  TerminateAllTasks;
  FreeAndNil(FTasks);
  FreeAndNil(FSite);
  FreeAndNil(FCtx);
end;

procedure TfrmVideoSearch.cbbSiteChange(Sender: TObject);
begin
  if FInitializing then Exit;
  if (cbbSite.ItemIndex < 0) or (FSite = nil) then Exit;

  ActivateSite(cbbSite.ItemIndex);
end;

procedure TfrmVideoSearch.btnSearchClick(Sender: TObject);
var
  Key: string;
  OK : Boolean;
begin
  if FSite = nil then Exit;

  Key := Trim(edtKeyword.Text);
  if Key = '' then
  begin
    lblStatus.Caption := '请输入片名';
    Exit;
  end;

  lblStatus.Caption := '正在搜索...';
  Screen.Cursor := crHourGlass;
  // 换词搜索前清空上一次的结果，避免下拉框与剧集列表残留旧内容
  cbbVideos.Items.Clear;
  SetLength(FVideoSlugs, 0);
  SetLength(FEpisodes, 0);
  lvEpisodes.Clear;
  try
    OK := FSite.Search(Key, cbbVideos.Items, FVideoSlugs);
    if OK and (cbbVideos.Items.Count > 0) then
    begin
      cbbVideos.ItemIndex := 0;
      cbbVideosChange(Self);
    end
    else
      lblStatus.Caption := '未找到相关影片';
  except
    on E: Exception do
      lblStatus.Caption := '搜索失败: ' + E.Message;
  end;
  Screen.Cursor := crDefault;
end;

procedure TfrmVideoSearch.cbbVideosChange(Sender: TObject);
var
  Idx, I: Integer;
begin
  if FSite = nil then Exit;

  FLastPlayUsedProxy := False;
  tmrProxy.Enabled := False;
  UpdateProxyIndicator;
  Idx := cbbVideos.ItemIndex;
  if (Idx < 0) or (Idx >= Length(FVideoSlugs)) then Exit;
  Screen.Cursor := crHourGlass;
  try
    if FSite.LoadDetail(FVideoSlugs[Idx], FEpisodes) then
    begin
      lvEpisodes.Clear;
      // 按集数倒序填充
      for I := 0 to High(FEpisodes) do
        with lvEpisodes.Items.Add do
        begin
          Caption := '第' + FEpisodes[I].Num + '集';
          SubItems.Add(FEpisodes[I].LineNo);
          SubItems.Add(FEpisodes[I].DataId);
          SubItems.Add(FEpisodes[I].PageUrl);
        end;
      lblStatus.Caption := Format('共 %d 集', [Length(FEpisodes)]);
    end
    else
      lblStatus.Caption := '读取详情失败';
  except
    on E: Exception do
      lblStatus.Caption := '读取详情失败: ' + E.Message;
  end;
  Screen.Cursor := crDefault;
end;

procedure TfrmVideoSearch.edtKeywordKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    btnSearchClick(Self);
  end;
end;

procedure TfrmVideoSearch.lvEpisodesDblClick(Sender: TObject);
var
  Idx: Integer;
  Cmd: string;
begin
  if FSite = nil then Exit;
  Idx := lvEpisodes.ItemIndex;
  if (Idx < 0) or (Idx >= Length(FEpisodes)) then Exit;

  lblStatus.Caption := '正在解析播放地址...';
  Screen.Cursor := crHourGlass;
  try
    FCtx.Log('DblClick episode=' + FEpisodes[Idx].Num + ' dataid=' + FEpisodes[Idx].DataId);
    Cmd := FSite.BuildPlayCommand(FEpisodes[Idx]);
    if FSite.ResolvedUrl <> '' then lvEpisodes.Items[Idx].SubItems[2] := FSite.ResolvedUrl;
    FCtx.PlayInVlc(Cmd);
    // 指示灯改为反映本次播放是否真正走了系统代理：
    // 代理脚本在走系统代理时写标记文件，定时器轮询它。
    FLastPlayUsedProxy := False;
    tmrProxy.Enabled := True;
    UpdateProxyIndicator;
    lblStatus.Caption := '已用 VLC 播放第' + FEpisodes[Idx].Num + '集';
  except
    on E: Exception do
    begin
      FCtx.Log('PLAY ERROR: ' + E.Message);
      tmrProxy.Enabled := False;
      FLastPlayUsedProxy := False;
      UpdateProxyIndicator;
      lblStatus.Caption := '播放失败: ' + E.Message;
    end;
  end;
  Screen.Cursor := crDefault;
end;

procedure TfrmVideoSearch.SetProxyImage(AColor: TColor);
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Width := imgProxy.Width;
    Bmp.Height := imgProxy.Height;
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.FillRect(Rect(0, 0, Bmp.Width, Bmp.Height));
    Bmp.Canvas.Brush.Color := AColor;
    Bmp.Canvas.Pen.Color := AColor;
    Bmp.Canvas.Ellipse(Rect(0, 0, Bmp.Width, Bmp.Height));
    Bmp.Transparent := True;
    Bmp.TransparentColor := clWhite;
    imgProxy.Picture.Assign(Bmp);
  finally
    Bmp.Free;
  end;
end;

procedure TfrmVideoSearch.UpdateProxyIndicator;
begin
  if FLastPlayUsedProxy then
  begin
    SetProxyImage(CLR_PROXY_ON);
    imgProxy.Hint := '当前视频数据走本地代理（红色）';
  end
  else
  begin
    SetProxyImage(CLR_PROXY_OFF);
    imgProxy.Hint := '当前视频数据未走代理（蓝色）';
  end;
  imgProxy.ShowHint := True;
end;

procedure TfrmVideoSearch.tmrProxyTimer(Sender: TObject);
var
  FlagFile: string;
  UsedProxy: Boolean;
begin
  if FCtx = nil then Exit;
  FlagFile := TPath.Combine(FCtx.CurrentLogDir, PROXY_USED_FILE);
  UsedProxy := TFile.Exists(FlagFile);
  if UsedProxy <> FLastPlayUsedProxy then
  begin
    FLastPlayUsedProxy := UsedProxy;
    UpdateProxyIndicator;
    if UsedProxy then
      FCtx.Log('Proxy indicator: system proxy USED (red)')
    else
      FCtx.Log('Proxy indicator: all direct (blue)');
  end;
end;

//function TfrmVideoSearch.ExtractLocalUrl(const ACmd: string): string;
//var
//  P1, P2: Integer;
//begin
//  Result := '';
//  P1 := Pos('http://127.0.0.1:', ACmd);
//  if P1 < 1 then Exit;
//  P2 := P1;
//  while (P2 <= Length(ACmd)) and (ACmd[P2] <> '"') and (ACmd[P2] <> ' ') do Inc(P2);
//  Result := Copy(ACmd, P1, P2 - P1);
//end;

function TfrmVideoSearch.SafeFileName(const S: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if CharInSet(C, ['\', '/', ':', '*', '?', '"', '<', '>', '|']) then C := '_';
    Result := Result + C;
  end;
end;

procedure TfrmVideoSearch.btnDownloadClick(Sender: TObject);
var
  FFMPEG_EXE : string;
  Idx: Integer;
  LocalUrl, OutDir, OutFile, FFcmd, FfLog, Token, BaseName: string;
  SI: TStartupInfo;
  FfLogHandle, NullHandle: THandle;
  Task: TDownloadTask;
  FfProcessTmp: TProcessInformation;
begin
  if FSite = nil then
  begin
    lblStatus.Caption := '请先选择站点';
    Exit;
  end;

  Idx := lvEpisodes.ItemIndex;
  if (Idx < 0) or (Idx >= Length(FEpisodes)) then
  begin
    lblStatus.Caption := '请先选中要下载的一集';
    Exit;
  end;

  FFMPEG_EXE := ExtractFilePath(ParamStr(0)) + 'plugins\ffmpeg\ffmpeg.exe';
  if not TFile.Exists(FFMPEG_EXE) then
  begin
    lblStatus.Caption := '未找到 ffmpeg: ' + FFMPEG_EXE;
    Exit;
  end;

  lblStatus.Caption := '正在准备下载地址...';
  Screen.Cursor := crHourGlass;

  try
    // 每个任务一个独立下载代理（Token 唯一），不会停止 VLC 播放代理，也不影响其它下载
    Inc(FTaskSeq);
    Token := IntToStr(GetTickCount) + '_' + IntToStr(FTaskSeq);
    LocalUrl := FSite.BuildDownloadCommand(FEpisodes[Idx], Token);
    if LocalUrl = '' then raise Exception.Create('未能取得本地下载地址');

    OutDir := IncludeTrailingPathDelimiter(FCtx.ExeDir) + 'downloads';
    ForceDirectories(OutDir);
    BaseName := SafeFileName(cbbVideos.Text + '_' + FEpisodes[Idx].Num);
    if BaseName = '' then BaseName := 'video';
    // 输出文件带序号避免多任务/重复下载同名时互相覆盖
    OutFile := TPath.Combine(OutDir, BaseName + '_' + IntToStr(FTaskSeq) + '.mp4');
    FfLog := TPath.Combine(FCtx.CurrentLogDir, 'download', Token, 'ffmpeg.log');
    ForceDirectories(ExtractFilePath(FfLog));

    // -multiple_requests 0 禁用 keepalive 复用，避免 node 同步阻塞时连接被重置；
    // -rw_timeout 提高单分片读超时容错（微秒），网络抖动时等待更久而非跳过分片。
    FFcmd := '"' + FFMPEG_EXE + '" -y -nostdin -loglevel warning ' +
             '-multiple_requests 0 -rw_timeout 60000000 ' +
             '-i "' + LocalUrl + '" -c copy -bsf:a aac_adtstoasc -movflags +faststart ' +
             '"' + OutFile + '"';

    // 直接 CreateProcess 启动 ffmpeg（不经 cmd 外壳），句柄即 ffmpeg 本体，关闭程序可精确终止。
    FfLogHandle := CreateFile(PChar(FfLog), GENERIC_WRITE, FILE_SHARE_READ, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if FfLogHandle = INVALID_HANDLE_VALUE then raise Exception.Create('无法创建下载日志: ' + IntToStr(GetLastError));
    NullHandle := CreateFile('NUL', GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
    try
      FillChar(SI, SizeOf(SI), 0);
      SI.cb := SizeOf(SI);
      SI.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
      SI.wShowWindow := SW_HIDE;
      SI.hStdInput := NullHandle;
      SI.hStdOutput := FfLogHandle;
      SI.hStdError := FfLogHandle;
      if not CreateProcess(nil, PChar(FFcmd), nil, nil, True, CREATE_NO_WINDOW, nil, nil, SI, FfProcessTmp) then raise Exception.Create('无法启动 ffmpeg: ' + IntToStr(GetLastError));
    finally
      CloseHandle(FfLogHandle);
      if NullHandle <> INVALID_HANDLE_VALUE then CloseHandle(NullHandle);
    end;

    Task := TDownloadTask.Create;
    Task.Token := Token;
    Task.FfProcess := FfProcessTmp;
    Task.ProcRunning := True;
    Task.OutFile := OutFile;
    Task.DisplayName := BaseName + '_' + IntToStr(FTaskSeq);
    Task.FfLogFile := FfLog;
    FTasks.Add(Task);
    tmrDownload.Enabled := True;
    FCtx.Log('DOWNLOAD START token=' + Token + ' url=' + LocalUrl + ' out=' + OutFile);
    RefreshTaskStatus;
  except
    on E: Exception do
    begin
      // 启动失败：释放本任务可能已创建的代理；回滚已失败的 FTaskSeq 由下次覆盖
      FCtx.StopDownloadProxy(Token);
      FCtx.Log('DOWNLOAD ERROR: ' + E.Message);
      lblStatus.Caption := '下载失败: ' + E.Message;
    end;
  end;
  Screen.Cursor := crDefault;
end;

procedure TfrmVideoSearch.TerminateAllTasks;
begin
  for var I := 0 to FTasks.Count - 1 do
  begin
    if FTasks[I].ProcRunning then
    begin
      try TerminateProcess(FTasks[I].FfProcess.hProcess, 0); except end;
      try CloseHandle(FTasks[I].FfProcess.hThread); except end;
      try CloseHandle(FTasks[I].FfProcess.hProcess); except end;
      FTasks[I].ProcRunning := False;
    end;
  end;
  // 所有下载代理（node）由 TSiteContext 析构时统一 StopAllDownloadProxies
end;

procedure TfrmVideoSearch.RefreshTaskStatus;
var
  Running  : Integer;
  Text     : string;
  SizeBytes: Int64;
begin
  Running := 0;
  Text := '';
  for var I := 0 to FTasks.Count - 1 do
    if FTasks[I].ProcRunning then
    begin
      Inc(Running);
      SizeBytes := 0;
      if TFile.Exists(FTasks[I].OutFile) then SizeBytes := TFile.GetSize(FTasks[I].OutFile);
      if Text <> '' then Text := Text + '  |  ';
      Text := Text + ExtractFileName(FTasks[I].OutFile) + ' ' + FormatFloat('0.0', SizeBytes / 1024 / 1024) + 'MB';
    end;
  if Running > 0 then
    lblStatus.Caption := Format('下载中(%d): %s', [Running, Text])
  else if FTasks.Count = 0 then
    lblStatus.Caption := '就绪';
end;

procedure TfrmVideoSearch.tmrDownloadTimer(Sender: TObject);
var
  I        : Integer;
  Code     : DWORD;
  SizeBytes: Int64;
  T        : TDownloadTask;
begin
  if FTasks = nil then Exit;
  if FTasks.Count = 0 then
  begin
    tmrDownload.Enabled := False;
    Exit;
  end;

  I := 0;
  while I < FTasks.Count do
  begin
    T := FTasks[I];
    if not T.ProcRunning then
    begin
      Inc(I);
      Continue;
    end;

    if WaitForSingleObject(T.FfProcess.hProcess, 0) <> WAIT_OBJECT_0 then
    begin
      Inc(I);
      Continue;
    end;

    // 该任务结束：取真实退出码，关句柄，停它自己那一个下载代理（不碰其它任务/播放代理）
    GetExitCodeProcess(T.FfProcess.hProcess, Code);
    try CloseHandle(T.FfProcess.hThread); except end;
    try CloseHandle(T.FfProcess.hProcess); except end;
    T.ProcRunning := False;
    FCtx.StopDownloadProxy(T.Token);

    if (Code = 0) and TFile.Exists(T.OutFile) then
    begin
      SizeBytes := TFile.GetSize(T.OutFile);
      FCtx.Log('DOWNLOAD DONE token=' + T.Token + ' size=' + IntToStr(SizeBytes) + ' out=' + T.OutFile);
    end
    else
      FCtx.Log('DOWNLOAD FAILED token=' + T.Token + ' exitcode=' + IntToStr(Code) + ' log=' + T.FfLogFile);

    T.Free;
    FTasks.Delete(I);
    // 不 Inc(I)：下一个任务移到当前索引
  end;

  RefreshTaskStatus;
  if FTasks.Count = 0 then tmrDownload.Enabled := False;
end;

end.
