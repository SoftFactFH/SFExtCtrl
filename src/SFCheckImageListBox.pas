unit SFCheckImageListBox;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, System.Generics.Collections,
  System.Types, Winapi.Messages, Winapi.Windows, Vcl.Graphics;

type
  TSFCheckImageListBoxItem = class;

  TSFCheckImageListBox = class(TCustomListBox)
    private
      mLstItems: TObjectList<TSFCheckImageListBoxItem>;
      mOnClickCheck: TNotifyEvent;
      mCheckWidth: Integer;
      mCheckHeight: Integer;
      mImageLst: TImageList;
      mUseCheck: Boolean;
    private
      procedure setCheckSize;
      procedure resetItemHeight;
      procedure drawCheck(pRect: TRect; pChecked, pEnabled: Boolean);
      procedure setChecked(pIndex: Integer; pChecked: Boolean);
      function getChecked(pIndex: Integer): Boolean;
      procedure setUseCheck(pVal: Boolean);
      procedure setImageLst(pVal: TImageList);
      procedure setImageIndex(pIndex: Integer; pImgIndex: Integer);
      function getImageIndex(pIndex: Integer): Integer;
      procedure setItemColor(pIndex: Integer; pColor: TColor);
      function getItemColor(pIndex: Integer): TColor;
      procedure setItemStyle(pIndex: Integer; pStyle: TFontStyles);
      function getItemStyle(pIndex: Integer): TFontStyles;
      function getItemFontChanged(pIndex: Integer): Boolean;
      procedure toggleClickCheck(pIndex: Integer);
      procedure invalidateCheck(pIndex: Integer);
      procedure invalidateImage(pIndex: Integer);
      procedure invalidateItem(pIndex: Integer);
      function createLstItem(pIndex: Integer): TObject;
      function extractLstItem(pIndex: Integer): TObject;
      function getLstItem(pIndex: Integer): TObject;
      function haveLstItem(pIndex: Integer): Boolean;
      function isStyleEnabled: Boolean;
      procedure CNDrawItem(var Message: TWMDrawItem); message CN_DRAWITEM;
      procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    protected
      procedure DrawItem(pIndex: Integer; pRect: TRect; pState: TOwnerDrawState); override;
      function InternalGetItemData(pIndex: Integer): TListBoxItemData; override;
      procedure InternalSetItemData(pIndex: Integer; pData: TListBoxItemData); override;
      procedure SetItemData(pIndex: Integer; pData: TListBoxItemData); override;
      function GetItemData(pIndex: Integer): TListBoxItemData; override;
      procedure KeyPress(var pKey: Char); override;
      procedure MouseDown(pButton: TMouseButton; pShift: TShiftState; X, Y: Integer); override;
      procedure ResetContent; override;
      procedure LoadRecreateItems(pRecreateItems: TStrings); override;
      procedure SaveRecreateItems(pRecreateItems: TStrings); override;
      procedure DeleteString(pIndex: Integer); override;
      procedure ClickCheck; dynamic;
      procedure CreateParams(var pParams: TCreateParams); override;
      procedure CreateWnd; override;
    public
      constructor Create(pOwner: TComponent); override;
      destructor Destroy; override;
      procedure CheckAll(pChecked: Boolean);
      function GetCheckWidth: Integer;
      function GetImageWidth: Integer;
      function GetImageHeight: Integer;
      procedure Assign(Source: TPersistent); override;
    public
      property Checked[pIndex: Integer]: Boolean read getChecked write setChecked;
      property ImageIndex[pIndex: Integer]: Integer read getImageIndex write setImageIndex;
      property ItemColor[pIndex: Integer]: TColor read getItemColor write setItemColor;
      property ItemStyle[pIndex: Integer]: TFontStyles read getItemStyle write setItemStyle;
    published
      property OnClickCheck: TNotifyEvent read mOnClickCheck write mOnClickCheck;
      property ImageLst: TImageList read mImageLst write setImageLst;
      property UseCheck: Boolean read mUseCheck write setUseCheck;
      property Align;
      property Anchors;
      property AutoComplete;
      property BevelEdges;
      property BevelInner;
      property BevelOuter;
      property BevelKind;
      property BevelWidth;
      property BiDiMode;
      property BorderStyle;
      property Color;
      property Columns;
      property Constraints;
      property Ctl3D;
      property DoubleBuffered;
      property DragCursor;
      property DragKind;
      property DragMode;
      property Enabled;
      property Font;
      property ImeMode;
      property ImeName;
      property IntegralHeight;
      property ItemHeight;
      property Items;
      property ParentBiDiMode;
      property ParentColor;
      property ParentCtl3D;
      property ParentDoubleBuffered;
      property ParentFont;
      property ParentShowHint;
      property PopupMenu;
      property ScrollWidth;
      property ShowHint;
      property Sorted;
      property Style;
      property TabOrder;
      property TabStop;
      property TabWidth;
      property Touch;
      property Visible;
      property StyleElements;
      property OnClick;
      property OnContextPopup;
      property OnData;
      property OnDataFind;
      property OnDataObject;
      property OnDblClick;
      property OnDragDrop;
      property OnDragOver;
      property OnDrawItem;
      property OnEndDock;
      property OnEndDrag;
      property OnEnter;
      property OnExit;
      property OnGesture;
      property OnKeyDown;
      property OnKeyPress;
      property OnKeyUp;
      property OnMeasureItem;
      property OnMouseActivate;
      property OnMouseDown;
      property OnMouseEnter;
      property OnMouseLeave;
      property OnMouseMove;
      property OnMouseUp;
      property OnStartDock;
      property OnStartDrag;
  end;

  TSFCheckImageListBoxItem = class(TObject)
    private
      mChecked: Boolean;
      mImageIndex: Integer;
      mData: TListBoxItemData;
      mFontColor: TColor;
      mFontStyle: TFontStyles;
      mFontAttrChanged: Boolean;
    public
      constructor Create;
  end;

implementation

uses Vcl.Themes, System.UITypes, System.RTLConsts;


constructor TSFCheckImageListBoxItem.Create;
begin
  inherited Create;

  mImageIndex := -1;
  mChecked := False;
  mFontColor := clNone;
  mFontStyle := [];
  mFontAttrChanged := False;
end;

constructor TSFCheckImageListBox.Create(pOwner: TComponent);
begin
  inherited;

  setCheckSize;
  mUseCheck := True;
  mImageLst := nil;
  mLstItems := TObjectList<TSFCheckImageListBoxItem>.Create(True);
end;

destructor TSFCheckImageListBox.Destroy;
begin
  mLstItems.Clear;
  FreeAndNil(mLstItems);

  inherited;
end;

procedure TSFCheckImageListBox.CheckAll(pChecked: Boolean);
  var i: Integer;
begin
  for i := 0 to (Items.Count - 1) do
    setChecked(i, pChecked);
end;

procedure TSFCheckImageListBox.CreateWnd;
begin
  inherited CreateWnd;

  resetItemHeight;
end;

procedure TSFCheckImageListBox.CreateParams(var pParams: TCreateParams);
begin
  inherited;

  with pParams do
  begin
    if (Style and (LBS_OWNERDRAWFIXED or LBS_OWNERDRAWVARIABLE) = 0) then
      Style := Style or LBS_OWNERDRAWFIXED;
  end;
end;

procedure TSFCheckImageListBox.CNDrawItem(var Message: TWMDrawItem);
  var lDrawItemStruct: PDrawItemStruct;
begin
  if not (csDestroying in ComponentState) then
  begin
    if (Items.Count = 0) then
      Exit;

    lDrawItemStruct := Message.DrawItemStruct;
    with lDrawItemStruct^ do
    begin
      if not(UseRightToLeftAlignment) then
        rcItem.Left := rcItem.Left + GetCheckWidth + GetImageWidth
      else
      begin
        rcItem.Left := rcItem.Left + GetImageWidth;
        rcItem.Right := rcItem.Right - GetCheckWidth;
      end;
    end;

    inherited;
  end;
end;

procedure TSFCheckImageListBox.CMFontChanged(var Message: TMessage);
begin
  inherited;

  resetItemHeight;
end;

procedure TSFCheckImageListBox.KeyPress(var pKey: Char);
begin
  if (pKey = ' ') then
    toggleClickCheck(ItemIndex);

  inherited;
end;

procedure TSFCheckImageListBox.MouseDown(pButton: TMouseButton; pShift: TShiftState; X, Y: Integer);
  var lIndex: Integer;
begin
  inherited;

  if (pButton = mbLeft) then
  begin
    lIndex := ItemAtPos(Point(X, Y), True);

    if (lIndex <> -1) then
    begin
      if not(UseRightToLeftAlignment) then
      begin
        if (X - ItemRect(lIndex).Left < GetCheckWidth) then
          toggleClickCheck(lIndex);
      end else
      begin
        Dec(X, ItemRect(lIndex).Right - GetCheckWidth);
        if (X > 0) and (X < GetCheckWidth) then
          toggleClickCheck(lIndex);
      end;
    end;
  end;
end;

procedure TSFCheckImageListBox.ClickCheck;
begin
  if (Assigned(mOnClickCheck)) then
    mOnClickCheck(Self);
end;

procedure TSFCheckImageListBox.DrawItem(pIndex: Integer; pRect: TRect; pState: TOwnerDrawState);
const
  ItemState: array[Boolean] of TThemedCheckListBox = (tclListItemDisabled, tclListItemNormal);

  var lRect, lImgRect: TRect;
      lEnable: Boolean;
      lCheckWidth, lImgWidth, lImgIdx: Integer;
      lSaveEvent: TDrawItemEvent;
      lColor: TColor;
      lStyle: TCustomStyleServices;
      lDetails: TThemedElementDetails;
begin
  lCheckWidth := GetCheckWidth;
  lImgWidth := GetImageWidth;

  if (pIndex < Items.Count) then
  begin
    lRect := pRect;
    lEnable := Enabled;

    lStyle := StyleServices;

    // draw checkbox
    if not(UseRightToLeftAlignment) then
    begin
      lRect.Right := pRect.Left - lImgWidth;
      lRect.Left := lRect.Right - lCheckWidth;
    end else
    begin
      lRect.Left := pRect.Right;
      lRect.Right := lRect.Left + lCheckWidth;
    end;

    if (mUseCheck) then
      drawCheck(lRect, getChecked(pIndex), lEnable);

    // draw image
    lImgIdx := getImageIndex(pIndex);
    if (Assigned(mImageLst)) and (lImgIdx >= 0) and (lImgIdx < mImageLst.Count) then
    begin
      lImgRect.Left := pRect.Left - lImgWidth + 1;
      lImgRect.Right := pRect.Left + lImgWidth;
      lImgRect.Top := pRect.Top;
      lImgRect.Bottom := pRect.Top + GetImageHeight;
      Canvas.FillRect(lImgRect);
      mImageLst.Draw(Canvas, lImgRect.Left, lImgRect.Top, lImgIdx);
    end;

    if (isStyleEnabled) then
    begin
      lDetails := lStyle.GetElementDetails(ItemState[lEnable]);
      if (seFont in StyleElements) and (lStyle.GetElementColor(lDetails, ecTextColor, lColor)) and (lColor <> clNone) then
        Canvas.Font.Color := lColor;
    end else
    if not(lEnable) then
      Canvas.Font.Color := clGrayText;

    if (getItemFontChanged(pIndex)) then
    begin
      Canvas.Font.Color := getItemColor(pIndex);
      Canvas.Font.Style := getItemStyle(pIndex);
    end;
  end;

  if (Style = lbStandard) and Assigned(OnDrawItem) then
  begin
    // force lbStandard list to ignore OnDrawItem event
    lSaveEvent := OnDrawItem;
    OnDrawItem := nil;
    try
      inherited;
    finally
      OnDrawItem := lSaveEvent;
    end;
  end else
    inherited;
end;

function TSFCheckImageListBox.GetItemData(pIndex: Integer): TListBoxItemData;
begin
  Result := 0;

  if (haveLstItem(pIndex)) then
    Result := TSFCheckImageListBoxItem(getLstItem(pIndex)).mData;
end;

function TSFCheckImageListBox.InternalGetItemData(pIndex: Integer): TListBoxItemData;
begin
  Result := inherited GetItemData(pIndex);
end;

procedure TSFCheckImageListBox.InternalSetItemData(pIndex: Integer; pData: TListBoxItemData);
begin
  inherited SetItemData(pIndex, pData);
end;

procedure TSFCheckImageListBox.SetItemData(pIndex: Integer; pData: TListBoxItemData);
  var lLstItem: TSFCheckImageListBoxItem;
begin
  if (haveLstItem(pIndex)) or (pData <> 0) then
  begin
    lLstItem := TSFCheckImageListBoxItem(getLstItem(pIndex));
    lLstItem.mData := pData;
  end;
end;

procedure TSFCheckImageListBox.ResetContent;
  var i, lIndex: Integer;
      lLstItem: TSFCheckImageListBoxItem;
begin
  for i := 0 to (Items.Count - 1) do
  begin
    lLstItem := TSFCheckImageListBoxItem(extractLstItem(i));

    if (Assigned(lLstItem)) then
    begin
      lIndex := mLstItems.IndexOf(lLstItem);

      if (lIndex <> -1) then
        mLstItems.Delete(lIndex);
    end;
  end;

  inherited;
end;

procedure TSFCheckImageListBox.LoadRecreateItems(pRecreateItems: TStrings);
  var i, lIndex: Integer;
begin
  with pRecreateItems do
  begin
    BeginUpdate;
    try
      Items.NameValueSeparator := NameValueSeparator;
      Items.QuoteChar := QuoteChar;
      Items.Delimiter := Delimiter;
      Items.LineBreak := LineBreak;

      for i := 0 to (Count - 1) do
      begin
        lIndex := Items.Add(pRecreateItems[i]);
        if (Objects[i] <> nil) then
          InternalSetItemData(lIndex, TListBoxItemData(Objects[i]));
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TSFCheckImageListBox.SaveRecreateItems(pRecreateItems: TStrings);
  var i, lIndex: Integer;
      lLstItem: TSFCheckImageListBoxItem;
begin
  // mLstItems.Clear;

  with pRecreateItems do
  begin
    BeginUpdate;
    try
      NameValueSeparator := Items.NameValueSeparator;
      QuoteChar := Items.QuoteChar;
      Delimiter := Items.Delimiter;
      LineBreak := Items.LineBreak;

      for i := 0 to (Items.Count - 1) do
      begin
        lLstItem := TSFCheckImageListBoxItem(extractLstItem(i));
        AddObject(Items[i], lLstItem);

        if (lLstItem <> nil) then
        begin
          lIndex := mLstItems.IndexOf(lLstItem);
          if (lIndex = -1) then
            mLstItems.Add(lLstItem);
        end;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TSFCheckImageListBox.DeleteString(pIndex: Integer);
  var lIndex: Integer;
      lLstItem: TSFCheckImageListBoxItem;
begin
  if (haveLstItem(pIndex)) then
  begin
    lLstItem := TSFCheckImageListBoxItem(getLstItem(pIndex));

    lIndex := mLstItems.IndexOf(lLstItem);
    if (lIndex <> -1) then
      mLstItems.Delete(lIndex);
  end;

  inherited;
end;

function TSFCheckImageListBox.GetCheckWidth: Integer;
begin
  if (mUseCheck) then
    Result := mCheckWidth + 2
  else
    Result := 0;
end;

function TSFCheckImageListBox.GetImageWidth: Integer;
begin
  if (Assigned(mImageLst)) then
    Result := mImageLst.Width + 2
  else
    Result := 0;
end;

function TSFCheckImageListBox.GetImageHeight: Integer;
begin
  if (Assigned(mImageLst)) then
    Result := mImageLst.Height + 2
  else
    Result := 0;
end;

procedure TSFCheckImageListBox.Assign(Source: TPersistent);
begin
  inherited;

  if (Source is TSFCheckImageListBox) then
    UseCheck := TSFCheckImageListBox(Source).UseCheck;
end;

function TSFCheckImageListBox.isStyleEnabled: Boolean;
begin
  Result := StyleServices.Enabled;
  if Result and TStyleManager.IsCustomStyleActive and not (seClient in StyleElements) then
    Result := False;
end;

procedure TSFCheckImageListBox.resetItemHeight;
  var lDfltHeight: Integer;
begin
  if (HandleAllocated) and (Style = lbStandard) then
  begin
    Canvas.Font := Font;
    lDfltHeight := Canvas.TextHeight('Wg');

    if (mCheckHeight > lDfltHeight) then
      lDfltHeight := mCheckHeight;
    if (Assigned(mImageLst)) and (GetImageHeight > lDfltHeight) then
      lDfltHeight := GetImageHeight;

    Perform(LB_SETITEMHEIGHT, 0, lDfltHeight);
  end;
end;

procedure TSFCheckImageListBox.setCheckSize;
var lDC: HDC;
    lCheckSize: TSize;
    lStyle: TCustomStyleServices;
begin
  lStyle := StyleServices;

  if (lStyle.Enabled) then
  begin
    lDC := CreateCompatibleDC(0);
    try
      lStyle.GetElementSize(lDC, lStyle.GetElementDetails(tbCheckBoxCheckedNormal), esActual, lCheckSize);
      if (lCheckSize.Width <= 0) or (lCheckSize.Height <= 0) then
      begin
        lStyle := TStyleManager.SystemStyle;
        lStyle.GetElementSize(lDC, lStyle.GetElementDetails(tbCheckBoxCheckedNormal), esActual, LCheckSize);
      end;

      mCheckWidth := lCheckSize.Width;
      mCheckHeight := lCheckSize.Height;
    finally
      DeleteDC(lDC);
    end;
  end else
  begin
    with TBitmap.Create do
    begin
      try
        Handle := LoadBitmap(0, PChar(OBM_CHECKBOXES));

        mCheckWidth := Width div 4;
        mCheckHeight := Height div 3;
      finally
        Free;
      end;
    end;
  end;
end;

procedure TSFCheckImageListBox.drawCheck(pRect: TRect; pChecked, pEnabled: Boolean);
  var lDrawState: Integer;
      lDrawRect: TRect;
      lElementDetails: TThemedElementDetails;
      lSaveIndex: Integer;
      lSaveColor: TColor;
begin
  lDrawRect.Left := pRect.Left + (pRect.Right - pRect.Left - mCheckWidth) div 2;
  lDrawRect.Top := pRect.Top + (pRect.Bottom - pRect.Top - mCheckHeight) div 2;
  lDrawRect.Right := lDrawRect.Left + mCheckWidth;
  lDrawRect.Bottom := lDrawRect.Top + mCheckHeight;

  with Canvas do
  begin
    if ThemeControl(Self) then
    begin
      if (pChecked) then
      begin
        if (pEnabled) then
          lElementDetails := StyleServices.GetElementDetails(tbCheckBoxCheckedNormal)
        else
          lElementDetails := StyleServices.GetElementDetails(tbCheckBoxCheckedDisabled);
      end else
      begin
        if (pEnabled) then
          lElementDetails := StyleServices.GetElementDetails(tbCheckBoxUncheckedNormal)
        else
          lElementDetails := StyleServices.GetElementDetails(tbCheckBoxUncheckedDisabled)
      end;

      lSaveColor := Brush.Color;
      lSaveIndex := SaveDC(Handle);
      try
        if (TStyleManager.IsCustomStyleActive and (seClient in StyleElements)) then
          Brush.Color := StyleServices.GetStyleColor(scListBox)
        else
          Brush.Color := Color;

        FillRect(pRect);
        IntersectClipRect(Handle, pRect.Left, pRect.Top, pRect.Right, pRect.Bottom);
        StyleServices.DrawElement(Handle, lElementDetails, pRect);
      finally
        RestoreDC(Handle, lSaveIndex);
      end;
      Brush.Color := lSaveColor;
    end else
    begin
      if (pChecked) then
        lDrawState := DFCS_BUTTONCHECK or DFCS_CHECKED
      else
        lDrawState := DFCS_BUTTONCHECK;

      if not(pEnabled) then
        lDrawState := lDrawState or DFCS_INACTIVE;

      DrawFrameControl(Handle, lDrawRect, DFC_BUTTON, lDrawState);
    end;
  end;
end;

procedure TSFCheckImageListBox.setChecked(pIndex: Integer; pChecked: Boolean);
begin
  if (pChecked <> getChecked(pIndex)) then
  begin
    TSFCheckImageListBoxItem(getLstItem(pIndex)).mChecked := pChecked;

    invalidateCheck(pIndex);
  end;
end;

function TSFCheckImageListBox.getChecked(pIndex: Integer): Boolean;
begin
  if (haveLstItem(pIndex)) then
    Result := TSFCheckImageListBoxItem(getLstItem(pIndex)).mChecked
  else
    Result := False;
end;

procedure TSFCheckImageListBox.setUseCheck(pVal: Boolean);
begin
  if (pVal <> mUseCheck) then
  begin
    mUseCheck := pVal;

    Invalidate;
  end;
end;

procedure TSFCheckImageListBox.setImageLst(pVal: TImageList);
begin
  if (pVal <> mImageLst) then
    mImageLst := pVal;
end;

procedure TSFCheckImageListBox.setImageIndex(pIndex: Integer; pImgIndex: Integer);
begin
  if not(Assigned(mImageLst)) then
    Exit;

  if (pImgIndex <> getImageIndex(pIndex)) then
  begin
    TSFCheckImageListBoxItem(getLstItem(pIndex)).mImageIndex := pImgIndex;

    invalidateImage(pIndex);
  end;
end;

function TSFCheckImageListBox.getImageIndex(pIndex: Integer): Integer;
begin
  if (Assigned(mImageLst)) and (haveLstItem(pIndex)) then
    Result := TSFCheckImageListBoxItem(getLstItem(pIndex)).mImageIndex
  else
    Result := -1;
end;

procedure TSFCheckImageListBox.setItemColor(pIndex: Integer; pColor: TColor);
begin
  if (pColor <> getItemColor(pIndex)) then
  begin
    TSFCheckImageListBoxItem(getLstItem(pIndex)).mFontColor := pColor;
    TSFCheckImageListBoxItem(getLstItem(pIndex)).mFontAttrChanged := True;

    invalidateItem(pIndex);
  end;
end;

function TSFCheckImageListBox.getItemColor(pIndex: Integer): TColor;
begin
  if (haveLstItem(pIndex)) then
    Result := TSFCheckImageListBoxItem(getLstItem(pIndex)).mFontColor
  else
    Result := Font.Color;
end;

procedure TSFCheckImageListBox.setItemStyle(pIndex: Integer; pStyle: TFontStyles);
begin
  if (pStyle <> getItemStyle(pIndex)) then
  begin
    TSFCheckImageListBoxItem(getLstItem(pIndex)).mFontStyle := pStyle;
    TSFCheckImageListBoxItem(getLstItem(pIndex)).mFontAttrChanged := True;

    invalidateItem(pIndex);
  end;
end;

function TSFCheckImageListBox.getItemStyle(pIndex: Integer): TFontStyles;
begin
  if (haveLstItem(pIndex)) then
    Result := TSFCheckImageListBoxItem(getLstItem(pIndex)).mFontStyle
  else
    Result := Font.Style;
end;

function TSFCheckImageListBox.getItemFontChanged(pIndex: Integer): Boolean;
begin
  Result := False;

  if (haveLstItem(pIndex)) then
    Result := TSFCheckImageListBoxItem(getLstItem(pIndex)).mFontAttrChanged;
end;

procedure TSFCheckImageListBox.invalidateCheck(pIndex: Integer);
  var lRect: TRect;
begin
  lRect := ItemRect(pIndex);

  if not(UseRightToLeftAlignment) then
    lRect.Right := lRect.Left + GetCheckWidth
  else
    lRect.Left := lRect.Right - GetCheckWidth;

  InvalidateRect(Handle, lRect, not (csOpaque in ControlStyle));
  UpdateWindow(Handle);
end;

procedure TSFCheckImageListBox.invalidateImage(pIndex: Integer);
  var lRect: TRect;
begin
  if not(Assigned(mImageLst)) then
    Exit;

  lRect := ItemRect(pIndex);

  if not(UseRightToLeftAlignment) then
    lRect.Right := lRect.Left + GetCheckWidth + GetImageWidth
  else
    lRect.Right := lRect.Left + GetImageWidth;

  InvalidateRect(Handle, lRect, not (csOpaque in ControlStyle));
  UpdateWindow(Handle);
end;

procedure TSFCheckImageListBox.invalidateItem(pIndex: Integer);
  var lRect: TRect;
begin
  lRect := ItemRect(pIndex);

  InvalidateRect(Handle, lRect, not (csOpaque in ControlStyle));
  UpdateWindow(Handle);
end;

procedure TSFCheckImageListBox.toggleClickCheck(pIndex: Integer);
  var lChecked: Boolean;
begin
  if (pIndex >= 0) and (pIndex < Items.Count) then
  begin
    lChecked := Checked[pIndex];
    Checked[pIndex] := not lChecked;

    ClickCheck;
  end;
end;

function TSFCheckImageListBox.getLstItem(pIndex: Integer): TObject;
begin
  Result := extractLstItem(pIndex);
  if (Result = nil) then
    Result := createLstItem(pIndex);
end;

function TSFCheckImageListBox.extractLstItem(pIndex: Integer): TObject;
begin
  Result := TSFCheckImageListBoxItem(inherited GetItemData(pIndex));

  if (LB_ERR = IntPtr(Result)) then
    raise EListError.CreateResFmt(@SListIndexError, [pIndex]);

  if (Result <> nil) and not(Result is TSFCheckImageListBoxItem) then
    Result := nil;
end;

function TSFCheckImageListBox.createLstItem(pIndex: Integer): TObject;
begin
  Result := TSFCheckImageListBoxItem.Create;

  TSFCheckImageListBoxItem(Result).mFontColor := Font.Color;
  TSFCheckImageListBoxItem(Result).mFontStyle := Font.Style;

  mLstItems.Add(TSFCheckImageListBoxItem(Result));

  inherited SetItemData(pIndex, TListBoxItemData(Result));
end;

function TSFCheckImageListBox.haveLstItem(pIndex: Integer): Boolean;
begin
  Result := (extractLstItem(pIndex) <> nil);
end;


end.
