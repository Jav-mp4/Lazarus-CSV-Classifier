unit TesterUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  ExtCtrls, TAGraph, Math, TypesUnit;

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
    function ApplyNaiveBayes(rowIndex: Integer): Integer;
    function SelectProbableClass(totalCProb: TDoubleArray): Integer;

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


//Valores de inicio
procedure TTesterForm.FormCreate(Sender: TObject);
begin
  VertBarImage.Canvas.Brush.Color := RGBToColor(226, 226, 226);
  VertBarImage.Canvas.FillRect(VertBarImage.ClientRect);
  HorzBarImage.Canvas.Brush.Color := RGBToColor(226, 226, 226);
  HorzBarImage.Canvas.FillRect(HorzBarImage.ClientRect);
  LoadTesterData(MainForm.LoadCSVFileToMatrix('data_sets\ST2_TestSet.txt'));
  UpdateTestVisual();
end;

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
var
  i: integer;
begin
      {for i := 0 to Length(TMCLASSARRAY) - 1 do
        ClassStringGrid.Cells[0, i + 1] := IntToStr(TMCLASSARRAY[i]);}//Mostrar Clase obtenida en StringGrid
  CheckExistingRows();
  case ClassifierTypeCB.Text of
    'Naive Bayes':
    begin
      for i := 0 to TMROWSIZE - 1 do
      begin
        //Se aplica el algoritmo para todos los elementos nuevos
        if (TMCLASSARRAY[i] = -1) then
          TMCLASSARRAY[i] := ApplyNaiveBayes(i);
        ClassStringGrid.Cells[0,i+1] := IntToStr(TMCLASSARRAY[i]);
      end;
    end;
    'other':
      ShowMessage('other');
  end;
end;

//Aplica el algoritmo Naive Bayes para encontrar la clase
function TTesterForm.ApplyNaiveBayes(rowIndex: integer): Integer;
var
  //C = Clase
  i, j, currentC, totalC, sameValueNum: integer;
  cMatchIndex: array of integer;
  totalCProb, ColCProb, cElements: TDoubleArray;
  mean, deviation: double;
begin
  totalC := TMDATATAG[Length(TMDATATAG) - 1];
  //Areglo del procentaje total de cada clase
  SetLength(totalCProb, totalC);
  //Arreglo del porcentaje en cada columna para la clase actual
  SetLength(ColCProb, TMCOLSIZE);
  ////Recorre todas las clases
  for currentC := 0 to totalC - 1 do
  begin
    //Encuentra los indices que son de la clase siendo evaluada actualmente
    SetLength(cMatchIndex, 0);
    for i := 0 to MainUnit.DMROWSIZE - 1 do
    begin
      if (MainUnit.CLASSARRAY[i] = currentC) then
      begin
        SetLength(cMatchIndex, Length(cMatchIndex) + 1);
        cMatchIndex[Length(cMatchIndex) - 1] := i;
      end;
    end;
    //Recorre todas las columnas
    for j := 0 to TMCOLSIZE - 1 do
    begin
      //Evaluacion si la columna es de tipo Continuo
      if (TMDATATAG[j] = 0) then
      begin
        //Se obtienen todos los elementos de esta columna que pertenecen a la clase currentC
        SetLength(cElements, 0);
        for i := 0 to Length(cMatchIndex) - 1 do
        begin
            SetLength(cElements, Length(cElements) + 1);
            cElements[Length(cElements) - 1] := MainUnit.DATAMATRIX[cMatchIndex[i], j];
        end;
        //Si hay por lo menos un elemento que pertenece a la clase se evalua
        if not (Length(cElements) = 0) then
        begin
          mean := MainForm.GetMean(cElements);
          deviation := MainForm.GetStandarDev(cElements, mean);
          //Se evita error si la desviacion estandar es igual a 0
          if(deviation = 0)then
            deviation := 1e-8;
          try
            ColCProb[j] := (1 / (Sqrt(2 * Pi) * deviation)) * Exp(-(Power((TESTMATRIX[rowIndex, j] - mean), 2) / (2 * Power(deviation, 2))));
          except
            on e1: EDivByZero do
              ShowMessage(e1.Message);
          end;
        end;
      end
      //Evaluacion si la columna es de tipo Nominal
      else
      begin
        sameValueNum := 0;
        for i := 0 to Length(cMatchIndex) - 1 do
        begin
            if ( MainUnit.DATAMATRIX[cMatchIndex[i], j] = TESTMATRIX[rowIndex, j]) then
               begin
               sameValueNum += 1;
               end;
        end;
        ColCProb[j] := sameValueNum / Length(cMatchIndex);
      //Si el valor es 0 se le asigna 1e-4 para evitar que anule los demas al multiplicar
      end;
      if (ColCProb[j] = 0) then
          ColCProb[j] := 1e-4;
    end;
    //Se agrega valor neutro de multiplicacion
    totalCProb[currentC] := 1;
    //Se obtiene la probabilidad conjunta de todas las probabilidades de atributo
    for j := 0 to TMCOLSIZE - 1 do
    begin
      totalCProb[currentC] := totalCProb[currentC] * ColCProb[j];
      //Si el valor es demasiado pequeño se regresa a el limite de 1e-200 para que el programa no lo convierta en 0
      if (totalCProb[currentC] < 1e-308) then
          totalCProb[currentC] := 1e-308;
    end;
  end;
  result := SelectProbableClass(totalCProb);
end;

function TtesterForm.SelectProbableClass(totalCProb: TDoubleArray): Integer;
var
  i, chosenC: Integer;
begin
  chosenC := 0;
  for i:= 0 to Length(totalCProb)-1 do
      if(totalCProb[i] > totalCProb[chosenC]) then
         chosenC := i;
  result := chosenC;
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
  //Si no hay se elige NONE se borran todos los datos y se limpian los StringGrid
  if (CURRENTTESTSET = 'NONE') then
  begin
    ClassifierTypeCB.Enabled := False;
    StartTestBtn.Enabled := False;
    ClearTestData();
  end
  else
  begin
    ClassifierTypeCB.Enabled := True;
    StartTestBtn.Enabled := True;
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
  BeginTesting();
end;

procedure TTesterForm.ClassStringGridSelection(Sender: TObject; aCol,
  aRow: Integer);
begin
  SELECTEDROW := ClassStringGrid.Row - 1;
  TestDataStringGrid.Invalidate;
  RowNumberStringGrid.Invalidate;
  ClassStringGrid.Invalidate;
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

