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
#property indicator_buffers 2
#property indicator_plots   2
//--- plot Value
#property indicator_label1  "Value"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGold
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLimeGreen
#property indicator_style2  STYLE_DOT
#property indicator_width2  2
//--- input parameters
input int      ma_period=9;
input int      rsi_period=7;
input int      avg_period=3;
//--- indicator buffers
double         ValueBuffer[];
double         SignalBuffer[];
double         SourceBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   IndicatorBuffers(3);
   SetIndexBuffer(0,ValueBuffer);
   SetIndexBuffer(1,SignalBuffer);
   SetIndexBuffer(2,SourceBuffer);
   IndicatorShortName("RSIforMA("+IntegerToString(ma_period)+","+IntegerToString(rsi_period)+","+IntegerToString(avg_period)+")");
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
   int avg_limit=ma_limit;
   if(prev_calculated==0){
      ma_limit-=ma_period;
      rsi_limit-=ma_period+rsi_period;
      avg_limit-=ma_period+rsi_period+avg_period;
   }
   
   for(int idx=ma_limit-1;idx>=0;idx--){
      SourceBuffer[idx]=iMA(Symbol(),PERIOD_CURRENT,ma_period,0,MODE_SMA,PRICE_MEDIAN,idx);
   }
   
   for(int idx=rsi_limit-1;idx>=0;idx--){
      ValueBuffer[idx]=iRSIOnArray(SourceBuffer,ArraySize(SourceBuffer),rsi_period,idx);
   }
   
   for(int idx=avg_limit-1;idx>=0;idx--){
      SignalBuffer[idx]=iMAOnArray(ValueBuffer,ArraySize(ValueBuffer),avg_period,0,MODE_SMA,idx);
   }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
