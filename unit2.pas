unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TRowOptForm }

  TRowOptForm = class(TForm)
    RowEdit: TEdit;
  private

  public

  end;

var
  RowOptForm: TRowOptForm;

implementation
uses
  Unit1;

{$R *.lfm}

end.

