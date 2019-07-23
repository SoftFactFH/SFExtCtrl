unit SFImages;

interface

uses
  System.SysUtils, Vcl.Graphics, System.Classes, System.Types, Vcl.Imaging.pngimage,
  Vcl.Imaging.GIFImg, Vcl.Imaging.jpeg, Winapi.GDIPOBJ, Winapi.GDIPAPI, Winapi.Windows;

type
  TpImgFormat =
  (
    imgFrmtPng,
    imgFrmtGif,
    imgFrmtJpg,
    imgFrmtBmp,
    imgFrmtIco,
    imgFrmtTif,
    imgFrmtEmf,
    imgFrmtWmf
  );

  TpImgFormats = set of TpImgFormat;

  TSFImageHelper = class(TObject)
    private
      mStream: TStream;
      mOwnsStream: Boolean;
    private
      function checkPng: Boolean;
      function checkGif: Boolean;
      function checkJpg: Boolean;
      function checkBmp: Boolean;
      function checkIco: Boolean;
      function checkTif: Boolean;
      function checkEmf: Boolean;
      function checkWmf: Boolean;
    public
      constructor Create(pStream: TStream); overload;
      constructor Create(pFileName: String); overload;
      destructor Destroy; override;
    public
      function GetGraphic(pFormats: TpImgFormats = [imgFrmtPng, imgFrmtGif, imgFrmtJpg,
                                                    imgFrmtBmp, imgFrmtIco, imgFrmtTif,
                                                    imgFrmtEmf, imgFrmtWmf]): TGraphic;
      function GetBitmap: Vcl.Graphics.TBitmap; overload;
      function GetBitmap(pFormats: TpImgFormats): Vcl.Graphics.TBitmap; overload;
      function GetMetafile: TMetafile;
  end;

implementation

constructor TSFImageHelper.Create(pStream: TStream);
begin
  inherited Create;

  mStream := pStream;
  mOwnsStream := False;
end;

constructor TSFImageHelper.Create(pFileName: String);
  var lStream: TStream;
begin
  lStream := TFileStream.Create(pFileName, fmOpenRead or fmShareDenyWrite);
  Create(lStream);
  mOwnsStream := True;
end;

destructor TSFImageHelper.Destroy;
begin
  inherited;

  if (Assigned(mStream)) and (mOwnsStream) then
    FreeAndNil(mStream);
end;


function TSFImageHelper.GetGraphic(pFormats: TpImgFormats): TGraphic;
  var lGraphicCls: TGraphicClass;
begin
  Result := nil;
  lGraphicCls := nil;
  if (imgFrmtPng in pFormats) and (checkPng) then
    lGraphicCls := TPngImage
  else if (imgFrmtGif in pFormats) and (checkGif) then
    lGraphicCls := TGifImage
  else if (imgFrmtBmp in pFormats) and (checkBmp) then
    lGraphicCls := Vcl.Graphics.TBitmap
  else if (imgFrmtIco in pFormats) and (checkIco) then
    lGraphicCls := TIcon
  else if (imgFrmtWmf in pFormats) and (checkWmf) then
    lGraphicCls := TMetafile
  else if (imgFrmtEmf in pFormats) and (checkEmf) then
    lGraphicCls := TMetafile
  else if (imgFrmtJpg in pFormats) and (checkJpg) then
    lGraphicCls := TJPEGImage
  else if (imgFrmtTif in pFormats) and (checkTif) then
    lGraphicCls := TWICImage;

  if (Assigned(lGraphicCls)) then
  begin
    Result := lGraphicCls.Create;
    mStream.Position := 0;
    Result.LoadFromStream(mStream);
  end;
end;


function TSFImageHelper.GetBitmap(pFormats: TpImgFormats): Vcl.Graphics.TBitmap;
  var lFormats: TpImgFormats;
      lGraphic: TGraphic;
begin
  Result := nil;

  lFormats := [];
  if (imgFrmtGif in pFormats) then
    lFormats := lFormats + [imgFrmtGif];
  if (imgFrmtBmp in pFormats) then
    lFormats := lFormats + [imgFrmtBmp];

  if (lFormats <> []) then
  begin
    lGraphic := GetGraphic(lFormats);
    if (Assigned(lGraphic)) then
    begin
      if (lGraphic is TGifImage) then
      begin
        Result := Vcl.Graphics.TBitmap.Create;
        Result.Assign(TGifImage(lGraphic).Bitmap);
      end else
      if (lGraphic is Vcl.Graphics.TBitmap) then
      begin
        Result := Vcl.Graphics.TBitmap.Create;
        Result.Assign(Vcl.Graphics.TBitmap(lGraphic));
      end;

      FreeAndNil(lGraphic);
    end;
  end;

  if not(Assigned(Result)) then
    Result := GetBitmap;
end;

function TSFImageHelper.GetBitmap: Vcl.Graphics.TBitmap;
  var lGraphic: TGPGraphics;
      lImg: TGPImage;
      lStreamAdapter: TStreamAdapter;
      lRect: TRect;
begin
  Result := nil;
  if not(Assigned(mStream)) then
    Exit;

  Result := Vcl.Graphics.TBitmap.Create;

  lStreamAdapter := TStreamAdapter.Create(mStream, soReference);
  lImg := TGPImage.Create(lStreamAdapter);
  try
    lRect.Top := 0;
    lRect.Left := 0;
    lRect.Right := lImg.GetWidth;
    lRect.Bottom := lImg.GetHeight;

    Result.Width := lRect.Right;
    Result.Height := lRect.Bottom;

    lGraphic := TGPGraphics.Create(Result.Canvas.Handle);
    try
      lGraphic.DrawImage(lImg, MakeRect(lRect), 0, 0, lImg.GetWidth, lImg.GetHeight, UnitPixel, nil);
    finally
      FreeAndNil(lGraphic)
    end;
  finally
    FreeAndNil(lImg); // streamadpater here also will be destroyed
  end;
end;

function TSFImageHelper.GetMetafile: TMetafile;
  var lGraphic: TGPGraphics;
      lImg: TGPImage;
      lStreamAdapter: TStreamAdapter;
      lRect: TRect;
      lCanvas: TMetafileCanvas;
begin
  Result := nil;
  if not(Assigned(mStream)) then
    Exit;

  Result := TMetafile.Create;

  lStreamAdapter := TStreamAdapter.Create(mStream, soReference);
  lImg := TGPImage.Create(lStreamAdapter);
  try
    lRect.Top := 0;
    lRect.Left := 0;
    lRect.Right := lImg.GetWidth;
    lRect.Bottom := lImg.GetHeight;

    Result.Width := lRect.Right;
    Result.Height := lRect.Bottom;

    lCanvas := TMetafileCanvas.Create(Result, 0);
    lGraphic := TGPGraphics.Create(lCanvas.Handle);
    try
      lGraphic.DrawImage(lImg, MakeRect(lRect), 0, 0, lImg.GetWidth, lImg.GetHeight, UnitPixel, nil);
    finally
      FreeAndNil(lGraphic);
      FreeAndNil(lCanvas);
    end;
  finally
    FreeAndNil(lImg); // streamadpater here also will be destroyed
  end;
end;

function TSFImageHelper.checkPng: Boolean;
  const lPngHeader: Array[0..7] of AnsiChar = (#137, #80, #78, #71, #13, #10, #26, #10);

  var lHeader: Array[0..7] of AnsiChar;
begin
  mStream.Position := 0;
  mStream.Read(lHeader[0], 8);

  Result := (lHeader = lPngHeader);
end;

function TSFImageHelper.checkGif: Boolean;
  type
    TGIFHeaderRec = record
      Signature: array[0..2] of AnsiChar; { contains 'GIF' }
      Version: TGIFVersionRec;   { '87a' or '89a' }
    end;

  var lGifHeader: TGIFHeaderRec;
begin
  Result := True;

  mStream.Position := 0;
  mStream.Read(lGifHeader, SizeOf(lGifHeader));
  if (UpperCase(String(lGifHeader.Signature)) <> 'GIF') then
  begin
    mStream.Position := 0;
    mStream.Seek(SizeOf(LongInt), soFromCurrent);
    // Attempt to read signature again
    mStream.Read(lGifHeader, SizeOf(lGifHeader));
    if (UpperCase(String(lGifHeader.Signature)) <> 'GIF') then
      Result := False;
  end;
end;

function TSFImageHelper.checkJpg: Boolean;
  var lJpgImage: TJPEGImage;
begin
  // no explicit check in TJPEGImage
  Result := True;

  mStream.Position := 0;
  lJpgImage := TJPEGImage.Create;
  try
    try
      lJpgImage.LoadFromStream(mStream);
    except
      on e: Exception do
        Result := False;
    end;
  finally
    FreeAndNil(lJpgImage);
  end;

end;

function TSFImageHelper.checkBmp: Boolean;
  var lBmf: TBitmapFileHeader;
begin
  mStream.ReadBuffer(lBmf, SizeOf(lBmf));

  Result := (lBmf.bfType = $4D42);
end;

function TSFImageHelper.checkIco: Boolean;
  var lCI: TCursorOrIcon;
      lBufferStream: TMemoryStream;
begin
  mStream.Position := 0;

  lBufferStream := TMemoryStream.Create;
  try
    lBufferStream.SetSize(mStream.Size - mStream.Position);
    mStream.ReadBuffer(lBufferStream.Memory^, lBufferStream.Size);
    lBufferStream.ReadBuffer(lCI, SizeOf(lCI));

    Result := (lCI.wType in [RC3_STOCKICON, RC3_ICON]);
  finally
    FreeAndNil(lBufferStream);
  end;
end;

function TSFImageHelper.checkTif: Boolean;
  var lWICImage: TWICImage;
begin
  // in this context no check possible
  Result := True;

  mStream.Position := 0;
  lWICImage := TWICImage.Create;
  try
    try
      lWICImage.LoadFromStream(mStream);
    except
      on e: Exception do
        Result := False;
    end;
  finally
    FreeAndNil(lWICImage);
  end;
end;

function TSFImageHelper.checkEmf: Boolean;
var lSize: Longint;
    lHeader: TEnhMetaHeader;
begin
  mStream.Position := 0;
  lSize := mStream.Size - mStream.Position;
  if (lSize > Sizeof(lHeader)) then
  begin
    mStream.Read(lHeader, SizeOf(lHeader));
    mStream.Seek(-SizeOf(lHeader), soFromCurrent);
  end;

  Result := (lSize > SizeOf(lHeader)) and (lHeader.iType = EMR_HEADER)
            and (lHeader.dSignature = ENHMETA_SIGNATURE);
end;

function TSFImageHelper.checkWmf: Boolean;
  const
    WMFKey  = Integer($9AC6CDD7);
    WMFWord = Word($CDD7);

  type
    TMetafileHeader = record
      Key: Longint;
      Handle: SmallInt;
      Box: TSmallRect;
      Inch: Word;
      Reserved: Longint;
      CheckSum: Word;
    end;

  var lWMF: TMetafileHeader;
      lWMFCheck: Word;
begin
  mStream.Position := 0;
  mStream.Read(lWMF, SizeOf(lWMF));

  Result := (lWMF.Key = WMFKEY);

  if not(Result) then
    Exit;

  lWMFCheck := 0;
  with lWMF, Box do
  begin
    lWMFCheck := lWMFCheck xor Word(Key);
    lWMFCheck := lWMFCheck xor HiWord(Key);
    lWMFCheck := lWMFCheck xor Word(Handle);
    lWMFCheck := lWMFCheck xor Word(Left);
    lWMFCheck := lWMFCheck xor Word(Top);
    lWMFCheck := lWMFCheck xor Word(Right);
    lWMFCheck := lWMFCheck xor Word(Bottom);
    lWMFCheck := lWMFCheck xor Inch;
    lWMFCheck := lWMFCheck xor Word(Reserved);
    lWMFCheck := lWMFCheck xor HiWord(Reserved);
  end;

  Result := (lWMFCheck = lWMF.CheckSum);
end;

end.
