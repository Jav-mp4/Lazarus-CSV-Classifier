unit TesterUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  ExtCtrls, TAGraph, TypesUnit;

type

  { TTesterForm }

  TTesterForm = class(TForm)
    AddTestDataBtn: TButton;
    StartTestBtn: TButton;
    ClassifierTypeCB: TComboBox;
    ColNumberStringGrid: TStringGrid;
    ColClassStringGrid1: TStringGrid;
    TestDataStringGrid: TStringGrid;
    DownScrollBtn: TButton;
    HorzBarImage: TImage;
    LeftScrollBtn: TButton;
    TSTRightScrollBtn: TButton;
    RowNumberStringGrid: TStringGrid;
    ClassStringGrid: TStringGrid;
    UpScrollBtn: TButton;
    VertBarImage: TImage;
    //Funciones
    procedure StartTestBtnClick(Sender: TObject);
    procedure UpdateTestVisual();
    procedure LoadTesterData(doubleMatrix: TDoubleMatrix);
    procedure DataStringPositionChange();
    procedure CheckExistingRows();
    procedure BeginTesting();
    procedure ClearTestData();

    //Eventos
    procedure FormCreate(Sender: TObject);
    procedure AddTestDataBtnClick(Sender: TObject);
    procedure ClassStringGridSelection(Sender: TObject; aCol, aRow: integer);
    procedure TestDataStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
    procedure TestDataStringGridSelection(Sender: TObject; aCol, aRow: integer);
    procedure DownScrollBtnClick(Sender: TObject);
    procedure LeftScrollBtnClick(Sender: TObject);
    procedure TSTRightScrollBtnClick(Sender: TObject);
    procedure RowNumberStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
    procedure RowNumberStringGridSelection(Sender: TObject; aCol, aRow: integer);
    procedure ClassStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
    procedure UpScrollBtnClick(Sender: TObject);
  private

  public
  end;


var
  TesterForm: TTesterForm;
  TESTMATRIX: TDoubleMatrix;
  TMDATATAG, TMCLASSARRAY, TMREALCLASSARRAY: array of integer;
  TMSELECTEDROW, TMROWSIZE, TMCOLSIZE: integer;
  CURRENTTESTSET: String;

implementation

uses
  MainUnit;

  {$R *.lfm}

  { TTesterForm }

//Obtener datos de prueba de un TDoubleMatrix
procedure TTesterForm.LoadTesterData(doubleMatrix: TDoubleMatrix);
var
  i, j: integer;
begin
  try
    //Comprobamos que los nuevos datos tengan la misma cantidad de atributos con o sin clase
    if (Length(doubleMatrix[0]) = MainUnit.DMCOLSIZE) or (Length(doubleMatrix[0]) = MainUnit.DMCOLSIZE + 1) then
    begin

      //Revisa que todos las etiquetas sean las mismas que las del dataset original excepto la de clase
      for j := 0 to MainUnit.DMCOLSIZE-1 do
      begin
        if not (DATATAG[j] = doubleMatrix[0, j]) then
          raise EConvertError.Create('');
      end;

      //Valores que dependen si ya tiene clase
      if (Length(doubleMatrix[0]) = MainUnit.DMCOLSIZE + 1) then
      begin
        if not (DATATAG[MainUnit.DMCOLSIZE] = doubleMatrix[0, MainUnit.DMCOLSIZE]) then
          raise EConvertError.Create('');
        //Se llenan los valores reales de clase en TMREALCLASSARRAY
        ClassStringGrid.Clean;
        SetLength(TMREALCLASSARRAY, Length(doubleMatrix) - 1);
        ClassStringGrid.rowCount := Length(doubleMatrix) + 1;
        for i := 0 to Length(TMREALCLASSARRAY) - 1 do
        begin
          TMREALCLASSARRAY[i] := Round(doubleMatrix[i + 1, MainUnit.DMCOLSIZE]);
          //ClassStringGrid.Cells[0, i + 1] := IntToStr(TMREALCLASSARRAY[i]); //Para probar la clase en TMREALCLASSARRAY
        end;
        CURRENTTESTSET:= 'HAS_CLASS';
      end
      //Valores que depended si no tiene clase
      else
      begin
        ClassStringGrid.Clean;
        SetLength(TMREALCLASSARRAY, 1);
        TMREALCLASSARRAY[0] := -1;
        CURRENTTESTSET:= 'NO_CLASS';
      end;
      //Se asigna como no revisado para cuando pase a CheckExistingRows()
      for i:= 0 to Length(TMCLASSARRAY)-1 do
          TMCLASSARRAY[i] := -2;
      //Tamaño sin columna de etiquetas
      TMROWSIZE := Length(doubleMatrix) - 1;
      TMCOLSIZE := MainUnit.DMCOLSIZE;
      TMDATATAG := MainUnit.DATATAG;
      //Se asignan tamaños a matrizes de datos
      SetLength(TESTMATRIX, TMROWSIZE, TMCOLSIZE);
      SetLength(TMCLASSARRAY, TMROWSIZE);
      TestDataStringGrid.Clean;
      TestDataStringGrid.ColCount := TMCOLSIZE;
      TestDataStringGrid.rowCount := TMROWSIZE + 1;
      ClassStringGrid.rowCount := TMROWSIZE + 1;
      //Se muestran etiquetas en StringGrid
      for j := 0 to TMCOLSIZE-1 do
      begin
        TestDataStringGrid.Cells[j, 0] := IntToStr(TMDATATAG[j]);
      end;
      ClassStringGrid.Cells[0, 0] := IntToStr(TMDATATAG[TMCOLSIZE]);
      //Se agregan los datos a TESTMATRIX y al StringGrid
      for i := 0 to TMROWSIZE - 1 do
      begin
        for j := 0 to TMCOLSIZE - 1 do
        begin
          TESTMATRIX[i, j] := doubleMatrix[i + 1, j];
          TestDataStringGrid.Cells[j, i + 1] := FloatToStr(doubleMatrix[i + 1, j]);
        end;
      end;
      //Se llena el StringGrid que contiene el indice de las columnas y el de las filas
      ColNumberStringGrid.ColCount := TMCOLSIZE;
      RowNumberStringGrid.RowCount := TMROWSIZE;
      ColNumberStringGrid.LeftCol := 0;
      RowNumberStringGrid.LeftCol := 0;
      TestDataStringGrid.LeftCol := 0;
      for j := 0 to TMCOLSIZE - 1 do
        ColNumberStringGrid.Cells[j, 0] := IntToStr(j + 1);
      ColClassStringGrid1.ColCount := 1;
      ColClassStringGrid1.Cells[0,0] := 'Class';
      for i := 0 to TMROWSIZE - 1 do
        RowNumberStringGrid.Cells[0, i] := IntToStr(i + 1);
      UpdateTestVisual();
    end
    else
      raise EConvertError.Create('');

  except
    //Si la estructura del TestSet no corresponde con el DataSet original
    On e1: EConvertError do
      ShowMessage('testset incompatible with dataset');
  end;
end;

procedure TTesterForm.BeginTesting();
begin
  case ClassifierTypeCB.Text of
    'Naive Bayes':
      ShowMessage('naive');
    'other':
      ShowMessage('naive');
  end;
end;

procedure TTesterForm.CheckExistingRows();
var
  i, k, j: integer;
  found: Array of Boolean;
  rowExists: boolean;
begin
  //Se asigna como no encontrado a todos los indices
  SetLength(found, TMROWSIZE);
   for k := 0 to TMROWSIZE - 1 do
      found[k] := False;
  //Valores de CLASSARRAY: -2 = No ha sido revisado, -1 = No existe en el DataSet original y se desconoce, Cualquier otro valor es la clase asignada en clasificador
  for i := 0 to MainUnit.DMROWSIZE - 1 do
  begin
    for k := 0 to TMROWSIZE - 1 do
    begin
      //Si aun no se ha encontrado se revisa
      if not (found[k]) then
      begin
        rowExists := True;
        for j := 0 to TMCOLSIZE - 1 do
        begin
          if not (MainUnit.DATAMATRIX[i, j] = TESTMATRIX[k, j]) then
            rowExists := False;
        end;
        //Si ya existe el ejemplo se le asigna la clase que le corresponde de lo contrario se marca con -1
        if (rowExists) then
        begin
          TMCLASSARRAY[k] := MainUnit.CLASSARRAY[i];
          found[k] := True;
        end;
      end;
    end;
  end;
  for k := 0 to TMROWSIZE - 1 do
    if not (found[k]) then
      TMCLASSARRAY[k] := -1;
end;


procedure TTesterForm.UpdateTestVisual();
var
  i: integer;
begin

  case CURRENTTESTSET of
    'NONE':
    begin
      ClassifierTypeCB.Enabled := False;
      StartTestBtn.Enabled := False;
      ClearTestData();
    end;
    'HAS_CLASS':
    begin
      ClassifierTypeCB.Enabled := True;
      StartTestBtn.Enabled := True;
      CheckExistingRows();
      for i := 0 to Length(TMCLASSARRAY) - 1 do
        ClassStringGrid.Cells[0, i + 1] := IntToStr(TMCLASSARRAY[i]);
    end;
    'NO_CLASS':
    begin
      ClassifierTypeCB.Enabled := True;
      StartTestBtn.Enabled := True;
      CheckExistingRows();
      for i := 0 to Length(TMCLASSARRAY) - 1 do
        ClassStringGrid.Cells[0, i + 1] := IntToStr(TMCLASSARRAY[i]);

    end;
  end;
end;

procedure TTesterForm.ClearTestData();
begin
  SetLength(TESTMATRIX, 0, 0);
  SetLength(TMDATATAG, 0);
  SetLength(TMCLASSARRAY, 0);
  SetLength(TMREALCLASSARRAY, 1);
  TMREALCLASSARRAY[1] := -1;
  TMROWSIZE := 0;
  TMCOLSIZE := 0;
  TestDataStringGrid.Clear;
  RowNumberStringGrid.Clear;
  ColNumberStringGrid.Clear;
  ClassStringGrid.Clear;
  ColClassStringGrid1.Clear;
end;

procedure TTesterForm.DataStringPositionChange();
begin
  ColNumberStringGrid.LeftCol := TestDataStringGrid.LeftCol;
  RowNumberStringGrid.TopRow := TestDataStringGrid.TopRow - 1;
  ClassStringGrid.TopRow := TestDataStringGrid.TopRow;
end;
 
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<FUNCIONES<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<//




//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>EVENTOS>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//


procedure TTesterForm.StartTestBtnClick(Sender: TObject);
begin
  UpdateTestVisual();
end;

procedure TTesterForm.ClassStringGridSelection(Sender: TObject; aCol,
  aRow: Integer);
begin
  SELECTEDROW := ClassStringGrid.Row - 1;
  TestDataStringGrid.Invalidate;
  RowNumberStringGrid.Invalidate;
  ClassStringGrid.Invalidate;
end;

procedure TTesterForm.FormCreate(Sender: TObject);
begin
  VertBarImage.Canvas.Brush.Color := RGBToColor(226, 226, 226);
  VertBarImage.Canvas.FillRect(VertBarImage.ClientRect);
  HorzBarImage.Canvas.Brush.Color := RGBToColor(226, 226, 226);
  HorzBarImage.Canvas.FillRect(HorzBarImage.ClientRect);
  CURRENTTESTSET:= 'NONE';
  UpdateTestVisual();
end;

procedure TTesterForm.TestDataStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
begin
  if (aRow = SELECTEDROW + 1) then
    TestDataStringGrid.Canvas.Brush.Color := RGBToColor(226, 226, 226);
end;

procedure TTesterForm.TestDataStringGridSelection(Sender: TObject; aCol, aRow: integer);
begin
  DataStringPositionChange();
  SELECTEDROW := TestDataStringGrid.Row - 1;
  TestDataStringGrid.Invalidate;
  RowNumberStringGrid.Invalidate;
  ClassStringGrid.Invalidate;
end;

procedure TTesterForm.DownScrollBtnClick(Sender: TObject);
begin
  if (TestDataStringGrid.TopRow > TestDataStringGrid.TopRow - 13) then
    begin
    TestDataStringGrid.TopRow := TestDataStringGrid.TopRow + 1;
    ClassStringGrid.TopRow := TestDataStringGrid.TopRow + 1;
    end;
  DataStringPositionChange();
end;

procedure TTesterForm.LeftScrollBtnClick(Sender: TObject);
begin
  if (TestDataStringGrid.LeftCol > 0) then
    TestDataStringGrid.LeftCol := TestDataStringGrid.LeftCol - 1;
  DataStringPositionChange();
end;

procedure TTesterForm.TSTRightScrollBtnClick(Sender: TObject);
begin
  if (TestDataStringGrid.LeftCol < TestDataStringGrid.ColCount - 6) then
    TestDataStringGrid.LeftCol := TestDataStringGrid.LeftCol + 1;
  DataStringPositionChange();
end;

procedure TTesterForm.RowNumberStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
begin
  if (aRow = SELECTEDROW) then
    RowNumberStringGrid.Canvas.Brush.Color := RGBToColor(198, 198, 198);
end;

procedure TTesterForm.RowNumberStringGridSelection(Sender: TObject; aCol, aRow: integer);
begin
  SELECTEDROW := RowNumberStringGrid.Row;
  //TestDataStringGrid.TopRow:=RowNumberStringGrid.TopRow+1;
  TestDataStringGrid.Invalidate;
  RowNumberStringGrid.Invalidate;
  ClassStringGrid.Invalidate;
end;

procedure TTesterForm.ClassStringGridPrepareCanvas(Sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
begin
  if (aRow = SELECTEDROW + 1) then
    ClassStringGrid.Canvas.Brush.Color := RGBToColor(226, 226, 226);
end;

procedure TTesterForm.UpScrollBtnClick(Sender: TObject);
begin
  if (TestDataStringGrid.TopRow > 0) then
  begin
    TestDataStringGrid.TopRow := TestDataStringGrid.TopRow - 1;
    ClassStringGrid.TopRow := TestDataStringGrid.TopRow - 1;
  end;
  DataStringPositionChange();
end;

procedure TTesterForm.AddTestDataBtnClick(Sender: TObject);
var
  doublematrix: TDoubleMatrix;
begin
  try
    MainForm.OpenDialog1.Execute;
    doubleMatrix := MainForm.LoadCSVFileToMatrix(MainForm.OpenDialog1.FileName);
    if (length(doubleMatrix) = 0) then
      raise ERangeError.Create('');
    LoadTesterData(doubleMatrix);
  except
    On e1: EInOutError do
      ShowMessage(e1.Message);
    On e2: ERangeError do
      //ShowMessage(e2.Message);
  end;
end;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<EVENTOS<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<//

end.

