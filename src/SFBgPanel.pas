unit SFBgPanel;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.ExtCtrls, Vcl.Graphics,
  Winapi.Messages;

type
  TSFBgPanel = class(TPanel)
    private
      mPictPath: String;
    private
      procedure setPicturePath(pPath: String);
      procedure drawBackground(pCanvas: TCanvas);
    public
      procedure WMEraseBkGnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
      procedure Assign(Source: TPersistent); override;
    public
      constructor Create(AOwner: TComponent); override;
    published
      property PictPath: String read mPictPath write setPicturePath;
  end;

implementation

constructor TSFBgPanel.Create(AOwner: TComponent);
begin
  inherited;

  mPictPath := '';
end;

procedure TSFBgPanel.Assign(Source: TPersistent);
begin
  inherited;

  if (Source is TSFBgPanel) then
  begin
    PictPath := TSFBgPanel(Source).PictPath;
  end;
end;

procedure TSFBgPanel.WMEraseBkGnd(var Message: TWMEraseBkgnd);
  var lCanvas: TCanvas;
begin
  if (mPictPath <> '') then
  begin
    if (Canvas.Handle <> Message.DC) then
    begin
      lCanvas := TCanvas.Create;
      lCanvas.Handle := Message.DC;
    end else
      lCanvas := Canvas;

    drawBackground(lCanvas);

    if (lCanvas <> Canvas) then
      FreeAndNil(lCanvas);
  end else
    inherited;
end;

procedure TSFBgPanel.setPicturePath(pPath: String);
begin
  if (mPictPath <> pPath) then
  begin
    mPictPath := pPath;
    Invalidate;
  end;
end;

procedure TSFBgPanel.drawBackground(pCanvas: TCanvas);
  var lPicture: TPicture;
      x, y: Integer;
begin
  if (mPictPath = '') then
    Exit;

  lPicture := TPicture.Create;
  try
    lPicture.LoadFromFile(mPictPath);
    if (lPicture.Width > 0) and (lPicture.Height > 0) then
    begin
      x := 0;
      while (x < ClientWidth) do
      begin
        y := 0;
        while (y < ClientHeight) do
        begin
          pCanvas.Draw(x, y, lPicture.Bitmap);
          y := y + lPicture.Height;
        end;
        x := x + lPicture.Width;
      end;
    end;
  finally
    FreeAndNil(lPicture);
  end;
end;

end.
