unit fMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.ComCtrls, uDirectoryTreeHelper,
  Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, Vcl.Graphics, uPicturesThread,
  uThumbnailExtractor, System.Contnrs;

type
  TfrmMain = class(TForm)
    DirectoryTree: TTreeView;
    TreeSplitter: TSplitter;
    ListView: TListView;
    ImageList: TImageList;
    procedure FormShow(Sender: TObject);
    procedure DirectoryTreeExpanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DirectoryTreeChange(Sender: TObject; Node: TTreeNode);
  private
    FDirectoryTreeHelper: TDirectoryTreeHelper;
    FThreads: TPicturesThreads;
    function AddBitmapToImageList(ABitmap: TBitmap): integer;
    procedure AddListItem(ACaption: string; ABitmap: TBitmap);
    procedure DestroyThreads;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FDirectoryTreeHelper := TDirectoryTreeHelper.Create(DirectoryTree);
  FThreads := TPicturesThreads.Create;

  ImageList.Width := THUMBNAIL_WIDTH;
  ImageList.Height := THUMBNAIL_HEIGHT;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  DestroyThreads;
  FDirectoryTreeHelper.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  FDirectoryTreeHelper.AddDriveNodes;
end;

function TfrmMain.AddBitmapToImageList(ABitmap: TBitmap): integer;
begin
  if not Assigned(ABitmap) or
     ABitmap.Empty then
    Exit(-1);

  ImageList.BeginUpdate;

  try
    Result := ImageList.Add(ABitmap,nil);
  finally
    ImageList.EndUpdate;
  end;
end;

procedure TfrmMain.AddListItem(ACaption: string; ABitmap: TBitmap);
var
  listItem: TListItem;
begin
  ListView.Items.BeginUpdate;

  try
    listItem := ListView.Items.Add;
    listItem.Caption := ACaption;
    listItem.ImageIndex := AddBitmapToImageList(ABitmap);
  finally
    ListView.Items.EndUpdate;
  end;
end;

procedure TfrmMain.DestroyThreads;
begin
  FThreads.TerminateAll;

  while FThreads.Count > 0 do
    FThreads.DeletePerformed;

  FThreads.Free;
end;

procedure TfrmMain.DirectoryTreeChange(Sender: TObject; Node: TTreeNode);
begin
  ListView.Clear;
  ImageList.Clear;

  FThreads.StartNewThread(
    FDirectoryTreeHelper.GetFullPath(Node),
    AddListItem
  );
end;

procedure TfrmMain.DirectoryTreeExpanding(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: Boolean);
begin
  FDirectoryTreeHelper.AddChildDirectoriesNodes(Node);
end;

end.
