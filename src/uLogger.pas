unit uLogger;
{
  功能：非线程安全的日志类；不要在多线程中使用
  作者：dbyoung@sina.com
  时间：2026-09-16
  注意：uLogger 最好是工程文件的首个引用单元
}

interface

uses System.SysUtils, System.Classes, System.Math, System.DateUtils;

type
  TLogLevel = (llDebug, llInfo, llWarn, llError, llFatal, llBlank, llFlush);

  { 非线程安全的日志类 }
  TLogger = class(TObject)
  private
    FmemStringListCache: TStringList;
    FmemStringListMaxCacheLines: Integer;
    FMaxDays: Integer;
    FLogDir: string;
    { 是否开启内存缓存保存到磁盘日志文件 }
    FbMemCacheLogWriteToFile : Boolean;
    { 获取日志文件名 }
    function GetLogFileName: string;
    { 日志文件名的日期合法化检查 }
    function TryParseDate(const DateStr: string; out Date: TDateTime): Boolean;
    { 将文本写入到内存缓存中； 并判别是否到了最大行数限制，或者用户强行指定，将内存文本以追加模式保存到磁盘日志文件中 }
    procedure WriteLogToMemCacheStringList(const strLine: string; const bFlush: Boolean = False);
    { 将内存缓存文本以追加模式保存到磁盘日志文件中 }
    procedure FlushMemStringListCacheToDiskFile;
    { 删除旧的磁盘日志文件 }
    procedure CleanOldLogs;
  public
    constructor Create(const strlogDir: string = ''; const MaxCacheLines: Integer = 500; const MaxDays: Integer = 365);
    destructor Destroy; override;
    procedure Log(const strLog: string = ''; const Level: TLogLevel = llInfo); virtual; { 写文本到内存缓存中 }
    procedure EnableLog(const bEnable: Boolean);                               virtual; { 暂停日志保存       }
  end;

var
  { 已创建好，可以直接使用；DLL 模块中使用 CreateLogger 提供的 Log / EnableLog 两个功能 }
  FLogger : TLogger = nil;

implementation

{ TLogger }

constructor TLogger.Create(const strlogDir: string = ''; const MaxCacheLines: Integer = 500; const MaxDays: Integer = 365);
begin
  inherited Create;
  
  FmemStringListCache         := TStringList.Create;
  FmemStringListMaxCacheLines := MaxCacheLines;
  FMaxDays                    := MaxDays;
  FbMemCacheLogWriteToFile    := True;

  { 创建存放日志文件的磁盘目录 }
  if (Trim(strlogDir).IsEmpty) or (SameText(strlogDir, '.\')) then
    FLogDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + 'Log')
  else if Copy(strlogDir, 1, 2) = '.\' then
    FLogDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + strlogDir.Replace('.\', ''))
  else 
    FLogDir := IncludeTrailingPathDelimiter(strlogDir);
  if not DirectoryExists(FLogDir) then ForceDirectories(FLogDir);
  
  { 删除旧的磁盘日志文件 }
  CleanOldLogs;
end;

destructor TLogger.Destroy;
begin
  { 退出时，将内存文本以追加模式保存到磁盘日志文件中 }
  FlushMemStringListCacheToDiskFile;
  FmemStringListCache.Free;

  inherited;
end;

{ 暂停日志保存 }
procedure TLogger.EnableLog(const bEnable: Boolean);
begin
  FbMemCacheLogWriteToFile := bEnable;
end;

function TLogger.GetLogFileName: string;
begin
  Result := FLogDir + FormatDateTime('yyyy-MM-dd', Now) + '.log';
end;

{ 将内存缓存文本以追加模式保存到磁盘日志文件中 }
procedure TLogger.FlushMemStringListCacheToDiskFile;
	procedure AppendLinesToFile(const strFileName: string; const Lines: TStringList;  Encoding: TEncoding);
	begin
	  var SW := TStreamWriter.Create(strFileName, True, Encoding);
	  try
		  SW.Write(Lines.Text);
	  finally
		  SW.Free;
	  end;
	end;
begin
  if FmemStringListCache.Count = 0 then Exit;

  var SL := TStringList.Create;
  try
    SL.Assign(FmemStringListCache); // 复制到临时列表中
    FmemStringListCache.Clear;      // 清空内存日志列表

   { 将内存文本追加保存到磁盘日志文件中 }
   AppendLinesToFile(GetLogFileName, SL, TEncoding.UTF8);
  finally
    SL.Free;
  end;
end;

{ 将文本写入到内存缓存中； 并判别是否到了最大行数限制，或者用户强行指定，将内存文本以追加模式保存到磁盘日志文件中 }
procedure TLogger.WriteLogToMemCacheStringList(const strLine: string; const bFlush: Boolean = False);
begin
  FmemStringListCache.Add(strLine);
  if (FmemStringListCache.Count >= FmemStringListMaxCacheLines) or bFlush then FlushMemStringListCacheToDiskFile;
end;

{ 日志文件名的日期合法化检查 }
function TLogger.TryParseDate(const DateStr: string; out Date: TDateTime): Boolean;
var
  Year, Month, Day: Word;
  tempDate        : TDateTime;
begin
  Result := False;
  Date := 0;
  if Length(DateStr) <> 10 then Exit;

  try
    Year  := StrToIntDef(Copy(DateStr, 1, 4), 2000);
    Month := StrToIntDef(Copy(DateStr, 6, 2), 1);
    Day   := StrToIntDef(Copy(DateStr, 9, 2), 1);
    if (Month < 1) or (Month > 12) then Exit;

    tempDate := EncodeDate(Year, Month, 1);
    if (Day >= 1) and (Day <= DaysInMonth(tempDate)) then
    begin
      Date   := EncodeDate(Year, Month, Day);
      Result := True;
    end;
  except
    Result := False;
  end;
end;

{ 删除旧的磁盘日志文件 }
procedure TLogger.CleanOldLogs;
var
  SearchRec  : TSearchRec;
  FileDateStr: string;
  FileDate   : TDateTime;
  FileAge    : Integer;
begin
  if FindFirst(FLogDir + '*.log', faAnyFile - faDirectory, SearchRec) = 0 then
  try
    repeat
      FileDateStr := Copy(SearchRec.Name, 1, 10);
      if TryParseDate(FileDateStr, FileDate) then
      begin
        FileAge := DaysBetween(Trunc(Now), FileDate);
        if FileAge > FMaxDays then DeleteFile(FLogDir + SearchRec.Name);
      end;
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
end;

{ 写文本到内存缓存中 }
procedure TLogger.Log(const strLog: string = ''; const Level: TLogLevel = llInfo);
const
  LevelNames: array[TLogLevel] of string = ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL', 'BLANK', 'FLUSH');
var
  strLogLine: string;
begin
  { 是否开启内存缓存保存到磁盘日志文件 }
  if not FbMemCacheLogWriteToFile then Exit;

  { 空行 }
  if (Level = llBlank) or (strLog.IsEmpty) then
    strLogLine := ''
  else 
    strLogLine := Format('[%s] [%s] %s', [FormatDateTime('HH:mm:ss.zzz', Now), LevelNames[Level], strLog]);

  { 文本写入到内存缓存中 }
  WriteLogToMemCacheStringList(strLogLine, Boolean(IfThen(Level = llFlush, 1, 0)));
end;

initialization
  FLogger := TLogger.Create();
  FLogger.Log('程序初始化开始');

finalization
  FLogger.Free;

end.

