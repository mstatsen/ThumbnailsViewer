unit uThumbnailExtractor;

interface

uses
  Vcl.Imaging.jpeg, Vcl.Imaging.pngimage, Vcl.Graphics, System.SysUtils,
  System.Classes, System.Types;

type
  TThumbnailExtractor = class
  public
    procedure DrawTumbnailOnBitmap(AFileName: string; ABitmap: TBitmap);
  end;

const
  THUMBNAIL_WIDTH = 86;
  THUMBNAIL_HEIGHT = 86;

implementation

type
  TGraphicFileDrawer = class abstract
  strict private
    procedure DrawGraphicOnBitmap(AGraphic: TGraphic; ABitmap: TBitmap);
    function GetCalcedThumbnailRect(AGraphic: TGraphic): TRect;
  protected
    function GetGraphicFromFile(AFileName: string): TGraphic; virtual; abstract;
  public
    procedure Draw(AFileName: string; ABitmap: TBitmap);
  end;

  TGraphicFileDrawerClass = class of TGraphicFileDrawer;

  TGraphicFileDrawerFactory = class
  strict private
    class var FRegisteredFileDrawers: TStringList;
    class function GetRegisteredFileDrawers: TStringList; static;
  private
    class procedure DestroyRegisteredFileDrawers;
    class procedure RegisterFileDrawer(AFileExtension: string; ADrawerClass: TGraphicFileDrawerClass);
    class property RegisteredFileDrawers: TStringList read GetRegisteredFileDrawers;
  public
    class function GetDrawer(AFileName: string): TGraphicFileDrawer;
  end;

  TBMPFileDrawer = class(TGraphicFileDrawer)
  protected
    function GetGraphicFromFile(AFileName: string): TGraphic; override;
  end;

  TJPGFileDrawer = class(TGraphicFileDrawer)
  protected
    function GetGraphicFromFile(AFileName: string): TGraphic; override;
  end;

  TPNGFileDrawer = class(TGraphicFileDrawer)
  protected
    function GetGraphicFromFile(AFileName: string): TGraphic; override;
  end;

{ TThumbnailExtractor }

procedure TThumbnailExtractor.DrawTumbnailOnBitmap(AFileName: string; ABitmap: TBitmap);
var
  graphicFileDrawer: TGraphicFileDrawer;
begin
  graphicFileDrawer := TGraphicFileDrawerFactory.GetDrawer(AFileName);

  try
    ABitmap.Canvas.Lock;

    try
      graphicFileDrawer.Draw(AFileName, ABitmap);
    finally
      ABitmap.Canvas.Unlock;
    end;
  finally
    graphicFileDrawer.Free;
  end;
end;

{ TGraphicFileDrawer }

procedure TGraphicFileDrawer.Draw(AFileName: string; ABitmap: TBitmap);
var
  graphic: TGraphic;
begin
  ABitmap.SetSize(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT);
  graphic := GetGraphicFromFile(AFileName);

  try
    DrawGraphicOnBitmap(graphic, ABitmap);
  finally
    graphic.Free;
  end;
end;

procedure TGraphicFileDrawer.DrawGraphicOnBitmap(AGraphic: TGraphic;
  ABitmap: TBitmap);
begin
  ABitmap.Canvas.StretchDraw(GetCalcedThumbnailRect(AGraphic), AGraphic);
end;

function TGraphicFileDrawer.GetCalcedThumbnailRect(AGraphic: TGraphic): TRect;
var
  ratio, ratioX, ratioY: double;
  calcedWidth, calcedHeight: integer;
begin
  if (AGraphic.Width < THUMBNAIL_WIDTH) and
     (AGraphic.Height < THUMBNAIL_HEIGHT) then
    ratio := 1
  else
  begin
    ratioX := AGraphic.Width / THUMBNAIL_WIDTH;
    ratioY := AGraphic.Height / THUMBNAIL_HEIGHT;

    if ratioX > ratioY then
      ratio := ratioX
    else ratio := ratioY;
  end;

  calcedWidth := Trunc(AGraphic.Width/ratio);
  calcedHeight := Trunc(AGraphic.Height/ratio);

  Result.Left := Trunc((THUMBNAIL_WIDTH - calcedWidth) / 2);
  Result.Top := Trunc((THUMBNAIL_HEIGHT - calcedHeight) / 2);
  Result.Width := calcedWidth;
  Result.Height := calcedHeight;
end;

{ TGraphicFileDrawerFactory }

class function TGraphicFileDrawerFactory.GetDrawer(
  AFileName: string): TGraphicFileDrawer;
var
  fileExt: string;
  drawerIndex: integer;
  graphicFileDrawerClass: TGraphicFileDrawerClass;
begin
  fileExt := UpperCase(ExtractFileExt(AFileName));
  drawerIndex := RegisteredFileDrawers.IndexOf(fileExt);

  if drawerIndex = -1 then
    Exit(nil);

  graphicFileDrawerClass := TGraphicFileDrawerClass(RegisteredFileDrawers.Objects[drawerIndex]);
  Result := graphicFileDrawerClass.Create;
end;

class function TGraphicFileDrawerFactory.GetRegisteredFileDrawers: TStringList;
begin
  if FRegisteredFileDrawers = nil then
    FRegisteredFileDrawers := TStringList.Create;

  Result := FRegisteredFileDrawers;
end;

class procedure TGraphicFileDrawerFactory.DestroyRegisteredFileDrawers;
begin
  RegisteredFileDrawers.Free;
end;

class procedure TGraphicFileDrawerFactory.RegisterFileDrawer(AFileExtension: string;
  ADrawerClass: TGraphicFileDrawerClass);
begin
  RegisteredFileDrawers.AddObject(AFileExtension, TObject(ADrawerClass));
end;

{ TBMPFileDrawer }

function TBMPFileDrawer.GetGraphicFromFile(AFileName: string): TGraphic;
begin
  inherited;

  Result := TBitmap.Create;
  Result.SetSize(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT);
  Result.LoadFromFile(AFileName);
end;

{ TJPGFileDrawer }

function TJPGFileDrawer.GetGraphicFromFile(AFileName: string): TGraphic;
begin
  inherited;

  Result := TJPEGImage.Create;
  TJPEGImage(Result).Performance := jpBestSpeed;
  Result.LoadFromFile(AFileName);
end;

{ TPNGFileDrawer }

function TPNGFileDrawer.GetGraphicFromFile(AFileName: string): TGraphic;
begin
  inherited;
  Result := TPNGImage.Create;
  Result.LoadFromFile(AFileName);
end;

initialization
  TGraphicFileDrawerFactory.RegisterFileDrawer('.BMP', TBMPFileDrawer);
  TGraphicFileDrawerFactory.RegisterFileDrawer('.JPG', TJPGFileDrawer);
  TGraphicFileDrawerFactory.RegisterFileDrawer('.JPEG', TJPGFileDrawer);
  TGraphicFileDrawerFactory.RegisterFileDrawer('.PNG', TPNGFileDrawer);

finalization
  TGraphicFileDrawerFactory.DestroyRegisteredFileDrawers;

end.
