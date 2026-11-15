unit DSCommon;

interface

uses Winapi.Windows, Winapi.ActiveX, Winapi.DirectShow9, System.SysUtils, System.Classes;

// ---- 滤镜 CLSID ----
const
  CLSID_FilterGraph           : TGUID = '{E436EBB3-524F-11CE-9F53-0020AF0BA770}';
  CLSID_VideoMixingRenderer9  : TGUID = '{51B4ABF3-748F-4E3B-A276-C828330E926A}';
  CLSID_MemoryAllocator       : TGUID = '{1E651CC0-B199-11D0-8212-00C04FC32C45}';
  CLSID_SystemDeviceEnum      : TGUID = '{62BE5D10-60EB-11D0-BD3B-00A0C911CE86}';
  CLSID_LegacyAmFilterCategory: TGUID = '{083863F1-70DE-11D0-BD40-00A0C911CE86}';

// ---- LAV Filters CLSID ----
const
  CLSID_LAVSplitterSource: TGUID = '{B98D13E7-55DB-4385-A33D-09FD1BA26338}';
  CLSID_LAVVideoDecoder  : TGUID = '{EE30215D-164F-4A92-A4EB-9D4C13390F9F}';
  CLSID_LAVAudioDecoder  : TGUID = '{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}';

// ---- 媒体类型 GUID ----
const
  MEDIATYPE_Video   : TGUID = '{73646976-0000-0010-8000-00AA00389B71}';
  MEDIATYPE_Audio   : TGUID = '{73647561-0000-0010-8000-00AA00389B71}';
  MEDIATYPE_Text    : TGUID = '{73747874-0000-0010-8000-00AA00389B71}';
  MEDIATYPE_Stream  : TGUID = '{E436EB83-524F-11CE-9F53-0020AF0BA770}';
  MEDIATYPE_Subtitle: TGUID = '{E487EB08-6B26-4BE9-9DD3-993434D313FD}';
  MEDIASUBTYPE_None : TGUID = '{E436EB8E-524F-11CE-9F53-0020AF0BA770}';
  MEDIASUBTYPE_UTF8 : TGUID = '{87C0B230-03A8-4FDF-8010-B27A5848200D}';
  MEDIASUBTYPE_SSA  : TGUID = '{3020560F-255A-4DDC-806E-6C5CC6DCD70A}';
  MEDIASUBTYPE_ASS  : TGUID = '{326444F7-686F-47FF-A4B2-C8C96307B4C2}';

// ---- IAMStreamSelect Enable 标志 ----
const
  AMSTREAMSELECTENABLE_ENABLE    = $00000001;
  AMSTREAMSELECTENABLE_ENABLEALL = $00000002;

// ---- VMR9 模式 ----
const
  VMR9Mode_Windowed    = $00000001;
  VMR9Mode_Windowless  = $00000002;
  VMR9Mode_Renderless  = $00000004;

  VMR9ARMode_Box    = 0;
  VMR9ARMode_NonBox = 1;

const
  // EVR / Media Foundation 声明
  CLSID_EnhancedVideoRenderer: TGUID = '{FA10746C-9B63-4B6C-BC49-FC300EA5F256}';
  IID_IMFGetService          : TGUID = '{FA993888-4383-415A-A930-DD472A8CF6F7}';
  MR_VIDEO_RENDER_SERVICE    : TGUID = '{1092A86C-AB1A-459A-A336-831FBC4D11FF}';
  IID_IMFVideoDisplayControl : TGUID = '{A490B1E4-AB84-4D31-A1B2-181E03B1077A}';

  CLSID_MMDeviceEnumerator: TGUID = '{BCDE0395-E52F-467C-8E3D-C4579291692E}';
  IID_IMMDeviceEnumerator : TGUID = '{A95664D2-9614-4F35-A746-DE8DB63617E6}';
  IID_IAudioEndpointVolume: TGUID = '{5CDF2C82-841E-4546-9722-0CF74078229A}';


  MFVideoARMode_None = 0;

type
  // IMFGetService（mfobjects.h）：滤镜/pin 的服务查询入口
  IMFGetService = interface(IUnknown)
    ['{FA993888-4383-415A-A930-DD472A8CF6F7}']
    function GetService(const guidService, riid: TGUID; out ppvObject): HRESULT; stdcall;
  end;

  // MFVideoNormalizedRect：归一化源矩形
  PMFVideoNormalizedRect = ^TMFVideoNormalizedRect;
  TMFVideoNormalizedRect = record
    left, top, right, bottom: Single;
  end;

  // IMFVideoDisplayControl：EVR 的窗口/位置控制
  IMFVideoDisplayControl = interface(IUnknown)
    ['{A490B1E4-AB84-4D31-A1B2-181E03B1077A}']
    function GetNativeVideoSize(var pszVideo, pszARVideo: TSize): HRESULT; stdcall;
    function GetIdealVideoSize(var pszMin, pszMax: TSize): HRESULT; stdcall;
    function SetVideoPosition(const pnrcSource: PMFVideoNormalizedRect; prcDest: PRect): HRESULT; stdcall;
    function GetVideoPosition(pnrcSource: PMFVideoNormalizedRect; prcDest: PRect): HRESULT; stdcall;
    function SetAspectRatioMode(dwAspectRatioMode: DWORD): HRESULT; stdcall;
    function GetAspectRatioMode(var dwAspectRatioMode: DWORD): HRESULT; stdcall;
    function SetVideoWindow(hwndVideo: HWND): HRESULT; stdcall;
    function GetVideoWindow(var phwndVideo: HWND): HRESULT; stdcall;
    function RepaintVideo: HRESULT; stdcall;
  end;

  // Windows 系统主音量（Core Audio / MMDevice）
  IMMDevice = interface(IUnknown)
    ['{D666063F-1587-4E43-81F1-B948E807363F}']
    function Activate(const iid: TGUID; dwClsCtx: DWORD; pActivationParams: Pointer; out ppInterface): HResult; stdcall;
    function OpenPropertyStore(stgmAccess: DWORD; out ppProperties: Pointer): HResult; stdcall;
    function GetId(out ppstrId: PWideChar): HResult; stdcall;
    function GetState(out pdwState: DWORD): HResult; stdcall;
  end;

  IMMDeviceEnumerator = interface(IUnknown)
    ['{A95664D2-9614-4F35-A746-DE8DB63617E6}']
    function EnumAudioEndpoints(dataFlow, dwStateMask: DWORD; out ppDevices: Pointer): HResult; stdcall;
    function GetDefaultAudioEndpoint(dataFlow, role: DWORD; out ppEndpoint: IMMDevice): HResult; stdcall;
    function GetDevice(pszID: PWideChar; out ppDevice: IMMDevice): HResult; stdcall;
    function RegisterEndpointNotificationCallback(pClient: Pointer): HResult; stdcall;
    function UnregisterEndpointNotificationCallback(pClient: Pointer): HResult; stdcall;
  end;

  IAudioEndpointVolume = interface(IUnknown)
    ['{5CDF2C82-841E-4546-9722-0CF74078229A}']
    function RegisterControlChangeNotify(pNotify: Pointer): HResult; stdcall;
    function UnregisterControlChangeNotify(pNotify: Pointer): HResult; stdcall;
    function GetVolumeRange(out pMin, pMax, pInc: Single): HResult; stdcall;
    function SetMasterVolumeLevel(fLevel: Single; pgEventCtx: PGUID): HResult; stdcall;
    function SetMasterVolumeLevelScalar(fLevel: Single; pgEventCtx: PGUID): HResult; stdcall;
    function GetMasterVolumeLevel(out fLevel: Single): HResult; stdcall;
    function GetMasterVolumeLevelScalar(out fLevel: Single): HResult; stdcall;
    function SetChannelVolumeLevel(dwChan: DWORD; fLevel: Single; pgEventCtx: PGUID): HResult; stdcall;
    function SetChannelVolumeLevelScalar(dwChan: DWORD; fLevel: Single; pgEventCtx: PGUID): HResult; stdcall;
    function GetChannelVolumeLevel(dwChan: DWORD; out fLevel: Single): HResult; stdcall;
    function GetChannelVolumeLevelScalar(dwChan: DWORD; out fLevel: Single): HResult; stdcall;
    function SetMute(fMute: LongBool; pgEventCtx: PGUID): HResult; stdcall;
    function GetMute(out fMute: LongBool): HResult; stdcall;
    function GetVolumeStepInfo(out pStep, pStepCount: DWORD): HResult; stdcall;
    function VolumeStepUp(pgEventCtx: PGUID): HResult; stdcall;
    function VolumeStepDown(pgEventCtx: PGUID): HResult; stdcall;
    function QueryHardwareSupport(out pdwSupport: DWORD): HResult; stdcall;
    function GetVolumeMeter(out pfMeter: Pointer): HResult; stdcall;
  end;

type
  PMediaTypeRec = PAMMediaType;
  TMediaTypeRec = TAMMediaType;
  PMTRec        = PAMMediaType;

function IsEqualGuid(const A, B: TGUID): Boolean;
function MajorIs(const Pmt: PMediaTypeRec; const G: TGUID): Boolean;

// 分配/复制/释放 AM_MEDIA_TYPE（标准 DirectShow 内存模型）
function AllocMediaType(const Size: Integer): PMediaTypeRec;
function CopyMediaType(const Src: PMediaTypeRec): PMediaTypeRec;
procedure FreeMediaType(const Pmt: PMediaTypeRec);
procedure DeleteMediaType(var Pmt: PMediaTypeRec);

// 枚举 pin / 查找
function PinCount(Filter: IBaseFilter; Direction: TPinDirection): Integer;
function GetPin(Filter: IBaseFilter; Direction: TPinDirection; Index: Integer; WantedMajor: PGUID = nil): IPin;
function FirstPin(Filter: IBaseFilter; Direction: TPinDirection; WantedMajor: PGUID = nil): IPin;
function GetPinMediaType(Pin: IPin; Direction: TPinDirection): PMediaTypeRec;

// 连接帮助：自动在 graph 中插接解码器（枚举 moniker 找滤镜）
function ConnectPins(Graph: IGraphBuilder; Out_: IPin; In_: IPin): HResult;
function RenderPin(Graph: IGraphBuilder; Pin: IPin): HResult;
function CreateInstanceFilter(const Clsid: TGUID): IBaseFilter;

// 通过系统设备枚举器按友好名查找滤镜（moniker 绑定）
function FindFilterByFriendlyName(const SubName: string): IBaseFilter;

// 免注册加载 LAV Filters（LoadLibraryEx + DllGetClassObject）
function LocateLavAx(const AxName: string): string;
function CreateLavFilter(const AxName: string; const Clsid: TGUID): IBaseFilter;

// 免注册属性页（LAV 配置对话框）
function RegisterLavClass(const AxName: string; const Clsid: TGUID; out Cookie: Longint): Boolean;
procedure RevokeLavClass(Cookie: Longint);

// 倍速播放
const
  RateTags  : array[ 0 .. 8 ] of Integer = (107, 108, 109, 110, 111, 112, 113, 114, 115);
  RateValues: array[ 0 .. 8 ] of Double  = (0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 2.00, 3.00, 4.00);

function RateTagIndex(ATag: Integer): Integer;

implementation

function RateTagIndex(ATag: Integer): Integer;
begin
  for var i := Low(RateTags) to High(RateTags) do if RateTags[i] = ATag then Exit(i);
  Result := 3;  // 默认 1.00x
end;

function IsEqualGuid(const A, B: TGUID): Boolean;
begin
  Result := A.D1 = B.D1;
  if not Result then Exit;
  Result := (A.D2 = B.D2) and (A.D3 = B.D3);
  if not Result then Exit;
  Result := CompareMem(@A.D4, @B.D4, SizeOf(A.D4));
end;

function MajorIs(const Pmt: PMediaTypeRec; const G: TGUID): Boolean;
begin
  Result := Assigned(Pmt) and IsEqualGuid(Pmt^.majortype, G);
end;

function AllocMediaType(const Size: Integer): PMediaTypeRec;
begin
  Result := CoTaskMemAlloc(Size);
  if Result = nil then Exit;
  
  FillChar(Result^, Size, 0);
  Result^.lSampleSize := 1;
  Result^.bFixedSizeSamples := True;
  Result^.formattype := GUID_NULL;
end;

function CopyMediaType(const Src: PMediaTypeRec): PMediaTypeRec;
begin
  if Src = nil then
  begin
    Result := nil;
    Exit;
  end;

  Result := AllocMediaType(SizeOf(TMediaTypeRec) + Src^.cbFormat);
  Result^ := Src^;
  if Src^.cbFormat > 0 then
  begin
    Result^.pbFormat := CoTaskMemAlloc(Src^.cbFormat);
    Move(Src^.pbFormat^, Result^.pbFormat^, Src^.cbFormat);
  end
  else
    Result^.pbFormat := nil;
end;

procedure FreeMediaType(const Pmt: PMediaTypeRec);
begin
  if Pmt = nil then Exit;
  if Pmt^.cbFormat > 0 then CoTaskMemFree(Pmt^.pbFormat);
  Pmt^.cbFormat := 0;
  Pmt^.pbFormat := nil;
  Pmt^.pUnk := nil;
end;

procedure DeleteMediaType(var Pmt: PMediaTypeRec);
begin
  if Pmt = nil then Exit;
  FreeMediaType(Pmt);
  CoTaskMemFree(Pmt); 
  Pmt := nil;
end;

function PinCount(Filter: IBaseFilter; Direction: TPinDirection): Integer;
var
  En: IEnumPins;
  Pin: IPin;
  Dir: TPinDirection;
  Fetched: Cardinal;
begin
  Result := 0;
  if not Assigned(Filter) then Exit;
  if Failed(Filter.EnumPins(En)) then Exit;
  try
    while En.Next(1, Pin, @Fetched) = S_OK do
    begin
      if Succeeded(Pin.QueryDirection(Dir)) and (Dir = Direction) then Inc(Result);
      Pin := nil;
    end;
  finally
    En := nil;
  end;
end;

function GetPin(Filter: IBaseFilter; Direction: TPinDirection; Index: Integer; WantedMajor: PGUID): IPin;
var
  En: IEnumPins;
  Pin: IPin;
  Dir: TPinDirection;
  Fetched: Cardinal;
  Seen: Integer;
  Pmt: PMediaTypeRec;
begin
  Result := nil;
  if not Assigned(Filter) then Exit;
  if Failed(Filter.EnumPins(En)) then Exit;
  try
    Seen := 0;
    while En.Next(1, Pin, @Fetched) = S_OK do
    begin
      try
        if Succeeded(Pin.QueryDirection(Dir)) and (Dir = Direction) then
        begin
          if WantedMajor <> nil then
          begin
            Pmt := GetPinMediaType(Pin, Direction);
            try
              if (Pmt <> nil) and IsEqualGuid(Pmt^.majortype, WantedMajor^) then
              begin
                if Seen = Index then
                begin
                  Result := Pin;
                  Break;
                end;
                Inc(Seen);
              end;
            finally
              DeleteMediaType(Pmt);
            end;
          end
          else
          begin
            if Seen = Index then
            begin
              Result := Pin;
              Break;
            end;
            Inc(Seen);
          end;
        end;
      finally
        Pin := nil;
      end;
    end;
  finally
    En := nil;
  end;
end;

function FirstPin(Filter: IBaseFilter; Direction: TPinDirection; WantedMajor: PGUID): IPin;
begin
  Result := GetPin(Filter, Direction, 0, WantedMajor);
end;

function GetPinMediaType(Pin: IPin; Direction: TPinDirection): PMediaTypeRec;
var
  En: IEnumMediaTypes;
  Mt: PMediaTypeRec;
  Fetched: Cardinal;
begin
  Result := nil;
  if not Assigned(Pin) then Exit;
  if Succeeded(Pin.EnumMediaTypes(En)) then
  begin
    try
      while En.Next(1, PAMMediaType(Mt), @Fetched) = S_OK do
      begin
        Result := Mt;
        Break;
      end;
    finally
      En := nil;
    end;
  end;
end;

function CreateInstanceFilter(const Clsid: TGUID): IBaseFilter;
begin
  Result := nil;
  CoCreateInstance(Clsid, nil, CLSCTX_INPROC_SERVER, IBaseFilter, Result);
end;

function ConnectPins(Graph: IGraphBuilder; Out_, In_: IPin): HResult;
begin
  Result := Graph.Connect(Out_, In_);
end;

function RenderPin(Graph: IGraphBuilder; Pin: IPin): HResult;
begin
  Result := Graph.Render(Pin);
end;

function FindFilterByFriendlyName(const SubName: string): IBaseFilter;
var
  DevEnum: ICreateDevEnum;
  En: IEnumMoniker;
  Mon: IMoniker;
  Fetched: Cardinal;
  Bag: IPropertyBag;
  VarName: OleVariant;
  Name: string;
  Unk: IUnknown;
  BF: IBaseFilter;
begin
  Result := nil;
  if Failed(CoCreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC_SERVER, ICreateDevEnum, DevEnum)) then Exit;
  if Failed(DevEnum.CreateClassEnumerator(CLSID_LegacyAmFilterCategory, En, 0)) then Exit;
  if not Assigned(En) then Exit;
  
  try
    while En.Next(1, Mon, @Fetched) = S_OK do
    begin
      try
        if Failed(Mon.BindToStorage(nil, nil, IPropertyBag, Bag)) then Continue;
        VarName := '';
        if Failed(Bag.Read('FriendlyName', VarName, nil)) then Continue;
        Name := string(VarName);
        if Pos(LowerCase(SubName), LowerCase(Name)) > 0 then
        begin
          Unk := nil;
          if Succeeded(Mon.BindToObject(nil, nil, IUnknown, Unk)) then
          begin
            if Unk.QueryInterface(IBaseFilter, BF) = S_OK then
            begin
              Result := BF;
              Exit;
            end;
          end;
        end;
      finally
        Bag := nil;
        Mon := nil;
      end;
    end;
  finally
    En := nil;
  end;
end;

{ 免注册加载 LAV Filters }
function SearchFileDir(const Base, AxName: string; Depth: Integer): string;
var
  F    : TSearchRec;
  R    : Integer;
  Found: string;
begin
  Result := '';
  if Depth <= 0 then Exit;
  Found := IncludeTrailingPathDelimiter(Base) + AxName;
  if FileExists(Found) then Exit(Found);

  R := FindFirst(IncludeTrailingPathDelimiter(Base) + '*', faDirectory, F);
  try
    while R = 0 do
    begin
      if (F.Attr and faDirectory <> 0) and (F.Name <> '.') and (F.Name <> '..') then
      begin
        Result := SearchFileDir(IncludeTrailingPathDelimiter(Base) + F.Name, AxName, Depth - 1);
        if Result <> '' then Exit;
      end;
      R := FindNext(F);
    end;
  finally
    FindClose(F);
  end;
end;

function LocateLavAx(const AxName: string): string;
var
  ExeDir : string;
begin
  Result := '';
  SetLength(ExeDir, MAX_PATH);
  SetLength(ExeDir, GetModuleFileName(HInstance, PChar(ExeDir), MAX_PATH));
  ExeDir  := ExtractFileDir(ExeDir);
  var Dir := ExeDir;
  for var i := 0 to 4 do
  begin
    Result := SearchFileDir(Dir, AxName, 3);
    if Result <> '' then Exit;
    Dir := ExtractFileDir(Dir);
    if (Dir = '') or (Length(Dir) < 3) then Break;
  end;
end;

function CreateLavFilter(const AxName: string; const Clsid: TGUID): IBaseFilter;
var
  GetClassObj: function(const clsid: TGUID; const iid: TGUID; out ppv): HResult; stdcall;
  CF         : IClassFactory;
begin
  Result := nil;
  var AxPath := LocateLavAx(AxName);
  if AxPath = '' then Exit;
  
  // LOAD_WITH_ALTERED_SEARCH_PATH：依赖 DLL（avcodec/avutil 等）从 .ax 所在目录解析
  var hLib := LoadLibraryEx(PChar(AxPath), 0, LOAD_WITH_ALTERED_SEARCH_PATH);
  if hLib = 0 then Exit;
  
  GetClassObj := GetProcAddress(hLib, 'DllGetClassObject');
  if not Assigned(GetClassObj) then Exit;
  if Failed(GetClassObj(Clsid, IClassFactory, CF)) then Exit;
  
  CF.CreateInstance(nil, IBaseFilter, Result);
end;

{ 免注册属性页 }

type
  // 直接转发到 .ax 内部类工厂的包装：CoRegisterClassObject 需要一个
  // 进程内的 IClassFactory 实现，而对象本身仍由原 .ax 创建。
  TLavFactoryForward = class(TInterfacedObject, IClassFactory)
  private
    FInner: IClassFactory;
  public
    constructor Create(const Inner: IClassFactory);
    function CreateInstance(const unkOuter: IUnknown; const iid: TGUID; out obj): HResult; stdcall;
    function LockServer(fLock: BOOL): HResult; stdcall;
  end;

constructor TLavFactoryForward.Create(const Inner: IClassFactory);
begin
  inherited Create;
  FInner := Inner;
end;

function TLavFactoryForward.CreateInstance(const unkOuter: IUnknown; const iid: TGUID; out obj): HResult;
begin
  Result := FInner.CreateInstance(unkOuter, iid, obj);
end;

function TLavFactoryForward.LockServer(fLock: BOOL): HResult;
begin
  Result := FInner.LockServer(fLock);
end;

function GetLavClassFactory(const AxName: string; const Clsid: TGUID): IClassFactory;
var
  GetClassObj: function(const clsid: TGUID; const iid: TGUID; out ppv): HResult; stdcall;
begin
  Result := nil;
  var AxPath := LocateLavAx(AxName);
  if AxPath = '' then Exit;
  var hLib := LoadLibraryEx(PChar(AxPath), 0, LOAD_WITH_ALTERED_SEARCH_PATH);
  if hLib = 0 then Exit;
  
  GetClassObj := GetProcAddress(hLib, 'DllGetClassObject');
  if not Assigned(GetClassObj) then Exit;
  
  if Failed(GetClassObj(Clsid, IClassFactory, Result)) then Result := nil;
end;

function RegisterLavClass(const AxName: string; const Clsid: TGUID; out Cookie: Longint): Boolean;
var
  Inner: IClassFactory;
  Fwd  : IClassFactory;
begin
  Result := False;
  Cookie := 0;
  Inner := GetLavClassFactory(AxName, Clsid);
  if Inner = nil then Exit;
  Fwd := TLavFactoryForward.Create(Inner);
  Result := Succeeded(CoRegisterClassObject(Clsid, Fwd, CLSCTX_INPROC_SERVER, REGCLS_MULTIPLEUSE, Cookie));
end;

procedure RevokeLavClass(Cookie: Longint);
begin
  if Cookie <> 0 then CoRevokeClassObject(Cookie);
end;

end.
