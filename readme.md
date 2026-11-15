DET
=============

#DET is a multi-document, modular development platform based on DLL dynamic library forms

- [简体中文](readmeCN.md)

## 1. Development Philosophy
    Adhering to the principle of minimizing or avoiding modifications to the original project (EXE) source code (Delphi, VC, QT);
    Supports Delphi DLL form, VC DLL form (Dialog / MFC), and QT DLL form.

## 2. Development Platform
    Developed under Delphi 13.2 and WIN10 X64; 
	The Raize、UDAC controls are used, please install them yourself; All open-source controls are located in the VCL directory; not need install;
    Tested on WIN10 X64; supports both X86 and X64;
    Email: dbyoung@sina.com;

## 3. Features
    Supports Delphi form DLLs;
    Supports VC Window32 form DLLs;
    Supports VC MFC form DLLs;
    Supports QT form DLLs;
    Supports displaying an EXE form program within our form;
    UI same as Chrome Dark-themed  interface to protect eyesight;

## 4. Usage Instructions
### Delphi:
* Modify the original Delphi EXE project file into a DLL project. Simply export the required functions without any changes to the existing code;
* Place the compiled DLL file in the plugins directory;
* Example: plugins\Delphi;
* Delphi function declaration:
```
type TLangStyle = (lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE);
procedure db_ShowDllForm_Plugins(var ls: TLangStyle; var frm: TFormClass; var strModuleName: PAnsiChar); stdcall;
```

### VC2022 / VC2026
* Convert VC form EXE into a DLL for use by other languages: [https://blog.csdn.net/dbyoung/article/details/103987103]
* For VC dialog-based EXEs, no modifications are needed. Compile to obtain LIB, RES, and OBJ files. Create a new Dll.cpp file, export the required functions, link, and generate the DLL module file;
* For VC MFC-based EXEs, modify the EXE project into a DLL project with minor adjustments; compile to obtain the DLL module file;
* Place the compiled DLL file in the plugins directory;
* Example: plugins\vc;
* VC2022 function declaration:
```
enum TLangStyle {lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE};
extern "C" __declspec(dllexport) void db_ShowDllForm_Plugins(TLangStyle* lsFileType, char** strModuleName, char** strClassName, char** strWindowName, const bool show = false)
```

### QT
* For the original QT EXE, no modifications are needed. Compile to obtain LIB, RES, and OBJ files;
* Create a new Dll.cpp file, export the required functions, compile, link, and generate the DLL file;
* Place the compiled DLL file in the plugins directory;
* The process is identical to VC Dialog DLL, including encapsulation and invocation;
* Example: plugins\qt;
* Function declaration:
```
enum TLangStyle {lsDelphi, lsVCDLG, lsVCMFC, lsQT, lsEXE};
extern "C" __declspec(dllexport) void db_ShowDllForm_Plugins(TLangStyle* lsFileType, char** strModuleName, char** strClassName, char** strWindowName, const bool show = false)
```

## 5. DLL Export Function Parameter Descriptions
* Delphi:
```
  procedure db_ShowDllForm_Plugins(var ls: TLangStyle; var frm: TFormClass; var strModuleName: PAnsiChar); stdcall;
 ls                  : DLL form type;
 frm                 : Main form class name in Delphi DLL;
 strModuleName       : Module name;
```
* VC2022/QT:
```
extern "C" __declspec(dllexport) void db_ShowDllForm_Plugins(TLangStyle* lsFileType, char** strModuleName, char** strClassName, char** strWindowName, const bool show = false)

 lsFileType        : DLL form type; whether it is a Dialog-based DLL form, an MFC-based DLL form, or a QT-based DLL form;
 strModuleName     : Module name;
 strClassName      : Main form class name in the DLL;
 strWindowName     : Main form title in the DLL;
 show              : Show/hide the form;
```

## 6. Marked:
    1. File drag-and-drop can only be performed on the main form, not directly on Module DLL windows; this is due to permission issues (the file explorer runs with normal permissions, while DET runs with administrator permissions);
    2. OpenCV SDK x64 version, due to some DLL files larger than 100M in size, they have been compressed into opencv.7z and must be decompressed before use(plugins\opencv);
    3. OpenCV SDK x64 version, utilizes CUDA acceleration, so if your machine does not have an NVIDIA video card, it cannot be used; you can only use x86 version;
    4. When adding a new DLL module to the plugins directory, if there is a DET.dat file in the main program directory, it needs to be deleted before it can take effect;

## 7. Future Work:
    Add database support (development is slow due to limited familiarity with databases and being a side project);

## 8. Effect picture:
![LOGIN](./login.png)
![UI](./DET.png)
