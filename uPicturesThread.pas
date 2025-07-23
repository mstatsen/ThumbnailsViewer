unit uPicturesThread;

interface

uses
  Vcl.Graphics, System.Classes, System.SysUtils, uThumbnailExtractor,
  System.Contnrs, System.Generics.Collections;

type
  TFileData = class
  strict private
    FBitmap: TBitmap;
    FFileName: string;
  public
    constructor Create;
    procedure Clear;
    function IsValid: boolean;
    property Bitmap: TBitmap read FBitmap write FBitmap;
    property FileName: string read FFileName write FFileName;
  end;

  TAddListItem = procedure (ACaption: string; ABitmap: TBitmap) of object;

  TPicturesThread = class(TThread)
  strict private
    FCurrentFileData: TFileData;
    FOnAddListItem: TAddListItem;
    FPath: string;
    FPerformed: boolean;
    FThumbnailExtractor: TThumbnailExtractor;
    procedure FillFileList(AFileList: TStringList);
    function IsImageFile(AFileName: string): boolean;
    procedure AddListData;
    procedure ProcessFile(AFileName: string);
  protected
    procedure TerminatedSet; override;
    procedure Execute; override;
  public
    constructor Create(APath: string; AOnAddListItem: TAddListItem);
    destructor Destroy; override;
    procedure Terminate; reintroduce;
    property Performed: boolean read FPerformed;
  end;

  TPicturesThreads = class(TObjectList<TPicturesThread>)
  public
    procedure DeletePerformed;
    procedure StartNewThread(APath: string; AOnAddListItem: TAddListItem);
    procedure TerminateAll;
  end;

implementation

{ TPicturesThread }

procedure TPicturesThread.AddListData;
begin
  if not Terminated and
     FCurrentFileData.IsValid and
     Assigned(FOnAddListItem) then
    FOnAddListItem(
      ExtractFileName(FCurrentFileData.FileName),
      FCurrentFileData.Bitmap
    );
end;

constructor TPicturesThread.Create(APath: string;
  AOnAddListItem: TAddListItem);
begin
  inherited Create(True);
  FCurrentFileData := TFileData.Create;
  FThumbnailExtractor := TThumbnailExtractor.Create;
  FPerformed := false;
  FPath := APath;
  FOnAddListItem := AOnAddListItem;
end;

destructor TPicturesThread.Destroy;
begin
  FCurrentFileData.Free;
  FThumbnailExtractor.Free;
  inherited;
end;

procedure TPicturesThread.Execute;
var
  imageFile: string;
  imageFileList: TStringList;
begin
  if not Assigned(FOnAddListItem) then
    Exit;

  imageFileList := TStringList.Create;

  try
    FillFileList(imageFileList);

    if Terminated then
      Exit;

    for imageFile in imageFileList do
    begin
      ProcessFile(imageFile);

      if Terminated then
        Exit;
    end;
  finally
    imageFileList.Free;
  end;
end;

procedure TPicturesThread.FillFileList(AFileList: TStringList);
var
  searchRec: TSearchRec;
begin
  if AFileList = nil then
    Exit;

  try
    if FindFirst(FPath + '*.*', faAnyFile, searchRec) = 0 then
    begin
      repeat
        if Terminated then
          Exit;

        if IsImageFile(searchRec.Name) then
          AFileList.Add(FPath + searchRec.Name);
      until FindNext(searchRec) <> 0;
    end;
  finally
    FindClose(searchRec);
  end;
end;

function TPicturesThread.IsImageFile(AFileName: string): boolean;
const
  IMAGE_FILE_EXTS: array[0..3] of string = ('JPG', 'JPEG', 'BMP', 'PNG');
var
  fileExt: string;
begin
  Result := false;

  for fileExt in IMAGE_FILE_EXTS do
    if UpperCase(ExtractFileExt(AFileName)) = '.'+fileExt then
      Exit(True);
end;

procedure TPicturesThread.ProcessFile(AFileName: string);
var
  bitmap: TBitmap;
begin
  FCurrentFileData.Clear;
  bitmap := TBitmap.Create;

  try
    try
      FThumbnailExtractor.DrawTumbnailOnBitmap(AFileName, bitmap);
    except
      //bad file header for example
      Exit;
    end;

    if Terminated then
      Exit;

    FCurrentFileData.FileName := AFileName;
    FCurrentFileData.Bitmap := bitmap;
    Synchronize(AddListData);
  finally
    bitmap.Free;
  end;
end;

procedure TPicturesThread.Terminate;
begin
  if not Terminated then
    inherited Terminate;
end;

procedure TPicturesThread.TerminatedSet;
begin
  inherited;
  FPerformed := True;
end;

{ TFileData }

procedure TFileData.Clear;
begin
  FBitmap := nil;
  FFileName := string.Empty;
end;

constructor TFileData.Create;
begin
  Clear;
end;

function TFileData.IsValid: boolean;
begin
  Result := not FFileName.IsEmpty;
end;

{ TPicturesThreads }

procedure TPicturesThreads.StartNewThread(APath: string;
  AOnAddListItem: TAddListItem);
var
  thread: TPicturesThread;
begin
  TerminateAll;
  DeletePerformed;

  thread := TPicturesThread.Create(APath, AOnAddListItem);
  thread.Start;

  Add(thread);
end;

procedure TPicturesThreads.DeletePerformed;
var
  i: integer;
begin
  for i := Count - 1 downto 0 do
    if Items[i].Performed then
      Delete(i);
end;

procedure TPicturesThreads.TerminateAll;
var
  thread: TPicturesThread;
begin
  for thread in Self do
    thread.Terminate;
end;

end.
