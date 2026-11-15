unit Unit1;

interface

uses
  Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Win.ComObj, System.ImageList, Data.DB, Data.Win.ADODB,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ImgList, Vcl.VirtualImageList, Vcl.BaseImageCollection, Vcl.ImageCollection,
  udd;

type
  TfrmPeopoleList = class(TfrmDataDll)
    pnlTop: TPanel;
    pnlData: TPanel;
    btnSearch: TButton;
    btnAdd: TButton;
    btnDel: TButton;
    btnModify: TButton;
    btnExport: TButton;
    btnInport: TButton;
    ImageCollection1: TImageCollection;
    VirtualImageList1: TVirtualImageList;
    btnViewDetail: TButton;
    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnModifyClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnViewDetailClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnInportClick(Sender: TObject);
  private
    FbSearch: Boolean;
    function ViewDetailRecordCallBack(DataSet: TDataSet): Boolean;
    function ModRecordCallBack(DataSet: TDataSet): Boolean;
    function AddRecordCallBack(DataSet: TDataSet): Boolean;
  end;

implementation

uses uMod;

{$R *.dfm}

function TfrmPeopoleList.ViewDetailRecordCallBack(DataSet: TDataSet): Boolean;
begin
  Result := ShowModRecordForm(DataSet, '记录详情：');
end;

function TfrmPeopoleList.AddRecordCallBack(DataSet: TDataSet): Boolean;
begin
  Result := ShowModRecordForm(DataSet, '添加记录：');
end;

function TfrmPeopoleList.ModRecordCallBack(DataSet: TDataSet): Boolean;
begin
  Result := ShowModRecordForm(DataSet);
end;

procedure TfrmPeopoleList.FormCreate(Sender: TObject);
begin
  FbSearch := False;
end;

procedure TfrmPeopoleList.FormDestroy(Sender: TObject);
begin
  frmDataDLL.Free;
end;

procedure TfrmPeopoleList.FormResize(Sender: TObject);
begin
  frmDataDLL.DataDllFormResize;
end;

{ 查询 }
procedure TfrmPeopoleList.btnSearchClick(Sender: TObject);
begin
  FbSearch := not FbSearch;
  frmDataDLL.SearchRecord(FbSearch);
end;

{ 查看详情 }
procedure TfrmPeopoleList.btnViewDetailClick(Sender: TObject);
begin
  frmDataDLL.DetailRecord(ViewDetailRecordCallBack);
end;

{ 添加 }
procedure TfrmPeopoleList.btnAddClick(Sender: TObject);
begin
  frmDataDLL.AddRecord(AddRecordCallBack);
end;

{ 修改 }
procedure TfrmPeopoleList.btnModifyClick(Sender: TObject);
begin
  frmDataDLL.ModRecord(ModRecordCallBack);
end;

{ 删除 }
procedure TfrmPeopoleList.btnDelClick(Sender: TObject);
begin
  frmDataDLL.DelRecord;
end;

{ 导出 }
procedure TfrmPeopoleList.btnExportClick(Sender: TObject);
begin
  frmDataDLL.ExportRecord;
end;

{ 导入 }
procedure TfrmPeopoleList.btnInportClick(Sender: TObject);
begin
  //
end;

end.
