unit SFImageLabel;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  SFLabeledImage, Winapi.Messages;

type
  TSFImageLabel = class(TLabel)
  private
    mImage: TSFLabeledImage;
    mRelativeTop: Integer;
    mRelativeLeft: Integer;
    mImageScale: Boolean;
    mOriginFontSize: Integer;
    mCalcImageScaleInProcess: Boolean;
  private
    procedure setImage(pImg: TSFLabeledImage);
    procedure setRelativeLeft(pVal: Integer);
    procedure setRelativeTop(pVal: Integer);
    procedure setImageScale(pVal: Boolean);
    procedure calcPosition;
    procedure calcImageScale;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  public
    procedure NotifyImageRepaint;
    procedure Assign(Source: TPersistent); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Image: TSFLabeledImage read mImage write setImage;
    property RelativeTop: Integer read mRelativeTop write setRelativeTop;
    property RelativeLeft: Integer read mRelativeLeft write setRelativeLeft;
    property ImageScale: Boolean read mImageScale write setImageScale;
    property OriginFontSize: Integer read mOriginFontSize;
  end;

implementation

constructor TSFImageLabel.Create(AOwner: TComponent);
begin
  inherited;

  mImage := nil;
  mRelativeTop := 0;
  mRelativeLeft := 0;
  mImageScale := False;
  mOriginFontSize := 0;
  mCalcImageScaleInProcess := False;
end;

destructor TSFImageLabel.Destroy;
begin
  if (Assigned(mImage)) then
    mImage.RemoveDepended(Self);

  mImage := nil;
  mRelativeTop := 0;
  mRelativeLeft := 0;

  inherited;
end;

procedure TSFImageLabel.NotifyImageRepaint;
begin
  calcPosition;
  calcImageScale;
end;

procedure TSFImageLabel.Assign(Source: TPersistent);
begin
  inherited;

  if (Source is TSFImageLabel) then
  begin
    RelativeTop := TSFImageLabel(Source).RelativeTop;
    RelativeLeft := TSFImageLabel(Source).RelativeLeft;
    ImageScale := TSFImageLabel(Source).ImageScale;
  end;
end;

procedure TSFImageLabel.setImage(pImg: TSFLabeledImage);
begin
  if (pImg = nil) then
  begin
    mImage := nil;
    Exit;
  end;

  if (pImg <> mImage) and (pImg.Parent = Parent) then
  begin
    mImage := pImg;
    mImage.NotifyDepended(Self);

    calcPosition;
    calcImageScale;
  end;
end;

procedure TSFImageLabel.setRelativeLeft(pVal: Integer);
begin
  if (pVal <> mRelativeLeft) then
  begin
    mRelativeLeft := pVal;
    calcPosition;
  end;
end;

procedure TSFImageLabel.setRelativeTop(pVal: Integer);
begin
  if (pVal <> mRelativeTop) then
  begin
    mRelativeTop := pVal;
    calcPosition;
  end;
end;

procedure TSFImageLabel.setImageScale(pVal: Boolean);
begin
  if (pVal <> mImageScale) then
  begin
    mImageScale := pVal;
    calcImageScale;
  end;
end;

procedure TSFImageLabel.CMFontChanged(var Message: TMessage);
begin
  inherited;

  if not(mCalcImageScaleInProcess) then
  begin
    mOriginFontSize := Font.Size;
    calcImageScale;
  end;
end;

procedure TSFImageLabel.calcPosition;
  var lTop, lLeft: Integer;
begin
  if (Assigned(mImage)) and (Assigned(mImage.Picture)) then
  begin
    lTop := mRelativeTop;
    lLeft := mRelativeLeft;

    mImage.DetectRelatedPosition(lLeft, lTop);

    Top := lTop;
    Left := lLeft;
  end;
end;

procedure TSFImageLabel.calcImageScale;
  var lParentPictWidth, lParentPictHeight, lFactHeight: Double;
begin
  if (mImageScale) and (Assigned(mImage)) and (Assigned(mImage.Picture)) then
  begin
    mImage.DetectRelatedPictSize(lParentPictHeight, lParentPictWidth);
    lFactHeight := lParentPictHeight / mImage.Picture.Height;

    if (mOriginFontSize <= 0) then
      mOriginFontSize := Font.Size;

    // take care, origin fontsize will not reseted on fontchange
    mCalcImageScaleInProcess := True;
    try
      Font.Size := Round(mOriginFontSize * lFactHeight);
    finally
      mCalcImageScaleInProcess := False;
    end;
  end;
end;

end.
