unit uMainForm;

interface

uses Winapi.Windows, System.IniFiles, System.SysUtils, System.Variants, System.Classes, System.Types, System.Diagnostics,
     Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, uScrollBar, cv4d, cvtype;

type
  TfrmOpenCV4Delphi = class(TForm)
    img1: TImage;
    mmoLOG: TMemo;
    spl1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    FSB  : TFMScrollBar;
    { 获取 OpenCV 编译信息 }
    procedure OpenCV_getBuildInformation;
    { 显示图片 }
    procedure OpenCV_ShowImage;
  end;

implementation

{$R *.dfm}


procedure TfrmOpenCV4Delphi.FormCreate(Sender: TObject);
begin
  OpenCV_getBuildInformation;
  OpenCV_ShowImage;
end;

procedure TfrmOpenCV4Delphi.FormDestroy(Sender: TObject);
begin
  FSB.Free;
end;

procedure TfrmOpenCV4Delphi.FormActivate(Sender: TObject);
begin
  if FSB = nil then
  begin
    FSB := TFMScrollBar.Create(nil);
    FSB.InitScrollbar(mmoLOG);
  end;
end;


{ 获取 OpenCV 编译信息 }
procedure TfrmOpenCV4Delphi.OpenCV_getBuildInformation;
var
  len : Integer;
begin
  var core := CreateOcvCore;
  try
    var Buffer := Core.GetVersionString(Len);
    if (Buffer <> nil) and (len > 0) then
    begin
      var strBuild := UTF8ToString(AnsiString(PAnsiChar(Buffer)));
      mmoLOG.Lines.Add('OpenCV 版本信息：' + strBuild);
      mmoLOG.Lines.Add('');
      FreeOcvBuffer(Buffer);
    end;

    Buffer := core.GetBuildInformation(len);
    if (Buffer <> nil) and (len > 0) then
    begin
      var strBuild := UTF8ToString(AnsiString(PAnsiChar(Buffer)));
      mmoLOG.Lines.Add('OpenCV 编译信息：');
      mmoLOG.Lines.Add(strBuild.Replace(#$A, #$D#$A, [rfReplaceAll]).Trim);
      FreeOcvBuffer(Buffer);
    end;
  finally
    DestroyOcvCore(core);
  end;
end;

{ 存取类的保护成员变量 }
type
  TBMPAccess         = class(TBitmap);
  TBitmapImageAccess = class(TBitmapImage);

procedure TfrmOpenCV4Delphi.OpenCV_ShowImage;
begin
  with TStopwatch.StartNew do
  begin
    var ImgCodecs := CreateOcvImgCodecs;
    try
      var matImage  := ImgCodecs.Imread(PChar(ExtractFilePath(ParamStr(0)) + 'plugins\java\4K.jpg'), IMREAD_COLOR);
      mmoLOG.Lines.Add(Format('解码用时：%d 毫秒', [ElapsedMilliseconds]));
      var bmpTemp   := TBitmap.Create;
      try
        bmpTemp.PixelFormat := pf32bit;
        bmpTemp.Width       := matImage.GetWidth;
        bmpTemp.Height      := matImage.GetHeight;
        Move(matImage.GetData^, TBitmapImageAccess(TBMPAccess(bmpTemp).FImage).FDIB.dsBm.bmBits^, matImage.GetTotalBytes);
        mmoLOG.Lines.Add(Format('图像大小：%d×%d', [bmpTemp.Width, bmpTemp.Height]));
        img1.Picture.Bitmap.Assign(bmpTemp);
      finally
        bmpTemp.free;
        DestroyOcvMat(matImage);
      end;
    finally
      DestroyOcvImgCodecs(ImgCodecs);
    end;
  end;
end;

end.
