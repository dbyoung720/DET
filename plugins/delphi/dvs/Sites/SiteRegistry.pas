unit SiteRegistry;

// ============================================================
// 站点注册表（扩展入口）：新增站点只需在此 uses + RegisterAll 各加一行。
// 主程序不直接引用任何具体站点单元，只依赖本单元完成注册。
// ============================================================

interface

implementation

uses
  SiteManager, SiteIntf, Site4kvm, Site555, SiteGangju, SiteFeikuai, SiteSyzljs, SiteWhtqedu, SiteIkanbot, SiteY2s52n7, SiteMedvsm, SiteVictoryyuly, SiteFiilacurent;

procedure RegisterAll;
begin
  GSiteManager.Register(TSite4kvm);
  GSiteManager.Register(TSite555);
  GSiteManager.Register(TSiteGangju);
  GSiteManager.Register(TSiteFeikuai);
  GSiteManager.Register(TSiteSyzljs);
  GSiteManager.Register(TSiteWhtqedu);
  GSiteManager.Register(TSiteIkanbot);
  GSiteManager.Register(TSiteY2s52n7);
  GSiteManager.Register(TSiteMedvsm);
  GSiteManager.Register(TSiteVictoryyuly);
  GSiteManager.Register(TSiteFiilacurent);
  // 以后新增站点示例：
  //   GSiteManager.Register(TSiteXxx);
end;

initialization
  RegisterAll;

end.
