unit Unit2;
{
  多线程 MFT 文件搜索
  如果不开启 USEDATABASE 功能，无法使用搜索功能；
  开始 USEDATABASE 功能，需要使用到数据库，本代码使用 SqlServer 数据库；
}

interface

uses Winapi.Windows, Winapi.Messages, Winapi.ActiveX, System.SysUtils, System.Types, System.Classes,
     {$IFDEF USEDATABASE}
     Data.DB, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
     FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait, FireDAC.Stan.Factory, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
     FireDAC.Comp.DataSet, FireDAC.Comp.Client, FireDAC.Phys.MSSQLDef, FireDAC.Phys.MSSQL,
     {$ENDIF}
     CnAES;

const
  BUF_LEN                    = 1024 * 1024;
  USN_DELETE_FLAG_DELETE     = $00000001;
  WM_SEARCHDRIVEFILEFINISHED = WM_USER + $2000;
  c_iMaxBATCH_SIZE           = 5000;
  c_strDatabaseName          = 'NTFS';
  c_strTableName             = 'FileID';
  c_strAESKey                = 'dbyoung@sina.com';

type
  CREATE_USN_JOURNAL_DATA = record
    MaximumSize: UInt64;
    AllocationDelta: UInt64;
  end;

  USN_JOURNAL_DATA = record
    UsnJournalID: UInt64;
    FirstUsn: Int64;
    NextUsn: Int64;
    LowestValidUsn: Int64;
    MaxUsn: Int64;
    MaximumSize: UInt64;
    AllocationDelta: UInt64;
  end;

  MFT_ENUM_DATA = record
    StartFileReferenceNumber: UInt64;
    LowUsn: Int64;
    HighUsn: Int64;
  end;

  PUSN = ^USN;

  USN = record
    RecordLength: Integer;
    MajorVersion: Word;
    MinorVersion: Word;
    FileReferenceNumber: UInt64;       // 低48位(MFT Record Number):文件在卷主文件表(MFT)中的索引号; 高16位(Sequence Number):序列号，每当一个 MFT 条目被重新分配给新文件时，这个序列号就会递增;
    ParentFileReferenceNumber: UInt64; // 低48位(MFT Record Number):文件在卷主文件表(MFT)中的索引号; 高16位(Sequence Number):序列号，每当一个 MFT 条目被重新分配给新文件时，这个序列号就会递增;
    USN: Int64;
    TimeStamp: LARGE_INTEGER;
    Reason: Cardinal;
    SourceInfo: Cardinal;
    SecurityId: Cardinal;
    FileAttributes: Cardinal;
    FileNameLength: Word;
    FileNameOffset: Word;
    FileName: PWideChar;
  end;

  DELETE_USN_JOURNAL_DATA = record
    UsnJournalID: UInt64;
    DeleteFlags: Cardinal;
  end;

  PFileInfo = ^TFileInfo;

  TFileInfo = record
    intFileID: UInt64;
  end;

type
  TSearchMFT = class(TThread)
  private
    FchrDrive : Char;
    FlstFiles : TList;
    FhMainForm: THandle;
    FhVol     : THandle;
    procedure GetUSNFileInfo(UsnInfo: PUSN);
  private
    {$IFDEF USEDATABASE}
    FstrLink       : string;
    FiCurentCount  : Integer;
    FFDConnection  : TFDConnection;
    FDMSSQLLink    : TFDPhysMSSQLDriverLink;
    FDQuery        : TFDQuery;
    procedure CheckDataBase;
    procedure CreateDataBaseLink;
    procedure InitDatabase;
    procedure SaveToDataBase(const UsnInfo : PUSN);
    procedure FreeDataBase;
    {$ENDIF}
  protected
    procedure Execute; override;
  public
    constructor Create(const chrDriver: Char; hWnd: THandle; lstFiles: TList; hVol: THandle; const strLink : string = '');
    destructor Destroy; override;
  end;

{$IFDEF USEDATABASE}
{ 由主程序调用；所有线程执行完毕后调用一次；只调用一次 }
procedure FinalizeDatabase(const strLink : string);

{ 由主程序调用；解密字符串 }
function DecryptString(const strTemp, strKey: string): String;

{ 由主程序调用；删除数据库 }
function DeleteDataBase(const strLink : string) : Boolean;
{$ENDIF}

implementation

{ TSearchMFT }

{$IFDEF USEDATABASE}

{ 由主程序调用；删除数据库 }
function DeleteDataBase(const strLink : string) : Boolean;
const
  c_SQLScript = 'IF EXISTS (SELECT 1 FROM sys.databases WHERE name = ''' + c_strDatabaseName + ''') '  + sLineBreak +
                'BEGIN '                                                                               + sLineBreak +
                '  ALTER DATABASE ' + c_strDatabaseName + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; ' + sLineBreak +
                '  DROP  DATABASE ' + c_strDatabaseName + '; '                                         + sLineBreak +
                'END; ' ;
var
  Conn            : TFDConnection;
  strProviderName : string;
  strUserName     : string;
  strUserPass     : string;
  strServerIP     : string;
begin
  Result := True;
  strProviderName := strLink.Split([';'])[0];
  strUserName     := strLink.Split([';'])[1];
  strUserPass     := strLink.Split([';'])[2];
  strServerIP     := strLink.Split([';'])[3];
  Conn            := TFDConnection.Create(nil);
  try
    TFDPhysMSSQLConnectionDefParams(Conn.Params).DriverID := 'MSSQL';
    TFDPhysMSSQLConnectionDefParams(Conn.Params).Server   := strServerIP;
    TFDPhysMSSQLConnectionDefParams(Conn.Params).Database := 'master';
    TFDPhysMSSQLConnectionDefParams(Conn.Params).Username := strUserName;
    TFDPhysMSSQLConnectionDefParams(Conn.Params).Password := strUserPass;
    Conn.LoginPrompt  := False;
    Conn.Connected    := True;
    Conn.ExecSQL(c_SQLScript);
  finally
    Conn.Free;
  end;
end;

{ 由主程序调用；解密字符串 }
function DecryptString(const strTemp, strKey: string): String;
begin
  Result := string(AESDecryptEcbStrFromHex(AnsiString(strTemp), AnsiString(strKey)));
end;

{ 由主程序调用；所有线程执行完毕后调用一次；只调用一次 }
procedure FinalizeDatabase(const strLink : string);
var
  Conn            : TFDConnection;
  strProviderName : string;
  strUserName     : string;
  strUserPass     : string;
  strServerIP     : string;
begin
  strProviderName := strLink.Split([';'])[0];
  strUserName     := strLink.Split([';'])[1];
  strUserPass     := strLink.Split([';'])[2];
  strServerIP     := strLink.Split([';'])[3];
  Conn            := TFDConnection.Create(nil);
  try
    TFDPhysMSSQLConnectionDefParams(Conn.Params).DriverID := 'MSSQL';
    TFDPhysMSSQLConnectionDefParams(Conn.Params).Server   := strServerIP;
    TFDPhysMSSQLConnectionDefParams(Conn.Params).Database := c_strDatabaseName;
    TFDPhysMSSQLConnectionDefParams(Conn.Params).Username := strUserName;
    TFDPhysMSSQLConnectionDefParams(Conn.Params).Password := strUserPass;
    Conn.LoginPrompt  := False;
    Conn.Connected    := True;
    Conn.ExecSQL('CREATE NONCLUSTERED INDEX IX_' + c_strTableName + '_ShortName ON dbo.' + c_strTableName + '(ShortName)');
    Conn.ExecSQL('CREATE NONCLUSTERED INDEX IX_' + c_strTableName + '_FullName ON dbo.'  + c_strTableName + '(FullName)');
    Conn.ExecSQL('UPDATE STATISTICS dbo.'        + c_strTableName + ' WITH FULLSCAN');
    Conn.ExecSQL('ALTER DATABASE '    + c_strDatabaseName + ' SET AUTO_CREATE_STATISTICS ON');
    Conn.ExecSQL('ALTER DATABASE '    + c_strDatabaseName + ' SET AUTO_UPDATE_STATISTICS ON');
  finally
    Conn.Free;
  end;
end;
{$ENDIF}

{$IFDEF USEDATABASE}
procedure TSearchMFT.CreateDataBaseLink;
var
  strProviderName : string;
  strUserName     : string;
  strUserPass     : string;
  strServerIP     : string;
begin
  FFDConnection   := TFDConnection.Create(nil);

  strProviderName := FstrLink.Split([';'])[0];
  strUserName     := FstrLink.Split([';'])[1];
  strUserPass     := FstrLink.Split([';'])[2];
  strServerIP     := FstrLink.Split([';'])[3];
  TFDPhysMSSQLConnectionDefParams(FFDConnection.Params).DriverID := 'MSSQL';
  TFDPhysMSSQLConnectionDefParams(FFDConnection.Params).Server   := strServerIP;
  TFDPhysMSSQLConnectionDefParams(FFDConnection.Params).Database := 'master';
  TFDPhysMSSQLConnectionDefParams(FFDConnection.Params).Username := strUserName;
  TFDPhysMSSQLConnectionDefParams(FFDConnection.Params).Password := strUserPass;
  FFDConnection.LoginPrompt  := False;
  FFDConnection.Connected    := True;

  FDMSSQLLink              := TFDPhysMSSQLDriverLink.Create(nil);
  FDMSSQLLink.ODBCDriver   := 'SQL Server';

  InitDatabase;
 end;

procedure TSearchMFT.InitDatabase;
const
  c_strCreateDB  = 'IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N''' + c_strDatabaseName + '''' + ') ' +
      ' BEGIN'                                                                        +
      '   CREATE DATABASE [' + c_strDatabaseName + ']'                                +
      '   ALTER  DATABASE [' + c_strDatabaseName + '] SET RECOVERY SIMPLE'            +
      '   ALTER  DATABASE [' + c_strDatabaseName + '] SET AUTO_CREATE_STATISTICS OFF' +
      '   ALTER  DATABASE [' + c_strDatabaseName + '] SET AUTO_UPDATE_STATISTICS OFF' +
      '   ALTER  DATABASE [' + c_strDatabaseName + '] MODIFY FILE (NAME = ' + c_strDatabaseName + ', SIZE = 4GB, FILEGROWTH = 512MB);' +
      ' END';
  c_strCreateTable = 'IF OBJECT_ID(N'''+ 'dbo.' + c_strTableName + ''', N''U'') IS NULL' +
      ' BEGIN'                                                                       +
      '   CREATE TABLE ' + c_strTableName  + ' ('                                    +
      '     AID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,'                             +
      '     FID DECIMAL(20, 0) NOT NULL,'                                            +
      '     FLow48ID BIGINT, FHig16ID INT,'                                          +
      '     ShortName NVARCHAR(256),'                                                +
      '     IsDir BIT NOT NULL DEFAULT 0,'                                           +
      '     PID DECIMAL(20, 0) NOT NULL,'                                            +
      '     PLow48ID BIGINT, PHig16ID INT,'                                          +
      '     FullName NVARCHAR(512)'                                                  +
      '   ) WITH (DATA_COMPRESSION = PAGE);'                                         +
      ' END';
begin
  // 1. 创建库
  FFDConnection.ExecSQL(c_strCreateDB);

  // 2. 切换到新创建的库
  FFDConnection.Connected       := False;
  FFDConnection.Params.Database := c_strDatabaseName;
  FFDConnection.Connected       := True;

  // 3. 创建表
  try
   FFDConnection.ExecSQL(c_strCreateTable);
  except
  end;

  // 4. 不自动提交，由用户决定什么时候提交数据
  FFDConnection.Connected            := False;
  FFDConnection.TxOptions.AutoCommit := False;
  FFDConnection.Connected            := True;

  // 5. 为插入数据作准备
  FDQuery            := TFDQuery.Create(nil);
  FDQuery.Connection := FFDConnection;

  FDQuery.SQL.Text   := 'INSERT INTO dbo.' + c_strTableName +
      ' (FID, PID, IsDir, ShortName) ' +
      ' VALUES (:FID, :PID, :IsDir, :ShortName)';
  FDQuery.Params[0].DataType := ftLargeint;       // FID       → BIGINT
  FDQuery.Params[1].DataType := ftLargeint;       // PID       → BIGINT
  FDQuery.Params[2].DataType := ftBoolean;        // IsDIr     → Boolaen
  FDQuery.Params[3].DataType := ftWideString;     // ShortName → NVARCHAR(256)
  FDQuery.Params.ArraySize   := c_iMaxBATCH_SIZE;
  FDQuery.Prepare;
end;

procedure TSearchMFT.CheckDataBase;
begin
  FFDConnection := nil;
  FiCurentCount  := 0;

  { 创建数据库连接 }
  CreateDataBaseLink;
end;

procedure TSearchMFT.SaveToDataBase(const UsnInfo: PUSN);
var
  FRN, PID: UInt64;
//  FHig16ID: Integer;
//  FLow48ID: Int64;
//  PHig16ID: Integer;
//  PLow48ID: Int64;
  IsDir   : Boolean;
begin
  var strFileName : string := PWideChar(Integer(UsnInfo) + UsnInfo^.FileNameOffset);
  strFileName     := Copy(strFileName, 1, UsnInfo^.FileNameLength div 2);
  IsDir           := UsnInfo^.FileAttributes and FILE_ATTRIBUTE_DIRECTORY = FILE_ATTRIBUTE_DIRECTORY;
  FRN             := UsnInfo^.FileReferenceNumber;
  PID             := UsnInfo^.ParentFileReferenceNumber;
//  FLow48ID := Int64(FRN and $FFFFFFFFFFFF); // 低48位，0~2^48-1
//  FHig16ID := FRN shr 48;                   // 高16位，0~65535
//  PLow48ID := Int64(PID and $FFFFFFFFFFFF); // 低48位，0~2^48-1
//  PHig16ID := PID shr 48;                   // 高16位，0~65535

  FDQuery.Params[0].AsLargeInts[FiCurentCount]   := FRN;
  FDQuery.Params[1].AsLargeInts[FiCurentCount]   := PID;
  FDQuery.Params[2].AsBooleans[FiCurentCount]    := IsDir;
  FDQuery.Params[3].AsWideStrings[FiCurentCount] := strFileName;
  Inc(FiCurentCount);

  { 一次性提交 c_iMaxBATCH_SIZE 条记录 }
  if FiCurentCount = c_iMaxBATCH_SIZE then
  begin
    FFDConnection.StartTransaction;
    FDQuery.Execute(c_iMaxBATCH_SIZE, 0);
    FFDConnection.Commit;
    FiCurentCount := 0;
  end;
end;

procedure TSearchMFT.FreeDataBase;
begin
  if Assigned(FDQuery) and (FiCurentCount > 0) then
  begin
   FFDConnection.StartTransaction;
   FDQuery.Execute(FiCurentCount, 0);
   FFDConnection.Commit;
   FiCurentCount := 0;
  end;

  if Assigned(FDQuery) then
  begin
    FDQuery.Close;
    FDQuery.Free;
  end;

  if Assigned(FDMSSQLLink) then
  begin
    FDMSSQLLink.Free;
  end;

  if Assigned(FFDConnection) then
  begin
    if FFDConnection.Connected then
      FFDConnection.Connected := False;
    FFDConnection.Free;
  end;
end;

{$ENDIF}

constructor TSearchMFT.Create(const chrDriver: Char; hWnd: THandle; lstFiles: TList; hVol: THandle; const strLink : string = '');
begin
  { DLL 里的工作线程默认栈只有 1MB，而 FDAC 递归/嵌套调用较深，堆栈必须扩大 }
  inherited Create(False, 4 * 1024 * 1024);
  FreeOnTerminate := True;

  FchrDrive  := chrDriver;
  FlstFiles  := lstFiles;
  FhMainForm := hWnd;
  FhVol      := hVol;
  {$IFDEF USEDATABASE}
  FstrLink   := strLink;
  {$ENDIF}
end;

destructor TSearchMFT.Destroy;
begin
  {$IFDEF USEDATABASE}
  FreeDataBase;
  {$ENDIF}
  inherited;
end;

procedure TSearchMFT.Execute;
var
  cjd      : CREATE_USN_JOURNAL_DATA;
  ujd      : USN_JOURNAL_DATA;
  djd      : DELETE_USN_JOURNAL_DATA;
  dwRet    : DWORD;
  int64Size: Integer;
  BufferOut: array [0 .. BUF_LEN - 1] of Char;
  BufferIn : MFT_ENUM_DATA;
  UsnInfo  : PUSN;
  intCount : Integer;
begin
  {$IFDEF USEDATABASE}
  { 检测 SqlServer 数据库是否存在 }
  CheckDataBase;
  {$ENDIF}

  intCount := 0;

  try
    { 初始化USN日志文件 }
    if not DeviceIoControl(FhVol, FSCTL_CREATE_USN_JOURNAL, @cjd, SizeOf(cjd), nil, 0, dwRet, nil) then
      Exit;

    { 获取USN日志基本信息 }
    if not DeviceIoControl(FhVol, FSCTL_QUERY_USN_JOURNAL, nil, 0, @ujd, SizeOf(ujd), dwRet, nil) then
      Exit;

    { 枚举USN日志文件中的所有记录 }
    int64Size                         := SizeOf(Int64);
    BufferIn.StartFileReferenceNumber := 0;
    BufferIn.LowUsn                   := 0;
    BufferIn.HighUsn                  := ujd.NextUsn;
    while DeviceIoControl(FhVol, FSCTL_ENUM_USN_DATA, @BufferIn, SizeOf(BufferIn), @BufferOut, BUF_LEN, dwRet, nil) do
    begin
      { 找到第一个 USN 记录 }
      dwRet   := dwRet - Cardinal(int64Size);
      UsnInfo := PUSN(NativeInt(@(BufferOut)) + int64Size);
      while dwRet > 0 do
      begin
        { 获取文件信息 }
        Inc(intCount);
        GetUSNFileInfo(UsnInfo);

        { 获取下一个 USN 记录 }
        Dec(dwRet, UsnInfo^.RecordLength);
        UsnInfo := PUSN(NativeInt(UsnInfo) + UsnInfo^.RecordLength);
      end;
      Move(BufferOut, BufferIn, int64Size);
    end;

    { 删除USN日志文件信息 }
    djd.UsnJournalID := ujd.UsnJournalID;
    djd.DeleteFlags  := USN_DELETE_FLAG_DELETE;
    DeviceIoControl(FhVol, FSCTL_DELETE_USN_JOURNAL, @djd, SizeOf(djd), nil, 0, dwRet, nil);
  finally
    PostMessage(FhMainForm, WM_SEARCHDRIVEFILEFINISHED, Byte(FchrDrive), intCount);
  end;
end;

procedure TSearchMFT.GetUSNFileInfo(UsnInfo: PUSN);
var
  FileInfo: PFileInfo;
begin
  FileInfo            := AllocMem(SizeOf(TFileInfo));
  FileInfo^.intFileID := UsnInfo^.FileReferenceNumber;
  FlstFiles.Add(FileInfo);

  {$IFDEF USEDATABASE}
  if (not Assigned(FFDConnection)) or (not FFDConnection.Connected) then Exit;
  SaveToDataBase(UsnInfo);
  {$ENDIF}
end;

end.
