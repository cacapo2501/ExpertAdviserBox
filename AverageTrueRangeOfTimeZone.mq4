//+------------------------------------------------------------------+
//|                                   AverageTrueRangeOfTimeZone.mq4 |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot ATR
#property indicator_label1  "ATR"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#include "../ExpertAdviserBox/DebugFunctions.mqh"
#include "../ExpertAdviserBox/CurveAnalyzer.mqh"
#include "../ExpertAdviserBox/StandardFunctions.mqh"
//--- input parameters
input int      unit_period=3;
//--- indicator buffers
double         ATRBuffer[];
double         TRBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   IndicatorBuffers(2);
   SetIndexBuffer(0,ATRBuffer);
   SetIndexBuffer(1,TRBuffer);
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
   int calculation_bars=rates_total-prev_calculated+1;
   int distinction_bars=rates_total-prev_calculated+1;
   if(prev_calculated==0){
      calculation_bars=rates_total-unit_period;
      distinction_bars=rates_total-unit_period-24;
   }
   else if(rates_total==prev_calculated){
      return(rates_total);
   }
   
   int times_sum[24];
   ArrayInitialize(times_sum,0);
   for(int idx=1;idx<calculation_bars;idx++){
      int idx_max=iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,unit_period,idx);
      int idx_min=iLowest (Symbol(),PERIOD_CURRENT,MODE_LOW ,unit_period,idx);
      TRBuffer[idx]=GetPrice(idx_max,PRICE_HIGH)-GetPrice(idx_min,PRICE_LOW);
   }
   
   ArrayInitialize(ATRBuffer,EMPTY_VALUE);
   for(int idx=1;idx<distinction_bars;idx++){
      times_sum[idx/24]++;
      ATRBuffer[idx%24]=ATRBuffer[idx%24]==EMPTY_VALUE?TRBuffer[idx]:(ATRBuffer[idx%24]*(times_sum[idx/24]-1)/times_sum[idx%24]+TRBuffer[idx]/times_sum[idx%24]);
   }
   
   
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
