unit SubGrabber;

{ 字幕接收滤镜：一个输入 pin，接受 MEDIATYPE_Subtitle / MEDIATYPE_Text，
  把字幕采样文本 + 时间戳通过 OnSample 回调交给上层字幕引擎。
  滤镜拥有 pin 对象（构造时隐式引用计数=1，析构时手动 _Release）。 }

interface

uses Winapi.Windows, Winapi.ActiveX, Winapi.DirectShow9, System.SysUtils, System.Classes, DSCommon;

type
  TSubSampleEvent = procedure(StartDs, EndDs: Int64; const Text: string; const Subtype: TGUID) of object;
  TSubGrabberPin = class;

  TSubGrabberFilter = class(TInterfacedObject, IPersist, IMediaFilter, IBaseFilter)
  private
    FPin: TSubGrabberPin;
    FState: TFilterState;
    FGraph: IFilterGraph;
    FName: string;
  public
    constructor Create;
    destructor Destroy; override;
    // IPersist
    function GetClassID(out classID: TGUID): HResult; stdcall;
    // IMediaFilter
    function Stop: HResult; stdcall;
    function Pause: HResult; stdcall;
    function Run(tStart: TReferenceTime): HResult; stdcall;
    function GetState(dwMilliSecsTimeout: DWORD; out State: TFilterState): HResult; stdcall;
    function SetSyncSource(pClock: IReferenceClock): HResult; stdcall;
    function GetSyncSource(out pClock: IReferenceClock): HResult; stdcall;
    // IBaseFilter
    function EnumPins(out ppEnum: IEnumPins): HResult; stdcall;
    function FindPin(Id: PWideChar; out ppPin: IPin): HResult; stdcall;
    function QueryPinInfo(out pInfo: TPinInfo): HResult; stdcall;
    function QueryFilterInfo(out pInfo: TFilterInfo): HResult; stdcall;
    function JoinFilterGraph(pGraph: IFilterGraph; pName: PWideChar): HResult; stdcall;
    function QueryVendorInfo(out pVendorInfo: PWideChar): HResult; stdcall;
    property Pin: TSubGrabberPin read FPin;
  end;

  TEnumPinsSingle = class(TInterfacedObject, IEnumPins)
  private
    FPin: IPin;
    FPos: Integer;
    FOwnFilter: IBaseFilter; // 保持滤镜存活
  public
    constructor Create(APin: IPin; AOwnFilter: IBaseFilter);
    function Next(cPins: ULONG; out ppPins: IPin; pcFetched: PULONG): HResult; stdcall;
    function Skip(cPins: ULONG): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out ppEnum: IEnumPins): HResult; stdcall;
  end;

  TSubGrabberPin = class(TInterfacedObject, IPin, IMemInputPin)
  private
    FOwnFilter: TSubGrabberFilter; // 对象指针（非接口引用，避免循环）
    FMT: TAMMediaType;
    FConnected: IPin;
    FOnSample: TSubSampleEvent;
  public
    constructor Create(AOwner: TSubGrabberFilter);
    destructor Destroy; override;
    // IPin
    function Connect(pReceivePin: IPin; const pmt: PAMMediaType): HResult; stdcall;
    function ReceiveConnection(pConnector: IPin; const pmt: TAMMediaType): HResult; stdcall;
    function Disconnect: HResult; stdcall;
    function ConnectedTo(out pPin: IPin): HResult; stdcall;
    function ConnectionMediaType(out pmt: TAMMediaType): HResult; stdcall;
    function QueryPinInfo(out pInfo: TPinInfo): HResult; stdcall;
    function QueryDirection(out pPinDir: TPinDirection): HResult; stdcall;
    function QueryId(out Id: LPWSTR): HResult; stdcall;
    function QueryAccept(const pmt: TAMMediaType): HResult; stdcall;
    function EnumMediaTypes(out ppEnum: IEnumMediaTypes): HResult; stdcall;
    function QueryInternalConnections(out apPin: IPin; var nPin: ULONG): HResult; stdcall;
    function EndOfStream: HResult; stdcall;
    function BeginFlush: HResult; stdcall;
    function EndFlush: HResult; stdcall;
    function NewSegment(tStart, tStop: TReferenceTime; dRate: Double): HResult; stdcall;
    // IMemInputPin
    function GetAllocator(out ppAllocator: IMemAllocator): HResult; stdcall;
    function NotifyAllocator(pAllocator: IMemAllocator; bReadOnly: BOOL): HResult; stdcall;
    function GetAllocatorRequirements(out pProps: TAllocatorProperties): HResult; stdcall;
    function Receive(pSample: IMediaSample): HResult; stdcall;
    function ReceiveMultiple(pSamples: PIMediaSampleArray; nSamples: Longint; out nSamplesProcessed: Longint): HResult; stdcall;
    function ReceiveCanBlock: HResult; stdcall;
    function AcceptableMajortype(const G: TGUID): Boolean;
    property OnSample: TSubSampleEvent read FOnSample write FOnSample;
  end;

implementation

{ TSubGrabberFilter }

constructor TSubGrabberFilter.Create;
begin
  inherited Create;
  FState := State_Stopped;
  FName  := 'Sub Grabber';
  FPin   := TSubGrabberPin.Create(Self);
end;

destructor TSubGrabberFilter.Destroy;
begin
  if Assigned(FPin) then
  begin
    FPin._Release; // 归还构造时的隐式引用
    FPin := nil;
  end;
  inherited Destroy;
end;

function TSubGrabberFilter.GetClassID(out classID: TGUID): HResult;
begin
  classID := GUID_NULL;
  Result := E_NOTIMPL;
end;

function TSubGrabberFilter.Stop: HResult;
begin
  FState := State_Stopped;
  Result := S_OK;
end;

function TSubGrabberFilter.Pause: HResult;
begin
  FState := State_Paused;
  Result := S_OK;
end;

function TSubGrabberFilter.Run(tStart: TReferenceTime): HResult;
begin
  FState := State_Running;
  Result := S_OK;
end;

function TSubGrabberFilter.GetState(dwMilliSecsTimeout: DWORD; out State: TFilterState): HResult;
begin
  State := FState;
  Result := S_OK;
end;

function TSubGrabberFilter.SetSyncSource(pClock: IReferenceClock): HResult;
begin
  Result := S_OK;
end;

function TSubGrabberFilter.GetSyncSource(out pClock: IReferenceClock): HResult;
begin
  pClock := nil;
  Result := S_OK;
end;

function TSubGrabberFilter.EnumPins(out ppEnum: IEnumPins): HResult;
var
  BF: IBaseFilter;
begin
  BF     := Self;
  ppEnum := TEnumPinsSingle.Create(FPin, BF);
  Result := S_OK;
end;

function TSubGrabberFilter.FindPin(Id: PWideChar; out ppPin: IPin): HResult;
begin
  ppPin := nil;
  if (Id <> nil) and SameText(string(Id), 'Input') then
  begin
    ppPin := FPin;
    Result := S_OK;
  end
  else
    Result := VFW_E_NOT_FOUND;
end;

function TSubGrabberFilter.QueryPinInfo(out pInfo: TPinInfo): HResult;
begin
  FillChar(pInfo, SizeOf(pInfo), 0);
  pInfo.pFilter := Self;
  StrLCopy(pInfo.achName, 'Input', High(pInfo.achName));
  pInfo.dir := PINDIR_INPUT;
  Result := S_OK;
end;

function TSubGrabberFilter.QueryFilterInfo(out pInfo: TFilterInfo): HResult;
begin
  FillChar(pInfo, SizeOf(pInfo), 0);
  pInfo.pGraph := FGraph;
  StrLCopy(pInfo.achName, PChar(FName), High(pInfo.achName));
  Result := S_OK;
end;

function TSubGrabberFilter.JoinFilterGraph(pGraph: IFilterGraph; pName: PWideChar): HResult;
begin
  FGraph := pGraph;
  if pName <> nil then FName := string(pName);
  Result := S_OK;
end;

function TSubGrabberFilter.QueryVendorInfo(out pVendorInfo: PWideChar): HResult;
begin
  pVendorInfo := nil;
  Result := E_NOTIMPL;
end;

{ TEnumPinsSingle }

constructor TEnumPinsSingle.Create(APin: IPin; AOwnFilter: IBaseFilter);
begin
  inherited Create;
  FPin       := APin;
  FOwnFilter := AOwnFilter;
  FPos       := 0;
end;

function TEnumPinsSingle.Next(cPins: ULONG; out ppPins: IPin; pcFetched: PULONG): HResult;
begin
  if Assigned(pcFetched) then pcFetched^ := 0;
  ppPins := nil;
  if cPins = 0 then Exit(E_INVALIDARG);
  
  if FPos = 0 then
  begin
    ppPins := FPin;
    FPos := 1;
    if Assigned(pcFetched) then pcFetched^ := 1;
    Result := S_OK;
  end
  else
    Result := S_FALSE;
end;

function TEnumPinsSingle.Skip(cPins: ULONG): HResult;
begin
  FPos := FPos + Integer(cPins);
  if FPos > 1 then
    Result := S_FALSE
  else
    Result := S_OK;
end;

function TEnumPinsSingle.Reset: HResult;
begin
  FPos   := 0;
  Result := S_OK;
end;

function TEnumPinsSingle.Clone(out ppEnum: IEnumPins): HResult;
begin
  ppEnum := TEnumPinsSingle.Create(FPin, FOwnFilter);
  TEnumPinsSingle(ppEnum).FPos := FPos;
  Result := S_OK;
end;

{ TSubGrabberPin }

constructor TSubGrabberPin.Create(AOwner: TSubGrabberFilter);
begin
  inherited Create;
  FOwnFilter := AOwner;
  FillChar(FMT, SizeOf(FMT), 0);
end;

destructor TSubGrabberPin.Destroy;
begin
  FConnected := nil;
  if FMT.cbFormat > 0 then FreeMem(FMT.pbFormat);
  FillChar(FMT, SizeOf(FMT), 0);
  inherited Destroy;
end;

function TSubGrabberPin.AcceptableMajortype(const G: TGUID): Boolean;
begin
  Result := IsEqualGuid(G, MEDIATYPE_Subtitle) or IsEqualGuid(G, MEDIATYPE_Text);
end;

function TSubGrabberPin.Connect(pReceivePin: IPin; const pmt: PAMMediaType): HResult;
begin
  Result := E_UNEXPECTED;
end;

function TSubGrabberPin.ReceiveConnection(pConnector: IPin; const pmt: TAMMediaType): HResult;
begin
  if not AcceptableMajortype(pmt.majortype) then Exit(VFW_E_TYPE_NOT_ACCEPTED);
  if Assigned(FConnected) then Exit(VFW_E_ALREADY_CONNECTED);
  if not Assigned(pConnector) then Exit(E_POINTER);
  
  FConnected := pConnector;
  
  // 复制媒体类型
  if FMT.cbFormat > 0 then
  begin
    FreeMem(FMT.pbFormat);
    FMT.cbFormat := 0;
    FMT.pbFormat := nil;
  end;
  FMT := pmt;
  if pmt.cbFormat > 0 then
  begin
    GetMem(FMT.pbFormat, pmt.cbFormat);
    Move(pmt.pbFormat^, FMT.pbFormat^, pmt.cbFormat);
  end
  else
    FMT.pbFormat := nil;
  Result := S_OK;
end;

function TSubGrabberPin.Disconnect: HResult;
begin
  if not Assigned(FConnected) then Exit(VFW_E_NOT_CONNECTED);
  
  FConnected := nil;
  if FMT.cbFormat > 0 then
  begin
    FreeMem(FMT.pbFormat);
    FMT.cbFormat := 0;
    FMT.pbFormat := nil;
  end;
  Result := S_OK;
end;

function TSubGrabberPin.ConnectedTo(out pPin: IPin): HResult;
begin
  pPin := FConnected;
  if Assigned(FConnected) then
    Result := S_OK
  else
    Result := VFW_E_NOT_CONNECTED;
end;

function TSubGrabberPin.ConnectionMediaType(out pmt: TAMMediaType): HResult;
begin
  if not Assigned(FConnected) then Exit(VFW_E_NOT_CONNECTED);
  
  pmt := FMT;
  if FMT.cbFormat > 0 then
  begin
    GetMem(pmt.pbFormat, FMT.cbFormat);
    Move(FMT.pbFormat^, pmt.pbFormat^, FMT.cbFormat);
  end
  else
    pmt.pbFormat := nil;
  Result := S_OK;
end;

function TSubGrabberPin.QueryPinInfo(out pInfo: TPinInfo): HResult;
begin
  FillChar(pInfo, SizeOf(pInfo), 0);
  pInfo.pFilter := FOwnFilter;
  StrLCopy(pInfo.achName, 'Input', High(pInfo.achName));
  pInfo.dir := PINDIR_INPUT;
  Result := S_OK;
end;

function TSubGrabberPin.QueryDirection(out pPinDir: TPinDirection): HResult;
begin
  pPinDir := PINDIR_INPUT;
  Result := S_OK;
end;

function TSubGrabberPin.QueryId(out Id: LPWSTR): HResult;
begin
  Id := LPWSTR(CoTaskMemAlloc((Length('Input') + 1) * SizeOf(WideChar)));
  if Id = nil then Exit(E_OUTOFMEMORY);
  
  StringToWideChar('Input', Id, Length('Input') + 1);
  Result := S_OK;
end;

function TSubGrabberPin.QueryAccept(const pmt: TAMMediaType): HResult;
begin
  if AcceptableMajortype(pmt.majortype) then
    Result := S_OK
  else
    Result := S_FALSE;
end;

function TSubGrabberPin.EnumMediaTypes(out ppEnum: IEnumMediaTypes): HResult;
begin
  ppEnum := nil;
  Result := E_NOTIMPL;
end;

function TSubGrabberPin.QueryInternalConnections(out apPin: IPin; var nPin: ULONG): HResult;
begin
  Result := E_NOTIMPL;
end;

function TSubGrabberPin.EndOfStream: HResult;
begin
  Result := S_OK;
end;

function TSubGrabberPin.BeginFlush: HResult;
begin
  Result := S_OK;
end;

function TSubGrabberPin.EndFlush: HResult;
begin
  Result := S_OK;
end;

function TSubGrabberPin.NewSegment(tStart, tStop: TReferenceTime; dRate: Double): HResult;
begin
  Result := S_OK;
end;

function TSubGrabberPin.GetAllocator(out ppAllocator: IMemAllocator): HResult;
begin
  ppAllocator := nil;
  Result := CoCreateInstance(CLSID_MemoryAllocator, nil, CLSCTX_INPROC_SERVER, IMemAllocator, ppAllocator);
end;

function TSubGrabberPin.NotifyAllocator(pAllocator: IMemAllocator; bReadOnly: BOOL): HResult;
begin
  if pAllocator = nil then Exit(E_POINTER);
  Result := S_OK;
end;

function TSubGrabberPin.GetAllocatorRequirements(out pProps: TAllocatorProperties): HResult;
begin
  Result := E_NOTIMPL;
end;

function TSubGrabberPin.Receive(pSample: IMediaSample): HResult;
var
  P             : PByte;
  Len           : Integer;
  StartDs, EndDs: TReferenceTime;
  Bytes         : TBytes;
  Txt           : string;
begin
  Result := S_OK;
  if not Assigned(pSample) then  Exit(E_POINTER);
  if not Assigned(FOnSample) then Exit;
  
  Len := pSample.GetActualDataLength;
  if Len <= 0 then Exit;
  if Failed(pSample.GetPointer(P)) then Exit;
  
  StartDs := 0;
  EndDs   := 0;
  pSample.GetTime(StartDs, EndDs);
  SetLength(Bytes, Len);
  Move(P^, Bytes[0], Len);
  Txt := TEncoding.UTF8.GetString(Bytes);
  try
    FOnSample(StartDs, EndDs, Txt, FMT.subtype);
  except
    // 不让上层异常破坏数据流
  end;
end;

function TSubGrabberPin.ReceiveMultiple(pSamples: PIMediaSampleArray;  nSamples: Longint; out nSamplesProcessed: Longint): HResult;
begin
  nSamplesProcessed := 0;
  for var i := 0 to nSamples - 1 do
  begin
    Result := Receive(pSamples^[i]);
    if Failed(Result) then Exit;
    Inc(nSamplesProcessed);
  end;
  Result := S_OK;
end;

function TSubGrabberPin.ReceiveCanBlock: HResult;
begin
  Result := S_OK;
end;

end.
