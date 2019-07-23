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
