//+------------------------------------------------------------------+
//|                                                 RangeChecker.mq4 |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property version   "1.00"

#include "../ExpertAdviserBox/StandardFunctions.mqh"
#property strict
//--- input parameters
input int      unit=4;
double         arr_range[];
int            arr_count[];
double         arr_max[];
double         arr_min[];
double         arr_value[][300];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ArrayResize(arr_range,24);
   ArrayResize(arr_count,24);
   ArrayResize(arr_max,24);
   ArrayResize(arr_min,24);
   ArrayResize(arr_value,24);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   int handle=FileOpen("RangeCheckerLog_H"+IntegerToString(unit)+".txt",FILE_TXT|FILE_WRITE);
   
   //ソート処理
   double arr_sorted[];
   double val_median;
   for(int i=0;i<24;i++){
      ArrayResize(arr_sorted,300);
      ArrayInitialize(arr_sorted,EMPTY_VALUE);
      
      for(int j=0;j<300;j++){
         if(arr_value[i][j]>0){
            arr_sorted[j]=arr_value[i][j];
         }
         else{
            break;
         }
      }
      ArraySort(arr_sorted,arr_count[i],0,MODE_ASCEND);
      val_median=arr_sorted[arr_count[i]/2];
      double val_quartile=arr_sorted[arr_count[i]*3/4]-arr_sorted[arr_count[i]/4];
      
      FileWrite(handle,IntegerToString(i,2),"時の価格幅は",DoubleToString(arr_range[i]/arr_count[i],4),"(最高値=",DoubleToString(arr_max[i],3),"、最低値=",DoubleToString(arr_min[i],3),"、中央値=",DoubleToString(val_median,3),"、値域=",DoubleToString(val_quartile,3),")");
   }
   
   FileWrite(handle,"\n[取得値詳細]");
   
   for(int idx1=0;idx1<24;idx1++){
      string output="Index["+IntegerToString(idx1)+"]=,"+DoubleToString(arr_value[idx1][0],_Digits);
      for(int idx2=1;idx2<300;idx2++){
         if(arr_value[idx1][idx2]<=0) break;
         output+=","+DoubleToString(arr_value[idx1][idx2],_Digits);
      }
      FileWrite(handle,output);
   }
   
   FileClose(handle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   static datetime lastupdate=0;
   if(lastupdate==Time[0]) return;
   lastupdate=Time[0];
   if(Time[1+unit]-Time[1]>_Period*60*unit) return;
   
   int idx=TimeHour(Time[1]);
   
   double current_value=High[iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,unit,1)]-Low[iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,unit,1)];
   arr_range[idx]+=current_value;
   arr_count[idx]++;
   arr_min[idx]=arr_min[idx]==0?current_value:MathMin(arr_min[idx],current_value);
   arr_max[idx]=arr_max[idx]==0?current_value:MathMax(arr_max[idx],current_value);
   for(int cnt=0;cnt<300;cnt++){
      if(arr_value[idx][cnt]<=0){
         arr_value[idx][cnt]=current_value;
         break;
      }
   }
  }
//+------------------------------------------------------------------+

