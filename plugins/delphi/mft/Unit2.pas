unit Unit2;
{  多线程 MFT 文件搜索 }

interface

uses Winapi.Windows, Winapi.Messages, Winapi.ActiveX, System.SysUtils, System.IOUtils, System.SyncObjs, System.Types, System.Classes, CnAES;

const
  BUF_LEN                    = 1024 * 1024;
  USN_DELETE_FLAG_DELETE     = $00000001;
  WM_SEARCHDRIVEFILEFINISHED = WM_USER + $2000;
  c_iMaxBATCH_LINE           = 50000;

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
    FileReferenceNumber      : UInt64; // 低48位(MFT Record Number):文件在卷主文件表(MFT)中的索引号; 高16位(Sequence Number):序列号，每当一个 MFT 条目被重新分配给新文件时，这个序列号就会递增;
    ParentFileReferenceNumber: UInt64; // 低48位(MFT Record Number):文件在卷主文件表(MFT)中的索引号; 高16位(Sequence Number):序列号，每当一个 MFT 条目被重新分配给新文件时，这个序列号就会递增;
    USN: Int64;
    TimeStamp: LARGE_INTEGER;
    Reason: Cardinal;
    SourceInfo: Cardinal;
    SecurityId: Cardinal;
    FileAttributes: Cardinal;
    FileNameLength: Word;
    FileNameOffset: Word;
    FileName: array [0 .. 0] of WideChar;
  end;

  DELETE_USN_JOURNAL_DATA = record
    UsnJournalID: UInt64;
    DeleteFlags: Cardinal;
  end;

  PFileInfo = ^TFileInfo;
  TFileInfo = packed record
    intFID   : UInt64;
  end;

type
  TSearchMFT = class(TThread)
  private
    FchrDrive : Char;
    FlstFiles : TList;
    FhMainForm: THandle;
    FhVol     : THandle;
    FCritical : TCriticalSection;
    FstrList  : TStringList;
    FFileName : string;
    procedure FlushToFile;
    procedure AppendLinesToFile(const strFileName: string; const Lines: TStringList;  Encoding: TEncoding);
    procedure GetUSNFileInfo(const UsnInfo: PUSN);
  protected
    procedure Execute; override;
  public
    constructor Create(const chrDriver: Char; hWnd: THandle; lstFiles: TList; hVol: THandle);
    destructor Destroy; override;
  end;

implementation

{ TSearchMFT }

constructor TSearchMFT.Create(const chrDriver: Char; hWnd: THandle; lstFiles: TList; hVol: THandle);
begin
  { DLL 里的工作线程默认栈只有 1MB，而 FDAC 递归/嵌套调用较深，堆栈必须扩大 }
  inherited Create(False, 4 * 1024 * 1024);
  FreeOnTerminate := True;

  FchrDrive  := chrDriver;
  FlstFiles  := lstFiles;
  FhMainForm := hWnd;
  FhVol      := hVol;

  FCritical := TCriticalSection.Create;
  FstrList  := TStringList.Create;
  FFileName := TPath.GetTempPath + 'Z' + chrDriver + '.dat';
  if FileExists(FFileName) then DeleteFile(FFileName);
end;

destructor TSearchMFT.Destroy;
begin
  FstrList.Free;
  FCritical.Free;
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
      if Terminated then Break;

      { 找到第一个 USN 记录 }
      dwRet   := dwRet - Cardinal(int64Size);
      UsnInfo := PUSN(NativeInt(@(BufferOut)) + int64Size);
      while dwRet > 0 do
      begin
        if Terminated then Break;

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
    if FstrList.Count > 0 then FlushToFile;
    PostMessage(FhMainForm, WM_SEARCHDRIVEFILEFINISHED, Byte(FchrDrive), intCount);
  end;
end;

procedure TSearchMFT.GetUSNFileInfo(const UsnInfo: PUSN);
var
  FileInfo : PFileInfo;
begin
  FileInfo         := AllocMem(SizeOf(TFileInfo));
  FileInfo^.intFID := UsnInfo^.FileReferenceNumber;
  FlstFiles.Add(FileInfo);

  FCritical.Enter;
  try
    { 添加到内存缓存列表 }
    FstrList.Add(
      UIntToStr(UsnInfo^.ParentFileReferenceNumber) + ';' +
      UIntToStr(UsnInfo^.FileReferenceNumber) + ';' +
      BoolToStr(UsnInfo^.FileAttributes and FILE_ATTRIBUTE_DIRECTORY = FILE_ATTRIBUTE_DIRECTORY) + ';' +
      Copy(PWideChar(NativeInt(UsnInfo) + UsnInfo^.FileNameOffset), 1, UsnInfo^.FileNameLength div 2)
      );

    { 内存缓存到达上限，保存到磁盘文件 }
    if FstrList.Count >= c_iMaxBATCH_LINE then FlushToFile;
  finally
    FCritical.Leave;
  end;
end;

procedure TSearchMFT.FlushToFile;
begin
  var SL := TStringList.Create;
  try
    FCritical.Enter;
    try
      SL.Assign(FstrList); // 复制到临时列表中
      FstrList.Clear;      // 清空内存日志列表
    finally
      FCritical.Leave;
    end;

   	{ 将内存文本追加保存到磁盘日志文件中 }
    FCritical.Enter;
    try
      AppendLinesToFile(FFileName, SL, TEncoding.UTF8);
    finally
      FCritical.Leave;
    end;
  finally
    SL.Free;
  end;
end;

{ 将内存文本追加保存到磁盘日志文件中 }
procedure TSearchMFT.AppendLinesToFile(const strFileName: string; const Lines: TStringList;  Encoding: TEncoding);
var
  SW: TStreamWriter;
begin
  SW := TStreamWriter.Create(strFileName, True, Encoding);
  try
    SW.Write(Lines.Text);
  finally
    SW.Free;
  end;
end;

end.
