unit Unit4;
{
  多线程将文本文件，导入到 sqlite 数据库中；
  目的：多线程解析 IO/CPU 并行，SQLite 仅单线程写入，彻底规避 database is locked 写锁冲突；支持文件陆续、动态调用 AddImportTask 提交任务。同一个文本文件不得反复提交；
  说明：
      TRecordQueue,         数据队列类：包含待导入的数据；由文本解析类调用和填充；
      TParserThread,        文本解析类：多线程解析文本文件，填充到数据队列之中；
      TWriterThread,        批量写入类：多线程批量提交数据到 sqlite 数据库；
      TTextToSqliteImporter,单线程写入数据类；开放给用户调用；
}

interface

uses System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs, System.StrUtils, System.Math,
     FireDAC.Phys.SQLiteWrapper.Stat,FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
     FireDAC.Stan.Util, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.Def, FireDAC.Phys, FireDAC.UI.Intf, FireDAC.Comp.Client;

const
  c_strDatabaseName    = 'NTFS.db';
  c_strTableName       = 'FileID';
  c_iMaxWriteLines     = 5000;    // DB批量提交大小
  c_iParserReportLines = 5000;    // 解析行数上报间隔
  c_iWriteReportDelta  = 40000;   // 条数上报间隔

type
  TParserProgressCallback = reference to procedure(const AFileName: string; AReadLines: Int64; const AErrorMsg: string);  // 文件解析进度回调
  TWriteProgressCallback  = reference to procedure(ATotalImported: Int64; AIsFinished: Boolean; const AErrorMsg: string);  // 入库数量进度回调

type
  TTextToSqliteImporter = class
  public
    type
    TImportRecord = record
      TableName: string;
      F1, F2   : UInt64;
      F3       : Boolean;
      F4       : string;
    end;
    type
    TParserState = record
      ActiveCount        : Integer;
      HasAnySubmittedTask: Boolean;
    end;
  private
    { ========== 线程安全记录队列 ========== }
    type
    TRecordQueue = class
    private
      FQueue  : TQueue<TImportRecord>;
      FCritSec: TCriticalSection;
      FEvent  : TEvent;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Enqueue(const ARec: TImportRecord);
      function Dequeue(out ARec: TImportRecord): Boolean;
      function IsEmpty: Boolean;
      property Event: TEvent read FEvent;
    end;

    { ========== 文件解析多线程 ========== }
    type
    TParserThread = class(TThread)
    private
      FFileName         : string;
      FTableName        : string;
      FQueue            : TRecordQueue;
      FGetParserCallback: TFunc<TParserProgressCallback>;
      FLineCount        : Int64;
      FErrorMsg         : string;
      FIsStopped        : TFunc<Boolean>;
      procedure SyncProgress;
    protected
      procedure Execute; override;
    public
      constructor Create(const AFileName, ATableName: string; AQueue: TRecordQueue; ACallback: TFunc<TParserProgressCallback>; AIsStopped: TFunc<Boolean>);
    end;

    { ========== SQLite写入线程；单线程 ========== }
    type
    TWriterThread = class(TThread)
    private
      FDbFile           : string;
      FQueue            : TRecordQueue;
      FBatchSize        : Integer;
      FGetWriteCallback : TFunc<TWriteProgressCallback>;
      FGetParserState   : TFunc<TParserState>;
      FImported         : Int64;
      FErrorMsg         : string;
      FInitializedTables: TDictionary<string,Boolean>;
      FReportThreshold  : Int64;
      FReportedImported : Int64;
      FIsStopped        : TFunc<Boolean>;
      procedure SyncProgress(AFinished: Boolean; const AErrMsg: string);
      function EnsureTable(const ATableName: string; AConn: TObject): Boolean;
      function UInt64ToBlob(AValue: UInt64): TFDByteString;
    protected
      procedure Execute; override;
    public
      constructor Create(const ADbFile: string; AQueue: TRecordQueue; ABatchSize: Integer; ACallback: TFunc<TWriteProgressCallback>; AGetCount: TFunc<TParserState>; AIsStopped: TFunc<Boolean>);
      destructor Destroy; override;
    end;

  private
    FRecordQueue        : TRecordQueue;
    FWriterThread       : TWriterThread;
    FParserThreads      : TObjectList<TParserThread>;
    FTaskFiles          : TDictionary<string, Boolean>;
    FCrit               : TCriticalSection;
    FParserCallback     : TParserProgressCallback;
    FWriteCallback      : TWriteProgressCallback;
    FHasAnyTaskSubmitted: Boolean;
    FStopped            : PBoolean;
    FIsStopped          : TFunc<Boolean>;
    function GetParserState: TParserState;
    procedure InternalStop;
  public
    constructor Create(const ABatchSize: Integer = c_iMaxWriteLines);
    destructor Destroy; override;
    { 添加导入任务 }
    function AddImportTask(const AFileName, ATableName: string): Boolean;
    { 设置解析回调 }
    function GetParserCallback: TParserProgressCallback;
    procedure SetParserCallback(ACallback: TParserProgressCallback);
    { 设置写入回调 }
    function GetWriteCallback: TWriteProgressCallback;
    procedure SetWriteCallback(ACallback: TWriteProgressCallback);
    {立即停止所有线程 }
    procedure Stop;
end;

implementation

constructor TTextToSqliteImporter.TRecordQueue.Create;
begin
  inherited;
  FQueue   := TQueue<TImportRecord>.Create;
  FCritSec := TCriticalSection.Create;
  FEvent   := TEvent.Create(nil, False, False, '');
end;

destructor TTextToSqliteImporter.TRecordQueue.Destroy;
begin
  FEvent.Free;
  FCritSec.Free;
  FQueue.Free;
  inherited;
end;

{ 数据加入队列 }
procedure TTextToSqliteImporter.TRecordQueue.Enqueue(const ARec: TImportRecord);
begin
  FCritSec.Enter;
  try
    FQueue.Enqueue(ARec);
  finally
    FCritSec.Leave;
  end;

  { 通知写线程有新数据到来 }
  FEvent.SetEvent;
end;

{ 数据取出队列 }
function TTextToSqliteImporter.TRecordQueue.Dequeue(out ARec: TImportRecord): Boolean;
begin
  Result := False;
  FCritSec.Enter;
  try
    if not FQueue.IsEmpty then
    begin
      ARec   := FQueue.Dequeue;
      Result := True;
    end;
    if FQueue.IsEmpty then
      FEvent.ResetEvent;
  finally
    FCritSec.Leave;
  end;
end;

function TTextToSqliteImporter.TRecordQueue.IsEmpty: Boolean;
begin
  FCritSec.Enter;
  try
    Result := FQueue.IsEmpty;
  finally
    FCritSec.Leave;
  end;
end;

{ TTextToSqliteImporter.TParserThread }

constructor TTextToSqliteImporter.TParserThread.Create(const AFileName, ATableName: string; AQueue: TRecordQueue; ACallback: TFunc<TParserProgressCallback>; AIsStopped: TFunc<Boolean>);
begin
  inherited Create(True);
  FreeOnTerminate := False;

  FFileName          := AFileName;
  FTableName         := ATableName;
  FQueue             := AQueue;
  FGetParserCallback := ACallback;
  FLineCount         := 0;
  FErrorMsg          := '';
  FIsStopped         := AIsStopped;
end;

procedure TTextToSqliteImporter.TParserThread.SyncProgress;
var
  CallBack      : TParserProgressCallback;
  LocalFileName : string;
  LocalLineCount: Int64;
  LocalErrMsg   : string;
  LocalCheck    : TFunc<Boolean>;
begin
  if not Assigned(FGetParserCallback) then Exit;
  CallBack := FGetParserCallback();
  if not Assigned(CallBack) then Exit;

  LocalFileName  := FFileName;
  LocalLineCount := FLineCount;
  LocalErrMsg    := FErrorMsg;
  LocalCheck     := FIsStopped;

  TThread.Queue(nil,
  procedure
  begin
  if Assigned(LocalCheck) and LocalCheck() then Exit;
  CallBack(LocalFileName, LocalLineCount, LocalErrMsg);
  end);
end;

procedure TTextToSqliteImporter.TParserThread.Execute;
var
  Rec : TImportRecord;
begin
  try
    var FS := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
    var SR := TStreamReader.Create(FS, TEncoding.UTF8);
    try
      Rec.TableName := FTableName;
      while not SR.EndOfStream and not Terminated do
      begin
        var Line := Trim(SR.ReadLine);
        Inc(FLineCount);
        if Line.IsEmpty then Continue;

        var strs := Line.Split([';']);
        if Length(strs) < 4 then Continue;

        var p1   := StrToUInt64Def(strs[0], 0);
        var p2   := StrToUInt64Def(strs[1], 0);
        var p3   := Boolean(IfThen(SameText(strs[2], '0'), 1, 0));
        var p4   := strs[3];
        if (p1 <= 0) or (p2 <= 0)  then
          Continue;

        Rec.F1 := p1;
        Rec.F2 := p2;
        Rec.F3 := p3;
        Rec.F4 := p4;

        { 加入到队列中 }
        FQueue.Enqueue(Rec);

        if (FLineCount mod c_iParserReportLines) = 0 then
          SyncProgress;
      end;
      SyncProgress;
    finally
      SR.Free;
      FS.Free;
    end;
  except
    on E: Exception do
    begin
      FErrorMsg := E.Message;
      SyncProgress;
    end;
  end;
end;

{ TTextToSqliteImporter.TWriterThread }

constructor TTextToSqliteImporter.TWriterThread.Create(const ADbFile: string; AQueue: TRecordQueue; ABatchSize: Integer; ACallback: TFunc<TWriteProgressCallback>; AGetCount: TFunc<TParserState>; AIsStopped: TFunc<Boolean>);
begin
  inherited Create(True);
  FreeOnTerminate := False;

  FDbFile               := ADbFile;
  FQueue                := AQueue;
  FBatchSize            := ABatchSize;
  FGetWriteCallback     := ACallback;
  FGetParserState       := AGetCount;
  FImported             := 0;
  FErrorMsg             := '';
  FInitializedTables    := TDictionary<string,Boolean>.Create;
  FReportThreshold      := c_iWriteReportDelta;
  FReportedImported     := 0;
  FIsStopped            := AIsStopped;
end;

procedure TTextToSqliteImporter.TWriterThread.SyncProgress(AFinished: Boolean; const AErrMsg: string);
var
  CallBack     : TWriteProgressCallback;
  LocalImported: Int64;
  LocalFinished: Boolean;
  LocalErr     : string;
  LocalCheck   : TFunc<Boolean>;
begin
  if not Assigned(FGetWriteCallback) then Exit;
  CallBack := FGetWriteCallback();
  if not Assigned(CallBack) then Exit;

  { 捕获当前栈局部变量，规避闭包延迟取值 }
  LocalImported := FImported;
  LocalFinished := AFinished;
  LocalErr      := AErrMsg;
  LocalCheck    := FIsStopped;

  { 结束事件：无条件投递；普通进度：达到阈值才投递 }
  if LocalFinished or ((LocalImported - FReportedImported) >= FReportThreshold) then
  begin
    TThread.Queue(nil,
    procedure
    begin
      if Assigned(LocalCheck) and LocalCheck() then Exit;
      CallBack(LocalImported, LocalFinished, LocalErr);
    end);
    if not LocalFinished then
      FReportedImported := LocalImported;
  end;
end;

destructor TTextToSqliteImporter.TWriterThread.Destroy;
begin
  FInitializedTables.Free;
  inherited;
end;

function TTextToSqliteImporter.TWriterThread.EnsureTable(const ATableName: string; AConn: TObject): Boolean;
begin
  Result := True;
  var Q  := TFDQuery.Create(nil);
  try
    Q.Connection := TFDConnection(AConn);
    Q.SQL.Text := Format('CREATE TABLE IF NOT EXISTS %s(f1 BLOB, f2 BLOB, f3 INTEGER, f4 TEXT);', [ATableName]);
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

{ UInt64 → TFDByteString(二进制blob，8字节) }
function TTextToSqliteImporter.TWriterThread.UInt64ToBlob(AValue: UInt64): TFDByteString;
begin
  SetLength(Result, SizeOf(UInt64));
  Move(AValue, Result[1], SizeOf(UInt64));
end;

procedure TTextToSqliteImporter.TWriterThread.Execute;
var
  BatchBuf       : array of TImportRecord;
  BatchCnt       : Integer;
  Rec            : TImportRecord;
begin
  var Conn := TFDConnection.Create(nil);
  var Q    := TFDQuery.Create(nil);
  SetLength(BatchBuf, FBatchSize);
  try
    Conn.DriverName      := 'SQLite';
    Conn.Params.Database := FDbFile;
    Conn.Params.Add('LockingMode=Normal');
    Conn.Params.Add('Synchronous=Off');
    Conn.Params.Add('JournalMode=WAL');
    Conn.Params.Add('PageSize=4096');
    Conn.Params.Add('BusyTimeout=5000');
    Conn.Connected := True;

    Conn.StartTransaction;
    try
      while not Terminated do
      begin
        { 等待解析线程的到来 }
        var ParserState := FGetParserState();
        if ParserState.HasAnySubmittedTask and (ParserState.ActiveCount = 0) and FQueue.IsEmpty then
          Break;

        if FQueue.IsEmpty then
        begin
          FQueue.Event.WaitFor(200);
          Continue;
        end;

        { 填充待提交的数据队列，必须是同一张表，直到填满 }
        BatchCnt := 0;
        while FQueue.Dequeue(Rec) and (BatchCnt < FBatchSize) and not Terminated do
        begin
          if (BatchCnt > 0) and (Rec.TableName <> BatchBuf[0].TableName) then
          begin
            FQueue.Enqueue(Rec);
            Break;
          end;

          BatchBuf[BatchCnt] := Rec;
          Inc(BatchCnt);
        end;

        if BatchCnt > 0 then
        begin
          var CurTableName := BatchBuf[0].TableName;
          if not FInitializedTables.ContainsKey(CurTableName) then
          begin
            EnsureTable(CurTableName, Conn);
            FInitializedTables.Add(CurTableName, True);
          end;

          Q.Connection       := Conn;
          Q.SQL.Text         := Format('INSERT INTO %s(f1,f2,f3,f4) VALUES(:f1,:f2,:f3,:f4)', [CurTableName]);
          Q.Params.ArraySize := BatchCnt;

          for var i := 0 to BatchCnt - 1 do
          begin
            Q.Params[0].AsBlobs[i]    := UInt64ToBlob(BatchBuf[i].F1);
            Q.Params[1].AsBlobs[i]    := UInt64ToBlob(BatchBuf[i].F2);
            Q.Params[2].AsBooleans[i] := BatchBuf[i].F3;
            Q.Params[3].AsStrings[i]  := BatchBuf[i].F4;
          end;
          Q.Execute(BatchCnt);
          Inc(FImported, BatchCnt);
          SyncProgress(False, '');
        end;
      end;

      if Terminated then
      begin
        if Conn.InTransaction then Conn.Rollback;
        FImported := 0;
        SyncProgress(True, '');
      end
      else
      begin
        if Conn.InTransaction then Conn.Commit;
        SyncProgress(True, '');
      end;
    except
      on E: Exception do
      begin
        if Conn.InTransaction then Conn.Rollback;
        FErrorMsg := E.Message;
        SyncProgress(True, FErrorMsg);
      end;
    end;
  finally
    Q.Free;
    Conn.Free;
  end;
end;

{ TTextToSqliteImporter }

constructor TTextToSqliteImporter.Create(const ABatchSize: Integer = c_iMaxWriteLines);
begin
  inherited Create;
  FHasAnyTaskSubmitted := False;
  FCrit                := TCriticalSection.Create;
  FTaskFiles           := TDictionary<string, Boolean>.Create;
  FParserThreads       := TObjectList<TParserThread>.Create(True);
  FRecordQueue         := TRecordQueue.Create;

  New(FStopped);
  FStopped^   := False;
  var FlagPtr := FStopped;
  FIsStopped  := function: Boolean begin Result := FlagPtr^; end;

  { 启动写入线程 }
  FWriterThread := TWriterThread.Create(ExtractFilePath(ParamStr(0)) + c_strDatabaseName, FRecordQueue, ABatchSize, function: TWriteProgressCallback  begin Result := GetWriteCallback(); end, function: TParserState begin Result := GetParserState(); end, FIsStopped);
  FWriterThread.Start;
end;

destructor TTextToSqliteImporter.Destroy;
begin
  Stop;
  FWriterThread.Free;
  FParserThreads.Free;
  FTaskFiles.Free;
  FCrit.Free;
  FRecordQueue.Free;
  inherited;
end;

function TTextToSqliteImporter.GetParserState: TParserState;
begin
  FCrit.Enter;
  try
    var ActiveCnt := 0;
    if Assigned(FParserThreads) then
    begin
      for var I := FParserThreads.Count - 1 downto 0 do
      begin
        if FParserThreads[I].Finished then
          FParserThreads.Delete(I)
        else
          Inc(ActiveCnt);
      end;
    end;
    Result.ActiveCount := ActiveCnt;
    Result.HasAnySubmittedTask := FHasAnyTaskSubmitted;
  finally
    FCrit.Leave;
  end;
end;

procedure TTextToSqliteImporter.InternalStop;
var
  ParserThreads: TArray<TParserThread>;
begin
  { 标记线程退出 }
  FCrit.Enter;
  try
    SetLength(ParserThreads, FParserThreads.Count);
    for var I := 0 to FParserThreads.Count - 1 do
      ParserThreads[I] := FParserThreads[I];
    for var t in ParserThreads do t.Terminate;
  finally
    FCrit.Leave;
  end;
  if Assigned(FWriterThread) then FWriterThread.Terminate;

  { 等待线程销毁完毕 }
  for var t in ParserThreads do t.WaitFor;
  if Assigned(FWriterThread) then FWriterThread.WaitFor;

  { 清空解析线程列表 }
  FCrit.Enter;
  try
    FParserThreads.Clear;
  finally
    FCrit.Leave;
  end;
end;

{ 立即停止所有线程 }
procedure TTextToSqliteImporter.Stop;
begin
  if AtomicExchange(PInteger(FStopped)^, 1) <> 0 then Exit;

  FStopped^ := True;
  InternalStop;
end;

{ 添加导入任务 }
function TTextToSqliteImporter.AddImportTask(const AFileName, ATableName: string): Boolean;
begin
  Result := False;
  if not Assigned(FRecordQueue) then Exit;

  FCrit.Enter;
  try
    if FStopped^ then Exit;
    if FTaskFiles.ContainsKey(AFileName) then Exit;

    { 添加到任务列表 }
    FTaskFiles.Add(AFileName, True);
    FHasAnyTaskSubmitted := True;
  finally
    FCrit.Leave;
  end;

  { 开始解析线程 }
  var Thr := TParserThread.Create(AFileName, c_strTableName + '_' + ATableName, FRecordQueue, function: TParserProgressCallback  begin Result := GetParserCallback(); end, FIsStopped);
  FCrit.Enter;
  try
    FParserThreads.Add(Thr);
  finally
    FCrit.Leave;
  end;
  Thr.Start;

  Result := True;
end;

{ 设置解析回调 }
function TTextToSqliteImporter.GetParserCallback: TParserProgressCallback;
begin
  FCrit.Enter;
  try
    Result := FParserCallback;
  finally
    FCrit.Leave;
  end;
end;

procedure TTextToSqliteImporter.SetParserCallback(ACallback: TParserProgressCallback);
begin
  FCrit.Enter;
  try
    FParserCallback := ACallback;
  finally
    FCrit.Leave;
  end;
end;

{ 设置写入回调 }
function TTextToSqliteImporter.GetWriteCallback: TWriteProgressCallback;
begin
  FCrit.Enter;
  try
    Result := FWriteCallback;
  finally
    FCrit.Leave;
  end;
end;

procedure TTextToSqliteImporter.SetWriteCallback(ACallback: TWriteProgressCallback);
begin
  FCrit.Enter;
  try
    FWriteCallback := ACallback;
  finally
    FCrit.Leave;
  end;
end;

end.
