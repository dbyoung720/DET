unit uDllDelphi;

interface

uses Winapi.Windows, System.SysUtils, Vcl.Controls, Vcl.Forms, uCommon;

{ 创建 Delphi Dll Form }
procedure CreateDelphiFormDll(const strDllFileName: string);

{ 销毁 Delphi Dll Form / DLL 模块 }
procedure FreeDelphiFormDll;

implementation

{ 创建 Delphi Dll Form }
procedure CreateDelphiFormDll(const strDllFileName: string);
var
  ls           : TLangStyle;
  DllDelphi    : Tdb_ShowDllForm_Plugins_Delphi;
  frmDll       : TFormClass;
  chrModuleName: PAnsiChar;
begin
  var hDllModule := LoadLibrary(PChar(strDllFileName));
  if hDllModule = 0 then raise Exception.Create('加载DLL失败:' + strDllFileName);

  try
    @DllDelphi := GetProcAddress(hDllModule, c_strDllExportFuncName);
    if not Assigned(DllDelphi) then raise Exception.Create('找不到导出函数 ' + c_strDllExportFuncName);

    DllDelphi(ls, frmDll, chrModuleName);
    var frmDelphiDll := frmDll.Create(nil);
    try
      frmDelphiDll.Position       := poDesigned;
      frmDelphiDll.DoubleBuffered := True;
      frmDelphiDll.Color          := Application.MainForm.Color;
      frmDelphiDll.Anchors        := [akLeft, akTop, akRight, akBottom];
      frmDelphiDll.Tag            := NativeInt(hDllModule);
      frmDelphiDll.BorderStyle    := bsNone;
      frmDelphiDll.BorderIcons    := [];
      var hWnd                    := frmDelphiDll.Handle;
	  
      { 子类回调函数; 拦截 Alt + F4 关闭窗体 }
      var OldProc := TFNWndProc(SetWindowLongPtr(hWnd, GWL_WNDPROC, NativeInt(@PluginFormWndProc)));
      SetWindowLongPtr(hWnd, GWLP_USERDATA, NativeInt(OldProc));

      var rzTab           := GetActiveTabSheet;                                                           // 查找当前模块列表中激活的页签
      rzTab.DisabledIndex := frmDelphiDll.Handle;                                                         // 窗体句柄
      rzTab.ImageIndex    := SetTabSheetExeIcon(strDllFileName, rzTab);                                   // 模块的页签图像
      rzTab.Data          := frmDelphiDll;                                                                // 保存窗体对象
      Winapi.Windows.SetParent(hWnd, rzTab.Handle);                                                       // 设置父窗体为 TabSheet
      SetWindowPos(hWnd, 0, 0, 0, rzTab.ClientWidth, rzTab.ClientHeight, SWP_NOZORDER OR SWP_NOACTIVATE); // 最大化 Dll 子窗体
      frmDelphiDll.Show;                                                                                  // 显示 Dll 子窗体
    except
      frmDelphiDll.Free;
      raise;
    end;
  except
    FreeLibrary(hDllModule);
    raise;
  end;
end;

{ 销毁 Delphi Dll Form / DLL 模块 }
procedure FreeDelphiFormDll;
begin
  var rzTab  := GetActiveTabSheet;
  var frmDll := TForm(rzTab.Data);
  if Assigned(frmDll) and frmDll.HandleAllocated then
  begin
    var hDllModule := frmDll.Tag;
    var OldProc    := TFNWndProc(GetWindowLongPtr(frmDll.Handle, GWLP_USERDATA));
    SetWindowLongPtr(frmDll.Handle, GWL_WNDPROC, NativeInt(OldProc));
    frmDll.Free;
    rzTab.Data := nil;
    DelayTime(100);
    FreeLibrary(hDllModule);
  end;
end;

end.
