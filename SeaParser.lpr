program SeaParser;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  SeaFonts,   // embedded fonts, must be before Interfaces (registered before GTK starts)
  Interfaces, // this includes the LCL widgetset
  Forms, Main
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;
  RegisterAppFonts;   // embedded Inter for csscontrols, before forms are created
  Application.CreateForm(TSeaParserForm, SeaParserForm);
  Application.Run;
end.

