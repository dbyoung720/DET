(* ********************************************************************
  *  DSPack 2.3.3                                                     *
  *                                                                   *
  *  home page : http://www.progdigy.com                              *
  *  email     : hgourvest@progdigy.com                               *
  *   Thanks to Michael Andersen. (DSVideoWindowEx)                   *
  *                                                                   *
  *  date      : 21-02-2003                                           *
  *                                                                   *
  *  The contents of this file are used with permission, subject to   *
  *  the Mozilla Public License Version 1.1 (the "License"); you may  *
  *  not use this file except in compliance with the License. You may *
  *  obtain a copy of the License at                                  *
  *  http://www.mozilla.org/MPL/MPL-1.1.html                          *
  *                                                                   *
  *  Software distributed under the License is distributed on an      *
  *  "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or   *
  *  implied. See the License for the specific language governing     *
  *  rights and limitations under the License.                        *
  *                                                                   *
  *  Contributor(s)                                                   *
  *    Peter J. Haas     <DSPack@pjh2.de>                             *
  *    Andriy Nevhasymyy <a.n@email.com>                              *
  *    Milenko Mitrovic  <dcoder@dsp-worx.de>                         *
  *    Michael Andersen  <michael@mechdata.dk>                        *
  *    Martin Offenwanger <coder@dsplayer.de>                         *
  *                                                                   *
  ******************************************************************** *)

{
  @abstract(Methods & usefull Class for Direct Show programming.)
  @author(Henri Gourvest: hgourvest@progdigy.com)
  @created(Mar 14, 2002)
  @lastmod(Oct 24, 2003)
}

unit DSUtil;
{$B-}  // needed at least for TSysDevEnum.FilterIndexOfFriendlyName
{$WARNINGS OFF}
{$IFDEF COMPILER7_UP}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CAST OFF}
{$ENDIF}

interface

uses
  System.Variants,
  Windows, VCL.Controls, SysUtils, ActiveX, Classes, Winapi.MMSystem, Winapi.DirectShow9, Winapi.WMF9,
  Winapi.DirectDraw;

const
  IID_IPropertyBag: TGUID          = '{55272A00-42CB-11CE-8135-00AA004BB851}';
  IID_ISpecifyPropertyPages: TGUID = '{B196B28B-BAB4-101A-B69C-00AA00341D07}';
  IID_IPersistStream: TGUID        = '{00000109-0000-0000-C000-000000000046}';
  IID_IMoniker: TGUID              = '{0000000F-0000-0000-C000-000000000046}';

  // MS Mepg4 DMO
  MEDIASUBTYPE_MP42: TGUID = '{3234504D-0000-0010-8000-00AA00389B71}';
  // DIVX
  MEDIASUBTYPE_DIVX: TGUID = '{58564944-0000-0010-8000-00AA00389B71}';
  // VoxWare MetaSound
  MEDIASUBTYPE_VOXWARE: TGUID = '{00000075-0000-0010-8000-00AA00389B71}';

  MiliSecPerDay: Cardinal = 86400000;
  MAX_TIME: Int64         = $7FFFFFFFFFFFFFFF;

  bits555: array [0 .. 2] of DWord = ($007C00, $0003E0, $00001F);
  bits565: array [0 .. 2] of DWord = ($00F800, $0007E0, $00001F);
  bits888: array [0 .. 2] of DWord = ($FF0000, $00FF00, $0000FF);

  /// /////////////////////////////////////////////////////////////////////////////
  // DIVX ressources translated from latest OpenDivx DirectX Codec

  // divx
  CLSID_DIVX: TGUID = '{78766964-0000-0010-8000-00aa00389b71}';
  // DIVX
  CLSID_DivX_U: TGUID = '{58564944-0000-0010-8000-00aa00389b71}';
  // dvx1
  CLSID_DivX_: TGUID = '{31787664-0000-0010-8000-00aa00389b71}';
  // DVX1
  CLSID_DivX__U: TGUID = '{31585644-0000-0010-8000-00aa00389b71}';
  // dx50
  CLSID_dx50: TGUID = '{30357864-0000-0010-8000-00aa00389b71}';
  // DX50
  CLSID_DX50_: TGUID = '{30355844-0000-0010-8000-00aa00389b71}';
  // div6
  CLSID_div6: TGUID = '{36766964-0000-0010-8000-00aa00389b71}';
  // DIV6
  CLSID_DIV6_: TGUID = '{36564944-0000-0010-8000-00aa00389b71}';
  // div5
  CLSID_div5: TGUID = '{35766964-0000-0010-8000-00aa00389b71}';
  // DIV5
  CLSID_DIV5_: TGUID = '{35564944-0000-0010-8000-00aa00389b71}';
  // div4
  CLSID_div4: TGUID = '{34766964-0000-0010-8000-00aa00389b71}';
  // DIV4
  CLSID_DIV4_: TGUID = '{34564944-0000-0010-8000-00aa00389b71}';
  // div3
  CLSID_div3: TGUID = '{33766964-0000-0010-8000-00aa00389b71}';
  // DIV3
  CLSID_DIV3_: TGUID = '{33564944-0000-0010-8000-00aa00389b71}';

  CLSID_DIVXCodec: TGUID           = '{78766964-0000-0010-8000-00aa00389b71}';
  IID_IIDivXFilterInterface: TGUID = '{D132EE97-3E38-4030-8B17-59163B30A1F5}';
  CLSID_DivXPropertiesPage: TGUID  = '{310e42a0-f913-11d4-887c-006008dc5c26}';

type
{$IFDEF VER130}
  PPointer = ^Pointer;
{$ENDIF}

  { Interface to control the Divx Decoder filter.
    TODO: discover the last function ... }
  IDivXFilterInterface = interface(IUnknown)
    ['{D132EE97-3E38-4030-8B17-59163B30A1F5}']
    { OpenDivx }
    // current postprocessing level 0..100
    function get_PPLevel(out PPLevel: integer): HRESULT; stdcall;
    // new postprocessing level 0..100
    function put_PPLevel(PPLevel: integer): HRESULT; stdcall;
    // Put the default postprocessing = 0
    function put_DefaultPPLevel: HRESULT; stdcall;
    { DIVX }
    function put_MaxDelayAllowed(maxdelayallowed: integer): HRESULT; stdcall;
    function put_Brightness(brightness: integer): HRESULT; stdcall;
    function put_Contrast(contrast: integer): HRESULT; stdcall;
    function put_Saturation(saturation: integer): HRESULT; stdcall;
    function get_MaxDelayAllowed(out maxdelayallowed: integer): HRESULT; stdcall;
    function get_Brightness(out brightness: integer): HRESULT; stdcall;
    function get_Contrast(out contrast: integer): HRESULT; stdcall;
    function get_Saturation(out saturation: integer): HRESULT; stdcall;
    function put_AspectRatio(x, y: integer): HRESULT; stdcall;
    function get_AspectRatio(out x, y: integer): HRESULT; stdcall;
  end;

  /// /////////////////////////////////////////////////////////////////////////////
  // Ogg Vorbis

type
  TVORBISFORMAT = record
    nChannels: WORD;
    nSamplesPerSec: Longword;
    nMinBitsPerSec: Longword;
    nAvgBitsPerSec: Longword;
    nMaxBitsPerSec: Longword;
    fQuality: Double;
  end;

  // add by pcplayer
  TDsPackDVDTimecode = record
    Hours1: byte;
    Hours10: byte;
    Minutes1: byte;
    Minutes10: byte;
    Seconds1: byte;
    Seconds10: byte;
    Frames1: byte;
    Frames10: byte;
    FrameRateCode: byte;
  end;

const

  // f07e245f-5a1f-4d1e-8bff-dc31d84a55ab
  CLSID_OggSplitter: TGUID = '{f07e245f-5a1f-4d1e-8bff-dc31d84a55ab}';

  // {078C3DAA-9E58-4d42-9E1C-7C8EE79539C5}
  CLSID_OggSplitPropPage: TGUID = '{078C3DAA-9E58-4d42-9E1C-7C8EE79539C5}';

  // 8cae96b7-85b1-4605-b23c-17ff5262b296
  CLSID_OggMux: TGUID = '{8cae96b7-85b1-4605-b23c-17ff5262b296}';

  // {AB97AFC3-D08E-4e2d-98E0-AEE6D4634BA4}
  CLSID_OggMuxPropPage: TGUID = '{AB97AFC3-D08E-4e2d-98E0-AEE6D4634BA4}';

  // {889EF574-0656-4B52-9091-072E52BB1B80}
  CLSID_VorbisEnc: TGUID = '{889EF574-0656-4B52-9091-072E52BB1B80}';

  // {c5379125-fd36-4277-a7cd-fab469ef3a2f}
  CLSID_VorbisEncPropPage: TGUID = '{c5379125-fd36-4277-a7cd-fab469ef3a2f}';

  // 02391f44-2767-4e6a-a484-9b47b506f3a4
  CLSID_VorbisDec: TGUID = '{02391f44-2767-4e6a-a484-9b47b506f3a4}';

  // 77983549-ffda-4a88-b48f-b924e8d1f01c
  CLSID_OggDSAboutPage: TGUID = '{77983549-ffda-4a88-b48f-b924e8d1f01c}';

  // {D2855FA9-61A7-4db0-B979-71F297C17A04}
  MEDIASUBTYPE_Ogg: TGUID = '{D2855FA9-61A7-4db0-B979-71F297C17A04}';

  // cddca2d5-6d75-4f98-840e-737bedd5c63b
  MEDIASUBTYPE_Vorbis: TGUID = '{cddca2d5-6d75-4f98-840e-737bedd5c63b}';

  // 6bddfa7e-9f22-46a9-ab5e-884eff294d9f
  FORMAT_VorbisFormat: TGUID = '{6bddfa7e-9f22-46a9-ab5e-884eff294d9f}';

  /// /////////////////////////////////////////////////////////////////////////////
  // WMF9 Utils
type
  TWMPofiles8 = (wmp_V80_255VideoPDA, wmp_V80_150VideoPDA, wmp_V80_28856VideoMBR, wmp_V80_100768VideoMBR, wmp_V80_288100VideoMBR, wmp_V80_288Video, wmp_V80_56Video, wmp_V80_100Video, wmp_V80_256Video, wmp_V80_384Video, wmp_V80_768Video, wmp_V80_700NTSCVideo, wmp_V80_1400NTSCVideo, wmp_V80_384PALVideo, wmp_V80_700PALVideo, wmp_V80_288MonoAudio, wmp_V80_288StereoAudio, wmp_V80_32StereoAudio, wmp_V80_48StereoAudio, wmp_V80_64StereoAudio, wmp_V80_96StereoAudio, wmp_V80_128StereoAudio, wmp_V80_288VideoOnly, wmp_V80_56VideoOnly, wmp_V80_FAIRVBRVideo, wmp_V80_HIGHVBRVideo, wmp_V80_BESTVBRVideo);

const
  WMProfiles8: array [TWMPofiles8] of TGUID = ('{FEEDBCDF-3FAC-4c93-AC0D-47941EC72C0B}', '{AEE16DFA-2C14-4a2f-AD3F-A3034031784F}', '{D66920C4-C21F-4ec8-A0B4-95CF2BD57FC4}', '{5BDB5A0E-979E-47d3-9596-73B386392A55}', '{D8722C69-2419-4b36-B4E0-6E17B60564E5}', '{3DF678D9-1352-4186-BBF8-74F0C19B6AE2}', '{254E8A96-2612-405c-8039-F0BF725CED7D}', '{A2E300B4-C2D4-4fc0-B5DD-ECBD948DC0DF}', '{BBC75500-33D2-4466-B86B-122B201CC9AE}', '{29B00C2B-09A9-48bd-AD09-CDAE117D1DA7}', '{74D01102-E71A-4820-8F0D-13D2EC1E4872}', '{C8C2985F-E5D9-4538-9E23-9B21BF78F745}', '{931D1BEE-617A-4bcd-9905-CCD0786683EE}', '{9227C692-AE62-4f72-A7EA-736062D0E21E}', '{EC298949-639B-45e2-96FD-4AB32D5919C2}', '{7EA3126D-E1BA-4716-89AF-F65CEE0C0C67}', '{7E4CAB5C-35DC-45bb-A7C0-19B28070D0CC}', '{60907F9F-B352-47e5-B210-0EF1F47E9F9D}', '{5EE06BE5-492B-480a-8A8F-12F373ECF9D4}', '{09BB5BC4-3176-457f-8DD6-3CD919123E2D}', '{1FC81930-61F2-436f-9D33-349F2A1C0F10}', '{407B9450-8BDC-4ee5-88B8-6F527BD941F2}',
    '{8C45B4C7-4AEB-4f78-A5EC-88420B9DADEF}', '{6E2A6955-81DF-4943-BA50-68A986A708F6}', '{3510A862-5850-4886-835F-D78EC6A64042}', '{0F10D9D3-3B04-4fb0-A3D3-88D4AC854ACC}', '{048439BA-309C-440e-9CB4-3DCCA3756423}');

function ProfileFromGUID(const GUID: TGUID): TWMPofiles8;
/// /////////////////////////////////////////////////////////////////////////////

{ Frees an object reference and replaces the reference with Nil. (Delphi4 compatibility) }
procedure FreeAndNil(var Obj);

{ Enable Graphedit to connect with a filter graph.<br>
  The application must register the filter graph instance in the Running Object
  Table (ROT). The ROT is a globally accessible look-up table that keeps track
  of running objects. Objects are registered in the ROT by moniker. To connect
  to the graph, GraphEdit searches the ROT for monikers whose display name matches
  a particular format: !FilterGraph X pid Y.<br>
  <b>Graph:</b> a graph interface (IGraphBuilder, IFilterGraph, IFilterGraph2).<br>
  <b>ID:</b> return the ROT identifier. }
function AddGraphToRot(Graph: IFilterGraph; out ID: integer): HRESULT;

{ Disable Graphedit to connect with your filter graph.<br>
  <b>ID:</b> identifier provided by the @link(AddGraphToRot) method. }
function RemoveGraphFromRot(ID: integer): HRESULT;

{ deprecated, convert a Time code event to TDVD_TimeCode record. }
function IntToTimeCode(x: longint): TDsPackDVDTimecode; // TDVDTimeCode;

{ Return a string explaining a filter graph event. }
function GetEventCodeDef(code: longint): string;

{ General purpose function to delete a heap allocated TAM_MEDIA_TYPE structure
  which is useful when calling IEnumMediaTypes.Next as the interface
  implementation allocates the structures which you must later delete
  the format block may also be a pointer to an interface to release. }
procedure DeleteMediaType(pmt: PAMMediaType);

{ The CreateMediaType function allocates a new AM_MEDIA_TYPE structure,
  including the format block. This also comes in useful when using the
  IEnumMediaTypes interface so that you can copy a media type, you can do
  nearly the same by creating a TMediaType class but as soon as it goes out
  of scope the destructor will delete the memory it allocated
  (this takes a copy of the memory). }
function CreateMediaType(pSrc: PAMMediaType): PAMMediaType;

{ The CopyMediaType function copies an AM_MEDIA_TYPE structure into another
  structure, including the format block. This function allocates the memory
  for the format block. If the pmtTarget parameter already contains an allocated
  format block, a memory leak will occur. To avoid a memory leak, call
  FreeMediaType before calling this function. }
procedure CopyMediaType(pmtTarget: PAMMediaType; pmtSource: PAMMediaType);

{ The FreeMediaType function frees the format block in an AM_MEDIA_TYPE structure.
  Use this function to free just the format block. To delete the AM_MEDIA_TYPE
  structure, call DeleteMediaType. }
procedure FreeMediaType(mt: PAMMediaType);

{ The CreateAudioMediaType function initializes a media type from a TWAVEFORMATEX structure.
  If the bSetFormat parameter is TRUE, the method allocates the memory for the format
  block. If the pmt parameter already contains an allocated format block, a memory
  leak will occur. To avoid a memory leak, call FreeMediaType before calling this function.
  After the method returns, call FreeMediaType again to free the format block. }
function CreateAudioMediaType(pwfx: PWaveFormatEx; pmt: PAMMediaType; bSetFormat: boolean): HRESULT;

{ The FOURCCMap function provides conversion between GUID media subtypes and
  old-style FOURCC 32-bit media tags. In the original Microsoft?Windows?
  multimedia APIs, media types were tagged with 32-bit values created from
  four 8-bit characters and were known as FOURCCs. Microsoft DirectShow?media
  types have GUIDs for the subtype, partly because these are simpler to create
  (creation of a new FOURCC requires its registration with Microsoft).
  Because FOURCCs are unique, a one-to-one mapping has been made possible by
  allocating a range of 4,000 million GUIDs representing FOURCCs. This range
  is all GUIDs of the form: XXXXXXXX-0000-0010-8000-00AA00389B71. }
function FOURCCMap(Fourcc: Cardinal): TGUID;

{ Find the four-character codes wich identifi a codec. }
function GetFOURCC(Fourcc: Cardinal): string;

{ Convert a FCC (Four Char Codes) to Cardinal. A FCC identifie a media type. }
function FCC(str: String): Cardinal;

{ Create the four-character codes from a Cardinal value. }
function MAKEFOURCC(ch0, ch1, ch2, ch3: char): Cardinal;

{ The GetErrorString function retrieves the error message for a given return
  code, using the current language setting. }
function GetErrorString(hr: HRESULT): string;

{ This function examine a media type and return a short description like GraphEdit. }
function GetMediaTypeDescription(MediaType: PAMMediaType): string;

{ Retrieve the Size needed to store a bitmat }
function GetBitmapSize(Header: PBitmapInfoHeader): integer;

function GetBitmapSubtype(bmiHeader: PBitmapInfoHeader): TGUID; stdcall;

function GetTrueColorType(bmiHeader: PBitmapInfoHeader): TGUID; stdcall;

function GetDXSDKMediaPath: String;

function CopyScreenToBitmap(Rect: TRect; pData: PByte; pHeader: PBitmapInfo): HBitmap;

type
  { Property pages.<br>See also: @link(ShowFilterPropertyPage), @link:(HaveFilterPropertyPage). }
  TPropertyPage = (ppDefault, // Simple property page.
    ppVFWCapDisplay,          // Capture Video source dialog box.
    ppVFWCapFormat,           // Capture Video format dialog box.
    ppVFWCapSource,           // Capture Video source dialog box.
    ppVFWCompConfig,          // Compress Configure dialog box.
    ppVFWCompAbout            // Compress About Dialog box.
    );

  { Show the property page associated with the Filter.
    A property page is one way for a filter to support properties that the user can set.
    Many of the filters provided with DirectShow support property pages, they are
    intended for debugging purposes, and are not recommended for application use.
    In most cases the equivalent functionality is provided through a custom interface
    on the filter. An application should control these filters programatically,
    rather than expose their property pages to users. }
function ShowFilterPropertyPage(parent: THandle; Filter: IBaseFilter; PropertyPage: TPropertyPage = ppDefault): HRESULT;

{ Return true if the specified property page is provided by the Filter. }
function HaveFilterPropertyPage(Filter: IBaseFilter; PropertyPage: TPropertyPage = ppDefault): boolean;

{ Show the property page associated with the Pin. <br>
  <b>See also: </b> @link:(ShowFilterPropertyPage). }
function ShowPinPropertyPage(parent: THandle; Pin: IPin): HRESULT;

{ Convert 100 nano sec unit to milisecondes. }
function RefTimeToMiliSec(RefTime: Int64): Cardinal;

{ Convert milisecondes to 100 nano sec unit }
function MiliSecToRefTime(Milisec: Int64): Int64;

{ The mechanism for describing a bitmap format is with the BITMAPINFOHEADER
  This is really messy to deal with because it invariably has fields that
  follow it holding bit fields, palettes and the rest. This function gives
  the number of bytes required to hold a VIDEOINFO that represents it. This
  count includes the prefix information (like the rcSource rectangle) the
  BITMAPINFOHEADER field, and any other colour information on the end.

  WARNING If you want to copy a BITMAPINFOHEADER into a VIDEOINFO always make
  sure that you use the HEADER macro because the BITMAPINFOHEADER field isn't
  right at the start of the VIDEOINFO (there are a number of other fields),

  CopyMemory(HEADER(pVideoInfo),pbmi,sizeof(BITMAPINFOHEADER)); }
function GetBitmapFormatSize(const Header: TBitmapInfoHeader): integer;

{ Retrieve original source rectangle from a TAM_Media_type record. }
function GetSourceRectFromMediaType(const MediaType: TAMMediaType): TRect;

{ TODO -oMichael Andersen: make documentation }
function StretchRect(R, IR: TRect): TRect;

// raise @link(EDirectShowException) exception if failed.
function CheckDSError(hr: HRESULT): HRESULT;

// milenko start (added functions from dshowutil.cpp)
function FindRenderer(pGB: IGraphBuilder; const MediaType: PGUID; out ppFilter: IBaseFilter): HRESULT;
function FindAudioRenderer(pGB: IGraphBuilder; out ppFilter: IBaseFilter): HRESULT;
function FindVideoRenderer(pGB: IGraphBuilder; out ppFilter: IBaseFilter): HRESULT;
function CountFilterPins(pFilter: IBaseFilter; out pulInPins: Cardinal; out pulOutPins: Cardinal): HRESULT;
function CountTotalFilterPins(pFilter: IBaseFilter; out pulPins: Cardinal): HRESULT;
function GetPin(pFilter: IBaseFilter; dirrequired: TPinDirection; iNum: integer; out ppPin: IPin): HRESULT;
function GetInPin(pFilter: IBaseFilter; nPin: integer): IPin;
function GetOutPin(pFilter: IBaseFilter; nPin: integer): IPin;
function FindOtherSplitterPin(pPinIn: IPin; GUID: TGUID; nStream: integer; out ppSplitPin: IPin): HRESULT;
function SeekNextFrame(pSeeking: IMediaSeeking; FPS: Double; Frame: longint): HRESULT;
procedure ShowFilenameByCLSID(clsid: TGUID; out szFilename: WideString);
function GetFileDurationString(pMS: IMediaSeeking; out szDuration: WideString): HRESULT;
function CanFrameStep(pGB: IGraphBuilder): boolean;
procedure UtilFreeMediaType(pmt: PAMMediaType);
procedure UtilDeleteMediaType(pmt: PAMMediaType);
function SaveGraphFile(pGraph: IGraphBuilder; wszPath: WideString): HRESULT;
function LoadGraphFile(pGraph: IGraphBuilder; const wszName: WideString): HRESULT;
// milenko end

// Added by Michael. Used to Detect installed DirectX Version. (Source from getdxver.cpp)
function GetDXVersion(var pdwDirectXVersion: DWord; out strDirectXVersion: String): HRESULT;

type
  // DirectShow Exception class
  EDirectShowException = class(Exception)
    ErrorCode: integer;
  end;

  EDSPackException = class(Exception)
    ErrorCode: integer;
  end;

  // *****************************************************************************
  // TSysDevEnum
  // *****************************************************************************
  { @exclude }
  PFilCatNode = ^TFilCatNode;

  { @exclude }
  TFilCatNode = record
    FriendlyName: Shortstring;
    clsid: TGUID;
  end;

  { Usefull class to enumerate availables filters.
    See "Filter Enumerator" sample. }
  TSysDevEnum = class
  private
    FGUID      : TGUID;
    FCategories: TList;
    FFilters   : TList;
    ACategory  : PFilCatNode;
    procedure GetCat(catlist: TList; CatGUID: TGUID);
    function GetCountCategories: integer;
    function GetCountFilters: integer;
    function GetCategory(item: integer): TFilCatNode;
    function GetFilter(item: integer): TFilCatNode;
  public
    { Select the main category by GUID. For example CLSID_VideoCompressorCategory
      to enumerate Video Compressors. }
    procedure SelectGUIDCategory(GUID: TGUID);
    { Select the main category by Index. }
    procedure SelectIndexCategory(index: integer);
    { Call CountCategories to retrieve categories count. }
    property CountCategories: integer read GetCountCategories;
    { Call CountFilters to retrieve the number of Filte within a Category. }
    property CountFilters: integer read GetCountFilters;
    { Call Categories to read Category Name and GUID. }
    property Categories[item: integer]: TFilCatNode read GetCategory;
    { Call Filters to read Filter Name and GUID. }
    property Filters[item: integer]: TFilCatNode read GetFilter;
    { Find filter index by FriendlyName; -1, if not found }
    function FilterIndexOfFriendlyName(const FriendlyName: string): integer;
    { Call GetBaseFilter to retrieve the IBaseFilter interface corresponding to index. }
    function GetBaseFilter(index: integer): IBaseFilter; overload;
    { Call GetBaseFilter to retrieve the IBaseFilter interface corresponding to GUID. }
    function GetBaseFilter(GUID: TGUID): IBaseFilter; overload;
    { Call GetMoniker to retrieve the IMoniker interface corresponding to index.
      This interface can be used to store a filter with the @link(TBaseFiter) class. }
    function GetMoniker(index: integer): IMoniker;
    { constructor }
    constructor Create; overload;
    { constructor. Create the class and initialize the main category with the GUID. }
    constructor Create(GUID: TGUID); overload;
    { destructor }
    destructor Destroy; override;
  end;

  // *****************************************************************************
  // TFilterList
  // *****************************************************************************

  { This class can enumerate all filters in a FilterGraph. }
  TFilterList = class(TInterfaceList)
  private
    Graph: IFilterGraph;
    function GetFilter(index: integer): IBaseFilter;
    procedure PutFilter(index: integer; item: IBaseFilter);
    function GetFilterInfo(index: integer): TFilterInfo;
  public
    { Create a list based on a FilterGraph. }
    constructor Create(FilterGraph: IFilterGraph); overload;
    { Destructor. }
    destructor Destroy; override;
    { Update the list. }
    procedure Update;
    { Reload the list from another FilterGraph. }
    procedure Assign(FilterGraph: IFilterGraph);
    { Call First to obtain the first interface in the list. }
    function First: IBaseFilter;
    { Call IndexOf to obtain the index of an interface. }
    function IndexOf(item: IBaseFilter): integer;
    { Call Add to add an interface to the list. }
    function Add(item: IBaseFilter): integer;
    { Call Insert to insert an interface into the list. Item is the interface to
      insert, and Index indicates the position (zero-offset) where the interface
      should be added. }
    procedure Insert(index: integer; item: IBaseFilter);
    { Call Last to obtain the last interface in the list. }
    function Last: IBaseFilter;
    { Call Remove to remove an interface from the list. Remove returns the index
      of the removed interface, or ? if the interface was not found. }
    function Remove(item: IBaseFilter): integer;
    { Use Items to directly access an interface in the list. Index identifies each
      interface by its position in the list. }
    property Items[Index: integer]: IBaseFilter read GetFilter write PutFilter; default;
    { call FilterInfo to retrieve the Filer name and his FilterGraph. }
    property FilterInfo[Index: integer]: TFilterInfo read GetFilterInfo;
  end;

  // ******************************************************************************
  // TPinList
  // ******************************************************************************

  { Helper class to enumerate pins on a filter. }
  TPinList = class(TInterfaceList)
  private
    Filter: IBaseFilter;
    function GetPin(index: integer): IPin;
    procedure PutPin(index: integer; item: IPin);
    function GetPinInfo(index: integer): TPinInfo;
    function GetConnected(index: integer): boolean;
  public
    { Create a Pin list from the IBaseFilter interface. }
    constructor Create(BaseFilter: IBaseFilter); overload;
    { Destructor. }
    destructor Destroy; override;
    { Update the Pin list. }
    procedure Update;
    { Load a Pin list from the IBaseFilter Interface. }
    procedure Assign(BaseFilter: IBaseFilter);
    { Return the First Pin from in the list. }
    function First: IPin;
    { Return the index of Pin in the list. }
    function IndexOf(item: IPin): integer;
    { Add A Pin to the list. }
    function Add(item: IPin): integer;
    { Insert a pin at the given position. }
    procedure Insert(index: integer; item: IPin);
    { Return the last pin in the list. }
    function Last: IPin;
    { Remove a pin from the lis. }
    function Remove(item: IPin): integer;
    { Return the the pin interface at the defined position. }
    property Items[Index: integer]: IPin read GetPin write PutPin; default;
    { Retrieve informations on a pin. }
    property PinInfo[Index: integer]: TPinInfo read GetPinInfo;
    property Connected[Index: integer]: boolean read GetConnected;
  end;

  // *****************************************************************************
  // TMediaType
  // *****************************************************************************

  { Uses TMediaType to configure media types. This class have a special property editor.
    See @link(TSampleGrabber) }
  TMediaType = class(TPersistent)
  private
    function GetMajorType: TGUID;
    procedure SetMajorType(mt: TGUID);
    function GetSubType: TGUID;
    procedure SetSubType(ST: TGUID);
    procedure SetFormatType(const GUID: TGUID);
    function GetFormatType: TGUID;
    procedure ReadData(Stream: TStream);
    procedure WriteData(Stream: TStream);
  protected
    { @exclude }
    procedure DefineProperties(Filer: TFiler); override;
  public
    { Local copy of the Media Type. }
    AMMediaType: PAMMediaType;
    { Destructor method. }
    destructor Destroy; override;
    { Constructor method. }
    constructor Create; overload;
    { Constructor method. Initialised with majortype. }
    constructor Create(majortype: TGUID); overload;
    { Constructor method. Initialised with another media type. }
    constructor Create(MediaType: PAMMediaType); overload;
    { Constructor method. Initialised with another TMediaType }
    constructor Create(MTClass: TMediaType); overload;
    { Copy from another TMediaType. }
    procedure Assign(Source: TPersistent); override;
    { Copy from another PAM_MEDIA_TYPE. }
    procedure Read(MediaType: PAMMediaType);
    { Tests for equality between TMediaType objects.<br>
      <b>rt:</b> Reference to the TMediaType object to compare.<br>
      Returns TRUE if rt is equal to this object. Otherwise, returns FALSE. }
    function Equal(MTClass: TMediaType): boolean; overload;
    { Tests for inequality between TMediaType objects.<br>
      <b>rt:</b> Reference to the TMediaType object to compare.<br>
      Returns TRUE if rt is not equal to this object. Otherwise, returns FALSE. }
    function NotEqual(MTClass: TMediaType): boolean; overload;
    { The IsValid method determines whether a major type has been assigned to this object.
      Returns TRUE if a major type has been assigned to this object. Otherwise, returns FALSE.
      By default, TMediaType objects are initialized with a major type of GUID_NULL.
      Call this method to determine whether the object has been correctly initialized. }
    function IsValid: boolean;
    { The IsFixedSize method determines if the samples have a fixed size or a variable size.
      Returns the value of the bFixedSizeSamples member. }
    function IsFixedSize: boolean;
    { The IsTemporalCompressed method determines if the stream uses temporal compression.
      Returns the value of the bTemporalCompression member. }
    function IsTemporalCompressed: boolean;
    { The GetSampleSize method retrieves the sample size.
      If the sample size is fixed, returns the sample size in bytes. Otherwise,
      returns zero. }
    function GetSampleSize: ULONG;
    { The SetSampleSize method specifies a fixed sample size, or specifies that
      samples have a variable size. If value of sz is zero, the media type uses
      variable sample sizes. Otherwise, the sample size is fixed at sz bytes. }
    procedure SetSampleSize(SZ: ULONG);
    { The SetVariableSize method specifies that samples do not have a fixed size.
      This method sets the bFixedSizeSamples member to FALSE. Subsequent calls to the TMediaType.GetSampleSize method return zero. }
    procedure SetVariableSize;
    { The SetTemporalCompression method specifies whether samples are compressed
      using temporal (interframe) compression. }
    procedure SetTemporalCompression(bCompressed: boolean);
    { read/write pointer to format - can't change length without
      calling SetFormat, AllocFormatBuffer or ReallocFormatBuffer }
    function Format: Pointer;
    { The FormatLength method retrieves the length of the format block. }
    function FormatLength: ULONG;
    { The SetFormat method specifies the format block.<br>
      <b>pFormat:</b> Pointer to a block of memory that contains the format block.<br>
      <b>length:</b> Length of the format block, in bytes. }
    function SetFormat(pFormat: Pointer; length: ULONG): boolean;
    { The ResetFormatBuffer method deletes the format block. }
    procedure ResetFormatBuffer;
    { The AllocFormatBuffer method allocates memory for the format block.<br>
      <b>length:</b> Size required for the format block, in bytes.<br>
      Returns a pointer to the new block if successful. Otherwise, returns nil.<br>
      If the method successfully allocates a new format block, it frees the existing
      format block. If the allocation fails, the method leaves the existing format block. }
    function AllocFormatBuffer(length: ULONG): Pointer;
    { The ReallocFormatBuffer method reallocates the format block to a new size.<br>
      <b>length:</b> New size required for the format block, in bytes. Must be greater
      than zero.<br>
      Returns a pointer to the new block if successful. Otherwise, returns either
      a pointer to the old format block, or nil.
      This method allocates a new format block. It copies as much of the existing
      format block as possible into the new format block. If the new block is
      smaller than the existing block, the existing format block is truncated.
      If the new block is larger, the contents of the additional space are undefined.
      They are not explicitly set to zero. }
    function ReallocFormatBuffer(length: ULONG): Pointer;
    { The InitMediaType method initializes the media type.
      This method zeroes the object's memory, sets the fixed-sample-size property
      to TRUE, and sets the sample size to 1. }
    procedure InitMediaType;
    { The MatchesPartial method determines if this media type matches a partially
      specified media type. The media type specified by ppartial can have a value
      of GUID_NULL for the major type, subtype, or format type. Any members with
      GUID_NULL values are not tested. (In effect, GUID_NULL acts as a wildcard.)
      Members with values other than GUID_NULL must match for the media type to match. }
    function MatchesPartial(ppartial: TMediaType): boolean;
    { The IsPartiallySpecified method determines if the media type is partially
      defined. A media type is partial if the major type, subtype, or format type
      is GUID_NULL. The IPin.Connect method can accept partial media types.
      The implementation does not actually test the subtype. If there is a specified
      format type, the media type is not considered partial, even if the subtype is GUID_NULL. }
    function IsPartiallySpecified: boolean;
    { Set or retrieve the MajorType GUID. }
    property majortype: TGUID read GetMajorType write SetMajorType;
    { Set or retrieve the SubType GUID. }
    property SubType: TGUID read GetSubType write SetSubType;
    { Set or retrieve the FormatType GUID. }
    property FormatType: TGUID read GetFormatType write SetFormatType;
  end;

  // *****************************************************************************
  // TEnumMediaType
  // *****************************************************************************

  { This class can retrieve all media types from a pin, a file or an IEnumMediaTypes interface. }
  TEnumMediaType = class(TObject)
  private
    FList: TList;
    function GetItem(index: integer): TMediaType;
    procedure SetItem(index: integer; item: TMediaType);
    function GetMediaDescription(index: integer): string;
    function GetCount: integer;
  public
    { Constructor method. }
    constructor Create; overload;
    { Constructor method enumerating all media types on a pin. }
    constructor Create(Pin: IPin); overload;
    { Constructor method enumerating media types provided by a IEnumMediaType interface. }
    constructor Create(EnumMT: IEnumMediaTypes); overload;
    { Constructor method enumerating all media types availables in a media file.
      Support WMF files. }
    constructor Create(FileName: TFileName); overload;
    { Destructor method. }
    destructor Destroy; override;
    { Enumerate all media types on a pin. }
    procedure Assign(Pin: IPin); overload;
    { Enumerate media types provided by a IEnumMediaType interface. }
    procedure Assign(EnumMT: IEnumMediaTypes); overload;
    { Enumerate all media types availables in a media file. Support WMF files. }
    procedure Assign(FileName: TFileName); overload;
    { Add a media type to the list. }
    function Add(item: TMediaType): integer;
    { Clear the list. }
    procedure Clear;
    { Remove a media type from the list. }
    procedure Delete(index: integer);
    { Retrieve a mediaa type. }
    property Items[Index: integer]: TMediaType read GetItem write SetItem;
    { Return a string describing the media type. }
    property MediaDescription[Index: integer]: string read GetMediaDescription;
    { Number of items in the list. }
    property Count: integer read GetCount;
  end;

  // *****************************************************************************
  // TPersistentMemory
  // *****************************************************************************

  { For internal use. This class is designed to store a custom memory stream with
    a form. It is the ancestor of @link(TBaseFilter). }
  TPersistentMemory = class(TPersistent)
  private
    FData      : Pointer;
    FDataLength: Cardinal;
    procedure ReadData(Stream: TStream);
    procedure WriteData(Stream: TStream);
    function Equal(Memory: TPersistentMemory): boolean;
    procedure AllocateMemory(ALength: Cardinal);
  protected
    { @exclude }
    procedure AssignTo(Dest: TPersistent); override;
    { @exclude }
    procedure DefineProperties(Filer: TFiler); override;
  public
    { Set/Get the buffer length. }
    property DataLength: Cardinal read FDataLength write AllocateMemory;
    { Pointer to buffer. }
    property Data: Pointer read FData;
    { Constructor }
    constructor Create; virtual;
    { Destructor }
    destructor Destroy; override;
    { Call Assign to copy the properties or other attributes of one object from another. }
    procedure Assign(Source: TPersistent); override;
  end;

  // *****************************************************************************
  // TBaseFilter
  // *****************************************************************************

  { This class can store a custom filter as a moniker within the dfm file. }
  TBaseFilter = class(TPersistentMemory)
  private
    procedure SetMoniker(Moniker: IMoniker);
    function GetMoniker: IMoniker;
  public
    { Set or retrieve the moniker interface. }
    property Moniker: IMoniker read GetMoniker write SetMoniker;
    { Read a property bag. For example you can read the GUID identifier (PropertyBag('CLSID')) }
    function PropertyBag(Name: WideString): OleVariant;
    { Return the IBaseFilter interface corresponding to filter. }
    function CreateFilter: IBaseFilter;
  end;

  // *****************************************************************************
  // DxDiag.h
  // *****************************************************************************

const
  // This identifier is passed to IDxDiagProvider::Initialize in order to ensure that an
  // application was built against the correct header files. This number is
  // incremented whenever a header (or other) change would require applications
  // to be rebuilt. If the version doesn't match, IDxDiagProvider::Initialize will fail.
  // (The number itself has no meaning.)
  DXDIAG_DX9_SDK_VERSION = 111;

  (* ***************************************************************************
    *
    * DxDiag Errors
    *
    *************************************************************************** *)
  DXDIAG_E_INSUFFICIENT_BUFFER = HRESULT($8007007A);

  (* ***************************************************************************
    *
    * DxDiag CLSIDs
    *
    *************************************************************************** *)
  CLSID_DxDiagProvider: TGUID = '{A65B8071-3BFE-4213-9A5B-491DA4461CA7}';

  (* ***************************************************************************
    *
    * DxDiag Interface IIDs
    *
    *************************************************************************** *)
  IID_IDxDiagProvider: TGUID  = '{9C6B4CB0-23F8-49CC-A3ED-45A55000A6D2}';
  IID_IDxDiagContainer: TGUID = '{7D0F462F-4064-4862-BC7F-933E5058C10F}';

Type
  (* ***************************************************************************
    *
    * DxDiag Structures
    *
    *************************************************************************** *)

  PDXDIAG_INIT_PARAMS = ^TDxDiagInitParams;

  _DXDIAG_INIT_PARAMS = record
    dwSize: DWord;                // Size of this structure.
    dwDxDiagHeaderVersion: DWord; // Pass in DXDIAG_DX9_SDK_VERSION.  This verifies
    // the header and dll are correctly matched.
    bAllowWHQLChecks: boolean; // If true, allow dxdiag to check if drivers are
    // digital signed as logo'd by WHQL which may
    // connect via internet to update WHQL certificates.
    pReserved: Pointer; // Reserved. Must be NULL.
  End;

{$EXTERNALSYM _DXDIAG_INIT_PARAMS}

  DXDIAG_INIT_PARAMS = _DXDIAG_INIT_PARAMS;
{$EXTERNALSYM DXDIAG_INIT_PARAMS}
  TDxDiagInitParams = _DXDIAG_INIT_PARAMS;

  (* ***************************************************************************
    *
    * DxDiag Application Interfaces
    *
    *************************************************************************** *)

  IDxDiagProvider  = interface;
  IDxDiagContainer = interface;

  IDxDiagProvider = interface(IUnknown)
    ['{9C6B4CB0-23F8-49CC-A3ED-45A55000A6D2}']
    // *** IDxDiagProvider methods *** //
    function Initialize(pParams: PDXDIAG_INIT_PARAMS): HRESULT; stdcall;
    function GetRootContainer(Out ppInstance: IDxDiagContainer): HRESULT; stdcall;
  End;

  IDxDiagContainer = interface(IUnknown)
    ['{7D0F462F-4064-4862-BC7F-933E5058C10F}']
    // *** IDxDiagContainer methods *** //
    function GetNumberOfChildContainers(Out pdwCount: DWord): HRESULT; stdcall;
    function EnumChildContainerNames(dwIndex: DWord; pwszContainer: PWideChar; cchContainer: DWord): HRESULT; stdcall;
    function GetChildContainer(pwszContainer: PWideChar; Out ppInstance: IDxDiagContainer): HRESULT; stdcall;
    function GetNumberOfProps(Out pdwCount: DWord): HRESULT; stdcall;
    function EnumPropNames(dwIndex: DWord; pwszPropName: PWideChar; cchPropName: DWord): HRESULT; stdcall;
    function GetProp(pwszPropName: PWideChar; Out pvarProp: OleVariant): HRESULT; stdcall;
  End;

  // milenko start DMO TMediaBuffer implementation
  TMediaBuffer = class(TObject, IMediaBuffer, IUnknown)
  private
    FRefCount : integer;
    FLength   : DWord;
    FMaxLength: DWord;
    FData     : PByte;
  public
    constructor Create(MaxLen: DWord);
    destructor Destroy; override;
    class function CreateBuffer(MaxLen: DWord; const IID: TGUID; out Obj): HRESULT;
    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
    function _AddRef: integer; stdcall;
    function _Release: integer; stdcall;
    // IMediaBuffer methods
    function SetLength(cbLength: DWord): HRESULT; stdcall;
    function GetMaxLength(out pcbMaxLength: DWord): HRESULT; stdcall;
    function GetBufferAndLength(out ppBuffer: PByte; // not filled if NULL
      out pcbLength: DWord                           // not filled if NULL
      ): HRESULT; stdcall;
  end;
  // milenko end

  // milenko start wxutil implementation
const
  RESOLUTION   = DWord(1);   // High resolution timer
  ADVISE_CACHE = integer(4); // Default cache size

  MILLISECONDS = LONGLONG(1000);                // 10 ^ 3
  NANOSECONDS  = LONGLONG(1000000000);          // 10 ^ 9
  UNITS        = LONGLONG(NANOSECONDS div 100); // 10 ^ 7

  TimeZero = LONGLONG(0);

type
  DWORDLONG = LONGLONG;  // Should be unsigned Int64 !!!
  ULONGLONG = DWORDLONG; // Should be unsigned Int64 !!!

function UInt32x32To64(a, b: DWord): ULONGLONG;
function Int64x32Div32(a: LONGLONG; b, c, d: longint): LONGLONG;
function Int32x32To64(a, b: integer): Int64;
function MILLISECONDS_TO_100NS_UNITS(Ms: LONGLONG): LONGLONG;

function llMulDiv(a, b, c, d: LONGLONG): LONGLONG;
function AmGetLastErrorToHResult: HRESULT;
function IsEqualObject(pFirst, pSecond: IUnknown): boolean;
// milenko end

// milenko start namedguid implementation
const
  IID_IDirectDrawKernel: TGUID        = '{8D56C120-6A08-11D0-9B06-00A0C903A3B8}';
  IID_IDirectDrawSurfaceKernel: TGUID = '{60755DA0-6A40-11D0-9B06-00A0C903A3B8}';

function GetGUIDString(GUID: TGUID): String;
// milenko end

// milenko start (usefull functions to get linear amplification)
function GetBasicAudioVolume(Value: integer): integer;
function SetBasicAudioVolume(Value: integer): integer;
function GetBasicAudioPan(Value: integer): integer;
function SetBasicAudioPan(Value: integer): integer;
// milenko end

// milenok start (yet another delphi5 compatibility ...)
{$IFDEF VER130}
function GUIDToString(const GUID: TGUID): string;
function StringToGUID(const S: string): TGUID;
function EnsureRange(const AValue, AMin, AMax: integer): integer;
{$ENDIF}
// milenko end

{$IFNDEF COMPILER6_UP}
procedure Set8087CW(NewCW: WORD);
function Get8087CW: WORD;
{$ENDIF}
// previously TMPEGHeaderBitsWrapper
function MPEGHeaderBitsGetSectionLength(Header: PMPEGHeaderBits): WORD;
function MPEGHeaderBitsGetReserved(Header: PMPEGHeaderBits): WORD;
function MPEGHeaderBitsGetPrivateIndicator(Header: PMPEGHeaderBits): WORD;
function MPEGHeaderBitsGetSectionSyntaxIndicator(Header: PMPEGHeaderBits): WORD;
procedure MPEGHeaderBitsSetSectionLength(Header: PMPEGHeaderBits; AValue: WORD);
procedure MPEGHeaderBitsSetReserved(Header: PMPEGHeaderBits; AValue: WORD);
procedure MPEGHeaderBitsSetPrivateIndicator(Header: PMPEGHeaderBits; AValue: WORD);
procedure MPEGHeaderBitsSetSectionSyntaxIndicator(Header: PMPEGHeaderBits; AValue: WORD);

// previously TPIDBitsWrapper
function PIDBitsGetReserved(PIDBits: PPIDBits): WORD;
function PIDBitsGetProgramId(PIDBits: PPIDBits): WORD;
procedure PIDBitsSetReserved(PIDBits: PPIDBits; AValue: WORD);
procedure PIDBitsSetProgramId(PIDBits: PPIDBits; AValue: WORD);

// previously TPIDBitsWrapper
function MPEGHeaderVersionBitsGetCurrentNextIndicator(MPEGHeaderVersionBits: PMPEGHeaderVersionBits): byte;
function MPEGHeaderVersionBitsGetVersionNumber(MPEGHeaderVersionBits: PMPEGHeaderVersionBits): byte;
function MPEGHeaderVersionBitsGetReserved(MPEGHeaderVersionBits: PMPEGHeaderVersionBits): byte;
procedure MPEGHeaderVersionBitsSetCurrentNextIndicator(MPEGHeaderVersionBits: PMPEGHeaderVersionBits; AValue: byte);
procedure MPEGHeaderVersionBitsSetVersionNumber(MPEGHeaderVersionBits: PMPEGHeaderVersionBits; AValue: byte);
procedure MPEGHeaderVersionBitsSetReserved(MPEGHeaderVersionBits: PMPEGHeaderVersionBits; AValue: byte);

implementation

uses
  DirectSound, Math, ComObj, Registry;

{$IFNDEF COMPILER6_UP}

var
  Default8087CW: WORD = $1372;

procedure Set8087CW(NewCW: WORD);
begin
  Default8087CW := NewCW;
  {$IF CPUX86}
  asm
    FNCLEX
    FLDCW Default8087CW
  end;
  {$ENDIF}
end;

function Get8087CW: WORD;
asm
  {$IF CPUX86}
  PUSH   0
  FNSTCW [ESP].Word
  POP    EAX
  {$ENDIF}
end;
{$ENDIF}

function ProfileFromGUID(const GUID: TGUID): TWMPofiles8;
begin
  for result := low(TWMPofiles8) to high(TWMPofiles8) do
    if IsEqualGUID(GUID, WMProfiles8[result]) then
      Exit;
  result := TWMPofiles8(-1);
end;

// ----------------------------------------------------------------------------
// Retrieve the Size needed to store a bitmat
// ----------------------------------------------------------------------------
function GetBitmapSize(Header: PBitmapInfoHeader): integer;

  function WIDTHBYTES(bits: DWord): DWord;
  begin
    result := DWord((bits + 31) and (not 31)) div 8;
  end;

  function DIBWIDTHBYTES(bi: PBitmapInfoHeader): DWord;
  begin
    result := DWord(WIDTHBYTES(DWord(bi.biWidth) * DWord(bi.biBitCount)));
  end;

  function _DIBSIZE(bi: PBitmapInfoHeader): integer;
  begin
    result := DIBWIDTHBYTES(bi) * DWord(bi.biHeight);
  end;

begin
  if (Header.biHeight < 0) then
    result := -1 * _DIBSIZE(Header)
  else
    result := _DIBSIZE(Header);
end;


// This is called if the header has a 16 bit colour depth and needs to work
// out the detailed type from the bit fields (either RGB 565 or RGB 555)

function GetTrueColorType(bmiHeader: PBitmapInfoHeader): TGUID; stdcall;
var
  bmInfo: PBitmapInfo;
begin
  bmInfo := PBitmapInfo(bmiHeader);
  ASSERT(bmiHeader.biBitCount = 16);

  // If its BI_RGB then it's RGB 555 by default
  if (bmiHeader.biCompression = BI_RGB) then
  begin
    result := MEDIASUBTYPE_RGB555;
    Exit;
  end;

  if CompareMem(@bmInfo.bmiColors, @bits555, SizeOf(bits555)) then
    result := MEDIASUBTYPE_RGB555
  else if CompareMem(@bmInfo.bmiColors, @bits565, SizeOf(bits565)) then
    result := MEDIASUBTYPE_RGB565
  else
    result := GUID_NULL;
end;

// Given a BITMAPINFOHEADER structure this returns the GUID sub type that is
// used to describe it in format negotiations. For example a video codec fills
// in the format block with a VIDEOINFO structure, it also fills in the major
// type with MEDIATYPE_VIDEO and the subtype with a GUID that matches the bit
// count, for example if it is an eight bit image then MEDIASUBTYPE_RGB8

function GetBitmapSubtype(bmiHeader: PBitmapInfoHeader): TGUID; stdcall;
begin
  ASSERT(bmiHeader <> nil);
  // If it's not RGB then create a GUID from the compression type
  if (bmiHeader.biCompression <> BI_RGB) then
    if (bmiHeader.biCompression <> BI_BITFIELDS) then
    begin
      result := FOURCCMap(bmiHeader.biCompression);
      Exit;
    end;

  // Map the RGB DIB bit depth to a image GUID
  case (bmiHeader.biBitCount) of
    1:
      result := MEDIASUBTYPE_RGB1;
    4:
      result := MEDIASUBTYPE_RGB4;
    8:
      result := MEDIASUBTYPE_RGB8;
    16:
      result := GetTrueColorType(bmiHeader);
    24:
      result := MEDIASUBTYPE_RGB24;
    32:
      result := MEDIASUBTYPE_RGB32;
  else
    result := GUID_NULL;
  end;

end;

// ----------------------------------------------------------------------------
// Frees an object reference and replaces the reference with Nil.
// ----------------------------------------------------------------------------
procedure FreeAndNil(var Obj);
var
  Temp: TObject;
begin
  Temp         := TObject(Obj);
  Pointer(Obj) := nil;
  Temp.Free;
end;

// ----------------------------------------------------------------------------
// Enable Graphedit to connect with your filter graph
// ----------------------------------------------------------------------------
function AddGraphToRot(Graph: IFilterGraph; out ID: integer): HRESULT;
var
  Moniker: IMoniker;
  ROT    : IRunningObjectTable;
  wsz    : WideString;
begin
  result := GetRunningObjectTable(0, ROT);
  if (result <> S_OK) then
    Exit;
  wsz    := Format('FilterGraph %p pid %x', [Pointer(Graph), GetCurrentProcessId()]);
  result := CreateItemMoniker('!', PWideChar(wsz), Moniker);
  if (result <> S_OK) then
    Exit;
  result  := ROT.Register(0, Graph, Moniker, ID);
  Moniker := nil;
end;

// ----------------------------------------------------------------------------
// Disable Graphedit to connect with your filter graph
// ----------------------------------------------------------------------------
function RemoveGraphFromRot(ID: integer): HRESULT;
var
  ROT: IRunningObjectTable;
begin
  result := GetRunningObjectTable(0, ROT);
  if (result <> S_OK) then
    Exit;
  result := ROT.Revoke(ID);
  ROT    := nil;
end;

function IntToTimeCode(x: longint): TDsPackDVDTimecode; // TDVDTimeCode;  by pcplayer
begin
  result.Hours1    := (x and $F0000000) shr 28;
  result.Hours10   := (x and $0F000000) shr 24;
  result.Minutes1  := (x and $00F00000) shr 20;
  result.Minutes10 := (x and $000F0000) shr 16;
  result.Seconds1  := (x and $0000F000) shr 12;
  result.Seconds10 := (x and $00000F00) shr 08;
  result.Frames1   := (x and $000000F0) shr 04;
  result.Frames10  := (x and $0000000C) shr 02;
  // Result.FrameRateCode := (x and $00000003) shr 00;   //Dspack 原来有着项,但XE3底下的 Winapi.DirectShow9.pas里面这个类型的声明里没有这项了.pcplayer
end;

function GetEventCodeDef(code: longint): string;
begin
  case code of
    EC_ACTIVATE:
      result := 'EC_ACTIVATE - A video window is being activated or deactivated.';
    EC_BUFFERING_DATA:
      result := 'EC_BUFFERING_DATA - The graph is buffering data, or has stopped buffering data.';
    EC_CLOCK_CHANGED:
      result := 'EC_CLOCK_CHANGED - The reference clock has changed.';
    EC_COMPLETE:
      result := 'EC_COMPLETE - All data from a particular stream has been rendered.';
    EC_DEVICE_LOST:
      result := 'EC_DEVICE_LOST - A Plug and Play device was removed or has become available again.';
    EC_DISPLAY_CHANGED:
      result := 'EC_DISPLAY_CHANGED - The display mode has changed.';
    EC_END_OF_SEGMENT:
      result := 'EC_END_OF_SEGMENT - The end of a segment has been reached.';
    EC_ERROR_STILLPLAYING:
      result := 'EC_ERROR_STILLPLAYING - An asynchronous command to run the graph has failed.';
    EC_ERRORABORT:
      result := 'EC_ERRORABORT - An operation was aborted because of an error.';
    EC_FULLSCREEN_LOST:
      result := 'EC_FULLSCREEN_LOST - The video renderer is switching out of full-screen mode.';
    EC_GRAPH_CHANGED:
      result := 'EC_GRAPH_CHANGED - The filter graph has changed.';
    EC_NEED_RESTART:
      result := 'EC_NEED_RESTART - A filter is requesting that the graph be restarted.';
    EC_NOTIFY_WINDOW:
      result := 'EC_NOTIFY_WINDOW - Notifies a filter of the video renderer''s window.';
    EC_OLE_EVENT:
      result := 'EC_OLE_EVENT - A filter is passing a text string to the application.';
    EC_OPENING_FILE:
      result := 'EC_OPENING_FILE - The graph is opening a file, or has finished opening a file.';
    EC_PALETTE_CHANGED:
      result := 'EC_PALETTE_CHANGED - The video palette has changed.';
    EC_PAUSED:
      result := 'EC_PAUSED - A pause request has completed.';
    EC_QUALITY_CHANGE:
      result := 'EC_QUALITY_CHANGE - The graph is dropping samples, for quality control.';
    EC_REPAINT:
      result := 'EC_REPAINT - A video renderer requires a repaint.';
    EC_SEGMENT_STARTED:
      result := 'EC_SEGMENT_STARTED - A new segment has started.';
    EC_SHUTTING_DOWN:
      result := 'EC_SHUTTING_DOWN - The filter graph is shutting down, prior to being destroyed.';
    EC_SNDDEV_IN_ERROR:
      result := 'EC_SNDDEV_IN_ERROR - An audio device error has occurred on an input pin.';
    EC_SNDDEV_OUT_ERROR:
      result := 'EC_SNDDEV_OUT_ERROR - An audio device error has occurred on an output pin.';
    EC_STARVATION:
      result := 'EC_STARVATION - A filter is not receiving enough data.';
    EC_STEP_COMPLETE:
      result := 'EC_STEP_COMPLETE - A filter performing frame stepping has stepped the specified number of frames.';
    EC_STREAM_CONTROL_STARTED:
      result := 'EC_STREAM_CONTROL_STARTED - A stream-control start command has taken effect.';
    EC_STREAM_CONTROL_STOPPED:
      result := 'EC_STREAM_CONTROL_STOPPED - A stream-control start command has taken effect.';
    EC_STREAM_ERROR_STILLPLAYING:
      result := 'EC_STREAM_ERROR_STILLPLAYING - An error has occurred in a stream. The stream is still playing.';
    EC_STREAM_ERROR_STOPPED:
      result := 'EC_STREAM_ERROR_STOPPED - A stream has stopped because of an error.';
    EC_USERABORT:
      result := 'EC_USERABORT - The user has terminated playback.';
    EC_VIDEO_SIZE_CHANGED:
      result := 'EC_VIDEO_SIZE_CHANGED - The native video size has changed.';
    EC_WINDOW_DESTROYED:
      result := 'EC_WINDOW_DESTROYED - The video renderer was destroyed or removed from the graph.';
    EC_TIMECODE_AVAILABLE:
      result := 'EC_TIMECODE_AVAILABLE- Sent by filter supporting timecode.';
    EC_EXTDEVICE_MODE_CHANGE:
      result := 'EC_EXTDEVICE_MODE_CHANGE - Sent by filter supporting IAMExtDevice.';
    EC_CLOCK_UNSET:
      result := 'EC_CLOCK_UNSET - notify the filter graph to unset the current graph clock.';
    EC_TIME:
      result := 'EC_TIME - The requested reference time occurred (currently not used).';
    EC_VMR_RENDERDEVICE_SET:
      result := 'EC_VMR_RENDERDEVICE_SET - Identifies the type of rendering mechanism the VMR is using to display video.';

    EC_DVD_ANGLE_CHANGE:
      result := 'EC_DVD_ANGLE_CHANGE - Signals that either the number of available angles changed or that the current angle number changed.';
    EC_DVD_ANGLES_AVAILABLE:
      result := 'EC_DVD_ANGLES_AVAILABLE - Indicates whether an angle block is being played and angle changes can be performed.';
    EC_DVD_AUDIO_STREAM_CHANGE:
      result := 'EC_DVD_AUDIO_STREAM_CHANGE - Signals that the current audio stream number changed for the main title.';
    EC_DVD_BUTTON_AUTO_ACTIVATED:
      result := 'EC_DVD_BUTTON_AUTO_ACTIVATED - Signals that a menu button has been automatically activated per instructions on the disc.';
    EC_DVD_BUTTON_CHANGE:
      result := 'EC_DVD_BUTTON_CHANGE - Signals that either the number of available buttons changed or that the currently selected button number changed.';
    EC_DVD_CHAPTER_AUTOSTOP:
      result := 'EC_DVD_CHAPTER_AUTOSTOP - Indicates that playback stopped as the result of a call to the IDvdControl2::PlayChaptersAutoStop method.';
    EC_DVD_CHAPTER_START:
      result := 'EC_DVD_CHAPTER_START - Signals that the DVD Navigator started playback of a new chapter in the current title.';
    EC_DVD_CMD_START:
      result := 'EC_DVD_CMD_START - Signals that a particular command has begun.';
    EC_DVD_CMD_END:
      result := 'EC_DVD_CMD_END - Signals that a particular command has completed.';
    EC_DVD_CURRENT_HMSF_TIME:
      result := 'EC_DVD_CURRENT_HMSF_TIME - Signals the current time in DVD_HMSF_TIMECODE format at the beginning of every VOBU, which occurs every .4 to 1.0 sec.';
    EC_DVD_CURRENT_TIME:
      result := 'EC_DVD_CURRENT_TIME - Signals the beginning of every video object unit (VOBU), a video segment which is 0.4 to 1.0 seconds in length.';
    EC_DVD_DISC_EJECTED:
      result := 'EC_DVD_DISC_EJECTED - Signals that a disc has been ejected from the drive.';
    EC_DVD_DISC_INSERTED:
      result := 'EC_DVD_DISC_INSERTED - Signals that a disc has been inserted into the drive.';
    EC_DVD_DOMAIN_CHANGE:
      result := 'EC_DVD_DOMAIN_CHANGE - Indicates the DVD Navigator''s new domain.';
    EC_DVD_ERROR:
      result := 'EC_DVD_ERROR - Signals a DVD error condition.';
    EC_DVD_KARAOKE_MODE:
      result := 'EC_DVD_KARAOKE_MODE - Indicates that the Navigator has either begun playing or finished playing karaoke data.';
    EC_DVD_NO_FP_PGC:
      result := 'EC_DVD_NO_FP_PGC - Indicates that the DVD disc does not have a FP_PGC (First Play Program Chain).';
    EC_DVD_PARENTAL_LEVEL_CHANGE:
      result := 'EC_DVD_PARENTAL_LEVEL_CHANGE - Signals that the parental level of the authored content is about to change.';
    EC_DVD_PLAYBACK_RATE_CHANGE:
      result := 'EC_DVD_PLAYBACK_RATE_CHANGE - Indicates that a playback rate change has been initiated and the new rate is in the parameter.';
    EC_DVD_PLAYBACK_STOPPED:
      result := 'EC_DVD_PLAYBACK_STOPPED - Indicates that playback has been stopped. The DVD Navigator has completed playback of the title and did not find any other branching instruction for subsequent playback.';
    EC_DVD_PLAYPERIOD_AUTOSTOP:
      result := 'EC_DVD_PLAYPERIOD_AUTOSTOP - Indicates that the Navigator has finished playing the segment specified in a call to PlayPeriodInTitleAutoStop.';
    EC_DVD_STILL_OFF:
      result := 'EC_DVD_STILL_OFF - Signals the end of any still.';
    EC_DVD_STILL_ON:
      result := 'EC_DVD_STILL_ON - Signals the beginning of any still.';
    EC_DVD_SUBPICTURE_STREAM_CHANGE:
      result := 'EC_DVD_SUBPICTURE_STREAM_CHANGE - Signals that the current subpicture stream number changed for the main title.';
    EC_DVD_TITLE_CHANGE:
      result := 'EC_DVD_TITLE_CHANGE - Indicates when the current title number changes.';
    EC_DVD_VALID_UOPS_CHANGE:
      result := 'EC_DVD_VALID_UOPS_CHANGE - Signals that the available set of IDVDControl2 interface methods has changed.';
    EC_DVD_WARNING:
      result := 'EC_DVD_WARNING - Signals a DVD warning condition.'
  else
    result := Format('Unknow Graph Event ($%x)', [code]);
  end;
end;

// general purpose function to delete a heap allocated AM_MEDIA_TYPE structure
// which is useful when calling IEnumMediaTypes::Next as the interface
// implementation allocates the structures which you must later delete
// the format block may also be a pointer to an interface to release
procedure DeleteMediaType(pmt: PAMMediaType);
begin
  // allow nil pointers for coding simplicity
  if (pmt = nil) then
    Exit;
  FreeMediaType(pmt);
  CoTaskMemFree(pmt);
end;

// this also comes in useful when using the IEnumMediaTypes interface so
// that you can copy a media type, you can do nearly the same by creating
// a CMediaType object but as soon as it goes out of scope the destructor
// will delete the memory it allocated (this takes a copy of the memory)
function CreateMediaType(pSrc: PAMMediaType): PAMMediaType;
var
  pMediaType: PAMMediaType;
begin
  ASSERT(pSrc <> nil);

  // Allocate a block of memory for the media type
  pMediaType := CoTaskMemAlloc(SizeOf(TAMMediaType));
  if (pMediaType = nil) then
  begin
    result := nil;
    Exit;
  end;

  // Copy the variable length format block
  CopyMediaType(pMediaType, pSrc);
  result := pMediaType;
end;

// ----------------------------------------------------------------------------
// Copies a task-allocated AM_MEDIA_TYPE structure.
// ----------------------------------------------------------------------------
procedure CopyMediaType(pmtTarget: PAMMediaType; pmtSource: PAMMediaType);
begin
  // We'll leak if we copy onto one that already exists - there's one
  // case we can check like that - copying to itself.
  ASSERT(pmtSource <> pmtTarget);
  // pmtTarget^ := pmtSource^;
  move(pmtSource^, pmtTarget^, SizeOf(TAMMediaType));
  if (pmtSource.cbFormat <> 0) then
  begin
    ASSERT(pmtSource.pbFormat <> nil);
    pmtTarget.pbFormat := CoTaskMemAlloc(pmtSource.cbFormat);
    if (pmtTarget.pbFormat = nil) then
      pmtTarget.cbFormat := 0
    else
      CopyMemory(pmtTarget.pbFormat, pmtSource.pbFormat, pmtTarget.cbFormat);
  end;
  if (pmtTarget.pUnk <> nil) then
    pmtTarget.pUnk._AddRef;
end;

procedure FreeMediaType(mt: PAMMediaType);
begin
  if (mt^.cbFormat <> 0) then
  begin
    CoTaskMemFree(mt^.pbFormat);
    // Strictly unnecessary but tidier
    mt^.cbFormat := 0;
    mt^.pbFormat := nil;
  end;
  if (mt^.pUnk <> nil) then
    mt^.pUnk := nil;
end;

// ----------------------------------------------------------------------------
// Initializes a media type structure given a wave format structure.
// ----------------------------------------------------------------------------
function CreateAudioMediaType(pwfx: PWaveFormatEx; pmt: PAMMediaType; bSetFormat: boolean): HRESULT;
begin
  pmt.majortype := MEDIATYPE_Audio;
  if (pwfx.wFormatTag = WAVE_FORMAT_EXTENSIBLE) then
    pmt.SubType := PWAVEFORMATEXTENSIBLE(pwfx).SubFormat
  else
    pmt.SubType            := FOURCCMap(pwfx.wFormatTag);
  pmt.FormatType           := FORMAT_WaveFormatEx;
  pmt.bFixedSizeSamples    := TRUE;
  pmt.bTemporalCompression := FALSE;
  pmt.lSampleSize          := pwfx.nBlockAlign;
  pmt.pUnk                 := nil;
  if (bSetFormat) then
  begin
    if (pwfx.wFormatTag = WAVE_FORMAT_PCM) then
      pmt.cbFormat := SizeOf(TWAVEFORMATEX)
    else
      pmt.cbFormat := SizeOf(TWAVEFORMATEX) + pwfx.cbSize;
    pmt.pbFormat   := CoTaskMemAlloc(pmt.cbFormat);
    if (pmt.pbFormat = nil) then
    begin
      result := E_OUTOFMEMORY;
      Exit;
    end;
    if (pwfx.wFormatTag = WAVE_FORMAT_PCM) then
    begin
      CopyMemory(pmt.pbFormat, pwfx, SizeOf(PCMWAVEFORMAT));
      PWaveFormatEx(pmt.pbFormat).cbSize := 0;
    end
    else
    begin
      CopyMemory(pmt.pbFormat, pwfx, pmt.cbFormat);
    end;
  end;
  result := S_OK;
end;

function FOURCCMap(Fourcc: Cardinal): TGUID;
const
  tmpguid: TGUID = '{00000000-0000-0010-8000-00AA00389B71}';
begin
  result    := tmpguid;
  result.D1 := Fourcc;
end;

{ Convert a FCC (Four Char Codes) to Cardinal. A FCC identifie a media type. }
{$NODEFINE FCC}

function FCC(str: String): Cardinal;
begin
  ASSERT(length(str) >= 4);
  result := PDWORD(str)^;
end;

function GetFOURCC(Fourcc: Cardinal): string;
type
  TFOURCC = array [0 .. 4] of char;
var
  CC: TFOURCC;
begin
  if Fourcc = 0 then
    result := 'RGB'
  else if Fourcc = 1 then
    result := 'RLE8'
  else if Fourcc = 2 then
    result := 'RLE4'
  else if Fourcc = 3 then
    result := 'BITFIELDS'
  else if Fourcc = 844715353 then
    result := 'YUY2'
  else if Fourcc = 842094169 then
    result := 'YV12'
  else if Fourcc = 842094158 then
    result := 'NV12'
  else if Fourcc = 1498831189 then
    result := 'UYVY'
  else if Fourcc = 1196444237 then
    result := 'MJPEG'
  else
  begin
    PDWORD(@CC)^ := Fourcc;           // abracadabra
    result       := IntToStr(Fourcc); // CC;
  end;
end;

{$NODEFINE MAKEFOURCC}

function MAKEFOURCC(ch0, ch1, ch2, ch3: char): Cardinal;
begin
  result := Cardinal(byte(ch0)) or (Cardinal(byte(ch1)) shl 8) or (Cardinal(byte(ch2)) shl 16) or (Cardinal(byte(ch3)) shl 24)
end;

function GetErrorString(hr: HRESULT): string;
var
  buffer: array [0 .. 254] of char;
begin
  AMGetErrorText(hr, @buffer, 255);
  result := buffer;
end;

function GetMediaTypeDescription(MediaType: PAMMediaType): string;
begin
  // major types
  result := 'Major Type: ';
  if IsEqualGUID(MediaType.majortype, MEDIATYPE_AnalogAudio) then
    result := result + 'AnalogAudio'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_AnalogVideo) then
    result := result + 'Analogvideo'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_Audio) then
    result := result + 'Audio'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_AUXLine21Data) then
    result := result + 'AUXLine21Data'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_File) then
    result := result + 'File'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_Interleaved) then
    result := result + 'Interleaved'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_LMRT) then
    result := result + 'LMRT'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_Midi) then
    result := result + 'Midi'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_MPEG2_PES) then
    result := result + 'MPEG2_PES'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_ScriptCommand) then
    result := result + 'ScriptCommand'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_Stream) then
    result := result + 'Stream'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_Text) then
    result := result + 'Text'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_Timecode) then
    result := result + 'Timecode'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_URL_STREAM) then
    result := result + 'URL_STREAM'
  else if IsEqualGUID(MediaType.majortype, MEDIATYPE_Video) then
    result := result + 'Video'
  else
    result := result + 'UnKnown ';
  // sub types
  result := result + ' - Sub Type: ';
  if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_CLPL) then
    result := result + 'CLPL'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_YUYV) then
    result := result + 'YUYV'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_IYUV) then
    result := result + 'IYUV'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_YVU9) then
    result := result + 'YVU9'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_Y411) then
    result := result + 'Y411'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_Y41P) then
    result := result + 'Y41P'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_YUY2) then
    result := result + 'YUY2'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_YVYU) then
    result := result + 'YVYU'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_UYVY) then
    result := result + 'UYVY'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_Y211) then
    result := result + 'Y211'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_NV12) then
    result := result + 'NV12'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_YV12) then
    result := result + 'YV12'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_CLJR) then
    result := result + 'CLJR'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_IF09) then
    result := result + 'IF09'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_CPLA) then
    result := result + 'CPLA'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MJPG) then
    result := result + 'MJPG'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_TVMJ) then
    result := result + 'TVMJ'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_WAKE) then
    result := result + 'WAKE'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_CFCC) then
    result := result + 'CFCC'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_IJPG) then
    result := result + 'IJPG'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_Plum) then
    result := result + 'Plum'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DVCS) then
    result := result + 'DVCS'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DVSD) then
    result := result + 'DVSD'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MDVF) then
    result := result + 'MDVF'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_RGB1) then
    result := result + 'RGB1'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_RGB4) then
    result := result + 'RGB4'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_RGB8) then
    result := result + 'RGB8'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_RGB565) then
    result := result + 'RGB565'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_RGB555) then
    result := result + 'RGB555'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_RGB24) then
    result := result + 'RGB24'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_RGB32) then
    result := result + 'RGB32'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_ARGB32) then
    result := result + 'ARGB32'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_Overlay) then
    result := result + 'Overlay'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MPEG1Packet) then
    result := result + 'MPEG1Packet'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MPEG1Payload) then
    result := result + 'MPEG1Payload'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MPEG1AudioPayload) then
    result := result + 'MPEG1AudioPayload'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MPEG1System) then
    result := result + 'MPEG1System'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MPEG1VideoCD) then
    result := result + 'MPEG1VideoCD'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MPEG1Video) then
    result := result + 'MPEG1Video'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MPEG1Audio) then
    result := result + 'MPEG1Audio'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_Avi) then
    result := result + 'Avi'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_Asf) then
    result := result + 'Asf'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_QTMovie) then
    result := result + 'QTMovie'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_QTRpza) then
    result := result + 'QTRpza'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_QTSmc) then
    result := result + 'QTSmc'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_QTRle) then
    result := result + 'QTRle'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_QTJpeg) then
    result := result + 'QTJpeg'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_PCMAudio_Obsolete) then
    result := result + 'PCMAudio_Obsolete'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_PCM) then
    result := result + 'PCM'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_WAVE) then
    result := result + 'WAVE'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AU) then
    result := result + 'AU'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AIFF) then
    result := result + 'AIFF'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_dvsd_) then
    result := result + 'dvsd_'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_dvhd) then
    result := result + 'dvhd'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_dvsl) then
    result := result + 'dvsl'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_Line21_BytePair) then
    result := result + 'Line21_BytePair'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_Line21_GOPPacket) then
    result := result + 'Line21_GOPPacket'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_Line21_VBIRawData) then
    result := result + 'Line21_VBIRawData'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DRM_Audio) then
    result := result + 'DRM_Audio'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_IEEE_FLOAT) then
    result := result + 'IEEE_FLOAT'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DOLBY_AC3_SPDIF) then
    result := result + 'DOLBY_AC3_SPDIF'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_RAW_SPORT) then
    result := result + 'RAW_SPORT'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_SPDIF_TAG_241h) then
    result := result + 'SPDIF_TAG_241h'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DssVideo) then
    result := result + 'DssVideo'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DssAudio) then
    result := result + 'DssAudio'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_VPVideo) then
    result := result + 'VPVideo'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_VPVBI) then
    result := result + 'VPVBI'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_NTSC_M) then
    result := result + 'AnalogVideo_NTSC_M'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_PAL_B) then
    result := result + 'AnalogVideo_PAL_B'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_PAL_D) then
    result := result + 'AnalogVideo_PAL_D'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_PAL_G) then
    result := result + 'AnalogVideo_PAL_G'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_PAL_H) then
    result := result + 'AnalogVideo_PAL_H'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_PAL_I) then
    result := result + 'AnalogVideo_PAL_I'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_PAL_M) then
    result := result + 'AnalogVideo_PAL_M'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_PAL_N) then
    result := result + 'AnalogVideo_PAL_N'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_PAL_N_COMBO) then
    result := result + 'AnalogVideo_PAL_N_COMBO'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_SECAM_B) then
    result := result + 'AnalogVideo_SECAM_B'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_SECAM_D) then
    result := result + 'AnalogVideo_SECAM_D'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_SECAM_G) then
    result := result + 'AnalogVideo_SECAM_G'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_SECAM_H) then
    result := result + 'AnalogVideo_SECAM_H'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_SECAM_K) then
    result := result + 'AnalogVideo_SECAM_K'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_SECAM_K1) then
    result := result + 'AnalogVideo_SECAM_K1'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_AnalogVideo_SECAM_L) then
    result := result + 'AnalogVideo_SECAM_L'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MPEG2_VIDEO) then
    result := result + 'MPEG2_VIDEO'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MPEG2_PROGRAM) then
    result := result + 'MPEG2_PROGRAM'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MPEG2_TRANSPORT) then
    result := result + 'MPEG2_TRANSPORT'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MPEG2_AUDIO) then
    result := result + 'MPEG2_AUDIO'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DOLBY_AC3) then
    result := result + 'DOLBY_AC3'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DVD_SUBPICTURE) then
    result := result + 'DVD_SUBPICTURE'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DVD_LPCM_AUDIO) then
    result := result + 'DVD_LPCM_AUDIO'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DTS) then
    result := result + 'DTS'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_SDDS) then
    result := result + 'SDDS'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DVD_NAVIGATION_PCI) then
    result := result + 'PCI'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DVD_NAVIGATION_DSI) then
    result := result + 'DSI'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DVD_NAVIGATION_PROVIDER) then
    result := result + 'PROVIDER'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_MP42) then
    result := result + 'MS-MPEG4'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_DIVX) then
    result := result + 'DIVX'
  else if IsEqualGUID(MediaType.SubType, MEDIASUBTYPE_VOXWARE) then
    result := result + 'VOXWARE_MetaSound'
  else
    result := result + 'UnKnown ';

  // format
  result := result + ' Format: ';
  if IsEqualGUID(MediaType.FormatType, FORMAT_VideoInfo) then
  begin
    result := result + 'VideoInfo ';
    if ((MediaType.cbFormat > 0) and assigned(MediaType.pbFormat)) then
      with PVideoInfoHeader(MediaType.pbFormat)^.bmiHeader do
        result := result + Format('%s %dX%d, %d bits', [GetFOURCC(biCompression), biWidth, biHeight, biBitCount]);
  end
  else
  begin
    if IsEqualGUID(MediaType.FormatType, FORMAT_VideoInfo2) then
    begin
      result := result + 'VideoInfo2 ';
      if ((MediaType.cbFormat > 0) and assigned(MediaType.pbFormat)) then
        with PVideoInfoHeader2(MediaType.pbFormat)^.bmiHeader do
          result := result + Format('%s %dX%d, %d bits', [GetFOURCC(biCompression), biWidth, biHeight, biBitCount]);
    end
    else
    begin
      if IsEqualGUID(MediaType.FormatType, FORMAT_WaveFormatEx) then
      begin
        result := result + 'WaveFormatEx: ';
        if ((MediaType.cbFormat > 0) and assigned(MediaType.pbFormat)) then
        begin
          case PWaveFormatEx(MediaType.pbFormat)^.wFormatTag of
            $0001:
              result := result + 'PCM'; // common
            $0002:
              result := result + 'ADPCM';
            $0003:
              result := result + 'IEEE_FLOAT';
            $0005:
              result := result + 'IBM_CVSD';
            $0006:
              result := result + 'ALAW';
            $0007:
              result := result + 'MULAW';
            $0010:
              result := result + 'OKI_ADPCM';
            $0011:
              result := result + 'DVI_ADPCM';
            $0012:
              result := result + 'MEDIASPACE_ADPCM';
            $0013:
              result := result + 'SIERRA_ADPCM';
            $0014:
              result := result + 'G723_ADPCM';
            $0015:
              result := result + 'DIGISTD';
            $0016:
              result := result + 'DIGIFIX';
            $0017:
              result := result + 'DIALOGIC_OKI_ADPCM';
            $0018:
              result := result + 'MEDIAVISION_ADPCM';
            $0020:
              result := result + 'YAMAHA_ADPCM';
            $0021:
              result := result + 'SONARC';
            $0022:
              result := result + 'DSPGROUP_TRUESPEECH';
            $0023:
              result := result + 'ECHOSC1';
            $0024:
              result := result + 'AUDIOFILE_AF36';
            $0025:
              result := result + 'APTX';
            $0026:
              result := result + 'AUDIOFILE_AF10';
            $0030:
              result := result + 'DOLBY_AC2';
            $0031:
              result := result + 'GSM610';
            $0032:
              result := result + 'MSNAUDIO';
            $0033:
              result := result + 'ANTEX_ADPCME';
            $0034:
              result := result + 'CONTROL_RES_VQLPC';
            $0035:
              result := result + 'DIGIREAL';
            $0036:
              result := result + 'DIGIADPCM';
            $0037:
              result := result + 'CONTROL_RES_CR10';
            $0038:
              result := result + 'NMS_VBXADPCM';
            $0039:
              result := result + 'CS_IMAADPCM';
            $003A:
              result := result + 'ECHOSC3';
            $003B:
              result := result + 'ROCKWELL_ADPCM';
            $003C:
              result := result + 'ROCKWELL_DIGITALK';
            $003D:
              result := result + 'XEBEC';
            $0040:
              result := result + 'G721_ADPCM';
            $0041:
              result := result + 'G728_CELP';
            $0050:
              result := result + 'MPEG';
            $0055:
              result := result + 'MPEGLAYER3';
            $0060:
              result := result + 'CIRRUS';
            $0061:
              result := result + 'ESPCM';
            $0062:
              result := result + 'VOXWARE';
            $0063:
              result := result + 'CANOPUS_ATRAC';
            $0064:
              result := result + 'G726_ADPCM';
            $0065:
              result := result + 'G722_ADPCM';
            $0066:
              result := result + 'DSAT';
            $0067:
              result := result + 'DSAT_DISPLAY';
            $0075:
              result := result + 'VOXWARE'; // aditionnal  ???
            $0080:
              result := result + 'SOFTSOUND';
            $0100:
              result := result + 'RHETOREX_ADPCM';
            $0200:
              result := result + 'CREATIVE_ADPCM';
            $0202:
              result := result + 'CREATIVE_FASTSPEECH8';
            $0203:
              result := result + 'CREATIVE_FASTSPEECH10';
            $0220:
              result := result + 'QUARTERDECK';
            $0300:
              result := result + 'FM_TOWNS_SND';
            $0400:
              result := result + 'BTV_DIGITAL';
            $1000:
              result := result + 'OLIGSM';
            $1001:
              result := result + 'OLIADPCM';
            $1002:
              result := result + 'OLICELP';
            $1003:
              result := result + 'OLISBC';
            $1004:
              result := result + 'OLIOPR';
            $1100:
              result := result + 'LH_CODEC';
            $1400:
              result := result + 'NORRIS';
          else
            result := result + 'Unknown';
          end;

          with PWaveFormatEx(MediaType.pbFormat)^ do
            result := result + Format(', %d Hertz, %d Bits, %d Channels', [nSamplesPerSec, wBitsPerSample, nChannels]);
        end;
      end
      else
      begin
        if IsEqualGUID(MediaType.FormatType, FORMAT_MPEGVideo) then
        begin
          result := result + 'MPEGVideo ';
          if ((MediaType.cbFormat > 0) and assigned(MediaType.pbFormat)) then
            with PMPEG1VIDEOINFO(MediaType.pbFormat)^.hdr.bmiHeader do
              result := result + Format('%s %dX%d, %d bits', [GetFOURCC(biCompression), biWidth, biHeight, biBitCount]);

        end
        else
        begin
          if IsEqualGUID(MediaType.FormatType, FORMAT_MPEG2Video) then
          begin
            result := result + 'MPEGStreams ';
            if ((MediaType.cbFormat > 0) and assigned(MediaType.pbFormat)) then
              with PMPEG2VIDEOINFO(MediaType.pbFormat)^.hdr.bmiHeader do
                result := result + Format('%s %dX%d, %d bits', [GetFOURCC(biCompression), biWidth, biHeight, biBitCount]);
          end
          else
          begin // todo
            if IsEqualGUID(MediaType.FormatType, FORMAT_DvInfo) then
              result := result + 'DvInfo'
            else if IsEqualGUID(MediaType.FormatType, FORMAT_MPEGStreams) then
              result := result + 'MPEGStreams'
            else if IsEqualGUID(MediaType.FormatType, FORMAT_DolbyAC3) then
              result := result + 'DolbyAC3'
            else if IsEqualGUID(MediaType.FormatType, FORMAT_MPEG2Audio) then
              result := result + 'MPEG2Audio'
            else if IsEqualGUID(MediaType.FormatType, FORMAT_DVD_LPCMAudio) then
              result := result + 'DVD_LPCMAudio'
            else
              result := result + 'Unknown';
          end;
        end;
      end;
    end;
  end;
end;

function ShowFilterPropertyPage(parent: THandle; Filter: IBaseFilter; PropertyPage: TPropertyPage = ppDefault): HRESULT;
var
  SpecifyPropertyPages: ISpecifyPropertyPages;
  CaptureDialog       : IAMVfwCaptureDialogs;
  CompressDialog      : IAMVfwCompressDialogs;
  CAGUID              : TCAGUID;
  FilterInfo          : TFilterInfo;
  code                : integer;
begin
  result := S_FALSE;
  code   := 0;
  if Filter = nil then
    Exit;

  ZeroMemory(@FilterInfo, SizeOf(TFilterInfo));

  case PropertyPage of
    ppVFWCapDisplay:
      code := VfwCaptureDialog_Display;
    ppVFWCapFormat:
      code := VfwCaptureDialog_Format;
    ppVFWCapSource:
      code := VfwCaptureDialog_Source;
    ppVFWCompConfig:
      code := VfwCompressDialog_Config;
    ppVFWCompAbout:
      code := VfwCompressDialog_About;
  end;

  case PropertyPage of
    ppDefault:
      begin
        result := Filter.QueryInterface(IID_ISpecifyPropertyPages, SpecifyPropertyPages);
        if result <> S_OK then
          Exit;
        result := SpecifyPropertyPages.GetPages(CAGUID);
        if result <> S_OK then
          Exit;
        result := Filter.QueryFilterInfo(FilterInfo);
        if result = S_OK then
        begin
          result            := OleCreatePropertyFrame(parent, 0, 0, FilterInfo.achName, 1, @Filter, CAGUID.cElems, CAGUID.pElems, 0, 0, nil);
          FilterInfo.pGraph := nil;
        end;
        if assigned(CAGUID.pElems) then
          CoTaskMemFree(CAGUID.pElems);
        SpecifyPropertyPages := nil;
      end;
    ppVFWCapDisplay .. ppVFWCapSource:
      begin
        result := Filter.QueryInterface(IID_IAMVfwCaptureDialogs, CaptureDialog);
        if (result <> S_OK) then
          Exit;
        result := CaptureDialog.HasDialog(code);
        if result <> S_OK then
          Exit;
        result        := CaptureDialog.ShowDialog(code, parent);
        CaptureDialog := nil;
      end;
    ppVFWCompConfig .. ppVFWCompAbout:
      begin
        result := Filter.QueryInterface(IID_IAMVfwCompressDialogs, CompressDialog);
        if (result <> S_OK) then
          Exit;
        case PropertyPage of
          ppVFWCompConfig:
            result := CompressDialog.ShowDialog(VfwCompressDialog_QueryConfig, 0);
          ppVFWCompAbout:
            result := CompressDialog.ShowDialog(VfwCompressDialog_QueryAbout, 0);
        end;
        if result = S_OK then
          result       := CompressDialog.ShowDialog(code, parent);
        CompressDialog := nil;
      end;
  end;
end;

function HaveFilterPropertyPage(Filter: IBaseFilter; PropertyPage: TPropertyPage = ppDefault): boolean;
var
  SpecifyPropertyPages: ISpecifyPropertyPages;
  CaptureDialog       : IAMVfwCaptureDialogs;
  CompressDialog      : IAMVfwCompressDialogs;
  code                : integer;
  hr                  : HRESULT;
begin
  result := FALSE;
  code   := 0;
  if Filter = nil then
    Exit;

  case PropertyPage of
    ppVFWCapDisplay:
      code := VfwCaptureDialog_Display;
    ppVFWCapFormat:
      code := VfwCaptureDialog_Format;
    ppVFWCapSource:
      code := VfwCaptureDialog_Source;
    ppVFWCompConfig:
      code := VfwCompressDialog_QueryConfig;
    ppVFWCompAbout:
      code := VfwCompressDialog_QueryAbout;
  end;

  case PropertyPage of
    ppDefault:
      begin
        result               := Succeeded(Filter.QueryInterface(IID_ISpecifyPropertyPages, SpecifyPropertyPages));
        SpecifyPropertyPages := nil;
      end;
    ppVFWCapDisplay .. ppVFWCapSource:
      begin
        hr := Filter.QueryInterface(IID_IAMVfwCaptureDialogs, CaptureDialog);
        if (hr <> S_OK) then
          Exit;
        result        := Succeeded(CaptureDialog.HasDialog(code));
        CaptureDialog := nil;
      end;
    ppVFWCompConfig .. ppVFWCompAbout:
      begin
        hr := Filter.QueryInterface(IID_IAMVfwCompressDialogs, CompressDialog);
        if (hr <> S_OK) then
          Exit;
        result         := Succeeded(CompressDialog.ShowDialog(code, 0));
        CompressDialog := nil;
      end;
  end;
end;

function ShowPinPropertyPage(parent: THandle; Pin: IPin): HRESULT;
var
  SpecifyPropertyPages: ISpecifyPropertyPages;
  CAGUID              : TCAGUID;
  PinInfo             : TPinInfo;
begin
  result := S_FALSE;
  if Pin = nil then
    Exit;
  result := Pin.QueryInterface(IID_ISpecifyPropertyPages, SpecifyPropertyPages);
  if result <> S_OK then
    Exit;
  result := SpecifyPropertyPages.GetPages(CAGUID);
  if result <> S_OK then
  begin
    SpecifyPropertyPages := nil;
    Exit;
  end;
  result := Pin.QueryPinInfo(PinInfo);
  if result <> S_OK then
    Exit;
  try
    result := OleCreatePropertyFrame(parent, 0, 0, PinInfo.achName, 1, @Pin, CAGUID.cElems, CAGUID.pElems, 0, 0, nil);
  finally
    CoTaskMemFree(CAGUID.pElems);
    PinInfo.pFilter := nil;
  end;
  SpecifyPropertyPages := nil;
end;

function RefTimeToMiliSec(RefTime: Int64): Cardinal;
begin
  result := Cardinal(RefTime div 10000);
end;

function MiliSecToRefTime(Milisec: Int64): Int64;
begin
  result := Milisec * 10000;
end;

// The mechanism for describing a bitmap format is with the BITMAPINFOHEADER
// This is really messy to deal with because it invariably has fields that
// follow it holding bit fields, palettes and the rest. This function gives
// the number of bytes required to hold a VIDEOINFO that represents it. This
// count includes the prefix information (like the rcSource rectangle) the
// BITMAPINFOHEADER field, and any other colour information on the end.
//
// WARNING If you want to copy a BITMAPINFOHEADER into a VIDEOINFO always make
// sure that you use the HEADER macro because the BITMAPINFOHEADER field isn't
// right at the start of the VIDEOINFO (there are a number of other fields),
//
// CopyMemory(HEADER(pVideoInfo),pbmi,sizeof(BITMAPINFOHEADER));
//

function GetBitmapFormatSize(const Header: TBitmapInfoHeader): integer;
var
  Size, Entries: integer;
begin
  // Everyone has this to start with this
  Size := SIZE_PREHEADER + Header.biSize;

  ASSERT(Header.biSize >= SizeOf(TBitmapInfoHeader));

  // Does this format use a palette, if the number of colours actually used
  // is zero then it is set to the maximum that are allowed for that colour
  // depth (an example is 256 for eight bits). Truecolour formats may also
  // pass a palette with them in which case the used count is non zero

  // This would scare me.
  ASSERT((Header.biBitCount <= iPALETTE) or (Header.biClrUsed = 0));

  if ((Header.biBitCount <= iPALETTE) or BOOL(Header.biClrUsed)) then
  begin
    Entries := DWord(1) shl Header.biBitCount;
    if BOOL(Header.biClrUsed) then
      Entries := Header.biClrUsed;
    Size      := Size + Entries * SizeOf(RGBQUAD);
  end;

  // Truecolour formats may have a BI_BITFIELDS specifier for compression
  // type which means that room for three DWORDs should be allocated that
  // specify where in each pixel the RGB colour components may be found

  if (Header.biCompression = BI_BITFIELDS) then
    Size := Size + SIZE_MASKS;
  result := Size;
end;

function GetSourceRectFromMediaType(const MediaType: TAMMediaType): TRect;
  function GetbmiHeader(const MediaType: TAMMediaType): PBitmapInfoHeader;
  begin
    result := nil;
    if MediaType.pbFormat = nil then
      Exit;
    if (IsEqualGUID(MediaType.FormatType, FORMAT_VideoInfo) and (MediaType.cbFormat >= SizeOf(TVIDEOINFOHEADER))) then
      result := @PVideoInfoHeader(MediaType.pbFormat)^.bmiHeader
    else if (IsEqualGUID(MediaType.FormatType, FORMAT_VideoInfo2) and (MediaType.cbFormat >= SizeOf(TVIDEOINFOHEADER2))) then
      result := @PVideoInfoHeader2(MediaType.pbFormat)^.bmiHeader;
  end;

var
  bih: PBitmapInfoHeader;
begin
  ZeroMemory(@result, SizeOf(TRect));
  if MediaType.pbFormat = nil then
    Exit;
  if (IsEqualGUID(MediaType.FormatType, FORMAT_VideoInfo) and (MediaType.cbFormat >= SizeOf(TVIDEOINFOHEADER))) then
    result := PVideoInfoHeader(MediaType.pbFormat)^.rcSource
  else if (IsEqualGUID(MediaType.FormatType, FORMAT_VideoInfo2) and (MediaType.cbFormat >= SizeOf(TVIDEOINFOHEADER2))) then
    result := PVideoInfoHeader2(MediaType.pbFormat)^.rcSource;
  if IsRectEmpty(result) then
  begin
    bih := GetbmiHeader(MediaType);
    if bih <> nil then
      SetRect(result, 0, 0, abs(bih.biWidth), abs(bih.biHeight));
  end;
end;

function StretchRect(R, IR: TRect): TRect;
var
  iW, iH: integer;
  rW, rH: integer;
begin
  iW := IR.Right - IR.Left;
  iH := IR.Bottom - IR.Top;
  rW := R.Right - R.Left;
  rH := R.Bottom - R.Top;
  if (rW / iW) < (rH / iH) then
  begin
    iH := MulDiv(iH, rW, iW);
    iW := MulDiv(iW, rW, iW);
  end
  else
  begin
    iW := MulDiv(iW, rH, iH);
    iH := MulDiv(iH, rH, iH);
  end;
  SetRect(result, 0, 0, iW, iH);
  OffsetRect(result, R.Left + (rW - iW) div 2, R.Top + (rH - iH) div 2);
end;

function CheckDSError(hr: HRESULT): HRESULT;
var
  Excep: EDirectShowException;
begin
  result := hr;
  if Failed(hr) then
  begin
    Excep           := EDirectShowException.Create(Format(GetErrorString(hr) + ' ($%x).', [hr]));
    Excep.ErrorCode := hr;
    raise Excep;
  end;
end;

// -----------------------------------------------------------------------------
// Name: DXUtil_GetDXSDKMediaPath()
// Desc: Returns the DirectX SDK media path
// -----------------------------------------------------------------------------
function GetDXSDKMediaPath: String;
var
  strPath       : array [1 .. MAX_PATH + 10] of char;
  Key           : HKey;
  dwType, dwSize: DWord;
  lr            : longint;

begin
  Key    := 0;
  dwType := 0;
  dwSize := MAX_PATH;

  // Initialize to NULL
  strPath[1] := #0;

  // Open the appropriate registry key
  lr := RegOpenKeyEx(HKEY_LOCAL_MACHINE, 'Software\Microsoft\DirectX SDK', 0, KEY_READ, Key);
  if (ERROR_SUCCESS <> lr) then
  begin
    result := '';
    Exit;
  end;

  lr := RegQueryValueEx(Key, 'DX9SDK Samples Path', nil, @dwType, @strPath, @dwSize);

  if (ERROR_SUCCESS <> lr) then
  begin
    // Reset size field
    dwSize := MAX_PATH;
    lr     := RegQueryValueEx(Key, 'DX81SDK Samples Path', nil, @dwType, @strPath, @dwSize);

    if (ERROR_SUCCESS <> lr) then
    begin
      // Reset size field
      dwSize := MAX_PATH;
      lr     := RegQueryValueEx(Key, 'DX8SDK Samples Path', nil, @dwType, @strPath, @dwSize);

      if (ERROR_SUCCESS <> lr) then
      begin
        RegCloseKey(Key);
        result := '';
        Exit;
      end;
    end;
  end;

  RegCloseKey(Key);
  result := PChar(@strPath);
  result := result + '\Media\';
end;

function CopyScreenToBitmap(Rect: TRect; pData: PByte; pHeader: PBitmapInfo): HBitmap;
var
  // screen DC and memory DC
  hScrDC, hMemDC: HDC;
  // handles to deice-dependent bitmaps
  hBmp, hOldBmp: HBitmap;
  // coordinates of rectangle to grab
  nX, nY, nX2, nY2,
  // DIB width and height
  nWidth, nHeight,
  // screen resolution
  xScrn, yScrn: integer;

begin
  // check for an empty rectangle
  if IsRectEmpty(Rect) then
  begin
    result := 0;
    Exit;
  end;

  // create a DC for the screen and create
  // a memory DC compatible to screen DC
  hScrDC := CreateDC('DISPLAY', nil, nil, nil);
  hMemDC := CreateCompatibleDC(hScrDC);

  // get points of rectangle to grab
  nX  := Rect.Left;
  nY  := Rect.Top;
  nX2 := Rect.Right;
  nY2 := Rect.Bottom;

  // get screen resolution
  xScrn := GetDeviceCaps(hScrDC, HORZRES);
  yScrn := GetDeviceCaps(hScrDC, VERTRES);

  // make sure bitmap rectangle is visible
  if (nX < 0) then
    nX := 0;
  if (nY < 0) then
    nY := 0;
  if (nX2 > xScrn) then
    nX2 := xScrn;
  if (nY2 > yScrn) then
    nY2 := yScrn;

  nWidth  := nX2 - nX;
  nHeight := nY2 - nY;

  // create a bitmap compatible with the screen DC
  hBmp := CreateCompatibleBitmap(hScrDC, nWidth, nHeight);

  // select new bitmap into memory DC
  hOldBmp := SelectObject(hMemDC, hBmp);

  // bitblt screen DC to memory DC
  BitBlt(hMemDC, 0, 0, nWidth, nHeight, hScrDC, nX, nY, SRCCOPY);

  // select old bitmap back into memory DC and get handle to
  // bitmap of the screen
  hBmp := SelectObject(hMemDC, hOldBmp);

  // Copy the bitmap data into the provided BYTE buffer
  GetDIBits(hScrDC, hBmp, 0, nHeight, pData, pHeader^, DIB_RGB_COLORS);

  // clean up
  DeleteDC(hScrDC);
  DeleteDC(hMemDC);

  // return handle to the bitmap
  result := hBmp;
end;


// *****************************************************************************
// TSysDevEnum
// *****************************************************************************

procedure TSysDevEnum.GetCat(catlist: TList; CatGUID: TGUID);
var
  SysDevEnum: ICreateDevEnum;
  EnumCat   : IEnumMoniker;
  Moniker   : IMoniker;
  Fetched   : ULONG;
  PropBag   : IPropertyBag;
  Name      : OleVariant;
  hr        : HRESULT;
  i         : integer;
begin
  if catlist.Count > 0 then
    for i := 0 to (catlist.Count - 1) do
      if assigned(catlist.Items[i]) then
        Dispose(catlist.Items[i]);
  catlist.Clear;
  CocreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC, IID_ICreateDevEnum, SysDevEnum);
  hr := SysDevEnum.CreateClassEnumerator(CatGUID, EnumCat, 0);
  if (hr = S_OK) then
  begin
    while (EnumCat.Next(1, Moniker, @Fetched) = S_OK) do
    begin
      Moniker.BindToStorage(nil, nil, IID_IPropertyBag, PropBag);
      new(ACategory);
      PropBag.Read('FriendlyName', Name, nil);
      ACategory^.FriendlyName := Shortstring(Name);
      if (PropBag.Read('CLSID', Name, nil) = S_OK) then
      begin
        try
          ACategory^.clsid := StringToGUID(Name); // try..except add by pcplayer
        except
          ACategory^.clsid := GUID_NULL;
        end;
        // ACategory^.CLSID := StringToGUID(Name)
      end
      else
        ACategory^.clsid := GUID_NULL;
      catlist.Add(ACategory);
      PropBag := nil;
      Moniker := nil;
    end;
  end;
  EnumCat    := nil;
  SysDevEnum := nil;
end;

constructor TSysDevEnum.Create;
begin
  FCategories := TList.Create;
  FFilters    := TList.Create;
  GetCat(FCategories, CLSID_ActiveMovieCategories);
end;

constructor TSysDevEnum.Create(GUID: TGUID);
begin
  FCategories := TList.Create;
  FFilters    := TList.Create;
  GetCat(FCategories, CLSID_ActiveMovieCategories);
  SelectGUIDCategory(GUID);
end;

destructor TSysDevEnum.Destroy;
var
  i: integer;
begin
  inherited Destroy;
  if FCategories.Count > 0 then
    for i := 0 to (FCategories.Count - 1) do
      if assigned(FCategories.Items[i]) then
        Dispose(FCategories.Items[i]);
  FCategories.Clear;
  FreeAndNil(FCategories);
  if FFilters.Count > 0 then
    for i := 0 to (FFilters.Count - 1) do
      if assigned(FFilters.Items[i]) then
        Dispose(FFilters.Items[i]);
  FFilters.Clear;
  FreeAndNil(FFilters);
end;

function TSysDevEnum.GetCategory(item: integer): TFilCatNode;
var
  PCategory: PFilCatNode;
begin
  PCategory := FCategories.Items[item];
  result    := PCategory^;
end;

function TSysDevEnum.GetFilter(item: integer): TFilCatNode;
var
  PCategory: PFilCatNode;
begin
  PCategory := FFilters.Items[item];
  result    := PCategory^;
end;

function TSysDevEnum.GetCountCategories: integer;
begin
  result := FCategories.Count;
end;

function TSysDevEnum.GetCountFilters: integer;
begin
  result := FFilters.Count;
end;

// Find filter index by FriendlyName; -1, if not found
function TSysDevEnum.FilterIndexOfFriendlyName(const FriendlyName: string): integer;
begin
  result := FFilters.Count - 1;
  while (result >= 0) and (AnsiCompareText(string(PFilCatNode(FFilters.Items[result])^.FriendlyName), FriendlyName) <> 0) do
    Dec(result);
end;

procedure TSysDevEnum.SelectGUIDCategory(GUID: TGUID);
begin
  FGUID := GUID;
  GetCat(FFilters, FGUID);
end;

procedure TSysDevEnum.SelectIndexCategory(index: integer);
begin
  SelectGUIDCategory(Categories[index].clsid);
end;

function TSysDevEnum.GetMoniker(index: integer): IMoniker;
var
  SysDevEnum: ICreateDevEnum;
  EnumCat   : IEnumMoniker;
begin
  result := nil;
  if ((index < CountFilters) and (index >= 0)) then
  begin
    CocreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC, IID_ICreateDevEnum, SysDevEnum);
    SysDevEnum.CreateClassEnumerator(FGUID, EnumCat, 0);
    EnumCat.Skip(index);
    EnumCat.Next(1, result, nil);
    EnumCat.Reset;
    SysDevEnum := nil;
    EnumCat    := nil;
  end
end;

function TSysDevEnum.GetBaseFilter(index: integer): IBaseFilter;
var
  SysDevEnum: ICreateDevEnum;
  EnumCat   : IEnumMoniker;
  Moniker   : IMoniker;
begin
  result := nil;
  if ((index < CountFilters) and (index >= 0)) then
  begin
    CocreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC, IID_ICreateDevEnum, SysDevEnum);
    SysDevEnum.CreateClassEnumerator(FGUID, EnumCat, 0);
    EnumCat.Skip(index);
    EnumCat.Next(1, Moniker, nil);
    Moniker.BindToObject(nil, nil, IID_IBaseFilter, result);
    EnumCat.Reset;
    SysDevEnum := nil;
    EnumCat    := nil;
    Moniker    := nil;
  end
end;

function TSysDevEnum.GetBaseFilter(GUID: TGUID): IBaseFilter;
var
  i: integer;
begin
  result := nil;
  if CountFilters > 0 then
    for i := 0 to CountFilters - 1 do
      if IsEqualGUID(GUID, Filters[i].clsid) then
      begin
        result := GetBaseFilter(i);
        Exit;
      end;
end;

// ******************************************************************************
//
// TMediaType implementation
//
// ******************************************************************************

destructor TMediaType.Destroy;
begin
  FreeMediaType(AMMediaType);
  Dispose(AMMediaType);
  inherited Destroy;
end;

// copy constructor does a deep copy of the format block

constructor TMediaType.Create;
begin
  InitMediaType;
end;

constructor TMediaType.Create(majortype: TGUID);
begin
  InitMediaType;
  AMMediaType.majortype := majortype;
end;

constructor TMediaType.Create(MediaType: PAMMediaType);
begin
  InitMediaType;
  CopyMediaType(AMMediaType, MediaType);
end;

constructor TMediaType.Create(MTClass: TMediaType);
begin
  InitMediaType;
  CopyMediaType(AMMediaType, MTClass.AMMediaType);
end;

procedure TMediaType.DefineProperties(Filer: TFiler);
  function DoWrite: boolean;
  begin
    result := TRUE;
    if Filer.Ancestor <> nil then
    begin
      result := TRUE;
      if Filer.Ancestor is TMediaType then
        result := not Equal(TMediaType(Filer.Ancestor))
    end;
  end;

begin
  Filer.DefineBinaryProperty('data', ReadData, WriteData, DoWrite);
end;

procedure TMediaType.ReadData(Stream: TStream);
begin
  ResetFormatBuffer;
  Stream.Read(AMMediaType^, SizeOf(TAMMediaType));
  if FormatLength > 0 then
  begin
    AMMediaType.pbFormat := CoTaskMemAlloc(FormatLength);
    Stream.Read(AMMediaType.pbFormat^, FormatLength)
  end;
end;

procedure TMediaType.WriteData(Stream: TStream);
begin
  Stream.Write(AMMediaType^, SizeOf(TAMMediaType));
  if FormatLength > 0 then
    Stream.Write(AMMediaType.pbFormat^, FormatLength);
end;

// copy MTClass.AMMediaType to current AMMediaType
procedure TMediaType.Assign(Source: TPersistent);
begin
  if Source is TMediaType then
  begin
    if (Source <> self) then
    begin
      FreeMediaType(AMMediaType);
      CopyMediaType(AMMediaType, TMediaType(Source).AMMediaType);
    end;
  end
  else
    inherited Assign(Source);
end;

// this class inherits publicly from AM_MEDIA_TYPE so the compiler could generate
// the following assignment operator itself, however it could introduce some
// memory conflicts and leaks in the process because the structure contains
// a dynamically allocated block (pbFormat) which it will not copy correctly
procedure TMediaType.Read(MediaType: PAMMediaType);
begin
  if (MediaType <> self.AMMediaType) then
  begin
    FreeMediaType(AMMediaType);
    CopyMediaType(AMMediaType, MediaType);
  end;
end;

function TMediaType.Equal(MTClass: TMediaType): boolean;
begin
  // I don't believe we need to check sample size or
  // temporal compression flags, since I think these must
  // be represented in the type, subtype and format somehow. They
  // are pulled out as separate flags so that people who don't understand
  // the particular format representation can still see them, but
  // they should duplicate information in the format block.
  result := ((IsEqualGUID(AMMediaType.majortype, MTClass.AMMediaType.majortype) = TRUE) and (IsEqualGUID(AMMediaType.SubType, MTClass.AMMediaType.SubType) = TRUE) and (IsEqualGUID(AMMediaType.FormatType, MTClass.AMMediaType.FormatType) = TRUE) and (AMMediaType.cbFormat = MTClass.AMMediaType.cbFormat) and ((AMMediaType.cbFormat = 0) or (CompareMem(AMMediaType.pbFormat, MTClass.AMMediaType.pbFormat, AMMediaType.cbFormat))));
end;

// Check to see if they are equal
function TMediaType.NotEqual(MTClass: TMediaType): boolean;
begin
  if (self = MTClass) then
    result := FALSE
  else
    result := TRUE;
end;

// By default, TDSMediaType objects are initialized with a major type of GUID_NULL.
// Call this method to determine whether the object has been correctly initialized.
function TMediaType.IsValid: boolean;
begin
  result := not IsEqualGUID(AMMediaType.majortype, GUID_NULL);
end;

// Determines if the samples have a fixed size or a variable size.
function TMediaType.IsFixedSize: boolean;
begin
  result := AMMediaType.bFixedSizeSamples;
end;

// Determines if the stream uses temporal compression.
function TMediaType.IsTemporalCompressed: boolean;
begin
  result := AMMediaType.bTemporalCompression;
end;

// If the sample size is fixed, returns the sample size in bytes. Otherwise,
// returns zero.
function TMediaType.GetSampleSize: ULONG;
begin
  if IsFixedSize then
    result := AMMediaType.lSampleSize
  else
    result := 0;
end;

// If value of sz is zero, the media type uses variable sample sizes. Otherwise,
// the sample size is fixed at sz bytes.
procedure TMediaType.SetSampleSize(SZ: ULONG);
begin
  if (SZ = 0) then
  begin
    SetVariableSize;
  end
  else
  begin
    AMMediaType.bFixedSizeSamples := TRUE;
    AMMediaType.lSampleSize       := SZ;
  end;
end;

// Specifies that samples do not have a fixed size.
procedure TMediaType.SetVariableSize;
begin
  AMMediaType.bFixedSizeSamples := FALSE;
end;

// Specifies whether samples are compressed using temporal compression
procedure TMediaType.SetTemporalCompression(bCompressed: boolean);
begin
  AMMediaType.bTemporalCompression := bCompressed;
end;

// Retrieves a pointer to the format block.
function TMediaType.Format: Pointer;
begin
  result := AMMediaType.pbFormat;
end;

// Retrieves the length of the format block.
function TMediaType.FormatLength: ULONG;
begin
  result := AMMediaType.cbFormat;
end;

function TMediaType.SetFormat(pFormat: Pointer; length: ULONG): boolean;
begin
  if (nil = AllocFormatBuffer(length)) then
  begin
    result := FALSE;
    Exit;
  end;
  ASSERT(AMMediaType.pbFormat <> nil);
  CopyMemory(AMMediaType.pbFormat, pFormat, length);
  result := TRUE;
end;

// reset the format buffer
procedure TMediaType.ResetFormatBuffer;
begin
  if (AMMediaType.cbFormat <> 0) then
    CoTaskMemFree(AMMediaType.pbFormat);
  AMMediaType.cbFormat := 0;
  AMMediaType.pbFormat := nil;
end;

// allocate length bytes for the format and return a read/write pointer
// If we cannot allocate the new block of memory we return NULL leaving
// the original block of memory untouched (as does ReallocFormatBuffer)
function TMediaType.AllocFormatBuffer(length: ULONG): Pointer;
var
  pNewFormat: Pointer;
begin
  ASSERT(length <> 0);

  // do the types have the same buffer size
  if (AMMediaType.cbFormat = length) then
  begin
    result := AMMediaType.pbFormat;
    Exit;
  end;

  // allocate the new format buffer
  pNewFormat := CoTaskMemAlloc(length);
  if (pNewFormat = nil) then
  begin
    if (length <= AMMediaType.cbFormat) then
    begin
      result := AMMediaType.pbFormat; // reuse the old block anyway.
      Exit;
    end
    else
    begin
      result := nil;
      Exit;
    end;
  end;

  // delete the old format
  if (AMMediaType.cbFormat <> 0) then
  begin
    ASSERT(AMMediaType.pbFormat <> nil);
    CoTaskMemFree(AMMediaType.pbFormat);
  end;

  AMMediaType.cbFormat := length;
  AMMediaType.pbFormat := pNewFormat;
  result               := AMMediaType.pbFormat;
end;

// reallocate length bytes for the format and return a read/write pointer
// to it. We keep as much information as we can given the new buffer size
// if this fails the original format buffer is left untouched. The caller
// is responsible for ensuring the size of memory required is non zero
function TMediaType.ReallocFormatBuffer(length: ULONG): Pointer;
var
  pNewFormat: Pointer;
begin
  ASSERT(length <> 0);

  // do the types have the same buffer size
  if (AMMediaType.cbFormat = length) then
  begin
    result := AMMediaType.pbFormat;
    Exit;
  end;

  // allocate the new format buffer
  pNewFormat := CoTaskMemAlloc(length);
  if (pNewFormat = nil) then
  begin
    if (length <= AMMediaType.cbFormat) then
    begin
      result := AMMediaType.pbFormat; // reuse the old block anyway.
      Exit;
    end
    else
    begin
      result := nil;
      Exit;
    end;
  end;

  // copy any previous format (or part of if new is smaller)
  // delete the old format and replace with the new one
  if (AMMediaType.cbFormat <> 0) then
  begin
    ASSERT(AMMediaType.pbFormat <> nil);
    CopyMemory(pNewFormat, AMMediaType.pbFormat, min(length, AMMediaType.cbFormat));
    CoTaskMemFree(AMMediaType.pbFormat);
  end;

  AMMediaType.cbFormat := length;
  AMMediaType.pbFormat := pNewFormat;
  result               := pNewFormat;
end;

// initialise a media type structure
procedure TMediaType.InitMediaType;
begin
  new(AMMediaType);
  ZeroMemory(AMMediaType, SizeOf(TAMMediaType));
  AMMediaType.lSampleSize       := 1;
  AMMediaType.bFixedSizeSamples := TRUE;
end;

// Determines if this media type matches a partially specified media type.
function TMediaType.MatchesPartial(ppartial: TMediaType): boolean;
begin
  if (not IsEqualGUID(ppartial.AMMediaType.majortype, GUID_NULL) and not IsEqualGUID(AMMediaType.majortype, ppartial.AMMediaType.majortype)) then
  begin
    result := FALSE;
    Exit;
  end;
  if (not IsEqualGUID(ppartial.AMMediaType.SubType, GUID_NULL) and not IsEqualGUID(AMMediaType.SubType, ppartial.AMMediaType.SubType)) then
  begin
    result := FALSE;
    Exit;
  end;

  if not IsEqualGUID(ppartial.AMMediaType.FormatType, GUID_NULL) then
  begin
    // if the format block is specified then it must match exactly
    if not IsEqualGUID(AMMediaType.FormatType, ppartial.AMMediaType.FormatType) then
    begin
      result := FALSE;
      Exit;
    end;
    if (AMMediaType.cbFormat <> ppartial.AMMediaType.cbFormat) then
    begin
      result := FALSE;
      Exit;
    end;
    if ((AMMediaType.cbFormat <> 0) and (CompareMem(AMMediaType.pbFormat, ppartial.AMMediaType.pbFormat, AMMediaType.cbFormat) <> FALSE)) then
    begin
      result := FALSE;
      Exit;
    end;
  end;
  result := TRUE;
end;

// a partially specified media type can be passed to IPin::Connect
// as a constraint on the media type used in the connection.
// the type, subtype or format type can be null.
function TMediaType.IsPartiallySpecified: boolean;
begin
  if (IsEqualGUID(AMMediaType.majortype, GUID_NULL) or IsEqualGUID(AMMediaType.FormatType, GUID_NULL)) then
  begin
    result := TRUE;
    Exit;
  end
  else
  begin
    result := FALSE;
    Exit;
  end;
end;

function TMediaType.GetMajorType: TGUID;
begin
  result := AMMediaType.majortype;
end;

procedure TMediaType.SetMajorType(mt: TGUID);
begin
  AMMediaType.majortype := mt;
end;

function TMediaType.GetSubType: TGUID;
begin
  result := AMMediaType.SubType;
end;

procedure TMediaType.SetSubType(ST: TGUID);
begin
  AMMediaType.SubType := ST;
end;

// set the type of the media type format block, this type defines what you
// will actually find in the format pointer. For example FORMAT_VideoInfo or
// FORMAT_WaveFormatEx. In the future this may be an interface pointer to a
// property set. Before sending out media types this should be filled in.
procedure TMediaType.SetFormatType(const GUID: TGUID);
begin
  AMMediaType.FormatType := GUID;
end;

function TMediaType.GetFormatType: TGUID;
begin
  result := AMMediaType.FormatType;
end;

// ******************************************************************************
//
// TDSEnumMediaType Implementation
//
// ******************************************************************************

constructor TEnumMediaType.Create;
begin
  FList := TList.Create;
end;

constructor TEnumMediaType.Create(Pin: IPin);
var
  EnumMT: IEnumMediaTypes;
  hr    : HRESULT;
begin
  FList := TList.Create;
  ASSERT(Pin <> nil, 'IPin not assigned');
  hr := Pin.EnumMediaTypes(EnumMT);
  if (hr <> S_OK) then
    Exit;
  Create(EnumMT);
end;

constructor TEnumMediaType.Create(EnumMT: IEnumMediaTypes);
var
  pmt: PAMMediaType;
begin
  if (FList = nil) then
    FList := TList.Create;
  ASSERT(EnumMT <> nil, 'IEnumMediaType not assigned');
  while (EnumMT.Next(1, pmt, nil) = S_OK) do
  begin
    FList.Add(TMediaType.Create(pmt));
  end;
end;

constructor TEnumMediaType.Create(FileName: TFileName);
begin
  FList := TList.Create;
  Assign(FileName);
end;

destructor TEnumMediaType.Destroy;
begin
  Clear;
  FList.Free;
end;

procedure TEnumMediaType.Assign(Pin: IPin);
var
  EnumMT: IEnumMediaTypes;
  hr    : HRESULT;
begin
  Clear;
  ASSERT(Pin <> nil, 'IPin not assigned');
  hr := Pin.EnumMediaTypes(EnumMT);
  if (hr <> S_OK) then
    Exit;
  Assign(EnumMT);
end;

procedure TEnumMediaType.Assign(EnumMT: IEnumMediaTypes);
var
  pmt: PAMMediaType;
begin
  if (Count <> 0) then
    Clear;
  ASSERT(EnumMT <> nil, 'IEnumMediaType not assigned');
  while (EnumMT.Next(1, pmt, nil) = S_OK) do
  begin
    FList.Add(TMediaType.Create(pmt));
  end;
end;

procedure TEnumMediaType.Assign(FileName: TFileName);
var
  MediaDet   : IMediaDet;
  KeyProvider: IServiceProvider;
  hr         : HRESULT;
  Streams    : longint;
  i          : longint;
  MediaType  : TAMMediaType;
begin
  Clear;
  hr := CocreateInstance(CLSID_MediaDet, nil, CLSCTX_INPROC, IID_IMediaDet, MediaDet);
  // milenko start get rid of compiler warnings ...
  if (hr = S_OK) then
  begin
  end;
  // milenko end;
  ASSERT(hr = S_OK, 'Media Detector not available');
  hr := MediaDet.put_Filename(FileName);
  if hr <> S_OK then
  begin
    MediaDet := nil;
    Exit;
  end;
  MediaDet.get_OutputStreams(Streams);
  if Streams > 0 then
  begin
    for i := 0 to (Streams - 1) do
    begin
      MediaDet.put_CurrentStream(i);
      MediaDet.get_StreamMediaType(MediaType);
      FList.Add(TMediaType.Create(@MediaType));
    end;
  end;
  KeyProvider := nil;
  MediaDet    := nil;
end;

function TEnumMediaType.GetItem(index: integer): TMediaType;
begin
  result := TMediaType(FList.Items[index]);
end;

function TEnumMediaType.GetMediaDescription(index: integer): string;
begin
  result := '';
  if ((index < Count) and (index > -1)) then
    result := GetMediaTypeDescription(TMediaType(FList.Items[index]).AMMediaType);
end;

procedure TEnumMediaType.SetItem(index: integer; item: TMediaType);
begin
  TMediaType(FList.Items[index]).Assign(item);
end;

function TEnumMediaType.GetCount: integer;
begin
  ASSERT(FList <> nil, 'TDSEnumMediaType not created');
  if (FList <> nil) then
    result := FList.Count
  else
    result := 0;
end;

function TEnumMediaType.Add(item: TMediaType): integer;
begin
  result := FList.Add(item);
end;

procedure TEnumMediaType.Clear;
var
  i: integer;
begin
  if Count <> 0 then
    for i := 0 to (Count - 1) do
    begin
      if (FList.Items[i] <> nil) then
        TMediaType(FList.Items[i]).Free;
    end;
  FList.Clear;
end;

procedure TEnumMediaType.Delete(index: integer);
begin
  if (FList.Items[index] <> nil) then
    TMediaType(FList.Items[index]).Free;
  FList.Delete(index);
end;

// *****************************************************************************
// TDSFilterList implementation
// *****************************************************************************

constructor TFilterList.Create(FilterGraph: IFilterGraph);
begin
  inherited Create;
  Graph := FilterGraph;
  Update;
end;

destructor TFilterList.Destroy;
begin
  inherited Destroy;
end;

procedure TFilterList.Update;
var
  EnumFilters: IEnumFilters;
  Filter     : IBaseFilter;
begin
  if assigned(Graph) then
    Graph.EnumFilters(EnumFilters);
  while (EnumFilters.Next(1, Filter, nil) = S_OK) do
    Add(Filter);
  EnumFilters := nil;
end;

procedure TFilterList.Assign(FilterGraph: IFilterGraph);
begin
  Clear;
  Graph := FilterGraph;
  Update;
end;

function TFilterList.GetFilter(index: integer): IBaseFilter;
begin
  result := get(index) as IBaseFilter;
end;

procedure TFilterList.PutFilter(index: integer; item: IBaseFilter);
begin
  put(index, item);
end;

function TFilterList.First: IBaseFilter;
begin
  result := GetFilter(0);
end;

function TFilterList.IndexOf(item: IBaseFilter): integer;
begin
  result := inherited IndexOf(item);
end;

function TFilterList.Add(item: IBaseFilter): integer;
begin
  result := inherited Add(item);
end;

procedure TFilterList.Insert(index: integer; item: IBaseFilter);
begin
  inherited Insert(index, item);
end;

function TFilterList.Last: IBaseFilter;
begin
  result := inherited Last as IBaseFilter;
end;

function TFilterList.Remove(item: IBaseFilter): integer;
begin
  result := inherited Remove(item);
end;

function TFilterList.GetFilterInfo(index: integer): TFilterInfo;
begin
  if assigned(Items[index]) then
    Items[index].QueryFilterInfo(result);
end;

// *****************************************************************************
// TPinList
// *****************************************************************************

constructor TPinList.Create(BaseFilter: IBaseFilter);
begin
  inherited Create;
  Filter := BaseFilter;
  Update;
end;

destructor TPinList.Destroy;
begin
  Filter := nil;
  inherited Destroy;
end;

procedure TPinList.Update;
var
  EnumPins: IEnumPins;
  Pin     : IPin;
begin
  Clear;
  if assigned(Filter) then
    Filter.EnumPins(EnumPins)
  else
    Exit;
  while (EnumPins.Next(1, Pin, nil) = S_OK) do
    Add(Pin);
  EnumPins := nil;
end;

procedure TPinList.Assign(BaseFilter: IBaseFilter);
begin
  Clear;
  Filter := BaseFilter;
  if Filter <> nil then
    Update;
end;

function TPinList.GetConnected(index: integer): boolean;
var
  Pin: IPin;
begin
  Items[Index].ConnectedTo(Pin);
  result := (Pin <> nil);
end;

function TPinList.GetPin(index: integer): IPin;
begin
  result := get(index) as IPin;
end;

procedure TPinList.PutPin(index: integer; item: IPin);
begin
  put(index, item);
end;

function TPinList.First: IPin;
begin
  result := GetPin(0);
end;

function TPinList.IndexOf(item: IPin): integer;
begin
  result := inherited IndexOf(item);
end;

function TPinList.Add(item: IPin): integer;
begin
  result := inherited Add(item);
end;

procedure TPinList.Insert(index: integer; item: IPin);
begin
  inherited Insert(index, item);
end;

function TPinList.Last: IPin;
begin
  result := inherited Last as IPin;
end;

function TPinList.Remove(item: IPin): integer;
begin
  result := inherited Remove(item);
end;

function TPinList.GetPinInfo(index: integer): TPinInfo;
begin
  if assigned(Items[index]) then
    Items[index].QueryPinInfo(result);
end;

// *****************************************************************************
// TPersistentMemory
// *****************************************************************************

constructor TPersistentMemory.Create;
begin
  FData       := nil;
  FDataLength := 0;
end;

destructor TPersistentMemory.Destroy;
begin
  AllocateMemory(0);
  inherited Destroy;
end;

procedure TPersistentMemory.AllocateMemory(ALength: Cardinal);
begin
  if (FDataLength > 0) and (FData <> nil) then
  begin
    FreeMem(FData, FDataLength);
    FData       := nil;
    FDataLength := 0;
  end;
  if ALength > 0 then
  begin
    GetMem(FData, ALength);
    ZeroMemory(FData, ALength);
    FDataLength := ALength;
  end
end;

procedure TPersistentMemory.ReadData(Stream: TStream);
var
  ALength: Cardinal;
begin
  Stream.Read(ALength, SizeOf(Cardinal));
  AllocateMemory(ALength);
  if ALength > 0 then
    Stream.Read(FData^, ALength);
end;

procedure TPersistentMemory.WriteData(Stream: TStream);
begin
  Stream.Write(FDataLength, SizeOf(Cardinal));
  if FDataLength > 0 then
    Stream.Write(FData^, FDataLength);
end;

procedure TPersistentMemory.Assign(Source: TPersistent);
begin
  if Source is TPersistentMemory then
  begin
    if (Source <> self) then
    begin
      AllocateMemory(TPersistentMemory(Source).FDataLength);
      if FDataLength > 0 then
        move(TPersistentMemory(Source).FData^, FData^, FDataLength);
    end;
  end
  else
    inherited Assign(Source);
end;

procedure TPersistentMemory.AssignTo(Dest: TPersistent);
begin
  Dest.Assign(self);
end;

function TPersistentMemory.Equal(Memory: TPersistentMemory): boolean;
begin
  result := FALSE;
  if (Memory.FDataLength > 0) and (Memory.FDataLength = FDataLength) and (Memory.FData <> nil) and (FData <> nil) then
    result := CompareMem(Memory.FData, FData, FDataLength);
end;

procedure TPersistentMemory.DefineProperties(Filer: TFiler);
  function DoWrite: boolean;
  begin
    result := TRUE;
    if Filer.Ancestor <> nil then
    begin
      result := TRUE;
      if Filer.Ancestor is TPersistentMemory then
        result := not Equal(TPersistentMemory(Filer.Ancestor))
    end;
  end;

begin
  Filer.DefineBinaryProperty('data', ReadData, WriteData, DoWrite);
end;

// *****************************************************************************
// TBaseFilter
// *****************************************************************************

procedure TBaseFilter.SetMoniker(Moniker: IMoniker);
var
  MemStream: TMemoryStream;
  AdaStream: TStreamAdapter;
begin
  if Moniker = nil then
  begin
    DataLength := 0;
    Exit;
  end;
  MemStream := TMemoryStream.Create;
  AdaStream := TStreamAdapter.Create(MemStream, soReference);
  OleSaveToStream(Moniker, AdaStream);
  DataLength := MemStream.Size;
  move(MemStream.Memory^, Data^, DataLength);
  AdaStream.Free;
  MemStream.Free;
end;

function TBaseFilter.GetMoniker: IMoniker;
var
  MemStream: TMemoryStream;
  AdaStream: TStreamAdapter;
begin
  if DataLength > 0 then
  begin
    MemStream := TMemoryStream.Create;
    MemStream.SetSize(DataLength);
    move(Data^, MemStream.Memory^, DataLength);
    AdaStream := TStreamAdapter.Create(MemStream, soReference);
    OleLoadFromStream(AdaStream, IMoniker, result);
    AdaStream.Free;
    MemStream.Free;
  end
  else
    result := nil;
end;

function TBaseFilter.CreateFilter: IBaseFilter;
var
  AMoniker: IMoniker;
begin
  AMoniker := Moniker;
  if AMoniker <> nil then
  begin
    AMoniker.BindToObject(nil, nil, IBaseFilter, result);
    AMoniker := nil;
  end
  else
    result := nil;
end;

function TBaseFilter.PropertyBag(Name: WideString): OleVariant;
var
  AMoniker: IMoniker;
  PropBag : IPropertyBag;
begin
  AMoniker := Moniker;
  if AMoniker <> nil then
  begin
    AMoniker.BindToStorage(nil, nil, IID_IPropertyBag, PropBag);
    if PropBag <> nil then
      PropBag.Read(PWideChar(Name), result, nil);
    PropBag  := nil;
    AMoniker := nil;
  end
  else
    result := VarNULL;
end;

// milenko start (added functions from dshowutil.cpp)
function FindRenderer(pGB: IGraphBuilder; const MediaType: PGUID; out ppFilter: IBaseFilter): HRESULT;
var
  Enum                    : IEnumFilters;
  Filter                  : IBaseFilter;
  Pin                     : IPin;
  Fetched, InPins, OutPins: Cardinal;
  Found                   : boolean;
  MediaType_              : TAMMediaType;
begin
  Found := FALSE;

  // Verify graph builder interface
  if not assigned(pGB) then
  begin
    result := E_NOINTERFACE;
    Exit;
  end;

  // Verify that a media type was passed
  if not assigned(MediaType) then
  begin
    result := E_POINTER;
    Exit;
  end;

  // Clear the filter pointer in case there is no match
  if assigned(ppFilter) then
    ppFilter := nil;

  // Get filter enumerator
  result := pGB.EnumFilters(Enum);
  if Failed(result) then
    Exit;

  Enum.Reset;

  // Enumerate all filters in the graph
  while ((not Found) and (Enum.Next(1, Filter, @Fetched) = S_OK)) do
  begin
    // Find a filter with one input and no output pins
    result := CountFilterPins(Filter, InPins, OutPins);
    if Failed(result) then
      break;

    if ((InPins = 1) and (OutPins = 0)) then
    begin
      // Get the first pin on the filter
      Pin := nil;
      Pin := GetInPin(Filter, 0);

      // Read this pin's major media type
      result := Pin.ConnectionMediaType(MediaType_);
      if Failed(result) then
        break;

      // Is this pin's media type the requested type?
      // If so, then this is the renderer for which we are searching.
      // Copy the interface pointer and return.
      if IsEqualGUID(MediaType_.majortype, MediaType^) then
      begin
        // Found our filter
        ppFilter := Filter;
        Found    := TRUE;
      end
      else
      begin
        // This is not the renderer, so release the interface.
        Filter := nil;
      end;

      // Delete memory allocated by ConnectionMediaType()
      UtilFreeMediaType(@MediaType_);
    end
    else
    begin
      // No match, so release the interface
      Filter := nil;
    end;
  end;

  Enum := nil;
end;

function FindAudioRenderer(pGB: IGraphBuilder; out ppFilter: IBaseFilter): HRESULT;
begin
  result := FindRenderer(pGB, @MEDIATYPE_Audio, ppFilter);
end;

function FindVideoRenderer(pGB: IGraphBuilder; out ppFilter: IBaseFilter): HRESULT;
begin
  result := FindRenderer(pGB, @MEDIATYPE_Video, ppFilter);
end;

function CountFilterPins(pFilter: IBaseFilter; out pulInPins: Cardinal; out pulOutPins: Cardinal): HRESULT;
var
  Enum  : IEnumPins;
  Found : Cardinal;
  Pin   : IPin;
  PinDir: TPinDirection;
begin
  // Verify input
  if (not assigned(pFilter) or not assigned(@pulInPins) or not assigned(@pulOutPins)) then
  begin
    result := E_POINTER;
    Exit;
  end;

  // Clear number of pins found
  pulInPins  := 0;
  pulOutPins := 0;

  // Get pin enumerator
  result := pFilter.EnumPins(Enum);
  if Failed(result) then
    Exit;

  Enum.Reset;

  // Count every pin on the filter
  while (S_OK = Enum.Next(1, Pin, @Found)) do
  begin
    result := Pin.QueryDirection(PinDir);
    if (PinDir = PINDIR_INPUT) then
      inc(pulInPins)
    else
      inc(pulOutPins);
    Pin := nil;
  end;

  Enum := nil;
end;

function CountTotalFilterPins(pFilter: IBaseFilter; out pulPins: Cardinal): HRESULT;
var
  Enum : IEnumPins;
  Found: Cardinal;
  Pin  : IPin;
begin
  // Verify input
  if (not assigned(pFilter) or not assigned(@pulPins)) then
  begin
    result := E_POINTER;
    Exit;
  end;

  // Clear number of pins found
  pulPins := 0;

  // Get pin enumerator
  result := pFilter.EnumPins(Enum);
  if Failed(result) then
    Exit;

  // Count every pin on the filter, ignoring direction
  while (S_OK = Enum.Next(1, Pin, @Found)) do
  begin
    inc(pulPins);
    Pin := nil;
  end;

  Enum := nil;
end;

function GetPin(pFilter: IBaseFilter; dirrequired: TPinDirection; iNum: integer; out ppPin: IPin): HRESULT;
var
  Enum  : IEnumPins;
  Found : Cardinal;
  Pin   : IPin;
  PinDir: TPinDirection;
begin
  ppPin := nil;

  if not assigned(pFilter) then
  begin
    result := E_POINTER;
    Exit;
  end;

  result := pFilter.EnumPins(Enum);
  if Failed(result) then
    Exit;

  result := E_FAIL;

  while (S_OK = Enum.Next(1, Pin, @Found)) do
  begin
    Pin.QueryDirection(PinDir);
    if (PinDir = dirrequired) then
    begin
      if (iNum = 0) then
      begin
        ppPin  := Pin;  // Return the pin's interface
        result := S_OK; // Found requested pin, so clear error
        break;
      end;
      inc(iNum);
    end;
    Pin := nil;
  end;
  Enum := nil;
end;

function GetInPin(pFilter: IBaseFilter; nPin: integer): IPin;
begin
  GetPin(pFilter, PINDIR_INPUT, nPin, result);
end;

function GetOutPin(pFilter: IBaseFilter; nPin: integer): IPin;
begin
  GetPin(pFilter, PINDIR_OUTPUT, nPin, result);
end;

function FindOtherSplitterPin(pPinIn: IPin; GUID: TGUID; nStream: integer; out ppSplitPin: IPin): HRESULT;
var
  PinOut         : IPin;
  ThisPinInfo, pi: TPinInfo;
  EnumPins       : IEnumPins;
  Fetched        : Cardinal;
  Pin            : IPin;
  MediaEnum      : IEnumMediaTypes;
  MediaType      : PAMMediaType;
begin
  if not assigned(ppSplitPin) then
  begin
    result := E_POINTER;
    Exit;
  end;

  PinOut := pPinIn;

  while assigned(PinOut) do
  begin
    PinOut.QueryPinInfo(ThisPinInfo);
    if assigned(ThisPinInfo.pFilter) then
      ThisPinInfo.pFilter := nil;

    PinOut := nil;
    ThisPinInfo.pFilter.EnumPins(EnumPins);
    if not assigned(EnumPins) then
    begin
      // return NULL; ???
      result := S_FALSE;
      Exit;
    end;

    // look at every pin on the current filter...
    while TRUE do
    begin
      Fetched := 0;
      ASSERT(not assigned(Pin)); // is it out of scope?
      EnumPins.Next(1, Pin, @Fetched);
      if not BOOL(Fetched) then
        break;

      Pin.QueryPinInfo(pi);
      if assigned(pi.pFilter) then
        pi.pFilter := nil;

      // if it's an input pin...
      if (pi.dir = PINDIR_INPUT) then
      begin
        // continue searching upstream from this pin
        Pin.ConnectedTo(PinOut);

        // a pin that supports the required media type is the
        // splitter pin we are looking for!  We are done
      end
      else
      begin
        Pin.EnumMediaTypes(MediaEnum);
        if assigned(MediaEnum) then
        begin
          Fetched := 0;
          MediaEnum.Next(1, MediaType, @Fetched);
          if BOOL(Fetched) then
          begin
            if IsEqualGUID(MediaType.majortype, GUID) then
            begin
              Dec(nStream);
              if (nStream = 0) then
              begin
                UtilDeleteMediaType(MediaType);
                ppSplitPin := Pin;
                result     := S_OK;
                Exit;
              end;
            end;
            UtilDeleteMediaType(MediaType);
          end;
        end;
      end;
      // go try the next pin
    end; // while
  end;

  ASSERT(FALSE);
  result := E_FAIL;
end;

function SeekNextFrame(pSeeking: IMediaSeeking; FPS: Double; Frame: longint): HRESULT;
var
  Pos: TReferenceTime;
begin
  // try seeking by frames first
  Pos    := 0;
  result := pSeeking.SetTimeFormat(TIME_FORMAT_FRAME);
  if not Failed(result) then
  begin
    pSeeking.GetCurrentPosition(Pos);
    inc(Pos);
  end
  else
  begin
    // couldn't seek by frames, use Frame and FPS to calculate time
    Pos := Round(Frame * UNITS / FPS);
    // add a half-frame to seek to middle of the frame
    Pos := Pos + Round(UNITS * 0.5 / FPS);
  end;

  result := pSeeking.SetPositions(Pos, AM_SEEKING_AbsolutePositioning, Pos, AM_SEEKING_NoPositioning);
end;

procedure ShowFilenameByCLSID(clsid: TGUID; out szFilename: WideString);
begin
  szFilename := '<Unknown>';
  with TRegistry.Create do
  begin
    RootKey := HKEY_LOCAL_MACHINE;
    if KeyExists('Software\Classes\CLSID\' + GUIDToString(clsid) + 'InprocServer32') then
    begin
      if OpenKeyReadOnly('Software\Classes\CLSID\' + GUIDToString(clsid) + 'InprocServer32') then
      begin
        szFilename := ReadString('');
        CloseKey;
      end;
    end;
    Free;
  end;
end;

function GetFileDurationString(pMS: IMediaSeeking; out szDuration: WideString): HRESULT;
var
  guidOriginalFormat: TGUID;
  Duration          : Int64;
  TotalMS           : Cardinal;
  Ms                : integer;
  Seconds           : integer;
  Minutes           : integer;
begin
  if not assigned(pMS) then
  begin
    result := E_NOINTERFACE;
    Exit;
  end;

  if not assigned(@szDuration) then
  begin
    result := E_POINTER;
    Exit;
  end;

  // Initialize the display in case we can't read the duration
  szDuration := '<00:00.000>';

  // Is media time supported for this file?
  if (S_OK <> pMS.IsFormatSupported(TIME_FORMAT_MEDIA_TIME)) then
  begin
    result := E_NOINTERFACE;
    Exit;
  end;

  // Read the time format to restore later
  result := pMS.GetTimeFormat(guidOriginalFormat);
  if Failed(result) then
    Exit;

  // Ensure media time format for easy display
  result := pMS.SetTimeFormat(TIME_FORMAT_MEDIA_TIME);
  if Failed(result) then
    Exit;

  // Read the file's duration
  result := pMS.GetDuration(Duration);
  if Failed(result) then
    Exit;

  // Return to the original format
  if not IsEqualGUID(guidOriginalFormat, TIME_FORMAT_MEDIA_TIME) then
  begin
    result := pMS.SetTimeFormat(guidOriginalFormat);
    if Failed(result) then
      Exit;
  end;

  // Convert the LONGLONG duration into human-readable format
  TotalMS := Cardinal(Duration div 10000); // 100ns -> ms
  Ms      := TotalMS mod 1000;
  Seconds := TotalMS div 1000;
  Minutes := Seconds div 60;
  Seconds := Seconds mod 60;

  // Update the string
  szDuration := IntToStr(Minutes) + 'm:' + IntToStr(Seconds) + '.' + IntToStr(Ms) + 's';
end;

function CanFrameStep(pGB: IGraphBuilder): boolean;
var
  pFS: IVideoFrameStep;
  hr : HRESULT;
begin
  // Get frame step interface
  hr := pGB.QueryInterface(IID_IVideoFrameStep, pFS);
  if Failed(hr) then
  begin
    result := FALSE;
    Exit;
  end;

  // Check if this decoder can step
  hr := pFS.CanStep(0, nil);

  // Release frame step interface
  pFS := nil;

  result := hr = S_OK;
end;

procedure UtilDeleteMediaType(pmt: PAMMediaType);
begin
  // Allow NULL pointers for coding simplicity
  if (pmt = nil) then
    Exit;

  // Free media type's format data
  if (pmt.cbFormat <> 0) then
  begin
    CoTaskMemFree(pmt.pbFormat);
    // Strictly unnecessary but tidier
    pmt.cbFormat := 0;
    pmt.pbFormat := nil;
  end;

  // Release interface
  if (pmt.pUnk <> nil) then
    pmt.pUnk := nil;

  // Free media type
  CoTaskMemFree(pmt);
end;

procedure UtilFreeMediaType(pmt: PAMMediaType);
begin
  if (pmt.cbFormat <> 0) then
  begin
    CoTaskMemFree(pmt.pbFormat);
    // Strictly unnecessary but tidier
    pmt.cbFormat := 0;
    pmt.pbFormat := nil;
  end;

  if (pmt.pUnk <> nil) then
    pmt.pUnk := nil;
end;

const
  wszStreamName: WideString = 'ActiveMovieGraph';

function SaveGraphFile(pGraph: IGraphBuilder; wszPath: WideString): HRESULT;
var
  Storage: IStorage;
  Stream : IStream;
  Persist: IPersistStream;
begin
  result := StgCreateDocfile(PWideChar(wszPath), STGM_CREATE or STGM_TRANSACTED or STGM_READWRITE or STGM_SHARE_EXCLUSIVE, 0, Storage);
  if Failed(result) then
    Exit;

  result := Storage.CreateStream(PWideChar(wszStreamName), STGM_WRITE or STGM_CREATE or STGM_SHARE_EXCLUSIVE, 0, 0, Stream);
  if Failed(result) then
    Exit;

  pGraph.QueryInterface(IID_IPersistStream, Persist);
  result  := Persist.Save(Stream, TRUE);
  Stream  := nil;
  Persist := nil;
  if Succeeded(result) then
    result := Storage.Commit(STGC_DEFAULT);
  Storage  := nil;
end;

function LoadGraphFile(pGraph: IGraphBuilder; const wszName: WideString): HRESULT;
var
  Storage      : IStorage;
  Stream       : IStream;
  PersistStream: IPersistStream;
begin
  if (S_OK <> StgIsStorageFile(PWideChar(wszName))) then
  begin
    result := E_FAIL;
    Exit;
  end;

  result := StgOpenStorage(PWideChar(wszName), nil, STGM_TRANSACTED or STGM_READ or STGM_SHARE_DENY_WRITE, nil, 0, Storage);

  if Failed(result) then
    Exit;

  result := pGraph.QueryInterface(IID_IPersistStream, PersistStream);

  if (Succeeded(result)) then
  begin
    result := Storage.OpenStream(PWideChar(wszStreamName), nil, STGM_READ or STGM_SHARE_EXCLUSIVE, 0, Stream);
    if Succeeded(result) then
    begin
      result := PersistStream.Load(Stream);
      Stream := nil;
    end;
    PersistStream := nil;
  end;

  Storage := nil;
end;
// milenko end

// Michael Start.
// -----------------------------------------------------------------------------
// Name: GetDXVersion()
// Desc: This function returns the DirectX version.
// Arguments:
// pdwDirectXVersion - This can be NULL.  If non-NULL, the return value is:
// 0x00000000 = No DirectX installed
// 0x00010000 = DirectX 1.0 installed
// 0x00020000 = DirectX 2.0 installed
// 0x00030000 = DirectX 3.0 installed
// 0x00030001 = DirectX 3.0a installed
// 0x00050000 = DirectX 5.0 installed
// 0x00060000 = DirectX 6.0 installed
// 0x00060100 = DirectX 6.1 installed
// 0x00060101 = DirectX 6.1a installed
// 0x00070000 = DirectX 7.0 installed
// 0x00070001 = DirectX 7.0a installed
// 0x00080000 = DirectX 8.0 installed
// 0x00080100 = DirectX 8.1 installed
// 0x00080101 = DirectX 8.1a installed
// 0x00080102 = DirectX 8.1b installed
// 0x00080200 = DirectX 8.2 installed
// 0x00090000 = DirectX 9.0 installed
// 0x00090001 = DirectX 9.0a installed
// 0x00090002 = DirectX 9.0b installed
// strDirectXVersion - Destination string to receive a string name of the DirectX Version.  Can be NULL.
// cchDirectXVersion - Size of destination buffer in characters.  Length should be at least 10 chars.
// Returns: S_OK if the function succeeds.
// E_FAIL if the DirectX version info couldn't be determined.
//
// Please note that this code is intended as a general guideline. Your
// app will probably be able to simply query for functionality (via
// QueryInterface) for one or two components.
//
// Also please ensure your app will run on future releases of DirectX.
// For example:
// "if( dwDirectXVersion != 0x00080100 ) return false;" is VERY BAD.
// "if( dwDirectXVersion < 0x00080100 ) return false;" is MUCH BETTER.
// -----------------------------------------------------------------------------
function GetDXVersion(var pdwDirectXVersion: DWord; out strDirectXVersion: String): HRESULT;
  function GetDirectXVersionViaDxDiag(var pdwDirectXVersionMajor: DWord; var pdwDirectXVersionMinor: DWord; var pcDirectXVersionLetter: char): HRESULT;

{$IFDEF VER130}
    function FindVarData(const V: Variant): PVarData;
    begin
      result := @TVarData(V);
      while result.VType = varByRef or varVariant do
        result := PVarData(result.VPointer);
    end;

    function VarIsType(const V: Variant; AVarType: TVarType): boolean;
    begin
      result := FindVarData(V)^.VType = AVarType;
    end;
{$ENDIF}

  var
    hr                   : HRESULT;
    bCleanupCOM          : boolean;
    bSuccessGettingMajor : boolean;
    bSuccessGettingMinor : boolean;
    bSuccessGettingLetter: boolean;
    bGotDirectXVersion   : boolean;
    pDxDiagProvider      : IDxDiagProvider;
    dxDiagInitParam      : TDxDiagInitParams;
    pDxDiagRoot          : IDxDiagContainer;
    pDxDiagSystemInfo    : IDxDiagContainer;
    va                   : OleVariant;
    strDestination       : String;
  Begin
    bSuccessGettingMajor  := FALSE;
    bSuccessGettingMinor  := FALSE;
    bSuccessGettingLetter := FALSE;

    // Init COM.  COM may fail if its already been inited with a different
    // concurrency model.  And if it fails you shouldn't release it.
    hr          := CoInitialize(nil);
    bCleanupCOM := Succeeded(hr);

    // Get an IDxDiagProvider
    bGotDirectXVersion := FALSE;

    pDxDiagProvider := Nil;

    hr := CocreateInstance(CLSID_DxDiagProvider, Nil, CLSCTX_INPROC_SERVER, IID_IDxDiagProvider, pDxDiagProvider);
    if Succeeded(hr) then
    Begin
      // Fill out a DXDIAG_INIT_PARAMS struct
      dxDiagInitParam.dwSize                := SizeOf(TDxDiagInitParams);
      dxDiagInitParam.dwDxDiagHeaderVersion := DXDIAG_DX9_SDK_VERSION;
      dxDiagInitParam.bAllowWHQLChecks      := FALSE;
      dxDiagInitParam.pReserved             := Nil;

      // Init the m_pDxDiagProvider
      hr := pDxDiagProvider.Initialize(@dxDiagInitParam);
      if Succeeded(hr) then
      Begin
        pDxDiagRoot       := Nil;
        pDxDiagSystemInfo := Nil;

        // Get the DxDiag root container
        hr := pDxDiagProvider.GetRootContainer(pDxDiagRoot);
        if Succeeded(hr) then
        Begin
          // Get the object called DxDiag_SystemInfo
          hr := pDxDiagRoot.GetChildContainer('DxDiag_SystemInfo', pDxDiagSystemInfo);
          if Succeeded(hr) then
          Begin
            // Get the "dwDirectXVersionMajor" property
            VariantInit(va);
            hr := pDxDiagSystemInfo.GetProp('dwDirectXVersionMajor', va);
            if (Succeeded(hr)) and (VarIsType(va, VT_UI4)) then
            Begin
              pdwDirectXVersionMajor := va;
              bSuccessGettingMajor   := TRUE;
            End;
            VariantClear(va);

            // Get the "dwDirectXVersionMinor" property
            hr := pDxDiagSystemInfo.GetProp('dwDirectXVersionMinor', va);
            if (Succeeded(hr)) and (VarIsType(va, VT_UI4)) then
            Begin
              pdwDirectXVersionMinor := va;
              bSuccessGettingMinor   := TRUE;
            End;
            VariantClear(va);

            // Get the "szDirectXVersionLetter" property
            hr := pDxDiagSystemInfo.GetProp('szDirectXVersionLetter', va);
            If (Succeeded(hr)) and (VarIsType(va, VT_BSTR)) then
            Begin
              strDestination         := WideCharToString(TVarData(va).VOleStr);
              pcDirectXVersionLetter := strDestination[1];
              bSuccessGettingLetter  := TRUE;
            End;
            VariantClear(va);

            // If it all worked right, then mark it down
            bGotDirectXVersion := bSuccessGettingMajor and bSuccessGettingMinor and bSuccessGettingLetter;
            pDxDiagSystemInfo  := Nil;
          end;
          pDxDiagRoot := Nil;
        End;
      end;
      pDxDiagProvider := Nil;
    end;

    if bCleanupCOM then
      CoUninitialize;

    if bGotDirectXVersion then
      result := S_OK
    else
      result := E_FAIL;
  end;

// -----------------------------------------------------------------------------
// Name: GetDirectXVerionViaFileVersions()
// Desc: Tries to get the DirectX version by looking at DirectX file versions
// -----------------------------------------------------------------------------
  function GetDirectXVerionViaFileVersions(var pdwDirectXVersionMajor: DWord; var pdwDirectXVersionMinor: DWord; var pcDirectXVersionLetter: char): HRESULT;
  type
    TFileVersion = record
      Major: integer;
      Minor: integer;
      Release: integer;
      Build: integer;
    End;

    function CompareFileVersion(Version1, Version2: TFileVersion): integer;
    var
      TmpStr1, TmpStr2: String;
    Begin
      TmpStr1 := Format('%4.4d%4.4d%8.8d%4.4d', [Version1.Major, Version1.Minor, Version1.Release, Version1.Build]);
      TmpStr2 := Format('%4.4d%4.4d%8.8d%4.4d', [Version2.Major, Version2.Minor, Version2.Release, Version2.Build]);
      // milenko start (delph 5 compatibility)
      // Result := CompareValue(Strtoint64(TmpStr1),Strtoint64(TmpStr2));
      result := Strtoint64(TmpStr1) - Strtoint64(TmpStr2);
      if result > 0 then
        result := 1
      else if result < 0 then
        result := -1;
      // milenko end
    End;

    function ReadVersionInfo(FileName: string): TFileVersion;
    var
      Info: PVSFixedFileInfo;
{$IFDEF VER120}
      InfoSize: Cardinal;
{$ELSE}
      InfoSize: UINT;
{$ENDIF}
      nHwnd     : DWord;
      BufferSize: DWord;
      buffer    : Pointer;
    begin
      ZeroMemory(@result, SizeOf(TFileVersion));
      If Not FileExists(FileName) then
        Exit;
      BufferSize := GetFileVersionInfoSize(PChar(FileName), nHwnd); // Get buffer size
      if BufferSize <> 0 then                                       // if zero, there is no version info
      begin
        GetMem(buffer, BufferSize); // allocate buffer memory
        try
          if GetFileVersionInfo(PChar(FileName), nHwnd, BufferSize, buffer) then
          begin
            // got version info
            if VerQueryValue(buffer, '\', Pointer(Info), InfoSize) then
            begin
              // got root block version information
              result.Major   := HiWord(Info^.dwFileVersionMS); // extract major version
              result.Minor   := LoWord(Info^.dwFileVersionMS); // extract minor version
              result.Release := HiWord(Info^.dwFileVersionLS); // extract release version
              result.Build   := LoWord(Info^.dwFileVersionLS); // extract build version
            end;
          end;
        finally
          FreeMem(buffer, BufferSize); // release buffer memory
        end;
      end;
    end;

    function FileVersion(Major, Minor, Release, Build: integer): TFileVersion;
    Begin
      result.Major   := Major;
      result.Minor   := Minor;
      result.Release := Release;
      result.Build   := Build;
    End;

  var
    szPath: PChar;
    Path  : String;

    ddraw_Version, d3drg8x_Version, dplayx_Version, dinput_Version, d3d8_Version, mpg2splt_Version, dpnet_Version, d3d9_Version: TFileVersion;
  begin
    pdwDirectXVersionMajor := 0;
    pdwDirectXVersionMinor := 0;
    pcDirectXVersionLetter := ' ';

    result := E_FAIL;
    szPath := GetMemory(MAX_PATH);
    If GetSystemDirectory(szPath, MAX_PATH) = 0 then
    Begin
      FreeMemory(szPath);
      Exit;
    End;
    Path := StrPas(szPath);
    FreeMemory(szPath);
    If Path[length(Path)] <> '\' then
      Path := Path + '\';

    ddraw_Version    := ReadVersionInfo(Path + 'ddraw.dll');
    d3drg8x_Version  := ReadVersionInfo(Path + 'd3drg8x.dll');
    dplayx_Version   := ReadVersionInfo(Path + 'dplayx.dll');
    dinput_Version   := ReadVersionInfo(Path + 'dinput.dll');
    d3d8_Version     := ReadVersionInfo(Path + 'd3d8.dll');
    mpg2splt_Version := ReadVersionInfo(Path + 'mpg2splt.ax');
    dpnet_Version    := ReadVersionInfo(Path + 'dpnet.dll');
    d3d9_Version     := ReadVersionInfo(Path + 'd3d9.dll');

    If CompareFileVersion(ddraw_Version, FileVersion(4, 2, 0, 95)) >= 0 then // Win9x version
    Begin
      // ddraw.dll is >= DX1.0 version, so we must be at least DX1.0
      pdwDirectXVersionMajor := 1;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := ' ';
    End;

    If CompareFileVersion(ddraw_Version, FileVersion(4, 3, 0, 1096)) >= 0 then // Win9x version
    Begin
      // ddraw.dll is is >= DX2.0 version, so we must DX2.0 or DX2.0a (no redist change)
      pdwDirectXVersionMajor := 2;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := ' ';
    End;

    If CompareFileVersion(ddraw_Version, FileVersion(4, 4, 0, 68)) >= 0 then // Win9x version
    Begin
      // ddraw.dll is >= DX3.0 version, so we must be at least DX3.0
      pdwDirectXVersionMajor := 3;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := ' ';
    End;

    If CompareFileVersion(d3drg8x_Version, FileVersion(4, 4, 0, 70)) >= 0 then // Win9x version
    Begin
      // d3drg8x.dll is the DX3.0a version, so we must be DX3.0a or DX3.0b  (no redist change)
      pdwDirectXVersionMajor := 3;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := 'a';
    End;

    If CompareFileVersion(ddraw_Version, FileVersion(4, 5, 0, 155)) >= 0 then // Win9x version
    Begin
      // ddraw.dll is the DX5.0 version, so we must be DX5.0 or DX5.2 (no redist change)
      pdwDirectXVersionMajor := 5;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := ' ';
    End;

    If CompareFileVersion(ddraw_Version, FileVersion(4, 6, 0, 318)) >= 0 then // Win9x version
    Begin
      // ddraw.dll is the DX6.0 version, so we must be at least DX6.0
      pdwDirectXVersionMajor := 6;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := ' ';
    End;

    If CompareFileVersion(ddraw_Version, FileVersion(4, 6, 0, 436)) >= 0 then // Win9x version
    Begin
      // ddraw.dll is the DX6.1 version, so we must be at least DX6.1
      pdwDirectXVersionMajor := 6;
      pdwDirectXVersionMinor := 1;
      pcDirectXVersionLetter := ' ';
    End;

    If CompareFileVersion(dplayx_Version, FileVersion(4, 6, 3, 518)) >= 0 then // Win9x version
    Begin
      // dplayx.dll is the DX6.1a version, so we must be at least DX6.1a
      pdwDirectXVersionMajor := 6;
      pdwDirectXVersionMinor := 1;
      pcDirectXVersionLetter := 'a';
    End;

    If CompareFileVersion(ddraw_Version, FileVersion(4, 7, 0, 700)) >= 0 then // Win9x version
    Begin
      // TODO: find win2k version

      // ddraw.dll is the DX7.0 version, so we must be at least DX7.0
      pdwDirectXVersionMajor := 7;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := ' ';
    End;

    If CompareFileVersion(dinput_Version, FileVersion(4, 7, 0, 716)) >= 0 then // Win9x version
    Begin
      // TODO: find win2k version

      // dinput.dll is the DX7.0a version, so we must be at least DX7.0a
      pdwDirectXVersionMajor := 7;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := 'a';
    End;

    If ((ddraw_Version.Major = 4) and (CompareFileVersion(ddraw_Version, FileVersion(4, 8, 0, 400)) >= 0)) or     // Win9x version
      ((ddraw_Version.Major = 5) and (CompareFileVersion(ddraw_Version, FileVersion(5, 1, 2258, 400)) >= 0)) then // Win2k/WinXP version
    Begin
      // ddraw.dll is the DX8.0 version, so we must be at least DX8.0 or DX8.0a (no redist change)
      //
      // DirectX 8.0a contains updates for issues with international installs on Windows 2000 and issues where
      // input devices could have buttons disabled that were enabled with previous DirectX releases.
      // There are no other changes.
      pdwDirectXVersionMajor := 8;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := ' ';
    End;

    If ((d3d8_Version.Major = 4) and (CompareFileVersion(d3d8_Version, FileVersion(4, 8, 1, 881)) >= 0)) or     // Win9x version
      ((d3d8_Version.Major = 5) and (CompareFileVersion(d3d8_Version, FileVersion(5, 1, 2600, 881)) >= 0)) then // Win2k/WinXP version
    Begin
      // d3d8.dll is the DX8.1 version, so we must be at least DX8.1
      pdwDirectXVersionMajor := 8;
      pdwDirectXVersionMinor := 1;
      pcDirectXVersionLetter := ' ';
    End;

    If ((d3d8_Version.Major = 4) and (CompareFileVersion(d3d8_Version, FileVersion(4, 8, 1, 901)) >= 0)) or     // Win9x version
      ((d3d8_Version.Major = 5) and (CompareFileVersion(d3d8_Version, FileVersion(5, 1, 2600, 901)) >= 0)) then // Win2k/WinXP version
    Begin
      // d3d8.dll is the DX8.1 version, so we must be at least DX8.1
      pdwDirectXVersionMajor := 8;
      pdwDirectXVersionMinor := 1;
      pcDirectXVersionLetter := 'a';
    End;

    If (CompareFileVersion(mpg2splt_Version, FileVersion(6, 3, 1, 885)) >= 0) then // Win9x/Win2k/WinXP version
    Begin
      // quartz.dll is the DX8.1b version, so we must be at least DX8.1b
      pdwDirectXVersionMajor := 8;
      pdwDirectXVersionMinor := 1;
      pcDirectXVersionLetter := 'b';
    End;

    If ((dpnet_Version.Major = 4) and (CompareFileVersion(dpnet_Version, FileVersion(4, 9, 0, 134)) >= 0)) or     // Win9x version
      ((dpnet_Version.Major = 5) and (CompareFileVersion(dpnet_Version, FileVersion(5, 2, 3677, 134)) >= 0)) then // Win2k/WinXP version
    Begin
      // dpnet.dll is the DX8.2 version, so we must be at least DX8.2
      pdwDirectXVersionMajor := 8;
      pdwDirectXVersionMinor := 2;
      pcDirectXVersionLetter := ' ';
    End;

    If ((d3d9_Version.Major = 4) and (CompareFileVersion(d3d9_Version, FileVersion(4, 9, 0, 900)) >= 0)) or  // Win9x version
      ((d3d9_Version.Major = 5) and (CompareFileVersion(d3d9_Version, FileVersion(5, 3, 0, 900)) >= 0)) then // Win2k/WinXP version
    Begin
      // d3d9.dll is the DX9.0 version, so we must be at least DX9.0
      pdwDirectXVersionMajor := 9;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := ' ';
    End;

    If ((d3d9_Version.Major = 4) and (CompareFileVersion(d3d9_Version, FileVersion(4, 9, 0, 901)) >= 0)) or  // Win9x version
      ((d3d9_Version.Major = 5) and (CompareFileVersion(d3d9_Version, FileVersion(5, 3, 0, 901)) >= 0)) then // Win2k/WinXP version
    Begin
      // d3d9.dll is the DX9.0a version, so we must be at least DX9.0a
      pdwDirectXVersionMajor := 9;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := 'a';
    End;

    If ((d3d9_Version.Major = 4) and (CompareFileVersion(d3d9_Version, FileVersion(4, 9, 0, 902)) >= 0)) or  // Win9x version
      ((d3d9_Version.Major = 5) and (CompareFileVersion(d3d9_Version, FileVersion(5, 3, 0, 902)) >= 0)) then // Win2k/WinXP version
    Begin
      // d3d9.dll is the DX9.0b version, so we must be at least DX9.0b
      pdwDirectXVersionMajor := 9;
      pdwDirectXVersionMinor := 0;
      pcDirectXVersionLetter := 'b';
    End;
    result := S_OK;
  end;

var
  dwDirectXVersionMajor: DWord;
  dwDirectXVersionMinor: DWord;
  cDirectXVersionLetter: char;

  dwDirectXVersion: DWord;
Begin
  // Init values to unknown
  pdwDirectXVersion := 0;
  strDirectXVersion := '';

  dwDirectXVersionMajor := 0;
  dwDirectXVersionMinor := 0;
  cDirectXVersionLetter := ' ';

  // First, try to use dxdiag's COM interface to get the DirectX version.
  // The only downside is this will only work on DX9 or later.
  result := GetDirectXVersionViaDxDiag(dwDirectXVersionMajor, dwDirectXVersionMinor, cDirectXVersionLetter);

  If result = E_FAIL then
    // Getting the DirectX version info from DxDiag failed,
    // so most likely we are on DX8.x or earlier
    result := GetDirectXVerionViaFileVersions(dwDirectXVersionMajor, dwDirectXVersionMinor, cDirectXVersionLetter);

  // If both techniques failed, then return E_FAIL
  If result = E_FAIL then
    Exit;

  // Set the output values to what we got and return
  // like 0x00080102 which would represent DX8.1b
  dwDirectXVersion := dwDirectXVersionMajor;
  dwDirectXVersion := dwDirectXVersion shl 8;
  dwDirectXVersion := dwDirectXVersion + dwDirectXVersionMinor;
  dwDirectXVersion := dwDirectXVersion shl 8;
  if (Ord(cDirectXVersionLetter) >= 97) and (Ord(cDirectXVersionLetter) <= 122) then
    dwDirectXVersion := dwDirectXVersion + Int64(Ord(cDirectXVersionLetter) - 96);
  pdwDirectXVersion  := dwDirectXVersion;

  If dwDirectXVersion > 0 then
  Begin
    if cDirectXVersionLetter = ' ' then
      strDirectXVersion := Format('%d.%d', [dwDirectXVersionMajor, dwDirectXVersionMinor])
    else
      strDirectXVersion := Format('%d.%d%s', [dwDirectXVersionMajor, dwDirectXVersionMinor, cDirectXVersionLetter]);
  End;

  result := S_OK;
End;

// Michael End.

// milenko start DMO TMediaBuffer implementation
constructor TMediaBuffer.Create(MaxLen: DWord);
begin
  inherited Create;
  FRefCount  := 0;
  FMaxLength := MaxLen;
  FLength    := 0;
  FData      := nil;
  FData      := AllocMem(MaxLen);
  ASSERT(assigned(FData));
end;

destructor TMediaBuffer.Destroy;
begin
  if assigned(FData) then
  begin
    FreeMem(FData);
    FData := nil;
  end;
end;

class function TMediaBuffer.CreateBuffer(MaxLen: DWord; const IID: TGUID; out Obj): HRESULT;
var
  pBuffer: TMediaBuffer;
begin
  try
    pBuffer := TMediaBuffer.Create(MaxLen);
    result  := pBuffer.QueryInterface(IID, Obj);
  except
    result := E_OUTOFMEMORY;
  end;
end;

function TMediaBuffer.QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
begin
  if not assigned(@Obj) then
  begin
    result := E_POINTER;
    Exit;
  end
  else if IsEqualGUID(IID, IID_IMediaBuffer) or IsEqualGUID(IID, IUnknown) then
  begin
    if GetInterface(IID, Obj) then
    begin
      result := S_OK;
      Exit;
    end
  end;
  Pointer(Obj) := nil;
  result       := E_NOINTERFACE;
end;

function TMediaBuffer._AddRef: integer; stdcall;
begin
  result := InterlockedIncrement(FRefCount);
end;

function TMediaBuffer._Release: integer; stdcall;
begin
  result := InterlockedDecrement(FRefCount);
  if (result = 0) then
    Free;
end;

function TMediaBuffer.SetLength(cbLength: DWord): HRESULT; stdcall;
begin
  if (cbLength > FMaxLength) then
  begin
    result := E_INVALIDARG;
  end
  else
  begin
    FLength := cbLength;
    result  := S_OK;
  end;
end;

function TMediaBuffer.GetMaxLength(out pcbMaxLength: DWord): HRESULT; stdcall;
begin
  if not assigned(@pcbMaxLength) then
  begin
    result := E_POINTER;
    Exit;
  end
  else
  begin
    pcbMaxLength := FMaxLength;
    result       := S_OK;
  end;
end;

function TMediaBuffer.GetBufferAndLength(out ppBuffer: PByte; // not filled if NULL
  out pcbLength: DWord                                        // not filled if NULL
  ): HRESULT; stdcall;
begin
  if not assigned(@ppBuffer) or not assigned(@pcbLength) then
  begin
    result := E_POINTER;
    Exit;
  end;
  ppBuffer  := FData;
  pcbLength := FLength;
  result    := S_OK;
end;
// milenko end

// milenko start wxutil implementation
function EnlargedUnsignedDivide(Dividend: ULARGE_INTEGER; Divisor: ULONG; Remainder: PULONG): ULONG; stdcall;
asm
  {$IF CPUX86}
  mov      eax, Dividend.LowPart
  mov      edx, Dividend.HighPart
  mov      ecx, Remainder
  div      Divisor
  or       ecx,ecx
  jz       @@End
  mov      [ecx],edx
  {$ENDIF}
@@End:
end;

function Int32x32To64(a, b: integer): Int64;
asm
  imul     b
end;

function MILLISECONDS_TO_100NS_UNITS(Ms: LONGLONG): LONGLONG;
begin
  result := Int32x32To64((Ms), (UNITS div MILLISECONDS))
end;

function UInt32x32To64(a, b: DWord): ULONGLONG;
asm
  mul      b
end;

function llMulDiv(a, b, c, d: LONGLONG): LONGLONG;
var
  ua, ub     : ULARGE_INTEGER;
  uc         : DWORDLONG;
  bSign      : BOOL;
  p, ud      : array [0 .. 1] of ULARGE_INTEGER;
  x          : ULARGE_INTEGER;
  uliTotal   : ULARGE_INTEGER;
  ullResult  : DWORDLONG;
  ulic       : ULARGE_INTEGER;
  uliDividend: ULARGE_INTEGER;
  uliResult  : ULARGE_INTEGER;
  dwDivisor  : DWord;
  i          : integer;
begin
  if a >= 0 then
    ua.QuadPart := DWORDLONG(a)
  else
    ua.QuadPart := DWORDLONG(-a);
  if b >= 0 then
    ub.QuadPart := DWORDLONG(b)
  else
    ua.QuadPart := DWORDLONG(-b);
  if c >= 0 then
    uc := DWORDLONG(c)
  else
    uc  := DWORDLONG(-c);
  bSign := (a < 0) xor (b < 0);

  p[0].QuadPart := UInt32x32To64(ua.LowPart, ub.LowPart);

  x.QuadPart := UInt32x32To64(ua.LowPart, ub.HighPart) + UInt32x32To64(ua.HighPart, ub.LowPart) + p[0].HighPart;

  p[0].HighPart := x.LowPart;
  p[1].QuadPart := UInt32x32To64(ua.HighPart, ub.HighPart) + x.HighPart;

  if (d <> 0) then
  begin
    if (bSign) then
    begin
      ud[0].QuadPart := DWORDLONG(-d);
      if (d > 0) then
        ud[1].QuadPart := $FFFFFFFFFFFFFFFF // DWORDLONG(LONGLONG(-1))   //by pcplayer 为了让它在 XE3 底下编译通过.
      else
        ud[1].QuadPart := DWORDLONG(0);
    end
    else
    begin
      ud[0].QuadPart := DWORDLONG(d);
      if (d < 0) then
        ud[1].QuadPart := $FFFFFFFFFFFFFFFF // DWORDLONG(LONGLONG(-1))
      else
        ud[1].QuadPart := DWORDLONG(0);
    end;

    uliTotal.QuadPart := DWORDLONG(ud[0].LowPart) + p[0].LowPart;
    p[0].LowPart      := uliTotal.LowPart;

    uliTotal.LowPart  := uliTotal.HighPart;
    uliTotal.HighPart := 0;

    uliTotal.QuadPart := uliTotal.QuadPart + (DWORDLONG(ud[0].HighPart) + p[0].HighPart);
    p[0].HighPart     := uliTotal.LowPart;

    uliTotal.LowPart  := uliTotal.HighPart;
    uliTotal.HighPart := 0;

    p[1].QuadPart := p[1].QuadPart + ud[1].QuadPart + uliTotal.QuadPart;

    if (longint(p[1].HighPart) < 0) then
    begin
      bSign         := not bSign;
      p[0].QuadPart := not p[0].QuadPart;
      p[1].QuadPart := not p[1].QuadPart;
      p[0].QuadPart := p[0].QuadPart + 1;
      p[1].QuadPart := p[1].QuadPart + longint(p[0].QuadPart = 0);
    end;
  end;

  if (c < 0) then
    bSign := not bSign;

  if (uc <= p[1].QuadPart) then
  begin
    if bSign then
      result := LONGLONG($8000000000000000)
    else
      result := LONGLONG($7FFFFFFFFFFFFFFF);
    Exit;
  end;

  if (p[1].QuadPart = 0) then
  begin
    ullResult := p[0].QuadPart div uc;
    if bSign then
      result := -LONGLONG(ullResult)
    else
      result := LONGLONG(ullResult);
    Exit;
  end;

  ulic.QuadPart := uc;
  if (ulic.HighPart = 0) then
  begin
    dwDivisor            := DWord(uc);
    uliDividend.HighPart := p[1].LowPart;
    uliDividend.LowPart  := p[0].HighPart;
    if (uliDividend.QuadPart >= DWORDLONG(dwDivisor)) then
      uliResult.HighPart := EnlargedUnsignedDivide(uliDividend, dwDivisor, @p[0].HighPart)
    else
      uliResult.HighPart := 0;
    uliResult.LowPart    := EnlargedUnsignedDivide(p[0], dwDivisor, nil);
    if bSign then
      result := -LONGLONG(uliResult.QuadPart)
    else
      result := LONGLONG(uliResult.QuadPart);
    Exit;
  end;

  ullResult := 0;

  for i := 0 to 63 do
  begin
    ullResult     := ullResult shl 1;
    p[1].QuadPart := p[1].QuadPart shl 1;
    if ((p[0].HighPart and $80000000) <> 0) then
      p[1].LowPart := p[1].LowPart + 1;
    p[0].QuadPart  := p[0].QuadPart shl 1;
    if (uc <= p[1].QuadPart) then
    begin
      p[1].QuadPart := p[1].QuadPart - uc;
      ullResult     := ullResult + 1;
    end;
  end;

  if bSign then
    result := -LONGLONG(ullResult)
  else
    result := LONGLONG(ullResult);
end;

function Int64x32Div32(a: LONGLONG; b, c, d: longint): LONGLONG;
var
  ua         : ULARGE_INTEGER;
  ub         : DWord;
  uc         : DWord;
  bSign      : BOOL;
  p0         : ULARGE_INTEGER;
  p1         : DWord;
  x          : ULARGE_INTEGER;
  ud0        : ULARGE_INTEGER;
  ud1        : DWord;
  uliTotal   : ULARGE_INTEGER;
  uliDividend: ULARGE_INTEGER;
  uliResult  : ULARGE_INTEGER;
  dwDivisor  : DWord;
begin
  if a >= 0 then
    ua.QuadPart := DWORDLONG(a)
  else
    ua.QuadPart := DWORDLONG(-a);
  if b >= 0 then
    ub := DWord(b)
  else
    ub := DWord(-b);
  if c >= 0 then
    uc := DWord(c)
  else
    uc  := DWord(-c);
  bSign := (a < 0) xor (b < 0);

  p0.QuadPart := UInt32x32To64(ua.LowPart, ub);

  if (ua.HighPart <> 0) then
  begin
    x.QuadPart  := UInt32x32To64(ua.HighPart, ub) + p0.HighPart;
    p0.HighPart := x.LowPart;
    p1          := x.HighPart;
  end
  else
  begin
    p1 := 0;
  end;

  if (d <> 0) then
  begin
    if bSign then
    begin
      ud0.QuadPart := DWORDLONG(-(LONGLONG(d)));
      if (d > 0) then
        ud1 := DWord(-1)
      else
        ud1 := DWord(0);
    end
    else
    begin
      ud0.QuadPart := DWORDLONG(d);
      if (d < 0) then
        ud1 := DWord(-1)
      else
        ud1 := DWord(0);
    end;
    uliTotal.QuadPart := DWORDLONG(ud0.LowPart) + p0.LowPart;
    p0.LowPart        := uliTotal.LowPart;

    uliTotal.LowPart  := uliTotal.HighPart;
    uliTotal.HighPart := 0;

    uliTotal.QuadPart := uliTotal.QuadPart + (DWORDLONG(ud0.HighPart) + p0.HighPart);
    p0.HighPart       := uliTotal.LowPart;

    p1 := p1 + ud1 + uliTotal.HighPart;

    if (longint(p1) < 0) then
    begin
      bSign := not bSign;

      p0.QuadPart := not p0.QuadPart;
      p1          := not p1;
      p0.QuadPart := p0.QuadPart + 1;
      p1          := p1 + DWord(p0.QuadPart = 0);
    end;
  end;

  dwDivisor := uc;

  if (c < 0) then
    bSign := not bSign;

  if (uc <= p1) then
  begin
    if bSign then
      result := LONGLONG($8000000000000000)
    else
      result := LONGLONG($7FFFFFFFFFFFFFFF);
    Exit;
  end;

  uliDividend.HighPart := p1;
  uliDividend.LowPart  := p0.HighPart;
  if (uliDividend.QuadPart >= DWORDLONG(dwDivisor)) then
  begin
    uliResult.HighPart := EnlargedUnsignedDivide(uliDividend, dwDivisor, @p0.HighPart);
  end
  else
  begin
    uliResult.HighPart := 0;
  end;

  uliResult.LowPart := EnlargedUnsignedDivide(p0, dwDivisor, nil);

  if bSign then
    result := -LONGLONG(uliResult.QuadPart)
  else
    result := LONGLONG(uliResult.QuadPart);
end;

function HRESULT_FROM_WIN32(x: DWord): HRESULT;
begin
  if HRESULT(x) <= 0 then
    result := HRESULT(x)
  else
    result := HRESULT((x and $0000FFFF) or (FACILITY_WIN32 shl 16) or $80000000);
end;

function AmGetLastErrorToHResult: HRESULT;
var
  LastError: DWord;
begin
  LastError := GetLastError;
  if (LastError <> 0) then
    result := HRESULT_FROM_WIN32(LastError)
  else
    result := E_FAIL;
end;

function IsEqualObject(pFirst, pSecond: IUnknown): boolean;
var
  pUnknown1,           // Retrieve the IUnknown interface
  pUnknown2: IUnknown; // Retrieve the other IUnknown interface
begin
  // Different objects can't have the same interface pointer for
  // any interface

  if (pFirst = pSecond) then
  begin
    result := TRUE;
    Exit;
  end;

  // OK - do it the hard way - check if they have the same
  // IUnknown pointers - a single object can only have one of these

  ASSERT(pFirst <> nil);
  ASSERT(pSecond <> nil);

  // See if the IUnknown pointers match

  result := Succeeded(pFirst.QueryInterface(IUnknown, pUnknown1));
  if (result) then
  begin
  end;
  ASSERT(result);
  ASSERT(pUnknown1 <> nil);

  result := Succeeded(pSecond.QueryInterface(IUnknown, pUnknown2));

  // get rid of Delphi compiler warnings ..
  if (result) then
  begin
  end;

  ASSERT(result);
  ASSERT(pUnknown2 <> nil);

  // Release the extra interfaces we hold

  result    := (pUnknown1 = pUnknown2);
  pUnknown1 := nil;
  pUnknown2 := nil;
end;
// milenko end

// milenko start namedguid implementation
function GetGUIDString(GUID: TGUID): String;
begin
  if IsEqualGUID(GUID, MEDIASUBTYPE_AIFF) then
    result := 'MEDIASUBTYPE_AIFF'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AU) then
    result := 'MEDIASUBTYPE_AU'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_NTSC_M) then
    result := 'MEDIASUBTYPE_AnalogVideo_NTSC_M'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_PAL_B) then
    result := 'MEDIASUBTYPE_AnalogVideo_PAL_B'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_PAL_D) then
    result := 'MEDIASUBTYPE_AnalogVideo_PAL_D'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_PAL_G) then
    result := 'MEDIASUBTYPE_AnalogVideo_PAL_G'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_PAL_H) then
    result := 'MEDIASUBTYPE_AnalogVideo_PAL_H'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_PAL_I) then
    result := 'MEDIASUBTYPE_AnalogVideo_PAL_I'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_PAL_M) then
    result := 'MEDIASUBTYPE_AnalogVideo_PAL_M'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_PAL_N) then
    result := 'MEDIASUBTYPE_AnalogVideo_PAL_N'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_SECAM_B) then
    result := 'MEDIASUBTYPE_AnalogVideo_SECAM_B'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_SECAM_D) then
    result := 'MEDIASUBTYPE_AnalogVideo_SECAM_D'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_SECAM_G) then
    result := 'MEDIASUBTYPE_AnalogVideo_SECAM_G'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_SECAM_H) then
    result := 'MEDIASUBTYPE_AnalogVideo_SECAM_H'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_SECAM_K) then
    result := 'MEDIASUBTYPE_AnalogVideo_SECAM_K'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_SECAM_K1) then
    result := 'MEDIASUBTYPE_AnalogVideo_SECAM_K1'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AnalogVideo_SECAM_L) then
    result := 'MEDIASUBTYPE_AnalogVideo_SECAM_L'

  else if IsEqualGUID(GUID, MEDIASUBTYPE_ARGB1555) then
    result := 'MEDIASUBTYPE_ARGB1555'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_ARGB4444) then
    result := 'MEDIASUBTYPE_ARGB4444'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_ARGB32) then
    result := 'MEDIASUBTYPE_ARGB32'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_A2R10G10B10) then
    result := 'MEDIASUBTYPE_A2R10G10B10'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_A2B10G10R10) then
    result := 'MEDIASUBTYPE_A2B10G10R10'

  else if IsEqualGUID(GUID, MEDIASUBTYPE_AYUV) then
    result := 'MEDIASUBTYPE_AYUV'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_AI44) then
    result := 'MEDIASUBTYPE_AI44'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_IA44) then
    result := 'MEDIASUBTYPE_IA44'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_NV12) then
    result := 'MEDIASUBTYPE_NV12'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_IMC1) then
    result := 'MEDIASUBTYPE_IMC1'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_IMC2) then
    result := 'MEDIASUBTYPE_IMC2'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_IMC3) then
    result := 'MEDIASUBTYPE_IMC3'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_IMC4) then
    result := 'MEDIASUBTYPE_IMC4'

  else if IsEqualGUID(GUID, MEDIASUBTYPE_Asf) then
    result := 'MEDIASUBTYPE_Asf'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_Avi) then
    result := 'MEDIASUBTYPE_Avi'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_CFCC) then
    result := 'MEDIASUBTYPE_CFCC'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_CLJR) then
    result := 'MEDIASUBTYPE_CLJR'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_CPLA) then
    result := 'MEDIASUBTYPE_CPLA'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_CLPL) then
    result := 'MEDIASUBTYPE_CLPL'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DOLBY_AC3) then
    result := 'MEDIASUBTYPE_DOLBY_AC3'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DOLBY_AC3_SPDIF) then
    result := 'MEDIASUBTYPE_DOLBY_AC3_SPDIF'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DVCS) then
    result := 'MEDIASUBTYPE_DVCS'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DVD_LPCM_AUDIO) then
    result := 'MEDIASUBTYPE_DVD_LPCM_AUDIO'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DVD_NAVIGATION_DSI) then
    result := 'MEDIASUBTYPE_DVD_NAVIGATION_DSI'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DVD_NAVIGATION_PCI) then
    result := 'MEDIASUBTYPE_DVD_NAVIGATION_PCI'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DVD_NAVIGATION_PROVIDER) then
    result := 'MEDIASUBTYPE_DVD_NAVIGATION_PROVIDER'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DVD_SUBPICTURE) then
    result := 'MEDIASUBTYPE_DVD_SUBPICTURE'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DVSD) then
    result := 'MEDIASUBTYPE_DVSD'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DRM_Audio) then
    result := 'MEDIASUBTYPE_DRM_Audio'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DssAudio) then
    result := 'MEDIASUBTYPE_DssAudio'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DssVideo) then
    result := 'MEDIASUBTYPE_DssVideo'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_IF09) then
    result := 'MEDIASUBTYPE_IF09'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_IEEE_FLOAT) then
    result := 'MEDIASUBTYPE_IEEE_FLOAT'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_IJPG) then
    result := 'MEDIASUBTYPE_IJPG'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_IYUV) then
    result := 'MEDIASUBTYPE_IYUV'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_Line21_BytePair) then
    result := 'MEDIASUBTYPE_Line21_BytePair'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_Line21_GOPPacket) then
    result := 'MEDIASUBTYPE_Line21_GOPPacket'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_Line21_VBIRawData) then
    result := 'MEDIASUBTYPE_Line21_VBIRawData'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MDVF) then
    result := 'MEDIASUBTYPE_MDVF'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MJPG) then
    result := 'MEDIASUBTYPE_MJPG'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MPEG1Audio) then
    result := 'MEDIASUBTYPE_MPEG1Audio'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MPEG1AudioPayload) then
    result := 'MEDIASUBTYPE_MPEG1AudioPayload'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MPEG1Packet) then
    result := 'MEDIASUBTYPE_MPEG1Packet'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MPEG1Payload) then
    result := 'MEDIASUBTYPE_MPEG1Payload'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MPEG1System) then
    result := 'MEDIASUBTYPE_MPEG1System'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MPEG1Video) then
    result := 'MEDIASUBTYPE_MPEG1Video'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MPEG1VideoCD) then
    result := 'MEDIASUBTYPE_MPEG1VideoCD'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MPEG2_AUDIO) then
    result := 'MEDIASUBTYPE_MPEG2_AUDIO'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MPEG2_PROGRAM) then
    result := 'MEDIASUBTYPE_MPEG2_PROGRAM'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MPEG2_TRANSPORT) then
    result := 'MEDIASUBTYPE_MPEG2_TRANSPORT'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_MPEG2_VIDEO) then
    result := 'MEDIASUBTYPE_MPEG2_VIDEO'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_None) then
    result := 'MEDIASUBTYPE_None'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_Overlay) then
    result := 'MEDIASUBTYPE_Overlay'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_PCM) then
    result := 'MEDIASUBTYPE_PCM'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_PCMAudio_Obsolete) then
    result := 'MEDIASUBTYPE_PCMAudio_Obsolete'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_Plum) then
    result := 'MEDIASUBTYPE_Plum'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_QTJpeg) then
    result := 'MEDIASUBTYPE_QTJpeg'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_QTMovie) then
    result := 'MEDIASUBTYPE_QTMovie'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_QTRle) then
    result := 'MEDIASUBTYPE_QTRle'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_QTRpza) then
    result := 'MEDIASUBTYPE_QTRpza'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_QTSmc) then
    result := 'MEDIASUBTYPE_QTSmc'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_RAW_SPORT) then
    result := 'MEDIASUBTYPE_RAW_SPORT'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_RGB1) then
    result := 'MEDIASUBTYPE_RGB1'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_RGB24) then
    result := 'MEDIASUBTYPE_RGB24'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_RGB32) then
    result := 'MEDIASUBTYPE_RGB32'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_RGB4) then
    result := 'MEDIASUBTYPE_RGB4'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_RGB555) then
    result := 'MEDIASUBTYPE_RGB555'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_RGB565) then
    result := 'MEDIASUBTYPE_RGB565'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_RGB8) then
    result := 'MEDIASUBTYPE_RGB8'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_SPDIF_TAG_241h) then
    result := 'MEDIASUBTYPE_SPDIF_TAG_241h'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_TELETEXT) then
    result := 'MEDIASUBTYPE_TELETEXT'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_TVMJ) then
    result := 'MEDIASUBTYPE_TVMJ'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_UYVY) then
    result := 'MEDIASUBTYPE_UYVY'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_VPVBI) then
    result := 'MEDIASUBTYPE_VPVBI'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_VPVideo) then
    result := 'MEDIASUBTYPE_VPVideo'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_WAKE) then
    result := 'MEDIASUBTYPE_WAKE'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_WAVE) then
    result := 'MEDIASUBTYPE_WAVE'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_Y211) then
    result := 'MEDIASUBTYPE_Y211'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_Y411) then
    result := 'MEDIASUBTYPE_Y411'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_Y41P) then
    result := 'MEDIASUBTYPE_Y41P'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_YUY2) then
    result := 'MEDIASUBTYPE_YUY2'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_YV12) then
    result := 'MEDIASUBTYPE_YV12'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_YVU9) then
    result := 'MEDIASUBTYPE_YVU9'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_YVYU) then
    result := 'MEDIASUBTYPE_YVYU'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_YUYV) then
    result := 'MEDIASUBTYPE_YUYV'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_dvhd) then
    result := 'MEDIASUBTYPE_dvhd'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_DVSD) then
    result := 'MEDIASUBTYPE_dvsd'
  else if IsEqualGUID(GUID, MEDIASUBTYPE_dvsl) then
    result := 'MEDIASUBTYPE_dvsl'

  else if IsEqualGUID(GUID, MEDIATYPE_AUXLine21Data) then
    result := 'MEDIATYPE_AUXLine21Data'
  else if IsEqualGUID(GUID, MEDIATYPE_AnalogAudio) then
    result := 'MEDIATYPE_AnalogAudio'
  else if IsEqualGUID(GUID, MEDIATYPE_AnalogVideo) then
    result := 'MEDIATYPE_AnalogVideo'
  else if IsEqualGUID(GUID, MEDIATYPE_Audio) then
    result := 'MEDIATYPE_Audio'
  else if IsEqualGUID(GUID, MEDIATYPE_DVD_ENCRYPTED_PACK) then
    result := 'MEDIATYPE_DVD_ENCRYPTED_PACK'
  else if IsEqualGUID(GUID, MEDIATYPE_DVD_NAVIGATION) then
    result := 'MEDIATYPE_DVD_NAVIGATION'
  else if IsEqualGUID(GUID, MEDIATYPE_File) then
    result := 'MEDIATYPE_File'
  else if IsEqualGUID(GUID, MEDIATYPE_Interleaved) then
    result := 'MEDIATYPE_Interleaved'
  else if IsEqualGUID(GUID, MEDIATYPE_LMRT) then
    result := 'MEDIATYPE_LMRT'
  else if IsEqualGUID(GUID, MEDIATYPE_MPEG1SystemStream) then
    result := 'MEDIATYPE_MPEG1SystemStream'
  else if IsEqualGUID(GUID, MEDIATYPE_MPEG2_PES) then
    result := 'MEDIATYPE_MPEG2_PES'
  else if IsEqualGUID(GUID, MEDIATYPE_Midi) then
    result := 'MEDIATYPE_Midi'
  else if IsEqualGUID(GUID, MEDIATYPE_ScriptCommand) then
    result := 'MEDIATYPE_ScriptCommand'
  else if IsEqualGUID(GUID, MEDIATYPE_Stream) then
    result := 'MEDIATYPE_Stream'
  else if IsEqualGUID(GUID, MEDIATYPE_Text) then
    result := 'MEDIATYPE_Text'
  else if IsEqualGUID(GUID, MEDIATYPE_Timecode) then
    result := 'MEDIATYPE_Timecode'
  else if IsEqualGUID(GUID, MEDIATYPE_URL_STREAM) then
    result := 'MEDIATYPE_URL_STREAM'
  else if IsEqualGUID(GUID, MEDIATYPE_VBI) then
    result := 'MEDIATYPE_VBI'
  else if IsEqualGUID(GUID, MEDIATYPE_Video) then
    result := 'MEDIATYPE_Video'

  else if IsEqualGUID(GUID, WMMEDIATYPE_Audio) then
    result := 'WMMEDIATYPE_Audio'
  else if IsEqualGUID(GUID, WMMEDIATYPE_Video) then
    result := 'WMMEDIATYPE_Video'
  else if IsEqualGUID(GUID, WMMEDIATYPE_Script) then
    result := 'WMMEDIATYPE_Script'
  else if IsEqualGUID(GUID, WMMEDIATYPE_Image) then
    result := 'WMMEDIATYPE_Image'
  else if IsEqualGUID(GUID, WMMEDIATYPE_FileTransfer) then
    result := 'WMMEDIATYPE_FileTransfer'
  else if IsEqualGUID(GUID, WMMEDIATYPE_Text) then
    result := 'WMMEDIATYPE_Text'

  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_Base) then
    result := 'WMMEDIASUBTYPE_Base'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_RGB1) then
    result := 'WMMEDIASUBTYPE_RGB1'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_RGB4) then
    result := 'WMMEDIASUBTYPE_RGB4'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_RGB8) then
    result := 'WMMEDIASUBTYPE_RGB8'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_RGB565) then
    result := 'WMMEDIASUBTYPE_RGB565'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_RGB555) then
    result := 'WMMEDIASUBTYPE_RGB555'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_RGB24) then
    result := 'WMMEDIASUBTYPE_RGB24'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_RGB32) then
    result := 'WMMEDIASUBTYPE_RGB32'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_I420) then
    result := 'WMMEDIASUBTYPE_I420'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_IYUV) then
    result := 'WMMEDIASUBTYPE_IYUV'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_YV12) then
    result := 'WMMEDIASUBTYPE_YV12'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_YUY2) then
    result := 'WMMEDIASUBTYPE_YUY2'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_UYVY) then
    result := 'WMMEDIASUBTYPE_UYVY'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_YVYU) then
    result := 'WMMEDIASUBTYPE_YVYU'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_YVU9) then
    result := 'WMMEDIASUBTYPE_YVU9'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_MP43) then
    result := 'WMMEDIASUBTYPE_MP43'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_MP4S) then
    result := 'WMMEDIASUBTYPE_MP4S'

  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_WMV1) then
    result := 'WMMEDIASUBTYPE_WMV1'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_WMV2) then
    result := 'WMMEDIASUBTYPE_WMV2'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_WMV3) then
    result := 'WMMEDIASUBTYPE_WMV3'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_MSS1) then
    result := 'WMMEDIASUBTYPE_MSS1'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_MSS2) then
    result := 'WMMEDIASUBTYPE_MSS2'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_MPEG2_VIDEO) then
    result := 'WMMEDIASUBTYPE_MPEG2_VIDEO'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_PCM) then
    result := 'WMMEDIASUBTYPE_PCM'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_DRM) then
    result := 'WMMEDIASUBTYPE_DRM'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_WMAudioV9) then
    result := 'WMMEDIASUBTYPE_WMAudioV9'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_WMAudio_Lossless) then
    result := 'WMMEDIASUBTYPE_WMAudio_Lossless'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_WMAudioV8) then
    result := 'WMMEDIASUBTYPE_WMAudioV8'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_WMAudioV7) then
    result := 'WMMEDIASUBTYPE_WMAudioV7'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_WMAudioV2) then
    result := 'WMMEDIASUBTYPE_WMAudioV2'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_ACELPnet) then
    result := 'WMMEDIASUBTYPE_ACELPnet'
  else if IsEqualGUID(GUID, WMMEDIASUBTYPE_WMSP1) then
    result := 'WMMEDIASUBTYPE_WMSP1'

  else if IsEqualGUID(GUID, WMFORMAT_VideoInfo) then
    result := 'WMFORMAT_VideoInfo'
  else if IsEqualGUID(GUID, WMFORMAT_WaveFormatEx) then
    result := 'WMFORMAT_WaveFormatEx'
  else if IsEqualGUID(GUID, WMFORMAT_Script) then
    result := 'WMFORMAT_Script'
  else if IsEqualGUID(GUID, WMFORMAT_MPEG2Video) then
    result := 'WMFORMAT_MPEG2Video'

  else if IsEqualGUID(GUID, WMSCRIPTTYPE_TwoStrings) then
    result := 'WMSCRIPTTYPE_TwoStrings'

  else if IsEqualGUID(GUID, PIN_CATEGORY_ANALOGVIDEOIN) then
    result := 'PIN_CATEGORY_ANALOGVIDEOIN'
  else if IsEqualGUID(GUID, PIN_CATEGORY_CAPTURE) then
    result := 'PIN_CATEGORY_CAPTURE'
  else if IsEqualGUID(GUID, PIN_CATEGORY_CC) then
    result := 'PIN_CATEGORY_CC'
  else if IsEqualGUID(GUID, PIN_CATEGORY_EDS) then
    result := 'PIN_CATEGORY_EDS'
  else if IsEqualGUID(GUID, PIN_CATEGORY_NABTS) then
    result := 'PIN_CATEGORY_NABTS'
  else if IsEqualGUID(GUID, PIN_CATEGORY_PREVIEW) then
    result := 'PIN_CATEGORY_PREVIEW'
  else if IsEqualGUID(GUID, PIN_CATEGORY_STILL) then
    result := 'PIN_CATEGORY_STILL'
  else if IsEqualGUID(GUID, PIN_CATEGORY_TELETEXT) then
    result := 'PIN_CATEGORY_TELETEXT'
  else if IsEqualGUID(GUID, PIN_CATEGORY_TIMECODE) then
    result := 'PIN_CATEGORY_TIMECODE'
  else if IsEqualGUID(GUID, PIN_CATEGORY_VBI) then
    result := 'PIN_CATEGORY_VBI'
  else if IsEqualGUID(GUID, PIN_CATEGORY_VIDEOPORT) then
    result := 'PIN_CATEGORY_VIDEOPORT'
  else if IsEqualGUID(GUID, PIN_CATEGORY_VIDEOPORT_VBI) then
    result := 'PIN_CATEGORY_VIDEOPORT_VBI'

  else if IsEqualGUID(GUID, CLSID_ACMWrapper) then
    result := 'CLSID_ACMWrapper'
  else if IsEqualGUID(GUID, CLSID_AVICo) then
    result := 'CLSID_AVICo'
  else if IsEqualGUID(GUID, CLSID_AVIDec) then
    result := 'CLSID_AVIDec'
  else if IsEqualGUID(GUID, CLSID_AVIDoc) then
    result := 'CLSID_AVIDoc'
  else if IsEqualGUID(GUID, CLSID_AVIDraw) then
    result := 'CLSID_AVIDraw'
  else if IsEqualGUID(GUID, CLSID_AVIMIDIRender) then
    result := 'CLSID_AVIMIDIRender'
  else if IsEqualGUID(GUID, CLSID_ActiveMovieCategories) then
    result := 'CLSID_ActiveMovieCategories'
  else if IsEqualGUID(GUID, CLSID_AnalogVideoDecoderPropertyPage) then
    result := 'CLSID_AnalogVideoDecoderPropertyPage'
  else if IsEqualGUID(GUID, CLSID_WMAsfReader) then
    result := 'CLSID_WMAsfReader'
  else if IsEqualGUID(GUID, CLSID_WMAsfWriter) then
    result := 'CLSID_WMAsfWriter'
  else if IsEqualGUID(GUID, CLSID_AsyncReader) then
    result := 'CLSID_AsyncReader'
  else if IsEqualGUID(GUID, CLSID_AudioCompressorCategory) then
    result := 'CLSID_AudioCompressorCategory'
  else if IsEqualGUID(GUID, CLSID_AudioInputDeviceCategory) then
    result := 'CLSID_AudioInputDeviceCategory'
  else if IsEqualGUID(GUID, CLSID_AudioProperties) then
    result := 'CLSID_AudioProperties'
  else if IsEqualGUID(GUID, CLSID_AudioRecord) then
    result := 'CLSID_AudioRecord'
  else if IsEqualGUID(GUID, CLSID_AudioRender) then
    result := 'CLSID_AudioRender'
  else if IsEqualGUID(GUID, CLSID_AudioRendererCategory) then
    result := 'CLSID_AudioRendererCategory'
  else if IsEqualGUID(GUID, CLSID_AviDest) then
    result := 'CLSID_AviDest'
  else if IsEqualGUID(GUID, CLSID_AviMuxProptyPage) then
    result := 'CLSID_AviMuxProptyPage'
  else if IsEqualGUID(GUID, CLSID_AviMuxProptyPage1) then
    result := 'CLSID_AviMuxProptyPage1'
  else if IsEqualGUID(GUID, CLSID_AviReader) then
    result := 'CLSID_AviReader'
  else if IsEqualGUID(GUID, CLSID_AviSplitter) then
    result := 'CLSID_AviSplitter'
  else if IsEqualGUID(GUID, CLSID_CAcmCoClassManager) then
    result := 'CLSID_CAcmCoClassManager'
  else if IsEqualGUID(GUID, CLSID_CDeviceMoniker) then
    result := 'CLSID_CDeviceMoniker'
  else if IsEqualGUID(GUID, CLSID_CIcmCoClassManager) then
    result := 'CLSID_CIcmCoClassManager'
  else if IsEqualGUID(GUID, CLSID_CMidiOutClassManager) then
    result := 'CLSID_CMidiOutClassManager'
  else if IsEqualGUID(GUID, CLSID_CMpegAudioCodec) then
    result := 'CLSID_CMpegAudioCodec'
  else if IsEqualGUID(GUID, CLSID_CMpegVideoCodec) then
    result := 'CLSID_CMpegVideoCodec'
  else if IsEqualGUID(GUID, CLSID_CQzFilterClassManager) then
    result := 'CLSID_CQzFilterClassManager'
  else if IsEqualGUID(GUID, CLSID_CVidCapClassManager) then
    result := 'CLSID_CVidCapClassManager'
  else if IsEqualGUID(GUID, CLSID_CWaveOutClassManager) then
    result := 'CLSID_CWaveOutClassManager'
  else if IsEqualGUID(GUID, CLSID_CWaveinClassManager) then
    result := 'CLSID_CWaveinClassManager'
  else if IsEqualGUID(GUID, CLSID_CameraControlPropertyPage) then
    result := 'CLSID_CameraControlPropertyPage'
  else if IsEqualGUID(GUID, CLSID_CaptureGraphBuilder) then
    result := 'CLSID_CaptureGraphBuilder'
  else if IsEqualGUID(GUID, CLSID_CaptureProperties) then
    result := 'CLSID_CaptureProperties'
  else if IsEqualGUID(GUID, CLSID_Colour) then
    result := 'CLSID_Colour'
  else if IsEqualGUID(GUID, CLSID_CrossbarFilterPropertyPage) then
    result := 'CLSID_CrossbarFilterPropertyPage'
  else if IsEqualGUID(GUID, CLSID_DSoundRender) then
    result := 'CLSID_DSoundRender'
  else if IsEqualGUID(GUID, CLSID_DVDHWDecodersCategory) then
    result := 'CLSID_DVDHWDecodersCategory'
  else if IsEqualGUID(GUID, CLSID_DVDNavigator) then
    result := 'CLSID_DVDNavigator'
  else if IsEqualGUID(GUID, CLSID_DVDecPropertiesPage) then
    result := 'CLSID_DVDecPropertiesPage'
  else if IsEqualGUID(GUID, CLSID_DVEncPropertiesPage) then
    result := 'CLSID_DVEncPropertiesPage'
  else if IsEqualGUID(GUID, CLSID_DVMux) then
    result := 'CLSID_DVMux'
  else if IsEqualGUID(GUID, CLSID_DVMuxPropertyPage) then
    result := 'CLSID_DVMuxPropertyPage'
  else if IsEqualGUID(GUID, CLSID_DVSplitter) then
    result := 'CLSID_DVSplitter'
  else if IsEqualGUID(GUID, CLSID_DVVideoCodec) then
    result := 'CLSID_DVVideoCodec'
  else if IsEqualGUID(GUID, CLSID_DVVideoEnc) then
    result := 'CLSID_DVVideoEnc'
  else if IsEqualGUID(GUID, CLSID_DirectDraw) then
    result := 'CLSID_DirectDraw'
  else if IsEqualGUID(GUID, CLSID_DirectDrawClipper) then
    result := 'CLSID_DirectDrawClipper'
  else if IsEqualGUID(GUID, CLSID_DirectDrawProperties) then
    result := 'CLSID_DirectDrawProperties'
  else if IsEqualGUID(GUID, CLSID_Dither) then
    result := 'CLSID_Dither'
  else if IsEqualGUID(GUID, CLSID_DvdGraphBuilder) then
    result := 'CLSID_DvdGraphBuilder'
  else if IsEqualGUID(GUID, CLSID_FGControl) then
    result := 'CLSID_FGControl'
  else if IsEqualGUID(GUID, CLSID_FileSource) then
    result := 'CLSID_FileSource'
  else if IsEqualGUID(GUID, CLSID_FileWriter) then
    result := 'CLSID_FileWriter'
  else if IsEqualGUID(GUID, CLSID_FilterGraph) then
    result := 'CLSID_FilterGraph'
  else if IsEqualGUID(GUID, CLSID_FilterGraphNoThread) then
    result := 'CLSID_FilterGraphNoThread'
  else if IsEqualGUID(GUID, CLSID_FilterMapper) then
    result := 'CLSID_FilterMapper'
  else if IsEqualGUID(GUID, CLSID_FilterMapper2) then
    result := 'CLSID_FilterMapper2'
  else if IsEqualGUID(GUID, CLSID_InfTee) then
    result := 'CLSID_InfTee'
  else if IsEqualGUID(GUID, CLSID_LegacyAmFilterCategory) then
    result := 'CLSID_LegacyAmFilterCategory'
  else if IsEqualGUID(GUID, CLSID_Line21Decoder) then
    result := 'CLSID_Line21Decoder'
  else if IsEqualGUID(GUID, CLSID_MOVReader) then
    result := 'CLSID_MOVReader'
  else if IsEqualGUID(GUID, CLSID_MPEG1Doc) then
    result := 'CLSID_MPEG1Doc'
  else if IsEqualGUID(GUID, CLSID_MPEG1PacketPlayer) then
    result := 'CLSID_MPEG1PacketPlayer'
  else if IsEqualGUID(GUID, CLSID_MPEG1Splitter) then
    result := 'CLSID_MPEG1Splitter'
  else if IsEqualGUID(GUID, CLSID_MediaPropertyBag) then
    result := 'CLSID_MediaPropertyBag'
  else if IsEqualGUID(GUID, CLSID_MemoryAllocator) then
    result := 'CLSID_MemoryAllocator'
  else if IsEqualGUID(GUID, CLSID_MidiRendererCategory) then
    result := 'CLSID_MidiRendererCategory'
  else if IsEqualGUID(GUID, CLSID_ModexProperties) then
    result := 'CLSID_ModexProperties'
  else if IsEqualGUID(GUID, CLSID_ModexRenderer) then
    result := 'CLSID_ModexRenderer'
  else if IsEqualGUID(GUID, CLSID_OverlayMixer) then
    result := 'CLSID_OverlayMixer'
  else if IsEqualGUID(GUID, CLSID_PerformanceProperties) then
    result := 'CLSID_PerformanceProperties'
  else if IsEqualGUID(GUID, CLSID_PersistMonikerPID) then
    result := 'CLSID_PersistMonikerPID'
  else if IsEqualGUID(GUID, CLSID_ProtoFilterGraph) then
    result := 'CLSID_ProtoFilterGraph'
  else if IsEqualGUID(GUID, CLSID_QualityProperties) then
    result := 'CLSID_QualityProperties'
  else if IsEqualGUID(GUID, CLSID_SeekingPassThru) then
    result := 'CLSID_SeekingPassThru'
  else if IsEqualGUID(GUID, CLSID_SmartTee) then
    result := 'CLSID_SmartTee'
  else if IsEqualGUID(GUID, CLSID_SystemClock) then
    result := 'CLSID_SystemClock'
  else if IsEqualGUID(GUID, CLSID_SystemDeviceEnum) then
    result := 'CLSID_SystemDeviceEnum'
  else if IsEqualGUID(GUID, CLSID_TVAudioFilterPropertyPage) then
    result := 'CLSID_TVAudioFilterPropertyPage'
  else if IsEqualGUID(GUID, CLSID_TVTunerFilterPropertyPage) then
    result := 'CLSID_TVTunerFilterPropertyPage'
  else if IsEqualGUID(GUID, CLSID_TextRender) then
    result := 'CLSID_TextRender'
  else if IsEqualGUID(GUID, CLSID_URLReader) then
    result := 'CLSID_URLReader'
  else if IsEqualGUID(GUID, CLSID_VBISurfaces) then
    result := 'CLSID_VBISurfaces'
  else if IsEqualGUID(GUID, CLSID_VPObject) then
    result := 'CLSID_VPObject'
  else if IsEqualGUID(GUID, CLSID_VPVBIObject) then
    result := 'CLSID_VPVBIObject'
  else if IsEqualGUID(GUID, CLSID_VfwCapture) then
    result := 'CLSID_VfwCapture'
  else if IsEqualGUID(GUID, CLSID_VideoCompressorCategory) then
    result := 'CLSID_VideoCompressorCategory'
  else if IsEqualGUID(GUID, CLSID_VideoInputDeviceCategory) then
    result := 'CLSID_VideoInputDeviceCategory'
  else if IsEqualGUID(GUID, CLSID_VideoProcAmpPropertyPage) then
    result := 'CLSID_VideoProcAmpPropertyPage'
  else if IsEqualGUID(GUID, CLSID_VideoRenderer) then
    result := 'CLSID_VideoRenderer'
  else if IsEqualGUID(GUID, CLSID_VideoStreamConfigPropertyPage) then
    result := 'CLSID_VideoStreamConfigPropertyPage'

  else if IsEqualGUID(GUID, CLSID_WMMUTEX_Language) then
    result := 'CLSID_WMMUTEX_Language'
  else if IsEqualGUID(GUID, CLSID_WMMUTEX_Bitrate) then
    result := 'CLSID_WMMUTEX_Bitrate'
  else if IsEqualGUID(GUID, CLSID_WMMUTEX_Presentation) then
    result := 'CLSID_WMMUTEX_Presentation'
  else if IsEqualGUID(GUID, CLSID_WMMUTEX_Unknown) then
    result := 'CLSID_WMMUTEX_Unknown'

  else if IsEqualGUID(GUID, CLSID_WMBandwidthSharing_Exclusive) then
    result := 'CLSID_WMBandwidthSharing_Exclusive'
  else if IsEqualGUID(GUID, CLSID_WMBandwidthSharing_Partial) then
    result := 'CLSID_WMBandwidthSharing_Partial'

  else if IsEqualGUID(GUID, FORMAT_AnalogVideo) then
    result := 'FORMAT_AnalogVideo'
  else if IsEqualGUID(GUID, FORMAT_DVD_LPCMAudio) then
    result := 'FORMAT_DVD_LPCMAudio'
  else if IsEqualGUID(GUID, FORMAT_DolbyAC3) then
    result := 'FORMAT_DolbyAC3'
  else if IsEqualGUID(GUID, FORMAT_DvInfo) then
    result := 'FORMAT_DvInfo'
  else if IsEqualGUID(GUID, FORMAT_MPEG2Audio) then
    result := 'FORMAT_MPEG2Audio'
  else if IsEqualGUID(GUID, FORMAT_MPEG2Video) then
    result := 'FORMAT_MPEG2Video'
  else if IsEqualGUID(GUID, FORMAT_MPEG2_VIDEO) then
    result := 'FORMAT_MPEG2_VIDEO'
  else if IsEqualGUID(GUID, FORMAT_MPEGStreams) then
    result := 'FORMAT_MPEGStreams'
  else if IsEqualGUID(GUID, FORMAT_MPEGVideo) then
    result := 'FORMAT_MPEGVideo'
  else if IsEqualGUID(GUID, FORMAT_None) then
    result := 'FORMAT_None'
  else if IsEqualGUID(GUID, FORMAT_VideoInfo2) then
    result := 'FORMAT_VIDEOINFO2'
  else if IsEqualGUID(GUID, FORMAT_VideoInfo) then
    result := 'FORMAT_VideoInfo'
  else if IsEqualGUID(GUID, FORMAT_VideoInfo2) then
    result := 'FORMAT_VideoInfo2'
  else if IsEqualGUID(GUID, FORMAT_WaveFormatEx) then
    result := 'FORMAT_WaveFormatEx'

  else if IsEqualGUID(GUID, TIME_FORMAT_BYTE) then
    result := 'TIME_FORMAT_BYTE'
  else if IsEqualGUID(GUID, TIME_FORMAT_FIELD) then
    result := 'TIME_FORMAT_FIELD'
  else if IsEqualGUID(GUID, TIME_FORMAT_FRAME) then
    result := 'TIME_FORMAT_FRAME'
  else if IsEqualGUID(GUID, TIME_FORMAT_MEDIA_TIME) then
    result := 'TIME_FORMAT_MEDIA_TIME'
  else if IsEqualGUID(GUID, TIME_FORMAT_SAMPLE) then
    result := 'TIME_FORMAT_SAMPLE'

  else if IsEqualGUID(GUID, AMPROPSETID_Pin) then
    result := 'AMPROPSETID_Pin'
  else if IsEqualGUID(GUID, AM_INTERFACESETID_Standard) then
    result := 'AM_INTERFACESETID_Standard'
  else if IsEqualGUID(GUID, AM_KSCATEGORY_AUDIO) then
    result := 'AM_KSCATEGORY_AUDIO'
  else if IsEqualGUID(GUID, AM_KSCATEGORY_CAPTURE) then
    result := 'AM_KSCATEGORY_CAPTURE'
  else if IsEqualGUID(GUID, AM_KSCATEGORY_CROSSBAR) then
    result := 'AM_KSCATEGORY_CROSSBAR'
  else if IsEqualGUID(GUID, AM_KSCATEGORY_DATACOMPRESSOR) then
    result := 'AM_KSCATEGORY_DATACOMPRESSOR'
  else if IsEqualGUID(GUID, AM_KSCATEGORY_RENDER) then
    result := 'AM_KSCATEGORY_RENDER'
  else if IsEqualGUID(GUID, AM_KSCATEGORY_TVAUDIO) then
    result := 'AM_KSCATEGORY_TVAUDIO'
  else if IsEqualGUID(GUID, AM_KSCATEGORY_TVTUNER) then
    result := 'AM_KSCATEGORY_TVTUNER'
  else if IsEqualGUID(GUID, AM_KSCATEGORY_VIDEO) then
    result := 'AM_KSCATEGORY_VIDEO'
  else if IsEqualGUID(GUID, AM_KSPROPSETID_AC3) then
    result := 'AM_KSPROPSETID_AC3'
  else if IsEqualGUID(GUID, AM_KSPROPSETID_CopyProt) then
    result := 'AM_KSPROPSETID_CopyProt'
  else if IsEqualGUID(GUID, AM_KSPROPSETID_DvdSubPic) then
    result := 'AM_KSPROPSETID_DvdSubPic'
  else if IsEqualGUID(GUID, AM_KSPROPSETID_TSRateChange) then
    result := 'AM_KSPROPSETID_TSRateChange'

  else if IsEqualGUID(GUID, IID_IAMDirectSound) then
    result := 'IID_IAMDirectSound'
  else if IsEqualGUID(GUID, IID_IAMLine21Decoder) then
    result := 'IID_IAMLine21Decoder'
  else if IsEqualGUID(GUID, IID_IBaseVideoMixer) then
    result := 'IID_IBaseVideoMixer'
  else if IsEqualGUID(GUID, IID_IDDVideoPortContainer) then
    result := 'IID_IDDVideoPortContainer'
  else if IsEqualGUID(GUID, IID_IDirectDraw) then
    result := 'IID_IDirectDraw'
  else if IsEqualGUID(GUID, IID_IDirectDraw2) then
    result := 'IID_IDirectDraw2'
  else if IsEqualGUID(GUID, IID_IDirectDrawClipper) then
    result := 'IID_IDirectDrawClipper'
  else if IsEqualGUID(GUID, IID_IDirectDrawColorControl) then
    result := 'IID_IDirectDrawColorControl'
  else if IsEqualGUID(GUID, IID_IDirectDrawKernel) then
    result := 'IID_IDirectDrawKernel'
  else if IsEqualGUID(GUID, IID_IDirectDrawPalette) then
    result := 'IID_IDirectDrawPalette'
  else if IsEqualGUID(GUID, IID_IDirectDrawSurface) then
    result := 'IID_IDirectDrawSurface'
  else if IsEqualGUID(GUID, IID_IDirectDrawSurface2) then
    result := 'IID_IDirectDrawSurface2'
  else if IsEqualGUID(GUID, IID_IDirectDrawSurface3) then
    result := 'IID_IDirectDrawSurface3'
  else if IsEqualGUID(GUID, IID_IDirectDrawSurfaceKernel) then
    result := 'IID_IDirectDrawSurfaceKernel'
  else if IsEqualGUID(GUID, IID_IDirectDrawVideo) then
    result := 'IID_IDirectDrawVideo'
  else if IsEqualGUID(GUID, IID_IFullScreenVideo) then
    result := 'IID_IFullScreenVideo'
  else if IsEqualGUID(GUID, IID_IFullScreenVideoEx) then
    result := 'IID_IFullScreenVideoEx'
  else if IsEqualGUID(GUID, IID_IKsDataTypeHandler) then
    result := 'IID_IKsDataTypeHandler'
  else if IsEqualGUID(GUID, IID_IKsInterfaceHandler) then
    result := 'IID_IKsInterfaceHandler'
  else if IsEqualGUID(GUID, IID_IKsPin) then
    result := 'IID_IKsPin'
  else if IsEqualGUID(GUID, IID_IMixerPinConfig) then
    result := 'IID_IMixerPinConfig'
  else if IsEqualGUID(GUID, IID_IMixerPinConfig2) then
    result := 'IID_IMixerPinConfig2'
  else if IsEqualGUID(GUID, IID_IMpegAudioDecoder) then
    result := 'IID_IMpegAudioDecoder'
  else if IsEqualGUID(GUID, IID_IQualProp) then
    result := 'IID_IQualProp'
  else if IsEqualGUID(GUID, IID_IVPConfig) then
    result := 'IID_IVPConfig'
  else if IsEqualGUID(GUID, IID_IVPControl) then
    result := 'IID_IVPControl'
  else if IsEqualGUID(GUID, IID_IVPNotify) then
    result := 'IID_IVPNotify'
  else if IsEqualGUID(GUID, IID_IVPNotify2) then
    result := 'IID_IVPNotify2'
  else if IsEqualGUID(GUID, IID_IVPObject) then
    result := 'IID_IVPObject'
  else if IsEqualGUID(GUID, IID_IVPVBIConfig) then
    result := 'IID_IVPVBIConfig'
  else if IsEqualGUID(GUID, IID_IVPVBINotify) then
    result := 'IID_IVPVBINotify'
  else if IsEqualGUID(GUID, IID_IVPVBIObject) then
    result := 'IID_IVPVBIObject'

  else if IsEqualGUID(GUID, LOOK_DOWNSTREAM_ONLY) then
    result := 'LOOK_DOWNSTREAM_ONLY'
  else if IsEqualGUID(GUID, LOOK_UPSTREAM_ONLY) then
    result := 'LOOK_UPSTREAM_ONLY'
  else
    result := '';
end;
// milenko end

// milenko start (usefull functions to get linear amplification)
// improved by XXX
function GetBasicAudioVolume(Value: integer): integer;
begin
  inc(Value, 10000);
  result := Round(Exp(Value / 1085.73) - 1);
end;

function SetBasicAudioVolume(Value: integer): integer;
begin
  inc(Value);
  result := Round(1085.73 * ln(Value)) - 10000;
end;

function GetBasicAudioPan(Value: integer): integer;
begin
  result := Round(Exp(abs(Value) / 1085.73) - 1);
  if Value <= 0 then
    result := -result;
end;

function SetBasicAudioPan(Value: integer): integer;
begin
  result := Round(1085.73 * ln(abs(Value) + 1));
  if Value >= 0 then
    result := -result;
end;
// milenko end

// milenok start (yet another delphi5 compatibility ...)
{$IFDEF VER130}

function StringToGUID(const S: string): TGUID;
begin
  if not Succeeded(CLSIDFromString(PWideChar(WideString(S)), result)) then
    raise Exception.Create('StringToGUID: Error converting String');
end;

function GUIDToString(const GUID: TGUID): string;
var
  p: PWideChar;
begin
  if not Succeeded(StringFromCLSID(GUID, p)) then
    raise Exception.Create('GUIDToString: Error converting GUID');
  result := p;
  CoTaskMemFree(p);
end;

function EnsureRange(const AValue, AMin, AMax: integer): integer;
begin
  result := AValue;
  ASSERT(AMin <= AMax);
  if result < AMin then
    result := AMin;
  if result > AMax then
    result := AMax;
end;
{$ENDIF}
// milenko end

const
  SectionLengthMask          = $FFF;  // 0000111111111111
  ReservedMask               = $3000; // 0011000000000000
  PrivateIndicatorMask       = $4000; // 0100000000000000
  SectionSyntaxIndicatorMask = $8000; // 1000000000000000

function MPEGHeaderBitsGetSectionLength(Header: PMPEGHeaderBits): WORD;
begin
  result := Header.bits and SectionLengthMask;
end;

function MPEGHeaderBitsGetReserved(Header: PMPEGHeaderBits): WORD;
begin
  result := (Header.bits and ReservedMask) shr 12;
end;

function MPEGHeaderBitsGetPrivateIndicator(Header: PMPEGHeaderBits): WORD;
begin
  result := (Header.bits and PrivateIndicatorMask) shr 14;
end;

function MPEGHeaderBitsGetSectionSyntaxIndicator(Header: PMPEGHeaderBits): WORD;
begin
  result := (Header.bits and SectionSyntaxIndicatorMask) shr 15;
end;

procedure MPEGHeaderBitsSetSectionLength(Header: PMPEGHeaderBits; AValue: WORD);
begin
  Header.bits := Header.bits or (AValue and SectionLengthMask);
end;

procedure MPEGHeaderBitsSetReserved(Header: PMPEGHeaderBits; AValue: WORD);
begin
  Header.bits := Header.bits or ((AValue shl 12) and ReservedMask);
end;

procedure MPEGHeaderBitsSetPrivateIndicator(Header: PMPEGHeaderBits; AValue: WORD);
begin
  Header.bits := Header.bits or ((AValue shl 14) and PrivateIndicatorMask);
end;

procedure MPEGHeaderBitsSetSectionSyntaxIndicator(Header: PMPEGHeaderBits; AValue: WORD);
begin
  Header.bits := Header.bits or ((AValue shl 15) and SectionSyntaxIndicatorMask);
end;

const
  PIDBitsReservedMask = $7;    // 0000000000000111
  PIDBitsProgramId    = $FFF8; // 1111111111111000

function PIDBitsGetReserved(PIDBits: PPIDBits): WORD;
begin
  result := PIDBits.bits and PIDBitsReservedMask;
end;

function PIDBitsGetProgramId(PIDBits: PPIDBits): WORD;
begin
  result := (PIDBits.bits and PIDBitsProgramId) shr 3;
end;

procedure PIDBitsSetReserved(PIDBits: PPIDBits; AValue: WORD);
begin
  PIDBits.bits := PIDBits.bits or (AValue and PIDBitsReservedMask);
end;

procedure PIDBitsSetProgramId(PIDBits: PPIDBits; AValue: WORD);
begin
  PIDBits.bits := PIDBits.bits or ((AValue shl 3) and PIDBitsProgramId);
end;

const
  MHBCurrentNextIndicator = $1;  // 00000001
  MHBVersionNumber        = $3E; // 00111110
  MHBReserved             = $C0; // 11000000

function MPEGHeaderVersionBitsGetCurrentNextIndicator(MPEGHeaderVersionBits: PMPEGHeaderVersionBits): byte;
begin
  result := MPEGHeaderVersionBits.bits and MHBCurrentNextIndicator;
end;

function MPEGHeaderVersionBitsGetVersionNumber(MPEGHeaderVersionBits: PMPEGHeaderVersionBits): byte;
begin
  result := (MPEGHeaderVersionBits.bits and MHBVersionNumber) shr 1;
end;

function MPEGHeaderVersionBitsGetReserved(MPEGHeaderVersionBits: PMPEGHeaderVersionBits): byte;
begin
  result := (MPEGHeaderVersionBits.bits and MHBReserved) shr 6;
end;

procedure MPEGHeaderVersionBitsSetCurrentNextIndicator(MPEGHeaderVersionBits: PMPEGHeaderVersionBits; AValue: byte);
begin
  MPEGHeaderVersionBits.bits := MPEGHeaderVersionBits.bits or (AValue and MHBCurrentNextIndicator);
end;

procedure MPEGHeaderVersionBitsSetVersionNumber(MPEGHeaderVersionBits: PMPEGHeaderVersionBits; AValue: byte);
begin
  MPEGHeaderVersionBits.bits := MPEGHeaderVersionBits.bits or ((AValue shl 1) and MHBVersionNumber);
end;

procedure MPEGHeaderVersionBitsSetReserved(MPEGHeaderVersionBits: PMPEGHeaderVersionBits; AValue: byte);
begin
  MPEGHeaderVersionBits.bits := MPEGHeaderVersionBits.bits or ((AValue shl 6) and MHBReserved);
end;

end.
