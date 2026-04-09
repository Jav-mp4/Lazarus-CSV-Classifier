unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls, Grids,
  ExtCtrls, TAGraph, TASeries, TATypes, TAChartUtils,
  TAMultiSeries, Math;

type
  TDoubleMatrix = array of array of double;
  TDoubleArray = array of double;


  { TForm1 }

  TForm1 = class(TForm)
    ClearDataBtn: TButton;
    CurrentRowEdit: TEdit;
    HorzBarImage: TImage;
    VertBarImage: TImage;
    XYTitleLabel: TLabel;
    RowRangeLabel: TLabel;
    VerticalBarlBtn: TButton;
    DeleteRowBtn: TButton;
    DownScrollBtn: TButton;
    UpScrollBtn: TButton;
    DataChartBoxAndWhiskerSeries1: TBoxAndWhiskerSeries;
    RightScrollBtn: TButton;
    LeftScrollBtn: TButton;
    DataChartBarSeries1: TBarSeries;
    DataStringGrid: TStringGrid;
    ClasesCheckBox: TCheckBox;
    ColNumberStringGrid: TStringGrid;
    RowNumberStringGrid: TStringGrid;
    SymbolsImage: TImage;
    ShowLineCheckBox: TCheckBox;
    ColRangeLabel: TLabel;
    ScatterPlotTB: TToggleBox;
    BarChartTB: TToggleBox;
    StatisticsStringGrid: TStringGrid;
    BoxPlotTB: TToggleBox;
    XYCOLlBtn: TButton;
    DataChartLineSeries1: TLineSeries;
    DataChart: TChart;
    XColEdit: TEdit;
    YColEdit: TEdit;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    LoadCSVMenuItem: TMenuItem;
    OpenDialog1: TOpenDialog;
    procedure BoxPlotTBChange(Sender: TObject);
    procedure ClearDataBtnClick(Sender: TObject);
    procedure DataStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
    procedure DataStringGridSelection(Sender: TObject; aCol, aRow: integer);
    procedure LoadCSVFile(root: string);

    //Funciones
    procedure GenerateScatterPlot();
    procedure GenerateBarChart();
    procedure ClearData();
    procedure DeleteRow();
    procedure GenerateBoxPlot(ColIndex: integer; boxplotNum: integer);
    procedure RowNumberStringGridSelection(Sender: TObject; aCol, aRow: integer);
    procedure SortColumn(colIndex: integer);
    procedure DataStringPositionChange();
    function IsInsideRange(index: integer; range: integer): boolean;
    function SortedMatrixToArray(colIndex: integer): TDoubleArray;
    function SortedMatrixRealValue(i, j: integer): double;
    function GetMean(colIndex: integer): double;
    function GetMedian(sortedArray: TDoubleArray): double;
    function GetStandarDev(colIndex: integer; mean: double): double;
    function Discretization(colIndex: integer): TDoubleMatrix;
    function RandomRGB(RMin, RMax, GMin, GMax, BMin, BMax: integer): TColor;

    //Eventos
    procedure RowNumberStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
    procedure DeleteRowBtnClick(Sender: TObject);
    procedure DownScrollBtnClick(Sender: TObject);
    procedure LeftScrollBtnClick(Sender: TObject);
    procedure UpdateDataChart();
    procedure ClasesCheckBoxChange(Sender: TObject);
    procedure BarChartTBChange(Sender: TObject);
    procedure ScatterPlotTBChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadCSVMenuItemClick(Sender: TObject);
    procedure RightScrollBtnClick(Sender: TObject);
    procedure ShowLineCheckBoxChange(Sender: TObject);
    procedure UpScrollBtnClick(Sender: TObject);
    procedure XYCOLlBtnClick(Sender: TObject);

  private

  public

  end;

var
  Form1: TForm1;
  //DATASTATSMATRIX Significado de indices:  0=Media, 1=Mediana, 2=Desviacion estandar
  DATAMATRIX, STATSMATRIX: TDoubleMatrix;
  SORTEDMATRIX: array of array of integer;
  DATATAG, CLASSARRAY: array of integer;
  DMROWSIZE, DMCOLSIZE, XCOLINDEX, YCOLINDEX, SELECTEDROW: integer;
  CURRENTGRAPH: string;

implementation

{$R *.lfm}

{ TForm1 }




//-------------------------- Valores de inicio ------------------------------//
procedure TForm1.FormCreate(Sender: TObject);
var
  back_color: TColor;
begin
     {back_color:=RGBToColor(250, 250, 250);
     Form1.Color:=back_color;
     RowNumberStringGrid.Color:=back_color;
     ColNumberStringGrid.Color:=back_color;
     DataChart.Color:=back_color;}

  SELECTEDROW := -1;
  VertBarImage.Canvas.Brush.Color := RGBToColor(226, 226, 226);
  VertBarImage.Canvas.FillRect(VertBarImage.ClientRect);
  HorzBarImage.Canvas.Brush.Color := RGBToColor(226, 226, 226);
  HorzBarImage.Canvas.FillRect(HorzBarImage.ClientRect);
  DataChartLineSeries1.Clear;
  DataChartLineSeries1.Pointer.Style := psCircle;
  DataChartLineSeries1.Pointer.Brush.Color := Clred;
  DataChartLineSeries1.Pointer.Pen.Style := psClear;
  DataChartLineSeries1.Pointer.Visible := True;
  DataChartLineSeries1.ShowLines := False;
  SymbolsImage.Picture.LoadFromFile('StatsSymbols.jpg');
  CURRENTGRAPH := 'NONE';

  //Cargar archivo automaticamente para pruebas//
  XCOLINDEX := 0;
  YCOLINDEX := 1;
  OpenDialog1.InitialDir := ExtractFilePath('project1.exe') + '\data_sets';
  LoadCSVFile('data_sets\ST2_test_short_1.txt');
end;

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>FUNCIONES>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//

//------------------------Cargar Archivo-----------------------------//
procedure TForm1.LoadCSVFile(root: string);
var
  i, j, c, file_colsize, file_rowsize: integer;
  txt_line, txt_number: string;
  full_file: TextFile;
begin

  try
    try
      AssignFile(full_file, root);
      Reset(full_file);
      //Se reserva espacio para las columnas
      SetLength(DATATAG, 100);
      DataStringGrid.Clean;
      DataStringGrid.ColCount := 100;
      DataStringGrid.rowCount := 1;
      file_colsize := 0;
      //Leemos la primera linea para obtener las etiquetas
      ReadLn(full_file, txt_line);
      txt_number := '';
      for c := 1 to Length(txt_line) do
      begin
        if (txt_line[c] = ',') or (c = Length(txt_line)) then
        begin
          if (c = Length(txt_line)) then
            txt_number += txt_line[c];
          //Se aumenta tamaño si se rebaso el tamaño reservado en el inicio
          if (file_colsize + 1 > Length(DATATAG)) then
            SetLength(DATATAG, file_colsize + 100);
          DataStringGrid.ColCount := file_colsize + 100;
          DATATAG[file_colsize] := StrToInt(txt_number);
          DataStringGrid.Cells[file_colsize, 0] := txt_number;
          file_colsize += 1;
          txt_number := '';
        end
        else
          txt_number += txt_line[c];
      end;

      //Asigna espacio real de columnas
      SetLength(DATATAG, file_colsize);
      DataStringGrid.ColCount := file_colsize;

      //Se Reserva espacio para las filas
      SetLength(DATAMATRIX, 500, file_colsize);
      SetLength(CLASSARRAY, 500);
      DataStringGrid.RowCount := 500;
      file_rowsize := 1;

      //Se agregan los demas valores
      while not EOF(full_file) do
      begin
        ReadLn(full_file, txt_line);
        j := 0;
        for c := 1 to Length(txt_line) do
        begin
          if (txt_line[c] = ',') or (c = Length(txt_line)) then
          begin
            if (c = Length(txt_line)) then
              txt_number += txt_line[c];
            //Se aumenta tamaño si se rebaso el tamaño reservado en el inicio
            if (file_rowsize + 1 > Length(DATAMATRIX)) then
              SetLength(DATAMATRIX, file_rowsize + 100);
            //Si es la ultima columna se asigna el valor en CLASSMATRIX de lo contrario se asigna a DATAMATRIX
            if (j + 1 < file_colsize) then
              DATAMATRIX[file_rowsize - 1, j] :=
                StrToFloat(txt_number)
            else
              CLASSARRAY[file_rowsize - 1] :=
                StrToInt(txt_number);
            DataStringGrid.Cells[j, file_rowsize] :=
              txt_number;
            j += 1;
            txt_number := '';
          end
          else
            txt_number += txt_line[c];
        end;
        file_rowsize += 1;
      end;
      SetLength(DATAMATRIX, file_rowsize);
      SetLength(CLASSARRAY, file_rowsize);
      DataStringGrid.RowCount := file_rowsize;

      DMCOLSIZE := file_colsize - 1;//Tamaño sin la primera fila
      DMROWSIZE := file_rowsize - 1;//Tamaño sin la ultima columna
      SetLength(STATSMATRIX, 3, DMCOLSIZE);
      SetLength(SORTEDMATRIX, DMROWSIZE, DMCOLSIZE);

      StatisticsStringGrid.Clean;
      ColNumberStringGrid.Clean;
      RowNumberStringGrid.Clean;
      StatisticsStringGrid.RowCount := 3;
      StatisticsStringGrid.ColCount := DMCOLSIZE + 1;
      ColNumberStringGrid.RowCount := 1;
      ColNumberStringGrid.ColCount := DMCOLSIZE + 1;
      RowNumberStringGrid.ColCount := 1;
      RowNumberStringGrid.RowCount := DMROWSIZE;

      ColNumberStringGrid.LeftCol := 0;
      RowNumberStringGrid.LeftCol := 0;
      DataStringGrid.LeftCol := 0;
      StatisticsStringGrid.LeftCol := 0;

      //Se llena el StringGrid que contiene el indice de las columnas y el de las filas
      for j := 0 to DMCOLSIZE - 1 do
        ColNumberStringGrid.Cells[j, 0] := IntToStr(j + 1);
      ColNumberStringGrid.Cells[DMCOLSIZE, 0] := 'Class';
      for i := 0 to DMROWSIZE - 1 do
        RowNumberStringGrid.Cells[0, i] := IntToStr(i + 1);

      //Agregar -1 a toda la primera fila de SORTEDMATRIX para indicar que no estan ordenadas
      for j := 0 to DMCOLSIZE - 1 do
        SORTEDMATRIX[0, j] := -1;

      //Obtiene los valores Media,Mediana y Desviacion para cada columna
      for j := 0 to DMCOLSIZE - 1 do
      begin
        if (DATATAG[j] = 0) then
        begin
          STATSMATRIX[0, j] := GetMean(j);
          StatisticsStringGrid.Cells[j, 0] :=
            FloatToStr(Round(STATSMATRIX[0, j] * 100) / 100);
          STATSMATRIX[1, j] := GetMedian(SortedMatrixToArray(j));
          StatisticsStringGrid.Cells[j, 1] :=
            FloatToStr(STATSMATRIX[1, j]);
          STATSMATRIX[2, j] := GetStandarDev(j, STATSMATRIX[0, j]);
          StatisticsStringGrid.Cells[j, 2] :=
            FloatToStr(Round(STATSMATRIX[2, j] * 100) / 100);
        end;
      end;
      //Toma el valor de la primera fila para utilizar en el Chart
      XCOLINDEX := 0;
      YCOLINDEX := 0;
      SELECTEDROW := 0;
      XColEdit.Text := IntToStr(XCOLINDEX + 1);
      YColEdit.Text := IntToStr(YCOLINDEX + 1);
      ColRangeLabel.Caption := 'Columns ' + IntToStr(DMCOLSIZE);
      RowRangeLabel.Caption := 'Rows ' + IntToStr(DMROWSIZE);

      XYCOLlBtn.Enabled := True;
      ScatterPlotTB.Enabled := True;
      BarChartTB.Enabled := True;
      BoxPlotTB.Enabled := True;
      DeleteRowBtn.Enabled := True;
    except
      On e1: EFOpenError do
        ShowMessage(e1.Message);
      On e2: EConvertError do
        ShowMessage('Caracteres encontrados en espacio de datos numericos');
      On e3: EAccessViolation do
        ShowMessage(e3.Message);
    end;
  finally
    CloseFile(full_file);
  end;
end;



//-------------------Actualizar grafica y cambiar tipo---------------//
procedure TForm1.UpdateDataChart();
var
  i, j: integer;
begin
  DataChartLineSeries1.Clear;
  DataChartBarSeries1.Clear;
  DataChartBoxAndWhiskerSeries1.Clear;
  case CURRENTGRAPH of
    'NONE':
    begin

    end;
    'SCATTERPLOT':
      GenerateScatterPlot();
    'BARCHART':
      GenerateBarChart();
    'BOXPLOT':
    begin
      j := 0;
      for i := 0 to DMCOLSIZE - 1 do
      begin
        if (DATATAG[i] = 0) then
        begin
          GenerateBoxPlot(i, j);
          j += 1;
        end;
      end;
    end;
  end;
end;


//------------------------Grafica de dispersion-------------------------------//
procedure TForm1.GenerateScatterPlot();
var
  i: integer;
begin
  if ShowLineCheckBox.Checked then
  begin
    DataChartLineSeries1.ShowLines := True;
    if not (DATATAG[XCOLINDEX] = 0) then
      SortColumn(XCOLINDEX);
    for i := 0 to DMROWSIZE - 1 do
      DataChartLineSeries1.AddXY(SortedMatrixRealValue(i, XCOLINDEX),
        DATAMATRIX[SORTEDMATRIX[i, XCOLINDEX], YCOLINDEX], '',
        RandomRGB(60, 90, 60, 140, 150, 150));
  end
  else
  begin
    DataChartLineSeries1.ShowLines := False;
    for i := 0 to DMROWSIZE - 1 do
      DataChartLineSeries1.AddXY(DATAMATRIX[i, XCOLINDEX],
        DATAMATRIX[i, YCOLINDEX], '', RandomRGB(60, 90, 60, 140, 150, 150));
  end;

end;

//------------------------Grafica de barras-------------------------------//
procedure TForm1.GenerateBarChart();
var
  i, j, intervalNum: integer;
  min, max, intervalWidth: double;
  fieldsDoubleMatrix: TDoubleMatrix;
  fieldsIntArray: array of integer;
begin
  DataChartBarSeries1.BarWidthPercent := 70;
  DataChartBarSeries1.Marks.Visible := True;
  DataChartBarSeries1.Marks.Style := smsLabel;
  DataChartBarSeries1.Marks.LabelBrush.Color := clWhite;
  DataChartBarSeries1.Marks.Frame.Visible := False;
  if ClasesCheckBox.Checked then
  begin
    SetLength(fieldsIntArray, DATATAG[DMCOLSIZE]);
    for i := 0 to Length(fieldsIntArray) - 1 do
      fieldsIntArray[i] := 0;
    for i := 0 to DMROWSIZE - 1 do
    begin
      for j := 0 to Length(fieldsIntArray) - 1 do
      begin
        if CLASSARRAY[i] = j then
          fieldsIntArray[j] += 1;
      end;
    end;
    for j := 0 to Length(fieldsIntArray) - 1 do
      DataChartBarSeries1.AddXY(j, fieldsIntArray[j],
        IntToStr(j), RandomRGB(60, 90, 60, 140, 150, 150));
  end
  else
  begin
    if (DATATAG[XCOLINDEX] = 0) then
    begin
      //Crear grafica de barras de una columna con valores discretos
      SortColumn(XCOLINDEX);
      intervalNum := 6;
      SetLength(fieldsDoubleMatrix, intervalNum, 2);
      //Obtenermos el tamaño de los intervalos y los valores de cada uno
      min := SortedMatrixRealValue(0, XCOLINDEX);
      max := SortedMatrixRealValue(DMROWSIZE - 1, XCOLINDEX);
      intervalWidth := (max - min) / 1000;
      min -= intervalWidth;
      max += intervalWidth;
      intervalWidth := (max - min) / intervalNum;
      //Generar los intervalos usando la cota superior para deifinir a cada uno
      for i := 0 to intervalNum - 1 do
      begin
        fieldsDoubleMatrix[i, 0] := min + (intervalWidth * (i + 1));
        fieldsDoubleMatrix[i, 1] := 0;
      end;

      for i := 0 to DMROWSIZE - 1 do
      begin
        for j := 0 to intervalNum - 1 do
        begin
          if ((fieldsDoubleMatrix[j, 0] - intervalWidth) <= SortedMatrixRealValue(i, XCOLINDEX)) and
            (SortedMatrixRealValue(i, XCOLINDEX) < fieldsDoubleMatrix[j, 0]) then
          begin
            fieldsDoubleMatrix[j, 1] += 1;
          end;
        end;
      end;

      for j := 0 to intervalNum - 1 do
        DataChartBarSeries1.AddXY(fieldsDoubleMatrix[j, 0] - (intervalWidth / 2), fieldsDoubleMatrix[j, 1],
          FloatToStr(Round((fieldsDoubleMatrix[j, 0] - intervalWidth) * 100) / 100) + '-' + FloatToStr(Round(fieldsDoubleMatrix[j, 0] * 100) / 100),
          RandomRGB(60, 90, 60, 140, 150, 150));
    end
    else
    begin
      SetLength(fieldsIntArray, DATATAG[XCOLINDEX]);
      for i := 0 to Length(fieldsIntArray) - 1 do
        fieldsIntArray[i] := 0;
      for i := 0 to DMROWSIZE - 1 do
      begin
        for j := 0 to Length(fieldsIntArray) - 1 do
        begin
          if DATAMATRIX[i, XCOLINDEX] = j then
            fieldsIntArray[j] += 1;
        end;
      end;
      for j := 0 to Length(fieldsIntArray) - 1 do
        DataChartBarSeries1.AddXY(
          j, fieldsIntArray[j], IntToStr(j),
          RandomRGB(60, 90, 60, 140, 150, 150));
    end;
  end;
end;

//-------------------------Grafica de Caja-------------------------------//
procedure TForm1.GenerateBoxPlot(colIndex: integer; boxplotNum: integer);
var
  i, tempSize: integer;
  tempArray: TDoubleArray;
  Min, Q1, Median, Q3, Max: double;
begin
  Min := SortedMatrixRealValue(0, colIndex);
  Max := SortedMatrixRealValue(DMROWSIZE - 1, colIndex);
  Median := STATSMATRIX[1, colIndex];

  if (DMROWSIZE mod 2 = 0) then
  begin
    tempSize := DMROWSIZE div 2;
    setLength(tempArray, tempSize);
    for i := 0 to tempSize - 1 do
    begin
      tempArray[i] := SortedMatrixRealValue(i, colIndex);
    end;
    Q1 := GetMedian(tempArray);
    for i := 0 to tempSize - 1 do
    begin
      tempArray[i] := SortedMatrixRealValue(i + tempsize, colIndex);
    end;
    Q3 := GetMedian(tempArray);
  end
  else
  begin
    tempSize := (DMROWSIZE + 1) div 2;
    setLength(tempArray, tempSize);
    for i := 0 to tempSize - 1 do
    begin
      tempArray[i] := SortedMatrixRealValue(i, colIndex);
    end;
    Q1 := GetMedian(tempArray);
    for i := 0 to tempSize - 1 do
    begin
      tempArray[i] := SortedMatrixRealValue(i + tempsize - 1, colIndex);
    end;
    Q3 := GetMedian(tempArray);
  end;

  DataChartBoxAndWhiskerSeries1.AddXY(boxplotNum, Min, Q1, Median,
    Q3, Max, '', RandomRGB(60, 90, 60, 140, 150, 150));
end;

//-------------------------Limpiar Datos-------------------------------//
procedure TForm1.ClearData();
begin
  SetLength(DATAMATRIX, 0, 0);
  SetLength(STATSMATRIX, 0, 0);
  SetLength(SORTEDMATRIX, 0, 0);
  SetLength(DATATAG, 0);
  SetLength(CLASSARRAY, 0);
  DMROWSIZE := -1;
  DMCOLSIZE := -1;
  XCOLINDEX := -1;
  YCOLINDEX := -1;
  SELECTEDROW := -1;

  XYCOLlBtn.Enabled := False;

  ScatterPlotTB.Checked := False;
  ScatterPlotTB.Enabled := False;

  BarChartTB.Checked := False;
  BarChartTB.Enabled := False;

  BoxPlotTB.Checked := False;
  BoxPlotTB.Enabled := False;
  DeleteRowBtn.Enabled := False;

  DataStringGrid.Clear;
  RowNumberStringGrid.Clear;
  ColNumberStringGrid.Clear;
  StatisticsStringGrid.Clear;
end;



//Convertir indices de columna en SORTEDMATRIX a columna real y devolverla en TDoubleArray
function TForm1.SortedMatrixToArray(colIndex: integer): TDoubleArray;
var
  sortedArray: TDoubleArray;
  i: integer;
begin
  if (SORTEDMATRIX[0, colIndex] = -1) then
    SortColumn(colIndex);
  SetLength(sortedArray, DMROWSIZE);
  for i := 0 to DMROWSIZE - 1 do
  begin
    sortedArray[i] := SortedMatrixRealValue(i, colIndex);
  end;
  Result := sortedArray;
end;

//Valor real del indice en SORTEDMATRIX
function TForm1.SortedMatrixRealValue(i, j: integer): double;
begin
  Result := DATAMATRIX[(SORTEDMATRIX[i, j]), j];
end;


//Discretization de valores en una columna
function TForm1.Discretization(colIndex: integer): TDoubleMatrix;
var
  intervalNum, i: integer;
  intervalWidth: double;
  min, max: double;
  newArray: TDoubleMatrix;
begin
  intervalNum := 6;
  SetLength(newArray, intervalNum, 2);
  min := DATAMATRIX[0, colIndex];
  max := DATAMATRIX[DMCOLSIZE - 1, colIndex];
  intervalWidth := (max - min) / intervalNum;
  for i := 0 to intervalNum - 1 do
  begin
    newArray[i, 0] := min + (intervalWidth * i);
    newArray[i, 1] := 0;
  end;
  for i := 0 to intervalNum - 1 do
  begin
    if (newArray[i, 0] <= DATAMATRIX[i, colIndex]) and (DATAMATRIX[i, colIndex] > newArray[i, 0] + intervalWidth) then
      newArray[i, 1] += 1;
  end;
  Result := newArray;
end;

//Ordenar Columna en SORTEDMATRIX
procedure TForm1.SortColumn(colIndex: integer);
var
  temp: integer;
  i, k: integer;
begin
  if (SORTEDMATRIX[0, colIndex] = -1) then
  begin
    for i := 0 to DMROWSIZE - 1 do
      SORTEDMATRIX[i, colIndex] := i;
    for i := 0 to DMROWSIZE - 2 do
    begin
      for k := 0 to DMROWSIZE - 2 - i do
      begin
        if (DATAMATRIX[(SORTEDMATRIX[k, colIndex]), colIndex] > DATAMATRIX[(SORTEDMATRIX[k + 1, colIndex]), colIndex]) then
        begin
          temp := SORTEDMATRIX[k, colIndex];
          SORTEDMATRIX[k, colIndex] :=
            SORTEDMATRIX[k + 1, colIndex];
          SORTEDMATRIX[k + 1, colIndex] := temp;
        end;

      end;
    end;
  end;

end;


//Obtener la Media de una columna
function TForm1.GetMean(colIndex: integer): double;
var
  i: integer;
  mean: double;
begin
  mean := 0;
  for i := 0 to DMROWSIZE - 1 do
  begin
    mean += DATAMATRIX[i, colIndex];
  end;
  mean := mean / DMROWSIZE;
  Result := mean;
end;

//Obtener la Mediana de un TDoubleArray
function TForm1.GetMedian(sortedArray: TDoubleArray): double;
var
  rowSize: integer;
begin
  rowSize := Length(sortedArray) - 1;
  //Se da el tamaño real en cuanto a los indices del arreglo para facilitar operaciones
  if (rowSize + 1 mod 2 = 0) then //Se compara cantidad de datos
    Result := (sortedArray[rowSize div 2] + sortedArray[(rowSize div 2) + 1]) / 2

  else
    Result := sortedArray[(rowSize + 1) div 2];
end;

//Obtener la desviacion estandar
function TForm1.GetStandarDev(colIndex: integer; mean: double): double;
var
  deviation: double;
  i: integer;
begin
  deviation := 0;
  for i := 0 to DMROWSIZE - 1 do
  begin
    deviation += Power((DATAMATRIX[i, colIndex] - mean), 2);
  end;
  deviation := Sqrt(deviation / DMROWSIZE);
  Result := deviation;
end;

function TForm1.RandomRGB(RMin, RMax, GMin, GMax, BMin, BMax: integer): TColor;
begin
  Result := RGBToColor(Random(RMax - RMin) + RMin, Random(GMax - GMin) + GMin, Random(BMax - BMin) + BMin);
end;

procedure TForm1.DataStringPositionChange();
begin
  ColNumberStringGrid.LeftCol := DataStringGrid.LeftCol;
  StatisticsStringGrid.LeftCol := DataStringGrid.LeftCol;
  RowNumberStringGrid.TopRow := DataStringGrid.TopRow - 1;
  if (DMROWSIZE > 13) then
    VerticalBarlBtn.Top :=
      Round(((DownScrollBtn.Top) - (UpScrollBtn.Top + UpScrollBtn.Height)) * ((DataStringGrid.TopRow) / (DMROWSIZE - 12))) +
      UpScrollBtn.Top + UpScrollBtn.Height - VerticalBarlBtn.Height;
end;

procedure TForm1.DeleteRow();
var
  rowToDelete, i, j: integer;
  rowWasFound: boolean;
begin
  try

    if (IsInsideRange(StrToInt(CurrentRowEdit.Text), DMROWSIZE)) then
    begin
      rowToDelete := StrToInt(CurrentRowEdit.Text) - 1;
      for i := rowToDelete to DMROWSIZE - 2 do
      begin
        for j := 0 to DMCOLSIZE - 1 do
        begin
          DATAMATRIX[i, j] := DATAMATRIX[i + 1, j];
          DataStringGrid.Cells[j, i + 1] := DataStringGrid.Cells[j, i + 2];
        end;
      end;


      for j := 0 to DMCOLSIZE - 1 do
      begin
        rowWasFound := False;
        for i := 0 to DMROWSIZE - 2 do
        begin
          if (rowWasFound or (rowToDelete = SORTEDMATRIX[i, j])) then
            if (rowWasFound) then
              SORTEDMATRIX[i, j] := SORTEDMATRIX[i + 1, j]
            else
              begin
                rowWasFound := True;
                SORTEDMATRIX[i, j] := SORTEDMATRIX[i + 1, j];
              end;
          if (SORTEDMATRIX[i, j] > rowToDelete) then
             SORTEDMATRIX[i, j] := SORTEDMATRIX[i, j]-1;
        end;
      end;


      DMROWSIZE := DMROWSIZE - 1;
      SetLength(DATAMATRIX, DMROWSIZE);
      SetLength(SORTEDMATRIX, DMROWSIZE);
      RowNumberStringGrid.RowCount := RowNumberStringGrid.RowCount - 1;
      DataStringGrid.RowCount := DataStringGrid.RowCount - 1;
      UpdateDataChart();
    end
    else
      raise ERangeError.Create('invalid index');
  except
    on e1: EConvertError do
      ShowMessage(e1.Message);
    on e2: ERangeError do
      ShowMessage(e2.Message);
  end;
end;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<FUNCIONES<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<//




//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>EVENTOS>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//



procedure TForm1.DeleteRowBtnClick(Sender: TObject);
begin
  DeleteRow();
end;

//Seleccion de Fila y coloreado de celdas
procedure TForm1.RowNumberStringGridSelection(Sender: TObject; aCol, aRow: integer);
begin
  SELECTEDROW := RowNumberStringGrid.Row;
  CurrentRowEdit.Text := IntToStr(SELECTEDROW + 1);
  //DataStringGrid.TopRow:=RowNumberStringGrid.TopRow+1;
  DataStringGrid.Invalidate;
  RowNumberStringGrid.Invalidate;

end;

procedure TForm1.RowNumberStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
begin
  if (aRow = SELECTEDROW) then
    RowNumberStringGrid.Canvas.Brush.Color := RGBToColor(198, 198, 198);
end;


procedure TForm1.DataStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
begin
  if (aRow = SELECTEDROW + 1) then
    DataStringGrid.Canvas.Brush.Color := RGBToColor(226, 226, 226);
end;


procedure TForm1.LoadCSVMenuItemClick(Sender: TObject);
begin
  try
    OpenDialog1.Execute;
    LoadCSVFile(OpenDialog1.FileName);
  except
    On e3: EAccessViolation do
      ShowMessage(e3.Message);
  end;
end;




//Actualizacion de StringGrids con respecto a posicion de DataStringGrid


procedure TForm1.DataStringGridSelection(Sender: TObject; aCol, aRow: integer);
begin
  DataStringPositionChange();
end;



procedure TForm1.LeftScrollBtnClick(Sender: TObject);
begin
  if (DataStringGrid.LeftCol > 0) then
    DataStringGrid.LeftCol := DataStringGrid.LeftCol - 1;
  DataStringPositionChange();
end;

procedure TForm1.RightScrollBtnClick(Sender: TObject);
begin
  if (DataStringGrid.LeftCol < DataStringGrid.ColCount - 6) then
    DataStringGrid.LeftCol := DataStringGrid.LeftCol + 1;
  DataStringPositionChange();
end;

procedure TForm1.UpScrollBtnClick(Sender: TObject);
begin
  if (DataStringGrid.TopRow > 0) then
    DataStringGrid.TopRow := DataStringGrid.TopRow - 1;
  DataStringPositionChange();
end;


procedure TForm1.DownScrollBtnClick(Sender: TObject);
begin
  if (DataStringGrid.TopRow > DataStringGrid.TopRow - 13) then
    DataStringGrid.TopRow := DataStringGrid.TopRow + 1;
  DataStringPositionChange();
end;




procedure TForm1.ShowLineCheckBoxChange(Sender: TObject);
begin
  UpdateDataChart();
end;



procedure TForm1.ClasesCheckBoxChange(Sender: TObject);
begin
  if ClasesCheckBox.Checked then
  begin
    YColEdit.Enabled := False;
    YColEdit.Text := '';
    XColEdit.Enabled := False;
    XColEdit.Text := '';
  end
  else
  begin
    YColEdit.Enabled := False;
    YColEdit.Text := '';
    XColEdit.Enabled := True;
    XColEdit.Text := IntToStr(XCOLINDEX + 1);
  end;
  UpdateDataChart();

end;



procedure TForm1.ScatterPlotTBChange(Sender: TObject);
begin
  if ScatterPlotTB.Checked = True then
  begin
    BarChartTB.Checked := False;
    BoxPlotTB.Checked := False;
    ShowLineCheckBox.Visible := True;
    CURRENTGRAPH := 'SCATTERPLOT';
    XColEdit.Text := IntToStr(XCOLINDEX + 1);
    YColEdit.Text := IntToStr(YCOLINDEX + 1);
    UpdateDataChart();
  end
  else
  begin
    if (BarChartTB.Checked = False) and (BoxPlotTB.Checked = False) then
      ScatterPlotTB.Checked := True
    else
      ShowLineCheckBox.Visible := False;

  end;
end;


procedure TForm1.BarChartTBChange(Sender: TObject);
begin
  if BarChartTB.Checked = True then
  begin
    ScatterPlotTB.Checked := False;
    BoxPlotTB.Checked := False;
    ClasesCheckBox.Visible := True;
    if ClasesCheckBox.Checked then
    begin
      XColEdit.Enabled := False;
      XColEdit.Text := '';
      YColEdit.Enabled := False;
      YColEdit.Text := '';
    end
    else
    begin
      XColEdit.Text := IntToStr(XCOLINDEX + 1);
      YColEdit.Enabled := False;
      YColEdit.Text := '';
    end;

    CURRENTGRAPH := 'BARCHART';
    UpdateDataChart();
  end
  else
  begin
    if (ScatterPlotTB.Checked = False) and (BoxPlotTB.Checked = False) then
      BarChartTB.Checked := True
    else
    begin
      XColEdit.Enabled := True;
      XColEdit.Text := IntToStr(XCOLINDEX + 1);
      YColEdit.Enabled := True;
      YColEdit.Text := IntToStr(YCOLINDEX + 1);
      ClasesCheckBox.Visible := False;
    end;

  end;
end;

procedure TForm1.BoxPlotTBChange(Sender: TObject);
begin
  if BoxPlotTB.Checked = True then
  begin
    ScatterPlotTB.Checked := False;
    BarChartTB.Checked := False;
    CURRENTGRAPH := 'BOXPLOT';
    XColEdit.Text := IntToStr(XCOLINDEX + 1);
    YColEdit.Text := IntToStr(YCOLINDEX + 1);
    UpdateDataChart();
  end
  else
  begin
    if (ScatterPlotTB.Checked = False) and (BarChartTB.Checked = False) then
      BoxPlotTB.Checked := True;

  end;
end;



procedure TForm1.ClearDataBtnClick(Sender: TObject);
begin
  CURRENTGRAPH := 'NONE';
  UpdateDataChart();
end;



function TForm1.IsInsideRange(index: integer; range: integer): boolean;
begin
  if (0 < index) and (index <= range) then
    Result := True
  else
    Result := False;
end;


procedure TForm1.XYCOLlBtnClick(Sender: TObject);
var
  x, y: integer;
begin
  try
    case CURRENTGRAPH of
      'NONE':
      begin

      end;

      'SCATTERPLOT':
      begin
        x := StrToInt(XColEdit.Text);
        y := StrToInt(YColEdit.Text);
        if (IsInsideRange(x, DMCOLSIZE)) and (IsInsideRange(y, DMCOLSIZE)) then
        begin
          XCOLINDEX := x - 1;
          YCOLINDEX := y - 1;
          UpdateDataChart();
        end
        else
          raise ERangeError.Create('invalid index');
      end;
      'BARCHART':
      begin
        if (not ClasesCheckBox.Checked) then
        begin
          x := StrToInt(XColEdit.Text);
          if (IsInsideRange(x, DMCOLSIZE)) then
          begin
            XCOLINDEX := x - 1;
            UpdateDataChart();
          end
          else
            raise ERangeError.Create('invalid index');
        end;
      end;
      'BOXPLOT':
      begin

      end;
    end;
  except
    On e1: EConvertError do
    begin
      ShowMessage(e1.Message);
      XColEdit.Text := IntToStr(XCOLINDEX + 1);
      YColEdit.Text := IntToStr(YCOLINDEX + 1);
    end;
    On e2: ERangeError do
    begin
      ShowMessage(e2.Message);
      XColEdit.Text := IntToStr(XCOLINDEX + 1);
      YColEdit.Text := IntToStr(YCOLINDEX + 1);
    end;
  end;
end;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<EVENTOS<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<//

end.

