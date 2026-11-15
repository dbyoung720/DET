unit uTabView;
{ Chrome 风格的 TTabView }

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.GDIPAPI, Winapi.GDIPOBJ, System.SysUtils, System.Classes, System.Math, System.StrUtils, System.Types, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls, Vcl.TabView, Vcl.ViewCtrlUtil, Vcl.GraphUtil, Vcl.Buttons, Vcl.ImgList, Vcl.TitleBarCtrls;

type
  TTabViewTab  = Vcl.TabView.TTabViewTab;
  TTabViewTabs = Vcl.TabView.TTabViewTabs;

  TChromeViewButton = class(TViewControlButton)
  protected
    procedure Paint; override;
  end;

  TTabPage = class;
  TTabView = class;

  { Chrome 风格页签控件 }
  TTabView = class(Vcl.TabView.TTabView)
  private
    FHotIndex: Integer;
    FPressedIndex: Integer;
    FDragTab: TTabViewTab;
    FDragging: Boolean;
    FDragStartX: Integer;
    FClosePressed: Boolean;
    procedure SetHotIndex(AValue: Integer);
  protected
    function GetButtonClass: TViewControlButtonClass; override;
    function GetTabWidth(ATab: TTabViewTab): Integer; override;
    function GetCloseButtonRect(ARect: TRect): TRect; override;
    procedure DrawBackground(ACanvas: TCanvas); override;
    procedure DrawTab(ACanvas: TCanvas; AIndex: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  public
    constructor Create(AOwner: TComponent); override;
    { 新建一个页签，并与页签内容控件绑定；返回新建的页签 }
    function AddTabPage(APage: TControl; const ACaption: string; AImageIndex: Integer = -1): TTabViewTab;
    { 显示指定页签的内容容器，其余隐藏；ATab 为 nil 时全部隐藏 }
    procedure ShowPage(ATab: TTabViewTab);
  end;

  { 页签内容容器；承载 DLL / EXE 子窗体 }
  TTabPage = class(TPanel)
  private
    FTab: TTabViewTab;
    FTabView: TTabView;
    FDisabledIndex: NativeInt;
    FData: TObject;
    function  GetImageIndex: System.UITypes.TImageIndex;
    procedure SetImageIndex(AValue: System.UITypes.TImageIndex);
  public
    constructor Create(AOwner: TComponent); override;
    property Tab: TTabViewTab read FTab write FTab;
    property TabView: TTabView read FTabView write FTabView;
    { 模块窗体句柄；-1 表示尚未加载 }
    property DisabledIndex: NativeInt read FDisabledIndex write FDisabledIndex;
    { 页签关联的数据对象（DLL 模块窗体） }
    property Data: TObject read FData write FData;
  published
    property ImageIndex: System.UITypes.TImageIndex read GetImageIndex write SetImageIndex default -1;
  end;

const
  cTabTextLeft      = 14;
  cTabIconSize      = 17;
  cTabIconGap       = 9;
  cTabTextRight     = 12;
  cTabCloseSpace    = 30;
  cTabMinWidth      = 200;
  cTabMaxWidth      = 252;

  cTitleBarHeight   = 45;
  cCaptionAreaWidth = 200;

  // Chrome dark palette. TColor is $00BBGGRR.
  CH_BG            : TColor = $0020201F; // $00242120; // #202124
  CH_BG_DEEP       : TColor = $001A1817; // #17181A
  CH_PANEL         : TColor = $00262423; // #232426
  CH_TAB_ACTIVE    : TColor = $002B2B2B; // #2B2B2B
  CH_TAB_HOVER     : TColor = $00754619; // $754619
  CH_TAB_PRESSED   : TColor = $0043403C; // #3C4043
  CH_CARD          : TColor = $002E2A29; // #292A2E
  CH_CARD_LINE     : TColor = $00423D3A; // #3A3D42
  CH_LINE          : TColor = $003B3835; // #35383B
  CH_TEXT          : TColor = $00F4F3F1; // #F1F3F4
  CH_TEXT_DIM      : TColor = $00A6A09A; // #9AA0A6
  CH_TEXT_MUTED    : TColor = $00857F7A; // #7A7F85
  CH_BLUE          : TColor = $00F8B48A; // #8AB4F8
  CH_GREEN         : TColor = $0095C981; // #81C995
  CH_YELLOW        : TColor = $0063D6FD; // #FDD663
  CH_RED           : TColor = $00828BF2; // #F28B82
  CH_WHITE         : TColor = $00FFFFFF;
  CH_CLOSE_HOVER   : TColor = $0068635F; // #5F6368
  CH_CLOSE_DOWN    : TColor = $00857F7A; // #7A7F85
  CH_STROKE        : TColor = $00514D4A; // #4A4D51
  CH_CLOSE_ICON    : TColor = $00C2BDB8; // #B8BDC2

implementation

function GPColor(Color: TColor; Alpha: Byte): ARGB;
begin
  Result := MakeColor(Alpha, GetRValue(Color), GetGValue(Color), GetBValue(Color));
end;

function BlendColor(const C1, C2: TColor; Pct: Integer): TColor;
var
  P: Integer;
begin
  P := EnsureRange(Pct, 0, 100);
  Result := TColor(RGB(
    (GetRValue(C1) * (100 - P) + GetRValue(C2) * P) div 100,
    (GetGValue(C1) * (100 - P) + GetGValue(C2) * P) div 100,
    (GetBValue(C1) * (100 - P) + GetBValue(C2) * P) div 100));
end;

procedure AddRoundRectPath(Path: TGPGraphicsPath; const R: TGPRectF; Radius: Single);
begin
  var D := Radius * 2;
  if D > R.Width then D := R.Width;
  if D > R.Height then D := R.Height;
  if D < 1 then D := 1;

  Path.StartFigure;
  Path.AddArc(R.X, R.Y, D, D, 180, 90);
  Path.AddArc(R.X + R.Width - D, R.Y, D, D, 270, 90);
  Path.AddArc(R.X + R.Width - D, R.Y + R.Height - D, D, D, 0, 90);
  Path.AddArc(R.X, R.Y + R.Height - D, D, D, 90, 90);
  Path.CloseFigure;
end;

procedure ChromeFillRoundRect(ACanvas: TCanvas; const R: TRect; Radius: Integer; Color: TColor; Alpha: Byte = 255);
var
  RF: TGPRectF;
begin
  if (R.Width <= 0) or (R.Height <= 0) then Exit;
  var G := TGPGraphics.Create(ACanvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    var B := TGPSolidBrush.Create(GPColor(Color, Alpha));
    try
      var P := TGPGraphicsPath.Create;
      try
        RF.X := R.Left;
        RF.Y := R.Top;
        RF.Width := R.Width;
        RF.Height := R.Height;
        AddRoundRectPath(P, RF, Radius);
        G.FillPath(B, P);
      finally
        P.Free;
      end;
    finally
      B.Free;
    end;
  finally
    G.Free;
  end;
end;

procedure AddOutwardBottomRoundRectPath(Path: TGPGraphicsPath; const R: TGPRectF; Radius: Single);
begin
  var D := Radius * 2;
  if D > R.Width then D := R.Width;
  if D > R.Height then D := R.Height;
  if D < 1 then D := 1;
  Radius := D / 2;
  var Outset := Radius * 3 / 4;
  var Right := R.X + R.Width;
  var Bottom := R.Y + R.Height;

  Path.StartFigure;
  Path.AddArc(R.X, R.Y, D, D, 180, 90);
  Path.AddArc(Right - D, R.Y, D, D, 270, 90);
  Path.AddLine(Right, R.Y + Radius, Right, Bottom - Radius);
  Path.AddBezier(Right, Bottom - Radius, Right, Bottom - Radius / 3, Right + Outset * 2 / 3, Bottom, Right + Outset, Bottom);
  Path.AddLine(Right + Outset, Bottom, R.X - Outset, Bottom);
  Path.AddBezier(R.X - Outset, Bottom, R.X - Outset * 2 / 3, Bottom, R.X, Bottom - Radius / 3, R.X, Bottom - Radius);
  Path.AddLine(R.X, Bottom - Radius, R.X, R.Y + Radius);
  Path.CloseFigure;
end;

procedure ChromeFillOutwardBottomRoundRect(ACanvas: TCanvas; const R: TRect; Radius: Integer; Color: TColor; Alpha: Byte);
var
  RF: TGPRectF;
begin
  if (R.Width <= 0) or (R.Height <= 0) then Exit;
  var G := TGPGraphics.Create(ACanvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    var B := TGPSolidBrush.Create(GPColor(Color, Alpha));
    try
      var P := TGPGraphicsPath.Create;
      try
        RF.X := R.Left;
        RF.Y := R.Top;
        RF.Width := R.Width;
        RF.Height := R.Height;
        AddOutwardBottomRoundRectPath(P, RF, Radius);
        G.FillPath(B, P);
      finally
        P.Free;
      end;
    finally
      B.Free;
    end;
  finally
    G.Free;
  end;
end;

procedure AddTopRoundRectPath(Path: TGPGraphicsPath; const R: TGPRectF; Radius: Single);
begin
  var D := Radius * 2;
  if D > R.Width then D := R.Width;
  if D > R.Height then D := R.Height;
  if D < 1 then D := 1;

  Path.StartFigure;
  Path.AddArc(R.X, R.Y, D, D, 180, 90);
  Path.AddArc(R.X + R.Width - D, R.Y, D, D, 270, 90);
  Path.AddLine(R.X + R.Width, R.Y + R.Height, R.X, R.Y + R.Height);
  Path.CloseFigure;
end;

procedure ChromeFillTopRoundRect(ACanvas: TCanvas; const R: TRect; Radius: Integer; Color: TColor; Alpha: Byte);
var
  RF: TGPRectF;
begin
  if (R.Width <= 0) or (R.Height <= 0) then Exit;
  var G := TGPGraphics.Create(ACanvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    var B := TGPSolidBrush.Create(GPColor(Color, Alpha));
    try
      var P := TGPGraphicsPath.Create;
      try
        RF.X := R.Left;
        RF.Y := R.Top;
        RF.Width := R.Width;
        RF.Height := R.Height;
        AddTopRoundRectPath(P, RF, Radius);
        G.FillPath(B, P);
      finally
        P.Free;
      end;
    finally
      B.Free;
    end;
  finally
    G.Free;
  end;
end;

procedure ChromeFillCircle(ACanvas: TCanvas; const R: TRect; Color: TColor; Alpha: Byte);
begin
  if (R.Width <= 0) or (R.Height <= 0) then Exit;
  var G := TGPGraphics.Create(ACanvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    var B := TGPSolidBrush.Create(GPColor(Color, Alpha));
    try
      G.FillEllipse(B, MakeRect(Single(R.Left), Single(R.Top), Single(R.Width), Single(R.Height)));
    finally
      B.Free;
    end;
  finally
    G.Free;
  end;
end;

procedure ChromeDrawCloseButton(ACanvas: TCanvas; const R: TRect; Hover, Pressed: Boolean; IconColor: TColor);
var
  B: TGPSolidBrush;
begin
  if (R.Width <= 0) or (R.Height <= 0) then Exit;

  var G := TGPGraphics.Create(ACanvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    if Hover or Pressed then
    begin
      B := TGPSolidBrush.Create(GPColor(IfThen(Pressed, CH_CLOSE_DOWN, CH_CLOSE_HOVER), 255));
      try
        G.FillEllipse(B, MakeRect(Single(R.Left), Single(R.Top), Single(R.Width), Single(R.Height)));
      finally
        B.Free;
      end;
    end;

    var C := R.CenterPoint;
    var D := Max(3, R.Width div 4);
    var P := TGPPen.Create(GPColor(IconColor, 255), Max(1.2, R.Width / 12));
    try
      P.SetStartCap(LineCapRound);
      P.SetEndCap(LineCapRound);
      G.DrawLine(P, C.X - D, C.Y - D, C.X + D, C.Y + D);
      G.DrawLine(P, C.X + D, C.Y - D, C.X - D, C.Y + D);
    finally
      P.Free;
    end;
  finally
    G.Free;
  end;
end;

{ TChromeViewButton }

procedure TChromeViewButton.Paint;
begin
  var LColor := IfThen(not Enabled, CH_TEXT_MUTED, CH_TEXT);
  var R      := ClientRect;
  InflateRect(R, -1, -1);
  if MouseInControl then ChromeFillRoundRect(Canvas, R, 5, IfThen(FState in [bsDown, bsExclusive], CH_CLOSE_DOWN, CH_TAB_PRESSED),  255);

  case ButtonStyle of
    vcbsAdd:         DrawAddIcon(Canvas, ClientRect, LColor, 10, CurrentPPI);
    vcbsScrollLeft:  DrawModernArrow(Canvas, sdLeft, ClientRect, LColor, 10, CurrentPPI);
    vcbsScrollRight: DrawModernArrow(Canvas, sdRight, ClientRect, LColor, 10, CurrentPPI);
    vcbsScrollUp:    DrawModernArrow(Canvas, sdUp, ClientRect, LColor, 10, CurrentPPI);
    vcbsScrollDown:  DrawModernArrow(Canvas, sdDown, ClientRect, LColor, 10, CurrentPPI);
  else
    inherited;
  end;
end;

{ TTabView }

constructor TTabView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHotIndex                    := -1;
  FPressedIndex                := -1;
  FDragging                    := False;
  DoubleBuffered               := True;
  ParentFont                   := False;
  Color                        := CH_BG;
  Font.Name                    := 'Microsoft YaHei UI';
  Font.Size                    := 12;
  Font.Quality                 := fqAntialiased;
  ForegroundColor              := CH_TEXT;
  TabOptions.Draggable         := True;
  TabOptions.ShowCloseButton   := True;
  TabOptions.ShowHints         := False;
  TabOptions.WordWrap          := False;
  ShowAddTabButton             := False;
  ShowTabsMenuButton           := False;
  ShowBottomLine               := False;
  BackgroundHitTestTransparent := False;
  MouseWheelScroll             := True;
  TabMinWidth                  := 200;
  TabMaxWidth                  := 252;
end;

procedure TTabView.DrawBackground(ACanvas: TCanvas);
begin
  var R := ClientRect;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := Color;
  ACanvas.FillRect(R);
end;

procedure TTabView.DrawTab(ACanvas: TCanvas; AIndex: Integer);
var
  LActive                           : Boolean;
  LFill, LTextColor, LCloseIconColor: TColor;
begin
  if (AIndex < 0) or (AIndex >= Tabs.Count) then Exit;

  var LTab := Tabs[AIndex];
  if FDragging and (FDragTab <> nil) then
    LActive := LTab = FDragTab
  else
    LActive := AIndex = TabIndex;

  var LHot     := (not LActive) and (AIndex = FHotIndex);
  var LPressed := AIndex = FPressedIndex;

  if LActive then
  begin
    LFill := CH_TAB_ACTIVE;
    if LPressed and not FClosePressed then LFill := BlendColor(CH_TAB_ACTIVE, CH_BG_DEEP, 26);
  end
  else if LPressed then
    LFill := CH_TAB_PRESSED
  else if LHot then
    LFill := CH_TAB_HOVER
  else
    LFill := Color;

  var R := LTab.BoundsRect;
  Inc(R.Left, ScaleValue(2));
  Dec(R.Right, ScaleValue(2));
  Inc(R.Top, ScaleValue(4));
  var LRadius := ScaleValue(10);

  if LActive then ChromeFillOutwardBottomRoundRect(ACanvas, R, LRadius, LFill, 255);
  if not LActive and (LHot or LPressed) then
  begin
    var HoverR := LTab.BoundsRect;
    InflateRect(HoverR, -ScaleValue(4), -ScaleValue(4));
    OffsetRect(HoverR, 0, -ScaleValue(2));
    ChromeFillRoundRect(ACanvas, HoverR, ScaleValue(8), LFill, 255);
  end;

  if LActive then
  begin
    ACanvas.Pen.Color := BlendColor(LFill, CH_WHITE, 12);
    ACanvas.Pen.Width := 1;
    ACanvas.MoveTo(R.Left + LRadius, R.Top + 1);
    ACanvas.LineTo(R.Right - LRadius, R.Top + 1);
  end
  else if not LHot then
  begin
    var LNextActive := (AIndex + 1 = TabIndex);
    var LNextHot    := (AIndex + 1 = FHotIndex);
    if (AIndex < Tabs.Count - 1) and not LNextActive and not LNextHot then
    begin
      ACanvas.Pen.Color := CH_LINE;
      ACanvas.Pen.Width := 1;
      ACanvas.MoveTo(R.Right + ScaleValue(2), R.Top + ScaleValue(12));
      ACanvas.LineTo(R.Right + ScaleValue(2), R.Bottom - ScaleValue(11));
    end;
  end;

  LTextColor := IfThen(LActive or LHot, CH_TEXT, CH_TEXT_DIM);
  ACanvas.Font.Assign(Font);
  ACanvas.Font.Color   := LTextColor;
  ACanvas.Font.Style   := [];
  ACanvas.Font.Quality := fqAntialiased;
  ACanvas.Brush.Style  := bsClear;
  SetBkMode(ACanvas.Handle, 1);

  var LContentLeft  := R.Left + ScaleValue(cTabTextLeft);
  var LContentRight := R.Right - ScaleValue(cTabCloseSpace);
  var LTextWidth    := Min(ACanvas.TextWidth(LTab.Caption), Max(0, LContentRight - LContentLeft - ScaleValue(cTabIconSize + cTabIconGap)));
  var LGroupWidth   := ScaleValue(cTabIconSize + cTabIconGap) + LTextWidth;
  var LGroupLeft    := LContentLeft + (LContentRight - LContentLeft - LGroupWidth) div 2;

  var IconR := Rect(
    LGroupLeft,
    LTab.BoundsRect.CenterPoint.Y - ScaleValue(cTabIconSize) div 2,
    LGroupLeft + ScaleValue(cTabIconSize),
    LTab.BoundsRect.CenterPoint.Y - ScaleValue(cTabIconSize) div 2 + ScaleValue(cTabIconSize));

  { 有模块图标时绘制图标，否则退回色块 + 圆点占位 }
  if (Images <> nil) and (LTab.ImageIndex >= 0) and (LTab.ImageIndex < Images.Count) then
    Images.Draw(ACanvas, IconR.Left + (IconR.Width  - Images.Width)  div 2, IconR.Top  + (IconR.Height - Images.Height) div 2, LTab.ImageIndex)
  else
  begin
    var LIconColor := CH_BLUE;
    ChromeFillRoundRect(ACanvas, IconR, ScaleValue(5), LIconColor, 255);
    var DotR := Rect(0, 0, ScaleValue(5), ScaleValue(5));
    OffsetRect(DotR, IconR.CenterPoint.X - DotR.Width div 2, IconR.CenterPoint.Y - DotR.Height div 2);
    ChromeFillCircle(ACanvas, DotR, CH_WHITE, 235);
  end;

  var TextR    := R;
  TextR.Left   := IconR.Right + ScaleValue(cTabIconGap);
  TextR.Right  := TextR.Left + LTextWidth;
  TextR.Top    := LTab.BoundsRect.Top;
  TextR.Bottom := LTab.BoundsRect.Bottom;

  var LFlags   := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX;
  var LTextTop := (TextR.Top + TextR.Bottom - ACanvas.TextHeight(LTab.Caption)) div 2;
  TextR.Top    := LTextTop;
  TextR.Bottom := LTextTop + ACanvas.TextHeight(LTab.Caption);
  DrawText(ACanvas.Handle, PChar(LTab.Caption), Length(LTab.Caption), TextR, DrawTextBiDiModeFlags(LFlags));

  var CloseR := inherited GetCloseButtonRect(LTab.BoundsRect);
  if not CloseR.IsEmpty then
  begin
    LCloseIconColor := IfThen(LActive, CH_WHITE, CH_CLOSE_ICON);
    ChromeDrawCloseButton(ACanvas, CloseR, LTab.CloseButtonMouseIn, LTab.CloseButtonMouseDown, LCloseIconColor);
  end;
end;

function TTabView.GetButtonClass: TViewControlButtonClass;
begin
  Result := TChromeViewButton;
end;

function TTabView.GetCloseButtonRect(ARect: TRect): TRect;
begin
  Result := TRect.Empty;
  for var I := 0 to Tabs.Count - 1 do
    if (Tabs[I].BoundsRect.Left = ARect.Left) and (Tabs[I].BoundsRect.Top = ARect.Top) and (Tabs[I].BoundsRect.Right = ARect.Right) and (Tabs[I].BoundsRect.Bottom = ARect.Bottom) then
    begin
      Result := inherited GetCloseButtonRect(ARect);
      Exit;
    end;
end;

function TTabView.GetTabWidth(ATab: TTabViewTab): Integer;
begin
  Canvas.Font.Assign(Font);
  var LTextWidth := Canvas.TextWidth(ATab.Caption);
  Result := ScaleValue(cTabTextLeft + cTabIconSize + cTabIconGap) + LTextWidth + ScaleValue(cTabTextRight + cTabCloseSpace);
  Result := EnsureRange(Result, ScaleValue(cTabMinWidth), ScaleValue(cTabMaxWidth));
end;

procedure TTabView.SetHotIndex(AValue: Integer);
begin
  if FHotIndex <> AValue then
  begin
    FHotIndex := AValue;
    Invalidate;
  end;
end;

procedure TTabView.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button <> mbLeft then Exit;

  FDragTab      := nil;
  FDragging     := False;
  FPressedIndex := -1;
  var LTab      := TabFromPoint(Point(X, Y));
  if (LTab <> nil) and not (TabOptions.ShowCloseButton and GetCloseButtonRect(LTab.BoundsRect).Contains(Point(X, Y))) then
  begin
    FDragTab      := LTab;
    FDragStartX   := X;
    FPressedIndex := LTab.Index;
  end;
end;

procedure TTabView.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if not FDragging and (FDragTab <> nil) and TabOptions.Draggable and (ssLeft in Shift) and (Abs(X - FDragStartX) > ScaleValue(5)) then
  begin
    FDragging := True;
    Invalidate;
  end;
  SetHotIndex(TabIndexFromPoint(Point(X, Y)));
end;

procedure TTabView.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  var LWasDragging := (Button = mbLeft) and FDragging;
  var LDragTab     := FDragTab;
  inherited;

  if LWasDragging and (LDragTab <> nil) and (LDragTab.Index >= 0) and (LDragTab.Index < Tabs.Count) and (Tabs[LDragTab.Index] = LDragTab) then
  begin
    var LIndex := LDragTab.Index;
    TabIndex   := -1;
    TabIndex   := LIndex;
  end;

  if Button = mbLeft then
  begin
    FDragTab      := nil;
    FDragging     := False;
    FPressedIndex := -1;
    Invalidate;
  end;
end;

procedure TTabView.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHotIndex(-1);
end;

function TTabView.AddTabPage(APage: TControl; const ACaption: string; AImageIndex: Integer): TTabViewTab;
begin
  AddTab;
  Result            := Tabs[Tabs.Count - 1];
  Result.Caption    := ACaption;
  Result.ImageIndex := AImageIndex;
  if APage <> nil then
  begin
    Result.Control := APage;
    Result.Hint    := APage.Hint;
    Result.Tag     := Integer(APage.Tag);
    if APage is TTabPage then
    begin
      TTabPage(APage).Tab     := Result;
      TTabPage(APage).TabView := Self;
    end;
  end;

  TabIndex := -1;
  TabIndex := Result.Index;
end;

procedure TTabView.ShowPage(ATab: TTabViewTab);
begin
  for var I := 0 to Tabs.Count - 1 do
    if Tabs[I].Control <> nil then Tabs[I].Control.Visible := Tabs[I] = ATab;
  if (ATab <> nil) and (ATab.Control <> nil) then ATab.Control.BringToFront;
end;

{ TTabPage }

constructor TTabPage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDisabledIndex   := -1;
  Align            := alClient;
  BevelOuter       := bvNone;
  ShowCaption      := False;
  ParentBackground := False;
  ParentColor      := False;
  Color            := CH_TAB_ACTIVE;
  Visible          := False;
end;

function TTabPage.GetImageIndex: System.UITypes.TImageIndex;
begin
  Result := IfThen(FTab <> nil, FTab.ImageIndex, -1);
end;

procedure TTabPage.SetImageIndex(AValue: System.UITypes.TImageIndex);
begin
  if FTab <> nil then FTab.ImageIndex := AValue;
end;

end.
