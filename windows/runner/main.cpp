#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <chrono>
#include <iostream>

int APIENTRY wWinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance,
                      _In_ LPWSTR lpCmdLine, _In_ int nCmdShow) {
  // Attach to console if started from terminal
  if (!AttachConsole(ATTACH_PARENT_PROCESS) && IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  std::vector<std::string> command_line_arguments = {};

  flutter::FlutterViewController controller(1280, 720, project);
  HWND hwnd = controller.view()->GetNativeWindow();

  SetWindowText(hwnd, L"Saiful IPTV Player");
  ShowWindow(hwnd, nCmdShow);
  UpdateWindow(hwnd);

  MSG msg;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return 0;
}

