
{$REGION ' ****** 配置 ****** ' }

procedure TfrmMain.btnDBConnectClick(Sender: TObject);
var
  strEnc: string;
begin
  with TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini') do
  begin
    strEnc := ReadString('DB', 'LINK', '');
    Free;
  end;

  UniConnection.LoginPrompt := Trim(strEnc) = '';
  try
    UniConnection.Connect;
  except
    on E: Exception do 
   	begin
	    MyMSG(Handle, E.Message);
    end;
  end;
end;

procedure TfrmMain.btnDBDisconnectClick(Sender: TObject);
begin
  UniConnection.Disconnect;
end;

procedure TfrmMain.btnDelConnectClick(Sender: TObject);
begin
  UniConnection.Disconnect;
  btnDelConnect.Enabled := False;
  with TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini') do
  begin
    DeleteKey('DB', 'LINK');
    Free;
  end;
end;

procedure TfrmMain.btnLoginCheckSaveClick(Sender: TObject);
begin
  with TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini') do
  begin
    WriteString('DB', 'LoginTable', cbbLoginTable.Text);
    WriteString('DB', 'LoginNameField', cbbLoginNameField.Text);
    WriteString('DB', 'LoginPassField', cbbLoginPassField.Text);
    WriteString('DB', 'LoginCheckDll', btnLoginDLL.Text);
    WriteString('DB', 'LoginCheckFunc', cbbLoginDLLFunc.Text);
    Free;
  end;
end;

procedure TfrmMain.btnLoginDLLButtonClick(Sender: TObject);
begin
  dlgOpenLoginCheck.InitialDir := ExtractFilePath(ParamStr(0))  + c_strPlugins;
  if not dlgOpenLoginCheck.Execute then Exit;

  var ls := TStringList.Create;
  try
    btnLoginDLL.Text := dlgOpenLoginCheck.FileName;
    CheckDllExportFunc(btnLoginDLL.Text, ls);
    cbbLoginDLLFunc.Clear;
    cbbLoginDLLFunc.Items.AddStrings(ls);
    cbbLoginDLLFunc.ItemIndex := IfThen(ls.Count > 0, 0, -1);
    btnLoginCheckSave.Enabled := Boolean(IfThen(ls.Count > 0, 1, 0));
  finally
    ls.Free;
  end;
end;

procedure TfrmMain.UniConnectionAfterConnect(Sender: TObject);
var
  strConnected: String;
  strEnc      : string;
  ls          : TStringList;
begin
  btnDBConnect.Enabled    := False;
  btnDBDisconnect.Enabled := True;
  btnDelConnect.Enabled   := True;
  rztbshtDataBaseManager.Enabled    := True;
  rztbshtDataBaseManager.TabEnabled := True;

  strConnected            := Format('%s;%s;%s;%s;%d;%s', [UniConnection.ProviderName, UniConnection.Username, UniConnection.Password, UniConnection.Server, UniConnection.Port, UniConnection.Database]);
  strEnc                  := EncryptString(strConnected, c_strAESKey);
  with TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini') do
  begin
    WriteString('DB', 'LINK', strEnc);
    Free;
  end;

  with TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini') do
  begin
    ls := TStringList.Create;
    try
      UniConnection.GetTableNames(cbbLoginTable.Items);
      cbbLoginTable.ItemIndex := cbbLoginTable.Items.IndexOf(ReadString('DB', 'LoginTable', ''));
      if cbbLoginTable.ItemIndex <> -1 then
      begin
        UniConnection.GetFieldNames(cbbLoginTable.Text, cbbLoginNameField.Items);
        UniConnection.GetFieldNames(cbbLoginTable.Text, cbbLoginPassField.Items);
        cbbLoginNameField.ItemIndex := cbbLoginNameField.Items.IndexOf(ReadString('DB', 'LoginNameField', ''));
        cbbLoginPassField.ItemIndex := cbbLoginPassField.Items.IndexOf(ReadString('DB', 'LoginPassField', ''));
      end;
      btnLoginDLL.Text := ReadString('DB', 'LoginCheckDll', '');

      CheckDllExportFunc(btnLoginDLL.Text, ls);
      cbbLoginDLLFunc.Clear;
      cbbLoginDLLFunc.Items.AddStrings(ls);
      cbbLoginDLLFunc.ItemIndex := cbbLoginDLLFunc.Items.IndexOf(ReadString('DB', 'LoginCheckFunc', ''));
      btnLoginCheckSave.Enabled := Boolean(IfThen(ls.Count > 0, 1, 0));
    finally
      ls.Free;
    end;
    Free;
  end;
end;

procedure TfrmMain.UniConnectionAfterDisconnect(Sender: TObject);
begin
  btnDBConnect.Enabled              := True;
  btnDBDisconnect.Enabled           := False;
  btnDelConnect.Enabled             := True;
  rztbshtDataBaseManager.Enabled    := False;
  rztbshtDataBaseManager.TabEnabled := False;
  cbbLoginTable.Items.Clear;
  cbbLoginNameField.Items.Clear;
  cbbLoginPassField.Items.Clear;
  btnLoginDLL.Text :='';
  cbbLoginDLLFunc.Items.Clear;
end;

{ 数据库连接 }
procedure TfrmMain.LinkDataBase;
var
  strConnected : String;
  strEnc       : string;
begin
  with TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini') do
  begin
    strEnc := ReadString('DB', 'LINK', '');
    Free;
  end;

  if Trim(strEnc) = '' then Exit;

  strConnected := DecryptString(strEnc, c_strAESKey);
  if Trim(strConnected) = '' then Exit;
  var arrInfo := strConnected.Split([';']);
  if Length(arrInfo) < 6 then Exit;

  UniConnection.ProviderName := arrInfo[0];
  UniConnection.Username     := arrInfo[1];
  UniConnection.Password     := arrInfo[2];
  UniConnection.Server       := arrInfo[3];
  UniConnection.Port         := StrToIntDef(arrInfo[4], 0);
  UniConnection.Database     := arrInfo[5];
  UniConnection.LoginPrompt  := False;
  try
    UniConnection.Connect;
  except
    on E: Exception do 
    begin
	    MyMSG(Handle, E.Message);
    end;
  end;
end;

procedure TfrmMain.cbbLoginTableChange(Sender: TObject);
begin
  UniConnection.GetFieldNames(cbbLoginTable.Text, cbbLoginNameField.Items);
  UniConnection.GetFieldNames(cbbLoginTable.Text, cbbLoginPassField.Items);
end;

{ 调整模块位置时，上移、下移按钮的可用状态 }
procedure TfrmMain.UpdateModuleMoveButtonState;
begin
  btnUP.Enabled   := (tvModuleSort.Selected <> nil) and (tvModuleSort.Selected.GetPrevSibling <> nil);
  btnDown.Enabled := (tvModuleSort.Selected <> nil) and (tvModuleSort.Selected.GetNextSibling <> nil);
end;

procedure TfrmMain.rzpgcntrlConfigPageChange(Sender: TObject);
begin
  if (rzpgcntrlConfig.ActivePage = rztbshtModuleConfig) then
  begin
    if ModuleTabCount > 0 then
    begin
      MyMSG(Handle, '修改模块信息，请先关闭所有正在运行的模块');
      Exit;
    end;

    if tvModule.Visible then btnExpandClick(nil);
    CopyTreeView(tvModule, tvModuleSort);

    Winapi.Windows.SetFocus(tvModuleSort.Handle);
    if tvModuleSort.Items.Count > 0 then
      tvModuleSort.Selected := tvModuleSort.Items[0];
    UpdateModuleMoveButtonState;
   end;
end;

procedure TfrmMain.tvModuleSortChange(Sender: TObject; Node: TTreeNode);
begin
  UpdateModuleMoveButtonState;
end;

procedure TfrmMain.btnUPClick(Sender: TObject);
var
  Node, PrevNode: TTreeNode;
begin
  if not btnUP.Enabled then Exit;

  btnModuleMoveSave.Enabled := True;
  Node                      := tvModuleSort.Selected;
  PrevNode                  := Node.GetPrevSibling;

  if PrevNode <> nil then
  begin
    Node.MoveTo(PrevNode, naInsert);
    tvModuleSort.Selected := Node;
    UpdateModuleMoveButtonState;
  end;
end;

procedure TfrmMain.btnDownClick(Sender: TObject);
var
  Node, NextNode: TTreeNode;
begin
  if not btnDown.Enabled then Exit;

  btnModuleMoveSave.Enabled := True;
  Node                      := tvModuleSort.Selected;
  NextNode                  := Node.GetNextSibling;

  if NextNode <> nil then
  begin
    NextNode.MoveTo(Node, naInsert);
    tvModuleSort.Selected := Node;
    UpdateModuleMoveButtonState;
  end;
end;

procedure TfrmMain.btnModuleMoveSaveClick(Sender: TObject);
begin
  pmModule.Items.Clear;
  tvModule.Items.Clear;
  CopyTreeView(tvModuleSort, tvModule);
  LoadModuleToPopMenu(tvModule, pmModule, ModuleMenuItemOnClick);

  with TMemoryStream.Create do
  begin
    WriteComponent(tvModule);
    var strMouduleFileName := ChangeFileExt(ParamStr(0), '.dat');
    SaveToFile(strMouduleFileName);
    Free;
  end;

  if MessageBox(Handle, '希望立即查看效果，关闭配置窗体吗？', c_strTip, MB_YESNO OR MB_ICONQUESTION) = ID_YES then
  begin
    CloseConfigTab;
  end;
end;

{$ENDREGION}
