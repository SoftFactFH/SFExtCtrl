//
//   Title:         SFLabeledImage
//
//   Description:   adjust labels on related images
//
//   Created by:    Frank Huber
//
//   Copyright:     Frank Huber - The SoftwareFactory -
//                  Alberweilerstr. 1
//                  D-88433 Schemmerhofen
//
//                  http://www.thesoftwarefactory.de
//
unit SFLabeledImage;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls,
  System.Generics.Collections, Vcl.Graphics, System.Types;

type
  TSFLabeledImage = class(TImage)
  private
    mLstDepended: TObjectList<Vcl.Controls.TGraphicControl>;
    mParentImage: TSFLabeledImage;
    mParentRelLeft: Integer;
    mParentRelTop: Integer;
    mImageColor: TColor;
    mImgClrTrans: Real;
    mParentScale: Boolean;
    mOnResize: TNotifyEvent;
    mImageInfo: Variant;
  private
    procedure setParentImage(pImg: TSFLabeledImage);
    procedure setParentRelLeft(pVal: Integer);
    procedure setParentRelTop(pVal: Integer);
    procedure setImageColor(pVal: TColor);
    procedure setImgClrTrans(pVal: Real);
    procedure setParentScale(pVal: Boolean);
    procedure calcParentedPosition;
    procedure calcParentScale;
    procedure doNotifyDepended;
    procedure paintWithImageColor;
  protected
    procedure Resize; override;
    procedure Paint; override;
    property Canvas;
  public
    procedure NotifyDepended(pObj: Vcl.Controls.TGraphicControl);
    procedure RemoveDepended(pObj: Vcl.Controls.TGraphicControl);
    procedure NotifyParentRepaint;
    procedure DetectRelatedPictSize(var pHeight, pWidth: Double);
    procedure DetectRelatedPosition(var pLeft, pTop: Integer);
    function GetPictRect: TRect;
    procedure Assign(Source: TPersistent); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ParentImage: TSFLabeledImage read mParentImage write setParentImage;
    property ParentRelLeft: Integer read mParentRelLeft write setParentRelLeft;
    property ParentRelTop: Integer read mParentRelTop write setParentRelTop;
    property ImageColor: TColor read mImageColor write setImageColor;
    property ImgClrTrans: Real read mImgClrTrans write setImgClrTrans;
    property ParentScale: Boolean read mParentScale write setParentScale;
    property ImageInfo: Variant read mImageInfo write mImageInfo;
    property OnResize: TNotifyEvent read mOnResize write mOnResize;
  end;

  TGraphicControl = class(Vcl.Controls.TGraphicControl)
    public
      property Canvas;
  end;

implementation

uses SFImageLabel, Winapi.GDIPOBJ, Winapi.GDIPAPI, Winapi.Windows, System.Variants;

constructor TSFLabeledImage.Create(AOwner: TComponent);
begin
  inherited;

  mLstDepended := TObjectList<Vcl.Controls.TGraphicControl>.Create(False);
  mParentImage := nil;
  mParentRelLeft := 0;
  mParentRelTop := 0;
  mImageColor := clNone;
  mImgClrTrans := 1.0;
  mParentScale := False;
  mImageInfo := NULL;
  mOnResize := nil;
end;

destructor TSFLabeledImage.Destroy;
  var i: Integer;
begin
  if (Assigned(mLstDepended)) then
  begin
    for i := 0 to (mLstDepended.Count - 1) do
    begin
      if (mLstDepended[i] is TSFImageLabel) then
        TSFImageLabel(mLstDepended[i]).Image := nil
      else if (mLstDepended[i] is TSFLabeledImage) then
        TSFLabeledImage(mLstDepended[i]).ParentImage := nil
    end;

    mLstDepended.Clear;
    FreeAndNil(mLstDepended);
  end;

  if (Assigned(mParentImage)) then
    mParentImage.RemoveDepended(Self);

  mParentImage := nil;
  mParentRelTop := 0;
  mParentRelLeft := 0;

  inherited;
end;

procedure TSFLabeledImage.Resize;
begin
  inherited;

  doNotifyDepended;

  if (Assigned(mOnResize)) then
    mOnResize(Self);
end;

procedure TSFLabeledImage.Paint;
begin
  if (mImageColor = clNone) then
    inherited
  else
    paintWithImageColor;
end;

procedure TSFLabeledImage.NotifyDepended(pObj: Vcl.Controls.TGraphicControl);
begin
  if (Assigned(mLstDepended)) then
  begin
    if (pObj is TSFImageLabel) or (pObj is TSFLabeledImage) then
      mLstDepended.Add(pObj);
  end;
end;

procedure TSFLabeledImage.RemoveDepended(pObj: Vcl.Controls.TGraphicControl);
begin
  if (Assigned(mLstDepended)) then
    mLstDepended.Remove(pObj);
end;

procedure TSFLabeledImage.NotifyParentRepaint;
begin
  calcParentedPosition;
  calcParentScale;
end;

procedure TSFLabeledImage.DetectRelatedPictSize(var pHeight, pWidth: Double);
  var lPropFactor: Double;
begin
  pHeight := 0;
  pWidth := 0;

  if not(Assigned(Picture)) then
    Exit;

  if (Proportional) then
  begin
    // relationfactor from picture
    lPropFactor := Picture.Height / Picture.Width;
    if (Width * lPropFactor <= Height) then
    begin
      // width ist the relevant size
      pHeight := Width * lPropFactor;
      pWidth := Width;
    end else
    begin
      pHeight := Height;
      pWidth := Height / lPropFactor;
    end;
  end else
  if (Stretch) then
  begin
    pHeight := Height;
    pWidth := Width;
  end else
  begin
    pHeight := Picture.Height;
    pWidth := Picture.Width;
  end;
end;

procedure TSFLabeledImage.DetectRelatedPosition(var pLeft, pTop: Integer);
  var lPictTop, lPictLeft, lPictHeight, lPictWidth: Double;
begin
  if (Assigned(Picture)) then
  begin
    lPictTop := 0;
    lPictLeft := 0;

    if (Width <> Picture.Width) or (Height <> Picture.Height) then
    begin
      if (Proportional) then
      begin
        DetectRelatedPictSize(lPictHeight, lPictWidth);

        lPictTop := pTop * (lPictHeight / Picture.Height) - pTop;
        lPictLeft := pLeft * (lPictWidth / Picture.Width) - pLeft;
        if (Center) then
        begin
          lPictTop := lPictTop + (Height - lPictHeight) / 2;
          lPictLeft := lPictLeft + (Width - lPictWidth) / 2;
        end;
      end else
      if (Center) and not(Stretch) then
      begin
        lPictTop := (Height - Picture.Height) / 2;
        lPictLeft := (Width - Picture.Width) / 2;
      end else
      if (Stretch) and not (Proportional) then
      begin
        lPictTop := pTop * (Height / Picture.Height) - pTop;
        lPictLeft := pLeft * (Width / Picture.Width) - pLeft;
      end;
    end;

    pTop := Top + Round(lPictTop) + pTop;
    pLeft := Left + Round(lPictLeft) + pLeft;
  end;
end;

function TSFLabeledImage.GetPictRect: TRect;
  var lLeft, lTop: Integer;
      lHeight, lWidth: Double;
begin
  if (Assigned(Picture)) then
  begin
    lLeft := 0;
    lTop := 0;

    DetectRelatedPosition(lLeft, lTop);
    DetectRelatedPictSize(lHeight, lWidth);

    // only look at picture-position inside control
    // -> subtract Top/Left of control (s. a. DetectRelatedPosition)
    Result.Left := lLeft - Left;
    Result.Top := lTop - Top;
    Result.Right := Result.Left + Trunc(lWidth);
    Result.Bottom := Result.Top + Trunc(lHeight);
  end;
end;

procedure TSFLabeledImage.Assign(Source: TPersistent);
begin
  inherited;

  if (Source is TSFLabeledImage) then
  begin
    ParentRelLeft := TSFLabeledImage(Source).ParentRelLeft;
    ParentRelTop := TSFLabeledImage(Source).ParentRelTop;
    ImageColor := TSFLabeledImage(Source).ImageColor;
    ImgClrTrans := TSFLabeledImage(Source).ImgClrTrans;
    ParentScale := TSFLabeledImage(Source).ParentScale;
    ImageInfo := TSFLabeledImage(Source).ImageInfo;
  end;
end;

procedure TSFLabeledImage.setParentImage(pImg: TSFLabeledImage);
begin
  if (pImg = nil) then
  begin
    mParentImage := nil;
    Exit;
  end;

  if (pImg <> mParentImage) and (pImg.Parent = Parent) then
  begin
    mParentImage := pImg;
    mParentImage.NotifyDepended(Self);

    calcParentedPosition;
    calcParentScale;
  end;
end;

procedure TSFLabeledImage.setParentRelLeft(pVal: Integer);
begin
  if (pVal <> mParentRelLeft) then
  begin
    mParentRelLeft := pVal;
    calcParentedPosition;
  end;
end;

procedure TSFLabeledImage.setParentRelTop(pVal: Integer);
begin
  if (pVal <> mParentRelTop) then
  begin
    mParentRelTop := pVal;
    calcParentedPosition;
  end;
end;

procedure TSFLabeledImage.setImageColor(pVal: TColor);
begin
  if (pVal <> mImageColor) then
  begin
    mImageColor := pVal;
    Invalidate;
  end;
end;

procedure TSFLabeledImage.setImgClrTrans(pVal: Real);
begin
  if (pVal <> mImgClrTrans) then
  begin
    mImgClrTrans := pVal;

    if (mImageColor <> clNone) then
      Invalidate;
  end;
end;

procedure TSFLabeledImage.setParentScale(pVal: Boolean);
begin
  if (pVal <> mParentScale) then
  begin
    mParentScale := pVal;
    calcParentScale;
  end;
end;

procedure TSFLabeledImage.calcParentedPosition;
  var lTop, lLeft: Integer;
begin
  if (Assigned(mParentImage)) and (Assigned(mParentImage.Picture)) then
  begin
    lTop := mParentRelTop;
    lLeft := mParentRelLeft;

    mParentImage.DetectRelatedPosition(lLeft, lTop);

    Top := lTop;
    Left := lLeft;

    doNotifyDepended;
  end;
end;

procedure TSFLabeledImage.calcParentScale;
  var lParentPictWidth, lParentPictHeight, lFactWidth, lFactHeight: Double;
begin
  if (mParentScale) and (Assigned(mParentImage)) and (Assigned(mParentImage.Picture)) and (Assigned(Picture)) then
  begin
    mParentImage.DetectRelatedPictSize(lParentPictHeight, lParentPictWidth);

    lFactWidth := lParentPictWidth / mParentImage.Picture.Width;
    lFactHeight := lParentPictHeight / mParentImage.Picture.Height;

    Width := Round(Picture.Width * lFactWidth);
    Height := Round(Picture.Height * lFactHeight);
  end;
end;

procedure TSFLabeledImage.doNotifyDepended;
  var i: Integer;
begin
  if (Assigned(mLstDepended)) then
  begin
    for i := 0 to (mLstDepended.Count - 1) do
    begin
      if (mLstDepended[i] is TSFImageLabel) then
        TSFImageLabel(mLstDepended[i]).NotifyImageRepaint
      else if (mLstDepended[i] is TSFLabeledImage) then
        TSFLabeledImage(mLstDepended[i]).NotifyParentRepaint;
    end;
  end;
end;

procedure TSFLabeledImage.paintWithImageColor;
const lBaseMatrix: TColorMatrix =
        ( ( 1.0 , 0.0 , 0.0 , 0.0 , 0.0 ),
          ( 0.0 , 1.0 , 0.0 , 0.0 , 0.0 ),
          ( 0.0 , 0.0 , 1.0 , 0.0 , 0.0 ),
          ( 0.0 , 0.0 , 0.0 , 1.0 , 0.0 ),
          ( 0.0 , 0.0 , 0.0 , 0.0 , 1.0 ) );
        //  R, G, B, Transparency, Dummy

var lMatrix: TColorMatrix;
    lGraphic: TGPGraphics;
    lImgAttr: TGPImageAttributes;
    lImg: TGPImage;
    lImgStream: TMemoryStream;
    lStreamAdapter: TStreamAdapter;
    lCanvas: TCanvas;
    lClrRGB: TColor;
    lRed, lGreen, lBlue: Byte;
begin
  if not(Assigned(Picture.Graphic)) then
    Exit;

  lImgStream := TMemoryStream.Create;
  lStreamAdapter := TStreamAdapter.Create(lImgStream, soOwned);
  Picture.Graphic.SaveToStream(lImgStream);
  lImg := TGPImage.Create(lStreamAdapter);
  lImgAttr := TGPImageAttributes.Create;
  try
    lMatrix := lBaseMatrix;

    lClrRGB := ColorToRGB(mImageColor);
    lRed := GetRValue(lClrRGB);
    lGreen := GetGValue(lClrRGB);
    lBlue := GetBValue(lClrRGB);

    lMatrix[0, 0] := lRed / 255;
    lMatrix[1, 1] := lGreen / 255;
    lMatrix[2, 2] := lBlue / 255;
    lMatrix[3, 3] := mImgClrTrans;

    lImgAttr.SetColorMatrix(lMatrix, ColorMatrixFlagsDefault);

    lCanvas := TGraphicControl(Self).Canvas;
    lGraphic := TGPGraphics.Create(lCanvas.Handle);
    try
      lGraphic.DrawImage(lImg, MakeRect(DestRect), 0, 0, lImg.GetWidth, lImg.GetHeight, UnitPixel, lImgAttr);
    finally
      FreeAndNil(lGraphic)
    end;
  finally
    FreeAndNil(lImg); // streamadpater and imgstream here will also destroyed
    FreeAndNil(lImgAttr);
  end;
end;

end.
