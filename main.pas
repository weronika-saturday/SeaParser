unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  cssbase, csshtml, CSSCtrls, SeaUI, SeaFonts;

type

  { TSeaParserForm }

  TSeaParserForm = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    FShape: TCSSShape;
    FSheet: TCSSStyleSheet;
    MapFileEdit: TEdit;
    AssetsListEdit: TEdit;
    FModels: Boolean;                    // True: models, False: textures
    function MakeEdit(const AId, AHint: string): TEdit;
    function Node(const AId: string): THtmlNode;
    procedure SetMode(AModels: Boolean);
    procedure SetStatus(const AText: string; AOk: Boolean; AProgress: Integer = -1);
    procedure Restyle;
    procedure ModelsClick(Sender: TObject);
    procedure TexturesClick(Sender: TObject);
    procedure MapFileOpenButtonClick(Sender: TObject);
    procedure AssetsListSaveButtonClick(Sender: TObject);
    procedure ParsingButtonClick(Sender: TObject);
    function IsToolTexture(const ATexturePath: string): Boolean;
  public
  end;

var
  SeaParserForm: TSeaParserForm;

implementation

{$R *.lfm}

{ TSeaParserForm }

procedure TSeaParserForm.FormCreate(Sender: TObject);
begin
  Color := SEA_BG_COLOR;

  FSheet := TCSSStyleSheet.Create(Self);
  FSheet.Style := SEA_CSS;

  FShape := TCSSShape.Create(Self);
  FShape.Parent := Self;
  FShape.Align := alClient;
  FShape.Body.StyleSheet := FSheet;
  FShape.Body.AppendHTML(SEA_HTML);

  // native inputs placed into the CSS layout
  MapFileEdit := MakeEdit('mapEdit', 'Select a .vmf file...');
  AssetsListEdit := MakeEdit('listEdit', 'Where to save the .txt list...');

  // events of painted nodes
  Node('openBtn').OnClick := @MapFileOpenButtonClick;
  Node('saveBtn').OnClick := @AssetsListSaveButtonClick;
  Node('optModels').OnClick := @ModelsClick;
  Node('optTextures').OnClick := @TexturesClick;
  Node('parseBtn').OnClick := @ParsingButtonClick;

  FModels := True;
  Restyle;
end;

function TSeaParserForm.MakeEdit(const AId, AHint: string): TEdit;
var
  N: THtmlNode;
begin
  Result := TEdit.Create(Self);
  Result.Parent := Self;
  Result.BorderStyle := bsNone;          // the rounded inset frame is painted by CSS
  Result.Color := SEA_BG_COLOR;
  Result.Font.Color := $80736B;          // #6b7380
  if Screen.Fonts.IndexOf(SEA_FONT) >= 0 then Result.Font.Name := SEA_FONT;
  Result.Font.Size := 10;
  Result.TextHint := AHint;
  N := Node(AId);
  N.Text := '';
  N.SetAlignControl(Result);
end;

function TSeaParserForm.Node(const AId: string): THtmlNode;
begin
  Result := FShape.Body.GetElementById(AId);
end;

procedure TSeaParserForm.Restyle;
begin
  FShape.Body.ApplyStyles;
  FShape.Changed;
end;

procedure TSeaParserForm.SetMode(AModels: Boolean);
begin
  FModels := AModels;
  if AModels then begin
    Node('optModels').SetClass('choice checked');
    Node('optTextures').SetClass('choice');
  end else begin
    Node('optModels').SetClass('choice');
    Node('optTextures').SetClass('choice checked');
  end;
  Restyle;
end;

procedure TSeaParserForm.SetStatus(const AText: string; AOk: Boolean; AProgress: Integer);
begin
  Node('status').Text := AText;
  if AOk then Node('status').SetClass('status ok')
    else Node('status').SetClass('status err');
  if AProgress >= 0 then
    Node('bar').SetInline('width: ' + IntToStr(AProgress) + '%');
  Restyle;
  Application.ProcessMessages;
end;

procedure TSeaParserForm.ModelsClick(Sender: TObject);
begin
  SetMode(True);
end;

procedure TSeaParserForm.TexturesClick(Sender: TObject);
begin
  SetMode(False);
end;

function TSeaParserForm.IsToolTexture(const ATexturePath: string): Boolean;
var
  LowPath: string;
begin
  LowPath := LowerCase(ATexturePath);

  // Отсеиваем стандартные служебные папки и маски Source Engine
  Result := (Pos('tools/', LowPath) = 1) or
            (Pos('nodraw', LowPath) > 0) or
            (Pos('trigger', LowPath) > 0) or
            (Pos('skybox', LowPath) > 0) or
            (Pos('origin', LowPath) > 0) or
            (Pos('clip', LowPath) > 0) or
            (Pos('skip', LowPath) > 0) or
            (Pos('hint', LowPath) > 0) or
            (Pos('black', LowPath) > 0) or
            (Pos('invisible', LowPath) > 0);
end;

procedure TSeaParserForm.MapFileOpenButtonClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog := TOpenDialog.Create(Self);
  try
    OpenDialog.Filter := 'VMF files (*.vmf)|*.vmf|All files (*.*)|*.*';
    OpenDialog.Title := 'Select VMF';
    if OpenDialog.Execute then
      MapFileEdit.Text := OpenDialog.FileName;
  finally
    OpenDialog.Free;
  end;
end;

procedure TSeaParserForm.AssetsListSaveButtonClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Filter := 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
    SaveDialog.DefaultExt := 'txt';
    SaveDialog.Title := 'Select directoty for save text file';
    if SaveDialog.Execute then
      AssetsListEdit.Text := SaveDialog.FileName;
  finally
    SaveDialog.Free;
  end;
end;

procedure TSeaParserForm.ParsingButtonClick(Sender: TObject);
var
  VMFStrings, AssetStrings: TStringList;
  i, PosKey, PosQuote: Integer;
  Line, ExtractedPath: string;
begin
  // 1. Первичные проверки на заполненность полей
  if MapFileEdit.Text = '' then
  begin
    SetStatus('Select VMF file!', False, 0);
    Exit;
  end;

  if AssetsListEdit.Text = '' then
  begin
    SetStatus('Select directory for save result!', False, 0);
    Exit;
  end;

  if not FileExists(MapFileEdit.Text) then
  begin
    SetStatus('This VMF file does not exist!', False, 0);
    Exit;
  end;

  VMFStrings := TStringList.Create;
  AssetStrings := TStringList.Create;
  try
    // Автоматическое исключение дубликатов и сортировка по алфавиту
    AssetStrings.Sorted := True;
    AssetStrings.Duplicates := dupIgnore;

    SetStatus('Reading file...', True, 10);
    VMFStrings.LoadFromFile(MapFileEdit.Text);

    // 2. Построчный анализ VMF файла
    for i := 0 to VMFStrings.Count - 1 do
    begin
      Line := Trim(VMFStrings[i]);

      if FModels then
      begin
        // РЕЖИМ МОДЕЛЕЙ
        PosKey := Pos('"model"', Line);
        if (PosKey > 0) and (Pos('.mdl', LowerCase(Line)) > 0) then
        begin
          Delete(Line, 1, PosKey + 6);
          Line := Trim(Line);
          if (Length(Line) > 0) and (Line[1] = '"') then
            Delete(Line, 1, 1);
          PosQuote := Pos('"', Line);
          if PosQuote > 0 then ExtractedPath := Copy(Line, 1, PosQuote - 1)
          else ExtractedPath := Line;
          ExtractedPath := Trim(ExtractedPath);
          if ExtractedPath <> '' then
            AssetStrings.Add(ExtractedPath);
        end;
      end
      else
      begin
        // РЕЖИМ ТЕКСТУР: в VMF текстуры лежат в параметре "material"
        PosKey := Pos('"material"', Line);
        if PosKey > 0 then
        begin
          Delete(Line, 1, PosKey + 9);
          Line := Trim(Line);
          if (Length(Line) > 0) and (Line[1] = '"') then
            Delete(Line, 1, 1);
          PosQuote := Pos('"', Line);
          if PosQuote > 0 then ExtractedPath := Copy(Line, 1, PosQuote - 1)
          else ExtractedPath := Line;
          ExtractedPath := Trim(ExtractedPath);
          if (ExtractedPath <> '') and not IsToolTexture(ExtractedPath) then
            AssetStrings.Add(ExtractedPath);
        end;
      end;

      // прогресс-бар (обновляем не на каждой строке, чтобы не тормозить)
      if (i and $FFF) = 0 then
        SetStatus('Parsing...', True, 10 + (i * 85) div VMFStrings.Count);
    end;

    // 3. Сохраняем итоговый список в текстовый файл
    AssetStrings.SaveToFile(AssetsListEdit.Text);

    if FModels then
      SetStatus('Ready! Models found: ' + IntToStr(AssetStrings.Count), True, 100)
    else
      SetStatus('Ready! Textures found: ' + IntToStr(AssetStrings.Count), True, 100);
  finally
    VMFStrings.Free;
    AssetStrings.Free;
  end;
end;

end.
