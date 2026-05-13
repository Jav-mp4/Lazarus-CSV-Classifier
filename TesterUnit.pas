unit TesterUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  ExtCtrls, Buttons, TAGraph, TASeries, TAChartUtils, Math, TypesUnit;

type

  { TTesterForm }

  TTesterForm = class(TForm)
    AddTestDataBtn: TButton;
    FoldsNumberEdit: TEdit;
    PerformanceLabel: TLabel;
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
    procedure FormActivate(Sender: TObject);
    procedure UpdateTestVisual();
    procedure LoadTesterData(doubleMatrix: TDoubleMatrix);
    procedure DataStringPositionChange();
    procedure CheckExistingRows();
    procedure ClassifyTestSet();
    procedure EvaluateClassifier();
    procedure PerformanceAnalysis();
    procedure ClearTestData();
    procedure EvaluationButtonsEnabling();
    procedure InitialValues();
    procedure UpdateStringGrids();
    procedure UpdateTestGraph();
    procedure UpdatePerformanceVisual();
    function ApplyNaiveBayes(TrainingSetIndexes: Array of Integer; testRow: TDoubleArray; testRowIndex: Integer): Integer;
    function SelectMaxProbClass(totalCProb: TDoubleArray): Integer;
    procedure ApplyKFold();


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
  //TM = TESTMATRIX, E = Evaluation
  TMCLASSPERCENT, TESTMATRIX: TDoubleMatrix;
  TMCLASSRESULTS, TMREALCLASS: array of integer;
  TMSELECTEDROW, TMROWSIZE, TMCOLSIZE, IGNORESTART, IGNOREEND, ECORRECT, ETOTAL: integer;
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

  //Cargar archivo automaticamente para pruebas//
  {LoadTesterData(MainForm.LoadCSVFileToMatrix('data_sets\ST2_2Rows.txt'));
  LoadTesterData(MainForm.LoadCSVFileToMatrix('data_sets\ST2_TestSet.txt'));}

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
      //Se agregan los datos a TESTMATRIX
      for i := 0 to TMROWSIZE - 1 do
      begin
        for j := 0 to TMCOLSIZE - 1 do
        begin
          TESTMATRIX[i, j] := doubleMatrix[i + 1, j];
        end;
      end;
      //Se actualiza la parte visual
      InitialValues();
      UpdateStringGrids();
      UpdateTestVisual();
      EvaluationButtonsEnabling();
    end
    else
      raise EConvertError.Create('');
  except
    //Si la estructura del TestSet no corresponde con el DataSet original
    On e1: EConvertError do
      ShowMessage('testset incompatible with dataset');
  end;
end;

procedure TTesterForm.InitialValues();
begin
  SetLength(TMCLASSRESULTS, TMROWSIZE);
  SetLength(TMCLASSPERCENT, TMROWSIZE, MainUnit.DATATAG[Length(MainUnit.DATATAG) - 1]);
  TestChartBarSeries1.Clear;
  TMCURRENTSTATUS := 'NOT_CLASSIFIED';
  SELECTEDROW := 0;
end;

procedure TTesterForm.EvaluateClassifier();
var
  i: integer;
begin
  case EvaluationTypeCB.Text of
    'K-Fold':
    begin
      ApplyKFold();
    end;
    'other':
      ShowMessage('other');
  end;
end;

procedure TTesterForm.ApplyKFold();
var
  //C = Class
  i, j, f, c, k, foldNum, foldRowCount, remaider, foldCorrect, foldTotal, totalC, rowIndex: integer;
  //foldsMatrix = indices que forman parte de cada fold, classSortedMatrix = indices pertenecientes a cada clase
  foldsMatrix, classSortedMatrix: array of array of integer;
  maxRowsPerClass, classRowsUsed: array of integer;
  classPercentage: TDoubleArray;
  foundIndex: Boolean;
begin
  try
    //------------------------Se obtiene una matrix en la que cada i contiene los indices de cada fold---------------------//
    //Se obtiene el numero de folds
    foldNum := StrToInt(FoldsNumberEdit.Text);
    //Se confirma que el rango es valido
    if (0 < foldNum) and (foldNum < MainUnit.DMROWSIZE) then
    begin
      totalC := MainUnit.DATATAG[Length(MainUnit.DATATAG) - 1];

      //Se obtiene el tamaño para cada fold
      SetLength(foldsMatrix, foldNum);
      foldRowCount := MainUnit.DMROWSIZE div foldNum;
      remaider := MainUnit.DMROWSIZE mod foldNum;
      //Se reparte el sobrante sumandole 1 a los primeros folds hasta que se tenga espacio para todos los elementos de DATAMATRIX
      for f := 0 to foldNum - 1 do
      begin
        if (remaider > 0) then
        begin
          SetLength(foldsMatrix[f], foldRowCount + 1);
          remaider -= 1;
        end
        else
          SetLength(foldsMatrix[f], foldRowCount);
      end;

      //Se cuentan ocurrencias de cada clase y se separan todos los valores segun su clase
      SetLength(classPercentage, totalC);
      SetLength(classSortedMatrix, totalC);
      for c := 0 to totalC-1 do
        classPercentage[c] := 0;
      for i := 0 to MainUnit.DMROWSIZE - 1 do
      begin
        //Sumador de recurrencia de clase
        classPercentage[MainUnit.CLASSARRAY[i]] += 1;
        //Se asigna el indice actual a la fila de classSortedMatrix que representa a su clase
        SetLength(classSortedMatrix[MainUnit.CLASSARRAY[i]], Length(classSortedMatrix[MainUnit.CLASSARRAY[i]])+1);
        classSortedMatrix[MainUnit.CLASSARRAY[i],Length(classSortedMatrix[MainUnit.CLASSARRAY[i]])-1] := i;
      end;

      SetLength(maxRowsPerClass, totalC);
      SetLength(classRowsUsed, totalC);
      for c := 0 to totalC - 1 do
      begin
        //Cada suma de ocurrencia de cada clase es dividida entre el total de elementos
        classPercentage[c] := classPercentage[c] / MainUnit.DMROWSIZE;
        //Se obtiene la cantidad de elementos en cada fold de cada clase, manteniendo la proporcion de clase encontrada en DATAMATRIX
        maxRowsPerClass[c] := Ceil(classPercentage[c] * foldRowCount);
      end;

      //Se asignan proporcionalmente los indices a cada fold
      //Recorre cada fold
      for f := 0 to foldNum - 1 do
      begin
        //Se reestablece a 0 el uso de clase en el fold actual
        for c := 0 to totalC - 1 do
          classRowsUsed[c] := maxRowsPerClass[c];
        //Recorre cada espacio disponible en el fold actual
        for i := 0 to Length(foldsMatrix[f]) - 1 do
        begin
          //Se recorre cada clase y se intenta meter un elemento de la misma
          foundIndex := False;
          for c := 0 to totalC - 1 do
          begin
            //Si classSortedMatrix no esta vacia y no se a rebasado el limite de elementos por clase se añade un elemento aleatorio
            if not (Length(classSortedMatrix[c]) = 0) and not (classRowsUsed[c] = 0) then
            begin
              rowIndex := random(Length(classSortedMatrix[c]));
              foldsMatrix[f, i] := classSortedMatrix[c, rowIndex];
              classRowsUsed[c] -= 1;
              //Se recorren los indices para eliminar el valor usado
              for j := rowIndex to Length(classSortedMatrix[c]) - 2 do
                classSortedMatrix[c, j] := classSortedMatrix[c, j + 1];
              SetLength(classSortedMatrix[c], Length(classSortedMatrix[c]) - 1);
              foundIndex := True;
              //ShowMessage(BoolToStr(foundIndex, True));
              Break;
            end;
          end;
          //Si no se encontro ningun indice debido al limite por clase se asigna el primer disponible
          if not (foundIndex) then
            //Se recorren todos los indices de classSortedMatrix hasta encontrar alguno disponible
            for c := 0 to totalC - 1 do
              if not (foundIndex) then
              begin
                for k := 0 to Length(classSortedMatrix[c]) - 1 do
                begin
                  foldsMatrix[f, i] := classSortedMatrix[c, k];
                  //Se recorren los indices para eliminar el valor usado
                  for j := k to Length(classSortedMatrix[c]) - 2 do
                    classSortedMatrix[c, j] := classSortedMatrix[c, j + 1];
                  SetLength(classSortedMatrix[c], Length(classSortedMatrix[c]) - 1);
                  foundIndex := True;
                  break;
                end;
              end
              else
                break;
        end;
      end;



      {TestDataStringGrid.RowCount := 1;
      TestDataStringGrid.ColCount := foldNum;
      for f := 0 to foldNum - 1 do
      begin
        if (Length(foldsMatrix[f]) + 1 > TestDataStringGrid.RowCount) then
          TestDataStringGrid.RowCount := Length(foldsMatrix[f]) + 1;
        for i := 0 to Length(foldsMatrix[f]) - 1 do
          TestDataStringGrid.Cells[f, i + 1] := IntToStr(foldsMatrix[f, i]);;
      end;}

      SetLength(TESTMATRIX, MainUnit.DMROWSIZE, MainUnit.DMCOLSIZE);
      showmessage(inttostr(MainUnit.DMROWSIZE)+' '+inttostr(MainUnit.DMCOLSIZE));
      i := 0;
      for f := 0 to foldNum - 1 do
        for j := 0 to Length(foldsMatrix[f]) - 1 do
        begin
          showmessage(inttostr(foldsMatrix[f, j]));
          TESTMATRIX[i] := MainUnit.DATAMATRIX[foldsMatrix[f, j]];
          i += 1;
        end;
      UpdateStringGrids();


      foldCorrect := 1;
      foldTotal := 1;
      ECORRECT := foldCorrect;
      ETOTAL := foldTotal;
      UpdatePerformanceVisual();
    end
    else
      ShowMessage('invalid k');

  except
    on e1: EConvertError do
      ShowMessage(e1.Message);
    on e2: ERangeError do
      ShowMessage(e2.Message);
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
  i, j: integer;
  DMIndexes: Array of Integer;
begin
  if not (TMCURRENTSTATUS = 'EVALUATING') then
  begin
    IGNORESTART := -1;
    IGNOREEND := -1;
  end;
  case ClassifierTypeCB.Text of
    'Naive Bayes':
    begin
      SetLength(TMCLASSPERCENT, TMROWSIZE, MainUnit.DATATAG[Length(MainUnit.DATATAG) - 1]);
      //Se agregan los indices de todos los elementos en DATAMATRIX
      SetLength(DMIndexes, MainUnit.DMROWSIZE);
      for j := 0 to MainUnit.DMROWSIZE - 1 do
        DMIndexes[j] := j;
      //Recorre todas las filas en TESTMATRIX para aplicarles Naive Bayes
      for i := 0 to Length(TESTMATRIX) - 1 do
      begin
        //Se aplica el algoritmo para todos los elementos
        TMCLASSRESULTS[i] := ApplyNaiveBayes(DMIndexes, TESTMATRIX[i], i);
        ClassStringGrid.Cells[0, i + 1] := IntToStr(TMCLASSRESULTS[i]);
      end;
      TMCURRENTSTATUS := 'CLASSIFIED';
      PerformanceAnalysis();
    end;
    'other':
      ShowMessage('other');
  end;
end;



//Aplica el algoritmo Naive Bayes para encontrar la clase
function TTesterForm.ApplyNaiveBayes(TrainingSetIndexes:Array of Integer; testRow: TDoubleArray; testRowIndex: Integer): Integer;
var
  //C = Clase
  i, j, currentC, totalC, sameValueNum: integer;
  currentClassIndexes: array of integer;
  ColCProb, numericalValues: TDoubleArray;
  mean, deviation, currentCProbInDM: double;
begin
  totalC := MainUnit.DATATAG[Length(MainUnit.DATATAG) - 1];
  //Arreglo del porcentaje en cada columna para la clase actual
  SetLength(ColCProb, TMCOLSIZE);
  ////Recorre todas las clases
  for currentC := 0 to totalC - 1 do
  begin
    //Encuentra los indices en DATAMATRIX que son de la clase siendo evaluada actualmente
    SetLength(currentClassIndexes, 0);
    currentCProbInDM := 0;
    for i := 0 to Length(TrainingSetIndexes) - 1 do
    begin
      if (MainUnit.CLASSARRAY[TrainingSetIndexes[i]] = currentC) then
      begin
        SetLength(currentClassIndexes, Length(currentClassIndexes) + 1);
        currentClassIndexes[Length(currentClassIndexes) - 1] := TrainingSetIndexes[i];
        currentCProbInDM += 1;
      end;
    end;
    //Se obtiene la probabilidad de clase
    currentCProbInDM := currentCProbInDM / Length(TrainingSetIndexes);
    //Recorre todas las columnas
    for j := 0 to MainUnit.DMCOLSIZE - 1 do
    begin
      //Evaluacion si la columna es de tipo Continuo
      if (MainUnit.DATATAG[j] = 0) then
      begin
        //Se obtienen todos los elementos de esta columna que pertenecen a la clase currentC
        SetLength(numericalValues, 0);
        for i := 0 to Length(currentClassIndexes) - 1 do
        begin
            SetLength(numericalValues, Length(numericalValues) + 1);
            numericalValues[Length(numericalValues) - 1] := MainUnit.DATAMATRIX[currentClassIndexes[i], j];
        end;
        //Si hay por lo menos un elemento que pertenece a la clase se evalua
        if not (Length(numericalValues) = 0) then
        begin
          mean := MainForm.GetMean(numericalValues);
          deviation := MainForm.GetStandarDev(numericalValues, mean);
          //Se evita error si la desviacion estandar es igual a 0
          if (deviation = 0) then
            ColCProb[j] := 1e-308
          else
            ColCProb[j] := (1 / (Sqrt(2 * Pi) * deviation)) * Exp(-(Power((testRow[j] - mean), 2) / (2 * Power(deviation, 2))));
        end
        else
          //Si no hay elementos de la clase actual se le da probabilidad 0
          ColCProb[j] := 0;
      end
      //Evaluacion si la columna es de tipo Nominal
      else
      begin
        //Cuenta cuantas columnas de la clase actual tienen el mismo valor que la fila siendo evaluada
        sameValueNum := 0;
        for i := 0 to Length(currentClassIndexes) - 1 do
        begin
            if ( MainUnit.DATAMATRIX[currentClassIndexes[i], j] = testRow[j]) then
               begin
               sameValueNum += 1;
               end;
        end;
        if (Length(currentClassIndexes) = 0) then
          ColCProb[j] := 0
        else
          ColCProb[j] := sameValueNum / Length(currentClassIndexes);
      //Si el valor es 0 se le asigna 1e-4 para evitar que anule los demas al multiplicar
      end;
      if (ColCProb[j] = 0) then
          ColCProb[j] := 1e-308;
    end;
    //Se agrega valor neutro de multiplicacion
    TMCLASSPERCENT[i, currentC] := 1;
    //Se obtiene la probabilidad conjunta de todas las probabilidades de atributo
    for j := 0 to TMCOLSIZE - 1 do
    begin
      TMCLASSPERCENT[i, currentC] := TMCLASSPERCENT[i, currentC] * ColCProb[j];
      //Si el valor es demasiado pequeño se regresa a el limite de 1e-200 para que el programa no lo convierta en 0
      if (TMCLASSPERCENT[i, currentC] < 1e-308) then
          TMCLASSPERCENT[i, currentC] := 1e-308;
    end;
    //Se multiplica por la probabilidad de clase
    TMCLASSPERCENT[i, currentC] := TMCLASSPERCENT[i, currentC] * currentCProbInDM;
  end;
  result := SelectMaxProbClass(TMCLASSPERCENT[i]);
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


procedure TTesterForm.PerformanceAnalysis();
var
  i: integer;
begin
  if (TSHASCLASS) then
  begin
    ECORRECT := 0;
    ETOTAL := 0;
    for i := 0 to Length(TMCLASSRESULTS) - 1 do
    begin
      ETOTAL += 1;
      if (TMCLASSRESULTS[i] = TMREALCLASS[i]) then
        ECORRECT += 1;
    end;
    if not (TMCURRENTSTATUS = 'EVALUATING') then
      UpdatePerformanceVisual();
  end;
end;

procedure TTesterForm.UpdatePerformanceVisual();
var
  error, accuracy : float;
begin
  accuracy := (ECORRECT / ETOTAL) * 100;
  error := (ETOTAL - ECORRECT) / ETOTAL;
  accuracy := Round(accuracy * 100) / 100;
  error := Round(error * 100) / 100;
  PerformanceLabel.Caption := 'Accuracy = '+FloatToStr(accuracy)+'     Error = '+FloatToStr(error);
end;

procedure TTesterForm.UpdateTestVisual();
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

//Actualiza la grafica de barras que muestra porcentaje de clase
procedure TTesterForm.UpdateTestGraph();
var
  j: Integer;
begin
  TestChartBarSeries1.Clear;
  TestChartBarSeries1.BarWidthPercent := 80;
  TestChartBarSeries1.Marks.Visible := False;
  TestChartBarSeries1.Marks.Style := smsLabel;
  TestChartBarSeries1.Marks.LabelBrush.Color := clWhite;
  TestChartBarSeries1.Marks.Frame.Visible := False;
  for j := 0 to Length(TMCLASSPERCENT[0]) - 1 do
  begin
    //Se redondea para evitar numeros demasiado pequeños ya que TCharBart no acepta tamaños como 1E-300
    TestChartBarSeries1.AddXY(j, Round(TMCLASSPERCENT[SELECTEDROW, j]*Power(10,10))/(Power(10,10)), IntToStr(j), MainForm.RandomRGB(60, 90, 60, 140, 150, 150));
  end;
end;
procedure TTesterForm.ClearTestData();
begin
  //Limpiar datos
  SetLength(TESTMATRIX, 0, 0);
  SetLength(TMCLASSRESULTS, 0);
  SetLength(TMREALCLASS, 1);
  TMREALCLASS[1] := -1;
  TMROWSIZE := 0;
  TMCOLSIZE := 0;

  //Limpiar StringGrids
  TestDataStringGrid.Clear;
  RowNumberStringGrid.Clear;
  ColNumberStringGrid.Clear;
  ClassStringGrid.Clear;
  ColClassStringGrid1.Clear;

  //Desactivar botones
  ClassifierTypeCB.Enabled := False;
  ClassificationBtn.Enabled := False;
  EvaluationButtonsEnabling();

  TMCURRENTSTATUS := 'NONE';
end;

procedure TtesterForm.EvaluationButtonsEnabling();
begin
  if (MainUnit.CURRENTGRAPH = 'NONE') then
  begin
    EvaluateBtn.Enabled := False;
    EvaluationTypeCB.Enabled := False;
  end
  else
  begin
    EvaluateBtn.Enabled := True;
    EvaluationTypeCB.Enabled := True;
  end;
end;

procedure TTesterForm.DataStringPositionChange();
begin
  ColNumberStringGrid.LeftCol := TestDataStringGrid.LeftCol;
  RowNumberStringGrid.TopRow := TestDataStringGrid.TopRow - 1;
  ClassStringGrid.TopRow := TestDataStringGrid.TopRow;
  if (TMCURRENTSTATUS = 'CLASSIFIED') or ((TMCURRENTSTATUS = 'EVALUATING')) then
     UpdateTestGraph();
end;
 
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<FUNCIONES<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<//




//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>EVENTOS>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//


procedure TTesterForm.ClassificationBtnClick(Sender: TObject);
begin
  ClassifyTestSet();
end;

procedure TTesterForm.FormActivate(Sender: TObject);
begin
   LoadTesterData(MainForm.LoadCSVFileToMatrix('data_sets\ST2_TestSet.txt'));
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

procedure TTesterForm.ClassStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
begin
  case TMCURRENTSTATUS of
    'CLASSIFIED':
    begin
      if (aRow = SELECTEDROW + 1) and (StrToInt(ClassStringGrid.Cells[acol, aRow]) = TMREALCLASS[aRow - 1]) then
        ClassStringGrid.Canvas.Brush.Color := RGBToColor(128, 199, 128)
      else if (aRow = SELECTEDROW + 1) then
        ClassStringGrid.Canvas.Brush.Color := RGBToColor(226, 226, 226)
      else if  (StrToInt(ClassStringGrid.Cells[acol, aRow]) = TMREALCLASS[aRow - 1]) then
        ClassStringGrid.Canvas.Brush.Color := RGBToColor(158, 247, 158);
    end;
    'NOT_CLASSIFIED':
    begin
      if (aRow = SELECTEDROW + 1) then
        ClassStringGrid.Canvas.Brush.Color := RGBToColor(226, 226, 226);
    end;
  end;
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

