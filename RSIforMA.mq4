//+------------------------------------------------------------------+
//|                                                     RSIforMA.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_buffers 1
#property indicator_plots   1
//--- plot Value
#property indicator_label1  "Value"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGold
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- input parameters
input int      ma_period=14;
input int      rsi_period=14;
//--- indicator buffers
double         ValueBuffer[];
double         SourceBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   IndicatorBuffers(2);
   SetIndexBuffer(0,ValueBuffer);
   SetIndexBuffer(1,SourceBuffer);
   IndicatorShortName("RSIforMA("+ma_period+","+rsi_period+")");
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
   int ma_limit=rates_total-prev_calculated+1;
   int rsi_limit=ma_limit;
   if(prev_calculated==0){
      ma_limit-=ma_period;
      rsi_limit-=ma_period+rsi_period;
   }
   
   for(int idx=ma_limit-1;idx>=0;idx--){
      SourceBuffer[idx]=iMA(Symbol(),PERIOD_CURRENT,ma_period,0,MODE_SMA,PRICE_MEDIAN,idx);
   }
   
   for(int idx=rsi_limit-1;idx>=0;idx--){
      ValueBuffer[idx]=iRSIOnArray(SourceBuffer,ArraySize(SourceBuffer),rsi_period,idx);
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
