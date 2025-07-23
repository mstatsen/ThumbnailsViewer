program ThumbnailsViewer;

uses
  Vcl.Forms,
  fMain in 'fMain.pas' {frmMain},
  uDirectoryTreeHelper in 'uDirectoryTreeHelper.pas',
  uPicturesThread in 'uPicturesThread.pas',
  uThumbnailExtractor in 'uThumbnailExtractor.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
