object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'ThumbnailsViewer'
  ClientHeight = 370
  ClientWidth = 677
  Color = clBtnFace
  Constraints.MinHeight = 300
  Constraints.MinWidth = 600
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 13
  object TreeSplitter: TSplitter
    Left = 179
    Top = 0
    Height = 370
  end
  object DirectoryTree: TTreeView
    Left = 0
    Top = 0
    Width = 179
    Height = 370
    Align = alLeft
    Indent = 19
    ReadOnly = True
    ShowLines = False
    TabOrder = 0
    OnChange = DirectoryTreeChange
    OnExpanding = DirectoryTreeExpanding
    ExplicitHeight = 362
  end
  object ListView: TListView
    Left = 182
    Top = 0
    Width = 495
    Height = 370
    Align = alClient
    Columns = <>
    DoubleBuffered = True
    IconOptions.AutoArrange = True
    LargeImages = ImageList
    ReadOnly = True
    ParentDoubleBuffered = False
    TabOrder = 1
  end
  object ImageList: TImageList
    Height = 64
    Width = 64
    Left = 282
    Top = 82
  end
end
