unit uData;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.PsAPI, System.IniFiles, System.SysUtils, System.StrUtils, System.Variants, System.Classes, System.Math, System.DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Menus, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.CheckLst, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.TabView, Data.DB, Data.Win.ADODB,
  dxCore, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges, dxScrollbarAnnotations,
  cxEdit, cxDBData, cxGridLevel, cxClasses, cxGridCustomView, cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, cxDBLookupComboBox, cxFindPanel, cxGridExportLink, cxTextEdit,
  DBAccess, Uni, MemDS, UniProvider, SQLServerUniProvider, SQLiteUniProvider, PostgreSQLUniProvider, OracleUniProvider, MySQLUniProvider, InterBaseUniProvider, ODBCUniProvider, DB2UniProvider,
  RzTabs, uKBDynamic, uCommon;

type
  TModifyRecordCallback = function(DataSet: TDataSet): Boolean of object;

type
  TfrmDataDll = class(TForm)
    rzpgcntrlData: TRzPageControl;
    rztbshtDesign: TRzTabSheet;
    rztbshtShow: TRzTabSheet;
    SQLServerUniProvider1: TSQLServerUniProvider;
    grpTable: TGroupBox;
    cbbTable: TComboBox;
    grpFields: TGroupBox;
    grpSelectField: TGroupBox;
    grpFieldDisplayTitle: TGroupBox;
    chklstFields: TCheckListBox;
    grpRelate: TGroupBox;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    lbl4: TLabel;
    btnAddRelate: TButton;
    btnDelRelate: TButton;
    lvRelate: TListView;
    mmoFieldShowTitle: TMemo;
    lblMasterFieldName: TLabel;
    cbbRelateTable: TComboBox;
    cbbRelateField: TComboBox;
    cbbDisplayField: TComboBox;
    cxstylrpstry: TcxStyleRepository;
    cxstyl: TcxStyle;
    cxstyl1: TcxStyle;
    cxstyl2: TcxStyle;
    cxstyl3: TcxStyle;
    cxstyl4: TcxStyle;
    StyleEven: TcxStyle;
    StyleOdd: TcxStyle;
    cxgrd: TcxGrid;
    cxgrdbtblvwGrid1DBTableView1: TcxGridDBTableView;
    cxgrdlvlGrid1Level1: TcxGridLevel;
    DB2UniProvider1: TDB2UniProvider;
    InterBaseUniProvider1: TInterBaseUniProvider;
    MySQLUniProvider1: TMySQLUniProvider;
    ODBCUniProvider1: TODBCUniProvider;
    OracleUniProvider1: TOracleUniProvider;
    PostgreSQLUniProvider1: TPostgreSQLUniProvider;
    SQLiteUniProvider1: TSQLiteUniProvider;
    UniConnection1: TUniConnection;
    grpSave: TGroupBox;
    lblOrder: TLabel;
    cbbOrder: TComboBox;
    grpWhere: TGroupBox;
    lblWhere: TLabel;
    cbbWhere: TComboBox;
    cbbWhereEqu: TComboBox;
    edtWhereSQL: TEdit;
    lblWhereSQL: TLabel;
    grpSave1: TGroupBox;
    btnSave: TButton;
    lblWhere1: TLabel;
    rzpgcntrlWhere: TRzPageControl;
    rztbshtWhereNum: TRzTabSheet;
    edtWhereValue: TEdit;
    rztbshtWhereTime: TRzTabSheet;
    dtpEndDate: TDateTimePicker;
    dtpStartDate: TDateTimePicker;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbbTableChange(Sender: TObject);
    procedure chklstFieldsClick(Sender: TObject);
    procedure cbbRelateTableChange(Sender: TObject);
    procedure btnAddRelateClick(Sender: TObject);
    procedure btnDelRelateClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure cxgrdbtblvwGrid1DBTableView1CustomDrawIndicatorCell(Sender: TcxGridTableView; ACanvas: TcxCanvas; AViewInfo: TcxCustomGridIndicatorItemViewInfo; var ADone: Boolean);
    procedure cxgrdbtblvwGrid1DBTableView1StylesGetContentStyle(Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
    procedure cxgrdbtblvwGrid1DBTableView1DblClick(Sender: TObject);
    procedure UniConnection1AfterConnect(Sender: TObject);
    procedure rztbshtDesignDblClick(Sender: TObject);
    procedure cbbWhereEquChange(Sender: TObject);
    procedure cbbWhereChange(Sender: TObject);
    procedure edtWhereValueChange(Sender: TObject);
    procedure dtpStartDateChange(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    procedure LinkDataBase;
    procedure CreateShowDataUI;
    procedure FreeDataUI;
    procedure ShowDataView;
    procedure LoadLayout;
    procedure SaveLayout;
    procedure GetWhereSQL;
  public
    procedure SearchRecord(const bShow: Boolean); virtual;
    procedure DetailRecord(DetailCallBack: TModifyRecordCallback); virtual;
    procedure AddRecord(AddRecordCallBack: TModifyRecordCallback); virtual;
    procedure ModRecord(ModRecordCallBack: TModifyRecordCallback); virtual;
    procedure DelRecord;     virtual;
    procedure ExportRecord;  virtual;
    procedure ImportRecord;  virtual;
    procedure RefreshRecord; virtual;
  end;

{$R *.dfm}

implementation

function GetCallerModuleName: string;
begin
  var pg := TTabView(GetMainFormApp.MainForm.FindComponent('pgModule'));
  Result := pg.ActiveTab.Hint;
  if Result <> '' then Result := ChangeFileExt(Result.Split([';'])[0], '');
end;

procedure TfrmDataDll.FormCreate(Sender: TObject);
begin
  rztbshtDesign.TabVisible    := False;
  rztbshtShow.TabVisible      := False;
  rzpgcntrlData.ActivePage    := rztbshtShow;
  rztbshtWhereNum.TabVisible  := False;
  rztbshtWhereTime.TabVisible := False;
  rzpgcntrlWhere.ActivePage   := rztbshtWhereNum;
  rzpgcntrlWhere.Height       := 35;
  dtpStartDate.DateTime       := Now;
  dtpEndDate.DateTime         := Now + 365;
  LinkDataBase;
end;

procedure TfrmDataDll.FormDestroy(Sender: TObject);
begin
  SaveLayout;
  FreeDataUI;
end;

procedure TfrmDataDll.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = Ord('X')) and (ssCtrl in Shift) and (ssAlt in Shift) then
  begin
    if rzpgcntrlData.ActivePageIndex = 0 then rzpgcntrlData.ActivePageIndex := 1 else rzpgcntrlData.ActivePageIndex := 0;
    Key := 0;
  end;
end;

procedure TfrmDataDll.LinkDataBase;
var
  strEnc : string;
begin
  with TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini') do
  begin
    strEnc := ReadString('DB', 'LINK', '');
    Free;
  end;

  if Trim(strEnc) = '' then Exit;

  var strConnected := DecryptString(strEnc, c_strAESKey);
  if Trim(strConnected) = '' then Exit;
  var arrInfo := strConnected.Split([';']);
  if Length(arrInfo) < 6 then Exit;

  UniConnection1.ProviderName := arrInfo[0];
  UniConnection1.Username     := arrInfo[1];
  UniConnection1.Password     := arrInfo[2];
  UniConnection1.Server       := arrInfo[3];
  UniConnection1.Port         := StrToIntDef(arrInfo[4], 0);
  UniConnection1.Database     := arrInfo[5];
  UniConnection1.LoginPrompt  := False;
  UniConnection1.Connect;
end;

procedure TfrmDataDll.UniConnection1AfterConnect(Sender: TObject);
begin
  CreateShowDataUI;
end;

procedure TfrmDataDll.btnAddRelateClick(Sender: TObject);
begin
  if cbbRelateTable.ItemIndex  = -1 then Exit;
  if cbbRelateField.ItemIndex  = -1 then Exit;
  if cbbDisplayField.ItemIndex = -1 then Exit;

  with lvRelate.Items.add do
  begin
    Caption := lblMasterFieldName.Caption;
    SubItems.add(cbbRelateTable.Text);
    SubItems.add(cbbRelateField.Text);
    SubItems.add(cbbDisplayField.Text);
  end;
end;

procedure TfrmDataDll.btnDelRelateClick(Sender: TObject);
begin
  if lvRelate.ItemIndex = -1 then Exit;

  lvRelate.DeleteSelected;
end;

procedure TfrmDataDll.btnSaveClick(Sender: TObject);
var
  dti     : TDisplayTableInfo;
  bExists : Boolean;
begin
  dti.strTableName        := cbbTable.Text;
  dti.strOrderByFieldName := cbbOrder.Text;
  dti.strWhereSQL         := edtWhereSQL.Text;

  var Count := 0;
  for var I := 0 to chklstFields.Items.Count - 1 do
  begin
    if chklstFields.Checked[I] then
    begin
      Inc(Count);
      SetLength(dti.ArrFields, Count);
      SetLength(dti.ArrDisplayTitle, Count);
      dti.ArrFields[Count - 1]       := chklstFields.Items[I];
      dti.ArrDisplayTitle[Count - 1] := mmoFieldShowTitle.Lines[I];
    end;
  end;

  SetLength(dti.RelateTable, lvRelate.Items.Count);
  for var I := 0 to lvRelate.Items.Count - 1 do
  begin
    dti.RelateTable[I].strPrimateField := lvRelate.Items[I].Caption;
    dti.RelateTable[I].strRelateTable  := lvRelate.Items[I].SubItems[0];
    dti.RelateTable[I].strRelateField  := lvRelate.Items[I].SubItems[1];
    dti.RelateTable[I].strDisplayField := lvRelate.Items[I].SubItems[2];
  end;

  var fs := TMemoryStream.Create;
  try
    var strFileName := ExtractFilePath(ParamStr(0)) + c_strPlugInsPath + GetCallerModuleName + '.dti';
    bExists         := FileExists(strFileName);
    TKBDynamic.WriteTo(fs, dti, TypeInfo(TDisplayTableInfo));
    fs.SaveToFile(strFileName);
  finally
    fs.Free;
  end;

  var strLayoutFileName := ExtractFilePath(ParamStr(0)) + c_strPlugInsPath + GetCallerModuleName + '.ini';
  if FileExists(strLayoutFileName) then DeleteFile(strLayoutFileName);

  if bExists then FreeDataUI;
  ShowDataView;
  rzpgcntrlData.ActivePage := rztbshtShow;
end;

procedure TfrmDataDll.cbbRelateTableChange(Sender: TObject);
begin
  cbbRelateField.Clear;
  cbbDisplayField.Clear;
  UniConnection1.GetFieldNames(cbbRelateTable.Text, cbbRelateField.Items);
  UniConnection1.GetFieldNames(cbbRelateTable.Text, cbbDisplayField.Items);
end;

procedure TfrmDataDll.chklstFieldsClick(Sender: TObject);
begin
  if chklstFields.ItemIndex = -1 then Exit;

  var StartPos                := mmoFieldShowTitle.Perform(EM_LINEINDEX, chklstFields.ItemIndex, 0);
  var EndPos                  := mmoFieldShowTitle.Perform(EM_LINELENGTH, StartPos, 0);
  mmoFieldShowTitle.SelStart  := StartPos;
  mmoFieldShowTitle.SelLength := EndPos;
  mmoFieldShowTitle.Perform(EM_SCROLLCARET, 0, 0);
  lblMasterFieldName.Caption := chklstFields.Items[chklstFields.ItemIndex];

  var bFind := False;
  var J     := -1;
  for var I := 0 to lvRelate.Items.Count - 1 do
  begin
    if SameText(lvRelate.Items[I].Caption, chklstFields.Items[chklstFields.ItemIndex]) then
    begin
      bFind := True;
      J     := I;
      Break;
    end;
  end;

  if bFind then
  begin
    cbbRelateTable.ItemIndex := cbbRelateTable.Items.IndexOf(lvRelate.Items[J].SubItems[0]);
    cbbRelateTable.OnChange(nil);
    cbbRelateField.ItemIndex  := cbbRelateField.Items.IndexOf(lvRelate.Items[J].SubItems[1]);
    cbbDisplayField.ItemIndex := cbbDisplayField.Items.IndexOf(lvRelate.Items[J].SubItems[2]);
  end
  else
  begin
    cbbRelateTable.ItemIndex  := -1;
    cbbRelateField.ItemIndex  := -1;;
    cbbDisplayField.ItemIndex := -1;;
  end;
end;

procedure TfrmDataDll.cxgrdbtblvwGrid1DBTableView1CustomDrawIndicatorCell(Sender: TcxGridTableView; ACanvas: TcxCanvas; AViewInfo: TcxCustomGridIndicatorItemViewInfo; var ADone: Boolean);
begin
  if (AViewInfo is TcxGridIndicatorRowItemViewInfo) then
  begin
    var FValue  := IntToStr(TcxGridIndicatorRowItemViewInfo(AViewInfo).GridRecord.Index + 1);
    var FBounds := AViewInfo.Bounds;
    ACanvas.FillRect(FBounds);
    ACanvas.DrawComplexFrame(FBounds, clBtnHighlight, clBtnShadow, [bBottom, bLeft, bRight], 1);
    InflateRect(FBounds, -1, -1);
    ACanvas.Font.Color  := clBlack;
    ACanvas.Brush.Style := bsClear;
    ACanvas.DrawText(FValue, FBounds, cxAlignCenter or cxAlignTop);
    ADone := True;
  end;
end;

procedure TfrmDataDll.cxgrdbtblvwGrid1DBTableView1StylesGetContentStyle(Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if (ARecord <> nil) then  // 奇数行和偶数行不同颜色
    if (ARecord.RecordIndex mod 2 = 0) then AStyle := StyleEven else AStyle := StyleOdd;
end;

procedure TfrmDataDll.cbbTableChange(Sender: TObject);
begin
  chklstFields.Clear;
  mmoFieldShowTitle.Clear;
  cbbOrder.Clear;
  UniConnection1.GetFieldNames(cbbTable.Text, chklstFields.Items);
  UniConnection1.GetFieldNames(cbbTable.Text, mmoFieldShowTitle.Lines);
  UniConnection1.GetFieldNames(cbbTable.Text, cbbOrder.Items);
  UniConnection1.GetFieldNames(cbbTable.Text, cbbWhere.Items);
end;

procedure TfrmDataDll.CreateShowDataUI;
var
  dti : TDisplayTableInfo;
begin
  rztbshtDesign.TabVisible := False;
  rztbshtShow.TabVisible   := False;
  UniConnection1.GetTableNames(cbbTable.Items);
  UniConnection1.GetTableNames(cbbRelateTable.Items);
  cbbTable.ItemIndex := 0;
  cbbTableChange(nil);

  var strFileName := ExtractFilePath(ParamStr(0)) + c_strPlugInsPath + GetCallerModuleName + '.dti';
  if not FileExists(strFileName) then Exit;

  { 更新设计界面 }
  UniConnection1.GetFieldNames(cbbTable.Text, cbbOrder.Items);
  UniConnection1.GetFieldNames(cbbTable.Text, cbbWhere.Items);

  var fs := TMemoryStream.Create;
  fs.LoadFromFile(strFileName);
  fs.Position := 0;
  TKBDynamic.ReadFrom(fs, dti, TypeInfo(TDisplayTableInfo));
  fs.Free;
  if dti.strTableName.Trim.IsEmpty then
  begin
    rzpgcntrlData.ActivePageIndex := 0;
    Exit;
  end;
  
  cbbTable.ItemIndex := cbbTable.Items.IndexOf(dti.strTableName);
  cbbTableChange(nil);
  cbbOrder.ItemIndex := cbbOrder.Items.IndexOf(dti.strOrderByFieldName);
  edtWhereSQL.Text   := dti.strWhereSQL;
  for var I          := 0 to chklstFields.Items.Count - 1 do
  begin
    for var J := 0 to Length(dti.ArrFields) - 1 do
    begin
      if SameText(chklstFields.Items[I], dti.ArrFields[J]) then
      begin
        chklstFields.Checked[I]    := True;
        mmoFieldShowTitle.Lines[I] := dti.ArrDisplayTitle[J];
        Break;
      end;
    end;
  end;

  for var I := 0 to Length(dti.RelateTable) - 1 do
  begin
    with lvRelate.Items.add do
    begin
      Caption := dti.RelateTable[I].strPrimateField;
      SubItems.add(dti.RelateTable[I].strRelateTable);
      SubItems.add(dti.RelateTable[I].strRelateField);
      SubItems.add(dti.RelateTable[I].strDisplayField);
    end;
  end;

  { 显示数据 }
  ShowDataView;
end;

procedure TfrmDataDll.FreeDataUI;
begin
  var ds := cxgrdbtblvwGrid1DBTableView1.DataController.DataSource;
  if ds = nil then Exit;

  { 先停止数据显示 }
  var qry := TUniQuery(ds.DataSet);
  qry.Close;

  { 先销毁关联的数据控件 }
  for var I := 0 to cxgrdbtblvwGrid1DBTableView1.ColumnCount - 1 do
  begin
    if SameText(cxgrdbtblvwGrid1DBTableView1.Columns[I].PropertiesClassName, 'TcxLookupComboBoxProperties') then
    begin
      ds  := TcxLookupComboBoxProperties(cxgrdbtblvwGrid1DBTableView1.Columns[I].Properties).ListSource;
      qry := TUniQuery(ds.DataSet);
      qry.Free;
      ds.Free;
    end;
  end;

  { 再销毁数据控件 }
  ds  := cxgrdbtblvwGrid1DBTableView1.DataController.DataSource;
  qry := TUniQuery(ds.DataSet);
  qry.Free;
  ds.Free;

  { 最后销毁动态创建的显示列 }
  cxgrdbtblvwGrid1DBTableView1.ClearItems;
end;

procedure TfrmDataDll.ShowDataView;
var
  qryRelate : array of TUniQuery;
  dsRelate  : array of TDataSource;
begin
  { 数据源 }
  var qry                                                := TUniQuery.Create(nil);
  qry.Connection                                         := UniConnection1;
  var ds                                                 := TDataSource.Create(nil);
  ds.DataSet                                             := qry;
  cxgrdbtblvwGrid1DBTableView1.DataController.DataSource := ds;

  { 创建显示列 }
  var strFields := '';
  for var I := 0 to chklstFields.Items.Count - 1 do
  begin
    if chklstFields.Checked[I] then
    begin
      strFields := strFields + ',' + chklstFields.Items[I];
      with cxgrdbtblvwGrid1DBTableView1.CreateColumn do
      begin
        DataBinding.FieldName := chklstFields.Items[I];
        Name                  := 'col_' + chklstFields.Items[I];
        Caption               := mmoFieldShowTitle.Lines[I];
        Width                 := 200;
        Options.Editing       := False;
        Index                 := cxgrdbtblvwGrid1DBTableView1.ColumnCount - 1;
        Visible               := True;
      end;
    end;
  end;

  strFields        := RightStr(strFields, Length(strFields) - 1);
  var strWhereSQL  := edtWhereSQL.Text;
  qry.SQL.Text     := 'select ' + strFields + ' from ' + cbbTable.Text + ' ' + strWhereSQL;
  if Trim(cbbOrder.Text) <> '' then qry.SQL.Text := qry.SQL.Text + ' order by ' + cbbOrder.Text;
  qry.Open;

  { 关联列 }
  var Count := lvRelate.Items.Count;
  SetLength(qryRelate, Count);
  SetLength(dsRelate, Count);
  Count := 0;
  for var I := 0 to lvRelate.Items.Count - 1 do
  begin
    var strPrimateFieldName := lvRelate.Items[I].Caption;
    for var J := 0 to cxgrdbtblvwGrid1DBTableView1.ColumnCount - 1 do
    begin
      if SameText(cxgrdbtblvwGrid1DBTableView1.Columns[J].DataBinding.FieldName, strPrimateFieldName) then
      begin
        qryRelate[Count]            := TUniQuery.Create(nil);
        qryRelate[Count].Connection := UniConnection1;
        qryRelate[Count].SQL.Text   := 'select ' + lvRelate.Items[I].SubItems[1] + ',' + lvRelate.Items[I].SubItems[2] + ' from ' + lvRelate.Items[I].SubItems[0];
        qryRelate[Count].Open;
        dsRelate[Count]                                                                                           := TDataSource.Create(nil);
        dsRelate[Count].DataSet                                                                                   := qryRelate[Count];
        cxgrdbtblvwGrid1DBTableView1.Columns[J].PropertiesClassName                                               := 'TcxLookupComboBoxProperties';
        TcxLookupComboBoxProperties(cxgrdbtblvwGrid1DBTableView1.Columns[J].Properties).KeyFieldNames             := lvRelate.Items[I].SubItems[1];
        TcxLookupComboBoxProperties(cxgrdbtblvwGrid1DBTableView1.Columns[J].Properties).ListColumns.add.FieldName := lvRelate.Items[I].SubItems[2];
        TcxLookupComboBoxProperties(cxgrdbtblvwGrid1DBTableView1.Columns[J].Properties).ListSource                := dsRelate[Count];
        Inc(Count);
        Break;
      end;
    end;
  end;

  LoadLayout;
end;

procedure TfrmDataDll.LoadLayout;
begin
  var strFileName := ExtractFilePath(ParamStr(0)) + c_strPlugInsPath + GetCallerModuleName + '.ini';
  cxgrdbtblvwGrid1DBTableView1.RestoreFromIniFile(strFileName, True, False, [gsoUseFilter, gsoUseSummary]);
end;

procedure TfrmDataDll.SaveLayout;
begin
  var strFileName := ExtractFilePath(ParamStr(0)) + c_strPlugInsPath + GetCallerModuleName + '.ini';
  cxgrdbtblvwGrid1DBTableView1.StoreToIniFile(strFileName, True, [gsoUseFilter, gsoUseSummary]);
end;

procedure TfrmDataDll.cxgrdbtblvwGrid1DBTableView1DblClick(Sender: TObject);
begin
  var ShiftState := KeyboardStateToShiftState;
  if ([ssShift, ssCtrl, ssAlt] <= ShiftState) then rzpgcntrlData.ActivePage := rztbshtDesign;
end;

procedure TfrmDataDll.SearchRecord(const bShow: Boolean);
begin
  cxgrdbtblvwGrid1DBTableView1.FindPanel.DisplayMode := TcxFindPanelDisplayMode(IfThen(bShow, 2, 0));
end;

procedure TfrmDataDll.DetailRecord(DetailCallBack: TModifyRecordCallback);
begin
  var ARecord := cxgrdbtblvwGrid1DBTableView1.Controller.FocusedRecord;
  if ARecord = nil then Exit;

  var FieldValue : Integer := ARecord.Values[0];
  var FieldName  : string  := cxgrdbtblvwGrid1DBTableView1.Columns[0].DataBinding.FieldName;
  var strSQL     := Format('select * from ' + cbbTable.Text + ' where %s = %d', [FieldName, FieldValue]);

  var qry        := TUniQuery.Create(nil);
  var ds         := TDataSource.Create(nil);
  try
    qry.Connection := UniConnection1;
    ds.DataSet     := qry;
    qry.SQL.Text   := strSQL;
    try
      qry.Open;
    except
     on E: Exception do raise Exception.Create('sql execute error: ' + E.Message);
    end;

    DetailCallBack(ds.DataSet);
  finally
    ds.free;
    qry.free;
  end;
end;

procedure TfrmDataDll.AddRecord(AddRecordCallBack: TModifyRecordCallback);
begin
  var iCurrentIndex := -1;
  var ARecord := cxgrdbtblvwGrid1DBTableView1.Controller.FocusedRecord;
  if ARecord <> nil then iCurrentIndex := ARecord.Index;

  var ADataSet := cxgrdbtblvwGrid1DBTableView1.DataController.DataSet;
  ADataSet.Append;

  if AddRecordCallBack(ADataSet) then
  begin
    ADataSet.Post;
    var ARecordIndex                                            := cxgrdbtblvwGrid1DBTableView1.DataController.RecordCount - 1;
    cxgrdbtblvwGrid1DBTableView1.DataController.FocusedRowIndex := ARecordIndex;
    cxgrdbtblvwGrid1DBTableView1.Controller.MakeFocusedRecordVisible;
  end
  else
  begin
    ADataSet.Cancel;
    cxgrdbtblvwGrid1DBTableView1.DataController.FocusedRowIndex := iCurrentIndex;
  end;
end;

procedure TfrmDataDll.ModRecord(ModRecordCallBack: TModifyRecordCallback);
begin
  var ARecord := cxgrdbtblvwGrid1DBTableView1.Controller.FocusedRecord;
  if ARecord = nil then Exit;

  if Assigned(ModRecordCallBack) then
  begin
    var I := ARecord.Index;
    cxgrdbtblvwGrid1DBTableView1.DataController.DataSet.Edit;
    if ModRecordCallBack(cxgrdbtblvwGrid1DBTableView1.DataController.DataSet) then
    begin
      cxgrdbtblvwGrid1DBTableView1.DataController.DataSet.Post;
      cxgrdbtblvwGrid1DBTableView1.DataController.Refresh;
      cxgrdbtblvwGrid1DBTableView1.DataController.FocusedRowIndex := I;
    end
    else
    begin
      cxgrdbtblvwGrid1DBTableView1.DataController.DataSet.Cancel;
    end;
  end;
end;

procedure TfrmDataDll.DelRecord;
begin
  cxgrdbtblvwGrid1DBTableView1.DataController.DeleteSelection;
end;

procedure TfrmDataDll.RefreshRecord;
begin
  var ARecord := cxgrdbtblvwGrid1DBTableView1.Controller.FocusedRecord;
  if ARecord = nil then Exit;
  var I := ARecord.Index;

  cxgrdbtblvwGrid1DBTableView1.DataController.Refresh;
  cxgrdbtblvwGrid1DBTableView1.DataController.FocusedRowIndex := IfThen(I = -1, 0, I);
end;

procedure TfrmDataDll.rztbshtDesignDblClick(Sender: TObject);
begin
  var ShiftState := KeyboardStateToShiftState;
  if ([ssShift, ssCtrl, ssAlt] <= ShiftState) then rzpgcntrlData.ActivePage := rztbshtShow;
end;

procedure TfrmDataDll.ExportRecord();
begin
  if cxgrdbtblvwGrid1DBTableView1.DataController.Groups.GroupingItemCount > 0 then
  begin
    ShowMessage('分组模式下不能导出数据记录...');
    Exit;
  end;

  with TSaveDialog.Create(nil) do
  begin
    Filter := 'EXCEL文件(*.xlsx)|*.xlsx|CSV文件(*.csv)|*.csv';
    if Execute then
      if Filename <> '' then
      begin
        if FilterIndex = 1 then
          ExportGridToXLSX(Filename, cxgrd, True, True, True, 'xlsx')
        else
          ExportGridToCSV(Filename, cxgrd, True, True, #$9, 'csv');
        ShowMessage('数据导出成功...')
      end;
    Free;
  end;
end;

procedure TfrmDataDll.ImportRecord;
begin
  //
end;

procedure TfrmDataDll.cbbWhereChange(Sender: TObject);
begin
  GetWhereSQL;
end;

procedure TfrmDataDll.edtWhereValueChange(Sender: TObject);
begin
  GetWhereSQL;
end;

procedure TfrmDataDll.dtpStartDateChange(Sender: TObject);
begin
  GetWhereSQL;
end;

procedure TfrmDataDll.cbbWhereEquChange(Sender: TObject);
begin
  rzpgcntrlWhere.ActivePageIndex := IfThen(cbbWhereEqu.ItemIndex = 6, 1, 0);
  GetWhereSQL;
end;

procedure TfrmDataDll.GetWhereSQL;
const
  c_strArr: array [0 .. 5] of string = (' = ', ' > ', ' >= ', ' < ', ' <= ', ' like ');
begin
  if cbbWhereEqu.ItemIndex <> 6 then
  begin
    if cbbWhereEqu.ItemIndex = 5 then
      edtWhereSQL.Text := Format('where %s %s ''%s''', [cbbWhere.Text, c_strArr[cbbWhereEqu.ItemIndex], '%' + edtWhereValue.Text + '%'])
    else
      edtWhereSQL.Text := Format('where %s %s %s', [cbbWhere.Text, c_strArr[cbbWhereEqu.ItemIndex], edtWhereValue.Text]);
  end
  else
  begin
    edtWhereSQL.Text := Format('where %s between ''%s'' and ''%s''', [cbbWhere.Text, dtpStartDate.DateTime.ToString, dtpEndDate.DateTime.ToString]);
  end;
end;

initialization
  dxUnitsLoader.Initialize;

finalization
  dxUnitsLoader.Finalize;

end.
