unit SFRotateText;

interface

uses
  Vcl.Controls, System.Classes, Vcl.Graphics, SFExtCtrlGlobalFunctions;

type
  TSFRotateText = class(TGraphicControl)
  private
    mText: String;
    mDrawBg: Boolean;
  private
    procedure setText(pVal: String);
    procedure setDrawBg(pVal: Boolean);
  protected
    procedure Paint; override;
  public
    procedure Assign(Source: TPersistent); override;
  public
    constructor Create(pOwner: TComponent); override;
  published
    property Text: String read mText write setText;
    property DrawBg: Boolean read mDrawBg write setDrawBg;
    property Align;
    property Anchors;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Touch;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation


constructor TSFRotateText.Create(pOwner: TComponent);
begin
  inherited;

  mText := '';
  mDrawBg := True;

  ControlStyle := ControlStyle + [csReplicatable];
  Width := 105;
  Height := 105;
end;

procedure TSFRotateText.Paint;
  var lLeft, lTop, lNewW, lNewH, lOri: Integer;
begin
  inherited;

  if (mDrawBg) then
  begin
    Canvas.Brush.Color := Color;
    Canvas.Brush.Style := bsSolid;
    Canvas.FillRect(ClientRect);
  end else
    Canvas.Brush.Style := bsClear;


  if (mText = '') then
    Exit;

  Canvas.Font.Assign(Font);

  // calc height and width from Text
  if (Canvas.Font.Orientation <> 0) then
  begin
    lNewH := Canvas.TextHeight(mText);
    lNewW := Canvas.TextWidth(mText);

    lOri := Canvas.Font.Orientation;
    CalcOrientatedTextRect(lNewW, lNewH, lOri);

    lTop := Trunc((ClientHeight - lNewH) / 2);
    lLeft := Trunc((ClientWidth - lNewW) / 2);

    // correct left/top because of the direction text will be paint
    if (lOri > 0) and (lOri < 1800) or (lOri < -1800) and (lOri > -3600) then
      lTop := lTop + lNewH;
    if (lOri > 900) and (lOri <= 2700) or (lOri <= -900) and (lOri > -2700) then
      lLeft := lLeft + lNewW;
  end else
  begin
    lLeft := Trunc((ClientWidth - Canvas.TextWidth(mText)) / 2);
    lTop := Trunc((ClientHeight - Canvas.TextHeight(mText)) / 2);
  end;

  Canvas.TextOut(lLeft, lTop, mText);
end;

procedure TSFRotateText.Assign(Source: TPersistent);
begin
  if (Source is TSFRotateText) then
  begin
    Text := TSFRotateText(Source).Text;
    DrawBg := TSFRotateText(Source).DrawBg;
  end else
    inherited;
end;

procedure TSFRotateText.setText(pVal: String);
begin
  if (mText <> pVal) then
  begin
    mText := pVal;
    Invalidate;
  end;
end;

procedure TSFRotateText.setDrawBg(pVal: Boolean);
begin
  if (mDrawBg <> pVal) then
  begin
    mDrawBg := pVal;
    Invalidate;
  end;
end;


end.
