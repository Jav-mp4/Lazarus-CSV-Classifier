unit TesterUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  ExtCtrls, TAGraph, TASeries, TAChartUtils, Math, TypesUnit;

type

  { TTesterForm }

  TTesterForm = class(TForm)
    AddTestDataBtn: TButton;
    TestChartBarSeries1: TBarSeries;
    TestChart: TChart;
    EvaluateBtn: TButton;
    EvaluationTypeCB: TComboBox;
    ClassificationBtn: TButton;
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
    procedure EvaluateBtnClick(Sender: TObject);
    procedure ClassificationBtnClick(Sender: TObject);
    procedure UpdateTestVisual();
    procedure LoadTesterData(doubleMatrix: TDoubleMatrix);
    procedure DataStringPositionChange();
    procedure CheckExistingRows();
    procedure ClassifyTestSet();
    procedure EvaluateClassifier();
    procedure ClearTestData();
    procedure UpdateStringGrids();
    procedure UpdateTestGraph();
    function ApplyNaiveBayes(rowIndex: integer): Integer;
    function SelectMaxProbClass(totalCProb: TDoubleArray): Integer;


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
  TMCLASSPERCENT, TESTMATRIX: TDoubleMatrix;
  TMCLASSRESULTS, TMREALCLASS: array of integer;
  TMSELECTEDROW, TMROWSIZE, TMCOLSIZE, IGNORESTART, IGNOREEND: integer;
  TSHASCLASS: Boolean;
  TMCURRENTSTATUS: String;

implementation

uses
  MainUnit;

  {$R *.lfm}

  { TTesterForm }


//Valores de inicio
procedure TTesterForm.FormCreate(Sender: TObject);
begin
  TMCURRENTSTATUS := 'NONE';
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
        //Se llenan los valores reales de clase en TMREALCLASS
        SetLength(TMREALCLASS, Length(doubleMatrix) - 1);
        for i := 0 to Length(TMREALCLASS) - 1 do
        begin
          TMREALCLASS[i] := Round(doubleMatrix[i + 1, MainUnit.DMCOLSIZE]);
          //ClassStringGrid.Cells[0, i + 1] := IntToStr(TMREALCLASS[i]); //Para probar la clase en TMREALCLASS
        end;
        TSHASCLASS:= True;
      end
      //Valores que depended si no tiene clase
      else
      begin
        SetLength(TMREALCLASS, 1);
        TMREALCLASS[0] := -1;
        TSHASCLASS := False;
      end;
      {//Se asigna como no revisado para cuando pase a CheckExistingRows()
      for i:= 0 to Length(TMCLASSRESULTS)-1 do
          TMCLASSRESULTS[i] := -2;}
      //Tamaño sin columna de etiquetas
      TMROWSIZE := Length(doubleMatrix) - 1;
      TMCOLSIZE := MainUnit.DMCOLSIZE;
      //Se asignan tamaños a matrizes de datos
      SetLength(TESTMATRIX, TMROWSIZE, TMCOLSIZE);
      SetLength(TMCLASSRESULTS, TMROWSIZE);
      SetLength(TMCLASSPERCENT, TMROWSIZE, MainUnit.CLASSARRAY[Length(MainUnit.CLASSARRAY)-1]);
      TMCURRENTSTATUS := 'NOT_CLASSIFIED';
      //Se agregan los datos a TESTMATRIX
      for i := 0 to TMROWSIZE - 1 do
      begin
        for j := 0 to TMCOLSIZE - 1 do
        begin
          TESTMATRIX[i, j] := doubleMatrix[i + 1, j];
        end;
      end;
      //Se actualiza la parte visual
      UpdateStringGrids();
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

procedure TTesterForm.UpdateStringGrids();
var
  i, j: integer;
begin
  TestDataStringGrid.Clean;
  ClassStringGrid.Clean;
  TestDataStringGrid.ColCount := TMCOLSIZE;
  TestDataStringGrid.rowCount := TMROWSIZE + 1;
  ClassStringGrid.rowCount := TMROWSIZE + 1;
  //Se muestran etiquetas en TestDataStringGrid
  ClassStringGrid.Cells[0, 0] := IntToStr(MainUnit.DATATAG[TMCOLSIZE]);
  for j := 0 to TMCOLSIZE - 1 do
  begin
    TestDataStringGrid.Cells[j, 0] := IntToStr(MainUnit.DATATAG[j]);
  end;
  //Se muestran datos en TestDataStringGrid;
  for i := 0 to TMROWSIZE - 1 do
  begin
    for j := 0 to TMCOLSIZE - 1 do
    begin
      TestDataStringGrid.Cells[j, i + 1] := FloatToStr(TESTMATRIX[i, j]);
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
  ColClassStringGrid1.Cells[0, 0] := 'Class';
  for i := 0 to TMROWSIZE - 1 do
    RowNumberStringGrid.Cells[0, i] := IntToStr(i + 1);
end;


procedure TTesterForm.ClassifyTestSet();
var
  i: integer;
begin
  case ClassifierTypeCB.Text of
    'Naive Bayes':
    begin
      SetLength(TMCLASSPERCENT, TMROWSIZE, MainUnit.DATATAG[Length(MainUnit.DATATAG) - 1]);
      for i := 0 to TMROWSIZE - 1 do
      begin
        //Se aplica el algoritmo para todos los elementos
        TMCLASSRESULTS[i] := ApplyNaiveBayes(i);
        ClassStringGrid.Cells[0,i+1] := IntToStr(TMCLASSRESULTS[i]);
      end;
      TMCURRENTSTATUS := 'CLASSIFIED';
    end;
    'other':
      ShowMessage('other');
  end;
end;

procedure TTesterForm.EvaluateClassifier();
var
  i, j, f, folds: Integer;
begin
  folds := 5;
  case EvaluationTypeCB.Text of
    'K-Fold':
    begin
      //Se obtiene el tamaño de cada fold de acuerdo a K y el tamaño de DATAMATRIX
      TMROWSIZE := (MainUnit.DMROWSIZE div folds);
      TMCOLSIZE := MainUnit.DMCOLSIZE;
      //Se llena TESTMATRIX con los valores de el fold que esta siendo evaluado
      SetLength(TESTMATRIX, TMROWSIZE, TMCOLSIZE);
      for f := 1 to folds do
      begin
        IGNORESTART := (TMROWSIZE * f)-TMROWSIZE;
        IGNOREEND := (TMROWSIZE * f)-1;
        for i := 0 to TMROWSIZE - 1 do
          for j := 0 to TMCOLSIZE - 1 do
            TESTMATRIX[i, j] := MainUnit.DATAMATRIX[IGNORESTART+i, j];;
      //Se asignan los valores reales de clase en TMREALCLASS
      SetLength(TMREALCLASS, TMROWSIZE);
      SetLength(TMCLASSRESULTS, TMROWSIZE);
      for i := 0 to TMROWSIZE - 1 do
        TMREALCLASS[i] := MainUnit.CLASSARRAY[i];
      TSHASCLASS := True;
      //Se asigna tamaño a TMCLASSPERCENT
      SetLength(TMCLASSPERCENT, TMROWSIZE, MainUnit.CLASSARRAY[Length(MainUnit.CLASSARRAY)-1]);
      TMCURRENTSTATUS := 'NOT_CLASSIFIED';
      //Se actualizan StringGrids y se empieza la clasificacion de TESTMATRIX
      UpdateStringGrids();
      ClassifyTestSet();
      showmessage(' ');
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
  ColCProb, cElements: TDoubleArray;
  mean, deviation, cProbInDM: double;
begin
  totalC := MainUnit.DATATAG[Length(MainUnit.DATATAG) - 1];
  //Arreglo del porcentaje en cada columna para la clase actual
  SetLength(ColCProb, TMCOLSIZE);
  ////Recorre todas las clases
  for currentC := 0 to totalC - 1 do
  begin
    //Encuentra los indices que son de la clase siendo evaluada actualmente
    SetLength(cMatchIndex, 0);
    for i := 0 to MainUnit.DMROWSIZE-1 do
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
      if (MainUnit.DATATAG[j] = 0) then
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
            deviation := 1e-308;
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
        if (Length(cMatchIndex) = 0) then
          ColCProb[j] := 0
        else
          ColCProb[j] := sameValueNum / Length(cMatchIndex);
      //Si el valor es 0 se le asigna 1e-4 para evitar que anule los demas al multiplicar
      end;
      if (ColCProb[j] = 0) then
          ColCProb[j] := 1e-308;
    end;
    //Se agrega valor neutro de multiplicacion
    TMCLASSPERCENT[rowIndex, currentC] := 1;
    //Se obtiene la probabilidad conjunta de todas las probabilidades de atributo
    for j := 0 to TMCOLSIZE - 1 do
    begin
      TMCLASSPERCENT[rowIndex, currentC] := TMCLASSPERCENT[rowIndex, currentC] * ColCProb[j];
      //Si el valor es demasiado pequeño se regresa a el limite de 1e-200 para que el programa no lo convierta en 0
      if (TMCLASSPERCENT[rowIndex, currentC] < 1e-308) then
          TMCLASSPERCENT[rowIndex, currentC] := 1e-308;
    end;
    //Se multiplica por la probabilidad de clase
    cProbInDM := 0;
    for i := 0 to MainUnit.DMROWSIZE-1 do
      if (MainUnit.CLASSARRAY[i] = currentC) then
        cProbInDM += 1;
    cProbInDM := cProbInDM / Length(MainUnit.CLASSARRAY);
    TMCLASSPERCENT[rowIndex, currentC] := TMCLASSPERCENT[rowIndex, currentC] * cProbInDM;
  end;
  result := SelectMaxProbClass(TMCLASSPERCENT[rowIndex]);
end;

function TtesterForm.SelectMaxProbClass(totalCProb: TDoubleArray): Integer;
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
          TMCLASSRESULTS[k] := MainUnit.CLASSARRAY[i];
          found[k] := True;
        end;
      end;
    end;
  end;
  for k := 0 to TMROWSIZE - 1 do
    if not (found[k]) then
      TMCLASSRESULTS[k] := -1;
end;


procedure TTesterForm.UpdateTestVisual();
var
  i: integer;
begin
  //Si no hay se elige NONE se borran todos los datos y se limpian los StringGrid
  if (TMCURRENTSTATUS = 'NONE') then
  begin
    ClearTestData();
  end
  else
  begin
    ClassifierTypeCB.Enabled := True;
    ClassificationBtn.Enabled := True;
  end;
end;

procedure TTesterForm.UpdateTestGraph();
var
  i, j: Integer;
begin
  TestChartBarSeries1.Clear;
  TestChartBarSeries1.BarWidthPercent := 80;
  TestChartBarSeries1.Marks.Visible := True;
  TestChartBarSeries1.Marks.Style := smsLabel;
  TestChartBarSeries1.Marks.LabelBrush.Color := clWhite;
  TestChartBarSeries1.Marks.Frame.Visible := False;
  for J := 0 to Length(TMCLASSPERCENT) - 1 do
        TestChartBarSeries1.AddXY(j, TMCLASSPERCENT[SELECTEDROW,j], IntToStr(j),MainForm.RandomRGB(60, 90, 60, 140, 150, 150));
end;

procedure TTesterForm.ClearTestData();
begin
  SetLength(TESTMATRIX, 0, 0);
  SetLength(TMCLASSRESULTS, 0);
  SetLength(TMREALCLASS, 1);
  TMREALCLASS[1] := -1;
  TMROWSIZE := 0;
  TMCOLSIZE := 0;
  TestDataStringGrid.Clear;
  RowNumberStringGrid.Clear;
  ColNumberStringGrid.Clear;
  ClassStringGrid.Clear;
  ColClassStringGrid1.Clear;
  ClassifierTypeCB.Enabled := False;
  ClassificationBtn.Enabled := False;
end;

procedure TTesterForm.DataStringPositionChange();
begin
  ColNumberStringGrid.LeftCol := TestDataStringGrid.LeftCol;
  RowNumberStringGrid.TopRow := TestDataStringGrid.TopRow - 1;
  ClassStringGrid.TopRow := TestDataStringGrid.TopRow;
  if (TMCURRENTSTATUS = 'CLASSIFIED') then
     UpdateTestGraph();
end;
 
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<FUNCIONES<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<//




//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>EVENTOS>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//


procedure TTesterForm.ClassificationBtnClick(Sender: TObject);
begin
  ClassifyTestSet();
end;

procedure TTesterForm.EvaluateBtnClick(Sender: TObject);
begin
  EvaluateClassifier();
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
  SELECTEDROW := TestDataStringGrid.Row - 1;
  DataStringPositionChange();
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

