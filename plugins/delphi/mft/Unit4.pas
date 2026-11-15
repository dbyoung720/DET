unit Unit4;
{
  多线程将文本文件，导入到 sqlite 数据库中；
  目的：多线程解析 IO/CPU 并行，SQLite 仅单线程写入，彻底规避 database is locked 写锁冲突；支持文件陆续、动态调用 AddImportTask 提交任务。同一个文本文件不得反复提交；
  说明：
      TRecordQueue,         数据队列类：包含待导入的数据；由文本解析类调用和填充；
      TParserThread,        文本解析类：多线程解析文本文件，填充到数据队列之中；
      TWriterThread,        批量写入类：多线程批量将队列中的数据提交到 sqlite 数据库；
      TTextToSqliteImporter,单线程工作类；开放给用户调用；
}

interface

uses
  Winapi.Messages, System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs, System.StrUtils, System.Math, Winapi.Windows,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Util, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.Def, FireDAC.Phys,
  FireDAC.UI.Intf, FireDAC.Comp.Client;

const
  WM_IMPORTER_DONE  = WM_USER + 200;
  c_strDatabaseName = 'NTFS.db';
  c_strTableName    = 'FileID';
  c_iMaxWriteLines  = 20000;
  c_iSendTimeoutMS  = 500;

type
  TTextToSqliteImporter = class
  private
    type
	TImportRecord = record
	  TableName: string;
	  FileID   : UInt64;
	  ParentID : UInt64;
	  IsDir    : Boolean;
	  Name     : string;
	end;

    type
    TTaskResult = record
      FileName : string;
      TableName: string;
      Success  : Boolean;
    end;

    type
    TParserState = record
      ActiveCount        : Integer;
      HasAnySubmittedTask: Boolean;
      FinishedTasks      : TArray<TTaskResult>;
    end;

  private
    type
    TRecordQueue = class
    private
      FQueue  : TQueue<TImportRecord>;
      FCritSec: TCriticalSection;
      FEvent  : TEvent;
    public
      constructor Create;
      destructor  Destroy; override;
      procedure Enqueue(const ARec: TImportRecord);
      function  Dequeue(out ARec: TImportRecord): Boolean;
      function  IsEmpty: Boolean;
      property  Event: TEvent read FEvent;
    end;

    type
    TParserThread = class(TThread)
    private
      FFileName     : string;
      FTableName    : string;
      FQueue        : TRecordQueue;
      FErrorOccurred: Boolean;
    protected
      procedure Execute; override;
    public
      constructor Create(const AFileName, ATableName: string; AQueue: TRecordQueue);
      property FileName     : string  read FFileName;
      property TableName    : string  read FTableName;
      property ErrorOccurred: Boolean read FErrorOccurred;
    end;

    type
    TWriterThread = class(TThread)
    private
      FDbFile          : string;
      FQueue           : TRecordQueue;
      FBatchSize       : Integer;
      FNotifyWnd       : HWND;
      FGetParserState  : TFunc<TParserState>;
      FInitializedTable: TDictionary<string, Boolean>;
      function  EnsureTable(const ATableName: string; AConn: TObject): Boolean;
      function  UInt64ToBlob(AValue: UInt64): TFDByteString;
      procedure SendNotify(AStatus: WPARAM; const AInfo: string);
    protected
      procedure Execute; override;
    public
      constructor Create(const ADbFile: string; AQueue: TRecordQueue; ABatchSize: Integer; ANotifyWnd: HWND; AGetState: TFunc<TParserState>);
      destructor  Destroy; override;
    end;

  private
    FRecordQueue    : TRecordQueue;
    FWriterThread   : TWriterThread;
    FParserThreads  : TObjectList<TParserThread>;
    FTaskFiles      : TDictionary<string, Boolean>;
    FCrit           : TCriticalSection;
    FNotifyWnd      : HWND;
    FStopped        : Boolean;
    FHasAnySubmitted: Boolean;
    function  GetParserState: TParserState;
    procedure InternalStop;
  public
    constructor Create(ANotifyWnd: HWND; const ABatchSize: Integer = c_iMaxWriteLines);
    destructor  Destroy; override;
    function  AddImportTask(const AFileName, ATableName: string): Boolean;
    procedure Stop;
  end;

implementation

{ ================= TRecordQueue ================= }

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

procedure TTextToSqliteImporter.TRecordQueue.Enqueue(const ARec: TImportRecord);
begin
  FCritSec.Enter;
  try
    FQueue.Enqueue(ARec);
  finally
    FCritSec.Leave;
  end;
  FEvent.SetEvent;
end;

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

{ ================= TParserThread ================= }

constructor TTextToSqliteImporter.TParserThread.Create(const AFileName, ATableName: string; AQueue: TRecordQueue);
begin
  inherited Create(True);
  FreeOnTerminate:= False;
  FFileName      := AFileName;
  FTableName     := ATableName;
  FQueue         := AQueue;
  FErrorOccurred := False;
end;

procedure TTextToSqliteImporter.TParserThread.Execute;
var
  Rec: TImportRecord;
begin
  FErrorOccurred := False;
  try
    var FS := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
    var SR := TStreamReader.Create(FS, TEncoding.UTF8);
    try
      Rec.TableName := FTableName;
      while (not SR.EndOfStream) and (not Terminated) do
      begin
        var Line := Trim(SR.ReadLine);
        if Line.IsEmpty then Continue;

        var strs := Line.Split([';']);
        if Length(strs) < 4 then Continue;

        var p1 := StrToUInt64Def(strs[0], 0);
        var p2 := StrToUInt64Def(strs[1], 0);
        var p3 := SameText(strs[2], '1');
        var p4 := strs[3];
        if (p1 = 0) or (p2 = 0) then Continue;

        Rec.F1 := p1;
        Rec.F2 := p2;
        Rec.F3 := p3;
        Rec.F4 := p4;
        FQueue.Enqueue(Rec);
      end;
    finally
      SR.Free;
      FS.Free;
    end;
  except
    FErrorOccurred := True;
  end;
end;

{ ================= TWriterThread ================= }

constructor TTextToSqliteImporter.TWriterThread.Create(const ADbFile: string; AQueue: TRecordQueue; ABatchSize: Integer; ANotifyWnd: HWND; AGetState: TFunc<TParserState>);
begin
  inherited Create(True);
  FreeOnTerminate  := False;
  FDbFile          := ADbFile;
  FQueue           := AQueue;
  FBatchSize       := ABatchSize;
  FNotifyWnd       := ANotifyWnd;
  FGetParserState  := AGetState;
  FInitializedTable:= TDictionary<string, Boolean>.Create;
end;

destructor TTextToSqliteImporter.TWriterThread.Destroy;
begin
  FInitializedTable.Free;
  inherited;
end;

function TTextToSqliteImporter.TWriterThread.EnsureTable(const ATableName: string; AConn: TObject): Boolean;
begin
  Result := True;
  var Q  := TFDQuery.Create(nil);
  try
    Q.Connection := TFDConnection(AConn);
    Q.SQL.Text   := Format('CREATE TABLE IF NOT EXISTS "%s" (FileID BLOB, ParentID BLOB, IsDir INTEGER, Name TEXT);', [ATableName]);
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TTextToSqliteImporter.TWriterThread.UInt64ToBlob(AValue: UInt64): TFDByteString;
begin
  SetLength(Result, SizeOf(UInt64));
  Move(AValue, Result[1], SizeOf(UInt64));
end;

procedure TTextToSqliteImporter.TWriterThread.SendNotify(AStatus: WPARAM; const AInfo: string);
var
  Dummy: DWORD_PTR;
begin
  SendMessageTimeout(FNotifyWnd, WM_IMPORTER_DONE, AStatus, LPARAM(PChar(AInfo)), SMTO_ABORTIFHUNG, c_iSendTimeoutMS, Dummy);
end;

procedure TTextToSqliteImporter.TWriterThread.Execute;
var
  BatchBuf: array of TImportRecord;
  BatchCnt: Integer;
  Rec     : TImportRecord;
  HasError: Boolean;
begin
  HasError := False;
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
        { 收集本轮已完成任务，立即为每个任务发送通知 }
        var State := FGetParserState();
        for var T in State.FinishedTasks do
        begin
          if T.Success then
            SendNotify(0, T.FileName + ' -> ' + T.TableName)
          else
          begin
            SendNotify(2, T.FileName + ' -> ' + T.TableName + '（失败）');
            HasError := True;
          end;
        end;

        { 全部结束条件：无活跃解析线程 + 队列空 }
        if State.HasAnySubmittedTask and (State.ActiveCount = 0) and FQueue.IsEmpty then
          Break;

        if FQueue.IsEmpty then
        begin
          FQueue.Event.WaitFor(200);
          Continue;
        end;

        { 填充同一张表的批量数据 }
        BatchCnt := 0;
        while FQueue.Dequeue(Rec) and (BatchCnt < FBatchSize) and (not Terminated) do
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
          if not FInitializedTable.ContainsKey(CurTableName) then
          begin
            EnsureTable(CurTableName, Conn);
            FInitializedTable.Add(CurTableName, True);
          end;

          Q.Connection       := Conn;
          Q.SQL.Text         := Format('INSERT INTO %s(FileID,ParentID,IsDir,Name) VALUES(:FileID,:ParentID,:IsDir,:Name)', [CurTableName]);
          Q.Params.ArraySize := BatchCnt;

          for var i := 0 to BatchCnt - 1 do
          begin
            Q.Params[0].AsBlobs[i]    := UInt64ToBlob(BatchBuf[i].FileID);
            Q.Params[1].AsBlobs[i]    := UInt64ToBlob(BatchBuf[i].ParentID);
            Q.Params[2].AsBooleans[i] := BatchBuf[i].IsDir;
            Q.Params[3].AsStrings[i]  := BatchBuf[i].Name;
          end;
          Q.Execute(BatchCnt);
        end;
      end;

      { 结束：按 HasError 决定提交或回滚 }
      if Terminated or HasError then
      begin
        if Conn.InTransaction then Conn.Rollback;
      end
      else
      begin
        if Conn.InTransaction then Conn.Commit;
      end;
    except
      on E: Exception do
      begin
        if Conn.InTransaction then Conn.Rollback;
      end;
    end;
  finally
    Q.Free;
    Conn.Free;
  end;
end;

{ ================= TTextToSqliteImporter ================= }

constructor TTextToSqliteImporter.Create(ANotifyWnd: HWND; const ABatchSize: Integer);
begin
  inherited Create;
  FNotifyWnd       := ANotifyWnd;
  FStopped         := False;
  FHasAnySubmitted := False;
  FCrit            := TCriticalSection.Create;
  FTaskFiles       := TDictionary<string, Boolean>.Create;
  FParserThreads   := TObjectList<TParserThread>.Create(True);
  FRecordQueue     := TRecordQueue.Create;
  FWriterThread    := TWriterThread.Create(ExtractFilePath(ParamStr(0)) + c_strDatabaseName, FRecordQueue, ABatchSize, FNotifyWnd, function: TParserState begin Result := GetParserState(); end);
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
var
  TaskList : TList<TTaskResult>;
  ActiveCnt: Integer;
begin
  TaskList := TList<TTaskResult>.Create;
  try
    FCrit.Enter;
    try
      ActiveCnt := 0;
      for var I := FParserThreads.Count - 1 downto 0 do
      begin
        var T := FParserThreads[I];
        if T.Finished then
        begin
          var R: TTaskResult;
          R.FileName  := T.FileName;
          R.TableName := T.TableName;
          R.Success   := not T.ErrorOccurred;
          TaskList.Add(R);
          FParserThreads.Delete(I);
        end
        else
          Inc(ActiveCnt);
      end;
      Result.ActiveCount         := ActiveCnt;
      Result.HasAnySubmittedTask := FHasAnySubmitted;
      Result.FinishedTasks       := TaskList.ToArray;
    finally
      FCrit.Leave;
    end;
  finally
    TaskList.Free;
  end;
end;

procedure TTextToSqliteImporter.InternalStop;
var
  Threads: TArray<TParserThread>;
begin
  FCrit.Enter;
  try
    SetLength(Threads, FParserThreads.Count);
    for var I := 0 to FParserThreads.Count - 1 do Threads[I] := FParserThreads[I];
    for var T in Threads do T.Terminate;
  finally
    FCrit.Leave;
  end;
  if Assigned(FWriterThread) then FWriterThread.Terminate;

  for var T in Threads do T.WaitFor;
  if Assigned(FWriterThread) then FWriterThread.WaitFor;

  FCrit.Enter;
  try
    FParserThreads.Clear;
  finally
    FCrit.Leave;
  end;
end;

procedure TTextToSqliteImporter.Stop;
begin
  if FStopped then Exit;
  
  FStopped := True;
  InternalStop;
end;

function TTextToSqliteImporter.AddImportTask(const AFileName, ATableName: string): Boolean;
begin
  Result := False;
  if FStopped then Exit;

  FCrit.Enter;
  try
    if FTaskFiles.ContainsKey(AFileName) then Exit;
    FTaskFiles.Add(AFileName, True);
    FHasAnySubmitted := True;
  finally
    FCrit.Leave;
  end;

  var Thr := TParserThread.Create(AFileName, c_strTableName + '_' + ATableName, FRecordQueue);
  FCrit.Enter;
  try
    FParserThreads.Add(Thr);
  finally
    FCrit.Leave;
  end;
  Thr.Start;

  Result := True;
end;

end.
