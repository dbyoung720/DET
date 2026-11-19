unit SiteManager;

// ============================================================
// 站点注册中心：所有站点解析器在此登记，主程序只依赖本单元与 SiteIntf。
// 新增站点步骤：
//   1. 在 Sites\<id>\ 下新建 SiteXxx.pas，继承 TSiteBase 实现抽象方法
//   2. 在 SiteRegistry.pas 的 uses 与 RegisterAll 中各加一行
//   3. 在 sites\<id>\ 执行目录放入该站点的 .mjs 脚本
// ============================================================

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, SiteIntf;

type
  TSiteManager = class
  private
    FSites: TList<TSiteClass>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Register(ASiteClass: TSiteClass);
    function Count: Integer;
    function SiteClass(AIndex: Integer): TSiteClass;
    function CreateSite(AIndex: Integer; ACtx: TSiteContext): TSiteBase;
  end;

var
  GSiteManager: TSiteManager;

implementation

constructor TSiteManager.Create;
begin
  inherited Create;
  FSites := TList<TSiteClass>.Create;
end;

destructor TSiteManager.Destroy;
begin
  FSites.Free;
  inherited;
end;

procedure TSiteManager.Register(ASiteClass: TSiteClass);
begin
  if ASiteClass = nil then Exit;
  if FSites.IndexOf(ASiteClass) < 0 then
    FSites.Add(ASiteClass);
end;

function TSiteManager.Count: Integer;
begin
  Result := FSites.Count;
end;

function TSiteManager.SiteClass(AIndex: Integer): TSiteClass;
begin
  if (AIndex < 0) or (AIndex >= FSites.Count) then
    Result := nil
  else
    Result := FSites[AIndex];
end;

function TSiteManager.CreateSite(AIndex: Integer; ACtx: TSiteContext): TSiteBase;
var
  C: TSiteClass;
begin
  C := SiteClass(AIndex);
  if C = nil then
    Result := nil
  else
    Result := C.Create(ACtx);
end;

initialization
  GSiteManager := TSiteManager.Create;

finalization
  GSiteManager.Free;

end.
