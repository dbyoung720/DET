unit SubOverlay;

{ 字幕覆盖层（分层弹出窗口）
  ------------------------------------------------------------
  用 WS_EX_LAYERED 顶层 popup 窗口 + UpdateLayeredWindow 绘制带描边的字幕。
  以视频面板为“宿主”，按宿主客户区在屏幕上的位置/尺寸同步自身窗口。

  Windows 上给 **子窗口** 加 WS_EX_LAYERED 时 CreateWindowEx 会失败,（System Error 1411 / Class does not exist），
  所以这里必须用顶层 popup，而不是 TWinControl 子控件。WS_EX_TRANSPARENT 让鼠标事件穿透到视频窗口。 
}

interface

uses Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Types, Vcl.Graphics, Vcl.Controls, Vcl.Forms;

type
  TSubOverlay = class(TObject)
  private
    FWnd: HWND;
    FOwner: TWinControl;      // 宿主（视频面板）
    FText: string;
    FFontSize: Integer;
    FFontName: string;
    FVisible: Boolean;
    FTopMost: Boolean;
    procedure EnsureWindow;
    procedure UpdateBitmap;
    procedure SetText(const Value: string);
    procedure SetFontSize(const Value: Integer);
    procedure SetFontName(const Value: string);
    procedure SetVisible(const Value: Boolean);
    procedure SetTopMost(const Value: Boolean);
  public
    constructor Create(AOwnerControl: TWinControl);
    destructor Destroy; override;
    // 让覆盖层贴合宿主客户区（屏幕坐标），窗口移动/缩放后需调用
    procedure SyncToParent;
    // 重新绘制字幕位图
    procedure Redraw;
    property Text: string read FText write SetText;
    property FontSize: Integer read FFontSize write SetFontSize;
    property FontName: string read FFontName write SetFontName;
    property Visible: Boolean read FVisible write SetVisible;
    // 全屏时主窗体是置顶的，覆盖层也必须置顶才不会压到画面下面
    property TopMost: Boolean read FTopMost write SetTopMost;
    property Handle: HWND read FWnd;
  end;

implementation

const
  OVERLAY_CLASS     = 'LAVPlayerSubOverlayWnd';
  SUB_MARGIN_BOTTOM = 36;   // 字幕距画面底部的边距（像素）

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
  WC.hCursor       := LoadCursor(0, IDC_ARROW);
  WC.lpszClassName := PChar(OVERLAY_CLASS);
  Winapi.Windows.RegisterClass(WC);
  GClassRegistered := True;
end;

{ 创建 }
constructor TSubOverlay.Create(AOwnerControl: TWinControl);
begin
  inherited Create;
  FOwner    := AOwnerControl;
  FFontSize := 26;
  FFontName := 'Microsoft YaHei UI';
  FWnd      := 0;
  FVisible  := True;
  FTopMost  := False;
end;

{ 销毁 }
destructor TSubOverlay.Destroy;
begin
  if (FWnd <> 0) and IsWindow(FWnd) then
  begin
    DestroyWindow(FWnd);
    FWnd := 0;
  end;
  inherited;
end;

procedure TSubOverlay.EnsureWindow;
var
  Frm: TCustomForm;
begin
  // 宿主窗体句柄重建（改 BorderStyle/Menu/FormStyle 时会发生）会顺带销毁
  // 归它所有的分层窗口，此时 FWnd 变成野句柄，必须丢弃后重新创建
  if (FWnd <> 0) and (not IsWindow(FWnd)) then FWnd := 0;
  if FWnd <> 0 then Exit;
  if FOwner = nil then Exit;
  // 宿主与所属窗体的句柄必须已创建，才能挂 owner
  if not FOwner.HandleAllocated then Exit;
  Frm := GetParentForm(FOwner);
  if (Frm = nil) or (not Frm.HandleAllocated) then Exit;

  EnsureWindowClass;
  FWnd := CreateWindowEx(WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_NOACTIVATE or WS_EX_TOOLWINDOW, PChar(OVERLAY_CLASS), '', WS_POPUP, 0, 0, 8, 8, Frm.Handle, 0, HInstance, nil);
end;

{ 定位 }
procedure TSubOverlay.SyncToParent;
var
  R: TRect;
  P: TPoint;
  InsertAfter: HWND;
begin
  if FOwner = nil then Exit;
  EnsureWindow;
  if FWnd = 0 then Exit;
  if not FOwner.HandleAllocated then Exit;

  R := FOwner.ClientRect;
  if (R.Width <= 0) or (R.Height <= 0) then Exit;

  P := FOwner.ClientToScreen(Point(R.Left, R.Top));
  if FTopMost then
    InsertAfter := HWND_TOPMOST
  else
    InsertAfter := HWND_TOP;
  SetWindowPos(FWnd, InsertAfter, P.X, P.Y, R.Width, R.Height, SWP_NOACTIVATE or SWP_NOOWNERZORDER or SWP_NOCOPYBITS);
end;

{ 属性 }
procedure TSubOverlay.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    UpdateBitmap;
  end;
end;

procedure TSubOverlay.SetFontSize(const Value: Integer);
begin
  var V := Value;
  if V < 10 then V := 10;
  if V > 72 then V := 72;
  if FFontSize <> V then
  begin
    FFontSize := V;
    UpdateBitmap;
  end;
end;

procedure TSubOverlay.SetFontName(const Value: string);
begin
  if FFontName <> Value then
  begin
    FFontName := Value;
    UpdateBitmap;
  end;
end;

procedure TSubOverlay.SetVisible(const Value: Boolean);
begin
  if FVisible = Value then Exit;
  FVisible := Value;
  if FWnd <> 0 then
  begin
    if FVisible then
      ShowWindow(FWnd, SW_SHOWNOACTIVATE)
    else
      ShowWindow(FWnd, SW_HIDE);
  end;
end;

procedure TSubOverlay.SetTopMost(const Value: Boolean);
begin
  if FTopMost = Value then Exit;
  FTopMost := Value;
  SyncToParent;
end;

procedure TSubOverlay.Redraw;
begin
  UpdateBitmap;
end;

{ 绘制 }
procedure TSubOverlay.UpdateBitmap;
var
  ScreenDC, MemDC: HDC;
  BI: TBitmapInfo;
  Bits: PByte;
  HBmp, OldBmp: HBITMAP;
  W, H, PixelCount: Integer;
  HFnt, OldFont: HFONT;
  Sz, ActualSz: TSize;
  Lines: TArray<string>;
  i, LineH, TotalH, X, Y, Outline, OffX, OffY: Integer;
  Blend: TBlendFunction;
  PtSrc: TPoint;
  Siz: TSize;
  R: TRect;
  OutlineMask, TextMask: TBytes;
  Idx, tc, oc, a: Integer;
begin
  EnsureWindow;
  if FWnd = 0 then Exit;
  // 句柄刚重建时尺寸还是 8x8，先与宿主对齐再绘制
  SyncToParent;
  if (FWnd = 0) or (not IsWindow(FWnd)) then Exit;

  FillChar(R, SizeOf(R), 0);
  GetClientRect(FWnd, R);
  W := R.Right - R.Left;
  H := R.Bottom - R.Top;
  if (W <= 0) or (H <= 0) then Exit;

  PixelCount := W * H;

  ScreenDC := GetDC(0);
  MemDC := CreateCompatibleDC(ScreenDC);
  try
    FillChar(BI, SizeOf(BI), 0);
    BI.bmiHeader.biSize := SizeOf(BITMAPINFOHEADER);
    BI.bmiHeader.biWidth := W;
    BI.bmiHeader.biHeight := -H;      // top-down
    BI.bmiHeader.biPlanes := 1;
    BI.bmiHeader.biBitCount := 32;
    BI.bmiHeader.biCompression := BI_RGB;

    Bits := nil;
    HBmp := CreateDIBSection(MemDC, BI, DIB_RGB_COLORS, Pointer(Bits), 0, 0);
    if HBmp = 0 then Exit;
    OldBmp := SelectObject(MemDC, HBmp);
    try
      FillChar(Bits^, PixelCount * 4, 0);   // 全透明

      if FText <> '' then
      begin
        HFnt := CreateFont(-FFontSize, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY, DEFAULT_PITCH or FF_DONTCARE, PChar(FFontName));
        OldFont := SelectObject(MemDC, HFnt);
        SetBkMode(MemDC, TRANSPARENT);
        // GDI 只写 RGB、不写 alpha，所以先用白色画“覆盖率遮罩”，再自己合成 alpha
        SetTextColor(MemDC, RGB(255, 255, 255));

        Lines := FText.Replace(#13#10, #10).Split([#10]);
        GetTextExtentPoint32(MemDC, '字', 1, ActualSz);
        LineH := (ActualSz.cy * 118) div 100;
        TotalH := LineH * Length(Lines);
        Y := H - SUB_MARGIN_BOTTOM - TotalH;
        if Y < 0 then Y := 0;
        Outline := 2 + FFontSize div 14;

        // 第 1 遍：描边遮罩
        for i := 0 to High(Lines) do
          if Lines[i] <> '' then
          begin
            GetTextExtentPoint32(MemDC, PChar(Lines[i]), Length(Lines[i]), Sz);
            X := (W - Sz.cx) div 2;
            if X < 0 then X := 0;
            for OffY := -Outline to Outline do
              for OffX := -Outline to Outline do
                if (OffX <> 0) or (OffY <> 0) then
                  TextOut(MemDC, X + OffX, Y + i * LineH + OffY, PChar(Lines[i]), Length(Lines[i]));
          end;

        SetLength(OutlineMask, PixelCount);
        for i := 0 to PixelCount - 1 do
          OutlineMask[i] := Bits[i * 4];      // R 通道 = 覆盖率

        // 第 2 遍：正文遮罩
        FillChar(Bits^, PixelCount * 4, 0);
        for i := 0 to High(Lines) do
          if Lines[i] <> '' then
          begin
            GetTextExtentPoint32(MemDC, PChar(Lines[i]), Length(Lines[i]), Sz);
            X := (W - Sz.cx) div 2;
            if X < 0 then X := 0;
            TextOut(MemDC, X, Y + i * LineH, PChar(Lines[i]), Length(Lines[i]));
          end;

        SetLength(TextMask, PixelCount);
        for i := 0 to PixelCount - 1 do TextMask[i] := Bits[i * 4];

        // 合成预乘 alpha（UpdateLayeredWindow + AC_SRC_ALPHA 要求预乘）：
        //   文字覆盖 ≥ 描边覆盖 → 白色字；否则 → 黑色描边
        for i := 0 to PixelCount - 1 do
        begin
          Idx := i * 4;
          tc := TextMask[i];
          oc := OutlineMask[i];
          if tc >= oc then
            a := tc
          else
            a := oc;
          if a = 0 then
          begin
            Bits[Idx] := 0;
            Bits[Idx + 1] := 0;
            Bits[Idx + 2] := 0;
          end
          else if tc >= oc then
          begin
            Bits[Idx] := a;         // 白色（预乘）
            Bits[Idx + 1] := a;
            Bits[Idx + 2] := a;
          end
          else
          begin
            Bits[Idx] := 0;         // 黑色描边
            Bits[Idx + 1] := 0;
            Bits[Idx + 2] := 0;
          end;
          Bits[Idx + 3] := a;
        end;

        SelectObject(MemDC, OldFont);
        DeleteObject(HFnt);
      end;

      Blend.BlendOp := AC_SRC_OVER;
      Blend.BlendFlags := 0;
      Blend.SourceConstantAlpha := 255;
      Blend.AlphaFormat := AC_SRC_ALPHA;
      PtSrc := Point(0, 0);
      Siz.cx := W;
      Siz.cy := H;
      // pptDst = nil：保持窗口当前位置，只更新内容
      UpdateLayeredWindow(FWnd, ScreenDC, nil, @Siz, MemDC, @PtSrc, 0,  @Blend, ULW_ALPHA);
    finally
      SelectObject(MemDC, OldBmp);
      DeleteObject(HBmp);
    end;
  finally
    DeleteDC(MemDC);
    ReleaseDC(0, ScreenDC);
  end;

  if FVisible then ShowWindow(FWnd, SW_SHOWNOACTIVATE);
end;

end.
