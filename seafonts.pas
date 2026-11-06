unit SeaFonts;

{ Fonts embedded into the executable (seafonts.res, RCDATA) and registered for this process only.
  Nothing is installed into the system.

  Windows / ReactOS : AddFontResourceExW(FR_PRIVATE)  -> AddFontMemResourceEx -> AddFontResourceW
  Linux / BSD       : fontconfig FcConfigAppFontAddFile (used by GTK2/GTK3/Qt through Pango/fontconfig)

  Put SeaFonts in the uses of the .lpr BEFORE Interfaces, and call RegisterAppFonts after
  Application.Initialize. If registration fails, the program still works: CSS falls back to the next
  family in font-family. }

{$mode objfpc}{$H+}

interface

const
  SEA_FONT = 'Inter';     // family name inside the .ttf files (name ID 1)

function RegisterAppFonts: Boolean;   // after Application.Initialize; True when the embedded font can be used

implementation

{$R seafonts.res}

uses
  Classes, SysUtils, Forms, LCLType
  {$ifdef windows}, Windows{$endif}
  {$ifdef unix}, dynlibs{$endif};

const
  FONT_RESOURCES: array[0..1] of String = ('FONT_REGULAR', 'FONT_BOLD');
  FONT_FILES: array[0..1] of String = ('Inter-Regular.ttf', 'Inter-Bold.ttf');

var
  Registered: Boolean = False;
  {$ifdef windows}
  FontFiles: array[0..1] of WideString;
  FontFileFlags: array[0..1] of DWORD;        // flags used to register (for removal), $FFFFFFFF = not registered
  MemFonts: array[0..1] of THandle;
  {$endif}

function FileSizeOf(const AFileName: String): Int64;
var
  SR: TSearchRec;
begin
  Result := -1;
  if FindFirst(AFileName, faAnyFile, SR) = 0 then begin
    Result := SR.Size;
    SysUtils.FindClose(SR);
  end;
end;

{ Save font from resources into the per-user application folder (not overwritten when it's the same) }
function ExtractFont(AIndex: Integer; out AFileName: String; out AStream: TResourceStream): Boolean;
var
  Dir: String;
  F: TFileStream;
begin
  Result := False;
  AStream := nil;
  AFileName := '';
  try
    AStream := TResourceStream.Create(HInstance, FONT_RESOURCES[AIndex], RT_RCDATA);
    Dir := IncludeTrailingPathDelimiter(GetAppConfigDir(False)) + 'fonts';
    ForceDirectories(Dir);
    AFileName := IncludeTrailingPathDelimiter(Dir) + FONT_FILES[AIndex];
    if FileSizeOf(AFileName) <> AStream.Size then begin
      F := TFileStream.Create(AFileName, fmCreate);
      try
        AStream.Position := 0;
        F.CopyFrom(AStream, AStream.Size);
      finally
        F.Free;
      end;
    end;
    Result := True;
  except
    AFileName := '';      // no writable folder: Windows can still use the font from memory
    Result := Assigned(AStream);
  end;
end;

{$ifdef windows}
type
  TAddFontResourceExW = function(Name: PWideChar; Flags: DWORD; Res: Pointer): Integer; stdcall;
  TRemoveFontResourceExW = function(Name: PWideChar; Flags: DWORD; Res: Pointer): BOOL; stdcall;
  TAddFontMemResourceEx = function(Data: Pointer; Size: DWORD; Res: Pointer; NumFonts: PDWORD): THandle; stdcall;
  TRemoveFontMemResourceEx = function(H: THandle): BOOL; stdcall;

const
  FR_PRIVATE = $10;

var
  Gdi: HMODULE;
  pAddFontResourceExW: TAddFontResourceExW;
  pRemoveFontResourceExW: TRemoveFontResourceExW;
  pAddFontMemResourceEx: TAddFontMemResourceEx;
  pRemoveFontMemResourceEx: TRemoveFontMemResourceEx;

{ Functions are loaded dynamically, so the program starts even when an old Windows / ReactOS build lacks one }
procedure LoadGdi;
begin
  Gdi := GetModuleHandle('gdi32.dll');
  Pointer(pAddFontResourceExW) := GetProcAddress(Gdi, 'AddFontResourceExW');
  Pointer(pRemoveFontResourceExW) := GetProcAddress(Gdi, 'RemoveFontResourceExW');
  Pointer(pAddFontMemResourceEx) := GetProcAddress(Gdi, 'AddFontMemResourceEx');
  Pointer(pRemoveFontMemResourceEx) := GetProcAddress(Gdi, 'RemoveFontMemResourceEx');
end;

function RegisterOne(AIndex: Integer): Boolean;
var
  FileName: String;
  Res: TResourceStream;
  N: DWORD;
begin
  Result := False;
  FontFileFlags[AIndex] := $FFFFFFFF;
  MemFonts[AIndex] := 0;
  if not ExtractFont(AIndex, FileName, Res) then Exit;
  try
    FontFiles[AIndex] := UTF8Decode(FileName);
    // 1. private font from file: only this process sees it, and it is listed in Screen.Fonts
    if (FileName <> '') and Assigned(pAddFontResourceExW) and
      (pAddFontResourceExW(PWideChar(FontFiles[AIndex]), FR_PRIVATE, nil) > 0) then begin
      FontFileFlags[AIndex] := FR_PRIVATE;
      Exit(True);
    end;
    // 2. private font from memory (not listed by font enumeration, Screen.Fonts is fixed below)
    if Assigned(pAddFontMemResourceEx) then begin
      N := 0;
      MemFonts[AIndex] := pAddFontMemResourceEx(Res.Memory, Res.Size, nil, @N);
      if MemFonts[AIndex] <> 0 then Exit(True);
    end;
    // 3. old fallback: font for the session, removed again when the program ends
    if (FileName <> '') and (AddFontResourceW(PWideChar(FontFiles[AIndex])) > 0) then begin
      FontFileFlags[AIndex] := 0;
      Exit(True);
    end;
  finally
    Res.Free;
  end;
end;

procedure UnregisterAll;
var
  I: Integer;
begin
  for I := 0 to High(FONT_FILES) do begin
    if MemFonts[I] <> 0 then begin
      if Assigned(pRemoveFontMemResourceEx) then pRemoveFontMemResourceEx(MemFonts[I]);
    end else if FontFileFlags[I] = FR_PRIVATE then begin
      if Assigned(pRemoveFontResourceExW) then pRemoveFontResourceExW(PWideChar(FontFiles[I]), FR_PRIVATE, nil);
    end else if FontFileFlags[I] = 0 then
      RemoveFontResourceW(PWideChar(FontFiles[I]));
  end;
end;
{$endif}

{$ifdef unix}
type
  TFcConfigAppFontAddFile = function(Config: Pointer; FileName: PChar): LongBool; cdecl;

function RegisterOne(AIndex: Integer): Boolean;
var
  Lib: TLibHandle;
  AddFile: TFcConfigAppFontAddFile;
  FileName: String;
  Res: TResourceStream;
begin
  Result := False;
  if not ExtractFont(AIndex, FileName, Res) then Exit;
  Res.Free;
  if FileName = '' then Exit;            // fontconfig needs a file
  Lib := LoadLibrary('libfontconfig.so.1');
  if Lib = NilHandle then Lib := LoadLibrary('libfontconfig.so');
  if Lib = NilHandle then Exit;
  Pointer(AddFile) := GetProcAddress(Lib, 'FcConfigAppFontAddFile');
  // nil = current configuration, which is used by Pango (GTK) and Qt
  Result := Assigned(AddFile) and AddFile(nil, PChar(FileName));
end;
{$endif}

{ Registers the font files. Runs in the initialization of this unit, so on Linux the fonts are added to
  fontconfig before GTK/Pango starts and builds its font list (SeaFonts must be before Interfaces in the .lpr). }
procedure RegisterFontFiles;
var
  I: Integer;
begin
  {$ifdef windows}
  LoadGdi;
  {$endif}
  for I := 0 to High(FONT_FILES) do
    if RegisterOne(I) then Registered := True;
end;

function RegisterAppFonts: Boolean;
begin
  Result := Registered;
  // csscontrols takes only fonts from Screen.Fonts. Fonts from memory (AddFontMemResourceEx) are not
  // enumerated by the system, so the name is added when it is missing.
  if Result and (Screen.Fonts.IndexOf(SEA_FONT) < 0) then Screen.Fonts.Add(SEA_FONT);
end;

initialization
  RegisterFontFiles;

{$ifdef windows}
finalization
  if Registered then UnregisterAll;
{$endif}

end.
