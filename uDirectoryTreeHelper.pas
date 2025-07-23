unit uDirectoryTreeHelper;

interface

uses
  Vcl.ComCtrls, System.IOUtils, System.Types, Winapi.Windows, System.SysUtils;

type
  TDirectoryParams = class
  strict private
    FFullPath: string;
    FName: string;
    FParentNode: TTreeNode;
  public
    property FullPath: string read FFullPath write FFullPath;
    property Name: string read FName write FName;
    property ParentNode: TTreeNode read FParentNode write FParentNode;
  end;

  TDirectoryTreeHelper = class
  strict private
    FTree: TTreeView;
    procedure AddDirectory(AParams: TDirectoryParams);
    procedure AddDriveNode(ADriveLetter: Char);
    function IsAvailableDrive(ADriveLetter: Char): boolean;
    function IsDirectoryName(AName: string): boolean;
    function IsExistChildDirectory(APath: string): boolean;
  public
    constructor Create(ATree: TTreeView);
    procedure AddChildDirectoriesNodes(AParentNode: TTreeNode);
    procedure AddDriveNodes;
    function GetFullPath(ANode: TTreeNode): string;
  end;

implementation

type
  TDriveNodeData = class
  strict private
    FLetter: Char;
    FDisplayName: string;
    function GetDriveLabel: string;
  private
    function Path: string;
    function DisplayName: string;
    constructor Create(ALetter: Char);
  end;

{ TDirectoryTreeHelper }

constructor TDirectoryTreeHelper.Create(ATree: TTreeView);
begin
  FTree := ATree;
end;

function TDirectoryTreeHelper.GetFullPath(ANode: TTreeNode): string;
var
  nodePath: string;
begin
  Result := string.Empty;

  repeat
    if TObject(ANode.Data) is TDriveNodeData then
      nodePath := TDriveNodeData(ANode.Data).Path
    else
      nodePath := ANode.Text;

    Result := IncludeTrailingPathDelimiter(nodePath) + Result;
    ANode := ANode.Parent;
  until ANode = nil;
end;

procedure TDirectoryTreeHelper.AddDirectory(AParams: TDirectoryParams);
var
  node: TTreeNode;
begin
  if not IsDirectoryName(AParams.Name) then
    Exit;

  node := FTree.Items.AddChild(AParams.ParentNode, AParams.Name);
  node.HasChildren := IsExistChildDirectory(AParams.FullPath + AParams.Name);
end;

procedure TDirectoryTreeHelper.AddDriveNode(ADriveLetter: Char);
var
  driveNode: TTreeNode;
  driveNodeData: TDriveNodeData;
begin
  driveNodeData := TDriveNodeData.Create(ADriveLetter);
  driveNode := FTree.Items.AddChild(nil, driveNodeData.DisplayName);
  driveNode.Data := driveNodeData;
  driveNode.HasChildren := IsExistChildDirectory(driveNodeData.Path)
end;

procedure TDirectoryTreeHelper.AddDriveNodes;
var
  drives: TStringDynArray;
  drive: string;
  driveLetter: Char;
begin
  drives := TDirectory.GetLogicalDrives;

  FTree.Items.BeginUpdate;

  try
    FTree.Items.Clear;

    for drive in drives do
    begin
      driveLetter := drive[1];

      if not IsAvailableDrive(driveLetter) then
        Continue;

      AddDriveNode(driveLetter);
    end;
  finally
    FTree.Items.EndUpdate;
  end;
end;

procedure TDirectoryTreeHelper.AddChildDirectoriesNodes(AParentNode: TTreeNode);
var
  searchRec: TSearchRec;
  fullPath: string;
  directoryParams: TDirectoryParams;
begin
  FTree.Items.BeginUpdate;

  try
    AParentNode.DeleteChildren;
    fullPath := GetFullPath(AParentNode);

    try
      if FindFirst(fullPath + '*.*', faDirectory, searchRec) = 0 then
      begin
        directoryParams := TDirectoryParams.Create;

        try
          directoryParams.FullPath := fullPath;
          directoryParams.ParentNode := AParentNode;

          repeat
            if searchRec.Attr and faDirectory <> 0 then
            begin
              directoryParams.Name := searchRec.Name;
              AddDirectory(directoryParams);
            end;
          until FindNext(searchRec) <> 0;
        finally
          directoryParams.Free;
        end;
      end
      else AParentNode.HasChildren := false;

    finally
      FindClose(searchRec);
    end;
  finally
    FTree.Items.EndUpdate;
  end;
end;

function TDirectoryTreeHelper.IsAvailableDrive(ADriveLetter: Char): boolean;
begin
  Exit(
    GetDriveType(PChar(ADriveLetter+':')) <> DRIVE_NO_ROOT_DIR
  );
end;

function TDirectoryTreeHelper.IsDirectoryName(AName: string): boolean;
begin
  Result := (AName <> '.') and (AName <> '..');
end;

function TDirectoryTreeHelper.IsExistChildDirectory(APath: string): boolean;
var
  searchRec: TSearchRec;
begin
  Result := False;

  try
    if FindFirst(IncludeTrailingPathDelimiter(APath) + '*.*', faDirectory, searchRec) = 0 then
      repeat
        if (searchRec.Attr and faDirectory <> 0) and IsDirectoryName(searchRec.Name) then
          Exit(True);
      until FindNext(searchRec) <> 0;
  finally
    FindClose(searchRec);
  end;
end;

{ TDriveNodeData }

constructor TDriveNodeData.Create(ALetter: Char);
begin
  FLetter := ALetter;
end;

function TDriveNodeData.DisplayName: string;
var
  driveLabel: string;
begin
  if FDisplayName.IsEmpty then
  begin
    driveLabel := GetDriveLabel;

    if driveLabel.IsEmpty then
      FDisplayName := Path
    else
      FDisplayName := driveLabel + ' ('+Path+')'
  end;

  Result := FDisplayName;
end;

function TDriveNodeData.Path: string;
begin
  Result := FLetter + ':';
end;

function TDriveNodeData.GetDriveLabel: string;
var
  volumeName: array [0..MAX_PATH-1] of char;
  fileSystemName: array [0..MAX_PATH-1] of char;
  volumeSerialNo: Longword;
  maxComponentLength: Longword;
  fileSystemFlags: Longword;
begin
  Result := string.Empty;

  if GetVolumeInformation(
       PChar(IncludeTrailingPathDelimiter(Path)),
       volumeName,
       MAX_PATH,
       @volumeSerialNo,
       maxComponentLength,
       fileSystemFlags,
       fileSystemName,MAX_PATH) then
    Result := volumeName;
end;

end.
