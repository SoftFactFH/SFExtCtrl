unit SFLabeledColorPanel;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.Graphics;

const
  LBLEDPNLITEM_DEFAULTWIDTH     = 100;
  LBLEDPNLITEM_DEFAULTMARGIN    = 5;
  LBLEDPNLITEM_OVERFLOWDIV      = 5;
  LBLEDPNLITEM_PNLEDGE          = 1;
  LBLEDPNLITEM_PNLHEIGHTFACTOR  = 1.5;


type
  TpMMClrPnlPosition =
  (
    clrPnlPosLeft,
    clrPnlPosRight,
    clrPnlPosTop,
    clrPnlPosBottom
  );

  TSFLabeledColorPanelItems = class;
  TSFLabeledColorPanelItem = class;

  TSFLabeledColorPanel = class(TLabel)
  private
    mColorItems: TSFLabeledColorPanelItems;
    mPanelPosition: TpMMClrPnlPosition;
    mDrawItemDesc: Boolean;
    mDrawBevelForColorPanel: Boolean;
  private
    procedure setDrawItemDesc(pVal: Boolean);
    procedure setDrawBevelForColorPanel(pVal: Boolean);
    procedure setColorItems(pVal: TSFLabeledColorPanelItems);
    procedure setPanelPosition(pVal: TpMMClrPnlPosition);
    function getTotalHeight: Integer;
    function getTotalWidth: Integer;
    function getColorPanelHeight: Integer;
    function getColorPanelWidth: Integer;
    procedure paintColorPanel(pCanvas: TCanvas; var pPointX, pPointY: Integer);
    procedure paintCaption(pCanvas: TCanvas; var pPointX, pPointY: Integer);
  protected
    procedure AdjustBounds; override;
    procedure Paint; override;
  public
    constructor Create(pOwner: TComponent); override;
    destructor Destroy; override;
  public
    procedure Assign(pSource: TPersistent); override;
    procedure IncItemByRef(pItemRef: Integer);
    procedure DecItemByRef(pItemRef: Integer);
    procedure PaintToCanvas(pCanvas: TCanvas; pPointX, pPointY: Integer);
  published
    property DrawItemDesc: Boolean read mDrawItemDesc write setDrawItemDesc;
    property DrawBevelForColorPanel: Boolean read mDrawBevelForColorPanel write setDrawBevelForColorPanel;
    property ColorItems: TSFLabeledColorPanelItems read mColorItems write setColorItems;
    property ColorPanelPosition: TpMMClrPnlPosition read mPanelPosition write setPanelPosition;
  end;


  TSFLabeledColorPanelItems = class(TCollection)
  private
    mLbledClrPanel: TSFLabeledColorPanel;
  private
    function getItem(pIndex: Integer): TSFLabeledColorPanelItem;
    procedure setItem(pIndex: Integer; pVal: TSFLabeledColorPanelItem);
  public
    constructor Create(pLbledClrPanel: TSFLabeledColorPanel); overload;
  public
    function Add: TSFLabeledColorPanelItem;
    procedure Clear;
    function IndexByRef(pItemRef: Integer): Integer;
    property Items[pIndex: Integer]: TSFLabeledColorPanelItem read getItem write setItem; default;
  public
    property LbledClrPanel: TSFLabeledColorPanel read mLbledClrPanel;
  end;


  TSFLabeledColorPanelItem = class(TCollectionItem)
  private
    mRef: Integer;
    mCntParts: Integer;
    mColor: TColor;
    mDesc: String;
    mParentCollection: TSFLabeledColorPanelItems;
  private
    procedure setCntParts(pVal: Integer);
    procedure setColor(pVal: TColor);
    procedure setDesc(pVal: String);
  public
    constructor Create(pCollection: TCollection); override;
  public
    procedure Assign(pSource: TPersistent); override;
  published
    property ItemReference: Integer read mRef write mRef;
    property PartsCount: Integer read mCntParts write setCntParts;
    property ItemColor: TColor read mColor write setColor;
    property Desc: String read mDesc write setDesc;
  end;

implementation

uses SFExtCtrlGlobalFunctions, winapi.Windows, Vcl.GraphUtil;

//============================================================================//
//                      TSFLabeledColorPanelItems                             //
//============================================================================//

constructor TSFLabeledColorPanelItems.Create(pLbledClrPanel: TSFLabeledColorPanel);
begin
  inherited Create(TSFLabeledColorPanelItem);

  mLbledClrPanel := pLbledClrPanel;
end;

function TSFLabeledColorPanelItems.getItem(pIndex: Integer): TSFLabeledColorPanelItem;
begin
  Result := inherited GetItem(pIndex) as TSFLabeledColorPanelItem;
end;

procedure TSFLabeledColorPanelItems.setItem(pIndex: Integer; pVal: TSFLabeledColorPanelItem);
begin
  inherited SetItem(pIndex, pVal);
end;

function TSFLabeledColorPanelItems.Add: TSFLabeledColorPanelItem;
begin
  Result := inherited Add as TSFLabeledColorPanelItem;

  if (Assigned(mLbledClrPanel)) then
    mLbledClrPanel.Invalidate;
end;

procedure TSFLabeledColorPanelItems.Clear;
begin
  inherited Clear;

  if (Assigned(mLbledClrPanel)) then
    mLbledClrPanel.Invalidate;
end;

function TSFLabeledColorPanelItems.IndexByRef(pItemRef: Integer): Integer;
  var i: Integer;
begin
  for i := 0 to (Count - 1) do
  begin
    if (Items[i].ItemReference = pItemRef) then
    begin
      Result := i;
      Exit;
    end;
  end;

  Result := -1;
end;

//============================================================================//
//                      TSFLabeledColorPanelItem                              //
//============================================================================//

constructor TSFLabeledColorPanelItem.Create(pCollection: TCollection);
begin
  inherited;

  mParentCollection := nil;

  if (pCollection is TSFLabeledColorPanelItems) then
    mParentCollection := pCollection as TSFLabeledColorPanelItems;

  mRef := 0;
  mCntParts := 0;
  mColor := clNone;
  mDesc := '';
end;

procedure TSFLabeledColorPanelItem.Assign(pSource: TPersistent);
begin
  if (pSource is TSFLabeledColorPanelItem) then
  begin
    ItemReference := TSFLabeledColorPanelItem(pSource).ItemReference;
    PartsCount := TSFLabeledColorPanelItem(pSource).PartsCount;
    ItemColor := TSFLabeledColorPanelItem(pSource).ItemColor;
    Desc := TSFLabeledColorPanelItem(pSource).Desc;
  end else
    inherited;
end;

procedure TSFLabeledColorPanelItem.setCntParts(pVal: Integer);
begin
  if (mCntParts <> pVal) then
  begin
    mCntParts := pVal;

    if (Assigned(mParentCollection)) then
      mParentCollection.LbledClrPanel.Invalidate;
  end;
end;

procedure TSFLabeledColorPanelItem.setColor(pVal: TColor);
begin
  if (mColor <> pVal) then
  begin
    mColor := pVal;

    if (Assigned(mParentCollection)) then
      mParentCollection.LbledClrPanel.Invalidate;
  end;
end;

procedure TSFLabeledColorPanelItem.setDesc(pVal: String);
begin
  if (mDesc <> pVal) then
  begin
    mDesc := pVal;

    if (Assigned(mParentCollection)) and (mParentCollection.LbledClrPanel.DrawItemDesc) then
      mParentCollection.LbledClrPanel.Invalidate;
  end;
end;

//============================================================================//
//                      TSFLabeledColorPanel                                  //
//============================================================================//

constructor TSFLabeledColorPanel.Create(pOwner: TComponent);
begin
  inherited;

  mColorItems := TSFLabeledColorPanelItems.Create(Self);

  mPanelPosition := clrPnlPosBottom;
  mDrawItemDesc := True;
  mDrawBevelForColorPanel := True;
end;

destructor TSFLabeledColorPanel.Destroy;
begin
  inherited;

  if (Assigned(mColorItems)) then
  begin
    mColorItems.Clear;
    FreeAndNil(mColorItems);
  end;
end;

procedure TSFLabeledColorPanel.Assign(pSource: TPersistent);
begin
  if (pSource is  TSFLabeledColorPanel) then
  begin
    DrawItemDesc := TSFLabeledColorPanel(pSource).DrawItemDesc;
    DrawBevelForColorPanel := TSFLabeledColorPanel(pSource).DrawBevelForColorPanel;
    ColorPanelPosition := TSFLabeledColorPanel(pSource).ColorPanelPosition;
    ColorItems := TSFLabeledColorPanel(pSource).ColorItems;
  end else
    inherited;
end;

procedure TSFLabeledColorPanel.IncItemByRef(pItemRef: Integer);
  var lItem: TSFLabeledColorPanelItem;
      lIdx: Integer;
begin
  if (Assigned(mColorItems)) then
  begin
    lIdx := mColorItems.IndexByRef(pItemRef);
    if (lIdx >= 0) and (lIdx < mColorItems.Count) then
    begin
      lItem := mColorItems.Items[lIdx];
      lItem.PartsCount := lItem.PartsCount + 1;
    end;
  end;
end;

procedure TSFLabeledColorPanel.DecItemByRef(pItemRef: Integer);
  var lItem: TSFLabeledColorPanelItem;
      lIdx: Integer;
begin
  if (Assigned(mColorItems)) then
  begin
    lIdx := mColorItems.IndexByRef(pItemRef);
    if (lIdx >= 0) and (lIdx < mColorItems.Count) then
    begin
      lItem := mColorItems.Items[mColorItems.IndexByRef(pItemRef)];
      lItem.PartsCount := lItem.PartsCount - 1;
    end;
  end;
end;

procedure TSFLabeledColorPanel.PaintToCanvas(pCanvas: TCanvas; pPointX, pPointY: Integer);
  var lForeignCanvas: Boolean;
      lSavedFont: TFont;
      lSavedTextAlign, x, y: Integer;
begin
  lSavedFont := nil;
  lSavedTextAlign := 0;

  lForeignCanvas := (pCanvas <> Canvas);
  if (lForeignCanvas) and (Canvas.HandleAllocated) then
  begin
    lSavedTextAlign := SetTextAlign(Canvas.Handle, TA_TOP or TA_LEFT);
    lSavedFont := TFont.Create;
    lSavedFont.Assign(pCanvas.Font);
    pCanvas.Font.Assign(Font);
    pCanvas.Brush.Color := Color;
    pCanvas.Brush.Style := bsClear;
  end;

  x := pPointX;
  y := pPointY;

  if (mPanelPosition in [clrPnlPosLeft, clrPnlPosTop]) then
    paintColorPanel(pCanvas, x, y);

  if (mPanelPosition = clrPnlPosLeft) then
  begin
    y := pPointY;
    x := x + LBLEDPNLITEM_DEFAULTMARGIN;
  end else
  if ((mPanelPosition = clrPnlPosTop)) then
  begin
    x := pPointX;
    y := pPointY + LBLEDPNLITEM_DEFAULTMARGIN + getColorPanelHeight;
  end;

  paintCaption(pCanvas, x, y);

  if (mPanelPosition = clrPnlPosRight) then
  begin
    y := pPointY;
    x := x + LBLEDPNLITEM_DEFAULTMARGIN;
  end else
  if (mPanelPosition = clrPnlPosBottom) then
  begin
    x := pPointX;
    y := pPointY + LBLEDPNLITEM_DEFAULTMARGIN + GetTextHeight(pCanvas, Caption, False);
  end;

  if (mPanelPosition in [clrPnlPosRight, clrPnlPosBottom]) then
    paintColorPanel(pCanvas, x, y);

  if (lForeignCanvas) and (Assigned(lSavedFont)) then
  begin
    pCanvas.Font.Assign(lSavedFont);
    SetTextAlign(pCanvas.Handle, lSavedTextAlign);
    lSavedFont.Free;
  end;
end;

procedure TSFLabeledColorPanel.AdjustBounds;
begin
  if not(csReading in ComponentState) and (Parent <> nil) and (AutoSize) then
    SetBounds(Left, Top, getTotalWidth, getTotalHeight);
end;

procedure TSFLabeledColorPanel.Paint;
  var lImgBuffer: Vcl.Graphics.TBitmap;
begin
  // use buffered canvas because of transparency
  lImgBuffer := Vcl.Graphics.TBitmap.Create;
  try
    lImgBuffer.Width := Width;
    lImgBuffer.Height := Height;
    lImgBuffer.Canvas.Brush.Color := Color;
    lImgBuffer.Canvas.Brush.Style := bsSolid;
    lImgBuffer.Canvas.FillRect(ClientRect);

    PaintToCanvas(lImgBuffer.Canvas, 0, 0);

    if (Transparent) then
    begin
      lImgBuffer.Transparent := True;
      lImgBuffer.TransparentColor := Color;
    end;

    Canvas.Draw(0, 0, lImgBuffer);
  finally
    FreeAndNil(lImgBuffer);
  end;
end;

procedure TSFLabeledColorPanel.setDrawItemDesc(pVal: Boolean);
begin
  if (mDrawItemDesc <> pVal) then
  begin
    mDrawItemDesc := pVal;
    if (mColorItems.Count > 0) then
      Invalidate;
  end;
end;

procedure TSFLabeledColorPanel.setDrawBevelForColorPanel(pVal: Boolean);
begin
  if (mDrawBevelForColorPanel <> pVal) then
  begin
    mDrawBevelForColorPanel := pVal;
    Invalidate;
  end;
end;

procedure TSFLabeledColorPanel.setColorItems(pVal: TSFLabeledColorPanelItems);
begin
  if (Assigned(pVal)) and (Assigned(mColorItems)) then
  begin
    mColorItems.Clear;
    mColorItems.Assign(pVal);
  end;
end;

procedure TSFLabeledColorPanel.setPanelPosition(pVal: TpMMClrPnlPosition);
begin
  if (mPanelPosition <> pVal) then
  begin
    mPanelPosition := pVal;
    Invalidate;
  end;
end;

function TSFLabeledColorPanel.getTotalHeight: Integer;
  var lColorPnlHeight: Integer;
begin
  Result := 0;

  if (Caption <> '') then
  begin
    Canvas.Font.Assign(Font);

    Result := GetTextHeight(Canvas, Caption, False);
  end;

  lColorPnlHeight := getColorPanelHeight;
  if (mPanelPosition in [clrPnlPosTop, clrPnlPosBottom]) then
    Result := Result + LBLEDPNLITEM_DEFAULTMARGIN + lColorPnlHeight
  else if (lColorPnlHeight > Result) then
    Result := lColorPnlHeight;
end;

function TSFLabeledColorPanel.getTotalWidth: Integer;
  var lColorPnlWidth: Integer;
begin
  Result := 0;

  if (Caption <> '') then
  begin
    Canvas.Font.Assign(Font);

    Result := GetTextWidth(Canvas, Caption, False);
  end;

  lColorPnlWidth := getColorPanelWidth;
  if (mPanelPosition in [clrPnlPosLeft, clrPnlPosRight]) then
    Result := Result + LBLEDPNLITEM_DEFAULTMARGIN + lColorPnlWidth
  else if (lColorPnlWidth > Result) then
    Result := lColorPnlWidth;
end;

function TSFLabeledColorPanel.getColorPanelHeight: Integer;
begin
  if (Canvas.HandleAllocated) then
    Result := Trunc(GetDefaultTextHeight(Canvas) * LBLEDPNLITEM_PNLHEIGHTFACTOR)
  else
    Result := Trunc(GetDefaultTextHeight(Canvas.Font) * LBLEDPNLITEM_PNLHEIGHTFACTOR)
end;

function TSFLabeledColorPanel.getColorPanelWidth: Integer;
begin
  Result := mColorItems.Count * LBLEDPNLITEM_DEFAULTWIDTH;
end;

procedure TSFLabeledColorPanel.paintColorPanel(pCanvas: TCanvas; var pPointX, pPointY: Integer);
  var lRect, lRectOverflow: TRect;
      x, y, i, lTotalParts, lTotalWidth, lItemWidth, lPrevOverflow, lAfterOverflow: Integer;
      lItemPartsPct: Double;
      lItem: TSFLabeledColorPanelItem;
      lClr1, lClr2: TColor;
begin
  if (mColorItems.Count = 0) or not(Assigned(pCanvas)) then
    Exit;

  x := pPointX;
  y := pPointY;

  lRect.Left := x;
  lRect.Right := ClientWidth - LBLEDPNLITEM_PNLEDGE;
  if (mPanelPosition = clrPnlPosLeft) then
    lRect.Right := lRect.Right - GetTextWidth(pCanvas, Caption, False) - LBLEDPNLITEM_DEFAULTMARGIN;
  lRect.Top := y;
  lRect.Bottom := y + getColorPanelHeight;

  if (mDrawBevelForColorPanel) then
  begin
    pPointX := lRect.Right;
    pPointY := lRect.Top;

    DrawBevel(pCanvas, lRect, 1, bvLowered);
  end;

  lTotalParts := 0;
  for i := 0 to (mColorItems.Count - 1) do
    lTotalParts := lTotalParts + mColorItems.Items[i].PartsCount;

  if (lTotalParts = 0) then
    Exit;

  lTotalWidth := lRect.Right - lRect.Left;
  x := lRect.Left;
  lClr1 := Color;
  lAfterOverflow := 0;
  for i := 0 to (mColorItems.Count - 1) do
  begin
    lItem := mColorItems.Items[i];
    if (lItem.PartsCount > 0) then
    begin
      lItemPartsPct := 100 / lTotalParts * lItem.PartsCount;
      lItemWidth := Trunc(lTotalWidth / 100 * lItemPartsPct);
      lPrevOverflow := Trunc(lItemWidth / LBLEDPNLITEM_OVERFLOWDIV);
      lClr2 := lItem.ItemColor;
      lRect.Left := x;
      lRect.Right := x + lItemWidth + lAfterOverflow;

      if (lPrevOverflow > 0) or (lAfterOverflow > 0) then
      begin
        lRectOverflow.Left := lRect.Left;
        lRectOverflow.Right := lRect.Left + lPrevOverflow + lAfterOverflow;
        lRectOverflow.Top := lRect.Top;
        lRectOverflow.Bottom := lRect.Bottom;

        GradientFillCanvas(pCanvas, lClr1, lClr2, lRectOverflow, gdHorizontal);

        lRect.Left := lRectOverflow.Right;
      end;

      lAfterOverflow := Trunc(lItemWidth / LBLEDPNLITEM_OVERFLOWDIV);
      lRect.Right := lRect.Right - lAfterOverflow;
      GradientFillCanvas(pCanvas, lClr2, lClr2, lRect, gdHorizontal);

      if (mDrawItemDesc) and (lItem.Desc <> '') then
      begin
        // draw desc in center of rect
        x := lRect.Left + ((lRect.Right - lRect.Left - GetTextWidth(pCanvas, lItem.Desc, False)) div 2);
        if (x < lRect.Left) then
          x := lRect.Left;

        y := lRect.Top + ((lRect.Bottom - lRect.Top - GetTextHeight(pCanvas, lItem.Desc, False)) div 2);
        if (y < lRect.Top) then
          y := lRect.Top;

        DrawTextOnPoint(pCanvas, lItem.Desc, x, y, False);
      end;

      x := lRect.Right;
      lClr1 := lClr2;
    end;
  end;

  // draw margin gradient to original color
  if (lAfterOverflow > 0) then
  begin
    lRect.Left := x;
    lRect.Right := x + lAfterOverflow;
    GradientFillCanvas(pCanvas, lClr1, Color, lRect, gdHorizontal);
  end;

  if not(mDrawBevelForColorPanel) then
  begin
    pPointX := lRect.Right;
    pPointY := lRect.Top;
  end;
end;

procedure TSFLabeledColorPanel.paintCaption(pCanvas: TCanvas; var pPointX, pPointY: Integer);
  var x, y, lTxtWidth: Integer;
begin
  if (Caption = '') or not(Assigned(pCanvas)) then
    Exit;

  x := pPointX;
  y := pPointY;

  lTxtWidth := GetTextWidth(pCanvas, Caption, False);

  if (mPanelPosition in [clrPnlPosBottom, clrPnlPosTop]) then
  begin
    case Alignment of
      taRightJustify: x := ClientWidth - lTxtWidth;
      taCenter: x := (ClientWidth - lTxtWidth) div 2;
    end;
  end;

  DrawTextOnPoint(pCanvas, Caption, x, y, False);

  pPointX := x;
  pPointY := y;
end;

end.
