unit SFExtCtrlGlobalFunctions;

interface

uses Vcl.Graphics, System.Types, Vcl.ExtCtrls, winapi.Windows, System.SysUtils,
     System.Classes, System.Math;

procedure DrawBevel(pCanvas: TCanvas; var pRect: TRect; pWidth: Integer; pBevel: TPanelBevel);
procedure DrawTextOnPoint(pCanvas: TCanvas; pText: String; var pPointX, pPointY: Integer; pChinese: Boolean);
function GetTextWidth(pCanvas: TCanvas; pTxt: String; pChinese: Boolean): Integer;
function GetTextHeight(pCanvas: TCanvas; pTxt: String; pChinese: Boolean): Integer;
function GetUnicodeCharAtPos(pStr: String; var pPos: Integer; var pRslt: Array of Byte; pGetOnlyChinese: Boolean): Boolean;
function ConvertChineseHexToByte(pHex: String): Byte;
function GetDefaultTextHeight(pCanvas: TCanvas): Integer; overload;
function GetDefaultTextHeight(pFont: TFont): Integer; overload;
function GetCntLines(pStr: String): Integer;
procedure CalcOrientatedTextRect(var pWidth, pHeight: Integer; pOrientation: Integer);
procedure AdjustRectForOrientation(var pRect: TRect; pOrientation: Integer);

implementation

procedure DrawBevel(pCanvas: TCanvas; var pRect: TRect; pWidth: Integer; pBevel: TPanelBevel);
  var lClr1, lClr2: TColor;
begin
  case pBevel of
    Vcl.ExtCtrls.TPanelBevel.bvRaised:
      begin
        lClr1 := clBtnHighlight;
        lClr2 := clBtnShadow;
      end;
    Vcl.ExtCtrls.TPanelBevel.bvLowered:
      begin
        lClr2 := clBtnHighlight;
        lClr1 := clBtnShadow;
      end;
    else
      Exit;
  end;

  with pCanvas do
  begin
    Pen.Width := pWidth;
    Pen.Color := lClr1;
    PolyLine([Point(pRect.Left, pRect.Bottom), Point(pRect.Left, pRect.Top), Point(pRect.Right,pRect.Top)]);
    Pen.Color := lClr2;
    PolyLine([Point(pRect.Right, pRect.Top), Point(pRect.Right, pRect.Bottom), Point(pRect.Left, pRect.Bottom)]);

    with pRect do
    begin
      Left := Left + pWidth + 1;
      Top := Top + pWidth + 1;
      Right := Right - pWidth - 1;
      Bottom := Bottom - pWidth - 1;
    end;
  end;
end;

procedure DrawTextOnPoint(pCanvas: TCanvas; pText: String; var pPointX, pPointY: Integer; pChinese: Boolean);
  var i, x, y: Integer;
      lChar: Array[0..1] of Byte;
      lSize: TSize;
begin
  if (pText = '') or not(Assigned(pCanvas)) then
    Exit;

  x := pPointX;
  y := pPointY;

  i := 1;
  while (GetUnicodeCharAtPos(pText, i, lChar, pChinese)) do
  begin
    // Draw a single character
    // TextOutW(pCanvas.Handle, pPointX + x, y, @lChar, 1);
    TextOutW(pCanvas.Handle, x, y, @lChar, 1);

    // find the coordinates of the next character

    // The GetTextExtentPoint32 function computes the width and height of the specified string of text.
    GetTextExtentPoint32(pCanvas.Handle, @lChar, 1, lSize);
    x := x + lSize.cx;
  end;

  pPointX := x;
  pPointY := y;
end;

// detect width of text
function GetTextWidth(pCanvas: TCanvas; pTxt: String; pChinese: Boolean): Integer;
  var i: Integer;
      lChar: Array[0..1] of Byte;
      lSize: TSize;
begin
  Result := 0;

  if (pTxt = '') then
    Exit;

  i := 1;
  while (getUnicodeCharAtPos(pTxt, i, lChar, pChinese)) do
  begin
    // The GetTextExtentPoint32 function computes the width and height of the specified string of text.
    GetTextExtentPoint32(pCanvas.Handle, @lChar, 1, lSize);
    Result := Result + lSize.cx;
  end;
end;

// detect height of text
function GetTextHeight(pCanvas: TCanvas; pTxt: String; pChinese: Boolean): Integer;
  var i: Integer;
      lChar: Array[0..1] of Byte;
      lSize: TSize;
begin
  Result := 0;

  if (pTxt = '') then
    Exit;

  i := 1;
  while (GetUnicodeCharAtPos(pTxt, i, lChar, pChinese)) do
  begin
    // The GetTextExtentPoint32 function computes the width and height of the specified string of text.
    GetTextExtentPoint32(pCanvas.Handle, @lChar, 1, lSize);

    if (lSize.cy > Result) then
      Result := lSize.cy;
  end;
end;

// detect char at pos from string and convert in unicode
// chinese char looks like \uxxxx, p. e. \u62fc
function GetUnicodeCharAtPos(pStr: String; var pPos: Integer; var pRslt: Array of Byte; pGetOnlyChinese: Boolean): Boolean;
  var lChineseChar: String;
begin
  Result := False;

  // is chinese character
  if (copy(pStr, pPos, 2) = '\u') then
  begin
    // get whole chinese character
    lChineseChar := copy(pStr, pPos + 2, 4);

    if (Length(lChineseChar) = 4) then
    begin
      // set pos after character and split into single bytes
      pPos := pPos + 6;
      pRslt[1] := ConvertChineseHexToByte(copy(lChineseChar, 1, 2));
      pRslt[0] := ConvertChineseHexToByte(copy(lChineseChar, 3, 2));

      Result := True;
      Exit;
    end else
    begin
      // Error: Ignore the rest, be done with
      FillChar(pRslt, SizeOf(pRslt), 0);
      Result := False;
      Exit;
    end;
  end;

  if not(Result) then
  begin
    // str has more characters than pos
    if (pPos <= Length(pStr)) then
    begin
      if not(pGetOnlyChinese) then
      begin
        pRslt[1] := 0;
        pRslt[0] := Byte(pStr[pPos]);
        Result := True;
        inc(pPos);
      end else
      begin
        // search next chinese character and convert
        while (pPos < Length(pStr)) do
        begin
          if (copy(pStr, pPos, 2) = '\u') then
          begin
            Result := GetUnicodeCharAtPos(pStr, pPos, pRslt, pGetOnlyChinese);
            Exit;
          end else
            inc(pPos);
        end;

        Result := False;
      end;
    end;
  end;
end;

// convert a chinsese character from hex into byte
function ConvertChineseHexToByte(pHex: String): Byte;
begin
  try
    Result := StrToInt('$' + Trim(pHex));
  except
    Result := 0;
  end;
end;

// get textheight from canvas
function GetDefaultTextHeight(pCanvas: TCanvas): Integer;
begin
  Result := pCanvas.TextHeight('A');
end;

function GetDefaultTextHeight(pFont: TFont): Integer;
  var lBmp: Vcl.Graphics.TBitmap;
begin
  lBmp := Vcl.Graphics.TBitmap.Create;
  try
    lBmp.Canvas.Font.Assign(pFont);
    Result := GetDefaultTextHeight(lBmp.Canvas);
  finally
    FreeAndNil(lBmp);
  end;
end;

function GetCntLines(pStr: String): Integer;
  var i, lNextPos: Integer;

begin
  Result := 1;

  i := 1;
  while (i < Length(pStr)) do
  begin
    lNextPos := Pos(Chr(13), pStr, i);
    if (lNextPos >= i) then
    begin
      inc(Result);
      i := lNextPos + 1;
    end else
      Exit;
  end;
end;

procedure CalcOrientatedTextRect(var pWidth, pHeight: Integer; pOrientation: Integer);
  var lMod, lDiv, lNewW, lNewH, lAlpha, lLen: Integer;
      lAlphaRad: Extended;
begin
  lMod := Abs(pOrientation) mod 900;
  lDiv := Abs(pOrientation) div 900;
  if (lMod = 0) then
  begin
    if (lDiv mod 2 = 0) then
    begin
      lNewW := pWidth;
      lNewH := pHeight;
    end else
    begin
      lNewW := pHeight;
      lNewH := pWidth;
    end;
  end else
  begin
    if (lDiv mod 2 = 0) then
      lAlpha := Abs(pOrientation) - (lDiv * 900)
    else
      lAlpha := ((lDiv + 1) * 900) - Abs(pOrientation);

    // transfer alpha to rad
    lAlphaRad := (2 * Pi) / 360 * (lAlpha / 10);
    lLen := Trunc(Sqrt(IntPower(pHeight, 2) + IntPower(pWidth, 2))) + 1;

    lNewH := Max(Min(Trunc(Sin(lAlphaRad) * lLen) + 1, pWidth), pHeight);
    lNewW := Max(Trunc(Cos(lAlphaRad) * lLen) + 1, pHeight);
  end;

  pWidth := lNewW;
  pHeight := lNewH;
end;

procedure AdjustRectForOrientation(var pRect: TRect; pOrientation: Integer);
  var lMod, lCirclePart, lHeight, lWidth: Integer;
begin
  lMod := pOrientation mod 3600;
  if (lMod = 0) or (pOrientation = 0) then
    Exit;

  if (lMod < 0) then
    lMod := 3600 - Abs(lMod);

  lCirclePart := ((lMod - 1) div 900) + 1;

  lHeight := pRect.Bottom - pRect.Top;
  lWidth := pRect.Right - pRect.Left;

  // adjust top
  if (lCirclePart = 1) or (lCirclePart = 2) then
    pRect.Top := pRect.Top + lHeight;

  // adjust left
  if (lCirclePart = 2) or (lCirclePart = 3) then
    pRect.Left := pRect.Left + lWidth;
end;

end.
