//
//   Title:         SFExtCtrlReg
//
//   Description:   register controls
//
//   Created by:    Frank Huber
//
//   Copyright:     Frank Huber - The SoftwareFactory -
//                  Alberweilerstr. 1
//                  D-88433 Schemmerhofen
//
//                  http://www.thesoftwarefactory.de
//
unit SFExtCtrlReg;

interface

uses System.Classes, System.SysUtils;

procedure Register;

implementation

uses SFBgPanel, SFCheckImageListBox, SFImageLabel, SFLabeledColorPanel,
     SFLabeledImage, SFRotateText;

procedure Register;
begin
  RegisterComponents('SFFH ExtCtrls', [TSFBgPanel, TSFCheckImageListBox, TSFImageLabel, TSFLabeledColorPanel, TSFLabeledImage, TSFRotateText]);
end;

end.
