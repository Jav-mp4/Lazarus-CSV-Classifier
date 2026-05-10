unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls, Grids,
  ExtCtrls, TAGraph, TASeries, TATypes, TAChartUtils,
  TAMultiSeries, Math, TypesUnit, TesterUnit;

type
  { TMainForm }

  TMainForm = class(TForm)
    AddInterClassBtn: TButton;
    NewMinMaxLabel: TLabel;
    NewMinEdit: TEdit;
    NewMaxEdit: TEdit;
    NormalizeTypeCB: TComboBox;
    NormalizeColBtn: TButton;
    DataChartTypeCB: TComboBox;
    CurrentColEdit: TEdit;
    InterClassCB: TComboBox;
    InterChartXAxisImg: TImage;
    InterChartYAxisImg: TImage;
    InterChartCanvasImg: TImage;
    InterChartMenuItem: TMenuItem;
    SaveDataMenuItem: TMenuItem;
    TesterBtn: TButton;
    ClearDataBtn: TButton;
    CurrentRowEdit: TEdit;
    HorzBarImage: TImage;
    VertBarImage: TImage;
    XYTitleLabel: TLabel;
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
    DMSize: TLabel;
    StatisticsStringGrid: TStringGrid;
    XYCOLlBtn: TButton;
    DataChartLineSeries1: TLineSeries;
    DataChart: TChart;
    XValueEdit: TEdit;
    YValueEdit: TEdit;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    LoadCSVMenuItem: TMenuItem;
    OpenDialog1: TOpenDialog;



    //Static Chart
    function LoadCSVFileToMatrix(root: string): TDoubleMatrix;
    procedure ExportDataToCSVFile();
    procedure DisableDCExtraElements();
    procedure LoadMainData(doubleMatrix: TDoubleMatrix);
    procedure GenerateScatterPlot();
    procedure GenerateBarChart();
    procedure EnableStaticFormElements();
    procedure GenerateBoxPlot(ColIndex: integer; boxplotNum: integer);
    procedure NormalizeTypeCBChange(Sender: TObject);
    procedure SortColumn(colIndex: integer);
    function SortedMatrixToArray(colIndex: integer): TDoubleArray;
    function SortedMatrixRealValue(i, j: integer): double;
    function Discretization(colIndex: integer): TDoubleMatrix;
    procedure SynchDataChartTypeValues();

    //Interactive Chart 
    procedure LoadInteractiveChart();
    procedure InterChartStartValues();
    procedure GenerateInteractiveChartAxisLines();
    procedure AddInterClass();
    procedure GenerateInterPoint(x,y:Integer);
    procedure EraseInterPoint(xCol, yCol: double);
    procedure EnableInterFormElements();

    //Funciones 
    procedure UpdateDataChart();
    procedure SynchNormalizeTypeValues();
    function GetMean(doubleArray: TDoubleArray): double;
    function GetMedian(sortedDoubleArray: TDoubleArray): double;
    function GetStandarDev(doubleArray: TDoubleArray; mean: double): double;
    function GetColMinMaxValues(colIndex: integer): TDoubleArray;
    procedure NormalizeCol();
    procedure MinMaxDMCol(colIndex: integer; oldMin, oldMax, newMin, newMax: double);
    procedure GetStats();
    procedure UpdateDataStringGridValues();
    procedure DisableFormElements();
    procedure ShowChartElement(elementToShow: string);
    procedure HideChartElement(elementToHide: string);
    procedure ClearData();
    procedure HandleXYValues();
    procedure DeleteRow();
    procedure DataStringPositionChange();
    function IsInsideRange(index: integer; range: integer): boolean;
    function RandomRGB(RMin, RMax, GMin, GMax, BMin, BMax: integer): TColor;

    //Eventos
    procedure DataChartTypeCBChange(Sender: TObject);
    procedure NormalizeColBtnClick(Sender: TObject);
    procedure SaveDataMenuItemClick(Sender: TObject);
    procedure AddInterClassBtnClick(Sender: TObject);
    procedure InterChartMenuItemClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure InterChartCanvasImgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure TesterBtnClick(Sender: TObject);
    procedure ClearDataBtnClick(Sender: TObject);
    procedure DataStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
    procedure DataStringGridSelection(Sender: TObject; aCol, aRow: integer);
    procedure RowNumberStringGridSelection(Sender: TObject; aCol, aRow: integer);
    procedure RowNumberStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
    procedure DeleteRowBtnClick(Sender: TObject);
    procedure DownScrollBtnClick(Sender: TObject);
    procedure LeftScrollBtnClick(Sender: TObject);
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
  MainForm: TMainForm;
  //DATASTATSMATRIX Significado de indices:  0=Media, 1=Mediana, 2=Desviacion estandar
  DATAMATRIX, STATSMATRIX: TDoubleMatrix;
  SORTEDMATRIX: array of array of integer;
  DATATAG, CLASSARRAY: array of integer;
  DMROWSIZE, DMCOLSIZE, XCOLINDEX, YCOLINDEX, SELECTEDROW,SELECTEDCOL, IXRange, IYRange: integer;
  CURRENTGRAPH: string; // CURRENTGRAPH ['NONE', 'SCATTERPLOT', 'BARCHART', 'BOXPLOT', 'INTERACTIVE']

  CLASSCOLORS: array of TColor;

implementation
{$R *.lfm}

{ TMainForm }

//-------------------------- Valores de inicio ------------------------------//
procedure TMainForm.FormCreate(Sender: TObject);
begin
     {back_color:=RGBToColor(250, 250, 250);
     MainForm.Color:=back_color;
     RowNumberStringGrid.Color:=back_color;
     ColNumberStringGrid.Color:=back_color;
     DataChart.Color:=back_color;}

  SELECTEDROW := -1;
  IXRange := 10;
  IYRange := 10;
  VertBarImage.Canvas.Brush.Color := RGBToColor(226, 226, 226);
  VertBarImage.Canvas.FillRect(VertBarImage.ClientRect);
  HorzBarImage.Canvas.Brush.Color := RGBToColor(226, 226, 226);
  HorzBarImage.Canvas.FillRect(HorzBarImage.ClientRect);
  GenerateInteractiveChartAxisLines();
  DataChartLineSeries1.Clear;
  DataChartLineSeries1.Pointer.Style := psCircle;
  DataChartLineSeries1.Pointer.Brush.Color := Clred;
  DataChartLineSeries1.Pointer.Pen.Style := psClear;
  DataChartLineSeries1.Pointer.Visible := True;
  DataChartLineSeries1.ShowLines := False;
  SymbolsImage.Picture.LoadFromFile('StatsSymbols.jpg');
  CURRENTGRAPH := 'NONE';
  UpdateDataChart();
end;

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>FUNCIONES>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//




procedure TMainForm.UpdateDataStringGridValues();
var
  i, j: integer;
begin
  if not (Length(DATAMATRIX) = 0) then
  begin
    for i := 0 to DMROWSIZE - 1 do
      for j := 0 to DMCOLSIZE - 1 do
        DataStringGrid.Cells[j, i + 1] := FloatToStr(DATAMATRIX[i, j]);
    GetStats();
  end;
end;


//-------Cargar archivo CSV y devolverlo como matriz de tipo Double------//
function TMainForm.LoadCSVFileToMatrix(root: string): TDoubleMatrix;
var
  doubleMatrix: TDoubleMatrix;
  c, row, col, mtxRowLength, mtxColLength: integer;
  txt_line, txt_number: string;
  full_file: TextFile;
begin
  try 
    try
      AssignFile(full_file, root);
      //Se posiciona al principio de la primera fila
      Reset(full_file);
      //Se reserva espacio
      mtxRowLength := 500;
      mtxColLength := 100;
      SetLength(doubleMatrix, mtxRowLength, mtxColLength);

      //Se agregan los valores
      txt_number := '';
      row := 0;
      while not EOF(full_file) do
      begin
        ReadLn(full_file, txt_line);
        //Se checa que no se exceda tamaño de filas
        if (row + 1 > mtxRowLength) then
        begin
          mtxRowLength += 100;
          SetLength(doubleMatrix, mtxRowLength);
        end;
        col := 0;
        for c := 1 to Length(txt_line) do
        begin
          if (txt_line[c] = ',') or (c = Length(txt_line)) then
          begin
            if (c = Length(txt_line)) then
              txt_number += txt_line[c];
            //Se aumenta tamaño si se rebaso el tamaño reservado en el inicio
            if (col + 1 > mtxColLength) then
            begin
              mtxColLength += 100;
              SetLength(doubleMatrix, mtxRowLength, mtxColLength);
            end;
            doubleMatrix[row, col] := StrToFloat(txt_number);
            col += 1;
            txt_number := '';
          end
          else
            txt_number += txt_line[c];
        end;
        row += 1;
      end;
      SetLength(doubleMatrix, row, col);
      Result := doubleMatrix;
    except
      On e1: EFOpenError do
      begin
         setlength(doubleMatrix, 0, 0);
         result := doubleMatrix;
        ShowMessage(e1.Message);
      end;
      On e2: EConvertError do
      begin
         setlength(doubleMatrix, 0, 0);
         result := doubleMatrix;
        ShowMessage('Caracteres encontrados en espacio de datos numericos');
      end;
      On e3: EAccessViolation do
         begin
         setlength(doubleMatrix, 0, 0);
         result := doubleMatrix;
        ShowMessage(e3.Message);
         end;
    end;
  finally
    CloseFile(full_file);
  end;
end;

// DC = DataChart
procedure TMainForm.DisableDCExtraElements();
begin
  ShowLineCheckBox.Visible := False;
  ClasesCheckBox.Visible := False;
end;

//Obtiene el valor de DataChartTypeCB y le asigna el valor correspondiente a CURRENTGRAPH
procedure TMainForm.SynchDataChartTypeValues();
begin
  DisableDCExtraElements();
  XValueEdit.Enabled:= True;
  YValueEdit.Enabled:= True;
  XValueEdit.Text := IntToStr(XCOLINDEX + 1);
  YValueEdit.Text := IntToStr(YCOLINDEX + 1);
  case DataChartTypeCB.Text of
    'None':
    begin
      CURRENTGRAPH := 'NONE';
    end;
    'Scatter Plot':
    begin
      CURRENTGRAPH := 'SCATTERPLOT';
      ShowLineCheckBox.Visible := True;
    end;
    'Bar Chart':
    begin
      CURRENTGRAPH := 'BARCHART';
      ClasesCheckBox.Visible := True;
      YValueEdit.Enabled:= False;
      if (ClasesCheckBox.Checked) then
        XValueEdit.Enabled:= False;
    end;
    'Box Plot':
    begin
      CURRENTGRAPH := 'BOXPLOT';
      XValueEdit.Enabled:= False;
      YValueEdit.Enabled:= False;
    end;
  end;
  UpdateDataChart();
end;

procedure TMainForm.ExportDataToCSVFile();
var
  i, j: integer;
  fileName, currentLine: string;
  txtFile: TextFile;
begin
  fileName := 'A1_Name_Example';
  if InputQuery('Save File', 'File name:', fileName) then
    if not (Length(fileName) = 0) then
    begin
      if not (Length(DATAMATRIX) = 0) then
      begin
        try
          try
            //Se crea el archivo dentro de la carpeta data_sets con el nombre que escogio el ususario
            AssignFile(txtFile, 'data_sets/' + fileName + '.txt');
            //Se borra el contenido si existe y se reinicia el apuntador para WriteLn
            Rewrite(txtFile);
            //Se obtiene un string con los valores de etiquetas y se agrega al archivo de texto
            currentLine := '';
            for j := 0 to DMCOLSIZE - 1 do
              currentLine += IntToStr(DATATAG[j]) + ',';
            currentLine += IntToStr(DATATAG[DMCOLSIZE]);
            WriteLn(txtFile, currentLine);

            //Se crean strings para cada fila con su respectivo valor de clase y se agregan al archivo de texto
            for i := 0 to DMROWSIZE - 1 do
            begin
              currentLine := '';
              for j := 0 to DMCOLSIZE - 1 do
                currentLine += FloatToStr(DATAMATRIX[i, j]) + ',';
              currentLine += IntToStr(CLASSARRAY[i]);
              WriteLn(txtFile, currentLine);
            end;
          finally
            CloseFile(txtFile);
          end;
        except
          on e1: EFOpenError do
            ShowMessage(e1.Message);
          on e2: EInOutError do
            ShowMessage(e2.Message);
        end;
      end
      else
        ShowMessage('no data');
    end
    else
      ShowMessage('no file name');

end;

procedure TMainForm.LoadInteractiveChart();
begin
  ClearData();
  DataChartTypeCB.ItemIndex := 0;
  SynchDataChartTypeValues();
  DisableFormElements();
  TesterForm.ClearTestData();
  EnableInterFormElements();
  GenerateInteractiveChartAxisLines();
  InterChartStartValues();
  CURRENTGRAPH := 'INTERACTIVE';
  UpdateDataChart();
end;

procedure TMainForm.InterChartStartValues();
var j: Integer;
begin
  //Se limpian valores en el arreglo de datos y el de colores de clase
  SetLength(DATATAG,3);
  SetLength(CLASSCOLORS,0);
  SetLength(STATSMATRIX,3,2);
  DATATAG[0] := 0;
  DATATAG[1] := 0;
  DATATAG[2] := 0;
  DMCOLSIZE := 2;
  DMROWSIZE := 0;
  //Se genera el DataStringGrid inicial con 1 fila y 3 columnas
  DataStringGrid.RowCount := 1;
  DataStringGrid.ColCount := 3;
  DataStringGrid.Cells[0,0] := '0';
  DataStringGrid.Cells[1,0] := '0';
  StatisticsStringGrid.RowCount := 3;
  StatisticsStringGrid.ColCount := 3;


  ColNumberStringGrid.RowCount := 1;
  ColNumberStringGrid.ColCount := 3;


  for j := 0 to DMCOLSIZE - 1 do
    ColNumberStringGrid.Cells[j, 0] := IntToStr(j + 1);
  ColNumberStringGrid.Cells[DMCOLSIZE, 0] := 'Class';

  ColNumberStringGrid.LeftCol := 0;
  DataStringGrid.LeftCol := 0;
  StatisticsStringGrid.LeftCol := 0;

  //Se agrega la primera clase y se muestra en el ComboBox
  AddInterClass();
  InterClassCB.ItemIndex := 0;

  CURRENTGRAPH := 'INTERACTIVE';
  TesterForm.EvaluationButtonsEnabling();
end;

procedure TMainForm.AddInterClass();
begin
  DATATAG[2] += 1;
  SetLength(CLASSCOLORS,Length(CLASSCOLORS)+1);
  //Se le agrega color aleatorio a la clase para pintar puntos en la grafica interactiva
  CLASSCOLORS[Length(CLASSCOLORS)-1] := RandomRGB(0, 255, 0, 255, 0, 255);
  InterClassCB.Items.Add('Class ' + IntToStr(DATATAG[2]-1));
  DataStringGrid.Cells[2,0] := IntToStr(DATATAG[2]);
end;
procedure TMainForm.GenerateInterPoint(x, y: integer);
var
  pointSize, i: Integer;
  cColor: TColor;
begin
  //showmessage(inttostr(x)+' '+inttostr(y));
  cColor := CLASSCOLORS[InterClassCB.ItemIndex];
  pointSize := 10;
  with InterChartCanvasImg.Picture.Bitmap.Canvas do
  begin
    //Pintar una elipse de tamaño pointSize alrededor de la coordenada
    Pen.Width := 1;
    Pen.Color := cColor;
    Brush.Color := cColor;
    Brush.Style := bsSolid;
    Ellipse(x - Round(pointSize/2), y - Round(pointSize/2) , x + Round(pointSize/2), y + Round(pointSize/2));
    InterChartCanvasImg.Invalidate;

    DMROWSIZE += 1;
    //Incrementar tamaños para introducir nuevo elemento
    SetLength(DATAMATRIX,DMROWSIZE,2);
    DataStringGrid.RowCount := DMROWSIZE+1;
    SetLength(CLASSARRAY,DMROWSIZE);
    SetLength(SORTEDMATRIX,DMROWSIZE,2);

    SORTEDMATRIX[0,0] := -1;
    SORTEDMATRIX[0,1] := -1;

    //Agregar valor de x
    DATAMATRIX[DMROWSIZE-1,0] := (x * IXRange) / InterChartCanvasImg.Width;
    DataStringGrid.Cells[0,DMROWSIZE] := FloatToStr(DATAMATRIX[Length(DATAMATRIX)-1,0]);
    //Agregar valor de x
    DATAMATRIX[DMROWSIZE-1,1] := ((InterChartCanvasImg.Height-y) * IYRange) / InterChartCanvasImg.Height;
    DataStringGrid.Cells[1,DMROWSIZE] := FloatToStr(DATAMATRIX[Length(DATAMATRIX)-1,1]);
    //Agregar valor de clase
    CLASSARRAY[DMROWSIZE-1] := InterClassCB.ItemIndex;
    DataStringGrid.Cells[2, DMROWSIZE] := IntToStr(InterClassCB.ItemIndex);
    GetStats();

    //Actualizar StringGrids de indices

    RowNumberStringGrid.ColCount := 1;
    RowNumberStringGrid.RowCount := DMROWSIZE;
    //Se llena el StringGrid que contiene el indice de las columnas y el de las filas
    for i := 0 to DMROWSIZE - 1 do
      RowNumberStringGrid.Cells[0, i] := IntToStr(i + 1);
  end;
end;

procedure TMainForm.EraseInterPoint(xCol, yCol: double);
var
  x, y, pointSize: integer;
begin
  pointSize := 10;
  with InterChartCanvasImg.Picture.Bitmap.Canvas do
  begin
    Pen.Width := 1;
    Pen.Color := clWhite;
    Brush.Color := clWhite;
    Brush.Style := bsSolid;
    x := Round ( (xCol * InterChartCanvasImg.Width) / IXRange);
    y := Round( (InterChartCanvasImg.Height - (yCol * InterChartCanvasImg.Height) / IYRange) );
    Ellipse(x - Round(pointSize / 2), y - Round(pointSize / 2), x + Round(pointSize / 2), y + Round(pointSize / 2));
    //showmessage(inttostr(x)+' '+inttostr(y));
    InterChartCanvasImg.Invalidate;
  end;
end;

//-----------------Generar las lineas de la grafica interactiva-------------//
procedure TMainForm.GenerateInteractiveChartAxisLines();
var
  i, x, y, unitNum, unitSize, oneThirdSize: Integer;
  currentNum: String;
begin
  unitNum := 10;

  //Limpia TImage de eje Y
  InterChartYAxisImg.Canvas.Brush.Color := RGBToColor(240, 240, 240);
  InterChartYAxisImg.Canvas.FillRect(InterChartYAxisImg.ClientRect);
  //Generar eje Y
  with InterChartYAxisImg do
  begin
    Picture.Bitmap.Canvas.Pen.Color := clBlack;
    Picture.Bitmap.Canvas.Pen.Width := 2;
    //Genera la linea principal del eje
    x := Width-1;
    y := Height - InterChartCanvasImg.Height;
    Picture.Bitmap.Canvas.MoveTo(x, y);
    y := Height;
    Picture.Bitmap.Canvas.LineTo(x, y);
    //Genera las lineas dependiendo de la cantidad de divisiones
    Picture.Bitmap.Canvas.Pen.Width := 1;
    oneThirdSize := Round(Width / 3);
    unitSize := Round(InterChartCanvasImg.Height / unitNum);
    for i := 1 to unitNum do
    begin
        x := Width - oneThirdSize;
        y := Height - (unitSize*i);
        Picture.Bitmap.Canvas.MoveTo(x, y);
        x := Width;
        Picture.Bitmap.Canvas.LineTo(x, y);
    end;
    //Genera los numeros para cada division
    for i := 1 to unitNum do
    begin
        currentNum := FloatToStr((IYRange/unitNum)*i);
        x := 0;
        y := Height - (unitSize*i) - Round(Picture.Bitmap.Canvas.TextHeight(currentNum)/2);
        Picture.Bitmap.Canvas.TextOut(x, y,currentNum);
    end;
    Invalidate;
  end;

  //Limpia TImage de eje X
  InterChartXAxisImg.Canvas.Brush.Color := RGBToColor(240, 240, 240);
  InterChartXAxisImg.Canvas.FillRect(InterChartXAxisImg.ClientRect);
  //Generar eje X
  with InterChartXAxisImg do
  begin
    Picture.Bitmap.Canvas.Pen.Color := clBlack;
    Picture.Bitmap.Canvas.Pen.Width :=2;
    //Genera la linea principal del eje
    x := 0;
    y := 1;
    Picture.Bitmap.Canvas.MoveTo(x, y);
    x := InterChartCanvasImg.Width;
    Picture.Bitmap.Canvas.LineTo(x,y);
    //Genera las lineas dependiendo de la cantidad de divisiones
    Picture.Bitmap.Canvas.Pen.Width := 1;
    oneThirdSize := Round(Height / 3);
    unitSize := Round(InterChartCanvasImg.Width / unitNum);
    for i := 1 to unitNum do
    begin
        x := unitSize*i;
        y := 0;
        Picture.Bitmap.Canvas.MoveTo(x, y);
        y := oneThirdSize;
        Picture.Bitmap.Canvas.LineTo(x, y);
    end;
    //Genera los numeros para cada division
    for i := 1 to unitNum do
    begin
        currentNum := FloatToStr((IXRange/unitNum)*i);
        x := (unitSize*i) - Round(Picture.Bitmap.Canvas.TextWidth(currentNum)/2);
        y := Height -Picture.Bitmap.Canvas.TextHeight('1');
        Picture.Bitmap.Canvas.TextOut(x, y,currentNum);
    end;
    Invalidate;
  end;
end;



//------------------------Cargar Archivo Principal -----------------------------//
procedure TMainForm.LoadMainData(doubleMatrix: TDoubleMatrix);
var
  i, j: integer;
begin
  try
  DMROWSIZE := Length(doubleMatrix) - 1;
  DMCOLSIZE := Length(doubleMatrix[0]) - 1;
  SetLength(DATATAG, DMCOLSIZE + 1);
  SetLength(DATAMATRIX, DMROWSIZE, DMCOLSIZE);
  SetLength(CLASSARRAY, DMROWSIZE);
  DataStringGrid.Clean;
  DataStringGrid.ColCount := DMCOLSIZE + 1;
  DataStringGrid.rowCount := DMROWSIZE + 1;
  //Se obtienen los datos de las etiquetas
  for j := 0 to DMCOLSIZE do
  begin
    DATATAG[j] := Round(doubleMatrix[0, j]);
    DataStringGrid.Cells[j, 0] := FloatToStr(doubleMatrix[0, j]);
  end;
  //Se obtienen los datos de cada ejemplo
  //Se empieza por i := 1 para ignorar primer fila
  for i := 0 to DMROWSIZE - 1 do
  begin
    for j := 0 to DMCOLSIZE - 1 do
    begin
      DATAMATRIX[i, j] := doubleMatrix[i + 1, j];
      DataStringGrid.Cells[j, i + 1] := FloatToStr(doubleMatrix[i + 1, j]);
    end;
  end;
  //Se obtienen los valores de clase de la ultima columna en cada fila DMCOLSIZE es equivalente a ultimo indice de doublematrix
  for i := 0 to DMROWSIZE - 1 do
  begin
    CLASSARRAY[i] := Round(doubleMatrix[i + 1, DMCOLSIZE]);
    DataStringGrid.Cells[DMCOLSIZE, i + 1] := FloatToStr(doubleMatrix[i + 1, DMCOLSIZE]);
  end;


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
  GetStats();
  //Toma el valor de la primera fila para utilizar en el Chart
  XCOLINDEX := 0;
  YCOLINDEX := 0;
  SELECTEDROW := 0;
  XValueEdit.Text := IntToStr(XCOLINDEX + 1);
  YValueEdit.Text := IntToStr(YCOLINDEX + 1);
  DMSize.Caption := 'Columns ' + IntToStr(DMCOLSIZE) + '     Rows ' + IntToStr(DMROWSIZE);

  EnableStaticFormElements();
  DataChartTypeCB.ItemIndex := 1;
  SynchDataChartTypeValues();
  UpdateDataChart();
  except
        On e: ERangeError do
        //ShowMessage(e.Message);
  end;
end;

procedure TMainForm.GetStats();
var
 j :Integer;
begin
  //Obtiene los valores Media,Mediana y Desviacion para cada columna
  for j := 0 to DMCOLSIZE - 1 do
  begin
    if (DATATAG[j] = 0) then
    begin
      STATSMATRIX[0, j] := GetMean(SortedMatrixToArray(j));
      StatisticsStringGrid.Cells[j, 0] := FloatToStr(Round(STATSMATRIX[0, j] * 100) / 100);
      STATSMATRIX[1, j] := GetMedian(SortedMatrixToArray(j));
      StatisticsStringGrid.Cells[j, 1] := FloatToStr(STATSMATRIX[1, j]);
      STATSMATRIX[2, j] := GetStandarDev(SortedMatrixToArray(j), STATSMATRIX[0, j]);
      StatisticsStringGrid.Cells[j, 2] := FloatToStr(Round(STATSMATRIX[2, j] * 100) / 100);
    end;
  end;
end;
//-------------------Actualizar grafica y cambiar tipo---------------//
procedure TMainForm.UpdateDataChart();
var
  i, j: integer;
begin
  DataChartLineSeries1.Clear;
  DataChartBarSeries1.Clear;
  DataChartBoxAndWhiskerSeries1.Clear;
  case CURRENTGRAPH of
    'NONE':
    begin
      ClearData();
      HideChartElement('static');
      HideChartElement('interactive');
    end;
    'SCATTERPLOT':
    begin
      HideChartElement('interactive');
      ShowChartElement('static');
      if not (Length(DATAMATRIX) = 0) then
        GenerateScatterPlot();
    end;
    'BARCHART':
    begin
      HideChartElement('interactive');
      ShowChartElement('static');
      if not (Length(DATAMATRIX) = 0) then
        GenerateBarChart();
    end;
    'BOXPLOT':
    begin
      HideChartElement('interactive');
      ShowChartElement('static');
      if not (Length(DATAMATRIX) = 0) then
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
    'INTERACTIVE':
    begin
      HideChartElement('static');
      ShowChartElement('interactive');
    end;
  end;
end;


//------------------------Grafica de dispersion-------------------------------//
procedure TMainForm.GenerateScatterPlot();
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
      DataChartLineSeries1.AddXY(DATAMATRIX[i, XCOLINDEX], DATAMATRIX[i, YCOLINDEX], '', RandomRGB(60, 90, 60, 140, 150, 150));
  end;

end;

//------------------------Grafica de barras-------------------------------//
procedure TMainForm.GenerateBarChart();
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
procedure TMainForm.GenerateBoxPlot(colIndex: integer; boxplotNum: integer);
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

procedure TMainForm.NormalizeTypeCBChange(Sender: TObject);
begin
  SynchNormalizeTypeValues();
end;

//-------------------------Limpiar Datos-------------------------------//
procedure TMainForm.ClearData();
begin
  //Limpiar datos
  SetLength(DATAMATRIX, 0, 0);
  SetLength(STATSMATRIX, 0, 0);
  SetLength(SORTEDMATRIX, 0, 0);
  SetLength(DATATAG, 0);
  SetLength(CLASSARRAY, 0);
  SetLength(CLASSCOLORS,0);
  DMROWSIZE := -1;
  DMCOLSIZE := -1;
  XCOLINDEX := -1;
  YCOLINDEX := -1;
  SELECTEDROW := -1;
  InterClassCB.Items.Clear;

  //Desactivar botones
  DisableFormElements();

  //Limpiar StringGrids
  DataStringGrid.Clear;
  RowNumberStringGrid.Clear;
  ColNumberStringGrid.Clear;
  StatisticsStringGrid.Clear;

  //Limpiar InteractiveChart
  InterChartCanvasImg.Canvas.Brush.Color := RGBToColor(255, 255, 255);
  InterChartCanvasImg.Canvas.FillRect(InterChartCanvasImg.ClientRect);
end;

procedure TMainForm.EnableStaticFormElements();
begin
  DataChartTypeCB.ItemIndex := 1;
  XYCOLlBtn.Enabled := True;
  DataChartTypeCB.Enabled := True;
  DeleteRowBtn.Enabled := True;
  TesterBtn.Enabled := True;
  XValueEdit.Enabled := True;
  YValueEdit.Enabled := True;
  CurrentRowEdit.Enabled := True;
  SaveDataMenuItem.Enabled := True;
end;
procedure TMainForm.EnableInterFormElements();
begin
  XYCOLlBtn.Enabled := True;
  TesterBtn.Enabled := True;
  XValueEdit.Enabled := True;
  YValueEdit.Enabled := True;
  InterClassCB.Enabled := True;
  AddInterClassBtn.Enabled := True;
  DeleteRowBtn.Enabled := True;
  CurrentRowEdit.Enabled := True;
  SaveDataMenuItem.Enabled := True;
end;



procedure TMainForm.DisableFormElements();
begin
   XYCOLlBtn.Enabled := False;
   DataChartTypeCB.ItemIndex := 0;
   DataChartTypeCB.Enabled := False;
  DeleteRowBtn.Enabled := False;
  TesterBtn.Enabled := False;
  XValueEdit.Enabled := False;
  YValueEdit.Enabled := False;
  CurrentRowEdit.Enabled := False;
  InterClassCB.Enabled := False;
  AddInterClassBtn.Enabled := False;
  SaveDataMenuItem.Enabled := False;
end;


//Convertir indices de columna en SORTEDMATRIX a columna real y devolverla en TDoubleArray
function TMainForm.SortedMatrixToArray(colIndex: integer): TDoubleArray;
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
function TMainForm.SortedMatrixRealValue(i, j: integer): double;
begin
  Result := DATAMATRIX[(SORTEDMATRIX[i, j]), j];
end;


//Discretization de valores en una columna
function TMainForm.Discretization(colIndex: integer): TDoubleMatrix;
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
procedure TMainForm.SortColumn(colIndex: integer);
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
function TMainForm.GetMean(doubleArray: TDoubleArray): double;
var
  i: integer;
  mean: double;
begin
  mean := 0;
  for i := 0 to Length(doubleArray) - 1 do
  begin
    mean += doubleArray[i];
  end;
  mean := mean / Length(doubleArray);
  Result := mean;
end;

//Obtener la Mediana de un TDoubleArray
function TMainForm.GetMedian(sortedDoubleArray: TDoubleArray): double;
var
  rowSize: integer;
begin
  rowSize := Length(sortedDoubleArray) - 1;
  //Se da el tamaño real en cuanto a los indices del arreglo para facilitar operaciones
  if (rowSize + 1 mod 2 = 0) then //Se compara cantidad de datos
    Result := (sortedDoubleArray[rowSize div 2] + sortedDoubleArray[(rowSize div 2) + 1]) / 2

  else
    Result := sortedDoubleArray[(rowSize + 1) div 2];
end;

//Obtener la desviacion estandar
function TMainForm.GetStandarDev(doubleArray: TDoubleArray; mean: double): double;
var
  deviation: double;
  i: integer;
begin
  deviation := 0;
  for i := 0 to Length(doubleArray) - 1 do
  begin
    deviation += Power((doubleArray[i] - mean), 2);
  end;
  deviation := Sqrt(deviation / Length(doubleArray));
  Result := deviation;
end;

function TMainForm.RandomRGB(RMin, RMax, GMin, GMax, BMin, BMax: integer): TColor;
begin
  Result := RGBToColor(Random(RMax - RMin) + RMin, Random(GMax - GMin) + GMin, Random(BMax - BMin) + BMin);
end;

procedure TMainForm.DataStringPositionChange();
begin
  ColNumberStringGrid.LeftCol := DataStringGrid.LeftCol;
  StatisticsStringGrid.LeftCol := DataStringGrid.LeftCol;
  RowNumberStringGrid.TopRow := DataStringGrid.TopRow - 1;
  if (DMROWSIZE > 13) then
    VerticalBarlBtn.Top :=
      Round(((DownScrollBtn.Top) - (UpScrollBtn.Top + UpScrollBtn.Height)) * ((DataStringGrid.TopRow) / (DMROWSIZE - 12))) +
      UpScrollBtn.Top + UpScrollBtn.Height - VerticalBarlBtn.Height;
end;

//Checar si un index esta dentro del rango
function TMainForm.IsInsideRange(index: integer; range: integer): boolean;
begin
  if (0 < index) and (index <= range) then
    Result := True
  else
    Result := False;
end;


//Borrar una fila
procedure TMainForm.DeleteRow();
var
  rowToDelete, i, j: integer;
  rowWasFound: boolean;
begin
  try
    //Se comprueba que el indice exista
    if (IsInsideRange(StrToInt(CurrentRowEdit.Text), DMROWSIZE)) then
    begin
      rowToDelete := StrToInt(CurrentRowEdit.Text) - 1;
      //Si la grafica actual es interactiva se borra punto en la grafica interactiva que corresponde a la fila
      if (CURRENTGRAPH = 'INTERACTIVE') then
        EraseInterPoint(DATAMATRIX[rowToDelete,0], DATAMATRIX[rowToDelete,1]);
      //A partir de la fila que se quiere eliminar se desplazan todas un indice hacia atras
      for i := rowToDelete to DMROWSIZE - 2 do
      begin
        for j := 0 to DMCOLSIZE - 1 do
        begin
          DATAMATRIX[i, j] := DATAMATRIX[i + 1, j];
          DataStringGrid.Cells[j, i + 1] := DataStringGrid.Cells[j, i + 2];
        end;
        //Se hace lo mismo con la columna de clase
        CLASSARRAY[i] := CLASSARRAY[i + 1];
        DataStringGrid.Cells[DataStringGrid.ColCount-1, i + 1] := DataStringGrid.Cells[DataStringGrid.ColCount-1, i + 2];
      end;

      //Se actualizan los indices en SORTEDMATRIX (la matriz con idices ordenados)
      for j := 0 to DMCOLSIZE - 1 do
      begin
        rowWasFound := False;
        for i := 0 to DMROWSIZE - 2 do
        begin
          //A partir de encontrarse con la fila eliminada comenzara a desplazar los valores de la columna hacia una fila anterior
          if (rowWasFound or (rowToDelete = SORTEDMATRIX[i, j])) then
            if (rowWasFound) then
              SORTEDMATRIX[i, j] := SORTEDMATRIX[i + 1, j]
            else
              begin
                rowWasFound := True;
                SORTEDMATRIX[i, j] := SORTEDMATRIX[i + 1, j];
              end;
          //Si les resta 1 a los indices que eran mas grandes que la fila eliminada para ajustarlos a el nuevo limite
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
      if (DMROWSIZE>0) then
         GetStats()
      else
        begin
          CURRENTGRAPH:='NONE';
          UpdateDataChart();
          ClearData();
        end;
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

procedure TMainForm.SynchNormalizeTypeValues();
begin
  NewMinEdit.Visible := False;
      NewMaxEdit.Visible := False;
      NewMinMaxLabel.Visible := False;
  case NormalizeTypeCB.Text of
    'Min-Max':
    begin
      NewMinEdit.Visible := True;
      NewMaxEdit.Visible := True;
      NewMinMaxLabel.Visible := True;
    end;
    'Z-Score':
    begin
    end;
    'Decimal Scaling':
    begin;
    end;
  end;
end;

procedure TMainForm.NormalizeCol();
var
  //Norm = Normalizar
  colIndex, i, j: integer;
  minMaxValues : TDoubleArray;
  newMin, newMax: Double;
begin
  //Se comprueba que el indice exista
  try
  if (IsInsideRange(StrToInt(CurrentColEdit.Text), DMCOLSIZE)) then
  begin
    colIndex := StrToInt(CurrentColEdit.Text)-1;
    if (DATATAG[colIndex - 1] = 0) then
    begin
      case NormalizeTypeCB.Text of
          'Min-Max':
          begin
            newMin := StrToFloat(NewMinEdit.Text);
            newMax := StrToFloat(NewMaxEdit.Text);
            if (newMin < newMax) then
            begin
              minMaxValues := GetColMinMaxValues(colIndex);
              MinMaxDMCol(colIndex, minMaxValues[0], minMaxValues[1], newMin, newMax);
              UpdateDataStringGridValues();
            end
            else
              raise  ERangeError.Create('invalid range');
          end;
          'Z-Score':
        begin

        end;
        'Decimal Scaling':
        begin

        end;
      end;
    end
    else
     raise  EConvertError.Create('invalid column type');
  end
  else
   raise  ERangeError.Create('invalid index');
  except
    on e1: EConvertError do
      ShowMessage(e1.Message);
    on e2: ERangeError do
      ShowMessage(e2.Message);
  end;
end;


//Se obtiene el valor minimo y el maximo de la columna  TDoubleArray[0] = minimo,  TDoubleArray[1] = maximo
function TMainForm.GetColMinMaxValues(colIndex: integer): TDoubleArray;
var
  i: integer;
  //minMaxValues[0] = minimo,  minMaxValues[1] = maximo
  minMaxValues: TDoubleArray;
begin
  SetLength(minMaxValues, 2);
  if not (Length(DATAMATRIX) = 0) then
  begin
    minMaxValues[0] := DATAMATRIX[0, colIndex];
    minMaxValues[1] := DATAMATRIX[0, colIndex];
    for i := 0 to DMROWSIZE - 1 do
    begin
      if (DATAMATRIX[i, colIndex] < minMaxValues[0]) then
        minMaxValues[0] := DATAMATRIX[i, colIndex];
      if (DATAMATRIX[i, colIndex] > minMaxValues[1]) then
        minMaxValues[1] := DATAMATRIX[i, colIndex];
    end;
    Result := minMaxValues;
  end
  else
    raise ERangeError.Create('datamatrix is empty');
end;

procedure TMainForm.MinMaxDMCol(colIndex: integer; oldMin, oldMax, newMin, newMax: double);
var
  i: integer;
begin
  //Se realiza la nomralizacion min-max en cada valor de la columna colIndex
  for i := 0 to DMROWSIZE-1 do
      DATAMATRIX[i, colIndex] := ( (DATAMATRIX[i, colIndex] - oldMin) / (oldMax - oldMin) * (newMax - newMin) ) + newMin;
end;

procedure TMainForm.ShowChartElement(elementToShow: string);
begin
  case elementToShow of
    'interactive':
    begin
      InterChartCanvasImg.Top := 96;
      InterChartCanvasImg.Left := 56;
      InterChartCanvasImg.Enabled := True;
      InterChartXAxisImg.Top := 506;
      InterChartXAxisImg.Left := 56;
      InterChartXAxisImg.Enabled := True;
      InterChartYAxisImg.Top := 72;
      InterChartYAxisImg.Left := 24;
      InterChartYAxisImg.Enabled := True;
    end;
    'static':
    begin
      DataChart.Top := 88;
      DataChart.Left := 24;
      DataChart.Enabled := True;
    end;
  end;
end;



procedure TMainForm.HideChartElement(elementToHide: string);
begin
  case elementToHide of
    'interactive':
    begin
      InterChartCanvasImg.Top := MainForm.Top + MainForm.Height;
      InterChartCanvasImg.Left := MainForm.Left + MainForm.Width;
      InterChartCanvasImg.Enabled := False;
      InterChartXAxisImg.Top := MainForm.Top + MainForm.Height;
      InterChartXAxisImg.Left := MainForm.Left + MainForm.Width;
      InterChartXAxisImg.Enabled := False;
      InterChartYAxisImg.Top := MainForm.Top + MainForm.Height;
      InterChartYAxisImg.Left := MainForm.Left + MainForm.Width;
      InterChartYAxisImg.Enabled := False;
    end;
    'static':
    begin
      DataChart.Top := MainForm.Top + MainForm.Height;
      DataChart.Left := MainForm.Left + MainForm.Width;
      DataChart.Enabled := False;
    end;
  end;
end;

procedure TMainForm.HandleXYValues();
var
  oldIXRange, oldIYRange: integer;
  x, y: integer;
begin
  try
    case CURRENTGRAPH of
      'NONE':
      begin

      end;
      'SCATTERPLOT':
      begin
        x := StrToInt(XValueEdit.Text);
        y := StrToInt(YValueEdit.Text);
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
          x := StrToInt(XValueEdit.Text);
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
      'INTERACTIVE':
      begin
        if not (StrToInt(XValueEdit.Text) = 0) and not (StrToInt(YValueEdit.Text) = 0) then
        begin
          oldIXRange := IXRange;
          oldIYRange := IYRange;
          IXRange := StrToInt(XValueEdit.Text);
          IYRange := StrToInt(YValueEdit.Text);
          GenerateInteractiveChartAxisLines();
          MinMaxDMCol(0, 0, oldIXRange, 0, IXRange);
          MinMaxDMCol(1, 0, oldIYRange, 0, IYRange);
          UpdateDataStringGridValues();
        end;
      end;
    end;
  except
    On e1: EConvertError do
    begin
      ShowMessage(e1.Message);
      XValueEdit.Text := IntToStr(XCOLINDEX + 1);
      YValueEdit.Text := IntToStr(YCOLINDEX + 1);
    end;
    On e2: ERangeError do
    begin
      ShowMessage(e2.Message);
      XValueEdit.Text := IntToStr(XCOLINDEX + 1);
      YValueEdit.Text := IntToStr(YCOLINDEX + 1);
    end;
  end;
end;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<FUNCIONES<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<//




//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>EVENTOS>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//



procedure TMainForm.DeleteRowBtnClick(Sender: TObject);
begin
  DeleteRow();
end;

//Seleccion de Fila y coloreado de celdas
procedure TMainForm.RowNumberStringGridSelection(Sender: TObject; aCol, aRow: integer);
begin
  SELECTEDROW := RowNumberStringGrid.Row;
  CurrentRowEdit.Text := IntToStr(SELECTEDROW + 1);
  //DataStringGrid.TopRow:=RowNumberStringGrid.TopRow+1;
  DataStringGrid.Invalidate;
  RowNumberStringGrid.Invalidate;

end;

procedure TMainForm.RowNumberStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
begin
  if (aRow = SELECTEDROW) then
    RowNumberStringGrid.Canvas.Brush.Color := RGBToColor(198, 198, 198);
end;


procedure TMainForm.DataStringGridPrepareCanvas(Sender: TObject; aCol, aRow: integer; aState: TGridDrawState);
begin
  if (aRow = SELECTEDROW + 1) then
    DataStringGrid.Canvas.Brush.Color := RGBToColor(226, 226, 226);
end;






//Actualizacion de StringGrids con respecto a posicion de DataStringGrid


procedure TMainForm.DataStringGridSelection(Sender: TObject; aCol, aRow: integer);
begin
  DataStringPositionChange();
  SELECTEDROW := DataStringGrid.Row-1;
  SELECTEDCOL := DataStringGrid.Col;
  CurrentColEdit.Text := IntToStr(SELECTEDCOL + 1);
  CurrentRowEdit.Text := IntToStr(SELECTEDROW + 1);
  DataStringGrid.Invalidate;
  RowNumberStringGrid.Invalidate;
end;



procedure TMainForm.LeftScrollBtnClick(Sender: TObject);
begin
  if (DataStringGrid.LeftCol > 0) then
    DataStringGrid.LeftCol := DataStringGrid.LeftCol - 1;
  DataStringPositionChange();
end;

procedure TMainForm.RightScrollBtnClick(Sender: TObject);
begin
  if (DataStringGrid.LeftCol < DataStringGrid.ColCount - 6) then
    DataStringGrid.LeftCol := DataStringGrid.LeftCol + 1;
  DataStringPositionChange();
end;

procedure TMainForm.UpScrollBtnClick(Sender: TObject);
begin
  if (DataStringGrid.TopRow > 0) then
    DataStringGrid.TopRow := DataStringGrid.TopRow - 1;
  DataStringPositionChange();
end;


procedure TMainForm.DownScrollBtnClick(Sender: TObject);
begin
  if (DataStringGrid.TopRow > DataStringGrid.TopRow - 13) then
    DataStringGrid.TopRow := DataStringGrid.TopRow + 1;
  DataStringPositionChange();
end;




procedure TMainForm.ShowLineCheckBoxChange(Sender: TObject);
begin
  SynchDataChartTypeValues();
end;



procedure TMainForm.ClasesCheckBoxChange(Sender: TObject);
begin
  SynchDataChartTypeValues();
end;

procedure TMainForm.BarChartTBChange(Sender: TObject);
begin

end;

procedure TMainForm.ScatterPlotTBChange(Sender: TObject);
begin

end;


procedure TMainForm.DataChartTypeCBChange(Sender: TObject);
begin
  SynchDataChartTypeValues();
end;






procedure TMainForm.TesterBtnClick(Sender: TObject);
begin
     TesterForm.ShowModal;
end;


procedure TMainForm.FormActivate(Sender: TObject);
begin
  ///Cargar elementos para prueba de TesterUnit//
  {TesterForm.ShowModal;}
  //Cargar elementos para prueba de Interactive Chart//
  {LoadInteractiveChart();}
  //Cargar elementos para prueba de Static Chart//
  XCOLINDEX := 0;
  YCOLINDEX := 1;
  OpenDialog1.InitialDir := ExtractFilePath('project1.exe') + '\data_sets';
  LoadMainData(LoadCSVFileToMatrix('data_sets\ST2.txt'));
end;

procedure TMainForm.InterChartCanvasImgMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  GenerateInterPoint(X,Y);
end;



procedure TMainForm.InterChartMenuItemClick(Sender: TObject);
begin
  LoadInteractiveChart();
end;

procedure TMainForm.AddInterClassBtnClick(Sender: TObject);
begin
  AddInterClass();
end;



procedure TMainForm.LoadCSVMenuItemClick(Sender: TObject);
var
  doubleMatrix: TDoubleMatrix;
begin
  try
    OpenDialog1.Execute;
    doubleMatrix := LoadCSVFileToMatrix(OpenDialog1.FileName);
    if(length(doubleMatrix) = 0) then
    raise ERangeError.Create('');
    LoadMainData(doubleMatrix);
    DisableFormElements();
    EnableStaticFormElements();
    TesterForm.ClearTestData();
  except
    On e1: EInOutError do
      ShowMessage(e1.Message);
    On e2: ERangeError do
      //ShowMessage(e2.Message);
  end;
end;

procedure TMainForm.ClearDataBtnClick(Sender: TObject);
begin
  CURRENTGRAPH := 'NONE';
  TesterUnit.TMCURRENTSTATUS := 'NONE';
  DisableFormElements();
  UpdateDataChart();
  TesterForm.UpdateTestVisual();
end;





procedure TMainForm.XYCOLlBtnClick(Sender: TObject);
begin
  HandleXYValues();
end;

procedure TMainForm.NormalizeColBtnClick(Sender: TObject);
begin
  NormalizeCol();
end;

procedure TMainForm.SaveDataMenuItemClick(Sender: TObject);
begin
  ExportDataToCSVFile();
end;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<EVENTOS<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<//

end.


// CTRL+D Format
