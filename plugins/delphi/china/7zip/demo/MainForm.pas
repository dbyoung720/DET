unit MainForm;

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.StrUtils, 
     Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.FileCtrl, SevenZip.Static;

type
  TFormMain = class(TForm)
    PanelTop: TPanel;
    lblTitle: TLabel;
    btnOpen: TButton;
    btnExtract: TButton;
    btnSelfTest: TButton;
    ProgressBar1: TProgressBar;
    lvFiles: TListView;
    MemoLog: TMemo;
    OpenDialog1: TOpenDialog;
    procedure btnOpenClick(Sender: TObject);
    procedure btnExtractClick(Sender: TObject);
    procedure btnSelfTestClick(Sender: TObject);
  private
    FArchive: T7zArchive;
    FArchiveFile: string;
    procedure Log(const S: string);
    procedure LoadArchive(const AFileName: string);
  public
    destructor Destroy; override;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

destructor TFormMain.Destroy;
begin
  FreeAndNil(FArchive);
  inherited Destroy;
end;

procedure TFormMain.Log(const S: string);
begin
  MemoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + S);
  MemoLog.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TFormMain.LoadArchive(const AFileName: string);
var
  Stream: TFileStream;
  Bytes: TBytes;
  I: Integer;
  Item: TListItem;
begin
  FreeAndNil(FArchive);
  lvFiles.Items.Clear;
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Bytes, Stream.Size);
    if Length(Bytes) > 0 then
      Stream.ReadBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;

  FArchive := T7zArchive.Create(Bytes);
  FArchiveFile := AFileName;
  for I := 0 to FArchive.Count - 1 do
    begin
      Item := lvFiles.Items.Add;
      Item.Caption := FArchive.Name(I);
      if FArchive.IsDir(I) then
        Item.SubItems.Add('<目录>')
      else
        Item.SubItems.Add(FormatFloat('#,##0', FArchive.Size(I)));
      if FArchive.IsDir(I) then
        Item.SubItems.Add('目录')
      else
        Item.SubItems.Add('文件');
    end;
  Log('已打开：' + AFileName + '，条目数 ' + IntToStr(FArchive.Count));
end;

procedure TFormMain.btnOpenClick(Sender: TObject);
begin
  OpenDialog1.Filter := '7z 压缩包|*.7z|所有文件|*.*';
  if OpenDialog1.Execute then
  try
    LoadArchive(OpenDialog1.FileName);
  except
    on E: Exception do
      Log('打开失败：' + E.Message);
  end;
end;

procedure TFormMain.btnExtractClick(Sender: TObject);
var
  DestDir: string;
begin
  if FArchive = nil then
  begin
    Log('请先打开一个 7z 文件');
    Exit;
  end;
  DestDir := '';
  if not SelectDirectory('选择解压目录', '', DestDir) then
    Exit;
  try
    ProgressBar1.Max := FArchive.Count;
    ProgressBar1.Position := 0;
    FArchive.ExtractAll(DestDir);
    ProgressBar1.Position := ProgressBar1.Max;
    Log('已解压到：' + DestDir);
  except
    on E: Exception do
      Log('解压失败：' + E.Message);
  end;
end;

procedure TFormMain.btnSelfTestClick(Sender: TObject);
var
  Src, Dest, Props, Back: TBytes;
  S: string;
  I: Integer;
begin
  S := '';
  for I := 1 to 200 do
    S := S + '7-Zip C 核心静态链接测试 abcdefghijklmnopqrstuvwxyz ';
  Src := TEncoding.UTF8.GetBytes(S);
  try
    LzmaCompress(Src, 6, Dest, Props);
    Back := LzmaDecompress(Dest, Props, Length(Src));
    Log(Format('LZMA 自测试：%d -> %d 字节，CRC32=%.8x，%s',
      [Length(Src), Length(Dest), Crc32Of(Back),
       IfThen(CompareMem(@Src[0], @Back[0], Length(Src)), '通过', '失败')]));
  except
    on E: Exception do
      Log('LZMA 自测试失败：' + E.Message);
  end;
end;

end.
