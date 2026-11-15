unit DLLSyncHelper;

interface

implementation

uses Windows, Messages, Classes;

type
  TDLLSystemController = class
  private
    FHandle: HWND;
    FPrevWakeMainThread: TNotifyEvent;
    procedure WakeMainThread(Sender: TObject);
    procedure HookSynchronizeWakeup;
    procedure UnhookSynchronizeWakeup;
  protected
    procedure WndProc(var Message: TMessage);
  public
    constructor Create;
    destructor Destroy; override;
  end;

var
  FDLLController: TDLLSystemController;

{ TDLLSystemController }

constructor TDLLSystemController.Create;
begin
  inherited;

  // 1. 创建一个隐藏窗口用于接收消息
  FHandle := AllocateHWnd(WndProc);

  // 2. 接管全局的 WakeMainThread 事件
  HookSynchronizeWakeup;
end;

destructor TDLLSystemController.Destroy;
begin
  // 3. 恢复并清理
  UnhookSynchronizeWakeup;
  DeallocateHWnd(FHandle);

  inherited;
end;

{ 隐藏窗口的消息处理函数 }
procedure TDLLSystemController.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_NULL then
    CheckSynchronize  // 收到消息后，处理同步请求队列
  else
    Message.Result := DefWindowProc(FHandle, Message.Msg, Message.wParam, Message.lParam);
end;

{ 当有 Synchronize 请求时，此函数会被调用 }
procedure TDLLSystemController.WakeMainThread(Sender: TObject);
begin
  // 向隐藏窗口发送一个空消息，触发 WndProc 中的 CheckSynchronize
  PostMessage(FHandle, WM_NULL, 0, 0);
end;

{ 保存原始的 WakeMainThread，并将自己的过程挂上去 }
procedure TDLLSystemController.HookSynchronizeWakeup;
begin
  FPrevWakeMainThread := Classes.WakeMainThread;
  Classes.WakeMainThread := WakeMainThread;
end;

{ 恢复原始的 WakeMainThread }
procedure TDLLSystemController.UnhookSynchronizeWakeup;
begin
  Classes.WakeMainThread := FPrevWakeMainThread;
end;

initialization
  FDLLController := TDLLSystemController.Create;

finalization
  FDLLController.Free;

end.
