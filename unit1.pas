unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls, Grids,
  ExtCtrls, TAGraph, TASeries, TATypes, TAChartUtils,
  TAMultiSeries, Math;

type
  TDoubleMatrix = Array of Array of Double;
  TDoubleArray = Array of Double;


  { TForm1 }

  TForm1 = class(TForm)
    DownScrollBtn: TButton;
    UpScrollBtn: TButton;
    Chart1BoxAndWhiskerSeries1: TBoxAndWhiskerSeries;
    RightScrollBtn: TButton;
    LeftScrollBtn: TButton;
    Chart1BarSeries1: TBarSeries;
    DataStringGrid: TStringGrid;
    ClasesCheckBox: TCheckBox;
    ColNumberStringGrid: TStringGrid;
    RowNumberStringGrid: TStringGrid;
    SymbolsImage: TImage;
    ShowLineCheckBox: TCheckBox;
    ColRangeLabel: TLabel;
    Label1: TLabel;
    DispersionTB: TToggleBox;
    BarrasTB: TToggleBox;
    StatisticsStringGrid: TStringGrid;
    CajaTB: TToggleBox;
    XYCOLlBtn: TButton;
    Chart1LineSeries1: TLineSeries;
    Chart1: TChart;
    XColEdit: TEdit;
    YColEdit: TEdit;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    CargarCSVMenuItem: TMenuItem;
    OpenDialog1: TOpenDialog;
    procedure CajaTBChange(Sender: TObject);
    procedure CargarArchivoCSV(root:String);
    procedure ActualizarGrafica();
    procedure DataStringGridAfterSelection(Sender: TObject; aCol, aRow: Integer);
    procedure DownScrollBtnClick(Sender: TObject);
    procedure GenerarGraficaDeDispersion();
    procedure GenerarGraficaDeBarras();
    procedure GenerarGraficaDeCaja(ColIndex:Integer;boxplotNum:Integer);
    procedure LeftScrollBtnClick(Sender: TObject);
    procedure OrdenarColumna(colIndex:Integer);
    function SortedMatrixToArray(colIndex:Integer):TDoubleArray;
    function SortedMatrixRealValue(i,j:Integer):Double;
    function ObtenerMedia(colIndex:Integer):Double;
    function ObtenerMediana(sortedArray:TDoubleArray):Double;
    function ObtenerDesviacionEst(colIndex:Integer;mean:Double):Double;
    function Discretizacion(colIndex:Integer):TDoubleMatrix;
    function RandomRGB(RMin,RMax,GMin,GMax,BMin,BMax:Integer):TColor;
    procedure ClasesCheckBoxChange(Sender: TObject);
    procedure BarrasTBChange(Sender: TObject);
    procedure DispersionTBChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CargarCSVMenuItemClick(Sender: TObject);
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
  DATAMATRIX,STATSMATRIX:TDoubleMatrix;
  SORTEDMATRIX:Array of Array of Integer;
  DATATAG,CLASSARRAY:Array of Integer;
  DMROWSIZE,DMCOLSIZE,XCOLINDEX,YCOLINDEX:Integer;
  CHARTTYPE:String;

implementation

{$R *.lfm}

{ TForm1 }




//-------------------------- Valores de inicio ------------------------------//
procedure TForm1.FormCreate(Sender: TObject);
begin
     Chart1LineSeries1.Clear;
     Chart1LineSeries1.Pointer.Style:=psCircle;
     Chart1LineSeries1.Pointer.Brush.Color:=Clred;
     Chart1LineSeries1.Pointer.Pen.Style:=psClear;
     Chart1LineSeries1.Pointer.Visible:=True;
     Chart1LineSeries1.ShowLines:=False;
     SymbolsImage.Picture.LoadFromFile('StatsSymbols.jpg');
     CHARTTYPE:='NINGUNA';

     //Cargar archivo automaticamente para pruebas//
     XCOLINDEX:=0;
     YCOLINDEX:=1;
     OpenDialog1.InitialDir:=ExtractFilePath('project1.exe')+'\data_sets';
     CargarArchivoCSV('data_sets\ST2.txt');
end;

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>FUNCIONES>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//

//------------------------Cargar Archivo-----------------------------//
procedure TForm1.CargarArchivoCSV(root:String);
var
   i,j,c,file_colsize,file_rowsize:Integer;
   txt_line,txt_number:String;
   full_file:TextFile;
begin

     try
        try
           AssignFile(full_file,root);
           Reset(full_file);
           //Se reserva espacio para las columnas
           SetLength(DATATAG,100);
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
                            if (file_colsize+1 > Length(DATATAG)) then
                               SetLength(DATATAG,file_colsize+100);
                               DataStringGrid.ColCount := file_colsize+100;
                            DATATAG[file_colsize] := StrToInt(txt_number);
                            DataStringGrid.Cells[file_colsize,0] := txt_number;
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
                      ReadLn(full_file,txt_line);
                      j := 0;
                      for c := 1 to Length(txt_line) do
                          begin
                               if (txt_line[c] = ',') or (c = Length(txt_line)) then
                                  begin
                                       if (c = Length(txt_line)) then
                                          txt_number += txt_line[c];
                                       //Se aumenta tamaño si se rebaso el tamaño reservado en el inicio
                                       if (file_rowsize+1 > Length(DATAMATRIX)) then
                                          SetLength(DATAMATRIX,file_rowsize+100);
                                       //Si es la ultima columna se asigna el valor en CLASSMATRIX de lo contrario se asigna a DATAMATRIX
                                       if (j+1 < file_colsize) then
                                          DATAMATRIX[file_rowsize-1, j] := StrToFloat(txt_number)
                                       else
                                           CLASSARRAY[file_rowsize-1] := StrToInt(txt_number);
                                       DataStringGrid.Cells[j,file_rowsize] := txt_number;
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

           DMCOLSIZE := file_colsize-1;//Tamaño sin la primera fila
           DMROWSIZE := file_rowsize-1;//Tamaño sin la ultima columna
           SetLength(STATSMATRIX,3,DMCOLSIZE);
           SetLength(SORTEDMATRIX,DMROWSIZE,DMCOLSIZE);

           StatisticsStringGrid.Clean;
           ColNumberStringGrid.Clean;
           RowNumberStringGrid.Clean;
           StatisticsStringGrid.RowCount:=3;
           StatisticsStringGrid.ColCount:=DMCOLSIZE+1;
           ColNumberStringGrid.RowCount:=1;
           ColNumberStringGrid.ColCount:=DMCOLSIZE+1;
           RowNumberStringGrid.ColCount:=1;
           RowNumberStringGrid.RowCount:=DMROWSIZE;

           ColNumberStringGrid.LeftCol:=0;
           RowNumberStringGrid.LeftCol:=0;
           DataStringGrid.LeftCol:=0;
           StatisticsStringGrid.LeftCol:=0;

           //Se llena el StringGrid que contiene el indice de las columnas y el de las filas
           for j:=0 to DMCOLSIZE-1 do
               ColNumberStringGrid.Cells[j,0]:=IntToStr(j+1);
           ColNumberStringGrid.Cells[DMCOLSIZE,0] := 'Class';
           for i:=0 to DMROWSIZE-1 do
               RowNumberStringGrid.Cells[0,i]:=IntToStr(i+1);

           //Agregar -1 a toda la primera fila de SORTEDMATRIX para indicar que no estan ordenadas
           for j:=0 to DMCOLSIZE-1 do
                    SORTEDMATRIX[0,j]:=-1;

           //Obtiene los valores Media,Mediana y Desviacion para cada columna
           for j:=0 to DMCOLSIZE-1 do
               begin
                    if (DATATAG[j]=0) then
                       begin
                            STATSMATRIX[0,j]:=ObtenerMedia(j);
                            StatisticsStringGrid.Cells[j,0]:=FloatToStr(Round(STATSMATRIX[0,j]*100)/100);
                            STATSMATRIX[1,j]:=ObtenerMediana(SortedMatrixToArray(j));
                            StatisticsStringGrid.Cells[j,1]:=FloatToStr(STATSMATRIX[1,j]);
                            STATSMATRIX[2,j]:=ObtenerDesviacionEst(j,STATSMATRIX[0,j]);
                            StatisticsStringGrid.Cells[j,2]:=FloatToStr(Round(STATSMATRIX[2,j]*100)/100);
                       end;
               end;
           //Toma el valor de la primera fila para utilizar en el Chart
           XCOLINDEX:=0;
           YCOLINDEX:=0;
           XColEdit.Text:=IntToStr(XCOLINDEX+1);
           YColEdit.Text:=IntToStr(YCOLINDEX+1);

           //showmessage('DM'+'-'+inttostr(length(DATAMATRIX))+','+inttostr(length(DATAMATRIX[0])));
        except
           On e1:EFOpenError do
              ShowMessage(e1.Message);
           On e2:EConvertError do
              ShowMessage('Caracteres encontrados en espacio de datos numericos');
           On e3:EAccessViolation do
              ShowMessage(e3.Message);
        end;
     ColRangeLabel.Caption:=IntToStr(DMCOLSIZE);
     finally
         CloseFile(full_file);
     end;
end;

//-------------------Actualizar grafica y cambiar tipo---------------//
procedure TForm1.ActualizarGrafica();
var
   i,j:Integer;

begin
     Chart1LineSeries1.clear;
     Chart1BarSeries1.clear;
     Chart1BoxAndWhiskerSeries1.clear;
     case CHARTTYPE of
          'NINGUNA':
                    ShowLineCheckBox.Visible:=False;
          'DISPERSION':
                    GenerarGraficaDeDispersion();
          'BARRAS':
                    GenerarGraficaDeBarras();
          'CAJA':
                    begin
                         j:=0;
                         for i:=0 to DMCOLSIZE-1 do
                             begin
                                  if (DATATAG[i]=0) then
                                     begin
                                          GenerarGraficaDeCaja(i,j);
                                          j+=1;
                                     end;
                             end;
                    end;



     end;
end;


//------------------------Grafica de dispersion-------------------------------//
procedure TForm1.GenerarGraficaDeDispersion();
var
   i:Integer;
begin
     if ShowLineCheckBox.Checked then
        begin
             Chart1LineSeries1.ShowLines:=True;
             if not(DATATAG[XCOLINDEX]=0) then
                OrdenarColumna(XCOLINDEX);
             for i:=0 to DMROWSIZE-1 do
                 Chart1LineSeries1.AddXY(SortedMatrixRealValue(i,XCOLINDEX),DATAMATRIX[SORTEDMATRIX[i,XCOLINDEX],YCOLINDEX],'',RandomRGB(60,90,60,140,150,150));
        end
     else
         begin
              Chart1LineSeries1.ShowLines:=False;
              for i:=0 to DMROWSIZE-1 do
                  Chart1LineSeries1.AddXY(DATAMATRIX[i,XCOLINDEX],DATAMATRIX[i,YCOLINDEX],'',RandomRGB(60,90,60,140,150,150));
         end;

end;

//------------------------Grafica de barras-------------------------------//
procedure TForm1.GenerarGraficaDeBarras();
var
   i,j,intervalNum:Integer;
   min,max,intervalWidth:Double;
   fieldsDoubleMatrix:TDoubleMatrix;
   fieldsIntArray:Array of Integer;
begin
     Chart1BarSeries1.BarWidthPercent := 70;
     Chart1BarSeries1.Marks.Visible:=True;
     Chart1BarSeries1.Marks.Style := smsLabel;
     Chart1BarSeries1.Marks.LabelBrush.Color:=clWhite;
     Chart1BarSeries1.Marks.Frame.Visible:=False;
     if ClasesCheckBox.Checked then
         begin
              SetLength(fieldsIntArray,DATATAG[DMCOLSIZE]);
              for i:=0 to Length(fieldsIntArray)-1 do
                  fieldsIntArray[i]:=0;
              for i:=0 to DMROWSIZE-1 do
                  begin
                       for j:=0 to Length(fieldsIntArray)-1 do
                           begin
                                if CLASSARRAY[i]=j then
                                fieldsIntArray[j]+=1;
                           end;
                  end;
                  for j:=0 to Length(fieldsIntArray)-1 do
                      Chart1BarSeries1.AddXY(j,fieldsIntArray[j],IntToStr(j),RandomRGB(60,90,60,140,150,150));
         end
     else
         begin
              if (DATATAG[XCOLINDEX]=0) then
                 begin
                      //Crear grafica de barras de una columna con valores discretos
                      OrdenarColumna(XCOLINDEX);
                      intervalNum:=6;
                      SetLength(fieldsDoubleMatrix,intervalNum,2);
                      //Obtenermos el tamaño de los intervalos y los valores de cada uno
                      min:=SortedMatrixRealValue(0,XCOLINDEX);
                      max:=SortedMatrixRealValue(DMROWSIZE-1,XCOLINDEX);
                      intervalWidth:=(max-min)/1000;
                      min-=intervalWidth;
                      max+=intervalWidth;
                      intervalWidth:=(max-min) / intervalNum;
                      //Generar los intervalos usando la cota superior para deifinir a cada uno
                      for i:=0 to intervalNum-1 do
                          begin
                               fieldsDoubleMatrix[i,0]:=min+(intervalWidth*(i+1));
                               fieldsDoubleMatrix[i,1]:=0;
                          end;

                      for i:=0 to DMROWSIZE-1 do
                          begin
                               for j:=0 to intervalNum-1 do
                                   begin
                                        if ((fieldsDoubleMatrix[j,0]-intervalWidth) <= SortedMatrixRealValue(i,XCOLINDEX)) and (SortedMatrixRealValue(i,XCOLINDEX) < fieldsDoubleMatrix[j,0]) then
                                           begin
                                                fieldsDoubleMatrix[j,1]+=1;
                                           end;

                                   end;
                          end;

                      for j:=0 to intervalNum-1 do
                          Chart1BarSeries1.AddXY(fieldsDoubleMatrix[j,0]-(intervalWidth/2),fieldsDoubleMatrix[j,1],FloatToStr(Round((fieldsDoubleMatrix[j,0]-intervalWidth)*100)/100)+'-'+FloatToStr(Round(fieldsDoubleMatrix[j,0]*100)/100),RandomRGB(60,90,60,140,150,150));
                 end
              else
                  begin
                       SetLength(fieldsIntArray,DATATAG[XCOLINDEX]);
                       for i:=0 to Length(fieldsIntArray)-1 do
                           fieldsIntArray[i]:=0;
                       for i:=0 to DMROWSIZE-1 do
                           begin
                                for j:=0 to Length(fieldsIntArray)-1 do
                                    begin
                                         if DATAMATRIX[i,XCOLINDEX]=j then
                                            fieldsIntArray[j]+=1;
                                    end;
                           end;
                        for j:=0 to Length(fieldsIntArray)-1 do
                          Chart1BarSeries1.AddXY(j,fieldsIntArray[j],IntToStr(j),RandomRGB(60,90,60,140,150,150));
                  end;
        end;
end;

//-------------------------Grafica De Caja-------------------------------//
procedure TForm1.GenerarGraficaDeCaja(colIndex:Integer;boxplotNum:Integer);
var
   i,tempSize:Integer;
   tempArray:TDoubleArray;
   Min,Q1,Median,Q3,Max:Double;
begin
     Min:=SortedMatrixRealValue(0,colIndex);
     Max:=SortedMatrixRealValue(DMROWSIZE-1,colIndex);
     Median:=STATSMATRIX[1,colIndex];

     if (DMROWSIZE mod 2=0)then
        begin
             tempSize:=DMROWSIZE div 2;
             setLength(tempArray,tempSize);
             for i:=0 to tempSize-1 do
               begin
                    tempArray[i]:=SortedMatrixRealValue(i,colIndex);
               end;
             Q1:=ObtenerMediana(tempArray);
             for i:=0 to tempSize-1 do
               begin
                    tempArray[i]:=SortedMatrixRealValue(i+tempsize,colIndex);
               end;
             Q3:=ObtenerMediana(tempArray);
        end
     else
         begin
              tempSize:=(DMROWSIZE+1) div 2;
             setLength(tempArray,tempSize);
             for i:=0 to tempSize-1 do
               begin
                    tempArray[i]:=SortedMatrixRealValue(i,colIndex);
               end;
             Q1:=ObtenerMediana(tempArray);
             for i:=0 to tempSize-1 do
               begin
                    tempArray[i]:=SortedMatrixRealValue(i+tempsize-1,colIndex);
               end;
             Q3:=ObtenerMediana(tempArray);
         end;

     Chart1BoxAndWhiskerSeries1.AddXY(boxplotNum,Min,Q1,Median,Q3,Max,'',RandomRGB(60,90,60,140,150,150));
end;

//Convertir indices de columna en SORTEDMATRIX a columna real y devolverla en TDoubleArray
function TForm1.SortedMatrixToArray(colIndex:Integer):TDoubleArray;
var
   sortedArray:TDoubleArray;
   i:Integer;
begin
     if (SORTEDMATRIX[0,colIndex]=-1) then
        OrdenarColumna(colIndex);
     SetLength(sortedArray,DMROWSIZE);
     for i:=0 to DMROWSIZE-1 do
       begin
            sortedArray[i]:=SortedMatrixRealValue(i,colIndex);
       end;
      result:=sortedArray;
end;

//Valor real del indice en SORTEDMATRIX
function TForm1.SortedMatrixRealValue(i,j:Integer):Double;
begin
     result:=DATAMATRIX[ (SORTEDMATRIX[i,j]) , j ];
end;


//-------------------------Discretizacion--------------------------------------//
function TForm1.Discretizacion(colIndex:Integer):TDoubleMatrix;
var
    intervalNum,i:Integer;
    intervalWidth:Double;
    min,max:Double;
    newArray:TDoubleMatrix;
begin
     intervalNum:=6;
     SetLength(newArray,intervalNum,2);
     min:=DATAMATRIX[0,colIndex];
     max:=DATAMATRIX[DMCOLSIZE-1,colIndex];
     intervalWidth:=(max-min) / intervalNum;
     for i:=0 to intervalNum-1 do
         begin
              newArray[i,0]:=min+(intervalWidth*i);
              newArray[i,1]:=0;
         end;
     for i:=0 to intervalNum-1 do
         begin
              if (newArray[i,0] <= DATAMATRIX[i,colIndex]) and (DATAMATRIX[i,colIndex] > newArray[i,0]+intervalWidth) then
                 newArray[i,1]+=1;
         end;
     result:=newArray;
end;

//Ordenar Columna en SORTEDMATRIX
procedure TForm1.OrdenarColumna(colIndex:Integer);
var
   temp:Integer;
   i,k:Integer;
begin
     if (SORTEDMATRIX[0,colIndex]=-1) then
        begin
             for i:=0 to DMROWSIZE-1 do
                 SORTEDMATRIX[i,colIndex]:=i;
             for i:=0 to DMROWSIZE-2 do
                 begin
                      for k:=0 to DMROWSIZE-2-i do
                          begin
                               if (DATAMATRIX[(SORTEDMATRIX[k,colIndex]),colIndex]>DATAMATRIX[(SORTEDMATRIX[k+1,colIndex]),colIndex]) then
                                  begin
                                       temp:=SORTEDMATRIX[k,colIndex];
                                       SORTEDMATRIX[k,colIndex]:=SORTEDMATRIX[k+1,colIndex];
                                       SORTEDMATRIX[k+1,colIndex]:=temp;
                                  end;

                          end;
                 end;
        end;

end;


//Obtener la Media de una columna
function TForm1.ObtenerMedia(colIndex:Integer):Double;
var
   i:Integer;
   mean:Double;
begin
     mean:=0;
     for i:=0 to DMROWSIZE-1 do
         begin
              mean+=DATAMATRIX[i,colIndex];
         end;
     mean:=mean/DMROWSIZE;
     result:=mean;
end;

//Obtener la Mediana de un TDoubleArray
function TForm1.ObtenerMediana(sortedArray:TDoubleArray):Double;
var
   rowSize:Integer;
begin
     rowSize:=Length(sortedArray)-1;//Se da el tamaño real en cuanto a los indices del arreglo para facilitar operaciones
     if (rowSize+1 mod 2=0) then //Se compara cantidad de datos
        result:=( sortedArray[rowSize div 2] + sortedArray[(rowSize div 2)+1] )/2

     else
         result:=sortedArray[(rowSize+1) div 2];
end;

//Obtener la desviacion estandar
function TForm1.ObtenerDesviacionEst(colIndex:Integer;mean:Double):Double;
var
   deviation:Double;
   i:Integer;
begin
     deviation:=0;
     for i:=0 to DMROWSIZE-1 do
         begin
              deviation+=Power( (DATAMATRIX[i,colIndex]-mean), 2 );
         end;
     deviation:=Sqrt(deviation/DMROWSIZE);
     result:=deviation;
end;

function TForm1.RandomRGB(RMin,RMax,GMin,GMax,BMin,BMax:Integer):TColor;
begin
     result:=RGBToColor(Random(RMax-RMin)+RMin,Random(GMax-GMin)+GMin,Random(BMax-BMin)+BMin);
end;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<FUNCIONES<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<//




//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>EVENTOS>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//

procedure TForm1.CargarCSVMenuItemClick(Sender: TObject);
begin
     try
     OpenDialog1.Execute;
     CargarArchivoCSV(OpenDialog1.FileName);
     except
        On e3:EAccessViolation do
              ShowMessage(e3.Message);
     end;
end;


//Actualizacion de StringGrids con respecto a posicion de DataStringGrid

procedure TForm1.DataStringGridAfterSelection(Sender: TObject; aCol,
  aRow: Integer);
begin
     ColNumberStringGrid.LeftCol := DataStringGrid.LeftCol;
     StatisticsStringGrid.LeftCol := DataStringGrid.LeftCol;
     RowNumberStringGrid.TopRow := DataStringGrid.TopRow-1;
end;



procedure TForm1.LeftScrollBtnClick(Sender: TObject);
begin
     if (DataStringGrid.LeftCol>0) then
        DataStringGrid.LeftCol := DataStringGrid.LeftCol-1;
     ColNumberStringGrid.LeftCol := DataStringGrid.LeftCol;
     StatisticsStringGrid.LeftCol := DataStringGrid.LeftCol;
end;

procedure TForm1.RightScrollBtnClick(Sender: TObject);
begin
     if (DataStringGrid.LeftCol<DataStringGrid.ColCount-6) then
        DataStringGrid.LeftCol := DataStringGrid.LeftCol+1;
     ColNumberStringGrid.LeftCol := DataStringGrid.LeftCol;
     StatisticsStringGrid.LeftCol := DataStringGrid.LeftCol;
end;

procedure TForm1.UpScrollBtnClick(Sender: TObject);
begin
     if (DataStringGrid.TopRow > 0) then
        DataStringGrid.TopRow := DataStringGrid.TopRow-1;
     RowNumberStringGrid.TopRow := DataStringGrid.TopRow-1;
end;

procedure TForm1.DownScrollBtnClick(Sender: TObject);
begin
     if (DataStringGrid.TopRow > DataStringGrid.TopRow-13) then
        DataStringGrid.TopRow := DataStringGrid.TopRow+1;
     RowNumberStringGrid.TopRow := DataStringGrid.TopRow-1;
end;


procedure TForm1.ShowLineCheckBoxChange(Sender: TObject);
begin
     ActualizarGrafica();
end;



procedure TForm1.ClasesCheckBoxChange(Sender: TObject);
begin
     if ClasesCheckBox.Checked then
        begin
             YColEdit.Enabled:=False;
             YColEdit.Text:='';
             XColEdit.Enabled:=False;
             XColEdit.Text:='';
        end
     else
         begin
              YColEdit.Enabled:=False;
              YColEdit.Text:='';
              XColEdit.Enabled:=True;
              XColEdit.Text:=IntToStr(XCOLINDEX+1);
         end;
     ActualizarGrafica();

end;



procedure TForm1.DispersionTBChange(Sender: TObject);
begin
     if DispersionTB.Checked=True then
        begin
             BarrasTB.Checked:=False;
             CajaTB.Checked:=False;
             ShowLineCheckBox.Visible:=True;
             CHARTTYPE:='DISPERSION';
             XColEdit.Text:=IntToStr(XCOLINDEX+1);
             YColEdit.Text:=IntToStr(YCOLINDEX+1);
             ActualizarGrafica();
        end
     else
         begin
              if (BarrasTB.Checked=False) and (CajaTB.Checked=False) then
                 DispersionTB.Checked:=True
              else
                  ShowLineCheckBox.Visible:=False;

         end;
end;


procedure TForm1.BarrasTBChange(Sender: TObject);
begin
     if BarrasTB.Checked=True then
        begin
             DispersionTB.Checked:=False;
             CajaTB.Checked:=False;
             ClasesCheckBox.Visible:=True;
             if ClasesCheckBox.Checked then
                begin
                     XColEdit.Enabled:=False;
                     XColEdit.Text:='';
                     YColEdit.Enabled:=False;
                     YColEdit.Text:='';
                end
             else
                 begin
                      XColEdit.Text:=IntToStr(XCOLINDEX+1);
                      YColEdit.Enabled:=False;
                      YColEdit.Text:='';
                 end;

             CHARTTYPE:='BARRAS';
             ActualizarGrafica();
        end
     else
         begin
              if (DispersionTB.Checked=False) and (CajaTB.Checked=False) then
                 BarrasTB.Checked:=True
              else
                  begin
                       XColEdit.Enabled:=True;
                       XColEdit.Text:=IntToStr(XCOLINDEX+1);
                       YColEdit.Enabled:=True;
                       YColEdit.Text:=IntToStr(YCOLINDEX+1);
                       ClasesCheckBox.Visible:=False;
                  end;

         end;
end;

procedure TForm1.CajaTBChange(Sender: TObject);
begin
     if CajaTB.Checked=True then
        begin
             DispersionTB.Checked:=False;
             BarrasTB.Checked:=False;
             CHARTTYPE:='CAJA';
             XColEdit.Text:=IntToStr(XCOLINDEX+1);
             YColEdit.Text:=IntToStr(YCOLINDEX+1);
             ActualizarGrafica();
        end
     else
         begin
              if (DispersionTB.Checked=False) and (BarrasTB.Checked=False) then
                 CajaTB.Checked:=True;

         end;
end;


procedure TForm1.XYCOLlBtnClick(Sender: TObject);
var
   x,y:Integer;
begin
     try
        x:=StrToInt(XColEdit.Text);
        if (0<x) and (x<=DMCOLSIZE) then
           if (BarrasTB.Checked) then
              begin
                   if (ClasesCheckBox.Checked) then
                       ActualizarGrafica()
                   else
                       begin
                           XCOLINDEX:=x-1;
                           ActualizarGrafica();
                       end;
              end
           else
               begin
                    y:=StrToInt(YColEdit.Text);
                    if (0<y) and (y<=DMROWSIZE) then
                       begin
                            XCOLINDEX:=x-1;
                            YCOLINDEX:=y-1;
                            ActualizarGrafica();
                       end

                    else
                        begin
                             ShowMessage('Rango invalido');
                             XColEdit.Text:=IntToStr(XCOLINDEX);
                             YColEdit.Text:=IntToStr(YCOLINDEX);
                        end;

               end
        else
            begin
                 ShowMessage('Rango invalido');
                 XColEdit.Text:=IntToStr(XCOLINDEX);
                 YColEdit.Text:=IntToStr(YCOLINDEX);
            end;

     except
        On e:EConvertError do
           begin
                ShowMessage('Campo vacio');
                XColEdit.Text:=IntToStr(XCOLINDEX);
                YColEdit.Text:=IntToStr(YCOLINDEX);
           end;
     end;
end;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<EVENTOS<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<//

end.

