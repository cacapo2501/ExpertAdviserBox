//+------------------------------------------------------------------+
//|                                                     OctaaRSI.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot RSIHi
#property indicator_label1  "RSIHi"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot RSILo
#property indicator_label2  "RSILo"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int      period_min=7;
input int      period_step=1;
input int      period_max=14;
//--- indicator buffers
double         RSIHiBuffer[];
double         RSILoBuffer[];
int            periods[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ArrayResize(periods,(period_max-period_min)/period_step+1);
   for(int idx=0;idx<ArraySize(periods);idx++){
      periods[idx]=period_min+period_step*idx;
   }
//--- indicator buffers mapping
   SetIndexBuffer(0,RSIHiBuffer);
   SetIndexBuffer(1,RSILoBuffer);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int limit=rates_total-prev_calculated+1;
   if(prev_calculated==0){
      limit-=period_max+1;
   }
   
   for(int idx=limit-1;idx>=0;idx--){
      double val_min,val_max;
      val_min=iRSI(Symbol(),PERIOD_CURRENT,periods[0],PRICE_MEDIAN,idx);
      val_max=val_min;
      for(int sub_idx=1;sub_idx<ArraySize(periods);sub_idx++){
         double val_temp=iRSI(Symbol(),PERIOD_CURRENT,periods[sub_idx],PRICE_MEDIAN,idx);
         val_max=MathMax(val_max,val_temp);
         val_min=MathMin(val_min,val_temp);
      }
      
      RSIHiBuffer[idx]=val_max;
      RSILoBuffer[idx]=val_min;
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
