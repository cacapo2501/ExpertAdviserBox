//+------------------------------------------------------------------+
//|                                                 SectionalRSI.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3
//--- plot Range
#property indicator_label1  "Range"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGold
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot Asc
#property indicator_label2  "Asc"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrAqua
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3
//--- plot Desc
#property indicator_label3  "Desc"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrFuchsia
#property indicator_style3  STYLE_SOLID
#property indicator_width3  3
//--- input parameters
input int      check_period=25;
input int      reverse_level=15;
//--- indicator buffers
double         RangeBuffer[];
double         AscBuffer[];
double         DescBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,RangeBuffer);
   SetIndexBuffer(1,AscBuffer);
   SetIndexBuffer(2,DescBuffer);
   
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
   int limit=rates_total-prev_calculated;
   if(prev_calculated==0){
      limit-=check_period;
   }
   
   for(int idx=limit-1;idx>=0;idx--){
      int idx_max=iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,check_period,idx);
      int idx_min=iLowest (Symbol(),PERIOD_CURRENT,MODE_LOW ,check_period,idx);
      double val_max=High[idx_max];
      double val_min=Low[idx_min];
      
      if(idx_min<idx_max){
         //降下中
         double val_current=Low[idx];
         double rat_current=(val_current-val_min)/(val_max-val_min)*100;
         if(rat_current<reverse_level) DescBuffer[idx]=val_current;
         RangeBuffer[idx]=val_current;
      }
      else if(idx_min>idx_max){
         //上昇中
         double val_current=High[idx];
         double rat_current=(val_current-val_min)/(val_max-val_min)*100;
         if(rat_current>100-reverse_level) AscBuffer[idx]=val_current;
         RangeBuffer[idx]=val_current;
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
