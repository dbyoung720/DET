unit OsdWin;

{ OSD 提示窗口
  ------------------------------------------------------------
  一个 WS_EX_LAYERED 顶层 popup 窗口，用来显示「音量 85」这类短暂提示。
  全屏播放时菜单栏/状态栏都隐藏了，没有它调音量就完全没有反馈。

  GDI 画到 32bpp DIB，再用 UpdateLayeredWindow 
  一次性贴上（预乘 alpha），不做 WM_PAINT。
  注意：它是宿主窗体所有的窗口，宿主句柄重建（改 BorderStyle / Menu）
  会连带销毁，所以每次使用前都要用 IsWindow 校验。 }

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, Vcl.Controls, Vcl.Forms;

type
  TOsdWindow = class
  private
    FWnd: HWND;
    FOwner: TWinControl;      // 定位基准（视频面板）
    FText: string;
    FUntil: TDateTime;
    FTopMost: Boolean;
    FW, FH: Integer;          // 上次绘制的尺寸（仅用于重新定位）
    procedure EnsureWindow;
    procedure Render;
    procedure SetTopMost(const Value: Boolean);
  public
    constructor Create(AOwnerControl: TWinControl);
    destructor Destroy; override;
    // 显示一条提示（毫秒后自动消失，靠外部定时器调 Tick）
    procedure ShowText(const AText: string; DurationMs: Integer = 1200);
    procedure Tick;
    procedure Hide;
    // 宿主移动/缩放/切全屏时跟随（提示还在显示的情况下）
    procedure Reposition;
    property TopMost: Boolean read FTopMost write SetTopMost;
    property Handle: HWND read FWnd;
  end;

implementation

const
  OSD_CLASS  = 'LAVPlayerOsdWnd';
  OSD_MARGIN = 24;        // 距画面左上角的边距
  PAD_X      = 16;
  PAD_Y      = 8;

var
  GClassRegistered: Boolean = False;

procedure EnsureWindowClass;
var
  WC: Winapi.Windows.TWndClass;
begin
  if GClassRegistered then Exit;
  FillChar(WC, SizeOf(WC), 0);
  WC.lpfnWndProc   := @Winapi.Windows.DefWindowProc;
  WC.hInstance     := HInstance;
  WC.lpszClassName := PChar(OSD_CLASS);
  Winapi.Windows.RegisterClass(WC);
  GClassRegistered := True;
end;

{ 创建 }
constructor TOsdWindow.Create(AOwnerControl: TWinControl);
begin
  inherited Create;
  FOwner   := AOwnerControl;
  FTopMost := False;
  FWnd := 0;
end;

{ 销毁 }
destructor TOsdWindow.Destroy;
begin
  if (FWnd <> 0) and IsWindow(FWnd) then DestroyWindow(FWnd);
  FWnd := 0;
  inherited;
end;

procedure TOsdWindow.EnsureWindow;
var
  Frm: TCustomForm;
begin
  if (FWnd <> 0) and (not IsWindow(FWnd)) then FWnd := 0;
  if FWnd <> 0 then Exit;
  if (FOwner = nil) or (not FOwner.HandleAllocated) then Exit;
  Frm := GetParentForm(FOwner);
  if (Frm = nil) or (not Frm.HandleAllocated) then Exit;

  EnsureWindowClass;
  FWnd := CreateWindowEx(WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_NOACTIVATE or WS_EX_TOOLWINDOW, PChar(OSD_CLASS), '', WS_POPUP, 0, 0, 8, 8, Frm.Handle, 0, HInstance, nil);
  if FWnd <> 0 then ShowWindow(FWnd, SW_HIDE);
end;

{ 显示 / 隐藏 }
procedure TOsdWindow.ShowText(const AText: string; DurationMs: Integer);
begin
  FText  := AText;
  FUntil := Now + (DurationMs / 86400000);
  Render;
end;

procedure TOsdWindow.Hide;
begin
  FText := '';
  if (FWnd <> 0) and IsWindow(FWnd) then ShowWindow(FWnd, SW_HIDE);
end;

procedure TOsdWindow.Tick;
begin
  if (FText = '') then Exit;
  if Now >= FUntil then Hide;
end;

procedure TOsdWindow.Reposition;
begin
  if (FWnd = 0) or (not IsWindow(FWnd)) or (FText = '') then Exit;
  if (FOwner = nil) or (not FOwner.HandleAllocated) then Exit;
  var P := FOwner.ClientToScreen(Point(OSD_MARGIN, OSD_MARGIN));
  SetWindowPos(FWnd, 0, P.X, P.Y, FW, FH, SWP_NOZORDER or SWP_NOACTIVATE);
end;

procedure TOsdWindow.SetTopMost(const Value: Boolean);
var
  InsertAfter: HWND;
begin
  if FTopMost = Value then Exit;
  FTopMost := Value;
  if (FWnd = 0) or (not IsWindow(FWnd)) then Exit;
  if FTopMost then
    InsertAfter := HWND_TOPMOST
  else
    InsertAfter := HWND_TOP;
  SetWindowPos(FWnd, InsertAfter, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

{ 绘制 }
procedure TOsdWindow.Render;
var
  ScreenDC, MemDC: HDC;
  BI             : TBitmapInfo;
  Bits           : PByte;
  HFnt, OldFont  : HFONT;
  Sz             : TSize;
  Siz            : TSize;
  Blend          : TBlendFunction;
  InsertAfter    : HWND;
  BgAlpha        : Byte;
begin
  EnsureWindow;
  if FWnd = 0 then Exit;
  if FText = '' then
  begin
    ShowWindow(FWnd, SW_HIDE);
    Exit;
  end;

  ScreenDC := GetDC(0);
  try
    // 先量文字尺寸（设置背景透明，避免 GDI 画白底）
    HFnt    := CreateFont(-18, 0, 0, 0, FW_SEMIBOLD, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY,  DEFAULT_PITCH or FF_DONTCARE, 'Microsoft YaHei UI');
    OldFont := SelectObject(ScreenDC, HFnt);
    GetTextExtentPoint32(ScreenDC, PChar(FText), Length(FText), Sz);
    SelectObject(ScreenDC, OldFont);

    var W := Sz.cx + PAD_X * 2;
    var H := Sz.cy + PAD_Y * 2;
    if (W < 40) or (H < 20) then
    begin
      DeleteObject(HFnt);
      Exit;
    end;

    var PixelCount := W * H;
    FW := W;
    FH := H;

    MemDC := CreateCompatibleDC(ScreenDC);
    try
      FillChar(BI, SizeOf(BI), 0);
      BI.bmiHeader.biSize := SizeOf(BITMAPINFOHEADER);
      BI.bmiHeader.biWidth := W;
      BI.bmiHeader.biHeight := -H;     // top-down
      BI.bmiHeader.biPlanes := 1;
      BI.bmiHeader.biBitCount := 32;
      BI.bmiHeader.biCompression := BI_RGB;

      Bits := nil;
      var HBmp := CreateDIBSection(MemDC, BI, DIB_RGB_COLORS, Pointer(Bits), 0, 0);
      if HBmp = 0 then
      begin
        DeleteObject(HFnt);
        Exit;
      end;

	  var OldBmp := SelectObject(MemDC, HBmp);
      try
        // 背景：纯黑 + 半透明（GDI 不写 alpha，先算好底色再让 GDI 只画文字）
        FillChar(Bits^, PixelCount * 4, 0);
        BgAlpha := 200;
        for var i := 0 to PixelCount - 1 do Bits[i * 4 + 3] := BgAlpha;
        SetBkMode(MemDC, TRANSPARENT);
        SetTextColor(MemDC, RGB(255, 255, 255));
        OldFont := SelectObject(MemDC, HFnt);
        TextOut(MemDC, PAD_X, PAD_Y, PChar(FText), Length(FText));
        SelectObject(MemDC, OldFont);

        // 合成预乘 alpha：文字像素（白）不透明，其余保持半透明黑底
        for var i := 0 to PixelCount - 1 do
        begin
          var Idx := i * 4;
          if Bits[Idx] > 96 then
          begin
            Bits[Idx] := 250;
            Bits[Idx + 1] := 250;
            Bits[Idx + 2] := 250;
            Bits[Idx + 3] := 250;
          end
          else
          begin
            Bits[Idx] := 0;
            Bits[Idx + 1] := 0;
            Bits[Idx + 2] := 0;
          end;
        end;

        var P := FOwner.ClientToScreen(Point(OSD_MARGIN, OSD_MARGIN));
        Siz.cx := W;
        Siz.cy := H;
        var PtSrc := Point(0, 0);
        Blend.BlendOp := AC_SRC_OVER;
        Blend.BlendFlags := 0;
        Blend.SourceConstantAlpha := 255;
        Blend.AlphaFormat := AC_SRC_ALPHA;
        UpdateLayeredWindow(FWnd, ScreenDC, @P, @Siz, MemDC, @PtSrc, 0, @Blend, ULW_ALPHA);
      finally
        SelectObject(MemDC, OldBmp);
        DeleteObject(HBmp);
      end;
    finally
      DeleteDC(MemDC);
    end;

    DeleteObject(HFnt);
  finally
    ReleaseDC(0, ScreenDC);
  end;

  if FTopMost then
    InsertAfter := HWND_TOPMOST
  else
    InsertAfter := HWND_TOP;
  SetWindowPos(FWnd, InsertAfter, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
  ShowWindow(FWnd, SW_SHOWNOACTIVATE);
end;

end.
