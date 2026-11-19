unit uProps;

{ 图像属性对话框: 显示文件系统信息与 WIC 读出的图像尺寸/帧数 }

interface

uses Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, 
     Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ValEdit, Vcl.Graphics, Vcl.Clipbrd, uImageKit;

type
  TPropsForm = class(TForm)
    PanelBottom: TPanel;
    btnOK: TButton;
    btnCopy: TButton;
    vle: TValueListEditor;
    procedure btnCopyClick(Sender: TObject);
  private
    FFileName: string;
    procedure FillInfo;
    procedure ApplyDarkTheme;
  end;

procedure ShowImageProperties(AOwner: TComponent; const AFileName: string);

implementation

{$R *.dfm}

type
  TButtonColorAccess = class(TButton);

procedure TPropsForm.ApplyDarkTheme;
var
  I: Integer;
begin
  { Dark look without VCL Styles: native colors and no themed client area }
  Color := TColor($181818);
  Font.Color := clWhite;
  PanelBottom.ParentBackground := False;
  PanelBottom.StyleElements := [];
  PanelBottom.Color := TColor($202020);
  for I := 0 to ComponentCount - 1 do
  begin
    if Components[I] is TLabel then
    begin
      TLabel(Components[I]).StyleElements := [];
      TLabel(Components[I]).Font.Color := clWhite;
    end
    else if Components[I] is TButton then
    begin
      TButton(Components[I]).StyleElements := [];
      TButtonColorAccess(Components[I]).Color := TColor($1C1C1C);
      TButton(Components[I]).Font.Color := clWhite;
    end;
  end;
  vle.Color := TColor($242120);
  vle.FixedColor := TColor($202020);
  vle.Font.Color := clWhite;
  EnableImmersiveDarkMode(True);
end;

procedure ShowImageProperties(AOwner: TComponent; const AFileName: string);
var
  F: TPropsForm;
begin
  F := TPropsForm.Create(AOwner);
  try
    F.ApplyDarkTheme;
    F.FFileName := AFileName;
    F.Caption := '图像属性 - ' + ExtractFileName(AFileName);
    F.FillInfo;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TPropsForm.btnCopyClick(Sender: TObject);
var
  I: Integer;
  S, K: string;
begin
  S := '';
  for I := 1 to vle.RowCount - 1 do
  begin
    K := vle.Keys[I];
    if K <> '' then S := S + K + ': ' + vle.Values[K] + sLineBreak;
  end;
  Clipboard.AsText := S;
end;

procedure TPropsForm.FillInfo;
var
  W: TWICImage;
  P: TBitmap;
  E, S: string;
  A: Cardinal;
  Sz: Int64;
begin
  E := UpperCase(ExtractFileExt(FFileName));
  if (E <> '') and (E[1] = '.') then Delete(E, 1, 1);
  vle.Values['文件名'] := ExtractFileName(FFileName);
  if E <> '' then
    vle.Values['文件类型'] := E + ' 图像文件'
  else
    vle.Values['文件类型'] := '图像文件';
  vle.Values['所在文件夹'] := ExtractFileDir(FFileName);
  vle.Values['完整路径'] := FFileName;

  try
    Sz := TFile.GetSize(FFileName);
    vle.Values['文件大小'] := Format('%s (%s 字节)', [FormatFileSize(Sz), FormatFloat('#,##0', Sz)]);
  except
    vle.Values['文件大小'] := '无法读取';
  end;
  try
    vle.Values['创建时间'] := FormatDateTime('yyyy-mm-dd hh:nn:ss', TFile.GetCreationTime(FFileName));
  except
    vle.Values['创建时间'] := '-';
  end;
  try
    vle.Values['修改时间'] := FormatDateTime('yyyy-mm-dd hh:nn:ss', TFile.GetLastWriteTime(FFileName));
  except
    vle.Values['修改时间'] := '-';
  end;

  W := nil;
  P := nil;
  try
    W := TWICImage.Create;
    W.LoadFromFile(FFileName);
    vle.Values['图像尺寸'] := Format('%d x %d 像素', [W.Width, W.Height]);
    vle.Values['帧数'] := IntToStr(W.FrameCount);
    vle.Values['解码方式'] := 'Windows WIC (TWICImage)';
  except
    { WIC 不支持的格式 (QOI 等) 用 TPicture 回退 }
    P := DecodeViaPicture(FFileName);
    if P <> nil then
    begin
      vle.Values['图像尺寸'] := Format('%d x %d 像素', [P.Width, P.Height]);
      vle.Values['帧数'] := '1';
      vle.Values['解码方式'] := 'VCL TPicture (QOI 等)';
    end
    else
    begin
      vle.Values['图像尺寸'] := '无法读取';
      vle.Values['帧数'] := '-';
      vle.Values['解码方式'] := '不支持的图像格式';
    end;
  end;
  P.Free;
  W.Free;

  S := '';
  try
    A := GetFileAttributes(PChar(FFileName));
    if A <> INVALID_FILE_ATTRIBUTES then
    begin
      if A and FILE_ATTRIBUTE_READONLY <> 0 then S := S + '只读 ';
      if A and FILE_ATTRIBUTE_HIDDEN <> 0 then S := S + '隐藏 ';
      if A and FILE_ATTRIBUTE_SYSTEM <> 0 then S := S + '系统 ';
      if A and FILE_ATTRIBUTE_ARCHIVE <> 0 then S := S + '存档 ';
      if A and FILE_ATTRIBUTE_NORMAL <> 0 then S := S + '普通 ';
    end;
  except
    S := '';
  end;
  if Trim(S) = '' then  S := '-';
  vle.Values['文件属性'] := Trim(S);
end;

end.
